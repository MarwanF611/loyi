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
| Security rules | `firestore.rules` |
| End-to-end tests against the emulators, plus demo seed data | `e2e/` |

**Data model (Firestore)**

- `businesses/{id}`: name, colour, ownerUid (one business per owner in the MVP)
- `programs/{id}`: a loyalty card: `stampsRequired`, `rewards[]` (each can be switched on or off), `stampCooldownMinutes`, `active`
- `tags/{id}`: `type: join | stamp`, linked to one program. The tag's URL is `/t/<id>`
- `cards/{programId_clientUid}`: a client's progress: `stamps`, `rewardsAvailable` (banked full cards)
- `stampEvents`, `redemptions`: the log behind the business dashboard

**Clients** start as anonymous Firebase users (nothing to sign up for at the
counter). They can add an email magic link from the card page. If they then sign
in on another phone, `mergeAccount` combines the stamps from both devices.

**Businesses** sign in with email and password. The native app opens on `/business`.

## Run locally (no Firebase account needed)

```bash
cd functions && npm install && npm run build && cd ..
cd app && flutter build web --dart-define=USE_EMULATORS=true && cd ..
firebase emulators:start --project demo-loyi
```

Then, in another terminal:

```bash
cd e2e && npm install && node seed.js   # prints a demo login + tag URLs
```

- Business: <http://localhost:5050/business>, sign in with `demo@loyi.test` / `demo1234`
- Client: open the printed `/t/...` URLs, which act as tag taps
- Emulator UI (data, auth users, email links): <http://localhost:4000>

For hot reload, run `flutter run -d chrome --dart-define=USE_EMULATORS=true` in `app/`.
On an Android emulator, add `--dart-define=EMULATOR_HOST=10.0.2.2`.

> **Emulator quirk (dev only):** in a release web build, a *full page reload*
> after a previous session can't reconnect to the Auth emulator. FlutterFire
> restores the saved user before `useAuthEmulator` runs, so the app falls back
> to production auth, which then fails with "API key not valid". Use `flutter run`
> (debug), a private window, or clear site data. Production is not affected.

## Tests

```bash
cd functions && npm test         # stamp maths unit tests
cd app && flutter test           # model tests
cd e2e && npm test               # full flow + security rules, needs emulators running
```

## Deploy (when ready)

1. Create a Firebase project (Blaze plan, required for Functions), with Firestore in `europe-west1`.
2. Enable **Authentication → Anonymous**, **Email/Password** and **Email link** sign-in.
3. `flutterfire configure --project=<id>` in `app/` (this regenerates `firebase_options.dart`), and set the project in `.firebaserc`.
4. `cd app && flutter build web` then `firebase deploy`.
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
