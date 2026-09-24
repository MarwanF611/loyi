# Loyi marketing visuals

Store screenshots and pitch visuals, generated from the real app running on the
local emulators with demo data. Regenerate them any time the app changes, for
example after the Dutch/French translation.

```bash
# 1. From the repo root: build the app for the emulators, with tag links on loyi.be
cd app && flutter build web --dart-define=USE_EMULATORS=true --dart-define=PUBLIC_BASE_URL=https://loyi.be && cd ..
firebase emulators:start --project demo-loyi

# 2. In another terminal
cd marketing && npm install
npm run all            # capture raw screens + compose everything (nl + en)
npm run compose -- nl  # only re-compose one language (after editing copy)
```

Headlines and layout live in `compose.js` (`CLIENT`, `BUSINESS`, `PITCH`). `*word*`
is highlighted in the accent colour. The demo world (shops, clients, a week of
activity) comes from `../e2e/seed.js`.

## Output (`out/<nl|en>/`)

| Folder | Size | Use |
| --- | --- | --- |
| `appstore-6.9/klant`, `appstore-6.9/zaak` | 1320×2868 JPEG | App Store, 6.9" iPhone (the required size; Apple scales it down for smaller iPhones) |
| `googleplay/klant`, `googleplay/zaak` | 1080×1920 JPEG | Google Play phone screenshots |
| `googleplay/feature-graphic.jpg` | 1024×500 JPEG | Google Play feature graphic (required) |
| `pitch/` | 3840×2160 PNG | 16:9 slides for investor and sales decks |

`klant` = client-facing screens, `zaak` = business app screens. The App Store
listing for the native business app would use `zaak`. `klant` is for a future
client app, the website and sales material.

All names, numbers and activity are **fictional demo data**. Don't present them
as real usage or traction.
