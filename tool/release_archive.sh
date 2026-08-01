#!/bin/sh

# Build, sign, and optionally upload a TrueDock iOS release.
#
# This is the "signed release automation" gap from
# docs/architecture/0002-phase5-hardening.md. It runs the local gates first, so
# an archive can never be produced from a tree that fails analysis, tests, or
# the schema audit.
#
# Usage:
#   tool/release_archive.sh                 # archive + export an IPA
#   tool/release_archive.sh --upload        # also upload to App Store Connect
#   tool/release_archive.sh --skip-gates    # re-export without re-running gates
#
# Required for signing (never hardcoded, never committed):
#   TRUEDOCK_TEAM_ID            Apple Developer team identifier
#
# Required for --upload, using an App Store Connect API key so no password or
# app-specific secret is stored anywhere:
#   TRUEDOCK_ASC_KEY_ID
#   TRUEDOCK_ASC_ISSUER_ID
#   TRUEDOCK_ASC_KEY_PATH       path to the .p8 private key
#
# Optional Sentry runtime diagnostics and iOS dSYM upload. Local releases read
# these values from the gitignored sentry.properties file created by the Sentry
# wizard. CI may provide the equivalent environment variables instead:
#   TRUEDOCK_SENTRY_DSN
#   TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE  optional 0.0-1.0 profiling ratio
#   SENTRY_AUTH_TOKEN           organization token with org:ci
#   SENTRY_ORG                  organization slug
#   SENTRY_PROJECT              iOS/Flutter project slug
#   SENTRY_URL                  self-hosted Sentry base URL, when applicable
#
# The script never writes a credential to disk, to the build directory, or to
# its own log, and it does not accept a password: an API key can be revoked
# independently, which a developer account password cannot.
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

upload=0
skip_gates=0
for arg in "$@"; do
  case "$arg" in
    --upload) upload=1 ;;
    --skip-gates) skip_gates=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--upload] [--skip-gates]" >&2
      exit 64
      ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "An iOS archive can only be produced on macOS." >&2
  exit 1
fi

if [ -z "${TRUEDOCK_TEAM_ID:-}" ]; then
  echo "TRUEDOCK_TEAM_ID is not set; signing would fall back to a stale" >&2
  echo "Xcode default or fail late during export. Set it explicitly." >&2
  exit 78
fi

# Fail before a long build rather than after it when upload credentials are
# incomplete. A partially configured upload is the worst time to discover this.
if [ "$upload" -eq 1 ]; then
  missing=''
  for var in TRUEDOCK_ASC_KEY_ID TRUEDOCK_ASC_ISSUER_ID TRUEDOCK_ASC_KEY_PATH; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
      missing="$missing $var"
    fi
  done
  if [ -n "$missing" ]; then
    echo "--upload needs:$missing" >&2
    exit 78
  fi
  if [ ! -f "$TRUEDOCK_ASC_KEY_PATH" ]; then
    echo "No App Store Connect key at $TRUEDOCK_ASC_KEY_PATH" >&2
    exit 78
  fi
fi

