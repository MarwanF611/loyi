# Loyi

Digital stamp cards for small businesses in Belgium. A client taps an NFC tag in
the shop, the card opens in the browser (no app to install), and every purchase
earns a stamp. When a card is full, the client chooses which of the shop's
current rewards to use, now or on a later visit.

## How it works

```
 Join tag (door/counter) ──tap──▶ https://<host>/t/<tagId> ──▶ card created
 Stamp tag (behind counter) ─tap─▶ https://<host>/t/<tagId> ──▶ +1 stamp
                                            │
                           Flutter Web ─────┴──▶ Cloud Function `tap` (only place stamps change)
```

| Piece | Where |
| --- | --- |
| Flutter app: business app (iOS/Android/web) and client pages (web) | `app/` |
| Cloud Functions: `tap`, `redeem`, `mergeAccount` (europe-west1) | `functions/src/index.ts` |
| Stamp maths (pure, unit tested) | `functions/src/stamping.ts` |
| Security rules | `firestore.rules`, `storage.rules` |
| End-to-end tests against the emulators, plus demo seed data | `e2e/` |

**Data model (Firestore)**

- `businesses/{id}`: name, brand colour, `logoUrl`, ownerUid (one business per owner in the MVP). Logos are stored in Storage under `logos/{businessId}/`
- `programs/{id}`: a loyalty card: `stampsRequired`, `rewards[]` (each can be switched on or off), `stampCooldownMinutes`, `active`, and `design` (card colour, optional second colour, style `solid | gradient | pattern`, stamp colour, stamp icon). Designs are limited to colours, an icon and the logo, so the same design can later become an Apple/Google Wallet pass
- `tags/{id}`: `type: join | stamp`, linked to one program. The tag's URL is `/t/<id>`
- `cards/{programId_clientUid}`: a client's progress: `stamps`, `rewardsAvailable` (banked full cards)
- `stampEvents`, `redemptions`: the log behind the business dashboard

**Clients** start as anonymous Firebase users (nothing to sign up for at the
counter). They can add an email magic link from the card page. If they then sign
in on another phone, `mergeAccount` combines the stamps from both devices.

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
cd functions && npm install && npm run build && cd ..
cd app && flutter build web --dart-define=USE_EMULATORS=true && cd ..
firebase emulators:start --project demo-loyi
```

Then, in another terminal:

```bash
cd e2e && npm install && node seed.js   # two branded demo shops; prints logins + tag URLs
```

- Business: <http://localhost:5050/business>, sign in with `demo@loyi.test` or `mokka@loyi.test` (password `demo1234`)
- Client: open the printed `/t/...` URLs, which act as tag taps
- Emulator UI (data, auth users, email links): <http://localhost:4000>

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
cd functions && npm test         # stamp maths unit tests
cd app && flutter test           # model tests
cd e2e && npm test               # full flow + security rules, needs emulators running
```

## Deploy (when ready)

1. Create a Firebase project (Blaze plan, required for Functions), with Firestore in `europe-west1`.
2. Enable **Authentication → Anonymous**, **Email/Password** and **Email link** sign-in, and enable **Storage**.
3. `flutterfire configure --project=<id>` in `app/` (this regenerates `firebase_options.dart`), and set the project in `.firebaserc`.
4. `cd app && flutter build web` then `firebase deploy`.
   Allow the web app to load logos from the bucket: `gsutil cors set cors.json gs://<bucket>` (edit the origins in `cors.json` first).
5. Add the hosting domain (e.g. `loyi.be`) to Auth's authorised domains and point the tags at it.

## Programming NFC tags

Use NTAG213/215 stickers. In the dashboard, open a card, add a join tag and a
stamp tag, copy the link, and write it as a **URL record** with an app like
*NFC Tools*. Join tags can also be shown as a QR code. Stamp tags deliberately
have no QR, because a visible code could be photographed and reused.

## Roadmap after the MVP

- **Apple Wallet and Google Wallet passes.** Needs an Apple Developer account (Pass Type ID certificate) and a Google Wallet issuer account. Add `pass` endpoints in Functions, and push updates on every stamp.
- **Tamper-proof stamp tags.** NTAG 424 DNA with SUN/SDM generates a unique signed URL on every tap, so a copied link can't be replayed from home. Verify the CMAC in `tap`.
- Dutch and French translations (`flutter gen-l10n`).
- Several locations or staff accounts per business, and a staff redeem-confirm screen.
- One Loyi account holding the cards from every shop (the long-term vision). The `cards` model already supports this.
