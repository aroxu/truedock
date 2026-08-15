#!/bin/sh

# Build an installable TrueDock Android release APK.
#
# The script intentionally uses POSIX shell syntax, so it behaves the same
# when executed directly or through bash/zsh:
#
#   tool/build_android_release.sh
#   bash tool/build_android_release.sh
#   zsh tool/build_android_release.sh --clean
#   tool/build_android_release.sh --split-per-abi
#
# Options:
#   --clean          Run flutter clean before restoring dependencies.
#   --skip-pub-get   Reuse the current resolved dependencies.
#   --split-per-abi  Produce smaller architecture-specific APKs.
#   --aab            Also build a signed Android App Bundle (.aab) for
#                     Play Store submission, alongside the APK(s).
#   --skip-apk       Skip the plain/split APK build. Only useful together
#                     with --aab, e.g. after a prior invocation already
#                     produced the APK(s) and only the bundle is missing.
#   --help           Show this help text.
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

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
if [ -f "$sentry_properties" ]; then
  property_dsn=$(read_sentry_property dsn)
fi
TRUEDOCK_SENTRY_DSN=${TRUEDOCK_SENTRY_DSN:-$property_dsn}

clean=0
pub_get=1
split_per_abi=0
build_aab=0
build_apk=1

usage() {
  sed -n '3,22p' "$0"
}

for arg in "$@"; do
  case "$arg" in
    --clean) clean=1 ;;
    --skip-pub-get) pub_get=0 ;;
    --split-per-abi) split_per_abi=1 ;;
    --aab) build_aab=1 ;;
    --skip-apk) build_apk=0 ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--clean] [--skip-pub-get] [--split-per-abi] [--aab] [--skip-apk]" >&2
      exit 64
      ;;
  esac
done

if [ "$build_apk" -eq 0 ] && [ "$build_aab" -eq 0 ]; then
  echo "Nothing to build: --skip-apk requires --aab." >&2
  exit 64
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not available on PATH." >&2
  exit 127
fi

key_properties="$project_dir/android/key.properties"
if [ ! -f "$key_properties" ]; then
  echo "Missing android/key.properties." >&2
  echo "Copy android/key.properties.example and fill in the signing values." >&2
  exit 78
fi

read_key_property() {
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
  ' "$key_properties"
}

missing_signing_values=''
for signing_key in storeFile storePassword keyAlias keyPassword; do
  if [ -z "$(read_key_property "$signing_key")" ]; then
    missing_signing_values="$missing_signing_values $signing_key"
  fi
done
if [ -n "$missing_signing_values" ]; then
  echo "Incomplete android/key.properties; missing:$missing_signing_values" >&2
  exit 78
fi

keystore_path=$(read_key_property storeFile)
case "$keystore_path" in
  '~') keystore_path=${HOME:?} ;;
  '~/'*) keystore_path=${HOME:?}/${keystore_path#\~/} ;;
esac
if [ ! -f "$keystore_path" ]; then
  echo "Android signing keystore was not found: $keystore_path" >&2
  exit 78
fi

if [ "$clean" -eq 1 ]; then
  echo "Cleaning Flutter build outputs..."
  flutter clean
fi

if [ "$pub_get" -eq 1 ]; then
  echo "Resolving Flutter dependencies..."
  flutter pub get
fi

# integration_test is a development-only native plugin. A debug or device
# test can leave this ignored generated source registering the plugin, while a
# release build correctly excludes the corresponding Android dependency. That
# stale combination fails javac with "IntegrationTestPlugin does not exist".
# Remove only Flutter's generated registrant and let the release command
# recreate it from the release dependency graph.
registrant='android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
if [ -f "$registrant" ]; then
  echo "Removing stale Android plugin registrant..."
  rm -f -- "$registrant"
fi

report_artifact() {
  artifact="$1"
  echo ""
  echo "Built: $project_dir/$artifact"
  ls -lh "$artifact"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$artifact"
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$artifact"
  else
    echo "SHA-256 tool not found; checksum skipped." >&2
  fi
}

if [ "$build_apk" -eq 1 ]; then
  echo "Building Android release APK..."
  set -- flutter build apk --release
  if [ -n "$TRUEDOCK_SENTRY_DSN" ]; then
    set -- "$@" \
      --dart-define="TRUEDOCK_SENTRY_DSN=$TRUEDOCK_SENTRY_DSN" \
      --dart-define="TRUEDOCK_SENTRY_ENVIRONMENT=production"
  fi
  if [ "$split_per_abi" -eq 1 ]; then
    set -- "$@" --split-per-abi
  fi
  "$@"

  artifact_dir='build/app/outputs/flutter-apk'
  found=0
  if [ "$split_per_abi" -eq 1 ]; then
    set -- "$artifact_dir"/app-*-release.apk
  else
    set -- "$artifact_dir/app-release.apk"
  fi
  for artifact in "$@"; do
    if [ ! -f "$artifact" ]; then
      continue
    fi
    found=1
    report_artifact "$artifact"
  done

  if [ "$found" -ne 1 ]; then
    echo "Flutter completed but no release APK was found in $artifact_dir." >&2
    exit 1
  fi
fi

if [ "$build_aab" -eq 1 ]; then
  echo ""
  echo "Building Android App Bundle (release, signed)..."
  set -- flutter build appbundle --release
  if [ -n "$TRUEDOCK_SENTRY_DSN" ]; then
    set -- "$@" \
      --dart-define="TRUEDOCK_SENTRY_DSN=$TRUEDOCK_SENTRY_DSN" \
      --dart-define="TRUEDOCK_SENTRY_ENVIRONMENT=production"
  fi
  "$@"

  aab_artifact='build/app/outputs/bundle/release/app-release.aab'
  if [ ! -f "$aab_artifact" ]; then
    echo "Flutter completed but no release AAB was found at $aab_artifact." >&2
    exit 1
  fi
  report_artifact "$aab_artifact"
fi
