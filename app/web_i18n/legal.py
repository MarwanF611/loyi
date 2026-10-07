"""The legal pages in Dutch (default), French and English. Edit here, then run
`python3 app/web_i18n/legal.py` to regenerate app/web/{,fr/,en/}<page>.html.
Keep the three languages saying the same thing; the Dutch text is the reference
for Belgian users. [Placeholders] still need the owner's details before launch."""
from legal_shell import write

UPDATED = {'nl': '7 oktober 2026', 'fr': '7 octobre 2026', 'en': '7 October 2026'}

# ── Privacy policy ─────────────────────────────────────────────────────────────

PRIVACY = {
'en': ('Privacy policy', 'How Loyi handles the data of shops and their clients.', f'''
  <h1>Privacy policy</h1>
  <p class="updated">Last updated: {UPDATED['en']}</p>

  <p>Loyi gives shops digital stamp cards. Clients tap an NFC tag in the shop and collect stamps in their
    browser, without installing an app. This policy explains what data Loyi uses, why, and what you can do about it.
    It covers the Loyi website (loyi-b530b.web.app) and the Loyi for business app on iPhone and Android.</p>

  <h2>Who is responsible</h2>
  <p>Loyi is run by <strong>[company name or your full name]</strong>, <strong>[street, postcode, city]</strong>,
    Belgium, <strong>[company number (KBO/BCE), if you have one]</strong>. Contact:
    <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>
  <p>For the loyalty programme of a shop (its cards, rewards and which clients collect stamps), the shop and Loyi
    each use the data for their own part: Loyi to run the service, the shop to run its programme.</p>

  <h2>Clients (people collecting stamps)</h2>
  <div class="card">
    <ul>
      <li><strong>Without an account:</strong> a random, anonymous ID stored in your browser. We don't know your name,
        email or phone number.</li>
      <li><strong>Your cards:</strong> for each shop, your stamps, rewards you earned and used, and when you tapped a
        tag (date and time). The shop sees this under a short code that only works in that shop, never your name or
        email.</li>
      <li><strong>Messages from shops:</strong> a shop can write a short message for a group of its card holders, such
        as "reward waiting" or "not seen in a month". Your own phone checks whether a message is meant for you, using
        your card. Neither the shop nor Loyi learns who saw it. Messages are shown only inside Loyi (no email, no push)
        and you can hide them.</li>
      <li><strong>If you save your cards to an account:</strong> your email address, or the email and name Apple or
        Google share with us when you use "Continue with Apple / Google". Apple can hide your real email.</li>
    </ul>
  </div>

  <h2>Shops (Loyi for business)</h2>
  <div class="card">
    <ul>
      <li>Account: email address (or your Apple ID's email when you use Sign in with Apple).</li>
      <li>Shop details you enter: name, brand colours, logo, loyalty cards, rewards and NFC tags.</li>
      <li>Activity: stamps given and rewards used by your clients (with anonymous client IDs). Your dashboard,
        client list and insights are counted from this; each client appears as a code that only works in your shop.</li>
      <li>Follow-up messages you write for your card holders. They must not contain personal data or links.</li>
      <li>Subscription: whether it is active, when it renews and how you pay. Payments are handled by Stripe;
        we never see your card or bank details.</li>
    </ul>
  </div>

  <h2>Why we use it</h2>
  <ul>
    <li>To provide Loyi: keep your cards and stamps, run a shop's programme and dashboard (contract, GDPR art.
      6(1)(b)).</li>
    <li>To keep Loyi safe: prevent fake stamps, abuse and fraud (legitimate interest, art. 6(1)(f)).</li>
    <li>To handle subscriptions and invoices, and meet legal obligations such as accounting (art. 6(1)(b) and (c)).</li>
  </ul>
  <p>We don't sell data, don't show ads and don't track you across other apps or websites. There are no
    advertising or analytics cookies.</p>

  <h2>Service providers</h2>
  <p>We use these providers to run Loyi. They process data only on our instructions:</p>
  <ul>
    <li><strong>Google Firebase</strong> (Google Ireland / Google LLC): accounts, the database (stored in Belgium,
      europe-west1) and hosting. Firebase Authentication can process data in the United States.</li>
    <li><strong>Stripe</strong> (Ireland / United States): takes payments for subscriptions bought on the
      website.</li>
    <li><strong>Apple</strong> and <strong>Google</strong>: Sign in with Apple and Google sign-in.</li>
    <li><strong>Cloudflare</strong>: runs the small service that switches a shop's tags on after payment.</li>
  </ul>
  <p>Transfers outside the EU are covered by the EU–US Data Privacy Framework or the European Commission's
    standard contractual clauses.</p>

  <h2>Browser storage</h2>
  <p>The website stores your anonymous ID, your sign-in session and your choice of language and appearance in your
    browser (local storage), because Loyi can't work without it. It is not used for tracking, so no cookie banner is
    needed.</p>

  <h2>How long we keep data</h2>
  <ul>
    <li>Your account and cards: until you delete them.</li>
    <li>When a shop deletes its account, its cards, tags and all its clients' stamps for that shop are deleted.</li>
    <li>Stamp and reward history of a shop (under anonymous IDs): deleted automatically after 2 years, or earlier when
      the shop deletes its account.</li>
    <li>Invoices and subscription records: as long as Belgian accounting law requires (up to 7 years).</li>
    <li>You can download a copy of your data at any time under Account &amp; privacy → Download my data.</li>
  </ul>

  <h2>Your rights</h2>
  <p>You can see, download, correct and delete your data yourself under <strong>Account &amp; privacy</strong> in
    Loyi: download a copy, change your email or password, or delete your account. You can also ask us to see,
    correct, export or delete your data, or object to or restrict its use. Email
    <a href="mailto:support@loyi.be">support@loyi.be</a>. You can delete your account yourself at any time; see
    <a href="{{p}}/delete-account">Delete your account</a>. If you think we handle your data wrongly, you can complain to
    the Belgian Data Protection Authority (<a href="https://www.dataprotectionauthority.be">dataprotectionauthority.be</a>).</p>

  <h2>Children</h2>
  <p>Loyi is not meant for children under 13. Shop accounts are for adults acting for a business.</p>

  <h2>Changes</h2>
  <p>If we change this policy, we update the date at the top. For important changes we tell shops by email.</p>
'''),

'nl': ('Privacybeleid', 'Hoe Loyi omgaat met de gegevens van zaken en hun klanten.', f'''
  <h1>Privacybeleid</h1>
  <p class="updated">Laatst bijgewerkt: {UPDATED['nl']}</p>

  <p>Loyi geeft zaken digitale stempelkaarten. Klanten tikken op een NFC-tag in de winkel en sparen stempels in hun
    browser, zonder een app te installeren. Dit beleid legt uit welke gegevens Loyi gebruikt, waarom, en wat je
    eraan kunt doen. Het geldt voor de website van Loyi (loyi-b530b.web.app) en de app Loyi voor zaken op iPhone en
    Android.</p>

  <h2>Wie is verantwoordelijk</h2>
  <p>Loyi wordt uitgebaat door <strong>[bedrijfsnaam of je volledige naam]</strong>,
    <strong>[straat, postcode, gemeente]</strong>, België, <strong>[ondernemingsnummer (KBO), als je er een
    hebt]</strong>. Contact: <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>
  <p>Voor het spaarprogramma van een zaak (haar kaarten, beloningen en welke klanten stempels sparen) gebruiken de
    zaak en Loyi de gegevens elk voor hun eigen deel: Loyi om de dienst te leveren, de zaak om haar programma te
    runnen.</p>

  <h2>Klanten (wie stempels spaart)</h2>
  <div class="card">
    <ul>
      <li><strong>Zonder account:</strong> een willekeurige, anonieme ID die in je browser wordt bewaard. We kennen je
        naam, e-mailadres of telefoonnummer niet.</li>
      <li><strong>Je kaarten:</strong> per zaak je stempels, de beloningen die je verdiende en gebruikte, en wanneer je
        een tag aantikte (datum en uur). De zaak ziet dit onder een korte code die alleen in die zaak werkt, nooit je
        naam of e-mailadres.</li>
      <li><strong>Berichten van zaken:</strong> een zaak kan een kort bericht schrijven voor een groep van haar
        kaarthouders, zoals "beloning klaar" of "al een maand niet gezien". Je eigen telefoon controleert aan de hand
        van je kaart of een bericht voor jou bedoeld is. Noch de zaak noch Loyi weet wie het zag. Berichten verschijnen
        alleen in Loyi (geen e-mail, geen pushmelding) en je kunt ze verbergen.</li>
      <li><strong>Als je je kaarten in een account bewaart:</strong> je e-mailadres, of het e-mailadres en de naam die
        Apple of Google met ons delen als je "Doorgaan met Apple / Google" gebruikt. Apple kan je echte e-mailadres
        verbergen.</li>
    </ul>
  </div>

  <h2>Zaken (Loyi voor zaken)</h2>
  <div class="card">
    <ul>
      <li>Account: e-mailadres (of het e-mailadres van je Apple ID als je Inloggen met Apple gebruikt).</li>
      <li>Gegevens van je zaak die je invult: naam, huiskleuren, logo, klantenkaarten, beloningen en NFC-tags.</li>
      <li>Activiteit: gegeven stempels en gebruikte beloningen van je klanten (met anonieme klant-ID's). Je dashboard,
        klantenlijst en inzichten worden hiermee berekend; elke klant verschijnt als een code die alleen in jouw zaak
        werkt.</li>
      <li>Opvolgberichten die je voor je kaarthouders schrijft. Ze mogen geen persoonsgegevens of links bevatten.</li>
      <li>Abonnement: of het actief is, wanneer het verlengd wordt en hoe je betaalt. Betalingen lopen via Stripe; wij
        zien nooit je kaart- of bankgegevens.</li>
    </ul>
  </div>

  <h2>Waarom we ze gebruiken</h2>
  <ul>
    <li>Om Loyi te leveren: je kaarten en stempels bewaren, het programma en dashboard van een zaak laten werken
      (overeenkomst, AVG art. 6(1)(b)).</li>
    <li>Om Loyi veilig te houden: valse stempels, misbruik en fraude voorkomen (gerechtvaardigd belang, art.
      6(1)(f)).</li>
    <li>Om abonnementen en facturen af te handelen en wettelijke verplichtingen zoals de boekhouding na te komen
      (art. 6(1)(b) en (c)).</li>
  </ul>
  <p>We verkopen geen gegevens, tonen geen advertenties en volgen je niet over andere apps of websites. Er zijn geen
    advertentie- of analysecookies.</p>

  <h2>Dienstverleners</h2>
  <p>We gebruiken deze dienstverleners om Loyi te laten werken. Ze verwerken gegevens alleen volgens onze
    instructies:</p>
  <ul>
    <li><strong>Google Firebase</strong> (Google Ireland / Google LLC): accounts, de databank (opgeslagen in België,
      europe-west1) en hosting. Firebase Authentication kan gegevens in de Verenigde Staten verwerken.</li>
    <li><strong>Stripe</strong> (Ierland / Verenigde Staten): neemt de betalingen af voor abonnementen die op de
      website worden genomen.</li>
    <li><strong>Apple</strong> en <strong>Google</strong>: Inloggen met Apple en inloggen met Google.</li>
    <li><strong>Cloudflare</strong>: draait de kleine dienst die de tags van een zaak na betaling aanzet.</li>
  </ul>
  <p>Doorgiften buiten de EU vallen onder het EU-VS-kader voor gegevensbescherming (Data Privacy Framework) of de
    modelcontractbepalingen van de Europese Commissie.</p>

  <h2>Opslag in je browser</h2>
  <p>De website bewaart je anonieme ID, je inlogsessie en je keuze van taal en weergave in je browser (local
    storage), omdat Loyi zonder niet werkt. Dit wordt niet gebruikt om je te volgen, dus een cookiebanner is niet
    nodig.</p>

  <h2>Hoe lang we gegevens bewaren</h2>
  <ul>
    <li>Je account en kaarten: tot je ze verwijdert.</li>
    <li>Als een zaak haar account verwijdert, worden haar kaarten, tags en alle stempels van haar klanten bij die zaak
      verwijderd.</li>
    <li>Geschiedenis van stempels en beloningen van een zaak (onder anonieme ID's): automatisch verwijderd na 2 jaar,
      of eerder als de zaak haar account verwijdert.</li>
    <li>Facturen en abonnementsgegevens: zo lang als de Belgische boekhoudwetgeving vereist (tot 7 jaar).</li>
    <li>Je kunt altijd een kopie van je gegevens downloaden via Account &amp; privacy → Mijn gegevens downloaden.</li>
  </ul>

  <h2>Je rechten</h2>
  <p>Je kunt je gegevens zelf inkijken, downloaden, verbeteren en verwijderen onder <strong>Account &amp;
    privacy</strong> in Loyi: een kopie downloaden, je e-mailadres of wachtwoord wijzigen, of je account verwijderen.
    Je kunt ons ook vragen om je gegevens in te kijken, te verbeteren, over te dragen of te verwijderen, of bezwaar
    maken tegen of een beperking vragen van het gebruik ervan. Mail naar
    <a href="mailto:support@loyi.be">support@loyi.be</a>. Je kunt je account altijd zelf verwijderen; zie
    <a href="{{p}}/delete-account">Je account verwijderen</a>. Vind je dat we je gegevens verkeerd behandelen, dan kun je
    klacht indienen bij de Belgische Gegevensbeschermingsautoriteit
    (<a href="https://www.gegevensbeschermingsautoriteit.be">gegevensbeschermingsautoriteit.be</a>).</p>

  <h2>Kinderen</h2>
  <p>Loyi is niet bedoeld voor kinderen jonger dan 13 jaar. Accounts voor zaken zijn voor volwassenen die handelen
    voor een onderneming.</p>

  <h2>Wijzigingen</h2>
  <p>Als we dit beleid wijzigen, passen we de datum bovenaan aan. Belangrijke wijzigingen laten we zaken per e-mail
    weten.</p>
'''),

'fr': ('Politique de confidentialité', 'Comment Loyi traite les données des commerces et de leurs clients.', f'''
  <h1>Politique de confidentialité</h1>
  <p class="updated">Dernière mise à jour : {UPDATED['fr']}</p>

  <p>Loyi offre aux commerces des cartes de fidélité numériques. Les clients touchent un tag NFC dans le commerce et
    collectent des tampons dans leur navigateur, sans installer d'app. Cette politique explique quelles données Loyi
    utilise, pourquoi, et ce que vous pouvez faire. Elle couvre le site de Loyi (loyi-b530b.web.app) et l'app Loyi pour
    les commerces sur iPhone et Android.</p>

  <h2>Qui est responsable</h2>
  <p>Loyi est exploité par <strong>[nom de la société ou votre nom complet]</strong>,
    <strong>[rue, code postal, commune]</strong>, Belgique, <strong>[numéro d'entreprise (BCE), si vous en avez
    un]</strong>. Contact : <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>
  <p>Pour le programme de fidélité d'un commerce (ses cartes, ses récompenses et les clients qui collectent des
    tampons), le commerce et Loyi utilisent chacun les données pour leur propre partie : Loyi pour fournir le service,
    le commerce pour gérer son programme.</p>

  <h2>Clients (personnes qui collectent des tampons)</h2>
  <div class="card">
    <ul>
      <li><strong>Sans compte :</strong> un identifiant aléatoire et anonyme enregistré dans votre navigateur. Nous ne
        connaissons ni votre nom, ni votre e-mail, ni votre numéro de téléphone.</li>
      <li><strong>Vos cartes :</strong> pour chaque commerce, vos tampons, les récompenses gagnées et utilisées, et le
        moment où vous avez touché un tag (date et heure). Le commerce voit ces données sous un code court qui ne
        fonctionne que chez lui, jamais votre nom ni votre e-mail.</li>
      <li><strong>Messages des commerces :</strong> un commerce peut écrire un court message pour un groupe de ses
        clients, comme « récompense en attente » ou « pas vu depuis un mois ». Votre propre téléphone vérifie, à partir
        de votre carte, si un message vous est destiné. Ni le commerce ni Loyi ne savent qui l'a vu. Les messages
        n'apparaissent que dans Loyi (ni e-mail, ni notification) et vous pouvez les masquer.</li>
      <li><strong>Si vous enregistrez vos cartes dans un compte :</strong> votre adresse e-mail, ou l'e-mail et le nom
        qu'Apple ou Google nous transmettent quand vous utilisez « Continuer avec Apple / Google ». Apple peut masquer
        votre véritable e-mail.</li>
    </ul>
  </div>

  <h2>Commerces (Loyi pour les commerces)</h2>
  <div class="card">
    <ul>
      <li>Compte : adresse e-mail (ou l'e-mail de votre identifiant Apple si vous utilisez Connexion avec Apple).</li>
      <li>Informations que vous saisissez : nom, couleurs de marque, logo, cartes de fidélité, récompenses et tags
        NFC.</li>
      <li>Activité : tampons donnés et récompenses utilisées par vos clients (avec des identifiants clients anonymes).
        Votre tableau de bord, votre liste de clients et vos statistiques en sont calculés ; chaque client apparaît sous
        un code qui ne fonctionne que dans votre commerce.</li>
      <li>Les messages de suivi que vous écrivez à vos clients. Ils ne peuvent contenir ni données personnelles ni
        liens.</li>
      <li>Abonnement : s'il est actif, quand il se renouvelle et comment vous payez. Les paiements passent par Stripe ;
        nous ne voyons jamais vos données de carte ou bancaires.</li>
    </ul>
  </div>

  <h2>Pourquoi nous les utilisons</h2>
  <ul>
    <li>Pour fournir Loyi : conserver vos cartes et tampons, faire fonctionner le programme et le tableau de bord d'un
      commerce (contrat, RGPD art. 6(1)(b)).</li>
    <li>Pour la sécurité de Loyi : empêcher les faux tampons, les abus et la fraude (intérêt légitime, art.
      6(1)(f)).</li>
    <li>Pour gérer les abonnements et les factures, et respecter nos obligations légales comme la comptabilité
      (art. 6(1)(b) et (c)).</li>
  </ul>
  <p>Nous ne vendons pas de données, n'affichons pas de publicité et ne vous suivons pas sur d'autres apps ou sites.
    Il n'y a pas de cookies publicitaires ni analytiques.</p>

  <h2>Prestataires</h2>
  <p>Nous faisons appel à ces prestataires pour faire fonctionner Loyi. Ils ne traitent les données que sur nos
    instructions :</p>
  <ul>
    <li><strong>Google Firebase</strong> (Google Ireland / Google LLC) : comptes, base de données (stockée en
      Belgique, europe-west1) et hébergement. Firebase Authentication peut traiter des données aux États-Unis.</li>
    <li><strong>Stripe</strong> (Irlande / États-Unis) : encaisse les paiements des abonnements souscrits sur le
      site.</li>
    <li><strong>Apple</strong> et <strong>Google</strong> : Connexion avec Apple et connexion avec Google.</li>
    <li><strong>Cloudflare</strong> : fait tourner le petit service qui active les tags d'un commerce après
      paiement.</li>
  </ul>
  <p>Les transferts hors de l'UE sont couverts par le cadre de protection des données UE–États-Unis (Data Privacy
    Framework) ou par les clauses contractuelles types de la Commission européenne.</p>

  <h2>Stockage dans votre navigateur</h2>
  <p>Le site enregistre votre identifiant anonyme, votre session de connexion et votre choix de langue et d'apparence
    dans votre navigateur (stockage local), car Loyi ne peut pas fonctionner sans. Ce n'est pas utilisé pour vous
    suivre : aucune bannière de cookies n'est donc nécessaire.</p>

  <h2>Durée de conservation</h2>
  <ul>
    <li>Votre compte et vos cartes : jusqu'à ce que vous les supprimiez.</li>
    <li>Quand un commerce supprime son compte, ses cartes, ses tags et tous les tampons de ses clients chez lui sont
      supprimés.</li>
    <li>Historique des tampons et récompenses d'un commerce (sous identifiants anonymes) : supprimé automatiquement
      après 2 ans, ou plus tôt si le commerce supprime son compte.</li>
    <li>Factures et données d'abonnement : aussi longtemps que l'exige la législation comptable belge (jusqu'à
      7 ans).</li>
    <li>Vous pouvez télécharger une copie de vos données à tout moment via Compte et confidentialité → Télécharger mes
      données.</li>
  </ul>

  <h2>Vos droits</h2>
  <p>Vous pouvez consulter, télécharger, corriger et supprimer vos données vous-même dans <strong>Compte et
    confidentialité</strong> dans Loyi : télécharger une copie, changer votre e-mail ou votre mot de passe, ou supprimer
    votre compte. Vous pouvez aussi nous demander de consulter, corriger, transférer ou supprimer vos données, ou vous
    opposer à leur utilisation ou en demander la limitation. Écrivez à
    <a href="mailto:support@loyi.be">support@loyi.be</a>. Vous pouvez supprimer votre compte vous-même à tout moment ;
    voir <a href="{{p}}/delete-account">Supprimer votre compte</a>. Si vous pensez que nous traitons mal vos données,
    vous pouvez porter plainte auprès de l'Autorité de protection des données belge
    (<a href="https://www.autoriteprotectiondonnees.be">autoriteprotectiondonnees.be</a>).</p>

  <h2>Enfants</h2>
  <p>Loyi ne s'adresse pas aux enfants de moins de 13 ans. Les comptes commerçants sont destinés à des adultes agissant
    pour une entreprise.</p>

  <h2>Modifications</h2>
  <p>Si nous modifions cette politique, nous mettons à jour la date en haut de page. Nous informons les commerces des
    changements importants par e-mail.</p>
'''),
}

