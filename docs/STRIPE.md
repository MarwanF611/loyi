# Payments with Stripe: setup and test

Shops subscribe on the website (€19/month excl. VAT) through Stripe Checkout. The
billing server in `billing-worker/` (a free Cloudflare Worker) creates the checkout
and "manage subscription" pages and turns Stripe's webhooks into
`subscriptions/{uid}` in Firestore, which the dashboard and tags follow. The apps
sell nothing; they only show the status.

Everything below runs in Stripe's **test mode**: no real money, no company details
needed. Allow about 45 minutes.

## 1. Stripe (15 min)

1. Create an account at <https://dashboard.stripe.com/register> and keep **Test mode**
   on (switch at the top right).
2. **Product catalogue → Add product**
   - Name: `Loyi for business`
   - Pricing: **Recurring**, **€19.00 EUR**, **Monthly**
   - Save, open the price and copy its ID (`price_…`).
3. **Settings → Payments → Payment methods**: make sure **Cards** and **Bancontact** are
   on. (SEPA Direct Debit also works, but its first payment takes a few days to confirm,
   so the shop waits that long for its dashboard.)
4. **Settings → Billing → Customer portal**: click **Save** (or **Activate test link**)
   once, so the "Manage subscription" page exists. Allow customers to cancel and to
   update their payment method.
5. **Settings → Business → Customer emails** (optional): turn on emails for successful
   payments and receipts.
6. **Developers → API keys**: copy the **Secret key** (`sk_test_…`). It is a password:
   never put it in the app or in git.

## 2. Firebase service key (5 min)

1. <https://console.cloud.google.com> → project **loyi-b530b** → **IAM & Admin →
   Service Accounts → Create service account**, name `loyi-billing`, role
   **Cloud Datastore User** → Done.
2. Open it → **Keys → Add key → Create new key → JSON**. Keep the downloaded file safe;
   it's a password too.

## 3. Billing server on Cloudflare (10 min)

Create a free account at <https://dash.cloudflare.com/sign-up>. Then, in the repo:

1. In `billing-worker/wrangler.toml`, set `STRIPE_PRICE_ID` to your `price_…`.
2. In a terminal:
   ```bash
   cd billing-worker
   npx wrangler@4 login
   npm run deploy
   ```
   The first deploy asks you to choose a `workers.dev` subdomain and prints the
   server's URL, e.g. `https://loyi-billing.yourname.workers.dev`.
3. Secrets (each command asks you to paste the value):
   ```bash
   npx wrangler@4 secret put STRIPE_SECRET_KEY            # sk_test_…
   npx wrangler@4 secret put FIREBASE_SERVICE_ACCOUNT < ~/Downloads/loyi-b530b-xxxxxxxx.json
   ```
4. Stripe → **Developers → Webhooks → Add endpoint**
   - URL: your server URL + `/stripe`
   - Events: `checkout.session.completed`, `checkout.session.async_payment_succeeded`,
     `checkout.session.async_payment_failed`, `customer.subscription.created`,
     `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`,
     `invoice.payment_failed`
   - Save, then **Reveal** the signing secret (`whsec_…`) and store it:
   ```bash
   npx wrangler@4 secret put STRIPE_WEBHOOK_SECRET        # whsec_…
   ```

## 4. Switch the website on (5 min)

1. In `app/config/prod.json`, set `"BILLING_API_URL"` to your server URL (no trailing `/`).
2. Deploy the website:
   ```bash
   ./scripts/deploy-web.sh
   ```
