# GDPR file

Loyi's internal privacy records: what the GDPR expects the owner to keep on file. The texts users see are the
privacy policy, terms and data processing agreement (`app/web_i18n/legal.py`). Review this file whenever Loyi starts
processing new data, and at least once a year. This is a working document, not legal advice: have it checked once by a
privacy lawyer or DPO before launch.

## 1. Before launch: owner checklist

These need you; nothing in the code can do them.

- [ ] **Your details** in the privacy policy, terms and data processing agreement: company name (or your full name),
  address, company number (KBO/BCE) and the court district. Edit `app/web_i18n/legal.py` (search for `[`), run
  `python3 app/web_i18n/legal.py`, then `./scripts/deploy-web.sh`.
- [ ] **Accept the providers' data processing terms:**
  - Google (Firebase): Firebase console → Project settings → General → *Data processing terms* / Google Cloud console →
    IAM & Admin → Settings → *Data processing terms*. Also fill in the EU representative and DPO contact fields there if
    asked.
  - Cloudflare (billing server): dashboard → Manage account → Configurations → *Data Processing Addendum*.
  - Stripe: the DPA is part of the Stripe Services Agreement; nothing to sign.
- [ ] **Store privacy forms** (section 6 below has the answers).
- [ ] **Read and keep this file up to date** (sections 2–5), and store a copy with your business records.
- [ ] **Support mailbox** support@loyi.be must exist and be read: it's where people send privacy requests (answer within
  one month).

## 2. Record of processing activities (art. 30)

Controller: Loyi, [company name, address, company number], support@loyi.be. No DPO is required (no large-scale
monitoring or special categories), but name one contact person: [you].

| Processing | Purpose | People | Data | Legal basis | Retention | Recipients |
| --- | --- | --- | --- | --- | --- | --- |
| Client cards (Loyi as controller) | Keep a client's cards across shops and devices, prevent fraud | Clients | Pseudonymous ID; optional email (or Apple/Google ID); cards, stamps, rewards, tap times | Contract (6(1)(b)); fraud prevention: legitimate interest (6(1)(f)) | Until the client deletes the account; cards unused 2 years are deleted | Google (Firebase) |
| Shop loyalty programmes (Loyi as **processor** for each shop) | Run the shop's programme, dashboard, client list, insights | Clients of that shop | Pseudonymous ID per shop, cards, stamps, rewards, tap times | The shop's; see the data processing agreement | Logs 2 years, unused cards 2 years, everything when the shop leaves | Google (Firebase) |
| Follow-up messages (shop as controller, Loyi as processor) | Show a shop's message to a group of its clients | Clients of that shop | Card data, matched on the client's own device | Shop's legitimate interest (6(1)(f)), direct marketing with opt-out (21(2)) | Message until its end date (max. 2 months) | None (matching happens on the device) |
| Shop accounts | Provide the business app | Shop owners | Email, shop name, colours, logo, cards, tags, messages | Contract (6(1)(b)) | Until the shop deletes its account | Google (Firebase) |
| Subscriptions and invoices | Billing | Shop owners | Email, billing address, VAT number, payment status (card details stay with Stripe) | Contract (6(1)(b)); accounting law (6(1)(c)) | Invoices 7 years (Belgian accounting law) | Stripe, Cloudflare (billing server) |
| Hosting logs | Deliver the site, protect it from abuse | Visitors | IP address, browser, requested page | Legitimate interest (6(1)(f)) | Google's short default log retention | Google (Firebase Hosting) |
| Support emails | Answer questions and privacy requests | Anyone who writes | Email and its content | Legitimate interest / legal obligation for rights requests | As long as needed for the request, then delete | Your email provider |

Transfers outside the EU: Firebase Authentication and Stripe can process data in the US, covered by the EU–US Data
Privacy Framework and standard contractual clauses. The database itself is in Belgium (europe-west1).

## 3. Technical and organisational measures (art. 32)

