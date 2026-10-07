# Loyi

Digital stamp cards for small businesses in Belgium. A client taps an NFC tag in
the shop, the card opens in the browser (no app to install), and every purchase
earns a stamp. When a card is full, the client chooses which of the shop's
current rewards to use, now or on a later visit.

## How it works

Loyi runs entirely on Firebase's **free Spark plan** (no card needed): Firestore,
Authentication and Hosting. There are no Cloud Functions and no Cloud Storage.

```
 Join tag (door/counter) ──tap──▶ https://<host>/t/<tagId> ──▶ card created
 Stamp tag (behind counter) ─tap─▶ https://<host>/t/<tagId> ──▶ +1 stamp
                                            │
          Flutter Web ── Firestore transaction ──▶ firestore.rules checks every write
```

The app writes stamps and rewards itself, and `firestore.rules` is the server-side
referee. A write is only accepted if it's exactly what the app would do:

- +1 stamp from an active stamp tag of that card, only after the cooldown (checked with server time)
- one log entry per stamp
- a reward only when one is banked, and only an active reward of that card
- account merges only via a hand-off written by the anonymous device session

`e2e/flow.test.js` performs these writes and a list of cheating attempts against the emulators.

| Piece | Where |
| --- | --- |
| Flutter app: business app (iOS/Android/web) and client pages (web) | `app/` |
| Tap / redeem transactions | `app/lib/services/api.dart` |
| Save cards (Google, Apple, email + password) and merge devices; business sign-in | `app/lib/services/auth_service.dart` |
| Stamp maths (pure, unit tested; mirrored in the rules) | `app/lib/services/stamping.dart` |
| Security rules | `firestore.rules` |
| End-to-end rules tests, plus demo seed data | `e2e/` |
| Business sign-up steps (name, colours, payment) | `app/lib/business/onboarding.dart` |
| Subscriptions (Stripe) and the paywall | `app/lib/services/billing.dart`, `app/lib/business/subscribe_page.dart` |
| Billing server: Stripe Checkout, portal, webhook → Firestore (Cloudflare Worker, free tier) | `billing-worker/`, setup in [`docs/STRIPE.md`](docs/STRIPE.md) |
| Account & privacy: data export, email/password, deletion | `app/lib/account/`, `app/lib/services/data_export.dart` |
| Privacy policy, terms, account deletion pages | `app/web/*.html` |
| Store launch checklist | [`docs/LAUNCH.md`](docs/LAUNCH.md) |

**Business sign-up** works in the app and in the browser, in three steps: (1) business name, email and
password, (2) up to three brand colours with a live card preview, (3) the €19/month subscription. Payment
happens on the website through Stripe Checkout (card or Bancontact); the apps sell nothing and only show
the status. The dashboard only opens once the payment is confirmed; leaving halfway continues at the same
step on the next sign-in. Clients find the way in through **I have a business** on their cards page.

**How payment switches a shop on.** `subscriptions/{ownerUid}.expiresAt` must be in the future for the
dashboard to open and for tags to work (`firestore.rules` checks it on every join and stamp; clients can
always use rewards they already earned). Only `billing-worker/` writes that document (a service account).
It creates Stripe Checkout and customer-portal sessions for signed-in shops (it verifies their Firebase ID
token), and on every Stripe webhook it reads the subscription back from Stripe's API and mirrors it. Deleting
a shop's account cancels its Stripe subscription. Pilot shops and the App Review demo account get access with
`billing-worker/grant-access.js`. Local tests: `cd billing-worker && npm test` (emulators running).

**The business app** has five tabs (a sidebar on wide screens, a bottom bar on phones), all fed by one
live listener on the shop's cards (`app/lib/business/shell.dart`):

