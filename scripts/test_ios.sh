#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/test_ios.sh [URL]

Open a link in the installed iOS Simulator app. Defaults to:
  deep-link-demo://app/promo?code=SUMMER20

Examples:
  scripts/test_ios.sh
  scripts/test_ios.sh 'deep-link-demo://app/products/42'
  scripts/test_ios.sh 'https://your-domain.com/promo?code=SUMMER20'

Optional environment variables:
  IOS_SIMULATOR  Simulator UDID (default: booted).
  IOS_BUNDLE_ID  Installed app bundle ID (default: com.example.deepLinkDemoApp).

Boot a simulator and install or rebuild the app first with flutter run.
An HTTPS URL may open Safari until the domain, association file, signing, and
Associated Domains entitlement are configured and verified.
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

if ! command -v xcrun >/dev/null 2>&1; then
  echo 'Error: xcrun is not installed. Run this script on a Mac with Xcode.' >&2
  exit 1
fi

url=${1:-'deep-link-demo://app/promo?code=SUMMER20'}
simulator=${IOS_SIMULATOR:-booted}
bundle_id=${IOS_BUNDLE_ID:-com.example.deepLinkDemoApp}

if ! xcrun simctl get_app_container "$simulator" "$bundle_id" app >/dev/null 2>&1; then
  echo "Error: $bundle_id is not installed on simulator $simulator, or that simulator is not booted. Run flutter run first." >&2
  exit 1
fi

printf 'Opening %s on iOS Simulator %s\n' "$url" "$simulator"
xcrun simctl openurl "$simulator" "$url"