- Clients are pseudonymous; each shop sees a different code per client (`clientCode`), so shops can't match lists.
- Shops never receive names, emails or phone numbers of clients. No free-text notes about people.
- Every database write is checked by `firestore.rules`, tested in `e2e/flow.test.js` (including attacks).
- Follow-up messages: no links allowed (enforced by the rules), max. 2 months, matched on the client's device; clients
  can hide one message or turn all of them off (then they aren't even loaded).
- Retention runs automatically: stamp and reward logs and unused cards are deleted after 2 years
  (`Repo.applyRetention`, run when a shop opens the app).
- No third-party content on the site or in the web app: the Firebase SDK, Flutter's engine and its fallback fonts are
  served from our own hosting (`scripts/vendor-firebase-sdk.sh`, `scripts/vendor-fallback-fonts.sh`), and the
  Content-Security-Policy in `firebase.json` blocks Google's CDNs. Google/Apple sign-in pages open only when chosen.
  If you ever turn on App Check for the web (reCAPTCHA), that adds a Google request: update the privacy policy first.
- Self-service rights: download (JSON), change email/password, delete account (also cancels Stripe).
- HTTPS everywhere; secrets (Stripe, service account) only in the billing server's environment, never in the app or git.
- Access: only the owner has access to the Firebase, Stripe and Cloudflare consoles; use two-factor authentication on
  all three.

## 4. Legitimate interest assessment: follow-up messages

- **Purpose:** a shop wants to invite back clients who stopped coming, remind them of a waiting reward, or welcome new
  ones. That's a real and lawful interest (recital 47 names direct marketing).
- **Necessity:** the message only works if it reaches the right group. Loyi does this with the least data possible: the
  group is worked out on the client's own phone from the card it already has; nobody learns who received it, and no
  contact details are needed.
- **Balance:** clients expect messages from a shop whose card they carry, inside that card. The impact is low: no
  email, no push, no profiling beyond the card itself, no data leaves the device. Clients can hide a message or turn
  all of them off at any time, and that stops the processing completely.
- **Outcome:** legitimate interest (6(1)(f)) is an appropriate basis, with the absolute right to object (21(2))
  built in.

## 5. Data breach procedure (art. 33–34)

1. **Contain** (stop the leak: rotate keys, tighten rules, disable an account) and write down what happened, when, which
   data and how many people.
2. **Assess the risk** for the people concerned. Pseudonymous card data alone is usually low risk; emails, billing
   data or a leak of the service account key is not.
3. **Within 72 hours** of becoming aware: notify the Belgian Data Protection Authority
   (gegevensbeschermingsautoriteit.be → "Datalek melden") unless the breach is unlikely to cause any risk.
4. **Shops:** if their clients' data is involved, inform the affected shops within 48 hours (data processing
   agreement, section 7).
5. **People:** if the risk is high, inform them directly in clear language.
6. **Log every breach**, even small ones, with the decisions taken (keep a simple list next to this file).

A data protection impact assessment (DPIA, art. 35) is not required: no large-scale monitoring, no special categories,
no automated decisions with legal effect. Re-check this if Loyi adds location, push notifications or anything that
identifies clients.

## 6. Store privacy forms

**App Store – App Privacy** (the native app is for shops; clients use the website):

- Contact info → Email address: *App Functionality*, linked to the user, not used for tracking.
- User content → Other user content (shop name, logo, cards, messages): *App Functionality*, linked, no tracking.
- Identifiers → User ID: *App Functionality*, linked, no tracking.
- Usage data, location, health, financial info, browsing history: **not collected** (payments happen on the website
  through Stripe, not in the app).
- Tracking: **No**.

**Google Play – Data safety:**

- Data collected: Email address; User IDs; Other in-app content (shop details, cards, messages). Purpose: App
  functionality, Account management. Not shared with third parties (service providers don't count as sharing).
- Encrypted in transit: Yes. Users can request deletion: Yes (in the app and at /delete-account).
- No data shared for advertising; no location; no financial info collected in the app.
