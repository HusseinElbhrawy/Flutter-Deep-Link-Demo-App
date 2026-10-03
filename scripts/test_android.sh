#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/test_android.sh [URL]

Open a link in the installed Android app. Defaults to:
  deep-link-demo://app/promo?code=SUMMER20

Examples:
  scripts/test_android.sh
  scripts/test_android.sh 'deep-link-demo://app/products/42'
  scripts/test_android.sh 'https://your-domain.com/promo?code=SUMMER20'

Optional environment variables:
  ANDROID_SERIAL   Target device when multiple devices are connected.
  ANDROID_PACKAGE  Installed application ID (default: com.example.deep_link_demo_app).

Install or rebuild the app first with flutter run -d <device-id>.
Passing an HTTPS URL with -p checks routing in the installed app; it does not
prove Android has verified your website association.
USAGE
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  usage
  exit 0
fi
if (( $# > 1 )); then
  usage >&2
  exit 2
fi

if ! command -v adb >/dev/null 2>&1; then
  echo 'Error: adb is not installed or is not on PATH.' >&2
  exit 1
fi

url=${1:-'deep-link-demo://app/promo?code=SUMMER20'}
package=${ANDROID_PACKAGE:-com.example.deep_link_demo_app}
adb_args=()
if [[ -n ${ANDROID_SERIAL:-} ]]; then
  adb_args=(-s "$ANDROID_SERIAL")
fi

if ! adb "${adb_args[@]}" get-state >/dev/null 2>&1; then
  echo 'Error: no ready Android device. Start an emulator or connect a device; set ANDROID_SERIAL if needed.' >&2
  exit 1
fi
if ! adb "${adb_args[@]}" shell pm path "$package" | grep -q '^package:'; then
  echo "Error: $package is not installed on the selected device. Run flutter run first." >&2
  exit 1
fi

# adb shell runs a device shell; quote user-supplied values for that shell.
printf -v remote_url '%q' "$url"
printf -v remote_package '%q' "$package"
printf 'Opening %s in %s\n' "$url" "$package"
adb "${adb_args[@]}" shell "am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d $remote_url -p $remote_package"
