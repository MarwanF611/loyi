# Launch checklist

Everything that has to happen outside the code before Loyi goes live. Payments
come first and work without any app store: [STRIPE.md](STRIPE.md) sets them up and
walks through a full test with real devices. The app stores are optional extras.

## 0. Accounts and costs

| Account | Cost | Notes |
| --- | --- | --- |
| Apple Developer Program | $99 / year | Individual, or organization (needs a free D-U-N-S number; the store then shows your company name). Enroll in the **App Store Small Business Program** so Apple takes 15% instead of 30%. |
| Google Play Console | $25 once | **Personal accounts must run a closed test with at least 12 testers for 14 days** before they can publish to production. Organization accounts (D-U-N-S) skip this. Google takes 15% on subscriptions. |
| Stripe | Free account | Shops pay here: about 1.5% + €0.25 per EU card payment, so about €18.50 of €19 reaches you. |
| Cloudflare | Free | Runs the billing server (`billing-worker/`). |
| Firebase | Free (Spark) | No change. |

The apps don't sell anything: shops subscribe on the website. That keeps Apple and
Google out of the payment (no 15% commission). Apple allows this for free companion
apps of a paid web service (guideline 3.1.3(f)) as long as the app has no buy
buttons and no "go pay on our website" text, which is how the app is built.

## 1. Legal details

Fill in the **[bracketed]** parts in `app/web_i18n/legal.py` (company or your name, address,
KBO/BCE number, court district), then run `python3 app/web_i18n/legal.py`. The support address
is marwan.fikri20@gmail.com until there's a domain (legal pages, home page, and
`app/config/prod.json` → `SUPPORT_EMAIL`). These are a solid starting point, not
legal advice: have them checked once.

## 2. App Store Connect

1. **Certificates, Identifiers & Profiles → Identifiers**: App ID `be.loyi.loyi` (no extra
   capabilities needed).
2. **App Store Connect → Apps → +**: bundle ID `be.loyi.loyi`, name e.g. "Loyi for Business"
   (the plain name "Loyi" may be taken), category Business.
3. **Pricing**: Free. No in-app purchases.
4. **App Privacy**: Email address, User ID, Purchase history, Photos (the logo), Other
   user content. All *linked to the user*, *not used for tracking*, purpose *App
   functionality*. This matches `ios/Runner/PrivacyInfo.xcprivacy`.
5. **Privacy policy URL**: `https://loyi-b530b.web.app/privacy`.
   **License agreement**: keep Apple's standard EULA (the terms link to it).
6. **App Review information** → sign-in required: a demo business account with access
   (step 6). Notes for the reviewer, for example:
   > Loyi for Business is a free companion app for shops that use the Loyi web service
   > (3.1.3(f)): the app sells nothing. Shops run digital stamp cards; clients never
   > install an app, they tap an NFC tag in the shop, which opens a web page. To try it
   > without NFC, open a tag link (Loyalty cards → a card → NFC tags → copy) in Safari.
   > The demo account has an active subscription.
7. Screenshots: 6.9" iPhone (required). The app also runs on iPad, so 13" iPad
   screenshots are required too (`marketing/` can produce both).

## 3. Google Play Console

1. Create the upload key and `android/key.properties` (see `android/key.properties.example`):
   ```bash
   keytool -genkey -v -keystore ~/loyi-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Back up the `.jks` file and its password; use **Play App Signing**.
2. Create the app (package `be.loyi.loyi`), free, category Business, target audience 18+,
   no ads.
3. Free app, **no in-app products**.
4. **Data safety**: same data as the Apple list; data is encrypted in transit; users can
   request deletion.
5. **Account deletion URL**: `https://loyi-b530b.web.app/delete-account`.
   **Privacy policy**: `https://loyi-b530b.web.app/privacy`.
6. Upload a build to **closed testing** first (see the 12-tester rule above).

## 4. Payments

Follow [STRIPE.md](STRIPE.md): Stripe, the Firebase service key, the Cloudflare billing
server, and a full test. It also covers switching to real money.

## 5. Firebase console

1. **Authentication → Sign-in method**: Email/Password, Anonymous and Google are enabled
   (Loyi doesn't offer Sign in with Apple).
2. **Deploy the rules** once the billing server works (STRIPE.md step 4), because from then
   on tags only work for subscribed businesses:
   ```bash
   firebase deploy --only firestore --project loyi-b530b
   ```
3. **App Check**: register the iOS app (DeviceCheck key from the Apple portal), the
   Android app (Play Integrity) and the web app (create a reCAPTCHA v3 key and put its
   site key in `APP_CHECK_WEB_KEY`). Watch the App Check metrics for a week after launch;
   when almost all requests are verified, **Enforce** for Cloud Firestore and
   Authentication.

## 6. Access for App Review and pilot shops

Create the review account in the app (email + password), copy its UID from Firebase
Authentication, then:

```bash
cd billing-worker
GOOGLE_SERVICE_ACCOUNT=~/loyi-billing-key.json node grant-access.js <uid> 365
```

A grant is never shortened by Stripe; run it with `0` days to end it.

## 7. Build and submit

```bash
cd app
flutter build ipa --release --dart-define-from-file=config/prod.json        # upload with Transporter or Xcode
flutter build appbundle --release --dart-define-from-file=config/prod.json  # upload to Play Console
cd .. && ./scripts/deploy-web.sh                                            # website with the same config
```

Bump `version:` in `app/pubspec.yaml` (e.g. `1.0.1+2`) for every upload.

## What the reviewers check (and where it's handled)

| Rule | Where |
| --- | --- |
| Account deletion in the app (Apple 5.1.1(v), Google Play), also before paying | Account & privacy (avatar on the dashboard and on every sign-up step); client account page |
| Data access, export and correction (GDPR) | Account & privacy: download my data, change email/password |
| Web page to request deletion (Google Play) | `/delete-account` |
| Login services (Apple 4.8): Loyi offers its own email + password accounts next to Google, without Sign in with Apple. If review asks for an equivalent login under 4.8, explain that every feature works with a Loyi email account, or add Sign in with Apple back | Business login |
| No purchases or purchase links in the app (Apple 3.1.1 / 3.1.3(f), Google Play payments) | `subscribe_page.dart`: Subscribe and Manage only on the website (`kIsWeb`) |
| Cancelling: deleting the account also cancels the Stripe subscription | `AuthService.deleteAccount` → billing server `/delete-account` |
| Privacy manifest, photo library purpose string, export compliance | `ios/Runner/PrivacyInfo.xcprivacy`, `Info.plist` |
| Demo account for review (Apple 2.1) | Step 6 |
| Release signed with your own key (Google Play) | `android/key.properties` |
