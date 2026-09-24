// Turns the raw captures (npm run capture) into store screenshots and pitch
// visuals in the Loyi house style. Output: marketing/out/<lang>/...
//   npm run compose            (all languages)
//   npm run compose -- nl      (one language)
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import puppeteer from "puppeteer-core";

const CHROME = process.env.CHROME_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const root = new URL("./", import.meta.url).pathname;
const RAW = `${root}raw/`;
const FONTS = new URL("../app/assets/fonts/", import.meta.url).pathname;

// ── Copy ─────────────────────────────────────────────────────────────────────
// *word* is highlighted in the accent colour.

const CLIENT = [
  {
    id: "01-kaarten",
    raw: "client-my-cards",
    theme: "cream",
    nl: ["Al je stempelkaarten op *één plek*.", "Van de bakker tot de koffiebar. Nooit meer papieren kaartjes."],
    en: ["All your stamp cards in *one place*.", "From the bakery to the coffee bar. No more paper cards."],
  },
  {
    id: "02-stempel",
    raw: "client-stamp",
    theme: "coral",
    nl: ["Tik. Stempel. *Klaar.*", "Houd je gsm tegen de Loyi-tag aan de kassa."],
    en: ["Tap. Stamp. *Done.*", "Hold your phone to the Loyi tag at the counter."],
  },
  {
    id: "03-kaart-vol",
    raw: "client-full-confetti",
    theme: "sun",
    nl: ["Kaart vol? *Feest!*", "Je beloning blijft bewaard tot jij ze wil gebruiken."],
    en: ["Card full? *Celebrate!*", "Your reward is saved until you want to use it."],
  },
  {
    id: "04-beloning",
    raw: "client-reward-sheet",
    theme: "cream",
    nl: ["Jij kiest je *beloning*.", "Broodje of koffie? Vandaag of later? Jij beslist."],
    en: ["You choose your *reward*.", "A sandwich or a coffee? Today or later? Up to you."],
  },
  {
    id: "05-toog",
    raw: "client-redeemed",
    theme: "ink",
    statusLight: true,
    nl: ["Toon het aan de *toog*.", "Een live bevestiging die het personeel meteen herkent."],
    en: ["Show it at the *counter*.", "A live confirmation staff recognise at a glance."],
  },
  {
    id: "06-geen-app",
    raw: "client-join",
    theme: "mint",
    nl: ["Geen app. Geen *account*.", "Eén tik op de tag en je kaart staat klaar."],
    en: ["No app. No *account*.", "One tap on the tag and your card is ready."],
  },
];

const BUSINESS = [
  {
    id: "01-dashboard",
    raw: "business-dashboard",
    theme: "cream",
    nl: ["Zie wie er *terugkomt*.", "Stempels, klanten en beloningen in één oogopslag."],
    en: ["See who *comes back*.", "Stamps, clients and rewards at a glance."],
  },
  {
    id: "02-ontwerp",
    raw: "business-editor",
    theme: "coral",
    nl: ["Jouw logo. Jouw *kleuren*.", "Ontwerp je eigen stempelkaart in een paar tikken."],
    en: ["Your logo. Your *colours*.", "Design your own stamp card in a few taps."],
  },
  {
    id: "03-beloningen",
    raw: "business-editor-rewards",
    theme: "sun",
    nl: ["Beloningen die *jij* kiest.", "Deze week koffie, volgende week een broodje."],
    en: ["Rewards *you* choose.", "Coffee this week, a sandwich next week."],
  },
  {
    id: "04-nfc",
    raw: "business-tags",
    theme: "mint",
    nl: ["Klaar in *2 minuten*.", "Zet de link op een NFC-sticker en je bent vertrokken."],
    en: ["Live in *2 minutes*.", "Put the link on an NFC sticker and you're good to go."],
  },
  {
    id: "05-live",
    raw: "business-dashboard-activity",
    theme: "ink",
    nl: ["Elke stempel, *live*.", "Volg in realtime wat er aan je toog gebeurt."],
    en: ["Every stamp, *live*.", "See what happens at your counter in real time."],
  },
];

