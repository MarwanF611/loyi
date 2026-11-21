#!/usr/bin/env bash
# Builds the print files for the Loyi tag card with headless Chrome (macOS):
#   loyi-tag-card-shop.pdf     2 pages, 154.5 x 111 mm (A6 card 148.5 x 105 mm + 3 mm bleed): front, back. For a card printer.
#   loyi-tag-card-a4-4up.pdf   2 A4 landscape pages (fronts, backs), 4 cards each, edge to edge. Flip on the SHORT edge.
#   loyi-tag-card-preview.png  both sides on screen
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
SRC="file://$(pwd)/loyi-tag-card.html"
pdf() { "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=4000 \
  --print-to-pdf="$2" "$SRC?mode=$1" 2>/dev/null; }
pdf shop loyi-tag-card-shop.pdf
pdf sheet loyi-tag-card-a4-4up.pdf
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=4000 --window-size=1120,1800 \
  --screenshot=loyi-tag-card-preview.png "$SRC?mode=preview" 2>/dev/null
ls -la *.pdf *.png
