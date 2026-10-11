// Loyi stamp card, 3D-printed with the NFC tag inside.
//
// Print flat, face up, 0.2 mm layers, PLA or PETG (no metal-filled filament).
//  1. Pause at the height printed in the console ("pause at …"), drop the tag in its
//     pocket (sticker: liner off, sticky side down), resume.
//  2. Optional: change filament at card_t for a white logo on a coloured card.
// Open in OpenSCAD, change the values at the top, F6, File > Export > STL.
// part = "card" (everything) | "body" | "relief" (two-colour printers: one STL each).

include <loyi-common.scad>

part = "card";
line1 = "Tik hier voor";
line2 = "je stempel";
line3 = "Touchez ici · Tap here";

tag_x = 22;   // tag (and NFC symbol) right of centre
tag_y = 4;

card_cover = 0.8;               // thinner than the stand's: the card is only card_t thick
pause_at = card_t - card_cover;  // top of the tag pocket (0.4 mm of plastic stays under it)
echo(str("Card: pause at ", pause_at, " mm to insert the tag; colour change at ", card_t, " mm"));

module body() {
  difference() {
    linear_extrude(card_t) rounded_rect(card_w, card_h, card_r);
    // Tag pocket, closed on all sides: it is printed over after the pause.
    translate([tag_x, tag_y, pause_at - tag_pocket])
      cylinder(d = tag_d + 2 * tag_gap, h = tag_pocket);
  }
}

module relief() {
  translate([0, 0, card_t]) linear_extrude(relief) {
    translate([-card_w / 2 + 7, card_h / 2 - 15]) wordmark(9);
    translate([tag_x, tag_y]) nfc_icon(17, 1.6);
    translate([-card_w / 2 + 7, -card_h / 2 + 22]) text(line1, size = 5.4, font = font);
    translate([-card_w / 2 + 7, -card_h / 2 + 14.5]) text(line2, size = 5.4, font = font);
    translate([-card_w / 2 + 7, -card_h / 2 + 6]) text(line3, size = 2.9, font = font);
  }
}

if (part == "card" || part == "body") body();
if (part == "card" || part == "relief") relief();
