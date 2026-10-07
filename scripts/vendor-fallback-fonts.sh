#!/usr/bin/env bash
# Serves Flutter's fallback fonts from our own hosting instead of fonts.gstatic.com.
# Flutter web always loads Roboto and, when a character is missing from Loyi's own
# fonts (an emoji in a shop name, Arabic, Greek, …), a Noto font for it. Fetching
# those from Google would send every visitor's IP address to Google.
#
# Copies every font the built engine can ask for (except the very large Chinese,
# Japanese and Korean sets, which then show as empty boxes) into build/web/fallback-fonts/,
# matching web/flutter_bootstrap.js (fontFallbackBaseUrl). Downloads are cached in
# app/.fallback-fonts-cache (not in git). Called by build-web.sh.
#   ./scripts/vendor-fallback-fonts.sh app/build/web
set -euo pipefail
web="${1:?build/web directory}"
cache="$(cd "$(dirname "$0")/../app" && pwd)/.fallback-fonts-cache"
out="$web/fallback-fonts"
paths=$(grep -oE '"[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.(ttf|woff2|otf)"' "$web/main.dart.js" | tr -d '"' |
  grep -vE '^notosans(kr|jp|hk|tc|sc)/' | sort -u)
[ -n "$paths" ] || { echo "No fallback fonts found in main.dart.js" >&2; exit 1; }
count=0
for p in $paths; do
  if [ ! -s "$cache/$p" ]; then
    mkdir -p "$(dirname "$cache/$p")"
    curl -fsSL "https://fonts.gstatic.com/s/$p" -o "$cache/$p"
  fi
  mkdir -p "$(dirname "$out/$p")"
  cp "$cache/$p" "$out/$p"
  count=$((count + 1))
done
cat > "$out/README.txt" <<'TXT'
Roboto and the Noto fonts are by Google and licensed under the SIL Open Font License 1.1
(https://openfontlicense.org). Served here so the Loyi web app doesn't load them from Google.
TXT
echo "Fallback fonts: $count files → $out"
