// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get continueAction => 'Continuer';

  @override
  String get done => 'Terminé';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get wrongPassword => 'Mot de passe incorrect.';

  @override
  String get confirmSameAccount =>
      'Confirmez avec le compte avec lequel vous êtes connecté.';

  @override
  String get tooManyAttempts =>
      'Trop de tentatives. Réessayez dans quelques minutes.';

  @override
  String get couldNotDeleteAccount => 'Votre compte n\'a pas pu être supprimé.';

  @override
  String get deleteAccountQuestion => 'Supprimer le compte ?';

  @override
  String get deleteAccountBusinessBody =>
      'Votre commerce, ses cartes de fidélité et ses tags, les tampons de vos clients chez vous et votre historique d\'activité sont définitivement supprimés. Vos tags ne fonctionneront plus.';

  @override
  String get deleteAccountClientBody =>
      'Vos cartes, tampons et récompenses sont définitivement supprimés. Cette action est irréversible.';

  @override
  String get deleteAccountSubscriptionNote =>
      'Votre abonnement est également résilié : vous ne serez plus débité.';

  @override
  String get yourPassword => 'Votre mot de passe';

  @override
  String get confirmWithGoogle => 'Vous confirmerez avec Google.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get customColour => 'Couleur personnalisée';

  @override
  String get hexCode => 'Code hexadécimal';

  @override
  String get hexCodeHint => 'Utilisez 6 caractères hexadécimaux, p. ex. E8553D';

  @override
  String get use => 'Utiliser';

  @override
  String colourNumber(int number) {
    return 'couleur $number';
  }

  @override
  String get cardsLiveInBrowser =>
      'Vos cartes ne sont enregistrées que dans ce navigateur. Ajoutez votre e-mail pour les garder sur un nouveau téléphone ou quand vous ouvrez Loyi depuis votre écran d\'accueil.';

  @override
  String get shopNoLongerUsesLoyi => 'Ce commerce n\'utilise plus Loyi.';

  @override
  String get messageTitlePlaceholder => 'Votre titre';

  @override
  String get messageBodyPlaceholder => 'Votre message';

  @override
  String get hideThisMessage => 'Masquer ce message';

  @override
  String get couldNotLoadBusiness => 'Votre commerce n\'a pas pu être chargé.';

  @override
  String get stampsPerWeekdayAndHour => 'Tampons par jour et par heure';

  @override
  String get couldNotCancelSubscription =>
      'Nous n\'avons pas pu résilier votre abonnement, rien n\'a donc été supprimé. Vérifiez votre connexion et réessayez.';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get device => 'Appareil';

  @override
  String get tagNotActive => 'Ce tag n\'est pas actif.';

  @override
  String get cardPaused => 'Cette carte de fidélité est en pause.';

  @override
  String get cardNotFound => 'Carte introuvable.';

  @override
  String get noFullCardYet => 'Pas encore de carte complète à échanger.';

  @override
  String get rewardNoLongerAvailable =>
      'Cette récompense n\'est plus disponible.';

  @override
  String get noConnection =>
      'Pas de connexion. Vérifiez votre connexion internet et réessayez.';

  @override
  String get somethingWentWrong =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get signInFirst => 'Connectez-vous d\'abord.';

  @override
  String get logoWrongType => 'Utilisez une image PNG, JPG ou WebP.';

  @override
  String get logoTooBig => 'Le logo doit faire moins de 200 Ko.';

  @override
  String exportAbout(Object url) {
    return 'Vos données dans Loyi. Ce qu\'elles signifient et vos droits : $url';
  }

  @override
  String get exportBusinessNote =>
      'Les clients n\'apparaissent que sous forme d\'identifiants anonymes. Votre logo n\'est pas inclus.';

  @override
  String get accountAndPrivacy => 'Compte et confidentialité';

  @override
  String get accountDeleted => 'Votre compte est supprimé.';

  @override
  String get language => 'Langue';

  @override
  String dontLoseCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ne perdez pas vos $count cartes',
      one: 'Ne perdez pas vos tampons',
    );
    return '$_temp0';
  }

  @override
  String get noPermission => 'Vous n\'avez pas l\'autorisation de faire cela.';

  @override
  String get shopNotActive =>
      'Les cartes Loyi de ce commerce ne sont pas actives pour le moment. Vos tampons sont conservés.';

  @override
  String get signInAgain => 'Reconnectez-vous.';

  @override
  String get onlyBusinessCanSubscribe =>
      'Seuls les comptes professionnels peuvent s\'abonner.';

  @override
  String get alreadySubscribed => 'Vous êtes déjà abonné.';

  @override
  String get noSubscriptionToManage =>
      'Il n\'y a pas encore d\'abonnement à gérer.';

  @override
  String get audienceAll => 'Tout le monde';

  @override
  String get audienceAllDesc => 'Tous ceux qui ont la carte';

  @override
  String get audienceNew => 'Nouveaux clients';

  @override
  String get audienceNewDesc => 'Inscrits ces 14 derniers jours';

  @override
  String get audienceAlmost => 'Presque là';

  @override
  String get audienceAlmostDesc => 'À 1 ou 2 tampons d\'une récompense';

  @override
  String get audienceReward => 'Récompense en attente';

  @override
  String get audienceRewardDesc =>
      'Ont une récompense qu\'ils n\'ont pas encore utilisée';

  @override
  String get audienceSlipping => 'En train de décrocher';

  @override
  String get audienceSlippingDesc => 'Dernière visite il y a 30 à 90 jours';

  @override
  String get audienceLost => 'Ne sont pas revenus';

  @override
  String get audienceLostDesc => 'Aucune visite depuis plus de 90 jours';

  @override
  String get statusReward => 'Récompense en attente';

  @override
  String get statusNew => 'Nouveau';

  @override
  String get statusAlmost => 'Presque là';

  @override
  String get statusRegular => 'Habitué';

  @override
  String get statusOccasional => 'Occasionnel';

  @override
  String get statusSlipping => 'Décroche';

  @override
  String get statusLost => 'Pas revenu';

  @override
  String get stampIconCheck => 'Coche';

  @override
  String get stampIconStar => 'Étoile';

  @override
  String get stampIconHeart => 'Cœur';

  @override
  String get stampIconCoffee => 'Café';

  @override
  String get stampIconBakery => 'Boulangerie';

  @override
  String get stampIconSandwich => 'Sandwich';

  @override
  String get stampIconPizza => 'Pizza';

  @override
  String get stampIconIceCream => 'Glace';

  @override
  String get stampIconCake => 'Gâteau';

  @override
  String get stampIconDrink => 'Boisson';

  @override
  String get stampIconHair => 'Coiffure';

  @override
  String get stampIconBeauty => 'Beauté';

  @override
  String get stampIconFlowers => 'Fleurs';

  @override
  String get stampIconPets => 'Animaux';

  @override
  String get stampIconCarWash => 'Lavage auto';

  @override
  String get stampIconShopping => 'Shopping';

  @override
  String get enterBusinessName => 'Indiquez le nom de votre commerce.';

  @override
  String get chooseOneColour => 'Choisissez au moins une couleur.';

  @override
  String get businessName => 'Nom du commerce';

  @override
  String get businessNameHint => 'p. ex. Boulangerie Dupont';

  @override
  String get brandColours => 'Couleurs de marque';

  @override
  String brandColoursHint(int max) {
    return 'Jusqu\'à $max. Les nouvelles cartes reprennent ces couleurs.';
  }

  @override
  String get cardColour => 'Couleur de la carte';

  @override
  String get style => 'Style';

  @override
  String get styleSolid => 'Uni';

  @override
  String get styleGradient => 'Dégradé';

  @override
  String get stylePattern => 'Motif';

  @override
  String get secondColour => 'Deuxième couleur';

  @override
  String get auto => 'Auto';

  @override
  String get stampColour => 'Couleur des tampons';

  @override
  String get stampIcon => 'Icône des tampons';

  @override
  String get tabOverview => 'Aperçu';

  @override
  String get tabClients => 'Clients';

  @override
  String get tabInsights => 'Statistiques';

  @override
  String get tabCards => 'Cartes';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get followUp => 'Suivi';

  @override
  String get whoToReachOut => 'Qui relancer';

  @override
  String get whoToReachOutSub =>
      'Les groupes se mettent à jour tout seuls. Votre message apparaît sur leur carte dans Loyi.';

  @override
  String get addYourLogo => 'Ajoutez votre logo';

  @override
  String get addYourLogoSub => 'Il apparaît sur chaque carte de vos clients.';

  @override
  String get live => 'En direct';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get allInsights => 'Toutes les statistiques';

  @override
  String get stampsToday => 'Tampons aujourd\'hui';

  @override
  String thisWeekCount(int count) {
    return '$count cette semaine';
  }

  @override
  String vsLastWeek(Object change) {
    return '$change vs semaine dernière';
  }

  @override
  String vsBefore(Object change) {
    return '$change vs avant';
  }

  @override
  String stampsLast7Days(Object values) {
    return 'Tampons par jour, 7 derniers jours : $values';
  }

  @override
  String get kpiClients => 'Clients';

  @override
  String kpiJoinedThisMonth(int count) {
    return '+$count ce mois-ci';
  }

  @override
  String get kpiActive => 'Actifs';

  @override
  String get kpiActiveNote => 'venus ces 30 derniers jours';

  @override
  String get kpiRewardsWaiting => 'Récompenses en attente';

  @override
  String get kpiRewardsWaitingNote => 'gagnées, pas encore utilisées';

  @override
  String get kpiRewardsGiven => 'Récompenses offertes';

  @override
  String get kpiRewardsGivenNote => 'depuis le début';

  @override
  String get pitchSlipping => 'Faites-les revenir avec une petite attention.';

  @override
  String get pitchAlmost => 'Encore une visite et ils ont une récompense.';

  @override
  String get pitchReward => 'Rappelez-leur qu\'une récompense les attend.';

  @override
  String get pitchNew =>
      'Souhaitez-leur la bienvenue et expliquez le fonctionnement.';

  @override
  String get writeAMessage => 'Écrire un message';

  @override
  String get message => 'Message';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String todayAt(Object time) {
    return 'Aujourd\'hui $time';
  }

  @override
  String get activityEmpty =>
      'Les tampons et les récompenses utilisées apparaîtront ici dès que vos clients toucheront vos tags.';

  @override
  String activityReward(Object title) {
    return 'Récompense : $title';
  }

  @override
  String get activityStamp => 'Tampon donné';

  @override
  String get csvHeader =>
      'client,statut,inscrit_le,derniere_visite,tampons_total,recompenses_en_attente,recompenses_utilisees';

  @override
  String get clientsTitle => 'Vos clients';

  @override
  String clientsSubtitle(int count) {
    return '$count avec une carte · toujours anonymes';
  }

  @override
  String get downloadCsv => 'Télécharger en CSV';

  @override
  String get newShort => 'Nouveau';

  @override
  String get messages => 'Messages';

  @override
  String get filterAll => 'Tous';

  @override
  String get findClientHint => 'Chercher un code client, p. ex. K7Q2';

  @override
  String get clientsEmpty =>
      'Les clients apparaissent ici après leur premier passage.';

  @override
  String get noClientsMatch => 'Aucun client ne correspond.';

  @override
  String showMore(int count) {
    return 'Afficher plus ($count)';
  }

  @override
  String get clientsPrivacyNote =>
      'Les clients sont anonymes : chacun a un code qui ne fonctionne que dans votre commerce. Loyi ne partage jamais de noms, d\'e-mails ni de numéros de téléphone, et les visites de plus de 2 ans sont supprimées automatiquement.';

  @override
  String get today => 'aujourd\'hui';

  @override
  String get yesterday => 'hier';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String clientRowSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tampons',
      one: '1 tampon',
    );
    return '$_temp0 · dernière visite $when';
  }

  @override
  String get factJoined => 'Inscrit le';

  @override
  String get factLastVisit => 'Dernière visite';

  @override
  String get factStamps => 'Tampons';

  @override
  String get factRewardsUsed => 'Récompenses utilisées';

  @override
  String rewardsWaitingCount(int count) {
    return '$count en attente';
  }

  @override
  String stampsOfRequired(int required, int stamps) {
    return '$stamps tampons sur $required';
  }

  @override
  String get recentVisits => 'Visites récentes';

  @override
  String get couldNotLoadVisits => 'Les visites n\'ont pas pu être chargées.';

  @override
  String get noStampsYet => 'Pas encore de tampons.';

  @override
  String get whyNoName =>
      'Pourquoi pas de nom ? Les clients utilisent Loyi sans dire aux commerces qui ils sont. Joignez-les plutôt avec un message sur leur carte.';

  @override
  String get noLinksAllowed =>
      'Les liens ne sont pas autorisés : ils font ressembler les messages à du phishing.';

  @override
  String get messageIsLive => 'Le message est en ligne';

  @override
  String get messageUpdated => 'Message mis à jour';

  @override
  String get couldNotSaveMessage =>
      'Le message n\'a pas pu être enregistré. Veuillez réessayer.';

  @override
  String get editMessage => 'Modifier le message';

  @override
  String get whoSeesIt => 'Qui le voit';

  @override
  String get card => 'Carte';

  @override
  String get allCards => 'Toutes les cartes';

  @override
  String get title => 'Titre';

  @override
  String get messageTitleHint => 'Vous nous manquez !';

  @override
  String get messageBodyHint =>
      'Montrez cette carte au comptoir cette semaine pour un café offert avec votre prochain sandwich.';

  @override
  String get addShortTitle => 'Ajoutez un titre court.';

  @override
  String get writeYourMessage => 'Écrivez votre message.';

  @override
  String get showItFor => 'L\'afficher pendant';

  @override
  String get oneWeek => '1 semaine';

  @override
  String get twoWeeks => '2 semaines';

  @override
  String get oneMonth => '1 mois';

  @override
  String get preview => 'Aperçu';

  @override
  String get messagePrivacyNote =>
      'Visible uniquement dans Loyi, jamais par e-mail ni notification. Le téléphone de chaque client décide si le message lui est destiné : vous ne voyez jamais qui l\'a lu.';

  @override
  String get publishMessage => 'Publier le message';

  @override
  String get deleteMessageQuestion => 'Supprimer ce message ?';

  @override
  String get deleteMessageBody => 'Les clients ne le verront plus.';

  @override
  String get noMessagesYet => 'Pas encore de messages';

  @override
  String get noMessagesBody =>
      'Faites revenir vos clients, encouragez ceux qui sont proches d\'une récompense ou accueillez les nouveaux. Votre message apparaît sur leur carte dans Loyi.';

  @override
  String get messageEnded => 'Terminé';

  @override
  String get messagePaused => 'En pause';

  @override
  String messageEndedOn(Object date) {
    return 'terminé le $date';
  }

  @override
  String messageReachUntil(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'touche $count clients',
      one: 'touche 1 client',
    );
    return '$_temp0 · jusqu\'au $date';
  }

  @override
  String get messageOptions => 'Options du message';

  @override
  String get editAndRunAgain => 'Modifier et relancer';

  @override
  String get pause => 'Mettre en pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get days7 => '7 jours';

  @override
  String get days30 => '30 jours';

  @override
  String get days90 => '90 jours';

  @override
  String get insightsTitle => 'Comment vont vos cartes';

  @override
  String get couldNotLoadInsights =>
      'Vos statistiques n\'ont pas pu être chargées.';

  @override
  String weekTo(Object date) {
    return 'Semaine jusqu\'au $date';
  }

  @override
  String get chartNow => 'Auj.';

  @override
  String weeksAgoShort(int weeks) {
    return '$weeks s';
  }

  @override
  String busyShop(Object count) {
    return 'Commerce animé ! Cette période compte plus de $count tampons : les graphiques n\'en montrent que le début. Choisissez une période plus courte pour des chiffres exacts.';
  }

  @override
  String get kpiStamps => 'Tampons';

  @override
  String get noEarlierData => 'pas encore de données antérieures';

  @override
  String get kpiActiveClients => 'Clients actifs';

  @override
  String cameBackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sont revenus',
      one: '1 est revenu',
    );
    return '$_temp0';
  }

  @override
  String get kpiNewClients => 'Nouveaux clients';

  @override
  String get joinedInPeriod => 'inscrits sur la période';

  @override
  String get kpiRewardsUsed => 'Récompenses utilisées';

  @override
  String stillWaitingCount(int count) {
    return '$count encore en attente';
  }

  @override
  String get stampsPerDay => 'Tampons par jour';

  @override
  String get stampsAppearHere =>
      'Les tampons apparaissent ici dès que vos clients touchent vos tags.';

  @override
  String busiestAt(Object day, Object time) {
    return 'Plus forte affluence : $day vers $time';
  }

  @override
  String stampsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tampons',
      one: '1 tampon',
    );
    return '$_temp0';
  }

  @override
  String newClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux clients',
      one: '1 nouveau client',
    );
    return '$_temp0';
  }

  @override
  String rewardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récompenses',
      one: '1 récompense',
    );
    return '$_temp0';
  }

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
    );
    return '$_temp0';
  }

  @override
  String stampsPerDaySemantic(int days, int total) {
    return 'Tampons par jour sur les $days derniers jours, $total au total';
  }

  @override
  String get perWeek => 'Par semaine';

  @override
  String get perDay => 'Par jour';

  @override
  String get legendNew => 'Nouveaux';

  @override
  String get legendRewards => 'Récompenses';

  @override
  String newClientsSemantic(Object values) {
    return 'Nouveaux clients : $values';
  }

  @override
  String rewardsUsedSemantic(Object values) {
    return 'Récompenses utilisées : $values';
  }

  @override
  String get busyTimes => 'Heures d\'affluence';

  @override
  String get busyTimesNote =>
      'Tampons par jour et par heure, pour savoir quand prévoir un coup de main.';

  @override
  String get clientMix => 'Répartition des clients';

  @override
  String clientMixNote(Object count) {
    return 'Où en sont vos $count clients';
  }

  @override
  String get clientsWord => 'clients';

  @override
  String get loyalty => 'Fidélité';

  @override
  String get loyaltyNote => 'À quelle fréquence vos clients reviennent';

  @override
  String get cameBackAfterFirst => 'Sont revenus après leur première visite';

  @override
  String get cameBackAfterFirstHint =>
      'Clients inscrits il y a au moins 30 jours';

  @override
  String get visitsPerActive => 'Visites par client actif';

  @override
  String get inThisPeriod => 'Sur cette période';

  @override
  String get daysBetweenVisits => 'Jours entre deux visites';

  @override
  String get daysBetweenVisitsHint =>
      'En moyenne, pour les clients venus plus d\'une fois';

  @override
  String get rewardsWaitingToUse => 'Récompenses à utiliser';

  @override
  String get rewardsWaitingToUseHint => 'Une bonne raison d\'envoyer un rappel';

  @override
  String programInsightNote(int clients, int rewards, int stamps) {
    return '$clients clients · $stamps tampons et $rewards récompenses sur la période. Barres : clients par nombre de tampons.';
  }

  @override
  String stampsOfRequiredShort(int required, int stamps) {
    return '$stamps tampons sur $required';
  }

  @override
  String programDistributionSemantic(Object card, Object values) {
    return 'Clients par nombre de tampons sur $card : $values';
  }

  @override
  String get insightsPrivacyNote =>
      'Les statistiques sont des chiffres, pas des personnes : Loyi ne sait jamais qui sont vos clients. L\'historique des tampons et récompenses de plus de 2 ans est supprimé automatiquement.';

  @override
  String get seeClients => 'Voir les clients';

  @override
  String get loyaltyCards => 'Cartes de fidélité';

  @override
  String get yourCards => 'Vos cartes';

  @override
  String get yourCardsSub =>
      'Tampons par carte, récompenses et design. Ouvrez une carte pour gérer ses tags NFC.';

  @override
  String get newCard => 'Nouvelle carte';

  @override
  String get howTagsWork => 'Comment fonctionnent les tags';

  @override
  String get howTagsWorkBody =>
      'Le tag d\'inscription à l\'entrée permet aux clients de prendre la carte. Le tag tampon au comptoir donne un tampon par contact, avec le délai que vous choisissez. Vous pouvez mettre un tag en pause à tout moment.';

  @override
  String get createFirstCard => 'Créez votre première carte de fidélité';

  @override
  String get createFirstCardSub =>
      'Choisissez le nombre de tampons pour remplir une carte, vos récompenses et vos couleurs.';

  @override
  String get paused => 'En pause';

  @override
  String programTileSummary(int rewards, int stamps) {
    String _temp0 = intl.Intl.pluralLogic(
      rewards,
      locale: localeName,
      other: '$rewards récompenses',
      one: '1 récompense',
    );
    return '$stamps tampons · $_temp0';
  }

  @override
  String get yourShop => 'Votre commerce';

  @override
  String get logo => 'Logo';

  @override
  String get logoHint =>
      'Affiché sur toutes vos cartes de fidélité. Un PNG carré avec un fond transparent est idéal.';

  @override
  String get details => 'Informations';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceHint =>
      'Clair par défaut. Appareil suit votre téléphone ou ordinateur.';

  @override
  String get languageHint => 'Le néerlandais est la langue par défaut.';

  @override
  String get subscription => 'Abonnement';

  @override
  String get accountSettingsSub =>
      'E-mail, mot de passe, vos données, suppression du compte';

  @override
  String get couldNotUpdateLogo =>
      'Le logo n\'a pas pu être modifié. Veuillez réessayer.';

  @override
  String get replaceLogo => 'Remplacer le logo';

  @override
  String get uploadLogo => 'Importer un logo';

  @override
  String get remove => 'Retirer';

  @override
  String get passwordTooShort =>
      'Utilisez au moins 8 caractères pour votre mot de passe.';

  @override
  String get wrongEmailOrPassword => 'E-mail ou mot de passe incorrect.';

  @override
  String get emailInUse =>
      'Un compte existe déjà avec cet e-mail. Connectez-vous plutôt.';

  @override
  String get emailHasAccount =>
      'Cet e-mail a déjà un compte Loyi. Connectez-vous avec votre e-mail et votre mot de passe.';

  @override
  String get invalidEmail => 'Indiquez une adresse e-mail valide.';

  @override
  String get signInMethodDisabled =>
      'Ce mode de connexion n\'est pas encore activé.';

  @override
  String get couldNotSignIn => 'Connexion impossible.';

  @override
  String get enterEmailFirst => 'Indiquez d\'abord votre adresse e-mail.';

  @override
  String resetLinkSent(Object email) {
    return 'Si $email a un compte, un lien pour réinitialiser le mot de passe est en route.';
  }

  @override
  String get startWithLoyi => 'Commencer avec Loyi';

  @override
  String get welcomeBack => 'Content de vous revoir';

  @override
  String get signUpSteps =>
      'Trois étapes : votre compte, vos couleurs, votre abonnement. Ensuite, votre tableau de bord est prêt.';

  @override
  String get signInSub => 'Connectez-vous pour gérer vos cartes de fidélité.';

  @override
  String get orWithEmail => 'ou par e-mail';

  @override
  String get signIn => 'Se connecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get agreeToTerms =>
      'En créant un compte, vous acceptez les conditions d\'utilisation, y compris l\'accord de traitement des données, ainsi que la politique de confidentialité.';

  @override
  String get continueAgreesToTerms =>
      'En continuant, vous acceptez les conditions d\'utilisation, y compris l\'accord de traitement des données, ainsi que la politique de confidentialité.';

  @override
  String get collectingStamps => 'Vous collectez des tampons ? Vers vos cartes';

  @override
  String get heroTitle => 'Des cartes de fidélité\nque vos clients gardent.';

  @override
  String get heroSub =>
      'Un contact sur un tag NFC. Aucune app à installer. Votre logo, vos couleurs, vos récompenses.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String stepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get yourBusiness => 'Votre commerce';

  @override
  String get yourBusinessSub =>
      'Le nom que vos clients voient sur leur carte de fidélité.';

  @override
  String get yourColours => 'Vos couleurs';

  @override
  String yourColoursSub(int max) {
    return 'Choisissez-en jusqu\'à $max : la carte, son dégradé et les tampons. Vous pourrez affiner chaque carte plus tard.';
  }

  @override
  String get loyaltyCard => 'Carte de fidélité';

  @override
  String coloursChosen(int count, int max) {
    return '$count sur $max choisies. Touchez à nouveau une couleur pour la retirer.';
  }

  @override
  String get subscriptionEnded => 'Votre abonnement est terminé';

  @override
  String get startSubscription => 'Démarrez votre abonnement';

  @override
  String get almostThere => 'Presque terminé';

  @override
  String get tagsPausedSub =>
      'Vos tags sont en pause. Les clients gardent leurs tampons et peuvent toujours utiliser les récompenses gagnées.';

  @override
  String get dashboardOpensWhenPaid =>
      'Votre tableau de bord s\'ouvre et vos tags fonctionnent dès que le paiement est confirmé. Résiliable à tout moment.';

  @override
  String get dashboardOpensWhenActive =>
      'Votre tableau de bord s\'ouvre dès que ce compte a un abonnement actif.';

  @override
  String get paymentReceived => 'Paiement reçu';

  @override
  String get switchingOn =>
      'Activation de votre compte. Cela prend quelques secondes.';

  @override
  String get takingLonger =>
      'Cela prend plus de temps que d\'habitude. Votre tableau de bord s\'ouvrira tout seul dès que le paiement sera confirmé. Si vous avez quitté la page de paiement sans payer, revenez à l\'étape de paiement.';

  @override
  String get backToPayment => 'Retour au paiement';

  @override
  String get paymentProblem => 'Problème de paiement';

  @override
  String get paymentProblemSub =>
      'Mettez à jour votre moyen de paiement pour que vos tags continuent de fonctionner.';

  @override
  String get loyiForBusiness => 'Loyi pour les commerces';

  @override
  String get planTagline =>
      'Des cartes de fidélité numériques que vos clients gardent vraiment.';

  @override
  String get perkTags => 'Vos tags NFC d\'inscription et de tampon, activés';

  @override
  String get perkUnlimited => 'Cartes de fidélité et récompenses illimitées';

  @override
  String get perkBrand => 'Votre logo, vos couleurs et le design de la carte';

  @override
  String get perkDashboard =>
      'Aperçu en direct, suivi des clients et statistiques';

  @override
  String get perkNoInstall => 'Rien à installer pour vos clients';

  @override
  String get youreSubscribed => 'Vous êtes abonné';

  @override
  String get tagsLive => 'Vos tags sont actifs.';

  @override
  String tagsLiveUntil(Object date) {
    return 'Vos tags sont actifs jusqu\'au $date.';
  }

  @override
  String lastPaymentFailed(Object date) {
    return 'Votre dernier paiement n\'est pas passé. Mettez à jour votre moyen de paiement avant le $date pour que vos tags continuent de fonctionner.';
  }

  @override
  String renewsOn(Object date) {
    return 'Vos tags sont actifs. Renouvellement le $date.';
  }

  @override
  String wontRenew(Object date) {
    return 'Vos tags sont actifs jusqu\'au $date. L\'abonnement ne sera pas renouvelé.';
  }

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get manageSubscriptionSub =>
      'Changez de moyen de paiement, téléchargez vos factures ou résiliez.';

  @override
  String get switchingOnTags => 'Paiement reçu. Activation de vos tags…';

  @override
  String get monthly => 'Mensuel';

  @override
  String get perMonthExclVat => ' / mois HTVA';

  @override
  String get cardOrBancontact =>
      'Carte ou Bancontact. Résiliable à tout moment.';

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get stripeNote =>
      'Vous payez en toute sécurité avec Stripe. L\'abonnement se renouvelle chaque mois jusqu\'à résiliation ; résiliez à tout moment via Abonnement → Gérer l\'abonnement. Vous recevez une facture pour chaque paiement.';

  @override
  String get noActiveSubscription => 'Pas d\'abonnement actif';

  @override
  String get noActiveSubscriptionSub =>
      'Ce compte n\'a pas d\'abonnement Loyi actif.';

  @override
  String get subscriptionsNotSetUp =>
      'Les abonnements ne sont pas configurés dans cette version.';

  @override
  String get noLimit => 'Aucune limite';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get giveCardName => 'Donnez un nom à votre carte.';

  @override
  String get addOneReward => 'Ajoutez au moins une récompense.';

  @override
  String get cardCreated =>
      'Carte créée. Ajoutez maintenant vos tags NFC ci-dessous.';

  @override
  String couldNotSave(Object reason) {
    return 'Enregistrement impossible. $reason';
  }

  @override
  String get yourCardName => 'Nom de votre carte';

  @override
  String get newLoyaltyCard => 'Nouvelle carte de fidélité';

  @override
  String get editLoyaltyCard => 'Modifier la carte de fidélité';

  @override
  String get create => 'Créer';

  @override
  String get cardName => 'Nom de la carte';

  @override
  String get cardNameSub =>
      'Court et clair ; les clients le voient sous le nom de votre commerce.';

  @override
  String get cardNameHint => 'p. ex. Carte café';

  @override
  String get design => 'Design';

  @override
  String get stampsForFullCard => 'Tampons pour une carte complète';

  @override
  String get stampsForFullCardSub =>
      '6 à 10 tampons semblent atteignables pour la plupart des clients ; au-delà, cela paraît vite lointain.';

  @override
  String get fewerStamps => 'Moins de tampons';

  @override
  String get moreStamps => 'Plus de tampons';

  @override
  String get rewards => 'Récompenses';

  @override
  String get rewardsSub =>
      'Les clients avec une carte complète choisissent une des récompenses actives. Activez ou désactivez-les à tout moment, p. ex. une récompense différente chaque semaine.';

  @override
  String get rewardHint => 'p. ex. Café offert';

  @override
  String get active => 'Actif';

  @override
  String get hiddenFromClients => 'Masquée pour les clients';

  @override
  String get addReward => 'Ajouter une récompense';

  @override
  String get timeBetweenStamps => 'Délai entre deux tampons';

  @override
  String get timeBetweenStampsSub =>
      'Le délai minimum avant que le même client puisse recevoir un autre tampon. Évite les doubles contacts.';

  @override
  String get cardIsLive => 'La carte est active';

  @override
  String get cardIsLiveSub =>
      'Quand la carte est en pause, les contacts sont refusés, mais les clients gardent leurs tampons.';

  @override
  String get createCard => 'Créer la carte';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get nfcTags => 'Tags NFC';

  @override
  String get nfcTagsSub =>
      'Chaque tag est un lien. Écrivez-le sur un autocollant NFC.';

  @override
  String get noTagsYet =>
      'Pas encore de tags. Créez un tag d\'inscription et un tag tampon pour commencer.';

  @override
  String get addJoinTag => 'Ajouter un tag d\'inscription';

  @override
  String get addStampTag => 'Ajouter un tag tampon';

  @override
  String get tagStep1 => 'Tag d\'inscription, bien visible';

  @override
  String get tagStep1Sub =>
      'À l\'entrée ou sur le comptoir. Le toucher ajoute la carte.';

  @override
  String get tagStep2 => 'Tag tampon, derrière le comptoir';

  @override
  String get tagStep2Sub =>
      'Présentez-le après un achat. Chaque contact donne un tampon.';

  @override
  String get programStickers => 'Programmez les autocollants';

  @override
  String get programStickersSub =>
      'Utilisez des autocollants NTAG213/215. Copiez le lien et écrivez-le comme enregistrement URL avec une app gratuite comme NFC Tools.';

  @override
  String get never => 'jamais';

  @override
  String joinTagLabel(Object label) {
    return 'Tag d\'inscription · $label';
  }

  @override
  String stampTagLabel(Object label) {
    return 'Tag tampon · $label';
  }

  @override
  String tapsSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
    );
    return '$_temp0 · dernier $when';
  }

  @override
  String get disabled => 'Désactivé';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get showQrCode => 'Afficher le code QR';

  @override
  String get joinQrCode => 'Code QR d\'inscription';

  @override
  String get joinQrCodeSub => 'Imprimez-le pour les clients sans NFC.';

  @override
  String get defaultJoinTagLabel => 'Entrée';

  @override
  String get defaultStampTagLabel => 'Comptoir';

  @override
  String get newJoinTag => 'Nouveau tag d\'inscription';

  @override
  String get newStampTag => 'Nouveau tag tampon';

  @override
  String get whereIsTag => 'Où se trouve ce tag ?';

  @override
  String get methodEmailPassword => 'E-mail et mot de passe';

  @override
  String get methodNotSaved => 'Non enregistré (ce navigateur uniquement)';

  @override
  String get yourAccount => 'Votre compte';

  @override
  String get signInMethod => 'Mode de connexion';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get signInSecurity => 'Connexion et sécurité';

  @override
  String get changeEmail => 'Changer d\'e-mail';

  @override
  String get changePassword => 'Changer de mot de passe';

  @override
  String noLoyiPassword(Object provider) {
    return 'Vous vous connectez avec $provider : il n\'y a donc pas de mot de passe Loyi. Gérez votre e-mail et votre sécurité dans votre compte $provider.';
  }

  @override
  String get yourData => 'Vos données';

  @override
  String get yourDataBusiness =>
      'Loyi conserve votre compte, votre commerce (nom, couleurs, logo), vos cartes de fidélité et tags, le statut de votre abonnement ainsi que les tampons et récompenses de vos clients sous des identifiants anonymes.';

  @override
  String get yourDataClient =>
      'Loyi conserve vos cartes, tampons et récompenses par commerce. Les commerces ne voient qu\'un identifiant anonyme, jamais votre e-mail.';

  @override
  String get yourDataClientEmail =>
      'Loyi conserve vos cartes, tampons et récompenses par commerce, ainsi que votre e-mail. Les commerces ne voient qu\'un identifiant anonyme, jamais votre e-mail.';

  @override
  String get readPrivacyPolicy => 'Lire la politique de confidentialité';

  @override
  String get deleteCardsOnDevice => 'Supprimer les cartes de cet appareil';

  @override
  String get downloadMyData => 'Télécharger mes données';

  @override
  String get newPasswordTooShort =>
      'Utilisez au moins 8 caractères pour votre nouveau mot de passe.';

  @override
  String get emailUsedByOther => 'Un autre compte utilise déjà cet e-mail.';

  @override
  String get signInAgainRetry => 'Reconnectez-vous et réessayez.';

  @override
  String get thatDidntWork => 'Cela n\'a pas fonctionné. Veuillez réessayer.';

  @override
  String get passwordsDontMatch =>
      'Les nouveaux mots de passe ne correspondent pas.';

  @override
  String get passwordChanged => 'Votre mot de passe a été modifié.';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get repeatNewPassword => 'Répétez le nouveau mot de passe';

  @override
  String get checkInbox => 'Consultez votre boîte de réception';

  @override
  String emailChangeSent(Object newEmail, Object oldEmail) {
    return 'Nous avons envoyé un lien à $newEmail. Votre e-mail change dès que vous l\'ouvrez. D\'ici là, continuez à vous connecter avec $oldEmail.';
  }

  @override
  String get ok => 'OK';

  @override
  String get newEmail => 'Nouvel e-mail';

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String ofStamps(int total) {
    return ' / $total tampons';
  }

  @override
  String toGo(int count) {
    return 'encore $count';
  }

  @override
  String cardSemantic(String business, String card, int stamps, int total) {
    return '$business, $card : $stamps tampons sur $total';
  }

  @override
  String rewardsReadySuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count récompenses prêtes',
      one: ', 1 récompense prête',
    );
    return '$_temp0';
  }

  @override
  String rewardsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récompenses',
      one: '1 récompense',
    );
    return '$_temp0';
  }

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      one: '1 carte',
    );
    return '$_temp0';
  }

  @override
  String rewardsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récompenses prêtes',
      one: '1 récompense prête',
    );
    return '$_temp0';
  }

  @override
  String get iHaveABusiness => 'J\'ai un commerce';

  @override
  String get noCardsYet => 'Pas encore de cartes';

  @override
  String get noCardsYetSub =>
      'Approchez votre téléphone d\'un tag Loyi dans un commerce pour obtenir votre première carte de fidélité.';

  @override
  String get cardsSaved => 'Vos cartes sont enregistrées.';

  @override
  String get emailOtherMethod =>
      'Cet e-mail a déjà un compte avec un autre mode de connexion. Utilisez celui-là.';

  @override
  String get emailHasAccountChoose =>
      'Cet e-mail a déjà un compte. Choisissez « J\'ai un compte ».';

  @override
  String get passwordTooShort6 =>
      'Utilisez au moins 6 caractères pour votre mot de passe.';

  @override
  String get accountAndCardsDeleted =>
      'Votre compte et vos cartes sont supprimés.';

  @override
  String get yourCardsAreSaved => 'Vos cartes sont enregistrées';

  @override
  String get yourCardsAreSavedSub =>
      'Connectez-vous avec ce compte sur n\'importe quel appareil pour voir vos cartes.';

  @override
  String get keepCardsSafe => 'Gardez vos cartes en sécurité';

  @override
  String get keepCardsSafeSub =>
      'Vos tampons sont enregistrés dans ce navigateur. Enregistrez-les dans un compte et ils vous suivent sur n\'importe quel téléphone. Vous avez déjà un compte ? Les cartes de cet appareil y sont ajoutées.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get newAccount => 'Nouveau compte';

  @override
  String get iHaveAnAccount => 'J\'ai un compte';

  @override
  String get saveMyCards => 'Enregistrer mes cartes';

  @override
  String get addingToCard => 'Ajout à votre carte…';

  @override
  String get onlyAMoment => 'Cela ne prend qu\'un instant.';

  @override
  String get thatDidntWorkTitle => 'Cela n\'a pas fonctionné';

  @override
  String get rewardRedeemed => 'Récompense utilisée';

  @override
  String redeemedAtShowStaff(Object time) {
    return 'Utilisée à $time · montrez cet écran au personnel';
  }

  @override
  String get myCards => 'Mes cartes';

  @override
  String get cardNotOnDevice => 'Carte introuvable sur cet appareil';

  @override
  String get goToMyCards => 'Vers mes cartes';

  @override
  String get savedOnCard =>
      'Enregistrée sur votre carte. Utilisez-la maintenant ou plus tard.';

  @override
  String get noRewardsNow =>
      'Ce commerce n\'a pas de récompense disponible pour le moment.';

  @override
  String get moreToGo => 'encore à collecter';

  @override
  String get thenChooseOne => 'Ensuite, choisissez parmi';

  @override
  String get stampsCollected => 'tampons collectés';

  @override
  String get rewardsUsedLower => 'récompenses utilisées';

  @override
  String get useAReward => 'Utiliser une récompense';

  @override
  String get chooseYourReward => 'Choisissez votre récompense';

  @override
  String get usesOneFullCard => 'Cela utilise une carte complète.';

  @override
  String get onlyAtCounter =>
      'Faites-le uniquement au comptoir. Le personnel doit voir l\'écran de confirmation.';

  @override
  String get useItNow => 'L\'utiliser maintenant';

  @override
  String get notYet => 'Pas encore';

  @override
  String get cardFull => 'Carte complète !';

  @override
  String get cardFullSub =>
      'Vous avez gagné une récompense. Utilisez-la maintenant ou lors d\'une prochaine visite.';

  @override
  String get stampAdded => 'Tampon ajouté';

  @override
  String get thanksForVisit => 'Merci de votre visite !';

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get welcomeSub =>
      'Votre carte est prête. Touchez le tag du comptoir après chaque achat.';

  @override
  String get yourCard => 'Votre carte';

  @override
  String get alreadyHaveCard => 'Vous avez déjà cette carte.';

  @override
  String get alreadyStamped => 'Déjà tamponné';

  @override
  String nextStampIn(Object wait) {
    return 'Prochain tampon possible dans $wait.';
  }

  @override
  String waitHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String waitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get shopMessagesTitle => 'Messages des commerces';

  @override
  String get shopMessagesSub =>
      'Les commerces peuvent afficher un court message sur votre carte, par exemple quand une récompense vous attend. Votre téléphone les choisit à partir de votre propre carte ; les commerces ne voient jamais qui les lit.';

  @override
  String get showShopMessages => 'Afficher les messages des commerces';

  @override
  String get turnOffShopMessages => 'Désactiver les messages des commerces';

  @override
  String get shopMessagesTurnedOff =>
      'Les messages des commerces sont désactivés. Vous pouvez les réactiver dans Compte et confidentialité.';

  @override
  String get undo => 'Annuler';

  @override
  String get kitLinkUsed =>
      'Ce lien a déjà été utilisé. Touchez à nouveau le tag.';

  @override
  String get notALoyiTag => 'Ce n\'est pas un tag Loyi.';

  @override
  String get kitAlreadyLinked => 'Ce tag est déjà associé à une carte.';

  @override
  String get kitTapAgain => 'Touchez à nouveau le tag, puis associez-le.';

  @override
  String get kitUnavailable =>
      'Les tags sécurisés ne sont pas encore disponibles. Réessayez plus tard.';

  @override
  String get kitNewTagTitle => 'Nouveau tag Loyi';

  @override
  String get kitNewTagShop =>
      'Choisissez la carte et le rôle de ce tag. Vous pourrez le désactiver plus tard sous Cartes.';

  @override
  String get kitNewTagClient =>
      'Ce tag n\'est pas encore associé à un commerce. Demandez au comptoir, ou réessayez plus tard.';

  @override
  String get kitShopSignIn =>
      'C\'est le tag de votre commerce ? Connectez-vous sur ce téléphone, puis touchez à nouveau le tag.';

  @override
  String get kitCard => 'Carte';

  @override
  String get kitNoCards =>
      'Créez d\'abord une carte de fidélité, puis touchez à nouveau le tag.';

  @override
  String get kitLink => 'Associer le tag';

  @override
  String get kitLinked => 'Tag associé';

  @override
  String get kitLinkedSub =>
      'Vos clients peuvent le toucher dès maintenant. Chaque contact crée un nouveau code à usage unique : un lien enregistré ne fonctionne pas deux fois.';

  @override
  String get kitOpenCard => 'Ouvrir la carte';

  @override
  String get tagTypeJoin => 'Inscription';

  @override
  String get tagTypeStamp => 'Tampon';

  @override
  String get secureTag => 'Tag de sécurité Loyi';

  @override
  String get secureTagSub =>
      'Un nouveau code unique à chaque contact : un lien enregistré ou partagé ne fonctionne pas.';

  @override
  String get kitHowTo => 'Tags de votre kit de démarrage';

  @override
  String get kitHowToSub =>
      'Connectez-vous sur votre téléphone, approchez-le d\'un tag du kit et choisissez cette carte. Rien à programmer.';

  @override
  String get ownStickers => 'Vos propres autocollants';

  @override
  String get ownStickersSub =>
      'Tout autocollant NTAG213/215 fonctionne avec les liens ci-dessous, mais un lien tampon sur un autocollant ordinaire peut être enregistré et réutilisé après le délai d\'attente. Utilisez un tag du kit pour les tampons.';

  @override
  String trialBadge(int days) {
    return '$days premiers jours gratuits';
  }

  @override
  String get startTrial => 'Commencer l\'essai gratuit';

  @override
  String trialNote(int days, String price) {
    return 'Vous ne payez rien aujourd\'hui. Après $days jours, votre abonnement démarre à $price par mois, sauf si vous résiliez avant. Nous vous envoyons aussi deux tags Loyi sécurisés ; Stripe vous demande l\'adresse.';
  }

  @override
  String trialUntil(String date, String price) {
    return 'Essai gratuit jusqu\'au $date. Ensuite $price par mois, sauf résiliation.';
  }

  @override
  String get demoTitle => 'Essayez une carte Loyi';

  @override
  String get demoSub =>
      'Voici ce que vos clients voient après avoir touché votre tag. Ici, un bouton remplace le tag.';

  @override
  String get demoStamp => 'Touchez le tag tampon';

  @override
  String demoStamped(int left) {
    return 'Tampon ajouté. Encore $left.';
  }

  @override
  String get demoFull =>
      'Carte complète ! La récompense attend sur la carte du client.';

  @override
  String get demoAgain => 'Recommencer';

  @override
  String get demoForShops => 'Vous voulez ceci pour votre commerce ?';
}
