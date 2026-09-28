#!/usr/bin/env bash
# Builds the production web app, deploys it to Firebase Hosting (loyi-b530b),
# then restores the emulator build so http://localhost:5050 keeps working.
set -euo pipefail
cd "$(dirname "$0")/.."

(cd app && flutter build web --release)
firebase deploy --only hosting --project loyi-b530b
(cd app && flutter build web --dart-define=USE_EMULATORS=true)