const PITCH = {
  nl: {
    heroTitle: "Digitale stempelkaarten voor de *lokale zaak*.",
    heroSub: "Klanten tikken met hun gsm op een NFC-tag. Geen app, geen papier, geen gedoe.",
    heroChips: ["Eén tik = één stempel", "Eigen logo & kleuren", "Live dashboard"],
    howTitle: "Zo werkt *Loyi*",
    how: [
      ["Tik de welkom-tag", "De kaart staat meteen klaar in de browser. Geen app nodig."],
      ["Tik na elke aankoop", "Stempel erbij, live bijgewerkt. De tag ligt achter de toog."],
      ["Kies je beloning", "Kaart vol? De klant kiest zelf wat en wanneer."],
    ],
    bizTitle: "Alles voor de zaak in *één dashboard*.",
    bizSub: "Klanten, stempels en beloningen in realtime. Kaarten ontwerpen en NFC-tags beheren vanop de gsm of de computer.",
    brandTitle: "Jouw merk op *elke kaart*.",
    brandSub: "Logo, kleuren, stijl en stempelicoon. Elke zaak een eigen kaart, samen in de portefeuille van de klant.",
    feature: ["Stempelkaarten,", "*digitaal.*"],
    featureSub: "Eén tik met je gsm. Geen app nodig.",
  },
  en: {
    heroTitle: "Digital stamp cards for *local businesses*.",
    heroSub: "Clients tap their phone on an NFC tag. No app, no paper, no hassle.",
    heroChips: ["One tap = one stamp", "Your logo & colours", "Live dashboard"],
    howTitle: "How *Loyi* works",
    how: [
      ["Tap the welcome tag", "The card opens straight in the browser. No app needed."],
      ["Tap after each purchase", "Another stamp, updated live. The tag stays behind the counter."],
      ["Choose a reward", "Card full? Clients pick what they want, and when."],
    ],
    bizTitle: "Everything for the shop in *one dashboard*.",
    bizSub: "Clients, stamps and rewards in real time. Design cards and manage NFC tags from a phone or a computer.",
    brandTitle: "Your brand on *every card*.",
    brandSub: "Logo, colours, style and stamp icon. Every shop its own card, together in the client's wallet.",
    feature: ["Stamp cards,", "*digital.*"],
    featureSub: "One tap with your phone. No app needed.",
  },
};

// ── Design tokens (mirror app/lib/theme.dart) ────────────────────────────────

const THEMES = {
  cream: { bg: "#F7F5F2", fg: "#17161C", em: "#FF5A3C", sub: "#6E6A73", blobA: "#FFE9E3", blobB: "#FFF4D6" },
  coral: { bg: "linear-gradient(160deg,#FF6B4F,#E0432A)", fg: "#FFFFFF", em: "#FFE08A", sub: "rgba(255,255,255,.86)", blobA: "rgba(255,255,255,.18)", blobB: "rgba(255,200,61,.35)" },
  ink: { bg: "linear-gradient(160deg,#1F1E25,#111015)", fg: "#F5F3EF", em: "#FFC83D", sub: "#A5A1AB", blobA: "rgba(255,90,60,.35)", blobB: "rgba(255,200,61,.22)" },
  sun: { bg: "linear-gradient(160deg,#FFD35C,#FFB81F)", fg: "#17161C", em: "#D2381E", sub: "rgba(23,22,28,.72)", blobA: "rgba(255,255,255,.45)", blobB: "rgba(255,90,60,.25)" },
  mint: { bg: "linear-gradient(160deg,#25C487,#139660)", fg: "#FFFFFF", em: "#FFF1B8", sub: "rgba(255,255,255,.88)", blobA: "rgba(255,255,255,.2)", blobB: "rgba(255,200,61,.3)" },
};

