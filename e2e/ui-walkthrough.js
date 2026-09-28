// Clicks through the real app (web build on the local emulators) as a business
// and as clients, end to end. Prerequisites, from the repo root:
//   cd app && flutter build web --dart-define=USE_EMULATORS=true && cd ..
//   firebase emulators:start --project demo
// Then: cd e2e && npm run test:ui
import assert from "node:assert/strict";
import puppeteer from "puppeteer-core";

const HOST = process.env.LOYI_URL ?? "http://localhost:5050";
const CHROME = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const DESKTOP = { width: 1280, height: 900 };
const PHONE = { width: 400, height: 860, isMobile: true };
const run = Date.now();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function step(name) {
  console.log(`  • ${name}`);
}

async function openApp(browser, viewport, path) {
  const page = await (await browser.createBrowserContext()).newPage();
  page.on("pageerror", (e) => {
    // Flutter's web keyboard converter throws on some synthetic key events from
    // puppeteer; real keyboards don't trigger it. Show it only with STACKS=1.
    if (e.message.includes("reading 'toString'") && !process.env.STACKS) return;
    console.warn("    page error:", e.message.slice(0, 200));
    if (process.env.STACKS) console.warn(e.stack?.split("\n").slice(0, 8).join("\n"));
  });
  await page.setViewport(viewport);
  await page.goto(HOST + path);
  await page.waitForFunction(() => window.firebase_auth && document.querySelector("flutter-view"), { timeout: 30000 });
  await sleep(1500);
  await page.evaluate(() => document.querySelector("flt-semantics-placeholder")?.click());
  return page;
}

/**
 * Flutter only exposes what's (nearly) on screen, so helpers scroll while they
 * search: down first, then back up. The wheel goes over the page's left margin.
 */
function scroller(page) {
  let moves = 0;
  let dir = 1;
  return async () => {
    if (++moves % 14 === 0) dir = -dir;
    const vp = page.viewport();
    await page.mouse.move(8, vp.height * 0.6);
    await page.mouse.wheel({ deltaY: dir * 380 });
    await sleep(250);
  };
}

/** All text the app exposes to screen readers (Flutter web semantics). */
const screenText = (page) =>
  page.evaluate(() => {
    const host = document.querySelector("flt-semantics-host");
    if (!host) return "";
    const labels = [...host.querySelectorAll("[aria-label]")].map((e) => e.getAttribute("aria-label"));
    return `${host.innerText}\n${labels.join("\n")}`;
  });

async function see(page, text, timeout = 15000) {
  const end = Date.now() + timeout;
  const scroll = scroller(page);
  let tries = 0;
  while (Date.now() < end) {
    await page.evaluate(() => document.querySelector("flt-semantics-placeholder")?.click());
    if ((await screenText(page)).includes(text)) return;
    await sleep(300);
    if (++tries > 4) await scroll(); // give it a moment before assuming it's off-screen
  }
  throw new Error(`Expected to see "${text}". Screen:\n${(await screenText(page)).slice(0, 1500)}`);
}

/** Clicks the last button/switch/radio whose accessible text contains [label]. */
async function tap(page, label, { role = null, wait = 700 } = {}) {
  const end = Date.now() + 15000;
  const scroll = scroller(page);
  let tries = 0;
  while (Date.now() < end) {
    const ok = await page.evaluate(
      (label, role) => {
        const roles = role ? [role] : ["button", "switch", "radio", "menuitem", "option", "checkbox", "link", "tab"];
        const el = [...document.querySelectorAll("flt-semantics-host [role]")]
          .reverse()
          .find(
            (e) =>
              roles.includes(e.getAttribute("role")) &&
              `${e.getAttribute("aria-label") ?? ""} ${e.textContent}`.includes(label),
          );
        el?.click();
        return Boolean(el);
      },
      label,
      role,
    );
    if (ok) return sleep(wait);
    await sleep(300);
    if (++tries > 3) await scroll();
  }
  throw new Error(`No button "${label}". Screen:\n${(await screenText(page)).slice(0, 1500)}`);
}

