#!/usr/bin/env bash
# Builds the production website + web app, deploys it to Firebase Hosting (loyi-b530b),
# then restores the emulator build so http://localhost:5050 keeps working.
#   config/prod.json: public settings (billing server URL, App Check).
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-web.sh --release --dart-define-from-file=config/prod.json
firebase deploy --only hosting --project loyi-b530b
./scripts/build-web.sh --dart-define=USE_EMULATORS=true