const em = (s) => s.replace(/\*(.+?)\*/g, "<em>$1</em>");
const img = (name) => `file://${RAW}${name}.png`;

const baseCss = `
  @font-face { font-family: Jakarta; font-weight: 500; src: url("file://${FONTS}PlusJakartaSans-Medium.ttf"); }
  @font-face { font-family: Jakarta; font-weight: 600; src: url("file://${FONTS}PlusJakartaSans-SemiBold.ttf"); }
  @font-face { font-family: Jakarta; font-weight: 700; src: url("file://${FONTS}PlusJakartaSans-Bold.ttf"); }
  @font-face { font-family: Jakarta; font-weight: 800; src: url("file://${FONTS}PlusJakartaSans-ExtraBold.ttf"); }
  * { box-sizing: border-box; margin: 0; }
  html, body { width: 100%; height: 100%; overflow: hidden; font-family: Jakarta, sans-serif; -webkit-font-smoothing: antialiased; }
  em { font-style: normal; }
  .blob { position: absolute; border-radius: 50%; filter: blur(60px); }
  .wordmark { font-weight: 800; letter-spacing: -.05em; line-height: 1; }
`;

/**
 * An iPhone-style frame. `w` is the screen width in px; the screen keeps the
 * 440×956 pt proportions. The status bar reuses the screenshot's own top row
 * (stretched), so it always matches the app's background.
 */
function phone(rawName, w, { statusLight = false, style = "" } = {}) {
  const s = w / 440;
  const screenH = 956 * s;
  const bar = 54 * s;
  const bezel = 14 * s;
  const radius = 62 * s;
  const color = statusLight ? "#fff" : "#17161C";
  return `
  <div style="position:absolute;${style};width:${w + bezel * 2}px;height:${screenH + bezel * 2}px;
      padding:${bezel}px;border-radius:${radius + bezel}px;background:#1B1A1F;
      box-shadow:0 ${40 * s}px ${90 * s}px rgba(23,22,28,.28), 0 ${6 * s}px ${14 * s}px rgba(23,22,28,.18),
        inset 0 0 0 ${2 * s}px #3A3940;">
    <div style="position:relative;width:${w}px;height:${screenH}px;border-radius:${radius}px;overflow:hidden;background:#fff;">
      <div style="height:${bar}px;background:url('${img(rawName)}') top/100% 60000% no-repeat;"></div>
      <img src="${img(rawName)}" style="display:block;width:${w}px;height:${screenH - bar}px;">
      <div style="position:absolute;top:0;left:0;right:0;height:${bar}px;display:flex;align-items:center;justify-content:space-between;
          padding:${6 * s}px ${34 * s}px 0 ${44 * s}px;color:${color};font:600 ${17 * s}px Jakarta, sans-serif;">
        <span>9:41</span>
        <span style="display:flex;gap:${6 * s}px;align-items:center">
          <svg width="${18 * s}" height="${12 * s}" viewBox="0 0 18 12"><g fill="${color}"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></g></svg>
          <svg width="${16 * s}" height="${12 * s}" viewBox="0 0 16 12"><path fill="${color}" d="M8 2.2c2.3 0 4.4.9 6 2.4l1.2-1.3A10.4 10.4 0 0 0 8 .4C5.2.4 2.7 1.5.8 3.3L2 4.6a8.5 8.5 0 0 1 6-2.4Zm0 3.6c1.3 0 2.5.5 3.4 1.3l1.2-1.3A6.7 6.7 0 0 0 8 4c-1.8 0-3.4.7-4.6 1.8l1.2 1.3A5 5 0 0 1 8 5.8Zm0 3.6c.4 0 .8.2 1.1.4L8 11.4 6.9 9.8c.3-.2.7-.4 1.1-.4Z"/></svg>
          <svg width="${27 * s}" height="${13 * s}" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.5" fill="none" stroke="${color}" opacity=".4"/><rect x="2" y="2" width="19" height="9" rx="2" fill="${color}"/><rect x="24.5" y="4.5" width="1.6" height="4" rx=".8" fill="${color}" opacity=".4"/></svg>
        </span>
      </div>
      <div style="position:absolute;top:${11 * s}px;left:50%;transform:translateX(-50%);width:${124 * s}px;height:${36 * s}px;border-radius:${18 * s}px;background:#000;"></div>
    </div>
  </div>`;
}

