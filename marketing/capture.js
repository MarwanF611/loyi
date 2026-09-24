// Captures raw app screens from the local emulator build for marketing use.
//
// Prerequisites (from the repo root):
//   cd app && flutter build web --dart-define=USE_EMULATORS=true --dart-define=PUBLIC_BASE_URL=https://loyi.be
//   firebase emulators:start --project demo-loyi
// Then: cd marketing && npm run capture   (re-seeds the demo data first)
import { execFileSync } from "node:child_process";
import { mkdirSync } from "node:fs";
import puppeteer from "puppeteer-core";

const HOST = "http://localhost:5050";
const CHROME = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const OUT = new URL("./raw/", import.meta.url).pathname;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// iPhone Pro Max: 440×956 pt at 3×. The top 54 pt are left for the status bar
// that compose.js draws, so the app itself is captured at 440×902.
const PHONE = { width: 440, height: 902, deviceScaleFactor: 3, isMobile: true };
const DESKTOP = { width: 1440, height: 900, deviceScaleFactor: 2 };

const DEMO = {
  client: "sam@loyi.test",
  peetersOwner: "demo@loyi.test",
  password: "demo1234",
  peetersProgram: "peeters-broodjeskaart",
  peetersStamp: "Hs8vD1qLr6Yp0KaN5tWu",
  mokkaStamp: "Zq5wE8rT2yU6iO9pA3sD",
  liesJoin: "Lf4gH7jK1lZ3xC6vB9nM",
};

async function openApp(browser, viewport, path = "/cards") {
  const context = await browser.createBrowserContext();
  const page = await context.newPage();
  page.on("pageerror", (e) => console.warn("  page error:", e.message.slice(0, 160)));
  await page.emulateMediaFeatures([{ name: "prefers-color-scheme", value: "light" }]);
  await page.setViewport(viewport);
  await page.goto(HOST + path);
  await page.waitForFunction(() => window.firebase_auth && document.querySelector("flutter-view"), { timeout: 30000 });
  await sleep(2500);
  // Hide the "Running in emulator mode" banner.
  await page.addStyleTag({ content: ".firebase-emulator-warning { display: none !important; }" });
  return page;
}

/** Signs in through the Firebase JS SDK the app already loaded; Flutter picks it up. */
async function signIn(page, email) {
  await page.evaluate(
    (email, password) =>
      window.firebase_auth.signInWithEmailAndPassword(
        window.firebase_auth.getAuth(window.firebase_core.getApp()),
        email,
        password,
      ),
    email,
    DEMO.password,
  );
  await sleep(1500);
}

/** In-app navigation (a full reload would drop the emulator session). */
async function go(page, path, wait = 3000) {
  await page.evaluate((p) => {
    history.pushState({}, "", p);
    dispatchEvent(new PopStateEvent("popstate"));
  }, path);
  await sleep(wait);
}

/** Clicks a Flutter button/radio by its accessible text. */
async function tap(page, text, wait = 1500) {
  await page.evaluate(() => document.querySelector("flt-semantics-placeholder")?.click());
  await sleep(300);
  const ok = await page.evaluate((text) => {
    const el = [...document.querySelectorAll("[role]")]
      .reverse()
      .find(
        (e) =>
          ["button", "radio"].includes(e.getAttribute("role")) &&
          ((e.getAttribute("aria-label") ?? "") + " " + e.textContent).includes(text),
      );
    el?.click();
    return Boolean(el);
  }, text);
  if (!ok) throw new Error(`Button not found: ${text}`);
  await sleep(wait);
}

async function scroll(page, dy, at = { x: 6, y: 600 }) {
  await page.mouse.move(at.x, at.y);
  for (let i = 0; i < Math.abs(dy) / 200; i++) {
    await page.mouse.wheel({ deltaY: Math.sign(dy) * 200 });
    await sleep(80);
  }
  await sleep(900);
}

const shot = (page, name) => {
  console.log("  ✓", name);
  return page.screenshot({ path: `${OUT}${name}.png` });
};

mkdirSync(OUT, { recursive: true });
console.log("Seeding demo data…");
execFileSync("node", ["seed.js"], { cwd: new URL("../e2e/", import.meta.url).pathname, stdio: "ignore" });

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: "new",
  args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--hide-scrollbars"],
});

try {
  console.log("Client screens");
  // A brand-new visitor tapping a join tag.
  const guest = await openApp(browser, PHONE, `/t/${DEMO.liesJoin}`);
  await sleep(2500);
  await shot(guest, "client-join");

  const sam = await openApp(browser, PHONE);
  await signIn(sam, DEMO.client);
  await go(sam, `/t/${DEMO.mokkaStamp}`, 2600);
  await shot(sam, "client-stamp");
  await go(sam, `/t/${DEMO.peetersStamp}`, 1150);
  await shot(sam, "client-full-confetti");
  await sleep(2500);
  await shot(sam, "client-full");
  await go(sam, "/cards", 3500);
  await shot(sam, "client-my-cards");
  await go(sam, `/c/${DEMO.peetersProgram}_demo-client-sam`, 3000);
  await tap(sam, "Use a reward");
  await tap(sam, "Gratis koffie", 800);
  await shot(sam, "client-reward-sheet");
  await tap(sam, "Use it now", 2600);
  await shot(sam, "client-redeemed");

  console.log("Business screens (phone)");
  const owner = await openApp(browser, PHONE, "/business/login");
  await signIn(owner, DEMO.peetersOwner);
  await go(owner, "/business", 4000);
  await shot(owner, "business-dashboard");
  await scroll(owner, 900);
  await shot(owner, "business-dashboard-activity");
  await go(owner, `/business/programs/${DEMO.peetersProgram}`, 3500);
  await shot(owner, "business-editor");
  await scroll(owner, 1400);
  await shot(owner, "business-editor-design");
  await scroll(owner, 1600);
  await shot(owner, "business-editor-rewards");
  await scroll(owner, 3000);
  await shot(owner, "business-tags");

  console.log("Business screens (desktop)");
  const desk = await openApp(browser, DESKTOP, "/business/login");
  await signIn(desk, DEMO.peetersOwner);
  await go(desk, "/business", 4000);
  await shot(desk, "desktop-dashboard");
  await go(desk, `/business/programs/${DEMO.peetersProgram}`, 3500);
  await shot(desk, "desktop-editor");
  const login = await openApp(browser, DESKTOP, "/business/login");
  await shot(login, "desktop-login");
} finally {
  await browser.close();
}
console.log(`Raw screens saved to ${OUT}`);