/** Types into the text field whose label or hint contains [label]. */
async function fill(page, label, value) {
  const end = Date.now() + 15000;
  const scroll = scroller(page);
  let tries = 0;
  while (Date.now() < end) {
    const handle = await page.evaluateHandle((label) => {
      return (
        [...document.querySelectorAll("input, textarea")].find((e) =>
          [e.getAttribute("aria-label"), e.getAttribute("placeholder"), e.closest("[aria-label]")?.getAttribute("aria-label")]
            .filter(Boolean)
            .some((t) => t.includes(label)),
        ) ?? null
      );
    }, label);
    const el = handle.asElement();
    const box = el ? await el.boundingBox() : null;
    const vp = page.viewport();
    if (el && box && (box.y < 70 || box.y + box.height > vp.height - 40)) {
      // Present but off-screen: scroll it towards the middle, then look again.
      await page.mouse.move(8, vp.height * 0.6);
      await page.mouse.wheel({ deltaY: box.y - vp.height / 2 });
      await sleep(400);
      continue;
    }
    if (el) {
      // Flutter attaches its text editing a moment after focus; retry until the value sticks.
      let typed = "";
      for (let attempt = 1; attempt <= 3 && typed !== value; attempt++) {
        await el.click();
        await sleep(250 * attempt + 200);
        // Clear: caret to the end, then more backspaces than any value we use.
        await page.keyboard.press("End");
        for (let i = 0; i < 60; i++) await page.keyboard.press("Backspace");
        await page.keyboard.type(value, { delay: 25 });
        await sleep(300);
        // Flutter may swap the DOM input on focus, so check the focused element.
        typed = await page.evaluate(() => document.activeElement?.value ?? "");
      }
      if (typed !== value) {
        if (process.env.SHOTS) await page.screenshot({ path: `${process.env.SHOTS}/fail-${label.replace(/\W/g, "")}.png` });
        throw new Error(`Typed "${typed}" into "${label}", expected "${value}"`);
      }
      return;
    }
    await sleep(300);
    if (++tries > 3) await scroll();
  }
  throw new Error(`No text field "${label}"`);
}

/** In-app navigation (a full reload would drop the emulator session). */
async function go(page, path) {
  await page.evaluate((p) => {
    history.pushState({}, "", p);
    dispatchEvent(new PopStateEvent("popstate"));
  }, path);
  await sleep(1200);
}

/** Runs Firestore JS in the page, as the signed-in user (reads only). */
const inPage = (page, fn, ...args) => page.evaluate(fn, ...args);

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: process.env.HEADFUL ? false : "new",
  args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