3. Deploy the database rules (from now on only paid shops' tags work):
   ```bash
   firebase deploy --only firestore --project loyi-b530b
   ```

## 5. Test with a laptop, two phones and an NFC tag

| Device | Role |
| --- | --- |
| Laptop (Chrome or Safari) | The shop |
| Phone A | Client 1 |
| Phone B | Client 2, and programs the NFC tag (install **NFC Tools**, free) |

Everything happens on <https://loyi-b530b.web.app>. Don't sign in as the shop on the
phones' browsers: the phones play clients.

1. **Sign up and pay (laptop).** Open the site → **I have a business** → Create account
   (business name, email, password) → colours → **Subscribe**. On Stripe's page pay
   with `4242 4242 4242 4242`, any future date, any CVC, any name and address.
   - ✅ You land back on Loyi, see "Payment received" for a few seconds, then the dashboard.
   - ✅ Stripe → **Customers** shows the shop with an active subscription; Firebase →
     Firestore → `subscriptions` has a document with `source: stripe`, `environment: TEST`.
2. **Create a card (laptop).** New card → name, a reward, **Time between stamps: No
   limit** (otherwise you can only stamp every 30 minutes) → Create → add a **join tag**
   and a **stamp tag**.
3. **Program the NFC tag (phone B).** On the laptop, copy the stamp tag's link and send it
   to phone B (WhatsApp/email to yourself). NFC Tools → **Write → Add a record → URL** →
   paste → **Write** → hold the phone to the tag. Never tap "Lock tag".
4. **Join with the QR code (phone A).** On the laptop, click the QR icon next to the join
   tag and scan it with phone A's camera. ✅ "Welcome!" on the phone, **Clients 1** on the
   laptop without refreshing.
5. **Collect stamps (phone A).** iPhone: unlocked, top edge to the tag, tap the banner.
   Android: NFC on, back of the phone to the tag. Repeat until the card is full.
   ✅ "Card full!", and the laptop counts along.
6. **Use the reward (phone A).** Use a reward → Use it now. ✅ Ticking-clock screen; the
   reward appears in the laptop's activity.
7. **Second client (phone B).** Tap the tag (the first tap joins and stamps). Person icon →
   save the cards with an email and password.
8. **Move cards between phones (phone A).** Person icon → **I have an account** → sign in
   with phone B's account. ✅ Phone A's stamps are added to that account.
9. **Privacy (any device).** Person icon → **Download my data**; change the password and
   sign in again with the new one.
10. **Manage the subscription (laptop).** Person icon → Subscription → **Manage
    subscription** → Stripe's page → cancel. ✅ Back in Loyi it says the subscription won't
    renew; the dashboard keeps working until the paid month ends.
11. **Subscription ended.** Simulate the end of the month: Stripe → Customers → the shop →
    the subscription → **⋯ → Cancel immediately**. ✅ Within seconds the laptop shows "Your
    subscription has ended"; tapping the tag says the cards aren't active ("your stamps
    are safe"); a reward that was already earned can still be used. Subscribe again with
    the test card to switch back on.
12. **Delete the shop (laptop).** Person icon → **Delete account** → password. ✅ Stripe shows
    the subscription cancelled; the tag no longer works.

More test cards: `4000 0000 0000 0341` (card declined on renewal),
`4000 0027 6000 3184` (asks for 3-D Secure confirmation). Bancontact in test mode shows a
page with "Authorize" / "Fail" buttons.

### When something doesn't work

- **Subscribe shows an error**: open the browser console (right-click → Inspect →
  Console) and Cloudflare → Workers → loyi-billing → **Logs**.
- **Paid, but "Payment received" keeps spinning**: Stripe → Developers → Webhooks → your
  endpoint → recent deliveries. A red delivery shows the server's answer (wrong
  `whsec_…`? missing service key?).
- Send me a screenshot with the step number.

## 6. Later: real money

1. Stripe → **Activate account**: your (company) details and bank account.
2. Recreate the product in live mode, a live webhook endpoint, and put the **live** keys
   in the server: `STRIPE_SECRET_KEY` (`sk_live_…`), `STRIPE_WEBHOOK_SECRET`, and the live
   `STRIPE_PRICE_ID` in `wrangler.toml`; `npm run deploy` again.
3. VAT: Stripe shows the price excl. VAT; decide with your accountant whether to add
   Belgian VAT (Stripe → Settings → Tax) and how to file it.
