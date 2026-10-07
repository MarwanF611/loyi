#!/usr/bin/env bash
# Builds the web app and puts the Loyi website in front of it:
#   /, /fr/, /en/ → the website (app/web/home.html in Dutch, French, English; see scripts/build-site.mjs)
#   everything else (/t/…, /cards, /business, …) → the Flutter app, served from app.html
# Pass flutter build options through, e.g. --dart-define=USE_EMULATORS=true.
set -euo pipefail
cd "$(dirname "$0")/../app"

# A stale plugin registrant (after adding or removing packages) silently drops web plugins.
rm -rf .dart_tool/flutter_build
flutter build web --csp "$@"
mv build/web/index.html build/web/app.html
# The website's home page in Dutch (/), French (/fr/) and English (/en/).
node ../scripts/build-site.mjs build/web
