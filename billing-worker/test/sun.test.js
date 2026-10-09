// SUN crypto against published test vectors (RFC 4493 for CMAC, NXP AN12196 for SUN).
import { test } from "node:test";
import assert from "node:assert/strict";
import { aesCmac, fromHex, makeSun, toHex, verifySun } from "../src/sun.js";

const RFC_KEY = "2b7e151628aed2a6abf7158809cf4f3c";

test("AES-CMAC matches RFC 4493", async () => {
  assert.equal(toHex(await aesCmac(fromHex(RFC_KEY), new Uint8Array(0))), "BB1D6929E95937287FA37D129B756746");
  assert.equal(toHex(await aesCmac(fromHex(RFC_KEY), fromHex("6bc1bee22e409f96e93d7e117393172a"))), "070A16B46B4D4144F79BDD9DD04A287C");
  const m40 = "6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411";
  assert.equal(toHex(await aesCmac(fromHex(RFC_KEY), fromHex(m40))), "DFA66747DE9AE63030CA32611497C827");
});

test("SUN message from NXP AN12196 (all-zero keys)", async () => {
  const zero = "00000000000000000000000000000000";
  const result = await verifySun("EF963FF7828658A599F3041510671E88", "94EED9EE65337086", zero, zero);
  assert.deepEqual(result, { uid: "04DE5F1EACC040", counter: 61 });
  // The tag fills the rest of the encrypted block with random bytes, so only the MAC is reproducible.
  const made = await makeSun("04DE5F1EACC040", 61, zero, zero);
  assert.equal(made.c, "94EED9EE65337086");
  assert.deepEqual(await verifySun(made.e, made.c, zero, zero), { uid: "04DE5F1EACC040", counter: 61 });
});

test("SUN rejects tampering and wrong keys", async () => {
  const meta = "11".repeat(16);
  const file = "22".repeat(16);
  const { e, c } = await makeSun("04A1B2C3D4E5F6", 7, meta, file);
  assert.deepEqual(await verifySun(e, c, meta, file), { uid: "04A1B2C3D4E5F6", counter: 7 });
  assert.equal(await verifySun(e, c.replace(/^./, (x) => (x === "0" ? "1" : "0")), meta, file), null);
  assert.equal(await verifySun(e, c, meta, "33".repeat(16)), null);
  assert.equal(await verifySun(e, c, "33".repeat(16), file), null);
  assert.equal(await verifySun("zz", c, meta, file), null);
  assert.equal(await verifySun(e, undefined, meta, file), null);
});