/** Desktop browser window around a desktop capture (2880×1800 source). */
function browser(rawName, w, url, style = "") {
  const s = w / 1440;
  return `
  <div style="position:absolute;${style};width:${w}px;border-radius:${18 * s}px;overflow:hidden;background:#fff;
      box-shadow:0 ${40 * s}px ${100 * s}px rgba(23,22,28,.25), 0 0 0 ${1.5 * s}px rgba(23,22,28,.08);">
    <div style="height:${44 * s}px;background:#F1EEEA;display:flex;align-items:center;gap:${8 * s}px;padding:0 ${16 * s}px;">
      <i style="width:${12 * s}px;height:${12 * s}px;border-radius:50%;background:#FF5F57"></i>
      <i style="width:${12 * s}px;height:${12 * s}px;border-radius:50%;background:#FEBC2E"></i>
      <i style="width:${12 * s}px;height:${12 * s}px;border-radius:50%;background:#28C840"></i>
      <span style="margin:0 auto;padding:${5 * s}px ${60 * s}px;border-radius:${8 * s}px;background:#fff;color:#6E6A73;font:500 ${13 * s}px Jakarta">${url}</span>
    </div>
    <img src="${img(rawName)}" style="display:block;width:${w}px;">
  </div>`;
}

const page = (w, h, bg, body) =>
  `<!doctype html><html><head><meta charset="utf-8"><style>${baseCss} body{background:${bg};position:relative;width:${w}px;height:${h}px}</style></head><body>${body}</body></html>`;

function blobs(t, w, h) {
  return `<div class="blob" style="width:${w * 0.8}px;height:${w * 0.8}px;background:${t.blobA};left:${-w * 0.25}px;top:${h * 0.45}px"></div>
    <div class="blob" style="width:${w * 0.7}px;height:${w * 0.7}px;background:${t.blobB};right:${-w * 0.3}px;top:${h * 0.25}px"></div>`;
}

/** Portrait store screenshot: headline on top, phone bleeding off the bottom. */
function storeSlide(slide, lang, { w, h, headline, sub, pad, phoneW, phoneTop }) {
  const t = THEMES[slide.theme];
  const [title, subtitle] = slide[lang];
  return page(
    w,
    h,
    t.bg,
    `${blobs(t, w, h)}
    <div style="position:absolute;left:${pad}px;right:${pad}px;top:${pad * 1.05}px;text-align:center;color:${t.fg}">
      <div style="font-weight:800;font-size:${headline}px;line-height:1.04;letter-spacing:-.025em">${em(title).replace(/<em>/g, `<em style="color:${t.em}">`)}</div>
      <div style="margin-top:${headline * 0.32}px;font-weight:600;font-size:${sub}px;line-height:1.35;color:${t.sub}">${subtitle}</div>
    </div>
    ${phone(slide.raw, phoneW, { statusLight: slide.statusLight, style: `left:${(w - phoneW) / 2 - phoneW * 0.032}px;top:${phoneTop}px` })}`,
  );
}

const chip = (text, bg, fg, size) =>
  `<span style="display:inline-block;padding:${size * 0.5}px ${size * 0.95}px;border-radius:999px;background:${bg};color:${fg};font:700 ${size}px Jakarta;margin:0 ${size * 0.45}px ${size * 0.5}px 0">${text}</span>`;