# ── Terms of use ───────────────────────────────────────────────────────────────

TERMS = {
'en': ('Terms of use', 'The terms for using Loyi, for shops and their clients.', f'''
  <h1>Terms of use</h1>
  <p class="updated">Last updated: {UPDATED['en']}</p>

  <p>These terms apply to Loyi, run by <strong>[company name or your full name]</strong>,
    <strong>[street, postcode, city]</strong>, Belgium (“Loyi”, “we”). By using Loyi you accept them.
    Contact: <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>

  <h2>1. What Loyi does</h2>
  <p>Loyi lets shops run digital stamp cards. Clients tap the shop's NFC tag (or scan its QR code), collect stamps
    in their browser and use rewards the shop offers. Shops can also show short follow-up messages on their clients'
    cards.</p>

  <h2>2. Clients</h2>
  <ul>
    <li>Using Loyi as a client is free.</li>
    <li>Rewards are offered by the shop, not by Loyi. The shop decides which rewards it offers and can change or
      stop them. Questions about a reward go to the shop.</li>
    <li>Stamps and rewards have no cash value and can't be sold or transferred.</li>
    <li>Collecting stamps without a real purchase, copying a shop's tag links or otherwise cheating is not allowed.
      Shops and Loyi may remove cards that were obtained that way.</li>
    <li>If a shop stops using Loyi, its cards stop working and are deleted.</li>
  </ul>

  <h2>3. Shops: account and subscription</h2>
  <ul>
    <li>You need an account and an active subscription to use your dashboard and for your tags to work.</li>
    <li>The subscription costs <strong>€19 per month excluding VAT</strong>. You subscribe on the Loyi website and
      pay through our payment provider Stripe, by card or Bancontact. You receive an invoice for every payment. The
      Loyi apps don't sell subscriptions.</li>
    <li><strong>It renews automatically every month</strong> until you cancel. You cancel at any time on the website
      under Settings → Subscription → Manage subscription. Deleting your Loyi account also cancels your
      subscription.</li>
    <li>After cancelling you keep access until the end of the paid period. Then your tags pause: clients can't join
      or collect stamps, but can still use rewards they already earned.</li>
    <li>Payments already made are not refunded, except where the law requires it. Contact us if you think a payment
      was wrong.</li>
    <li>If we change the price, we email you at least 30 days before it applies, and you can cancel before then.</li>
  </ul>

  <h2>4. Shops: your responsibilities</h2>
  <ul>
    <li>You honour the rewards you offer and the stamps your clients collected while your subscription was active.</li>
    <li>You keep your stamp tag behind the counter and only let clients tap it after a purchase.</li>
    <li>The content you upload (name, logo) is yours, and you may use it. You give Loyi the right to show it on your
      clients' cards.</li>
    <li>Follow-up messages are short, honest and about your shop. They contain no personal data, links, or anything
      unlawful or misleading. Loyi may remove messages that break this.</li>
    <li>You tell your clients that you use Loyi and point them to these terms and our
      <a href="{{p}}/privacy">privacy policy</a>.</li>
  </ul>

  <h2>5. Availability and liability</h2>
  <p>We work hard to keep Loyi running, but we can't promise it is never interrupted. To the extent Belgian law
    allows, Loyi is not liable for indirect damage such as lost profit or lost stamps, and our liability towards a
    shop is limited to the subscription fees it paid in the last 12 months. Nothing in these terms limits liability
    for intent or gross negligence, or rights you have as a consumer.</p>

  <h2>6. Ending</h2>
  <p>You can stop at any time by deleting your account (see <a href="{{p}}/delete-account">Delete your account</a>). We
    may suspend accounts that break these terms, for example for fraud, after warning you when possible.</p>

  <h2>7. Changes, language and law</h2>
  <p>We may update these terms; the date at the top shows the latest version, and we tell shops about important
    changes. These terms exist in Dutch, French and English; if they differ, the Dutch version applies. Belgian law
    applies. Disputes go to the courts of <strong>[your judicial district, e.g. Antwerp]</strong>, unless the law
    gives a consumer the right to go to their own court.</p>

  <h2>App Store</h2>
  <p>If you downloaded Loyi for business from Apple's App Store, Apple's
    <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Licensed Application End User License
    Agreement</a> also applies. Apple is not responsible for Loyi or its support.</p>
'''),

'nl': ('Gebruiksvoorwaarden', 'De voorwaarden om Loyi te gebruiken, voor zaken en hun klanten.', f'''
  <h1>Gebruiksvoorwaarden</h1>
  <p class="updated">Laatst bijgewerkt: {UPDATED['nl']}</p>

  <p>Deze voorwaarden gelden voor Loyi, uitgebaat door <strong>[bedrijfsnaam of je volledige naam]</strong>,
    <strong>[straat, postcode, gemeente]</strong>, België (“Loyi”, “wij”). Wie Loyi gebruikt, aanvaardt ze.
    Contact: <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>

  <h2>1. Wat Loyi doet</h2>
  <p>Met Loyi geven zaken digitale stempelkaarten. Klanten tikken op de NFC-tag van de zaak (of scannen haar QR-code),
    sparen stempels in hun browser en gebruiken de beloningen die de zaak aanbiedt. Zaken kunnen ook korte
    opvolgberichten op de kaarten van hun klanten tonen.</p>

  <h2>2. Klanten</h2>
  <ul>
    <li>Loyi gebruiken als klant is gratis.</li>
    <li>Beloningen worden aangeboden door de zaak, niet door Loyi. De zaak beslist welke beloningen ze aanbiedt en kan
      ze wijzigen of stopzetten. Met vragen over een beloning ga je naar de zaak.</li>
    <li>Stempels en beloningen hebben geen geldwaarde en kunnen niet verkocht of overgedragen worden.</li>
    <li>Stempels sparen zonder echte aankoop, de links van tags van een zaak kopiëren of op een andere manier
      sjoemelen is niet toegestaan. Zaken en Loyi mogen kaarten die zo verkregen zijn verwijderen.</li>
    <li>Als een zaak stopt met Loyi, werken haar kaarten niet meer en worden ze verwijderd.</li>
  </ul>

  <h2>3. Zaken: account en abonnement</h2>
  <ul>
    <li>Je hebt een account en een actief abonnement nodig om je dashboard te gebruiken en om je tags te laten
      werken.</li>
    <li>Het abonnement kost <strong>€19 per maand exclusief btw</strong>. Je neemt het op de website van Loyi en betaalt
      via onze betaalprovider Stripe, met kaart of Bancontact. Je krijgt een factuur voor elke betaling. De apps van
      Loyi verkopen geen abonnementen.</li>
    <li><strong>Het wordt elke maand automatisch verlengd</strong> tot je opzegt. Je zegt op wanneer je wilt via de
      website onder Instellingen → Abonnement → Abonnement beheren. Als je je Loyi-account verwijdert, wordt je
      abonnement ook stopgezet.</li>
    <li>Na het opzeggen behoud je toegang tot het einde van de betaalde periode. Daarna pauzeren je tags: klanten
      kunnen zich niet meer aanmelden of stempels sparen, maar kunnen verdiende beloningen nog gebruiken.</li>
    <li>Gedane betalingen worden niet terugbetaald, behalve als de wet het vereist. Neem contact op als je denkt dat
      een betaling niet klopt.</li>
    <li>Als we de prijs wijzigen, laten we je dat minstens 30 dagen op voorhand per e-mail weten, en kun je voordien
      opzeggen.</li>
  </ul>

  <h2>4. Zaken: jouw verantwoordelijkheden</h2>
  <ul>
    <li>Je komt de beloningen na die je aanbiedt en de stempels die je klanten spaarden terwijl je abonnement actief
      was.</li>
    <li>Je houdt je stempeltag achter de toog en laat klanten hem alleen na een aankoop aantikken.</li>
    <li>De inhoud die je uploadt (naam, logo) is van jou en je mag ze gebruiken. Je geeft Loyi het recht om ze op de
      kaarten van je klanten te tonen.</li>
    <li>Opvolgberichten zijn kort, eerlijk en gaan over je zaak. Ze bevatten geen persoonsgegevens, geen links en
      niets wat onwettig of misleidend is. Loyi mag berichten verwijderen die dat niet respecteren.</li>
    <li>Je laat je klanten weten dat je Loyi gebruikt en verwijst ze naar deze voorwaarden en ons
      <a href="{{p}}/privacy">privacybeleid</a>.</li>
  </ul>

  <h2>5. Beschikbaarheid en aansprakelijkheid</h2>
  <p>We doen er alles aan om Loyi draaiende te houden, maar we kunnen niet beloven dat het nooit onderbroken wordt.
    Voor zover de Belgische wet het toelaat, is Loyi niet aansprakelijk voor onrechtstreekse schade zoals gederfde
    winst of verloren stempels, en is onze aansprakelijkheid tegenover een zaak beperkt tot de abonnementsgelden die
    ze de laatste 12 maanden betaalde. Niets in deze voorwaarden beperkt de aansprakelijkheid voor opzet of grove fout,
    of de rechten die je als consument hebt.</p>

  <h2>6. Stoppen</h2>
  <p>Je kunt altijd stoppen door je account te verwijderen (zie <a href="{{p}}/delete-account">Je account
    verwijderen</a>). We kunnen accounts die deze voorwaarden schenden schorsen, bijvoorbeeld bij fraude, na je waar
    mogelijk te verwittigen.</p>

  <h2>7. Wijzigingen, taal en recht</h2>
  <p>We kunnen deze voorwaarden aanpassen; de datum bovenaan toont de laatste versie, en belangrijke wijzigingen
    laten we zaken weten. Deze voorwaarden bestaan in het Nederlands, Frans en Engels; bij verschillen geldt de
    Nederlandse versie. Het Belgische recht is van toepassing. Geschillen gaan naar de rechtbanken van
    <strong>[je gerechtelijk arrondissement, bv. Antwerpen]</strong>, tenzij de wet een consument het recht geeft om
    naar de eigen rechtbank te gaan.</p>

  <h2>App Store</h2>
  <p>Als je Loyi voor zaken uit de App Store van Apple hebt gedownload, geldt ook de
    <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Licensed Application End User License
    Agreement</a> van Apple. Apple is niet verantwoordelijk voor Loyi of de ondersteuning ervan.</p>
'''),

'fr': ("Conditions d'utilisation", "Les conditions d'utilisation de Loyi, pour les commerces et leurs clients.", f'''
  <h1>Conditions d'utilisation</h1>
  <p class="updated">Dernière mise à jour : {UPDATED['fr']}</p>

  <p>Ces conditions s'appliquent à Loyi, exploité par <strong>[nom de la société ou votre nom complet]</strong>,
    <strong>[rue, code postal, commune]</strong>, Belgique (« Loyi », « nous »). En utilisant Loyi, vous les acceptez.
    Contact : <a href="mailto:support@loyi.be">support@loyi.be</a>.</p>

  <h2>1. Ce que fait Loyi</h2>
  <p>Loyi permet aux commerces de proposer des cartes de fidélité numériques. Les clients touchent le tag NFC du
    commerce (ou scannent son code QR), collectent des tampons dans leur navigateur et utilisent les récompenses
    proposées par le commerce. Les commerces peuvent aussi afficher de courts messages de suivi sur les cartes de leurs
    clients.</p>

  <h2>2. Clients</h2>
  <ul>
    <li>L'utilisation de Loyi est gratuite pour les clients.</li>
    <li>Les récompenses sont offertes par le commerce, pas par Loyi. Le commerce décide des récompenses qu'il propose et
      peut les modifier ou y mettre fin. Les questions sur une récompense s'adressent au commerce.</li>
    <li>Les tampons et récompenses n'ont aucune valeur monétaire et ne peuvent être ni vendus ni cédés.</li>
    <li>Il est interdit de collecter des tampons sans achat réel, de copier les liens des tags d'un commerce ou de
      tricher de toute autre manière. Les commerces et Loyi peuvent supprimer les cartes obtenues ainsi.</li>
    <li>Si un commerce arrête d'utiliser Loyi, ses cartes cessent de fonctionner et sont supprimées.</li>
  </ul>

  <h2>3. Commerces : compte et abonnement</h2>
  <ul>
    <li>Vous avez besoin d'un compte et d'un abonnement actif pour utiliser votre tableau de bord et pour que vos tags
      fonctionnent.</li>
    <li>L'abonnement coûte <strong>19 € par mois hors TVA</strong>. Vous vous abonnez sur le site de Loyi et payez via
      notre prestataire de paiement Stripe, par carte ou Bancontact. Vous recevez une facture pour chaque paiement. Les
      apps Loyi ne vendent pas d'abonnement.</li>
    <li><strong>Il se renouvelle automatiquement chaque mois</strong> jusqu'à sa résiliation. Vous résiliez à tout
      moment sur le site via Réglages → Abonnement → Gérer l'abonnement. La suppression de votre compte Loyi résilie
      aussi votre abonnement.</li>
    <li>Après résiliation, vous gardez l'accès jusqu'à la fin de la période payée. Ensuite, vos tags se mettent en
      pause : les clients ne peuvent plus s'inscrire ni collecter de tampons, mais peuvent toujours utiliser les
      récompenses déjà gagnées.</li>
    <li>Les paiements effectués ne sont pas remboursés, sauf si la loi l'exige. Contactez-nous si vous pensez qu'un
      paiement est erroné.</li>
    <li>Si nous modifions le prix, nous vous prévenons par e-mail au moins 30 jours à l'avance, et vous pouvez résilier
      avant.</li>
  </ul>

  <h2>4. Commerces : vos responsabilités</h2>
  <ul>
    <li>Vous honorez les récompenses que vous proposez et les tampons collectés par vos clients pendant que votre
      abonnement était actif.</li>
    <li>Vous gardez votre tag tampon derrière le comptoir et ne le faites toucher qu'après un achat.</li>
    <li>Le contenu que vous importez (nom, logo) vous appartient et vous avez le droit de l'utiliser. Vous autorisez
      Loyi à l'afficher sur les cartes de vos clients.</li>
    <li>Les messages de suivi sont courts, honnêtes et concernent votre commerce. Ils ne contiennent ni données
      personnelles, ni liens, ni rien d'illégal ou de trompeur. Loyi peut supprimer les messages qui ne respectent pas
      ces règles.</li>
    <li>Vous informez vos clients que vous utilisez Loyi et les renvoyez vers ces conditions et notre
      <a href="{{p}}/privacy">politique de confidentialité</a>.</li>
  </ul>

  <h2>5. Disponibilité et responsabilité</h2>
  <p>Nous faisons tout pour que Loyi fonctionne, mais nous ne pouvons pas garantir qu'il ne soit jamais interrompu.
    Dans la mesure permise par le droit belge, Loyi n'est pas responsable des dommages indirects comme un manque à
    gagner ou des tampons perdus, et notre responsabilité envers un commerce est limitée aux frais d'abonnement payés
    au cours des 12 derniers mois. Rien dans ces conditions ne limite la responsabilité en cas de dol ou de faute
    lourde, ni les droits dont vous disposez en tant que consommateur.</p>

  <h2>6. Fin</h2>
  <p>Vous pouvez arrêter à tout moment en supprimant votre compte (voir <a href="{{p}}/delete-account">Supprimer votre
    compte</a>). Nous pouvons suspendre les comptes qui enfreignent ces conditions, par exemple en cas de fraude, après
    vous avoir prévenu lorsque c'est possible.</p>

  <h2>7. Modifications, langue et droit applicable</h2>
  <p>Nous pouvons modifier ces conditions ; la date en haut indique la dernière version, et nous informons les
    commerces des changements importants. Ces conditions existent en néerlandais, en français et en anglais ; en cas de
    divergence, la version néerlandaise prévaut. Le droit belge s'applique. Les litiges relèvent des tribunaux de
    <strong>[votre arrondissement judiciaire, p. ex. Bruxelles]</strong>, sauf si la loi permet à un consommateur de
    saisir son propre tribunal.</p>

  <h2>App Store</h2>
  <p>Si vous avez téléchargé Loyi pour les commerces sur l'App Store d'Apple, le
    <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Licensed Application End User License
    Agreement</a> d'Apple s'applique également. Apple n'est pas responsable de Loyi ni de son assistance.</p>
'''),
}

