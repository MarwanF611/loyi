#!/usr/bin/env bash
# Exports every printable part to kit/3d/stl/ (needs OpenSCAD: brew install --cask openscad@snapshot).
# The kit is the same for every shop, so there's nothing to fill in.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl
for p in card body relief; do openscad -q -o "stl/loyi-card-$p.stl" -D "part=\"$p\"" loyi-card.scad; done
for p in base plate plate_body plate_relief; do openscad -q -o "stl/loyi-stand-$p.stl" -D "part=\"$p\"" loyi-stand.scad; done
echo "STL files in $(pwd)/stl"
