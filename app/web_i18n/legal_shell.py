"""Shared frame for the legal pages (privacy, terms, delete-account) in nl/fr/en.

Run `python3 app/web_i18n/legal.py` after editing a text; it writes app/web/<page>.html
(Dutch, the default), app/web/fr/<page>.html and app/web/en/<page>.html.
"""
import os
import re

WEB = os.path.join(os.path.dirname(__file__), '..', 'web')
SITE = 'https://loyi-b530b.web.app'
PREFIX = {'nl': '', 'fr': '/fr', 'en': '/en'}
HOME = {'nl': '/', 'fr': '/fr/', 'en': '/en/'}
NAMES = {'nl': 'Nederlands', 'fr': 'Français', 'en': 'English'}
LINKS = {
    'nl': {'privacy': 'Privacybeleid', 'terms': 'Gebruiksvoorwaarden', 'dpa': 'Verwerkersovereenkomst', 'delete-account': 'Je account verwijderen', 'language': 'Taal'},
    'fr': {'privacy': 'Politique de confidentialité', 'terms': "Conditions d'utilisation", 'dpa': 'Accord de traitement des données', 'delete-account': 'Supprimer votre compte', 'language': 'Langue'},
    'en': {'privacy': 'Privacy policy', 'terms': 'Terms of use', 'dpa': 'Data processing agreement', 'delete-account': 'Delete your account', 'language': 'Language'},
}


def write(page, lang, title, description, body):
    """body uses {p} for the language prefix in internal links (e.g. {p}/privacy)."""
    p = PREFIX[lang]
    alternates = '\n'.join(
        f'  <link rel="alternate" hreflang="{l}" href="{SITE}{PREFIX[l]}/{page}">' for l in PREFIX
    )
    current = ' aria-current="true"'
    switch = ''.join(
        f'<a href="{PREFIX[l]}/{page}" data-lang="{l}" hreflang="{l}" lang="{l}"{current if l == lang else ""}>{NAMES[l]}</a>'
        for l in PREFIX
    )
    footer = ''.join(
        f'<a href="{p}/{other}">{LINKS[lang][other]}</a>' for other in ('privacy', 'terms', 'dpa', 'delete-account') if other != page
    ) + f'<a href="{HOME[lang]}">Loyi</a>'
    html = f'''<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} · Loyi</title>
  <meta name="description" content="{description}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="canonical" href="{SITE}{p}/{page}">
{alternates}
  <link rel="alternate" hreflang="x-default" href="{SITE}/{page}">
  <script src="/site/theme.js"></script>
  <script src="/site/lang.js"></script>
  <link rel="stylesheet" href="/legal.css">
</head>
<body>
<main>
  <div class="top">
    <a class="wordmark" href="{HOME[lang]}">loyi<span>.</span></a>
    <nav class="lang-links" aria-label="{LINKS[lang]['language']}">{switch}</nav>
  </div>
{body.replace('{p}', p).rstrip()}

  <footer>
    {footer}
  </footer>
</main>
</body>
</html>
'''
    if lang == 'fr':
        # French typography: a no-break space before ? ! : ; » and after «, so a sign never wraps alone.
        html = re.sub(r' ([?!:;»])', '\u00a0\\1', html).replace('« ', '«\u00a0')
    folder = WEB if lang == 'nl' else os.path.join(WEB, lang)
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, f'{page}.html'), 'w') as f:
        f.write(html)
