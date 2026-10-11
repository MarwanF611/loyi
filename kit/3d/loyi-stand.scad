// Loyi counter stand: a front plate with the join tag inside, on a base that holds
// the plate at 15° and has a slot behind it for the stamp card.
//
// Two parts, both printed flat without supports (PLA or PETG, 0.2 mm layers, 15–20 % infill):
//  - plate: face up. Pause at the height printed in the console to drop the tag in, resume.
//    Change filament at plate_t for coloured text.
//  - base: as it stands. Push the plate into the groove (a drop of glue if it's loose).
// part = "assembled" (preview) | "both" (side by side) | "plate" | "plate_body" | "plate_relief" | "base"

include <loyi-common.scad>

part = "both";
shop = "Bakkerij Peeters";   // shop name on the plate; "" for none
line1 = "Spaar hier";
line2 = "je stempels";
line3 = "Tik met je telefoon · Touchez · Tap";

plate_w = 96;
plate_h = 120;
plate_t = 6;
plate_r = 6;
tilt = 15;          // degrees the plate leans back
insert = 13;        // how deep the plate sits in the base

base_w = 104;
base_d = 76;
base_h = 18;
base_r = 8;
fit = 0.4;          // clearance in the groove and slot
card_slot_t = 3.2;  // fits the printed card (2.6 with logo) and a PVC card
card_slot_depth = 14;

tag_y = 2;          // tag centre above the middle of the plate (the dashed ring is drawn around it)
pause_at = plate_t - tag_cover;
echo(str("Plate: pause at ", pause_at, " mm to insert the tag; colour change at ", plate_t, " mm"));

module plate_body() {
  difference() {
    linear_extrude(plate_t) rounded_rect(plate_w, plate_h, plate_r);
    translate([0, tag_y, pause_at - tag_pocket]) cylinder(d = tag_d + 2 * tag_gap, h = tag_pocket);
  }
}

module plate_relief() {
  translate([0, 0, plate_t]) linear_extrude(relief) {
    top = plate_h / 2;
    if (shop != "") translate([0, top - 13]) text(shop, size = 5, font = font, halign = "center");
    translate([0, top - 25]) text(line1, size = 8.5, font = font, halign = "center");
    translate([0, top - 36]) text(line2, size = 8.5, font = font, halign = "center");
    // Dashed ring around the tag: "tap here".
    translate([0, tag_y]) {
      for (i = [0 : 23]) rotate(i * 15) arc(r = 17, width = 1.4, half_angle = 4.5);
      translate([1.5, 0]) nfc_icon(15, 1.6);
    }
    // Keep text above the part that sits in the base's groove (`insert`).
    translate([0, -top + insert + 22]) text(line3, size = 3.4, font = font, halign = "center");
    translate([-12, -top + insert + 9]) wordmark(8);
  }
}

module plate() { plate_body(); plate_relief(); }

module base() {
  groove_y = -base_d / 2 + 16;    // front of the plate's foot
  slot_y = base_d / 2 - 16;       // card slot near the back
  difference() {
    // Body with softened top edges.
    hull() {
      linear_extrude(base_h - 2) rounded_rect(base_w, base_d, base_r);
      translate([0, 0, base_h - 2]) linear_extrude(2) rounded_rect(base_w - 4, base_d - 4, base_r - 2);
    }
    // Groove for the plate, leaning back by `tilt`.
    translate([0, groove_y, base_h])
      rotate([-tilt, 0, 0])
        translate([-(plate_w + fit) / 2, 0, -insert])
          cube([plate_w + fit, plate_t + fit, insert + 20]);
    // Upright slot for the stamp card.
    translate([-(card_w + 1) / 2, slot_y - card_slot_t / 2, base_h - card_slot_depth])
      cube([card_w + 1, card_slot_t, card_slot_depth + 1]);
  }
}

// The plate standing in its groove, as on the counter (preview only).
module assembled() {
  base();
  translate([0, -base_d / 2 + 16, base_h]) rotate([-tilt, 0, 0]) translate([0, fit / 2, -insert])
    translate([0, plate_t, plate_h / 2]) rotate([90, 0, 0]) plate();
}

if (part == "assembled") assembled();
if (part == "both") {
  translate([-plate_w / 2 - 8, 0, 0]) plate();
  translate([base_w / 2 + 8, 0, 0]) base();
}
if (part == "plate") plate();
if (part == "plate_body") plate_body();
if (part == "plate_relief") plate_relief();
if (part == "base") base();