sentry_properties="$project_dir/sentry.properties"
read_sentry_property() {
  awk -v wanted="$1" '
    /^[[:space:]]*($|#|;)/ { next }
    {
      separator = index($0, "=")
      if (separator == 0) next
      key = substr($0, 1, separator - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key != wanted) next
      value = substr($0, separator + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$sentry_properties"
}

property_dsn=''
property_org=''
property_project=''
property_url=''
property_token=''
if [ -f "$sentry_properties" ]; then
  property_dsn=$(read_sentry_property dsn)
  property_org=$(read_sentry_property org)
  property_project=$(read_sentry_property project)
  property_url=$(read_sentry_property url)
  property_token=$(read_sentry_property auth_token)
fi

TRUEDOCK_SENTRY_DSN=${TRUEDOCK_SENTRY_DSN:-$property_dsn}
TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE=${TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE:-0.2}
SENTRY_ORG=${SENTRY_ORG:-$property_org}
SENTRY_PROJECT=${SENTRY_PROJECT:-$property_project}
SENTRY_URL=${SENTRY_URL:-$property_url}

sentry_enabled=0
sentry_any=0
sentry_missing=''
if [ -n "$TRUEDOCK_SENTRY_DSN$SENTRY_ORG$SENTRY_PROJECT$SENTRY_URL${SENTRY_AUTH_TOKEN:-}$property_token" ]; then
  sentry_any=1
fi
[ -n "$TRUEDOCK_SENTRY_DSN" ] || sentry_missing="$sentry_missing dsn"
[ -n "$SENTRY_ORG" ] || sentry_missing="$sentry_missing org"
[ -n "$SENTRY_PROJECT" ] || sentry_missing="$sentry_missing project"
if [ -z "${SENTRY_AUTH_TOKEN:-}" ] && [ -z "$property_token" ]; then
  sentry_missing="$sentry_missing auth_token"
fi
if [ "$sentry_any" -eq 1 ]; then
  if [ -n "$sentry_missing" ]; then
    echo "Incomplete Sentry configuration; missing:$sentry_missing" >&2
    exit 78
  fi
  sentry_enabled=1
  export SENTRY_ORG SENTRY_PROJECT
  if [ -n "$SENTRY_URL" ]; then
    export SENTRY_URL
  fi
fi

# Signing needs an identity in the keychain. Xcode's own message for this is
# buried under a wall of provisioning advice, so check it up front and say
# plainly what is missing.
if ! security find-identity -v -p codesigning 2>/dev/null \
  | grep -qE 'Apple (Development|Distribution)|iPhone (Developer|Distribution)'
then
  echo "No code-signing identity in the keychain." >&2
  echo "Sign in to Xcode with the team that owns $TRUEDOCK_TEAM_ID, or import" >&2
  echo "a distribution certificate, then re-run. Nothing was built." >&2
  exit 78
fi

version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
build_name=${version%%+*}
build_number=${version##*+}
if [ "$build_name" = "$version" ] || [ -z "$build_number" ]; then
  echo "pubspec version '$version' has no build number; expected name+number." >&2
  exit 1
fi
echo "Releasing TrueDock $build_name ($build_number)"

# Use one release identifier for Dart events, native iOS events, and uploaded
# dSYMs. This is exported for sentry_dart_plugin and also compiled into the SDK
# options below.
SENTRY_RELEASE="me.aroxu.truedock@$build_name+$build_number"
SENTRY_DIST="$build_number"
export SENTRY_RELEASE SENTRY_DIST

if [ "$skip_gates" -eq 0 ]; then
  # An archive that skips the gates is how a regression reaches the store.
  "$project_dir/tool/release_check.sh"
else
  echo "Skipping local gates at the caller's request." >&2
fi

archive_dir="build/release"
mkdir -p "$archive_dir"

# Clear any IPA from an earlier run so the discovery below cannot pick up a
# stale artifact and report a build that did not happen.
rm -rf build/ios/ipa

# Export options are written per run rather than committed, because a team
# identifier is environment-specific and does not belong in the repository.
cat >"$archive_dir/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>$TRUEDOCK_TEAM_ID</string>
  <key>uploadSymbols</key>
  <true/>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>destination</key>
  <string>export</string>
</dict>
</plist>
PLIST

# Let Flutter drive the archive so the Dart AOT build, asset bundling, and
# generated localizations match a normal release build. Source builds remain
# Sentry-free; official builds receive the public DSN only at build time.
if [ "$sentry_enabled" -eq 1 ]; then
  flutter build ipa \
    --release \
    --build-name "$build_name" \
    --build-number "$build_number" \
    --dart-define="TRUEDOCK_SENTRY_DSN=$TRUEDOCK_SENTRY_DSN" \
    --dart-define="TRUEDOCK_SENTRY_ENVIRONMENT=production" \
    --dart-define="TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE=$TRUEDOCK_SENTRY_PROFILES_SAMPLE_RATE" \
    --dart-define="TRUEDOCK_SENTRY_RELEASE=$SENTRY_RELEASE" \
    --dart-define="TRUEDOCK_SENTRY_DIST=$SENTRY_DIST" \
    --export-options-plist "$archive_dir/ExportOptions.plist"
else
  flutter build ipa \
    --release \
    --build-name "$build_name" \
    --build-number "$build_number" \
    --export-options-plist "$archive_dir/ExportOptions.plist"
fi

ipa=$(find build/ios/ipa -name '*.ipa' -maxdepth 1 2>/dev/null | head -n 1)
if [ -z "$ipa" ]; then
  echo "No IPA was produced. Check the signing identity and provisioning." >&2
  exit 1
fi
echo "Signed IPA: $ipa"

if [ "$sentry_enabled" -eq 1 ]; then
  echo "Uploading iOS debug symbols to Sentry..."
  dart run sentry_dart_plugin
  echo "Sentry debug symbols uploaded for $SENTRY_RELEASE ($SENTRY_DIST)."
else
  echo "Sentry values are unset; runtime diagnostics and symbol upload skipped."
fi

# Building is not validating. altool's validation catches the rejections that
# otherwise arrive by email hours later: missing usage strings, an
# unregistered privacy manifest, an already-used build number.
validate() {
  xcrun altool --validate-app \
    --type ios \
    --file "$ipa" \
    --apiKey "$TRUEDOCK_ASC_KEY_ID" \
    --apiIssuer "$TRUEDOCK_ASC_ISSUER_ID"
}

if [ "$upload" -eq 1 ]; then
  # altool finds the .p8 by convention; point it at the caller's key without
  # copying the secret anywhere permanent.
  key_dir="$HOME/.appstoreconnect/private_keys"
  key_file="$key_dir/AuthKey_$TRUEDOCK_ASC_KEY_ID.p8"
  installed_key=0
  if [ ! -f "$key_file" ]; then
    mkdir -p "$key_dir"
    cp "$TRUEDOCK_ASC_KEY_PATH" "$key_file"
    chmod 600 "$key_file"
    installed_key=1
  fi
  # Remove the copy even if validation or upload fails, so a private key is
  # never left behind by a broken run.
  cleanup() {
    if [ "$installed_key" -eq 1 ]; then
      rm -f "$key_file"
    fi
  }
  trap cleanup EXIT INT TERM

  echo "Validating with App Store Connect..."
  validate

  echo "Uploading..."
  xcrun altool --upload-app \
    --type ios \
    --file "$ipa" \
    --apiKey "$TRUEDOCK_ASC_KEY_ID" \
    --apiIssuer "$TRUEDOCK_ASC_ISSUER_ID"
  echo "Uploaded TrueDock $build_name ($build_number)."
else
  echo "Archive complete. Re-run with --upload to validate and submit."
fi
