#!/usr/bin/env bash
# Copies the Firebase JS SDK into app/web/firebase/<version>/ so the web app loads it
# from Loyi's own hosting instead of www.gstatic.com (no visitor IPs sent to Google's
# CDN before anyone uses the app). Run after a FlutterFire upgrade changes the version
# (test/firebase_sdk_version_test.dart tells you when).
#   ./scripts/vendor-firebase-sdk.sh 12.19.0
set -euo pipefail
v="${1:?Firebase JS SDK version, e.g. 12.19.0}"
out="$(dirname "$0")/../app/web/firebase/$v"
mkdir -p "$out"
for name in app auth firestore-pipelines app-check; do
  curl -fsSL "https://www.gstatic.com/firebasejs/$v/firebase-$name.js" |
    # The bundles import firebase-app from the CDN; point that at the local copy.
    sed "s#https://www.gstatic.com/firebasejs/$v/firebase-app.js#./firebase-app.js#g; /sourceMappingURL=/d" \
      > "$out/firebase-$name.js"
done
if grep -l "www.gstatic.com/firebasejs" "$out"/*.js; then echo "CDN references left" >&2; exit 1; fi
echo "Firebase JS SDK $v → $out"
