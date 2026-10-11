#!/usr/bin/env bash
# Exports every printable part to kit/3d/stl/ (needs OpenSCAD: brew install --cask openscad@snapshot).
#   ./export.sh                          default shop name
#   ./export.sh "Bakkerij Peeters"       that shop's name on the stand
set -euo pipefail
cd "$(dirname "$0")"
shop="${1:-Bakkerij Peeters}"
slug=$(echo "$shop" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
mkdir -p stl
for p in card body relief; do openscad -q -o "stl/loyi-card-$p.stl" -D "part=\"$p\"" loyi-card.scad; done
openscad -q -o "stl/loyi-stand-base.stl" -D 'part="base"' loyi-stand.scad
for p in plate plate_body plate_relief; do
  openscad -q -o "stl/loyi-stand-$p-$slug.stl" -D "part=\"$p\"" -D "shop=\"$shop\"" loyi-stand.scad
done
echo "STL files in $(pwd)/stl"
