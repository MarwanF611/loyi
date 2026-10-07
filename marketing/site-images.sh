#!/usr/bin/env bash
# Copies the screenshots the website uses from raw/<lang>/ into app/web/site/img/<lang>/
# (phones 488 px wide, desktop 1440 px, JPEG). Run after `LANG_CODE=<lang> npm run capture`.
# macOS only (uses sips).
set -euo pipefail
cd "$(dirname "$0")"
for lang in nl fr en; do
  [ -d "raw/$lang" ] || continue
  out="../app/web/site/img/$lang"
  mkdir -p "$out"
  for f in business-dashboard business-dashboard-followup business-clients business-insights client-full-confetti client-my-cards client-message; do
    sips -s format jpeg -s formatOptions 80 --resampleWidth 488 "raw/$lang/$f.png" --out "$out/$f.jpg" >/dev/null
  done
  for f in desktop-dashboard desktop-insights desktop-clients; do
    sips -s format jpeg -s formatOptions 78 --resampleWidth 1440 "raw/$lang/$f.png" --out "$out/$f.jpg" >/dev/null
  done
  echo "site images: $lang"
done