try {
  const ownerEmail = `owner-${run}@loyi.test`;
  const clientEmail = `client-${run}@loyi.test`;
  const password = "Test-1234";

  console.log("Business");
  const biz = await openApp(browser, DESKTOP, "/business/login");
  step("create a business account");
  await tap(biz, "Create account", { role: "button" });
  await fill(biz, "Email", ownerEmail);
  await fill(biz, "Password", password);
  await tap(biz, "Create account");
  await see(biz, "Welcome to Loyi");

  step("set up the shop");
  await fill(biz, "Business name", "Testbakker");
  await tap(biz, "Create my shop");
  await see(biz, "Testbakker");
  await see(biz, "Create your first loyalty card");

  step("create a loyalty card");
  await tap(biz, "New card");
  await see(biz, "New loyalty card");
  await fill(biz, "Koffiekaart", "Testkaart");
  await tap(biz, "5", { role: null });
  await fill(biz, "Free coffee", "Gratis koffie");
  await tap(biz, "30 minutes");
  await tap(biz, "No limit");
  await tap(biz, "Create card");
  await see(biz, "Edit loyalty card");

  step("add a join tag and a stamp tag");
  await tap(biz, "Add join tag");
  await tap(biz, "Create", { role: "button" });
  await see(biz, "Join tag · Entrance");
  await tap(biz, "Add stamp tag");
  await tap(biz, "Create", { role: "button" });
  await see(biz, "Stamp tag · Counter");
  const tags = await inPage(biz, async () => {
    const f = window.firebase_firestore;
    const db = f.getFirestore(window.firebase_core.getApp());
    const uid = window.firebase_auth.getAuth(window.firebase_core.getApp()).currentUser.uid;
    const snap = await f.getDocs(f.query(f.collection(db, "tags"), f.where("ownerUid", "==", uid)));
    return Object.fromEntries(snap.docs.map((d) => [d.data().type, d.id]));
  });
  assert.ok(tags.join && tags.stamp, "both tags exist");

  console.log("Client, phone 1");
  const phone = await openApp(browser, PHONE, `/t/${tags.join}`);
  step("tap the join tag");
  await see(phone, "Welcome!");
  await see(phone, "Testbakker");
  step("collect 5 stamps");
  for (let i = 1; i <= 5; i++) {
    await go(phone, `/t/${tags.stamp}`);
    await see(phone, i < 5 ? "Stamp added" : "Card full!");
  }
  step("redeem the reward at the counter");
  await tap(phone, "Use a reward");
  await see(phone, "Choose your reward");
  await tap(phone, "Use it now", { wait: 1500 });
  await see(phone, "Reward redeemed");
  await see(phone, "Gratis koffie");
  await tap(phone, "Done");

  step("save the cards with email + password");
  await go(phone, "/account");
  await see(phone, "Keep your cards safe");
  await fill(phone, "Email", clientEmail);
  await fill(phone, "Password", password);
  await tap(phone, "Save my cards", { wait: 2000 });
  await see(phone, "Your cards");
  const phoneUser = await inPage(phone, () => {
    const u = window.firebase_auth.getAuth(window.firebase_core.getApp()).currentUser;
    return { anonymous: u.isAnonymous, email: u.email };
  });
  assert.deepEqual(phoneUser, { anonymous: false, email: clientEmail });

  console.log("Client, phone 2 (new device)");
  const phone2 = await openApp(browser, PHONE, `/t/${tags.stamp}`);
  step("collect a stamp before signing in");
  await see(phone2, "Stamp added");
  step("sign in: the stamp moves into the saved account");
  await go(phone2, "/account");
  await tap(phone2, "I have an account");
  await fill(phone2, "Email", clientEmail);
  await fill(phone2, "Password", password);
  await tap(phone2, "Sign in", { wait: 3000 });
  await see(phone2, "Your cards");
  const merged = await inPage(phone2, async () => {
    const f = window.firebase_firestore;
    const db = f.getFirestore(window.firebase_core.getApp());
    const uid = window.firebase_auth.getAuth(window.firebase_core.getApp()).currentUser.uid;
    const snap = await f.getDocs(f.query(f.collection(db, "cards"), f.where("clientUid", "==", uid)));
    return snap.docs.map((d) => ({ stamps: d.data().stamps, total: d.data().totalStamps, redeemed: d.data().totalRedeemed }));
  });
  assert.deepEqual(merged, [{ stamps: 1, total: 6, redeemed: 1 }]);

  console.log("Business again");
  step("dashboard shows the activity");
  await go(biz, "/business");
  await see(biz, "Reward: Gratis koffie");
  await see(biz, "Stamp given");

  step("pause the card; taps are refused");
  await tap(biz, "Testkaart");
  await see(biz, "Edit loyalty card");
  await see(biz, "Card is live");
  const toggled = await biz.evaluate(() => {
    // The "Card is live" switch is the one on the same line as that text.
    const nodes = [...document.querySelectorAll("flt-semantics-host *")];
    const has = (n) => `${n.getAttribute("aria-label") ?? ""} ${n.textContent}`.includes("Card is live");
    const label = nodes.filter(has).at(-1);
    if (!label) return false;
    const y = (n) => n.getBoundingClientRect().top + n.getBoundingClientRect().height / 2;
    const sw = nodes
      .filter((n) => n.getAttribute("role") === "switch")
      .sort((a, b) => Math.abs(y(a) - y(label)) - Math.abs(y(b) - y(label)))[0];
    sw?.click();
    return Boolean(sw);
  });
  assert.ok(toggled, "found the Card is live switch");
  await sleep(500);
  await tap(biz, "Save", { role: "button", wait: 1500 });
  await go(phone, `/t/${tags.stamp}`);
  await see(phone, "This loyalty card is paused.");

  step("rename the business in settings");
  await go(biz, "/business/settings");
  await fill(biz, "Business name", "Testbakker Peeters");
  await tap(biz, "Save", { role: "button" });
  await see(biz, "Saved");

  step("forgot password sends a reset link");
  await go(biz, "/business");
  await tap(biz, "Sign out");
  await see(biz, "Welcome back");
  await fill(biz, "Email", ownerEmail);
  await tap(biz, "Forgot password?");
  await see(biz, "a link to reset the password is on its way");

  console.log("\n✔ UI walkthrough passed");
} catch (e) {
  console.error("\n✖ UI walkthrough failed:", e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