function pitchSlides(lang) {
  const c = PITCH[lang];
  const W = 1920;
  const H = 1080;
  const hl = (s, color) => em(s).replace(/<em>/g, `<em style="color:${color}">`);
  return {
    "pitch-1-hero": page(
      W,
      H,
      "#F7F5F2",
      `${blobs(THEMES.cream, W, H)}
      <div style="position:absolute;left:120px;top:120px;width:760px">
        <div class="wordmark" style="font-size:64px;color:#17161C">loyi<span style="color:#FF5A3C">.</span></div>
        <div style="margin-top:90px;font:800 76px/1.05 Jakarta;letter-spacing:-.025em;color:#17161C">${hl(c.heroTitle, "#FF5A3C")}</div>
        <div style="margin-top:30px;font:600 28px/1.45 Jakarta;color:#6E6A73;width:640px">${c.heroSub}</div>
        <div style="margin-top:44px">${c.heroChips.map((x, i) => chip(x, ["#FFFFFF", "#FFF4D6", "#DDF5EA"][i], "#17161C", 22)).join("")}</div>
      </div>
      ${phone("client-stamp", 300, { style: "left:1000px;top:230px;transform:rotate(-7deg)" })}
      ${phone("client-redeemed", 300, { statusLight: true, style: "left:1520px;top:230px;transform:rotate(7deg)" })}
      ${phone("client-my-cards", 340, { style: "left:1230px;top:120px" })}`,
    ),
    "pitch-2-hoe-het-werkt": page(
      W,
      H,
      THEMES.coral.bg,
      `${blobs(THEMES.coral, W, H)}
      <div style="position:absolute;left:0;right:0;top:70px;text-align:center;font:800 64px Jakarta;letter-spacing:-.03em;color:#fff">${hl(c.howTitle, "#FFE08A")}</div>
      ${["client-join", "client-stamp", "client-reward-sheet"]
        .map((raw, i) => {
          const x = 250 + i * 520;
          return `${phone(raw, 250, { style: `left:${x}px;top:200px` })}
          <div style="position:absolute;left:${x - 60}px;width:400px;top:780px;text-align:center;color:#fff">
            <div style="display:inline-flex;width:56px;height:56px;border-radius:50%;background:#fff;color:#E0432A;align-items:center;justify-content:center;font:800 28px Jakarta">${i + 1}</div>
            <div style="margin-top:16px;font:800 32px Jakarta;letter-spacing:-.02em">${c.how[i][0]}</div>
            <div style="margin-top:8px;font:600 21px/1.45 Jakarta;color:rgba(255,255,255,.85)">${c.how[i][1]}</div>
          </div>`;
        })
        .join("")}`,
    ),
    "pitch-3-dashboard": page(
      W,
      H,
      THEMES.ink.bg,
      `${blobs(THEMES.ink, W, H)}
      <div style="position:absolute;left:110px;top:130px;width:560px;color:#F5F3EF">
        <div class="wordmark" style="font-size:48px">loyi<span style="color:#FF5A3C">.</span> <span style="font:700 22px Jakarta;letter-spacing:0;color:#A5A1AB">for business</span></div>
        <div style="margin-top:70px;font:800 64px/1.06 Jakarta;letter-spacing:-.025em">${hl(c.bizTitle, "#FFC83D")}</div>
        <div style="margin-top:28px;font:600 25px/1.5 Jakarta;color:#A5A1AB">${c.bizSub}</div>
      </div>
      ${browser("desktop-dashboard", 1080, "loyi.be/business", "left:740px;top:150px")}
      ${phone("business-editor", 230, { style: "left:1600px;top:480px" })}`,
    ),
    "pitch-4-merk": page(
      W,
      H,
      THEMES.sun.bg,
      `${blobs(THEMES.sun, W, H)}
      <div style="position:absolute;left:110px;top:150px;width:600px;color:#17161C">
        <div style="font:800 68px/1.06 Jakarta;letter-spacing:-.025em">${hl(c.brandTitle, "#D2381E")}</div>
        <div style="margin-top:28px;font:600 26px/1.5 Jakarta;color:rgba(23,22,28,.72)">${c.brandSub}</div>
      </div>
      ${browser("desktop-editor", 980, "loyi.be/business/programs", "left:780px;top:110px")}
      ${phone("client-my-cards", 260, { style: "left:640px;top:430px;transform:rotate(-5deg)" })}`,
    ),
  };
}

