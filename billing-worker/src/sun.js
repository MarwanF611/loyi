// Secure Loyi tags: NXP NTAG 424 DNA with "Secure Unique NFC" (SUN) messages.
//
// Every tap makes the tag write a fresh URL:  …/k?e=<PICCData>&c=<SDMMAC>
//   e  32 hex: AES-128-CBC(SDM meta read key, IV 0) of  C7 ‖ UID (7 bytes) ‖ tap counter (3 bytes, LSB first) ‖ padding
//   c  16 hex: the odd bytes of AES-CMAC(session key, "") where
//      session key = AES-CMAC(SDM file read key, 3CC300010080 ‖ UID ‖ counter)
// The counter only goes up, so a saved or shared link can't be used twice.
// Reference: NXP application note AN12196 ("NTAG 424 DNA features and hints").
//
// WebCrypto has no raw AES block mode, so one block is encrypted with AES-CBC
// (zero IV, first output block) and decrypted with a crafted second block that
// carries valid PKCS#7 padding.

const ZERO_IV = new Uint8Array(16);

export function fromHex(hex) {
  if (!/^(?:[0-9a-fA-F]{2})*$/.test(hex)) throw new Error("bad hex");
  return Uint8Array.from(hex.match(/../g) ?? [], (b) => parseInt(b, 16));
}

export function toHex(bytes) {
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
}

const importKey = (raw, usages) => crypto.subtle.importKey("raw", raw, { name: "AES-CBC" }, false, usages);

/** AES-128 of one 16-byte block. */
async function encryptBlock(key, block) {
  const k = await importKey(key, ["encrypt"]);
  const out = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-CBC", iv: ZERO_IV }, k, block));
  return out.slice(0, 16);
}

/** AES-128 decryption of one 16-byte block (no padding). */
async function decryptBlock(key, block) {
  const pad = new Uint8Array(16).fill(16);
  const tail = await encryptBlock(key, xor(pad, block)); // decrypts to `pad` after CBC's XOR with `block`
  const k = await importKey(key, ["decrypt"]);
  const both = new Uint8Array(32);
  both.set(block, 0);
  both.set(tail, 16);
  return new Uint8Array(await crypto.subtle.decrypt({ name: "AES-CBC", iv: ZERO_IV }, k, both));
}

function xor(a, b) {
  return a.map((v, i) => v ^ b[i]);
}

/** Left shift of a 16-byte block by one bit (CMAC subkeys). */
function shift(block) {
  const out = new Uint8Array(16);
  for (let i = 0; i < 16; i++) out[i] = ((block[i] << 1) | (i < 15 ? block[i + 1] >> 7 : 0)) & 0xff;
  return out;
}

/** AES-CMAC (RFC 4493). */
export async function aesCmac(key, message) {
  const l = await encryptBlock(key, new Uint8Array(16));
  const k1 = shift(l);
  if (l[0] & 0x80) k1[15] ^= 0x87;
  const k2 = shift(k1);
  if (k1[0] & 0x80) k2[15] ^= 0x87;

  const blocks = Math.max(1, Math.ceil(message.length / 16));
  const complete = message.length > 0 && message.length % 16 === 0;
  const last = new Uint8Array(16);
  last.set(message.subarray((blocks - 1) * 16));
  if (!complete) last[message.length - (blocks - 1) * 16] = 0x80;

  let x = new Uint8Array(16);
  for (let i = 0; i < blocks - 1; i++) x = await encryptBlock(key, xor(x, message.subarray(i * 16, i * 16 + 16)));
  return encryptBlock(key, xor(x, xor(last, complete ? k1 : k2)));
}

/**
 * Checks one SUN message. Returns {uid: "04…" hex, counter} when the MAC is right,
 * or null for anything that isn't a genuine tap of a tag programmed with these keys.
 */
export async function verifySun(e, c, metaKeyHex, fileKeyHex) {
  if (!/^[0-9a-fA-F]{32}$/.test(e ?? "") || !/^[0-9a-fA-F]{16}$/.test(c ?? "")) return null;
  const plain = await decryptBlock(fromHex(metaKeyHex), fromHex(e));
  if (plain[0] !== 0xc7) return null; // PICCDataTag: UID (7 bytes) and counter (3 bytes) mirrored
  const uid = plain.slice(1, 8);
  const ctr = plain.slice(8, 11);

  const sv2 = new Uint8Array([0x3c, 0xc3, 0x00, 0x01, 0x00, 0x80, ...uid, ...ctr]);
  const sessionKey = await aesCmac(fromHex(fileKeyHex), sv2);
  const full = await aesCmac(sessionKey, new Uint8Array(0));
  const mac = full.filter((_, i) => i % 2 === 1);

  const given = fromHex(c);
  let diff = 0;
  for (let i = 0; i < 8; i++) diff |= mac[i] ^ given[i];
  if (diff !== 0) return null;
  return { uid: toHex(uid), counter: ctr[0] | (ctr[1] << 8) | (ctr[2] << 16) };
}

/** Test helper and kit tooling: the e/c pair a tag with these keys writes for (uid, counter). */
export async function makeSun(uidHex, counter, metaKeyHex, fileKeyHex) {
  const uid = fromHex(uidHex);
  const ctr = new Uint8Array([counter & 0xff, (counter >> 8) & 0xff, (counter >> 16) & 0xff]);
  const plain = new Uint8Array(16);
  plain.set([0xc7, ...uid, ...ctr]);
  const e = await encryptBlock(fromHex(metaKeyHex), plain);
  const sv2 = new Uint8Array([0x3c, 0xc3, 0x00, 0x01, 0x00, 0x80, ...uid, ...ctr]);
  const full = await aesCmac(await aesCmac(fromHex(fileKeyHex), sv2), new Uint8Array(0));
  return { e: toHex(e), c: toHex(full.filter((_, i) => i % 2 === 1)) };
}
