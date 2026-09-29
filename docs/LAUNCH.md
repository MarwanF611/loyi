# Launch checklist

Everything that has to happen outside the code before Loyi for business can go
into the App Store and Google Play. Work top to bottom: later steps need keys
from earlier ones.

## 0. Accounts and costs

| Account | Cost | Notes |
| --- | --- | --- |
| Apple Developer Program | $99 / year | Individual, or organization (needs a free D-U-N-S number; the store then shows your company name). Enroll in the **App Store Small Business Program** so Apple takes 15% instead of 30%. |
| Google Play Console | $25 once | **Personal accounts must run a closed test with at least 12 testers for 14 days** before they can publish to production. Organization accounts (D-U-N-S) skip this. Google takes 15% on subscriptions. |
| RevenueCat | Free up to $2.5k revenue / month | Then 1% of revenue. |
| Stripe | Free account | Only for payments in the browser (RevenueCat Web Billing): about 1.5% + €0.25 per EU card payment. |
| Cloudflare | Free | Runs the billing webhook (`billing-worker/`). |
| Firebase | Free (Spark) | No change. |

Store prices include VAT. For €19 excl. VAT a Belgian shop pays €22.99 incl. 21%
VAT; after the store's 15% and VAT you receive about €16. Pick the price point
in App Store Connect / Play Console accordingly.

## 1. Legal details

Fill in the **[bracketed]** parts of `app/web/privacy.html` and `app/web/terms.html`
(company or your name, address, KBO/BCE number, court district) and set a
support address you actually read (`support@loyi.be` is used in both pages and in
`app/config/prod.json` → `SUPPORT_EMAIL`). These are a solid starting point, not
legal advice: have them checked once.

## 2. App Store Connect

1. **Certificates, Identifiers & Profiles → Identifiers**: App ID `be.loyi.loyi` with
   **Sign in with Apple** and **In-App Purchase** enabled.
2. **App Store Connect → Apps → +**: bundle ID `be.loyi.loyi`, name e.g. "Loyi for Business"
   (the plain name "Loyi" may be taken), category Business.
3. **Subscriptions**: subscription group "Loyi", product ID **`loyi_business_monthly`**,
   duration 1 month, price (see above), a display name and description.
4. **Users and Access → Integrations → In-App Purchase**: create an In-App Purchase key
   (.p8) for RevenueCat.
5. **App Privacy**: Email address, User ID, Purchase history, Photos (the logo), Other
   user content. All *linked to the user*, *not used for tracking*, purpose *App
   functionality*. This matches `ios/Runner/PrivacyInfo.xcprivacy`.
6. **Privacy policy URL**: `https://loyi-b530b.web.app/privacy`.
   **License agreement**: keep Apple's standard EULA (the terms link to it).
7. **App Review information** → sign-in required: a demo business account with access
   (step 7). Notes for the reviewer, for example:
   > Loyi for Business lets shops run digital stamp cards. Clients never install an app:
   > they tap an NFC tag in the shop, which opens a web page. To try it without NFC,
   > open a tag link (shown under Loyalty cards → a card → NFC tags → copy) in Safari.
   > The demo account already has an active subscription. The subscription itself can be
   > tested with a sandbox account on the Subscription screen.
8. Screenshots: 6.9" iPhone (required). The app also runs on iPad, so 13" iPad
   screenshots are required too (`marketing/` can produce both).

## 3. Google Play Console

1. Create the upload key and `android/key.properties` (see `android/key.properties.example`):
   ```bash
   keytool -genkey -v -keystore ~/loyi-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Back up the `.jks` file and its password; use **Play App Signing**.
2. Create the app (package `be.loyi.loyi`), free, category Business, target audience 18+,
   no ads.
3. **Monetize → Subscriptions**: product **`loyi_business_monthly`** with a monthly
   auto-renewing base plan.
4. **Data safety**: same data as the Apple list; data is encrypted in transit; users can
   request deletion.
5. **Account deletion URL**: `https://loyi-b530b.web.app/delete-account`.
   **Privacy policy**: `https://loyi-b530b.web.app/privacy`.
