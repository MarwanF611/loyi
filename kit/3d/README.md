# Starter kit: 3D models

Two printable objects, as editable OpenSCAD files (`brew install --cask openscad@snapshot`):

- **`loyi-card.scad`**: the stamp card, bank-card size (85.6 × 54 mm, 2 mm thick + 0.6 mm raised logo), with the
  NFC tag sealed inside. The shop holds it out after a purchase.
- **`loyi-stand.scad`**: the counter stand. A front plate (96 × 120 × 6 mm) with the join tag sealed inside,
  leaning back 15° in a base (104 × 76 × 18 mm) that has a slot behind the plate for the stamp card.

Both are the same for every shop: nothing on them names the shop, so you can print a stock of them.

Sizes, texts and the tag size are at the top of each file. `loyi-common.scad` holds the shared ones.

Export everything:

```bash
./export.sh
```

## Printing

PLA or PETG, 0.4 mm nozzle, 0.2 mm layers, 15–20 % infill, no supports. No metallic or carbon-filled filament:
it blocks NFC.

| Part | Orientation | Pause to insert the tag | Colour change (optional) |
| --- | --- | --- | --- |
| Card (`loyi-card-card.stl`) | flat, logo up | at **1.2 mm** | at **2.0 mm** |
| Stand plate (`loyi-stand-plate.stl`) | flat, text up | at **5.0 mm** | at **6.0 mm** |
| Stand base (`loyi-stand-base.stl`) | as it stands | no | no |

The pause height is also printed in OpenSCAD's console. In the slicer, add a pause (Bambu/Orca: right-click the
layer slider → *Add pause*; PrusaSlicer: *Add pause print (M601)*) **after the layer that ends at that height**.
When it pauses: peel the sticker's liner and press the tag flat into the round pocket, sticky side down, then
resume. The printer covers it with ~1 mm of plastic (0.8 mm on the card), thin enough for any phone.

Two colours on a multi-colour printer (AMS, MMU): load `…-body.stl` and `…-relief.stl` together as one object
with two parts instead of using a colour change.

The tag pocket fits a **25 mm** round NTAG 424 DNA sticker or inlay up to about 0.6 mm thick. For Shop NFC's
ø29 mm stickers set `tag_d = 29` in `loyi-common.scad`.

## Before it goes in the box

Program each tag before you seal it in (docs/KIT.md §3), or after printing: the reader works through the plastic.
Then test it with your phone: a sealed tag can't be swapped.

STL files aren't in git (they're large and generated); run `./export.sh`.