# ── Delete your account ────────────────────────────────────────────────────────

DELETE = {
'en': ('Delete your account', 'How to delete your Loyi account and data.', '''
  <h1>Delete your account</h1>
  <p class="updated">You can delete your Loyi account and data yourself, at any time.</p>

  <h2>Shops (Loyi for business)</h2>
  <div class="card">
    <ol>
      <li>Open the Loyi for business app, or <a href="/business/account">sign in on the website</a>.</li>
      <li>Open <strong>Account &amp; privacy</strong>: in the menu on the left on a computer, or with the person icon at
        the top right on a phone (also during sign-up).</li>
      <li>Tap <strong>Delete account</strong> and confirm with your password (or Apple).</li>
    </ol>
    <p>This permanently deletes your account, shop, loyalty cards, tags, logo, follow-up messages, activity history
      and your clients' stamps for your shop. Your tags stop working.</p>
    <p class="note">Deleting your account also cancels your subscription, so you won't be charged again. Invoices
      already sent stay with our payment provider Stripe, as accounting law requires.</p>
  </div>

  <h2>Clients</h2>
  <div class="card">
    <ol>
      <li>Open <a href="/account">Account &amp; privacy</a> (the person icon on your cards page) in the browser where
        you collect stamps.</li>
      <li>Tap <strong>Delete account</strong> (or <strong>Delete the cards on this device</strong> if you never saved
        your cards) and confirm.</li>
    </ol>
    <p>This permanently deletes your account, cards, stamps and rewards.</p>
  </div>

  <h2>Can't sign in?</h2>
  <p>Email <a href="mailto:support@loyi.be?subject=Delete%20my%20Loyi%20account">support@loyi.be</a> from the email
    address of your account and we delete it within 30 days. Records we must keep by law (invoices) are kept for as
    long as the law requires; everything else is deleted.</p>
'''),

'nl': ('Je account verwijderen', 'Zo verwijder je je Loyi-account en je gegevens.', '''
  <h1>Je account verwijderen</h1>
  <p class="updated">Je kunt je Loyi-account en je gegevens altijd zelf verwijderen.</p>

  <h2>Zaken (Loyi voor zaken)</h2>
  <div class="card">
    <ol>
      <li>Open de app Loyi voor zaken, of <a href="/business/account">log in op de website</a>.</li>
      <li>Open <strong>Account &amp; privacy</strong>: in het menu links op een computer, of met het persoonsicoon
        rechtsboven op een telefoon (ook tijdens het aanmelden).</li>
      <li>Tik op <strong>Account verwijderen</strong> en bevestig met je wachtwoord (of met Apple).</li>
    </ol>
    <p>Dit verwijdert definitief je account, je zaak, je klantenkaarten, tags, logo, opvolgberichten,
      activiteitengeschiedenis en de stempels van je klanten bij jouw zaak. Je tags werken niet meer.</p>
    <p class="note">Als je je account verwijdert, wordt ook je abonnement stopgezet, dus je betaalt niets meer. Al
      verstuurde facturen blijven bij onze betaalprovider Stripe, zoals de boekhoudwet vereist.</p>
  </div>

  <h2>Klanten</h2>
  <div class="card">
    <ol>
      <li>Open <a href="/account">Account &amp; privacy</a> (het persoonsicoon op je kaartenpagina) in de browser
        waarin je stempels spaart.</li>
      <li>Tik op <strong>Account verwijderen</strong> (of <strong>De kaarten op dit toestel verwijderen</strong> als je
        je kaarten nooit bewaarde) en bevestig.</li>
    </ol>
    <p>Dit verwijdert definitief je account, kaarten, stempels en beloningen.</p>
  </div>

  <h2>Kun je niet inloggen?</h2>
  <p>Mail naar <a href="mailto:support@loyi.be?subject=Mijn%20Loyi-account%20verwijderen">support@loyi.be</a> vanaf
    het e-mailadres van je account en we verwijderen het binnen 30 dagen. Gegevens die we wettelijk moeten bewaren
    (facturen) houden we zo lang als de wet vereist; al de rest wordt verwijderd.</p>
'''),

'fr': ('Supprimer votre compte', 'Comment supprimer votre compte Loyi et vos données.', '''
  <h1>Supprimer votre compte</h1>
  <p class="updated">Vous pouvez supprimer vous-même votre compte Loyi et vos données, à tout moment.</p>

  <h2>Commerces (Loyi pour les commerces)</h2>
  <div class="card">
    <ol>
      <li>Ouvrez l'app Loyi pour les commerces, ou <a href="/business/account">connectez-vous sur le site</a>.</li>
      <li>Ouvrez <strong>Compte et confidentialité</strong> : dans le menu à gauche sur ordinateur, ou avec l'icône de
        personne en haut à droite sur téléphone (aussi pendant l'inscription).</li>
      <li>Touchez <strong>Supprimer le compte</strong> et confirmez avec votre mot de passe (ou avec Apple).</li>
    </ol>
    <p>Cela supprime définitivement votre compte, votre commerce, vos cartes de fidélité, tags, logo, messages de suivi,
      historique d'activité et les tampons de vos clients chez vous. Vos tags ne fonctionneront plus.</p>
    <p class="note">La suppression de votre compte résilie aussi votre abonnement : vous ne serez plus débité. Les
      factures déjà envoyées restent chez notre prestataire de paiement Stripe, comme l'exige la loi comptable.</p>
  </div>

  <h2>Clients</h2>
  <div class="card">
    <ol>
      <li>Ouvrez <a href="/account">Compte et confidentialité</a> (l'icône de personne sur votre page de cartes) dans
        le navigateur où vous collectez vos tampons.</li>
      <li>Touchez <strong>Supprimer le compte</strong> (ou <strong>Supprimer les cartes de cet appareil</strong> si
        vous n'avez jamais enregistré vos cartes) et confirmez.</li>
    </ol>
    <p>Cela supprime définitivement votre compte, vos cartes, tampons et récompenses.</p>
  </div>

  <h2>Vous ne pouvez pas vous connecter ?</h2>
  <p>Écrivez à <a href="mailto:support@loyi.be?subject=Supprimer%20mon%20compte%20Loyi">support@loyi.be</a> depuis
    l'adresse e-mail de votre compte et nous le supprimons dans les 30 jours. Les données que la loi nous oblige à
    conserver (factures) sont gardées aussi longtemps que nécessaire ; tout le reste est supprimé.</p>
'''),
}

if __name__ == '__main__':
    for page, texts in (('privacy', PRIVACY), ('terms', TERMS), ('delete-account', DELETE)):
        for lang, (title, description, body) in texts.items():
            write(page, lang, title, description, body)
    print('legal pages written')