6. Google Cloud: a service account with the Play Console *financial data* permissions
   for RevenueCat (RevenueCat's guide walks through it).
7. Upload a build to **closed testing** first (see the 12-tester rule above).

## 4. RevenueCat

1. Create a project with an **App Store** app (bundle ID, In-App Purchase key from 2.4)
   and a **Play Store** app (package name, service account from 3.6).
2. **Entitlement** `business`; attach `loyi_business_monthly` from both stores.
3. **Offering** `default` (current) with a **Monthly** package containing both products.
4. Copy the public SDK keys (`appl_…`, `goog_…`) into `app/config/prod.json`.
5. **Web Billing (required: shops can sign up and pay in the browser).** Create a free
   Stripe account, connect it under RevenueCat → Web Billing, create a monthly web
   product, add it to the `business` entitlement and the `default` offering, and put
   the `rcb_…` key in `REVENUECAT_WEB_KEY`. Stripe handles cards and Bancontact; the
   website's security policy already allows Stripe's checkout. Test the whole browser
   sign-up once in Stripe's test mode before going live.
6. Integrations → **Webhooks** (after step 5): URL
   `https://loyi-billing.<your-subdomain>.workers.dev/revenuecat`, and an Authorization
   header value you make up, e.g. `Bearer <long random string>`.
7. Copy the **secret API key** (`sk_…`, v1) for the Worker.

## 5. Billing Worker (Cloudflare)

1. Google Cloud console for `loyi-b530b` → IAM → Service accounts → create
   `loyi-billing` with the role **Cloud Datastore User** → Keys → add a JSON key.
2. Deploy:
   ```bash
   cd billing-worker
   npx wrangler@4 login
   npx wrangler@4 secret put REVENUECAT_WEBHOOK_AUTH     # the exact header value from 4.6
   npx wrangler@4 secret put REVENUECAT_SECRET_KEY       # sk_… from 4.7
   npx wrangler@4 secret put FIREBASE_SERVICE_ACCOUNT < ~/loyi-billing-key.json
   npm run deploy
   ```
3. In RevenueCat, **Send test event** on the webhook: it should return 200.
4. Delete the downloaded key file after `secret put`, or keep it somewhere safe for
   `grant-access.js`.

## 6. Firebase console

1. **Authentication → Sign-in method → Apple**: enable. For the iOS app nothing else is
   needed. For the website and Android also create a **Services ID** and a **Sign in with
   Apple key** in the Apple Developer portal, enter them here, and add the return URL
   `https://loyi-b530b.firebaseapp.com/__/auth/handler` to the Services ID.
2. **Deploy the new rules** once the Worker works, because from then on tags only work for
   subscribed businesses:
   ```bash
   firebase deploy --only firestore --project loyi-b530b
   ```
3. **App Check**: register the iOS app (DeviceCheck key from the Apple portal), the
   Android app (Play Integrity) and the web app (create a reCAPTCHA v3 key and put its
   site key in `APP_CHECK_WEB_KEY`). Watch the App Check metrics for a week after launch;
   when almost all requests are verified, **Enforce** for Cloud Firestore and
   Authentication.

## 7. Access for App Review and pilot shops

Create the review account in the app (email + password), copy its UID from Firebase
Authentication, then:

```bash
cd billing-worker
GOOGLE_SERVICE_ACCOUNT=~/loyi-billing-key.json node grant-access.js <uid> 365
```

A grant is never shortened by a purchase or expiry webhook; run it with `0` days to end it.

## 8. Build and submit

```bash
cd app
flutter build ipa --release --dart-define-from-file=config/prod.json        # upload with Transporter or Xcode
flutter build appbundle --release --dart-define-from-file=config/prod.json  # upload to Play Console
cd .. && ./scripts/deploy-web.sh                                            # website with the same keys
```

Bump `version:` in `app/pubspec.yaml` (e.g. `1.0.1+2`) for every upload.

## What the reviewers check (and where it's handled)

| Rule | Where |
| --- | --- |
| Account deletion in the app (Apple 5.1.1(v), Google Play), also before paying | Account & privacy (avatar on the dashboard and on every sign-up step); client account page |
| Data access, export and correction (GDPR) | Account & privacy: download my data, change email/password |
| Web page to request deletion (Google Play) | `/delete-account` |
| Sign in with Apple when other sign-in providers are offered (Apple 4.8) | Business login and client save page |
| Revoke Apple tokens on account deletion | `AuthService.deleteAccount` |
| Subscriptions through in-app purchase (Apple 3.1.1, Google Play billing) | RevenueCat, `lib/business/subscribe_page.dart` |
| Price, period, auto-renew terms, restore, privacy + terms links on the paywall (Apple 3.1.2) | `subscribe_page.dart` |
| Privacy manifest, photo library purpose string, export compliance | `ios/Runner/PrivacyInfo.xcprivacy`, `Info.plist` |
| Demo account for review (Apple 2.1) | Step 7 |
| Release signed with your own key (Google Play) | `android/key.properties` |
