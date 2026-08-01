#!/bin/sh

# Reproduce every local, non-signing TrueDock release gate on macOS.
# Live-server, physical-device, App Store signing, and upload checks remain
# deliberate manual steps documented in docs/support/release-checklist.md.
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

flutter pub get

# Run before gen-l10n: a duplicate ARB key is valid JSON, so gen-l10n accepts it
# and simply drops the earlier string. Nothing downstream can see that, which is
# how two locales ended up disagreeing about storageSnapshotCreated.
python3 tool/arb_lint.py lib/l10n/app_en.arb

flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze

# Prove no screen reaches a destructive controller method without asking the
# user first. Tests cannot cover this: a new screen calling deleteDataset
# directly would simply have no test, and nothing would fail. This caught
# pool.replace silently dropping the force flag the confirmation had promised.
python3 tool/confirmation_audit.py lib

# Catch options the repository accepts but the controller never forwards. The
# layers each look correct in isolation, so nothing else fails: the analyzer
# sees a legal call using a default, and the break lives in the seam between
# them. This is the shape of the pool.replace force defect.
python3 tool/parameter_drop_audit.py

# Flutter can report a test-device interruption while returning success after
# SIGINT during finalization. Require both a zero exit status and its terminal
# success marker so an interrupted suite can never fall through to a green
# release result.
mkdir -p build
test_log="build/release-test.log"
# Running the full widget suite in parallel can deadlock the Flutter test
# compiler on macOS (the individual files and the same suite serially pass).
# Release verification favors a deterministic result over test throughput.
if ! flutter test --concurrency=1 >"$test_log" 2>&1; then
  cat "$test_log"
  exit 1
fi
cat "$test_log"
if ! grep -Fq 'All tests passed!' "$test_log"; then
  echo "Flutter test did not produce its success marker." >&2
  exit 1
fi

flutter build apk --debug
flutter build ios --simulator --no-codesign

privacy_manifest="build/ios/iphonesimulator/Runner.app/PrivacyInfo.xcprivacy"
if [ ! -f "$privacy_manifest" ]; then
  echo "Missing bundled iOS privacy manifest: $privacy_manifest" >&2
  exit 1
fi

sentry_privacy_manifest="build/ios/iphonesimulator/Runner.app/Frameworks/Sentry.framework/PrivacyInfo.xcprivacy"
if [ ! -f "$sentry_privacy_manifest" ]; then
  echo "Missing bundled Sentry iOS privacy manifest: $sentry_privacy_manifest" >&2
  exit 1
fi
for data_type in \
  NSPrivacyCollectedDataTypeCrashData \
  NSPrivacyCollectedDataTypePerformanceData \
  NSPrivacyCollectedDataTypeOtherDiagnosticData
do
  if ! grep -Fq "$data_type" "$sentry_privacy_manifest"; then
    echo "Sentry privacy manifest does not declare $data_type." >&2
    exit 1
  fi
done

# Compare every call TrueDock makes against a schema captured from a real
# server. This is the check that caught payloads the fixtures agreed with and
# the server rejected (app.delete, system.reboot, interface.commit_node), so it
# belongs in the gate rather than in someone's memory.
#
# It needs a schema dump, which needs a live server, so it is skipped when no
# dump is present rather than blocking an offline run. Refresh the dump with:
#   dart run tool/schema_dump.dart <host> <user> <password> tool/fixtures/methods.json
schema_dump="${TRUEDOCK_SCHEMA_DUMP:-tool/fixtures/methods.json}"
if [ -f "$schema_dump" ]; then
  audit_log="build/release-schema-audit.log"
  if ! python3 tool/schema_audit.py "$schema_dump" lib >"$audit_log" 2>&1; then
    cat "$audit_log"
    echo "Schema audit failed." >&2
    exit 1
  fi
  cat "$audit_log"
  # The audit reports findings on stdout and still exits zero, so a clean run
  # has to be asserted positively or a regression would pass silently.
  for marker in \
    'no unexpected payload keys found' \
    'no positional-argument shape mismatches found' \
    'no unexpected keys in delegated payloads' \
    'no unexpected keys in interpolated-method payloads' \
    'no missing required keys found'
  do
    if ! grep -Fq "$marker" "$audit_log"; then
      echo "Schema audit did not report: $marker" >&2
      exit 1
    fi
  done
  if grep -Fq 'UNADVERTISED METHODS' "$audit_log"; then
    echo "Schema audit found methods the server does not advertise." >&2
    exit 1
  fi
  # A method name built by interpolation is invisible to the literal scan, so
  # an unresolved one means the audit is covering less than it reports.
  if grep -Fq 'UNRESOLVED INTERPOLATED METHOD NAMES' "$audit_log"; then
    echo "Schema audit found method names it could not resolve." >&2
    exit 1
  fi
else
  echo "Skipping schema audit: no dump at $schema_dump" >&2
  echo "Capture one with tool/schema_dump.dart before a public release." >&2
fi

echo "TrueDock local release gates passed."