- **Overview:** stamps today and this week (vs last week), key numbers, ready-made follow-up groups and the live feed.
- **Clients:** every card holder as an anonymous code (`#K7Q2`, unique per shop, so shops can't match lists),
  with a status (new, regular, almost there, reward waiting, slipping away, haven't been back), filters,
  a visit history and CSV export. The **Messages** view holds follow-up messages.
- **Insights:** 7/30/90 days: stamps per day, new clients, rewards used, busy times (weekday × hour),
  client mix, return rate, visits per client, days between visits, and progress per card. Computed in the
  app from the log (`app/lib/business/insights/analytics.dart`); one load is capped at 5,000 stamps to stay
  inside the free Firestore quota, and shorter periods are cut from a longer one already loaded.
- **Cards** and **Settings** (logo, name, colours, appearance, subscription).

**Follow-up without personal data.** A shop writes a short message for a group ("slipping away",
"reward waiting", ...). Clients see it on their card in Loyi; their own device decides whether they're in
the group (`audiencesFor` in `app/lib/models.dart`), so the shop never learns who saw it. No email, no
push, no links (enforced by `firestore.rules`), at most two months, and clients can hide a message.
Clients can hide a message or turn off all messages from shops (Account & privacy); then they aren't even loaded.
Stamp and reward logs and cards unused for two years are deleted by the owner's app when it opens (no server on Spark).

**Privacy file.** `docs/GDPR.md` holds the record of processing, security measures, the breach procedure, the
interest assessment for messages, the store privacy answers and the owner's launch checklist. The website and web app
load nothing from third parties: the Firebase SDK, Flutter's engine and its fallback fonts are self-hosted
(`scripts/vendor-firebase-sdk.sh`, `scripts/vendor-fallback-fonts.sh`, run by `build-web.sh`), and the
Content-Security-Policy blocks Google's CDNs.

**Account & privacy (GDPR).** Shops (Account & privacy in the sidebar, or the avatar on phones) and clients (avatar on My cards) see what is
stored, download all of it as JSON (art. 15/20), change their email or password (art. 16), and delete their
account and data (art. 17). `/delete-account` explains the same for Google Play.

**Data model (Firestore)**

- `businesses/{id}`: name, `colors` (1–3 brand colours; `color` is the first), `logoVersion`, ownerUid (one business per owner in the MVP)
- `logos/{businessId}`: the logo image itself (max 200 KB, 256 px), public
- `programs/{id}`: a loyalty card: `stampsRequired`, `rewards[]` (each can be switched on or off), `stampCooldownMinutes`, `active`, and `design` (card colour, optional second colour, style `solid | gradient | pattern`, stamp colour, stamp icon). Designs are limited to colours, an icon and the logo, so the same design can later become an Apple/Google Wallet pass
- `tags/{id}`: `type: join | stamp`, linked to one program. The tag's URL is `/t/<id>`
- `cards/{programId_clientUid}`: a client's progress: `stamps`, `rewardsAvailable` (banked full cards)
- `stampEvents/{cardId}_{n}`, `redemptions/{cardId}_r{n}`: the log behind the business dashboard, deleted after 2 years
- `messages/{id}`: a shop's follow-up message: `title`, `body`, `audience`, optional `programId`, `active`, `endsAt`; public like programs
- `transfers/{anonUid}`: hand-off used when merging a device's cards into an account
- `subscriptions/{ownerUid}`: `expiresAt`, `store`, `willRenew`, `billingIssue`, `source` (`stripe` or `grant`). Written only by the billing server or `grant-access.js`
- `billing/{ownerUid}`: Stripe customer and subscription ids; only the billing server reads or writes it

**Clients** start as anonymous Firebase users (nothing to sign up for at the
counter). They can save their cards with **Google**, **Apple** or **email + password**. This
links the anonymous account, so the user id and cards stay the same. Signing
into an account that already exists (for example on a second phone) merges that
device's cards into it. Email sign-in links aren't used, because Spark allows
only 5 of those emails per day.

**Several shops, one client:** a client's cards from every shop live under the same client ID, so *My cards* shows them all. Cards with a reward ready come first. Each shop only ever sees its own clients' cards.

**Businesses** sign in with email and password, Google or Sign in with Apple; a new Google or Apple account is asked for the shop's name (with the terms) first. The native app opens on `/business`. Under *Business settings* they upload a logo and change their name and brand colours. In each card's editor they choose the card's colours, style and stamp icon, with a live preview.

## Design system ("Coral & Ink")

The app and the website share one look: the same tokens are in `app/web/site/site.css`. All app styling
lives in `app/lib/theme.dart` (colour tokens, typography, component themes) and `app/lib/widgets/ui.dart`
(shared building blocks); charts are in `app/lib/widgets/charts.dart`, without a chart package.

| Token | Light | Use |
| --- | --- | --- |
| canvas / surface | `#FFFFFF` / `#FFFFFF` | white page, white cards |
| surfaceMuted | `#F7F5F2` | warm panels that group cards |
| ink / inkMuted | `#17161C` / `#6E6A73` | text |
| accent / accentSoft | `#FF5A3C` / `#FFE9E3` | primary actions, highlights |
| sun / sunSoft | `#FFC83D` / `#FFF4D6` | rewards |
| mint / mintSoft | `#1FB57A` / `#DDF5EA` | success, stamps, switches |

- **Type:** Plus Jakarta Sans (bundled in `app/assets/fonts`, SIL OFL), semibold headings with tight tracking;
  small caps labels ("eyebrows") in JetBrains Mono (OFL).
- **Icons:** Lucide line icons, like the website (`LoyiIcons`; the font is tree-shaken to the icons used).
- **Surfaces:** white `Panel`s with a soft drop shadow, warm `Panel(muted: true)` groups, and the coral
  `CoralStage` hero with its dotted texture. Pill-shaped 52px buttons.
- **Patterns:** a coral hero with this week's stamps on the overview, the primary action in a bottom bar within thumb reach, bottom sheets for choices, a frosted app bar only where content scrolls under it, shimmering loading placeholders, a press-scale on tappable cards, haptics when a stamp lands, and confetti when a card fills up (skipped when "reduce motion" is on).
- **Dark mode:** its own palette (`LoyiPalette.dark`), not an inversion.

## Run locally (no Firebase account needed)

```bash
./scripts/build-web.sh --dart-define=USE_EMULATORS=true
firebase emulators:start --project demo-loyi
```

Then, in another terminal:

```bash
cd e2e && npm install && node seed.js   # three demo shops with a week of activity; prints logins + tag URLs
```

- Business: <http://localhost:5050/business>, sign in with `demo@loyi.test`, `mokka@loyi.test` or `lies@loyi.test` (password `demo1234`)
- Client: open the printed `/t/...` URLs, which act as tag taps
- Emulator UI (data and auth users): <http://localhost:4000>

For hot reload, run `flutter run -d chrome --dart-define=USE_EMULATORS=true` in `app/`.
On an Android emulator, add `--dart-define=EMULATOR_HOST=10.0.2.2`.

> **Emulator quirk (dev only):** in a release web build, a *full page reload*
> after a previous session can't reconnect to the Auth emulator. FlutterFire
> restores the saved user before `useAuthEmulator` runs, so the app falls back
> to production auth, which then fails with "API key not valid". Use `flutter run`
> (debug), a private window, or clear site data. Production is not affected.
> Also, `flutter build web --profile` builds hang on startup with FlutterFire web
> auth, so use a debug or release build.

## Tests

```bash
cd app && flutter test           # stamp maths, models, design, insights, follow-up groups, translations
cd e2e && npm test               # full flow + abuse attempts against firestore.rules (emulators running)
```

## Firebase project

The production project is **`loyi-b530b`** (`.firebaserc` default). The alias `demo` → `demo-loyi` is only for the local emulators.

- `app/lib/firebase_options.dart`: real project config (generated with `flutterfire configure`; the iOS entry was added from `ios/Runner/GoogleService-Info.plist`).
- `app/lib/demo_firebase_options.dart`: used when building with `--dart-define=USE_EMULATORS=true`.
- These API keys are not secrets. Access is controlled by the security rules.

Status (free Spark plan, no billing):

- [x] Android, iOS and web apps registered
- [x] Firestore `(default)` in **europe-west1**, delete protection on, rules and indexes deployed
- [x] Authentication: Anonymous and Email/Password enabled
- [x] Authentication: Google sign-in enabled ("Continue with Google" for clients and businesses). Web uses
  a popup through `loyi-b530b.firebaseapp.com`. iOS: `CLIENT_ID` in `GoogleService-Info.plist`, `iosClientId`
  in `firebase_options.dart` and its `REVERSED_CLIENT_ID` as a URL scheme in `Info.plist`. Android: the
  debug key's SHA-1/SHA-256 are registered; **add the release upload key's and Google Play's app signing
  key's fingerprints too** (`firebase apps:android:sha:create <appId> <sha>`, the Play key is under Play
  Console → Setup → App signing), then download `google-services.json` again
  (`firebase apps:sdkconfig ANDROID <appId>`)
- [ ] Authentication: Sign in with Apple is **not enabled yet** (the buttons answer "not enabled"). Needs an
  Apple Developer Services ID, key and team ID in Firebase → Authentication → Sign-in method → Apple
- [x] Hosting: live at **https://loyi-b530b.web.app**. Deploy updates with `./scripts/deploy-web.sh` (builds production, deploys, then restores the local emulator build)
- [ ] Custom domain (loyi.be) in Hosting and Auth's authorised domains; build with `--dart-define=PUBLIC_BASE_URL=https://loyi.be`

Deploy rules after changing them: `firebase deploy --only firestore`. The emulators **don't
enforce indexes**, so after adding or changing a query, add its index to
`firestore.indexes.json` and check the screen once against the real project. Never deploy to a
project whose database doesn't exist yet: firebase-tools would create it in the US
(nam5). Create it first with `firebase firestore:databases:create "(default)" --location=europe-west1`.

Spark limits to keep in mind: 50k reads / 20k writes per day, 1 GiB of Firestore
data, and 100 new accounts per hour per IP address (anonymous clients count too).

**Later, with Blaze:** Apple/Google Wallet passes need a server to sign passes. The
earlier Cloud Functions version is in git history (commit `d3a53f6`).

## Website

The page at `/` is a static website (`app/web/home.html`, `app/web/site/`) in the same Coral & Ink style:
what Loyi does, for clients and shops, features, pricing and FAQ, with **Get started** buttons that open
the app on *Create account* (`/business/login?signup=1`). `scripts/build-web.sh` builds the Flutter app and
puts the website in front of it: `index.html` is the website and the app shell is `app.html`, which
Firebase Hosting serves for every other path (`/t/…`, `/cards`, `/business`, …). Always build with that
script (or `./scripts/deploy-web.sh`), not with a bare `flutter build web`.

## Languages

Loyi speaks **Dutch (default)**, French and English. The choice is stored once (`localStorage["flutter.locale"]`)
and shared by the website and the app, so a shop that signs up from the French site gets the app in French.

- **App:** strings live in `app/lib/l10n/app_{en,nl,fr}.arb` (English is the template with the
  placeholders; Flutter generates `L10n` on build). Widgets use `context.l10n.someKey`; code without a
  `BuildContext` (services, error messages) uses the global `l10n`. Shops pick the language under
  Settings or Account & privacy, clients on their cards page and on the sign-in screen
  (`app/lib/services/language.dart`). Stripe Checkout, the billing portal and Firebase's password emails
  follow the same language. Add a string to all three ARB files; `flutter gen-l10n` warns about missing ones.
- **Website:** `app/web/home.html` is the English source. `app/web_i18n/home.json` holds the Dutch and French
  text for every piece of it, and `scripts/build-site.mjs` renders `/` (Dutch), `/fr/` and `/en/` at build
  time. The build stops when a sentence has no translation. Screenshots come from `app/web/site/img/<lang>/`
  (`cd marketing && npm run capture:all`).
- **Legal pages:** edit `app/web_i18n/legal.py` and run `python3 app/web_i18n/legal.py`; it writes
  `app/web/{privacy,terms,dpa,delete-account}.html` (Dutch) and the `fr/` and `en/` versions. `dpa` is the data
  processing agreement shops accept with the terms. The Dutch terms
  prevail if the versions differ.

## Marketing visuals

`marketing/` generates App Store / Google Play screenshots and 16:9 pitch slides
from the running app with demo data (`npm run all`). See `marketing/README.md`.

## Programming NFC tags

Use NTAG213/215 stickers. In the dashboard, open a card, add a join tag and a
stamp tag, copy the link, and write it as a **URL record** with an app like
*NFC Tools*. Join tags can also be shown as a QR code. Stamp tags deliberately
have no QR, because a visible code could be photographed and reused.

## Roadmap after the MVP

- **Apple Wallet and Google Wallet passes.** Needs an Apple Developer account (Pass Type ID certificate), a Google Wallet issuer account, and a server to sign passes (Blaze plan or another host).
- **Tamper-proof stamp tags.** NTAG 424 DNA with SUN/SDM generates a unique signed URL on every tap, so a copied link can't be replayed from home. Verifying the signature needs a server.
- Dutch and French translations (`flutter gen-l10n`).
- Several locations or staff accounts per business, and a staff redeem-confirm screen.
- One Loyi account holding the cards from every shop (the long-term vision). The `cards` model already supports this.
