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
| Save cards (Google, email + password) and merge devices | `app/lib/services/auth_service.dart` |
| Stamp maths (pure, unit tested; mirrored in the rules) | `app/lib/services/stamping.dart` |
| Security rules | `firestore.rules` |
| End-to-end rules tests, plus demo seed data | `e2e/` |

**Data model (Firestore)**

- `businesses/{id}`: name, brand colour, `logoVersion`, ownerUid (one business per owner in the MVP)
- `logos/{businessId}`: the logo image itself (max 200 KB, 256 px), public
- `programs/{id}`: a loyalty card: `stampsRequired`, `rewards[]` (each can be switched on or off), `stampCooldownMinutes`, `active`, and `design` (card colour, optional second colour, style `solid | gradient | pattern`, stamp colour, stamp icon). Designs are limited to colours, an icon and the logo, so the same design can later become an Apple/Google Wallet pass
- `tags/{id}`: `type: join | stamp`, linked to one program. The tag's URL is `/t/<id>`
- `cards/{programId_clientUid}`: a client's progress: `stamps`, `rewardsAvailable` (banked full cards)
- `stampEvents/{cardId}_{n}`, `redemptions/{cardId}_r{n}`: the log behind the business dashboard
- `transfers/{anonUid}`: hand-off used when merging a device's cards into an account

**Clients** start as anonymous Firebase users (nothing to sign up for at the
counter). They can save their cards with **Google** or **email + password**. This
links the anonymous account, so the user id and cards stay the same. Signing
into an account that already exists (for example on a second phone) merges that
device's cards into it. Email sign-in links aren't used, because Spark allows
only 5 of those emails per day.

**Several shops, one client:** a client's cards from every shop live under the same client ID, so *My cards* shows them all. Cards with a reward ready come first. Each shop only ever sees its own clients' cards.

**Businesses** sign in with email and password. The native app opens on `/business`. Under *Business settings* they upload a logo and pick a brand colour. In each card's editor they choose the card's colours, style and stamp icon, with a live preview.

## Design system ("Coral & Ink")

All styling lives in `app/lib/theme.dart` (colour tokens, typography, component themes) and
`app/lib/widgets/ui.dart` (shared building blocks).

| Token | Light | Use |
| --- | --- | --- |
| canvas / surface | `#F7F5F2` / `#FFFFFF` | warm off-white page, white panels |
| ink / inkMuted | `#17161C` / `#6E6A73` | text |
| accent / accentSoft | `#FF5A3C` / `#FFE9E3` | primary actions, highlights |
| sun / sunSoft | `#FFC83D` / `#FFF4D6` | rewards |
| mint / mintSoft | `#1FB57A` / `#DDF5EA` | success, stamps, switches |

- **Type:** Plus Jakarta Sans (bundled in `app/assets/fonts`, SIL OFL), bold headings with tight tracking.
- **Surfaces:** white `Panel`s with soft layered shadows instead of Material's tinted elevation. Pill-shaped 56px buttons.
- **Patterns:** a bento grid on the dashboard, the primary action in a bottom bar within thumb reach, bottom sheets for choices, a frosted app bar only where content scrolls under it, shimmering loading placeholders, a press-scale on tappable cards, haptics when a stamp lands, and confetti when a card fills up (skipped when "reduce motion" is on).
- **Dark mode:** its own palette (`LoyiPalette.dark`), not an inversion.

## Run locally (no Firebase account needed)

```bash
cd app && flutter build web --dart-define=USE_EMULATORS=true && cd ..
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
cd app && flutter test           # stamp maths, models, design
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
- [ ] Authentication: enable **Anonymous**, **Email/Password** and **Google** sign-in in the console
- [ ] Hosting: `cd app && flutter build web && cd .. && firebase deploy --only hosting`
- [ ] Custom domain (loyi.be) in Hosting and Auth's authorised domains; build with `--dart-define=PUBLIC_BASE_URL=https://loyi.be`

Deploy rules after changing them: `firebase deploy --only firestore`. Never deploy to a
project whose database doesn't exist yet: firebase-tools would create it in the US
(nam5). Create it first with `firebase firestore:databases:create "(default)" --location=europe-west1`.

Spark limits to keep in mind: 50k reads / 20k writes per day, 1 GiB of Firestore
data, and 100 new accounts per hour per IP address (anonymous clients count too).

**Later, with Blaze:** Apple/Google Wallet passes need a server to sign passes. The
earlier Cloud Functions version is in git history (commit `d3a53f6`).

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
