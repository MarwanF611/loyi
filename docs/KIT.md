# Starter kit: secure Loyi tags

Every new shop gets two secure tags in the post. They solve two problems at once:

- **No setup work for the shop.** The shop sticks the tags on, holds a signed-in phone to each one and picks a card
  and a role (join or stamp). No NFC Tools, no links to copy.
- **No stamping from home.** A plain sticker always holds the same link, so a client can save it and stamp again after
  the waiting time. A secure tag (NXP **NTAG 424 DNA**) writes a new link at every tap, with an encrypted tap
  counter and a signature. The billing Worker checks it and refuses any link it has seen before, and firestore.rules
  only accept a stamp from a secure tag together with the one-time ticket the Worker issued for that tap.

How it fits together:

```
tap → https://<site>/k?e=<encrypted UID + counter>&c=<MAC>
    → app (KitTapPage) → Worker POST /kit-tap  (checks MAC, counter must go up)
        unknown tag + shop signed in → link form → POST /kit-link → tags/{id} with secure: true
        join tag  → normal join
        stamp tag → stampTickets/{UID}_{counter} → app stamps and spends (deletes) the ticket in one write
```

Code: `billing-worker/src/sun.js` (crypto, tested against RFC 4493 and NXP AN12196), `billing-worker/src/index.js`
(`kitTap`, `kitLink`), `firestore.rules` (`ticketOk`, `stampTickets`, `kitTags`), `app/lib/client/kit_tap_page.dart`.

## 1. Before you program any tag: the domain

The link is written into the tag for good. Program kits with the address you'll keep. Tags made now for
`loyi-b530b.web.app` keep working after a move to loyi.be (Firebase keeps serving that address), but buying the domain
first is cleaner. Change `url` in `app/web_i18n/site.json` and `APP_URL`/`ALLOWED_ORIGINS` in
`billing-worker/wrangler.toml` when you do.

## 2. Keys (once)

Generate three random AES-128 keys **in your own terminal**. Never paste them in a chat, a ticket or git.

```bash
openssl rand -hex 16   # SDM meta read key  (decrypts UID + counter)  → tag key 1
openssl rand -hex 16   # SDM file read key  (checks the MAC)          → tag key 2
openssl rand -hex 16   # app master key     (protects the settings)   → tag key 0, keep offline
```

Store them in your password manager. Give the Worker the first two:

```bash
cd billing-worker && npx wrangler@4 secret put SDM_META_KEY
```

```bash
cd billing-worker && npx wrangler@4 secret put SDM_FILE_KEY
```

Until both secrets exist, `/kit-tap` answers "Secure tags aren't available yet".

## 3. Program a tag

Buy NTAG 424 DNA stickers (about €2–3 each, e.g. 25 mm round, "on-metal" if they go on a metal till). Program them
with NXP's free tools: **TagXplorer** (Windows/macOS, needs a USB NFC reader such as an ACR1252U) or **NFC TagWriter
by NXP** on an Android phone. Settings, all for the NDEF file (file 02):

| Setting | Value |
| --- | --- |
| NDEF record | URI: `https://loyi-b530b.web.app/k?e=00000000000000000000000000000000&c=0000000000000000` |
| Secure Dynamic Messaging (SDM) | on |
| UID mirror, SDM read counter mirror | on |
| PICC data | **encrypted**, with key 1 (SDMMetaRead = 1); offset = the first `0` after `e=` |
| SDM MAC | on, with key 2 (SDMFileRead = 2); MAC offset = MAC input offset = the first `0` after `c=` (no extra data in the MAC) |
| SDM counter read access (SDMCtrRet) | none (F) |
| File access | read: free (E); write and change settings: key 0 |
| Keys | key 0 = app master key, key 1 = SDM meta read key, key 2 = SDM file read key |

Then check it: tap it with a phone, copy the link the phone opens, and run (with the keys in your terminal only):

```bash
cd billing-worker && SDM_META_KEY=… SDM_FILE_KEY=… node tools/check-tag.mjs "<link>"
```

`✓ Genuine tap` means the tag is ready. Tap twice: the counter must go up. Program all tags of a batch the same way;
each tag is told apart by its UID, so nothing in the link is shop-specific and any kit can go to any shop.

## 4. Send kits

Stripe Checkout asks new shops for a shipping address (countries in `SHIPPING_COUNTRIES`, wrangler.toml). Turn on
Stripe's email for new customers (Settings → Team and security → Email notifications → *Successful payments* and
*New customers*), then post two tags with a short card: "Hold your phone to each tag while signed in to Loyi; choose
*Stamp* for the one behind the counter." The address is in Stripe → Customers → the shop → Shipping.

Trial cost: two tags + postage is about €8 per shop, also for shops that cancel during the trial. Send kits after the
first payment instead if that becomes a problem (filter Stripe customers on status `active`).

## 5. Support

- **"This link was already used"**: someone reloaded the page or opened a saved link. Tap the tag again.
- **Tag lost or stolen**: switch it off in the dashboard (Cards → the card → the tag's switch). A new kit tag is
  linked by tapping it.
- **Tag on the wrong card**: switch it off; to reuse the same sticker, delete the tag document in the Firebase console
  (`tags/{id}`), then tap and link it again.
- Plain stickers keep working for joining. For stamping, a plain stamp tag can be saved and reused after the waiting
  time; the dashboard says so.
