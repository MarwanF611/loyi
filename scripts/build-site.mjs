// Renders the website's home page in every language, after `flutter build web`:
//   node scripts/build-site.mjs [outDir]        (default: app/build/web)
//
// app/web/home.html is the English source. app/web_i18n/home.json maps each piece of
// its text (whole text nodes and alt/aria-label/content/title values, never parts of
// words) to Dutch and French. Dutch is the default and lives at "/", French and
// English at "/fr/" and "/en/". The build fails when any text has no translation, so
// a new sentence can't ship in English by accident.
//
// app/web_i18n/site.json holds the site address, the contact address and the company
// details (footer line); app/web_i18n/testimonials.json the shop quotes (section hidden
// while empty). Both are added after translating.
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "app");
const out = process.argv[2] ?? join(root, "build", "web");
const config = JSON.parse(readFileSync(join(root, "web_i18n", "site.json"), "utf8"));
const quotes = JSON.parse(readFileSync(join(root, "web_i18n", "testimonials.json"), "utf8")).quotes ?? [];
const SITE = config.url.replace(/\/$/, "");
// home.html is written with this address; site.json may change it.
const SOURCE_EMAIL = "marwan.fikri20@gmail.com";
const LANGS = { nl: "/", fr: "/fr/", en: "/en/" };
const OG_LOCALE = { nl: "nl_BE", fr: "fr_BE", en: "en_GB" };
const LEGAL = ["/privacy", "/terms", "/dpa", "/delete-account"];

const source = readFileSync(join(root, "web", "home.html"), "utf8").replaceAll(SOURCE_EMAIL, config.email);
const dict = JSON.parse(readFileSync(join(root, "web_i18n", "home.json"), "utf8"));
const norm = (s) => s.replace(/\s+/g, " ").trim();
const hasWords = (s) => /\p{L}{2}/u.test(s) && !/^\s*\S+@\S+\s*$/.test(s); // an email address isn't translated

function translate(text, lang, where) {
  if (lang === "en") return text;
  const key = norm(text);
  const entry = dict[key];
  if (!entry?.[lang]) throw new Error(`No ${lang} translation for ${where}: "${key}"`);
  // Keep the surrounding whitespace so the layout of the HTML stays the same.
  return text.match(/^\s*/)[0] + entry[lang] + text.match(/\s*$/)[0];
}

function render(lang) {
  const used = new Set();
  let html = source.replace(/(<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>)|>([^<]+)</g, (m, raw, text) => {
    if (raw) return raw;
    if (!hasWords(text)) return m;
    used.add(norm(text));
    return `>${translate(text, lang, "text")}<`;
  });
  // Search Console's ownership token (Google Auth Platform branding) stays as it is.
  html = html.replace(/<meta name="google-site-verification"[^>]*>|\b(alt|aria-label|content|title)="([^"]*)"/g, (m, attr, value) => {
    if (!attr || !hasWords(value) || /^(\/|https?:|#|width=|website)/.test(value)) return m;
    used.add(norm(value));
    return `${attr}="${translate(value, lang, attr)}"`;
  });

  const prefix = LANGS[lang];
  html = html
    .replace("<!-- testimonials -->", testimonials(lang))
    .replace("<!-- company -->", companyLine(lang))
    // Link previews (WhatsApp, LinkedIn…) need a full URL.
    .replace(/(property="og:image" content=")\//, `$1${SITE}/`)
    .replace(/<html lang="[^"]*">/, `<html lang="${lang}">`)
    // Home and legal links stay in this language; the language switch keeps its own links.
    .replace(/href="\/"(?![^>]*data-lang)/g, `href="${prefix}"`)
    .replace(/href="(\/(?:privacy|terms|dpa|delete-account))"/g, (m, path) => `href="${lang === "nl" ? path : `/${lang}${path}`}"`)
    // Screenshots in this language when they exist (site/img/<lang>/).
    .replace(/\/site\/img\/([\w-]+\.jpg)/g, (m, file) =>
      existsSync(join(root, "web", "site", "img", lang, file)) ? `/site/img/${lang}/${file}` : m,
    )
    .replace(/(<a [^>]*data-lang="(\w+)")/g, (m, tag, l) => (l === lang ? `${tag} aria-current="true"` : tag))
    .replace(
      "</head>",
      [
        `  <link rel="canonical" href="${SITE}${prefix}">`,
        ...Object.entries(LANGS).map(([l, p]) => `  <link rel="alternate" hreflang="${l}" href="${SITE}${p}">`),
        `  <link rel="alternate" hreflang="x-default" href="${SITE}/">`,
        `  <meta property="og:locale" content="${OG_LOCALE[lang]}">`,
        "</head>",
      ].join("\n"),
    );
  return { html, used };
}

function escape(s) {
  return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

const QUOTES_HEAD = {
  nl: ["Van onze pilootzaken", "Zaken die Loyi gebruiken"],
  fr: ["Nos commerces pilotes", "Ils utilisent Loyi"],
  en: ["From our pilot shops", "Shops using Loyi"],
};

/** Quotes stay in the language the shop said them in. */
function testimonials(lang) {
  if (!quotes.length) return "";
  const [eyebrow, title] = QUOTES_HEAD[lang];
  const items = quotes
    .map(
      (q) => `          <figure class="card quote">
            <blockquote>“${escape(q.quote)}”</blockquote>
            <figcaption>${q.photo ? `<img src="${escape(q.photo)}" alt="" width="44" height="44" loading="lazy">` : ""}<span><b>${escape(q.name)}</b>${escape(q.shop)}${q.city ? `, ${escape(q.city)}` : ""}</span></figcaption>
          </figure>`,
    )
    .join("\n");
  return `<section id="quotes">
    <div class="wrap">
      <div class="panel">
        <div class="panel-head reveal">
          <span class="eyebrow">${eyebrow}</span>
          <h2>${title}</h2>
        </div>
        <div class="quotes reveal-stagger">
${items}
        </div>
      </div>
    </div>
  </section>`;
}

const COMPANY = {
  nl: (c) => `Loyi is een dienst van ${c.name}, ${c.address}. Ondernemingsnummer ${c.number}.`,
  fr: (c) => `Loyi est un service de ${c.name}, ${c.address}. Numéro d'entreprise ${c.number}.`,
  en: (c) => `Loyi is a service of ${c.name}, ${c.address}. Company number ${c.number}.`,
};

/** Who is behind Loyi (Belgian law for businesses selling online), once site.json has the details. */
function companyLine(lang) {
  const c = config.company ?? {};
  if (!c.name || !c.address || !c.number) return "";
  return `<p class="company">${escape(COMPANY[lang](c))}</p>`;
}

let used;
for (const lang of Object.keys(LANGS)) {
  const page = render(lang);
  used = page.used;
  const dir = join(out, LANGS[lang]);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "index.html"), page.html);
}
rmSync(join(out, "home.html"), { force: true });

const stale = Object.keys(dict).filter((k) => !used.has(k));
if (stale.length) console.warn(`Unused translations (safe to remove):\n  ${stale.join("\n  ")}`);
console.log(`Home page rendered in ${Object.keys(LANGS).join(", ")} → ${out}`);
if (!companyLine("en")) console.warn("No company details in app/web_i18n/site.json yet: the footer leaves them out.");
if (!quotes.length) console.warn("No shop quotes in app/web_i18n/testimonials.json yet: that section is hidden.");
for (const page of LEGAL) {
  for (const lang of ["fr", "en"]) {
    if (!existsSync(join(root, "web", lang, `${page.slice(1)}.html`))) console.warn(`Missing ${lang}${page}.html`);
  }
}