function featureGraphic(lang) {
  const c = PITCH[lang];
  const [a, b] = c.feature;
  return page(
    1024,
    500,
    THEMES.coral.bg,
    `${blobs(THEMES.coral, 1024, 500)}
    <div style="position:absolute;left:70px;top:70px;color:#fff">
      <div class="wordmark" style="font-size:44px">loyi<span style="color:#FFE08A">.</span></div>
      <div style="margin-top:44px;font:800 58px/1.05 Jakarta;letter-spacing:-.025em">${a}<br>${em(b).replace(/<em>/g, '<em style="color:#FFE08A">')}</div>
      <div style="margin-top:18px;font:600 21px Jakarta;color:rgba(255,255,255,.88)">${c.featureSub}</div>
    </div>
    ${phone("client-stamp", 230, { style: "left:560px;top:60px;transform:rotate(-8deg)" })}
    ${phone("client-my-cards", 250, { style: "left:760px;top:30px;transform:rotate(6deg)" })}`,
  );
}

// ── Render ───────────────────────────────────────────────────────────────────

const STORES = {
  "appstore-6.9": {
    w: 1320,
    h: 2868,
    headline: 118,
    sub: 50,
    pad: 110,
    phoneW: 900,
    phoneTop: 760,
  },
  "googleplay": {
    w: 1080,
    h: 1920,
    headline: 84,
    sub: 36,
    pad: 80,
    phoneW: 620,
    phoneTop: 520,
  },
};

const langs = process.argv.slice(2).length ? process.argv.slice(2) : ["nl", "en"];
const browserApp = await puppeteer.launch({ executablePath: CHROME, headless: "new", args: ["--allow-file-access-from-files"] });
const tab = await browserApp.newPage();
const tmp = `${root}out/.render.html`;

async function render(html, w, h, file, { scale = 1, type = "png" } = {}) {
  writeFileSync(tmp, html);
  await tab.setViewport({ width: w, height: h, deviceScaleFactor: scale });
  await tab.goto(`file://${tmp}`, { waitUntil: "load" });
  await tab.evaluate(() => document.fonts.ready);
  await tab.screenshot({ path: file, type, ...(type === "jpeg" ? { quality: 92 } : {}) });
  console.log("  ✓", file.replace(root, ""));
}

try {
  for (const lang of langs) {
    const out = `${root}out/${lang}/`;
    rmSync(out, { recursive: true, force: true });
    for (const [store, spec] of Object.entries(STORES)) {
      for (const [set, slides] of [["klant", CLIENT], ["zaak", BUSINESS]]) {
        mkdirSync(`${out}${store}/${set}`, { recursive: true });
        for (const slide of slides) {
          await render(storeSlide(slide, lang, spec), spec.w, spec.h, `${out}${store}/${set}/${slide.id}.jpg`, { type: "jpeg" });
        }
      }
    }
    mkdirSync(`${out}googleplay`, { recursive: true });
    await render(featureGraphic(lang), 1024, 500, `${out}googleplay/feature-graphic.jpg`, { type: "jpeg" });
    mkdirSync(`${out}pitch`, { recursive: true });
    for (const [name, html] of Object.entries(pitchSlides(lang))) {
      await render(html, 1920, 1080, `${out}pitch/${name}.png`, { scale: 2 });
    }
  }
} finally {
  rmSync(tmp, { force: true });
  await browserApp.close();
}
