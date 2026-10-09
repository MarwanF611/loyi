// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class L10nNl extends L10n {
  L10nNl([String locale = 'nl']) : super(locale);

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get saved => 'Opgeslagen';

  @override
  String get continueAction => 'Doorgaan';

  @override
  String get done => 'Klaar';

  @override
  String get delete => 'Verwijderen';

  @override
  String get edit => 'Bewerken';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get termsOfUse => 'Gebruiksvoorwaarden';

  @override
  String get wrongPassword => 'Verkeerd wachtwoord.';

  @override
  String get confirmSameAccount =>
      'Bevestig met hetzelfde account waarmee je bent ingelogd.';

  @override
  String get tooManyAttempts =>
      'Te veel pogingen. Probeer het over een paar minuten opnieuw.';

  @override
  String get couldNotDeleteAccount => 'Je account kon niet worden verwijderd.';

  @override
  String get deleteAccountQuestion => 'Account verwijderen?';

  @override
  String get deleteAccountBusinessBody =>
      'Je zaak, haar klantenkaarten en tags, de stempels van je klanten bij jouw zaak en je activiteitengeschiedenis worden definitief verwijderd. Je tags werken niet meer.';

  @override
  String get deleteAccountClientBody =>
      'Je bewaarde kaarten, stempels en beloningen worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get deleteAccountSubscriptionNote =>
      'Je abonnement wordt ook stopgezet, dus je betaalt niets meer.';

  @override
  String get yourPassword => 'Je wachtwoord';

  @override
  String get confirmWithGoogle => 'Je bevestigt met Google.';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get customColour => 'Eigen kleur';

  @override
  String get hexCode => 'Hexcode';

  @override
  String get hexCodeHint => 'Gebruik 6 hextekens, bv. E8553D';

  @override
  String get use => 'Gebruiken';

  @override
  String colourNumber(int number) {
    return 'kleur $number';
  }

  @override
  String get cardsLiveInBrowser =>
      'Je kaarten staan alleen in deze browser. Voeg je e-mailadres toe om ze te bewaren op een nieuwe telefoon of als je Loyi opent vanaf je beginscherm.';

  @override
  String get shopNoLongerUsesLoyi => 'Deze zaak gebruikt Loyi niet meer.';

  @override
  String get messageTitlePlaceholder => 'Je titel';

  @override
  String get messageBodyPlaceholder => 'Je bericht';

  @override
  String get hideThisMessage => 'Dit bericht verbergen';

  @override
  String get couldNotLoadBusiness => 'Je zaak kon niet worden geladen.';

  @override
  String get stampsPerWeekdayAndHour => 'Stempels per weekdag en uur';

  @override
  String get couldNotCancelSubscription =>
      'We konden je abonnement niet stopzetten, dus er is niets verwijderd. Controleer je verbinding en probeer opnieuw.';

  @override
  String get light => 'Licht';

  @override
  String get dark => 'Donker';

  @override
  String get device => 'Toestel';

  @override
  String get tagNotActive => 'Deze tag is niet actief.';

  @override
  String get cardPaused => 'Deze klantenkaart is gepauzeerd.';

  @override
  String get cardNotFound => 'Kaart niet gevonden.';

  @override
  String get noFullCardYet => 'Nog geen volle kaart om in te wisselen.';

  @override
  String get rewardNoLongerAvailable =>
      'Deze beloning is niet meer beschikbaar.';

  @override
  String get noConnection =>
      'Geen verbinding. Controleer je internet en probeer opnieuw.';

  @override
  String get somethingWentWrong => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get signInFirst => 'Log eerst in.';

  @override
  String get logoWrongType => 'Gebruik een PNG-, JPG- of WebP-afbeelding.';

  @override
  String get logoTooBig => 'Het logo moet kleiner zijn dan 200 KB.';

  @override
  String exportAbout(Object url) {
    return 'Je gegevens in Loyi. Wat ze betekenen en wat je rechten zijn: $url';
  }

  @override
  String get exportBusinessNote =>
      'Klanten staan er alleen in als anonieme ID\'s. Je logo zit er niet in.';

  @override
  String get accountAndPrivacy => 'Account & privacy';

  @override
  String get accountDeleted => 'Je account is verwijderd.';

  @override
  String get language => 'Taal';

  @override
  String dontLoseCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verlies je $count kaarten niet',
      one: 'Verlies je stempels niet',
    );
    return '$_temp0';
  }

  @override
  String get noPermission => 'Je hebt geen toestemming om dat te doen.';

  @override
  String get shopNotActive =>
      'De Loyi-kaarten van deze zaak zijn nu niet actief. Je stempels blijven bewaard.';

  @override
  String get signInAgain => 'Log opnieuw in.';

  @override
  String get onlyBusinessCanSubscribe =>
      'Alleen zakelijke accounts kunnen een abonnement nemen.';

  @override
  String get alreadySubscribed => 'Je hebt al een abonnement.';

  @override
  String get noSubscriptionToManage =>
      'Er is nog geen abonnement om te beheren.';

  @override
  String get audienceAll => 'Iedereen';

  @override
  String get audienceAllDesc => 'Iedereen met de kaart';

  @override
  String get audienceNew => 'Nieuwe klanten';

  @override
  String get audienceNewDesc => 'Begonnen in de laatste 14 dagen';

  @override
  String get audienceAlmost => 'Bijna zover';

  @override
  String get audienceAlmostDesc => '1 of 2 stempels van een beloning';

  @override
  String get audienceReward => 'Beloning klaar';

  @override
  String get audienceRewardDesc =>
      'Hebben een beloning die ze nog niet gebruikten';

  @override
  String get audienceSlipping => 'Dreigen af te haken';

  @override
  String get audienceSlippingDesc => 'Laatste bezoek 30 tot 90 dagen geleden';

  @override
  String get audienceLost => 'Niet meer teruggekomen';

  @override
  String get audienceLostDesc => 'Meer dan 90 dagen geen bezoek';

  @override
  String get statusReward => 'Beloning klaar';

  @override
  String get statusNew => 'Nieuw';

  @override
  String get statusAlmost => 'Bijna zover';

  @override
  String get statusRegular => 'Vaste klant';

  @override
  String get statusOccasional => 'Af en toe';

  @override
  String get statusSlipping => 'Haakt af';

  @override
  String get statusLost => 'Niet meer gezien';

  @override
  String get stampIconCheck => 'Vinkje';

  @override
  String get stampIconStar => 'Ster';

  @override
  String get stampIconHeart => 'Hart';

  @override
  String get stampIconCoffee => 'Koffie';

  @override
  String get stampIconBakery => 'Bakkerij';

  @override
  String get stampIconSandwich => 'Broodje';

  @override
  String get stampIconPizza => 'Pizza';

  @override
  String get stampIconIceCream => 'IJsje';

  @override
  String get stampIconCake => 'Taart';

  @override
  String get stampIconDrink => 'Drankje';

  @override
  String get stampIconHair => 'Kapper';

  @override
  String get stampIconBeauty => 'Schoonheid';

  @override
  String get stampIconFlowers => 'Bloemen';

  @override
  String get stampIconPets => 'Dieren';

  @override
  String get stampIconCarWash => 'Carwash';

  @override
  String get stampIconShopping => 'Winkelen';

  @override
  String get enterBusinessName => 'Vul de naam van je zaak in.';

  @override
  String get chooseOneColour => 'Kies minstens één kleur.';

  @override
  String get businessName => 'Naam van je zaak';

  @override
  String get businessNameHint => 'bv. Bakkerij Peeters';

  @override
  String get brandColours => 'Huiskleuren';

  @override
  String brandColoursHint(int max) {
    return 'Maximaal $max. Nieuwe kaarten krijgen deze kleuren.';
  }

  @override
  String get cardColour => 'Kaartkleur';

  @override
  String get style => 'Stijl';

  @override
  String get styleSolid => 'Effen';

  @override
  String get styleGradient => 'Verloop';

  @override
  String get stylePattern => 'Patroon';

  @override
  String get secondColour => 'Tweede kleur';

  @override
  String get auto => 'Automatisch';

  @override
  String get stampColour => 'Stempelkleur';

  @override
  String get stampIcon => 'Stempelicoon';

  @override
  String get tabOverview => 'Overzicht';

  @override
  String get tabClients => 'Klanten';

  @override
  String get tabInsights => 'Inzichten';

  @override
  String get tabCards => 'Kaarten';

  @override
  String get tabSettings => 'Instellingen';

  @override
  String get goodMorning => 'Goedemorgen';

  @override
  String get goodAfternoon => 'Goedemiddag';

  @override
  String get goodEvening => 'Goedenavond';

  @override
  String get newMessage => 'Nieuw bericht';

  @override
  String get followUp => 'Opvolging';

  @override
  String get whoToReachOut => 'Wie je kunt opvolgen';

  @override
  String get whoToReachOutSub =>
      'De groepen werken zichzelf bij. Je bericht verschijnt op hun kaart in Loyi.';

  @override
  String get addYourLogo => 'Voeg je logo toe';

  @override
  String get addYourLogoSub => 'Het staat op elke kaart van je klanten.';

  @override
  String get live => 'Live';

  @override
  String get recentActivity => 'Recente activiteit';

  @override
  String get allInsights => 'Alle inzichten';

  @override
  String get stampsToday => 'Stempels vandaag';

  @override
  String thisWeekCount(int count) {
    return '$count deze week';
  }

  @override
  String vsLastWeek(Object change) {
    return '$change t.o.v. vorige week';
  }

  @override
  String vsBefore(Object change) {
    return '$change t.o.v. ervoor';
  }

  @override
  String stampsLast7Days(Object values) {
    return 'Stempels per dag, laatste 7 dagen: $values';
  }

  @override
  String get kpiClients => 'Klanten';

  @override
  String kpiJoinedThisMonth(int count) {
    return '+$count deze maand';
  }

  @override
  String get kpiActive => 'Actief';

  @override
  String get kpiActiveNote => 'kwamen langs in de laatste 30 dagen';

  @override
  String get kpiRewardsWaiting => 'Beloningen klaar';

  @override
  String get kpiRewardsWaitingNote => 'verdiend, nog niet gebruikt';

  @override
  String get kpiRewardsGiven => 'Beloningen gegeven';

  @override
  String get kpiRewardsGivenNote => 'sinds je begon';

  @override
  String get pitchSlipping => 'Nodig ze terug uit met een kleine attentie.';

  @override
  String get pitchAlmost => 'Nog één bezoek en ze hebben een beloning.';

  @override
  String get pitchReward => 'Herinner ze eraan dat er een beloning klaarligt.';

  @override
  String get pitchNew => 'Heet ze welkom en leg uit hoe het werkt.';

  @override
  String get writeAMessage => 'Schrijf een bericht';

  @override
  String get message => 'Bericht';

  @override
  String get justNow => 'Zonet';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min geleden';
  }

  @override
  String todayAt(Object time) {
    return 'Vandaag $time';
  }

  @override
  String get activityEmpty =>
      'Stempels en ingewisselde beloningen verschijnen hier zodra klanten je tags aantikken.';

  @override
  String activityReward(Object title) {
    return 'Beloning: $title';
  }

  @override
  String get activityStamp => 'Stempel gegeven';

  @override
  String get csvHeader =>
      'klant,status,klant_sinds,laatste_bezoek,stempels_totaal,beloningen_klaar,beloningen_gebruikt';

  @override
  String get clientsTitle => 'Je klanten';

  @override
  String clientsSubtitle(int count) {
    return '$count met een kaart · altijd anoniem';
  }

  @override
  String get downloadCsv => 'Downloaden als CSV';

  @override
  String get newShort => 'Nieuw';

  @override
  String get messages => 'Berichten';

  @override
  String get filterAll => 'Alle';

  @override
  String get findClientHint => 'Zoek een klantcode, bv. K7Q2';

  @override
  String get clientsEmpty => 'Klanten verschijnen hier na hun eerste tik.';

  @override
  String get noClientsMatch => 'Geen klanten gevonden.';

  @override
  String showMore(int count) {
    return 'Meer tonen ($count)';
  }

  @override
  String get clientsPrivacyNote =>
      'Klanten zijn anoniem: elk heeft een code die alleen in jouw zaak werkt. Loyi deelt nooit namen, e-mailadressen of telefoonnummers, en bezoeken van meer dan 2 jaar geleden worden automatisch verwijderd.';

  @override
  String get today => 'vandaag';

  @override
  String get yesterday => 'gisteren';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String clientRowSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stempels',
      one: '1 stempel',
    );
    return '$_temp0 · laatste bezoek $when';
  }

  @override
  String get factJoined => 'Klant sinds';

  @override
  String get factLastVisit => 'Laatste bezoek';

  @override
  String get factStamps => 'Stempels';

  @override
  String get factRewardsUsed => 'Beloningen gebruikt';

  @override
  String rewardsWaitingCount(int count) {
    return '$count klaar';
  }

  @override
  String stampsOfRequired(int required, int stamps) {
    return '$stamps van $required stempels';
  }

  @override
  String get recentVisits => 'Recente bezoeken';

  @override
  String get couldNotLoadVisits => 'Bezoeken konden niet worden geladen.';

  @override
  String get noStampsYet => 'Nog geen stempels.';

  @override
  String get whyNoName =>
      'Waarom geen naam? Klanten gebruiken Loyi zonder te zeggen wie ze zijn. Bereik ze in plaats daarvan met een bericht op hun kaart.';

  @override
  String get noLinksAllowed =>
      'Links zijn niet toegestaan: daardoor lijken berichten op phishing.';

  @override
  String get messageIsLive => 'Bericht staat online';

  @override
  String get messageUpdated => 'Bericht bijgewerkt';

  @override
  String get couldNotSaveMessage =>
      'Het bericht kon niet worden opgeslagen. Probeer opnieuw.';

  @override
  String get editMessage => 'Bericht bewerken';

  @override
  String get whoSeesIt => 'Wie het ziet';

  @override
  String get card => 'Kaart';

  @override
  String get allCards => 'Alle kaarten';

  @override
  String get title => 'Titel';

  @override
  String get messageTitleHint => 'We missen je!';

  @override
  String get messageBodyHint =>
      'Toon deze kaart deze week aan de toog voor een gratis koffie bij je volgende broodje.';

  @override
  String get addShortTitle => 'Geef een korte titel.';

  @override
  String get writeYourMessage => 'Schrijf je bericht.';

  @override
  String get showItFor => 'Hoe lang tonen';

  @override
  String get oneWeek => '1 week';

  @override
  String get twoWeeks => '2 weken';

  @override
  String get oneMonth => '1 maand';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get messagePrivacyNote =>
      'Alleen zichtbaar in Loyi, nooit via e-mail of pushmelding. De telefoon van elke klant beslist zelf of het bericht voor hem bedoeld is, dus je ziet nooit wie het las.';

  @override
  String get publishMessage => 'Bericht publiceren';

  @override
  String get deleteMessageQuestion => 'Dit bericht verwijderen?';

  @override
  String get deleteMessageBody => 'Klanten zien het dan niet meer.';

  @override
  String get noMessagesYet => 'Nog geen berichten';

  @override
  String get noMessagesBody =>
      'Nodig klanten terug uit, geef wie bijna een beloning heeft een duwtje, of heet nieuwkomers welkom. Je bericht verschijnt op hun kaart in Loyi.';

  @override
  String get messageEnded => 'Afgelopen';

  @override
  String get messagePaused => 'Gepauzeerd';

  @override
  String messageEndedOn(Object date) {
    return 'afgelopen op $date';
  }

  @override
  String messageReachUntil(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bereikt nu $count klanten',
      one: 'bereikt nu 1 klant',
    );
    return '$_temp0 · tot $date';
  }

  @override
  String get messageOptions => 'Opties voor bericht';

  @override
  String get editAndRunAgain => 'Bewerken en opnieuw tonen';

  @override
  String get pause => 'Pauzeren';

  @override
  String get resume => 'Hervatten';

  @override
  String get days7 => '7 dagen';

  @override
  String get days30 => '30 dagen';

  @override
  String get days90 => '90 dagen';

  @override
  String get insightsTitle => 'Hoe je kaarten het doen';

  @override
  String get couldNotLoadInsights => 'Je inzichten konden niet worden geladen.';

  @override
  String weekTo(Object date) {
    return 'Week tot $date';
  }

  @override
  String get chartNow => 'Nu';

  @override
  String weeksAgoShort(int weeks) {
    return '${weeks}w';
  }

  @override
  String busyShop(Object count) {
    return 'Drukke zaak! Deze periode telt meer dan $count stempels, dus de grafieken tonen alleen het eerste deel. Kies een kortere periode voor exacte cijfers.';
  }

  @override
  String get kpiStamps => 'Stempels';

  @override
  String get noEarlierData => 'nog geen eerdere gegevens';

  @override
  String get kpiActiveClients => 'Actieve klanten';

  @override
  String cameBackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kwamen terug',
      one: '1 kwam terug',
    );
    return '$_temp0';
  }

  @override
  String get kpiNewClients => 'Nieuwe klanten';

  @override
  String get joinedInPeriod => 'begonnen in deze periode';

  @override
  String get kpiRewardsUsed => 'Beloningen gebruikt';

  @override
  String stillWaitingCount(int count) {
    return '$count nog niet gebruikt';
  }

  @override
  String get stampsPerDay => 'Stempels per dag';

  @override
  String get stampsAppearHere =>
      'Stempels verschijnen hier zodra klanten je tags aantikken.';

  @override
  String busiestAt(Object day, Object time) {
    return 'Drukst: $day rond $time';
  }

  @override
  String stampsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stempels',
      one: '1 stempel',
    );
    return '$_temp0';
  }

  @override
  String newClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe klanten',
      one: '1 nieuwe klant',
    );
    return '$_temp0';
  }

  @override
  String rewardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beloningen',
      one: '1 beloning',
    );
    return '$_temp0';
  }

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klanten',
      one: '1 klant',
    );
    return '$_temp0';
  }

  @override
  String stampsPerDaySemantic(int days, int total) {
    return 'Stempels per dag over de laatste $days dagen, $total in totaal';
  }

  @override
  String get perWeek => 'Per week';

  @override
  String get perDay => 'Per dag';

  @override
  String get legendNew => 'Nieuw';

  @override
  String get legendRewards => 'Beloningen';

  @override
  String newClientsSemantic(Object values) {
    return 'Nieuwe klanten: $values';
  }

  @override
  String rewardsUsedSemantic(Object values) {
    return 'Beloningen gebruikt: $values';
  }

  @override
  String get busyTimes => 'Drukke momenten';

  @override
  String get busyTimesNote =>
      'Stempels per weekdag en uur, zodat je weet wanneer je extra hulp nodig hebt.';

  @override
  String get clientMix => 'Klantenmix';

  @override
  String clientMixNote(Object count) {
    return 'Waar je $count klanten nu staan';
  }

  @override
  String get clientsWord => 'klanten';

  @override
  String get loyalty => 'Trouw';

  @override
  String get loyaltyNote => 'Hoe vaak klanten terugkomen';

  @override
  String get cameBackAfterFirst => 'Kwamen terug na hun eerste bezoek';

  @override
  String get cameBackAfterFirstHint =>
      'Klanten die minstens 30 dagen geleden begonnen';

  @override
  String get visitsPerActive => 'Bezoeken per actieve klant';

  @override
  String get inThisPeriod => 'In deze periode';

  @override
  String get daysBetweenVisits => 'Dagen tussen bezoeken';

  @override
  String get daysBetweenVisitsHint =>
      'Gemiddeld, voor klanten die meer dan eens kwamen';

  @override
  String get rewardsWaitingToUse => 'Beloningen die nog gebruikt kunnen worden';

  @override
  String get rewardsWaitingToUseHint => 'Een goede reden voor een herinnering';

  @override
  String programInsightNote(int clients, int rewards, int stamps) {
    return '$clients klanten · $stamps stempels en $rewards beloningen in deze periode. Balken: klanten per aantal verzamelde stempels.';
  }

  @override
  String stampsOfRequiredShort(int required, int stamps) {
    return '$stamps van $required stempels';
  }

  @override
  String programDistributionSemantic(Object card, Object values) {
    return 'Klanten per aantal stempels op $card: $values';
  }

  @override
  String get insightsPrivacyNote =>
      'Inzichten zijn aantallen, geen mensen: Loyi weet nooit wie je klanten zijn. Stempels en beloningen van meer dan 2 jaar geleden worden automatisch verwijderd.';

  @override
  String get seeClients => 'Bekijk klanten';

  @override
  String get loyaltyCards => 'Klantenkaarten';

  @override
  String get yourCards => 'Je kaarten';

  @override
  String get yourCardsSub =>
      'Stempels per kaart, beloningen en ontwerp. Open een kaart om haar NFC-tags te beheren.';

  @override
  String get newCard => 'Nieuwe kaart';

  @override
  String get howTagsWork => 'Zo werken de tags';

  @override
  String get howTagsWorkBody =>
      'Via de aanmeldtag aan de ingang krijgen klanten de kaart. De stempeltag aan de toog geeft één stempel per tik, met de wachttijd die jij kiest. Je kunt een tag altijd pauzeren.';

  @override
  String get createFirstCard => 'Maak je eerste klantenkaart';

  @override
  String get createFirstCardSub =>
      'Kies hoeveel stempels een kaart vullen, je beloningen en je kleuren.';

  @override
  String get paused => 'Gepauzeerd';

  @override
  String programTileSummary(int rewards, int stamps) {
    String _temp0 = intl.Intl.pluralLogic(
      rewards,
      locale: localeName,
      other: '$rewards beloningen',
      one: '1 beloning',
    );
    return '$stamps stempels · $_temp0';
  }

  @override
  String get yourShop => 'Je zaak';

  @override
  String get logo => 'Logo';

  @override
  String get logoHint =>
      'Staat op al je klantenkaarten. Een vierkante PNG met transparante achtergrond werkt het best.';

  @override
  String get details => 'Gegevens';

  @override
  String get appearance => 'Weergave';

  @override
  String get appearanceHint =>
      'Licht is standaard. Toestel volgt je telefoon of computer.';

  @override
  String get languageHint => 'Nederlands is standaard.';

  @override
  String get subscription => 'Abonnement';

  @override
  String get accountSettingsSub =>
      'E-mail, wachtwoord, je gegevens, account verwijderen';

  @override
  String get couldNotUpdateLogo =>
      'Het logo kon niet worden aangepast. Probeer opnieuw.';

  @override
  String get replaceLogo => 'Logo vervangen';

  @override
  String get uploadLogo => 'Logo uploaden';

  @override
  String get remove => 'Verwijderen';

  @override
  String get passwordTooShort =>
      'Gebruik minstens 8 tekens voor je wachtwoord.';

  @override
  String get wrongEmailOrPassword => 'Verkeerd e-mailadres of wachtwoord.';

  @override
  String get emailInUse =>
      'Er bestaat al een account met dit e-mailadres. Log in.';

  @override
  String get emailHasAccount =>
      'Dit e-mailadres heeft al een Loyi-account. Log in met je e-mailadres en wachtwoord.';

  @override
  String get invalidEmail => 'Vul een geldig e-mailadres in.';

  @override
  String get signInMethodDisabled =>
      'Deze manier van inloggen is nog niet ingeschakeld.';

  @override
  String get couldNotSignIn => 'Inloggen lukte niet.';

  @override
  String get enterEmailFirst => 'Vul eerst je e-mailadres in.';

  @override
  String resetLinkSent(Object email) {
    return 'Als $email een account heeft, is er een link onderweg om je wachtwoord opnieuw in te stellen.';
  }

  @override
  String get startWithLoyi => 'Start met Loyi';

  @override
  String get welcomeBack => 'Welkom terug';

  @override
  String get signUpSteps =>
      'Drie stappen: je account, je kleuren, je abonnement. Daarna staat je dashboard klaar.';

  @override
  String get signInSub => 'Log in om je klantenkaarten te beheren.';

  @override
  String get orWithEmail => 'of met e-mail';

  @override
  String get signIn => 'Inloggen';

  @override
  String get createAccount => 'Account maken';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Wachtwoord';

  @override
  String get hidePassword => 'Wachtwoord verbergen';

  @override
  String get showPassword => 'Wachtwoord tonen';

  @override
  String get forgotPassword => 'Wachtwoord vergeten?';

  @override
  String get agreeToTerms =>
      'Door een account te maken ga je akkoord met de gebruiksvoorwaarden, inclusief de verwerkersovereenkomst, en het privacybeleid.';

  @override
  String get continueAgreesToTerms =>
      'Door verder te gaan ga je akkoord met de gebruiksvoorwaarden, inclusief de verwerkersovereenkomst, en het privacybeleid.';

  @override
  String get collectingStamps => 'Spaar je stempels? Ga naar je kaarten';

  @override
  String get heroTitle => 'Stempelkaarten die je\nklanten echt bijhouden.';

  @override
  String get heroSub =>
      'Eén tik op een NFC-tag. Geen app te installeren. Jouw logo, jouw kleuren, jouw beloningen.';

  @override
  String get signOut => 'Uitloggen';

  @override
  String stepOf(int step, int total) {
    return 'Stap $step van $total';
  }

  @override
  String get yourBusiness => 'Je zaak';

  @override
  String get yourBusinessSub =>
      'De naam die je klanten op hun klantenkaart zien.';

  @override
  String get yourColours => 'Je kleuren';

  @override
  String yourColoursSub(int max) {
    return 'Kies er maximaal $max: de kaart, het verloop en de stempels. Je kunt elke kaart later nog bijwerken.';
  }

  @override
  String get loyaltyCard => 'Klantenkaart';

  @override
  String coloursChosen(int count, int max) {
    return '$count van $max gekozen. Tik nog eens op een kleur om ze te verwijderen.';
  }

  @override
  String get subscriptionEnded => 'Je abonnement is afgelopen';

  @override
  String get startSubscription => 'Start je abonnement';

  @override
  String get almostThere => 'Bijna klaar';

  @override
  String get tagsPausedSub =>
      'Je tags zijn gepauzeerd. Klanten houden hun stempels en kunnen verdiende beloningen nog gebruiken.';

  @override
  String get dashboardOpensWhenPaid =>
      'Je dashboard gaat open en je tags werken zodra de betaling bevestigd is. Altijd opzegbaar.';

  @override
  String get dashboardOpensWhenActive =>
      'Je dashboard gaat open zodra dit account een actief abonnement heeft.';

  @override
  String get paymentReceived => 'Betaling ontvangen';

  @override
  String get switchingOn =>
      'We zetten je account aan. Dit duurt enkele seconden.';

  @override
  String get takingLonger =>
      'Dit duurt langer dan normaal. Je dashboard gaat vanzelf open zodra de betaling bevestigd is. Verliet je de betaalpagina zonder te betalen? Ga dan terug naar de betaalstap.';

  @override
  String get backToPayment => 'Terug naar betalen';

  @override
  String get paymentProblem => 'Probleem met betaling';

  @override
  String get paymentProblemSub =>
      'Werk je betaalmethode bij zodat je tags blijven werken.';

  @override
  String get loyiForBusiness => 'Loyi voor zaken';

  @override
  String get planTagline =>
      'Digitale stempelkaarten die je klanten echt bijhouden.';

  @override
  String get perkTags => 'Je NFC-tags om aan te melden en te stempelen, actief';

  @override
  String get perkUnlimited => 'Onbeperkt klantenkaarten en beloningen';

  @override
  String get perkBrand => 'Je logo, kleuren en kaartontwerp';

  @override
  String get perkDashboard => 'Live overzicht, klantenopvolging en inzichten';

  @override
  String get perkNoInstall => 'Niets te installeren voor je klanten';

  @override
  String get youreSubscribed => 'Je bent geabonneerd';

  @override
  String get tagsLive => 'Je tags werken.';

  @override
  String tagsLiveUntil(Object date) {
    return 'Je tags werken tot $date.';
  }

  @override
  String lastPaymentFailed(Object date) {
    return 'Je laatste betaling is niet gelukt. Werk je betaalmethode bij vóór $date zodat je tags blijven werken.';
  }

  @override
  String renewsOn(Object date) {
    return 'Je tags werken. Wordt verlengd op $date.';
  }

  @override
  String wontRenew(Object date) {
    return 'Je tags werken tot $date. Het abonnement wordt niet verlengd.';
  }

  @override
  String get manageSubscription => 'Abonnement beheren';

  @override
  String get manageSubscriptionSub =>
      'Wijzig je betaalmethode, download facturen of zeg op.';

  @override
  String get switchingOnTags => 'Betaling ontvangen. We zetten je tags aan…';

  @override
  String get monthly => 'Maandelijks';

  @override
  String get perMonthExclVat => ' / maand excl. btw';

  @override
  String get cardOrBancontact => 'Kaart of Bancontact. Altijd opzegbaar.';

  @override
  String get subscribe => 'Abonneren';

  @override
  String get stripeNote =>
      'Je betaalt veilig via Stripe. Het abonnement wordt elke maand verlengd tot je opzegt; opzeggen kan altijd via Abonnement → Abonnement beheren. Je krijgt een factuur voor elke betaling.';

  @override
  String get noActiveSubscription => 'Geen actief abonnement';

  @override
  String get noActiveSubscriptionSub =>
      'Dit account heeft geen actief Loyi-abonnement.';

  @override
  String get subscriptionsNotSetUp =>
      'Abonnementen zijn niet ingesteld in deze versie.';

  @override
  String get noLimit => 'Geen limiet';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten',
      one: '1 minuut',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur',
      one: '1 uur',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String get giveCardName => 'Geef je kaart een naam.';

  @override
  String get addOneReward => 'Voeg minstens één beloning toe.';

  @override
  String get cardCreated => 'Kaart gemaakt. Voeg hieronder je NFC-tags toe.';

  @override
  String couldNotSave(Object reason) {
    return 'Opslaan lukte niet. $reason';
  }

  @override
  String get yourCardName => 'Naam van je kaart';

  @override
  String get newLoyaltyCard => 'Nieuwe klantenkaart';

  @override
  String get editLoyaltyCard => 'Klantenkaart bewerken';

  @override
  String get create => 'Maken';

  @override
  String get cardName => 'Naam van de kaart';

  @override
  String get cardNameSub =>
      'Kort en duidelijk; klanten zien het onder de naam van je zaak.';

  @override
  String get cardNameHint => 'bv. Koffiekaart';

  @override
  String get design => 'Ontwerp';

  @override
  String get stampsForFullCard => 'Stempels voor een volle kaart';

  @override
  String get stampsForFullCardSub =>
      '6 tot 10 stempels voelt haalbaar voor de meeste klanten; meer lijkt al snel te veel.';

  @override
  String get fewerStamps => 'Minder stempels';

  @override
  String get moreStamps => 'Meer stempels';

  @override
  String get rewards => 'Beloningen';

  @override
  String get rewardsSub =>
      'Klanten met een volle kaart kiezen een van de actieve beloningen. Zet beloningen altijd aan of uit, bv. elke week een andere.';

  @override
  String get rewardHint => 'bv. Gratis koffie';

  @override
  String get active => 'Actief';

  @override
  String get hiddenFromClients => 'Verborgen voor klanten';

  @override
  String get addReward => 'Beloning toevoegen';

  @override
  String get timeBetweenStamps => 'Tijd tussen stempels';

  @override
  String get timeBetweenStampsSub =>
      'De minimale wachttijd voordat dezelfde klant weer een stempel kan krijgen. Voorkomt dubbele tikken.';

  @override
  String get cardIsLive => 'Kaart is actief';

  @override
  String get cardIsLiveSub =>
      'Als de kaart gepauzeerd is, worden tikken geweigerd, maar klanten houden hun stempels.';

  @override
  String get createCard => 'Kaart maken';

  @override
  String get saveChanges => 'Wijzigingen opslaan';

  @override
  String get nfcTags => 'NFC-tags';

  @override
  String get nfcTagsSub =>
      'Elke tag is een link. Schrijf hem op een NFC-sticker.';

  @override
  String get noTagsYet =>
      'Nog geen tags. Maak één aanmeldtag en één stempeltag om te beginnen.';

  @override
  String get addJoinTag => 'Aanmeldtag toevoegen';

  @override
  String get addStampTag => 'Stempeltag toevoegen';

  @override
  String get tagStep1 => 'Aanmeldtag, waar klanten hem zien';

  @override
  String get tagStep1Sub =>
      'Aan de deur of op de toog. Wie erop tikt, krijgt de kaart.';

  @override
  String get tagStep2 => 'Stempeltag, achter de toog';

  @override
  String get tagStep2Sub =>
      'Hou hem voor na een aankoop. Elke tik geeft één stempel.';

  @override
  String get programStickers => 'Programmeer de stickers';

  @override
  String get programStickersSub =>
      'Gebruik NTAG213/215-stickers. Kopieer de link en schrijf hem als URL-record met een gratis app zoals NFC Tools.';

  @override
  String get never => 'nooit';

  @override
  String joinTagLabel(Object label) {
    return 'Aanmeldtag · $label';
  }

  @override
  String stampTagLabel(Object label) {
    return 'Stempeltag · $label';
  }

  @override
  String tapsSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tikken',
      one: '1 tik',
    );
    return '$_temp0 · laatste $when';
  }

  @override
  String get disabled => 'Uitgeschakeld';

  @override
  String get copyLink => 'Link kopiëren';

  @override
  String get linkCopied => 'Link gekopieerd';

  @override
  String get showQrCode => 'QR-code tonen';

  @override
  String get joinQrCode => 'QR-code om aan te melden';

  @override
  String get joinQrCodeSub => 'Druk hem af voor klanten zonder NFC.';

  @override
  String get defaultJoinTagLabel => 'Ingang';

  @override
  String get defaultStampTagLabel => 'Toog';

  @override
  String get newJoinTag => 'Nieuwe aanmeldtag';

  @override
  String get newStampTag => 'Nieuwe stempeltag';

  @override
  String get whereIsTag => 'Waar hangt deze tag?';

  @override
  String get methodEmailPassword => 'E-mail en wachtwoord';

  @override
  String get methodNotSaved => 'Niet bewaard (alleen deze browser)';

  @override
  String get yourAccount => 'Je account';

  @override
  String get signInMethod => 'Inlogmethode';

  @override
  String get memberSince => 'Lid sinds';

  @override
  String get signInSecurity => 'Inloggen & beveiliging';

  @override
  String get changeEmail => 'E-mailadres wijzigen';

  @override
  String get changePassword => 'Wachtwoord wijzigen';

  @override
  String noLoyiPassword(Object provider) {
    return 'Je logt in met $provider, dus er is geen Loyi-wachtwoord. Beheer je e-mailadres en beveiliging in je $provider-account.';
  }

  @override
  String get yourData => 'Je gegevens';

  @override
  String get yourDataBusiness =>
      'Loyi bewaart je account, je zaak (naam, kleuren, logo), je klantenkaarten en tags, de status van je abonnement en de stempels en beloningen van je klanten onder anonieme ID\'s.';

  @override
  String get yourDataClient =>
      'Loyi bewaart je kaarten, stempels en beloningen per zaak. Zaken zien alleen een anonieme ID, nooit je e-mailadres.';

  @override
  String get yourDataClientEmail =>
      'Loyi bewaart je kaarten, stempels en beloningen per zaak, en je e-mailadres. Zaken zien alleen een anonieme ID, nooit je e-mailadres.';

  @override
  String get readPrivacyPolicy => 'Lees het privacybeleid';

  @override
  String get deleteCardsOnDevice => 'De kaarten op dit toestel verwijderen';

  @override
  String get downloadMyData => 'Mijn gegevens downloaden';

  @override
  String get newPasswordTooShort =>
      'Gebruik minstens 8 tekens voor je nieuwe wachtwoord.';

  @override
  String get emailUsedByOther =>
      'Een ander account gebruikt dit e-mailadres al.';

  @override
  String get signInAgainRetry => 'Log opnieuw in en probeer nog eens.';

  @override
  String get thatDidntWork => 'Dat lukte niet. Probeer opnieuw.';

  @override
  String get passwordsDontMatch => 'De nieuwe wachtwoorden komen niet overeen.';

  @override
  String get passwordChanged => 'Je wachtwoord is gewijzigd.';

  @override
  String get currentPassword => 'Huidig wachtwoord';

  @override
  String get newPassword => 'Nieuw wachtwoord';

  @override
  String get repeatNewPassword => 'Herhaal nieuw wachtwoord';

  @override
  String get checkInbox => 'Kijk in je inbox';

  @override
  String emailChangeSent(Object newEmail, Object oldEmail) {
    return 'We stuurden een link naar $newEmail. Je e-mailadres verandert zodra je die opent. Tot dan log je nog in met $oldEmail.';
  }

  @override
  String get ok => 'OK';

  @override
  String get newEmail => 'Nieuw e-mailadres';

  @override
  String get sendLink => 'Link versturen';

  @override
  String ofStamps(int total) {
    return ' / $total stempels';
  }

  @override
  String toGo(int count) {
    return 'nog $count';
  }

  @override
  String cardSemantic(String business, String card, int stamps, int total) {
    return '$business, $card: $stamps van $total stempels';
  }

  @override
  String rewardsReadySuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count beloningen klaar',
      one: ', 1 beloning klaar',
    );
    return '$_temp0';
  }

  @override
  String rewardsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beloningen',
      one: '1 beloning',
    );
    return '$_temp0';
  }

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String rewardsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beloningen klaar',
      one: '1 beloning klaar',
    );
    return '$_temp0';
  }

  @override
  String get iHaveABusiness => 'Ik heb een zaak';

  @override
  String get noCardsYet => 'Nog geen kaarten';

  @override
  String get noCardsYetSub =>
      'Hou je telefoon bij een Loyi-tag in een winkel om je eerste klantenkaart te krijgen.';

  @override
  String get cardsSaved => 'Je kaarten zijn bewaard.';

  @override
  String get emailOtherMethod =>
      'Dit e-mailadres heeft al een account met een andere inlogmethode. Gebruik die.';

  @override
  String get emailHasAccountChoose =>
      'Dit e-mailadres heeft al een account. Kies \"Ik heb een account\".';

  @override
  String get passwordTooShort6 =>
      'Gebruik minstens 6 tekens voor je wachtwoord.';

  @override
  String get accountAndCardsDeleted => 'Je account en kaarten zijn verwijderd.';

  @override
  String get yourCardsAreSaved => 'Je kaarten zijn bewaard';

  @override
  String get yourCardsAreSavedSub =>
      'Log met dit account in op eender welk toestel om je kaarten te zien.';

  @override
  String get keepCardsSafe => 'Bewaar je kaarten veilig';

  @override
  String get keepCardsSafeSub =>
      'Je stempels staan in deze browser. Bewaar ze in een account en ze volgen je naar elke telefoon. Heb je al een account? Dan worden de kaarten van dit toestel eraan toegevoegd.';

  @override
  String get continueWithGoogle => 'Doorgaan met Google';

  @override
  String get newAccount => 'Nieuw account';

  @override
  String get iHaveAnAccount => 'Ik heb een account';

  @override
  String get saveMyCards => 'Mijn kaarten bewaren';

  @override
  String get addingToCard => 'We voegen het toe aan je kaart…';

  @override
  String get onlyAMoment => 'Dit duurt maar even.';

  @override
  String get thatDidntWorkTitle => 'Dat lukte niet';

  @override
  String get rewardRedeemed => 'Beloning ingewisseld';

  @override
  String redeemedAtShowStaff(Object time) {
    return 'Ingewisseld om $time · toon dit scherm aan het personeel';
  }

  @override
  String get myCards => 'Mijn kaarten';

  @override
  String get cardNotOnDevice => 'Kaart niet gevonden op dit toestel';

  @override
  String get goToMyCards => 'Naar mijn kaarten';

  @override
  String get savedOnCard => 'Bewaard op je kaart. Gebruik ze nu of later.';

  @override
  String get noRewardsNow => 'Deze zaak heeft nu geen beloningen beschikbaar.';

  @override
  String get moreToGo => 'nog te gaan';

  @override
  String get thenChooseOne => 'Kies dan een van deze';

  @override
  String get stampsCollected => 'stempels verzameld';

  @override
  String get rewardsUsedLower => 'beloningen gebruikt';

  @override
  String get useAReward => 'Beloning gebruiken';

  @override
  String get chooseYourReward => 'Kies je beloning';

  @override
  String get usesOneFullCard => 'Dit gebruikt één volle kaart.';

  @override
  String get onlyAtCounter =>
      'Doe dit alleen aan de toog. Het personeel moet het bevestigingsscherm zien.';

  @override
  String get useItNow => 'Nu gebruiken';

  @override
  String get notYet => 'Nog niet';

  @override
  String get cardFull => 'Kaart vol!';

  @override
  String get cardFullSub =>
      'Je verdiende een beloning. Gebruik ze nu of bij een volgend bezoek.';

  @override
  String get stampAdded => 'Stempel erbij';

  @override
  String get thanksForVisit => 'Bedankt voor je bezoek!';

  @override
  String get welcome => 'Welkom!';

  @override
  String get welcomeSub =>
      'Je kaart is klaar. Tik na elke aankoop op de tag aan de toog.';

  @override
  String get yourCard => 'Je kaart';

  @override
  String get alreadyHaveCard => 'Je hebt deze kaart al.';

  @override
  String get alreadyStamped => 'Al gestempeld';

  @override
  String nextStampIn(Object wait) {
    return 'Je kunt over $wait weer een stempel krijgen.';
  }

  @override
  String waitHoursMinutes(int hours, int minutes) {
    return '$hours u $minutes min';
  }

  @override
  String waitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get shopMessagesTitle => 'Berichten van zaken';

  @override
  String get shopMessagesSub =>
      'Zaken kunnen een kort bericht op je kaart tonen, bijvoorbeeld als er een beloning klaarligt. Je telefoon kiest ze op basis van je eigen kaart; zaken zien nooit wie ze leest.';

  @override
  String get showShopMessages => 'Berichten van zaken tonen';

  @override
  String get turnOffShopMessages => 'Berichten van zaken uitzetten';

  @override
  String get shopMessagesTurnedOff =>
      'Berichten van zaken staan uit. Je kunt ze weer aanzetten onder Account & privacy.';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get kitLinkUsed => 'Deze link is al gebruikt. Tik opnieuw op de tag.';

  @override
  String get notALoyiTag => 'Dit is geen Loyi-tag.';

  @override
  String get kitAlreadyLinked => 'Deze tag is al aan een kaart gekoppeld.';

  @override
  String get kitTapAgain => 'Tik opnieuw op de tag en koppel hem dan.';

  @override
  String get kitUnavailable =>
      'Beveiligde tags zijn nog niet beschikbaar. Probeer het later opnieuw.';

  @override
  String get kitNewTagTitle => 'Nieuwe Loyi-tag';

  @override
  String get kitNewTagShop =>
      'Kies de kaart en wat deze tag doet. Je kunt hem later uitzetten onder Kaarten.';

  @override
  String get kitNewTagClient =>
      'Deze tag is nog niet aan een zaak gekoppeld. Vraag het aan de toog, of probeer het later opnieuw.';

  @override
  String get kitShopSignIn =>
      'Is dit de tag van jouw zaak? Log in op deze telefoon en tik dan opnieuw op de tag.';

  @override
  String get kitCard => 'Kaart';

  @override
  String get kitNoCards =>
      'Maak eerst een klantenkaart en tik dan opnieuw op de tag.';

  @override
  String get kitLink => 'Tag koppelen';

  @override
  String get kitLinked => 'Tag gekoppeld';

  @override
  String get kitLinkedSub =>
      'Klanten kunnen er nu op tikken. Elke tik maakt een nieuwe eenmalige code, dus een opgeslagen link werkt geen tweede keer.';

  @override
  String get kitOpenCard => 'Kaart openen';

  @override
  String get tagTypeJoin => 'Aanmelden';

  @override
  String get tagTypeStamp => 'Stempel';

  @override
  String get secureTag => 'Loyi-veiligheidstag';

  @override
  String get secureTagSub =>
      'Bij elke tik een nieuwe eenmalige code: een opgeslagen of gedeelde link werkt niet.';

  @override
  String get kitHowTo => 'Tags uit je starterkit';

  @override
  String get kitHowToSub =>
      'Log in op je telefoon, hou hem tegen een kit-tag en kies deze kaart. Niets te programmeren.';

  @override
  String get ownStickers => 'Je eigen stickers';

  @override
  String get ownStickersSub =>
      'Elke NTAG213/215-sticker werkt met de links hieronder, maar een stempellink op een gewone sticker kan worden opgeslagen en na de wachttijd opnieuw gebruikt. Gebruik een kit-tag om te stempelen.';

  @override
  String trialBadge(int days) {
    return 'Eerste $days dagen gratis';
  }

  @override
  String get startTrial => 'Gratis proefperiode starten';

  @override
  String trialNote(int days, String price) {
    return 'Vandaag betaal je niets. Na $days dagen start je abonnement aan $price per maand, tenzij je eerder opzegt. We sturen je ook twee beveiligde Loyi-tags op; Stripe vraagt het adres.';
  }

  @override
  String trialUntil(String date, String price) {
    return 'Gratis proefperiode tot $date. Daarna $price per maand, tenzij je opzegt.';
  }

  @override
  String get demoTitle => 'Probeer een Loyi-kaart';

  @override
  String get demoSub =>
      'Zo zien je klanten hun kaart na een tik op je tag. Hier vervangt een knop de tag.';

  @override
  String get demoStamp => 'Tik op de stempeltag';

  @override
  String demoStamped(int left) {
    return 'Stempel erbij. Nog $left.';
  }

  @override
  String get demoFull =>
      'Kaart vol! De beloning staat klaar op de kaart van de klant.';

  @override
  String get demoAgain => 'Opnieuw beginnen';

  @override
  String get demoForShops => 'Wil je dit voor je zaak?';
}
