#!/usr/bin/env bash
# Builds the production web app, deploys it to Firebase Hosting (loyi-b530b),
# then restores the emulator build so http://localhost:5050 keeps working.
#   --csp: no eval in the compiled code, required by the Content-Security-Policy in firebase.json.
#   config/prod.json: public client keys (RevenueCat, App Check).
set -euo pipefail
cd "$(dirname "$0")/.."

(cd app && flutter build web --release --csp --dart-define-from-file=config/prod.json)
firebase deploy --only hosting --project loyi-b530b
(cd app && flutter build web --csp --dart-define=USE_EMULATORS=true)
