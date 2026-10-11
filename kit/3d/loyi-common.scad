// Loyi starter kit: shared sizes and shapes (millimetres).
// Used by loyi-card.scad and loyi-stand.scad.

$fn = 96;

// Stamp card: the size of a bank card (ISO CR80).
card_w = 85.6;
card_h = 54;
card_t = 2.0;      // printed card body; a bought PVC card is 0.86
card_r = 3.18;     // corner radius of a bank card

// NFC tag that goes inside (NTAG 424 DNA sticker or inlay).
tag_d = 25;        // 25 mm round; set 29 for Shop NFC's ø29 stickers
tag_gap = 0.5;     // room around the tag in its pocket
tag_pocket = 0.8;  // pocket height: fits stickers and inlays up to ~0.6 mm
tag_cover = 1.0;   // plastic over the tag: keep 0.6–1.2 so phones still read it

// Raised logo and text (print it in a second colour).
relief = 0.6;
font = "Liberation Sans:style=Bold";

module rounded_rect(w, h, r) {
  offset(r) square([w - 2 * r, h - 2 * r], center = true);
}

// One arc of the NFC symbol.
module arc(r, width, half_angle = 42) {
  intersection() {
    difference() { circle(r + width / 2); circle(r - width / 2); }
    polygon([[0, 0], [2 * r * cos(half_angle), 2 * r * sin(half_angle)],
             [2 * r, 0], [2 * r * cos(half_angle), -2 * r * sin(half_angle)]]);
  }
}

// The NFC symbol (four arcs), about `size` wide.
module nfc_icon(size = 12, line = 1.2) {
  s = size / 12;
  translate([-size / 2, 0])
    for (i = [0 : 3]) arc(r = (3 + i * 2.6) * s, width = line);
}

// "loyi." wordmark.
module wordmark(size = 8) {
  text("loyi.", size = size, font = font, halign = "left", valign = "baseline");
}
