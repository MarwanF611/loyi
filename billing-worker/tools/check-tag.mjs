// Checks a freshly programmed secure tag (docs/KIT.md), on your own computer.
// Tap the tag with a phone, copy the link it opens (…/k?e=…&c=…), then:
//   SDM_META_KEY=… SDM_FILE_KEY=… node tools/check-tag.mjs "<link>"
// Prints the tag's UID and tap counter when the keys and settings are right.
import { verifySun } from "../src/sun.js";

const link = process.argv[2];
const { SDM_META_KEY: meta, SDM_FILE_KEY: file } = process.env;
if (!link || !meta || !file) {
  console.error('Usage: SDM_META_KEY=… SDM_FILE_KEY=… node tools/check-tag.mjs "<link the tag opened>"');
  process.exit(2);
}
const url = new URL(link);
const result = await verifySun(url.searchParams.get("e"), url.searchParams.get("c"), meta, file);
if (!result) {
  console.error("✗ Not a valid Loyi tap: check the keys, the e/c offsets and that PICC data is encrypted (docs/KIT.md).");
  process.exit(1);
}
console.log(`✓ Genuine tap. Tag UID ${result.uid}, tap counter ${result.counter}. Path: ${url.pathname}`);
if (url.pathname !== "/k") console.warn("  The path should be /k.");
