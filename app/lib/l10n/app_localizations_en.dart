// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get continueAction => 'Continue';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get tryAgain => 'Try again';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get appleSignInFailed =>
      'Sign in with Apple didn\'t work. Check that you\'re signed in to your Apple Account in Settings, or use email.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get wrongPassword => 'Wrong password.';

  @override
  String get confirmSameAccount =>
      'Confirm with the same account you are signed in with.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get couldNotDeleteAccount => 'Could not delete your account.';

  @override
  String get deleteAccountQuestion => 'Delete account?';

  @override
  String get deleteAccountBusinessBody =>
      'Your shop, its loyalty cards and tags, your clients\' stamps for your shop and your activity history are permanently deleted. Your tags stop working.';

  @override
  String get deleteAccountClientBody =>
      'Your saved cards, stamps and rewards are permanently deleted. This can\'t be undone.';

  @override
  String get deleteAccountSubscriptionNote =>
      'Your subscription is cancelled too, so you won\'t be charged again.';

  @override
  String get yourPassword => 'Your password';

  @override
  String get confirmWithApple => 'You\'ll confirm with Apple.';

  @override
  String get confirmWithGoogle => 'You\'ll confirm with Google.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get customColour => 'Custom colour';

  @override
  String get hexCode => 'Hex code';

  @override
  String get hexCodeHint => 'Use 6 hex digits, e.g. E8553D';

  @override
  String get use => 'Use';

  @override
  String colourNumber(int number) {
    return 'colour $number';
  }

  @override
  String get cardsLiveInBrowser =>
      'Your cards live in this browser only. Add your email to keep them on a new phone or when you open Loyi from your home screen.';

  @override
  String get shopNoLongerUsesLoyi => 'This shop no longer uses Loyi.';

  @override
  String get messageTitlePlaceholder => 'Your title';

  @override
  String get messageBodyPlaceholder => 'Your message';

  @override
  String get hideThisMessage => 'Hide this message';

  @override
  String get couldNotLoadBusiness => 'Could not load your business.';

  @override
  String get stampsPerWeekdayAndHour => 'Stamps per weekday and hour';

  @override
  String get couldNotCancelSubscription =>
      'We couldn\'t cancel your subscription, so nothing was deleted. Check your connection and try again.';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get device => 'Device';

  @override
  String get tagNotActive => 'This tag is not active.';

  @override
  String get cardPaused => 'This loyalty card is paused.';

  @override
  String get cardNotFound => 'Card not found.';

  @override
  String get noFullCardYet => 'No full card to redeem yet.';

  @override
  String get rewardNoLongerAvailable => 'This reward is no longer available.';

  @override
  String get noConnection =>
      'No connection. Check your internet and try again.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get signInFirst => 'Sign in first.';

  @override
  String get logoWrongType => 'Use a PNG, JPG or WebP image.';

  @override
  String get logoTooBig => 'The logo must be smaller than 200 KB.';

  @override
  String exportAbout(Object url) {
    return 'Your data in Loyi. What it means and your rights: $url';
  }

  @override
  String get exportBusinessNote =>
      'Clients appear only as anonymous IDs. Your logo image is not included.';

  @override
  String get accountAndPrivacy => 'Account & privacy';

  @override
  String get accountDeleted => 'Your account is deleted.';

  @override
  String get language => 'Language';

  @override
  String dontLoseCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Don\'t lose your $count cards',
      one: 'Don\'t lose your stamps',
    );
    return '$_temp0';
  }

  @override
  String get noPermission => 'You don\'t have permission to do that.';

  @override
  String get shopNotActive =>
      'This shop\'s Loyi cards aren\'t active right now. Your stamps are safe.';

  @override
  String get signInAgain => 'Sign in again.';

  @override
  String get onlyBusinessCanSubscribe =>
      'Only business accounts can subscribe.';

  @override
  String get alreadySubscribed => 'You\'re already subscribed.';

  @override
  String get noSubscriptionToManage =>
      'There is no subscription to manage yet.';

  @override
  String get audienceAll => 'Everyone';

  @override
  String get audienceAllDesc => 'Everyone with the card';

  @override
  String get audienceNew => 'New clients';

  @override
  String get audienceNewDesc => 'Joined in the last 14 days';

  @override
  String get audienceAlmost => 'Almost there';

  @override
  String get audienceAlmostDesc => '1 or 2 stamps from a reward';

  @override
  String get audienceReward => 'Reward waiting';

  @override
  String get audienceRewardDesc => 'Have a reward they haven\'t used yet';

  @override
  String get audienceSlipping => 'Slipping away';

  @override
  String get audienceSlippingDesc => 'Last visit 30 to 90 days ago';

  @override
  String get audienceLost => 'Haven\'t been back';

  @override
  String get audienceLostDesc => 'No visit in more than 90 days';

  @override
  String get statusReward => 'Reward waiting';

  @override
  String get statusNew => 'New';

  @override
  String get statusAlmost => 'Almost there';

  @override
  String get statusRegular => 'Regular';

  @override
  String get statusOccasional => 'Occasional';

  @override
  String get statusSlipping => 'Slipping away';

  @override
  String get statusLost => 'Haven\'t been back';

  @override
  String get stampIconCheck => 'Check';

  @override
  String get stampIconStar => 'Star';

  @override
  String get stampIconHeart => 'Heart';

  @override
  String get stampIconCoffee => 'Coffee';

  @override
  String get stampIconBakery => 'Bakery';

  @override
  String get stampIconSandwich => 'Sandwich';

  @override
  String get stampIconPizza => 'Pizza';

  @override
  String get stampIconIceCream => 'Ice cream';

  @override
  String get stampIconCake => 'Cake';

  @override
  String get stampIconDrink => 'Drink';

  @override
  String get stampIconHair => 'Hair';

  @override
  String get stampIconBeauty => 'Beauty';

  @override
  String get stampIconFlowers => 'Flowers';

  @override
  String get stampIconPets => 'Pets';

  @override
  String get stampIconCarWash => 'Car wash';

  @override
  String get stampIconShopping => 'Shopping';

  @override
  String get enterBusinessName => 'Enter your business name.';

  @override
  String get chooseOneColour => 'Choose at least one colour.';

  @override
  String get businessName => 'Business name';

  @override
  String get businessNameHint => 'e.g. Bakkerij Peeters';

  @override
  String get brandColours => 'Brand colours';

  @override
  String brandColoursHint(int max) {
    return 'Up to $max. New cards start in these colours.';
  }

  @override
  String get cardColour => 'Card colour';

  @override
  String get style => 'Style';

  @override
  String get styleSolid => 'Solid';

  @override
  String get styleGradient => 'Gradient';

  @override
  String get stylePattern => 'Pattern';

  @override
  String get secondColour => 'Second colour';

  @override
  String get auto => 'Auto';

  @override
  String get stampColour => 'Stamp colour';

  @override
  String get stampIcon => 'Stamp icon';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabClients => 'Clients';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabCards => 'Cards';

  @override
  String get tabSettings => 'Settings';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get newMessage => 'New message';

  @override
  String get followUp => 'Follow-up';

  @override
  String get whoToReachOut => 'Who to reach out to';

  @override
  String get whoToReachOutSub =>
      'Groups update by themselves. Your message appears on their card in Loyi.';

  @override
  String get addYourLogo => 'Add your logo';

  @override
  String get addYourLogoSub => 'It appears on every card your clients carry.';

  @override
  String get live => 'Live';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get allInsights => 'All insights';

  @override
  String get stampsToday => 'Stamps today';

  @override
  String thisWeekCount(int count) {
    return '$count this week';
  }

  @override
  String vsLastWeek(Object change) {
    return '$change vs last week';
  }

  @override
  String vsBefore(Object change) {
    return '$change vs before';
  }

  @override
  String stampsLast7Days(Object values) {
    return 'Stamps per day, last 7 days: $values';
  }

  @override
  String get kpiClients => 'Clients';

  @override
  String kpiJoinedThisMonth(int count) {
    return '+$count this month';
  }

  @override
  String get kpiActive => 'Active';

  @override
  String get kpiActiveNote => 'visited in 30 days';

  @override
  String get kpiRewardsWaiting => 'Rewards waiting';

  @override
  String get kpiRewardsWaitingNote => 'earned, not used yet';

  @override
  String get kpiRewardsGiven => 'Rewards given';

  @override
  String get kpiRewardsGivenNote => 'since you started';

  @override
  String get pitchSlipping => 'Invite them back with a small treat.';

  @override
  String get pitchAlmost => 'One more visit gets them a reward.';

  @override
  String get pitchReward => 'Remind them a reward is waiting.';

  @override
  String get pitchNew => 'Welcome them and tell them how it works.';

  @override
  String get writeAMessage => 'Write a message';

  @override
  String get message => 'Message';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String todayAt(Object time) {
    return 'Today $time';
  }

  @override
  String get activityEmpty =>
      'Stamps and redeemed rewards will show up here as clients tap your tags.';

  @override
  String activityReward(Object title) {
    return 'Reward: $title';
  }

  @override
  String get activityStamp => 'Stamp given';

  @override
  String get csvHeader =>
      'client,status,joined,last_visit,total_stamps,rewards_waiting,rewards_used';

  @override
  String get clientsTitle => 'Your clients';

  @override
  String clientsSubtitle(int count) {
    return '$count with a card · anonymous by design';
  }

  @override
  String get downloadCsv => 'Download as CSV';

  @override
  String get newShort => 'New';

  @override
  String get messages => 'Messages';

  @override
  String get filterAll => 'All';

  @override
  String get findClientHint => 'Find a client code, e.g. K7Q2';

  @override
  String get clientsEmpty => 'Clients appear here after their first tap.';

  @override
  String get noClientsMatch => 'No clients match.';

  @override
  String showMore(int count) {
    return 'Show more ($count)';
  }

  @override
  String get clientsPrivacyNote =>
      'Clients are anonymous: each has a code that only works in your shop. Loyi never shares names, emails or phone numbers, and visits older than 2 years are deleted automatically.';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String clientRowSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stamps',
      one: '1 stamp',
    );
    return '$_temp0 · last visit $when';
  }

  @override
  String get factJoined => 'Joined';

  @override
  String get factLastVisit => 'Last visit';

  @override
  String get factStamps => 'Stamps';

  @override
  String get factRewardsUsed => 'Rewards used';

  @override
  String rewardsWaitingCount(int count) {
    return '$count waiting';
  }

  @override
  String stampsOfRequired(int required, int stamps) {
    return '$stamps of $required stamps';
  }

  @override
  String get recentVisits => 'Recent visits';

  @override
  String get couldNotLoadVisits => 'Could not load visits.';

  @override
  String get noStampsYet => 'No stamps yet.';

  @override
  String get whyNoName =>
      'Why no name? Clients use Loyi without telling shops who they are. Reach them with a message on their card instead.';

  @override
  String get noLinksAllowed =>
      'Links aren\'t allowed: they make messages look like phishing.';

  @override
  String get messageIsLive => 'Message is live';

  @override
  String get messageUpdated => 'Message updated';

  @override
  String get couldNotSaveMessage =>
      'Could not save the message. Please try again.';

  @override
  String get editMessage => 'Edit message';

  @override
  String get whoSeesIt => 'Who sees it';

  @override
  String get card => 'Card';

  @override
  String get allCards => 'All cards';

  @override
  String get title => 'Title';

  @override
  String get messageTitleHint => 'We miss you!';

  @override
  String get messageBodyHint =>
      'Show this card at the counter this week for a free coffee with your next sandwich.';

  @override
  String get addShortTitle => 'Add a short title.';

  @override
  String get writeYourMessage => 'Write your message.';

  @override
  String get showItFor => 'Show it for';

  @override
  String get oneWeek => '1 week';

  @override
  String get twoWeeks => '2 weeks';

  @override
  String get oneMonth => '1 month';

  @override
  String get preview => 'Preview';

  @override
  String get messagePrivacyNote =>
      'Shown inside Loyi only, never by email or push. Each client\'s phone decides if the message is for them, so you never see who read it.';

  @override
  String get publishMessage => 'Publish message';

  @override
  String get deleteMessageQuestion => 'Delete this message?';

  @override
  String get deleteMessageBody => 'Clients won\'t see it anymore.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesBody =>
      'Invite clients back, nudge those close to a reward, or welcome newcomers. Your message appears on their card in Loyi.';

  @override
  String get messageEnded => 'Ended';

  @override
  String get messagePaused => 'Paused';

  @override
  String messageEndedOn(Object date) {
    return 'ended $date';
  }

  @override
  String messageReachUntil(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reaches $count clients now',
      one: 'reaches 1 client now',
    );
    return '$_temp0 · until $date';
  }

  @override
  String get messageOptions => 'Message options';

  @override
  String get editAndRunAgain => 'Edit and run again';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get days7 => '7 days';

  @override
  String get days30 => '30 days';

  @override
  String get days90 => '90 days';

  @override
  String get insightsTitle => 'How your cards do';

  @override
  String get couldNotLoadInsights => 'Could not load your insights.';

  @override
  String weekTo(Object date) {
    return 'Week to $date';
  }

  @override
  String get chartNow => 'Now';

  @override
  String weeksAgoShort(int weeks) {
    return '${weeks}w';
  }

  @override
  String busyShop(Object count) {
    return 'Busy shop! This period has more than $count stamps, so the charts show the first part only. Pick a shorter period for exact numbers.';
  }

  @override
  String get kpiStamps => 'Stamps';

  @override
  String get noEarlierData => 'no earlier data yet';

  @override
  String get kpiActiveClients => 'Active clients';

  @override
  String cameBackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count came back',
      one: '1 came back',
    );
    return '$_temp0';
  }

  @override
  String get kpiNewClients => 'New clients';

  @override
  String get joinedInPeriod => 'joined in this period';

  @override
  String get kpiRewardsUsed => 'Rewards used';

  @override
  String stillWaitingCount(int count) {
    return '$count still waiting';
  }

  @override
  String get stampsPerDay => 'Stamps per day';

  @override
  String get stampsAppearHere => 'Stamps appear here as clients tap your tags.';

  @override
  String busiestAt(Object day, Object time) {
    return 'Busiest: $day around $time';
  }

  @override
  String stampsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stamps',
      one: '1 stamp',
    );
    return '$_temp0';
  }

  @override
  String newClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new clients',
      one: '1 new client',
    );
    return '$_temp0';
  }

  @override
  String rewardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rewards',
      one: '1 reward',
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
    return 'Stamps per day over the last $days days, $total in total';
  }

  @override
  String get perWeek => 'Per week';

  @override
  String get perDay => 'Per day';

  @override
  String get legendNew => 'New';

  @override
  String get legendRewards => 'Rewards';

  @override
  String newClientsSemantic(Object values) {
    return 'New clients: $values';
  }

  @override
  String rewardsUsedSemantic(Object values) {
    return 'Rewards used: $values';
  }

  @override
  String get busyTimes => 'Busy times';

  @override
  String get busyTimesNote =>
      'Stamps by weekday and hour, so you know when to plan an extra hand.';

  @override
  String get clientMix => 'Client mix';

  @override
  String clientMixNote(Object count) {
    return 'Where your $count clients are now';
  }

  @override
  String get clientsWord => 'clients';

  @override
  String get loyalty => 'Loyalty';

  @override
  String get loyaltyNote => 'How often clients come back';

  @override
  String get cameBackAfterFirst => 'Came back after their first visit';

  @override
  String get cameBackAfterFirstHint =>
      'Clients who joined at least 30 days ago';

  @override
  String get visitsPerActive => 'Visits per active client';

  @override
  String get inThisPeriod => 'In this period';

  @override
  String get daysBetweenVisits => 'Days between visits';

  @override
  String get daysBetweenVisitsHint =>
      'Average, for clients who came more than once';

  @override
  String get rewardsWaitingToUse => 'Rewards waiting to be used';

  @override
  String get rewardsWaitingToUseHint => 'A good reason to send a reminder';

  @override
  String programInsightNote(int clients, int rewards, int stamps) {
    return '$clients clients · $stamps stamps and $rewards rewards in this period. Bars: clients by stamps collected.';
  }

  @override
  String stampsOfRequiredShort(int required, int stamps) {
    return '$stamps of $required stamps';
  }

  @override
  String programDistributionSemantic(Object card, Object values) {
    return 'Clients by stamps collected on $card: $values';
  }

  @override
  String get insightsPrivacyNote =>
      'Insights are counts, not people: Loyi never knows who your clients are. Stamp and reward logs older than 2 years are deleted automatically.';

  @override
  String get seeClients => 'See clients';

  @override
  String get loyaltyCards => 'Loyalty cards';

  @override
  String get yourCards => 'Your cards';

  @override
  String get yourCardsSub =>
      'Stamps per card, rewards and design. Open a card to manage its NFC tags.';

  @override
  String get newCard => 'New card';

  @override
  String get howTagsWork => 'How the tags work';

  @override
  String get howTagsWorkBody =>
      'A join tag at the entrance lets clients pick up the card. The stamp tag at the counter gives one stamp per tap, with the waiting time you set. Pause a tag any time.';

  @override
  String get createFirstCard => 'Create your first loyalty card';

  @override
  String get createFirstCardSub =>
      'Choose how many stamps fill a card, your rewards and your colours.';

  @override
  String get paused => 'Paused';

  @override
  String programTileSummary(int rewards, int stamps) {
    String _temp0 = intl.Intl.pluralLogic(
      rewards,
      locale: localeName,
      other: '$rewards rewards',
      one: '1 reward',
    );
    return '$stamps stamps · $_temp0';
  }

  @override
  String get yourShop => 'Your shop';

  @override
  String get logo => 'Logo';

  @override
  String get logoHint =>
      'Shown on all your loyalty cards. A square PNG with a transparent background works best.';

  @override
  String get details => 'Details';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceHint =>
      'Light is the default. Device follows your phone or computer.';

  @override
  String get languageHint => 'Nederlands is the default.';

  @override
  String get subscription => 'Subscription';

  @override
  String get accountSettingsSub => 'Email, password, your data, delete account';

  @override
  String get couldNotUpdateLogo =>
      'Could not update the logo. Please try again.';

  @override
  String get replaceLogo => 'Replace logo';

  @override
  String get uploadLogo => 'Upload logo';

  @override
  String get remove => 'Remove';

  @override
  String get passwordTooShort => 'Use at least 8 characters for your password.';

  @override
  String get wrongEmailOrPassword => 'Wrong email or password.';

  @override
  String get emailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get emailHasAccount =>
      'This email already has a Loyi account. Sign in with your email and password.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get signInMethodDisabled => 'This sign-in method is not enabled yet.';

  @override
  String get couldNotSignIn => 'Could not sign in.';

  @override
  String get enterEmailFirst => 'Enter your email address first.';

  @override
  String resetLinkSent(Object email) {
    return 'If $email has an account, a link to reset the password is on its way.';
  }

  @override
  String get startWithLoyi => 'Start with Loyi';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signUpSteps =>
      'Three steps: your account, your colours, your subscription. Then your dashboard is ready.';

  @override
  String get signInSub => 'Sign in to manage your loyalty cards.';

  @override
  String get orWithEmail => 'or with email';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get agreeToTerms =>
      'By creating an account you agree to the terms of use and privacy policy.';

  @override
  String get collectingStamps => 'Collecting stamps? Go to your cards';

  @override
  String get heroTitle => 'Stamp cards your\nclients actually keep.';

  @override
  String get heroSub =>
      'One tap on an NFC tag. No app to install. Your logo, your colours, your rewards.';

  @override
  String get signOut => 'Sign out';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get yourBusiness => 'Your business';

  @override
  String get yourBusinessSub =>
      'The name your clients see on their loyalty card.';

  @override
  String get yourColours => 'Your colours';

  @override
  String yourColoursSub(int max) {
    return 'Pick up to $max: the card, its gradient and the stamps. You can fine-tune each card later.';
  }

  @override
  String get loyaltyCard => 'Loyalty card';

  @override
  String coloursChosen(int count, int max) {
    return '$count of $max chosen. Tap a colour again to remove it.';
  }

  @override
  String get subscriptionEnded => 'Your subscription has ended';

  @override
  String get startSubscription => 'Start your subscription';

  @override
  String get almostThere => 'Almost there';

  @override
  String get tagsPausedSub =>
      'Your tags are paused. Clients keep their stamps and can still use rewards they earned.';

  @override
  String get dashboardOpensWhenPaid =>
      'Your dashboard opens and your tags work as soon as the payment is confirmed. Cancel anytime.';

  @override
  String get dashboardOpensWhenActive =>
      'Your dashboard opens as soon as this account has an active subscription.';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String get switchingOn =>
      'Switching on your account. This takes a few seconds.';

  @override
  String get takingLonger =>
      'This is taking longer than usual. Your dashboard opens by itself as soon as the payment is confirmed. If you left the payment page without paying, go back to the payment step.';

  @override
  String get backToPayment => 'Back to payment';

  @override
  String get paymentProblem => 'Payment problem';

  @override
  String get paymentProblemSub =>
      'Update your payment method to keep your tags working.';

  @override
  String get loyiForBusiness => 'Loyi for business';

  @override
  String get planTagline => 'Digital stamp cards your clients actually keep.';

  @override
  String get perkTags => 'Your NFC join and stamp tags, switched on';

  @override
  String get perkUnlimited => 'Unlimited loyalty cards and rewards';

  @override
  String get perkBrand => 'Your logo, colours and card design';

  @override
  String get perkDashboard => 'Live overview, client follow-up and insights';

  @override
  String get perkNoInstall => 'Nothing for your clients to install';

  @override
  String get youreSubscribed => 'You\'re subscribed';

  @override
  String get tagsLive => 'Your tags are live.';

  @override
  String tagsLiveUntil(Object date) {
    return 'Your tags are live until $date.';
  }

  @override
  String lastPaymentFailed(Object date) {
    return 'Your last payment didn\'t go through. Update your payment method before $date to keep your tags working.';
  }

  @override
  String renewsOn(Object date) {
    return 'Your tags are live. Renews on $date.';
  }

  @override
  String wontRenew(Object date) {
    return 'Your tags are live until $date. The subscription won\'t renew.';
  }

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get manageSubscriptionSub =>
      'Change your payment method, download invoices or cancel.';

  @override
  String get switchingOnTags => 'Payment received. Switching on your tags…';

  @override
  String get monthly => 'Monthly';

  @override
  String get perMonthExclVat => ' / month excl. VAT';

  @override
  String get cardOrBancontact => 'Card or Bancontact. Cancel anytime.';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get stripeNote =>
      'You pay securely with Stripe. The subscription renews every month until you cancel; cancel anytime under Subscription → Manage subscription. You get an invoice for every payment.';

  @override
  String get noActiveSubscription => 'No active subscription';

  @override
  String get noActiveSubscriptionSub =>
      'This account doesn\'t have an active Loyi subscription.';

  @override
  String get subscriptionsNotSetUp =>
      'Subscriptions aren\'t set up in this build.';

  @override
  String get noLimit => 'No limit';

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
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get giveCardName => 'Give your card a name.';

  @override
  String get addOneReward => 'Add at least one reward.';

  @override
  String get cardCreated => 'Card created. Now add your NFC tags below.';

  @override
  String couldNotSave(Object reason) {
    return 'Could not save. $reason';
  }

  @override
  String get yourCardName => 'Your card name';

  @override
  String get newLoyaltyCard => 'New loyalty card';

  @override
  String get editLoyaltyCard => 'Edit loyalty card';

  @override
  String get create => 'Create';

  @override
  String get cardName => 'Card name';

  @override
  String get cardNameSub =>
      'Short and descriptive; clients see it under your business name.';

  @override
  String get cardNameHint => 'e.g. Koffiekaart';

  @override
  String get design => 'Design';

  @override
  String get stampsForFullCard => 'Stamps for a full card';

  @override
  String get stampsForFullCardSub =>
      '6 to 10 stamps feels achievable for most clients; more can feel out of reach.';

  @override
  String get fewerStamps => 'Fewer stamps';

  @override
  String get moreStamps => 'More stamps';

  @override
  String get rewards => 'Rewards';

  @override
  String get rewardsSub =>
      'Clients with a full card choose one of the active rewards. Switch rewards on or off anytime, e.g. a different reward each week.';

  @override
  String get rewardHint => 'e.g. Free coffee';

  @override
  String get active => 'Active';

  @override
  String get hiddenFromClients => 'Hidden from clients';

  @override
  String get addReward => 'Add reward';

  @override
  String get timeBetweenStamps => 'Time between stamps';

  @override
  String get timeBetweenStampsSub =>
      'The minimum wait before the same client can get another stamp. Stops double taps.';

  @override
  String get cardIsLive => 'Card is live';

  @override
  String get cardIsLiveSub =>
      'When paused, taps are refused but clients keep their stamps.';

  @override
  String get createCard => 'Create card';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get nfcTags => 'NFC tags';

  @override
  String get nfcTagsSub => 'Every tag is a link. Write it onto an NFC sticker.';

  @override
  String get noTagsYet =>
      'No tags yet. Create one join tag and one stamp tag to get started.';

  @override
  String get addJoinTag => 'Add join tag';

  @override
  String get addStampTag => 'Add stamp tag';

  @override
  String get tagStep1 => 'Join tag, where clients can see it';

  @override
  String get tagStep1Sub =>
      'At the door or on the counter. Tapping it adds the card.';

  @override
  String get tagStep2 => 'Stamp tag, behind the counter';

  @override
  String get tagStep2Sub =>
      'Hold it out after a purchase. Every tap gives one stamp.';

  @override
  String get programStickers => 'Program the stickers';

  @override
  String get programStickersSub =>
      'Use NTAG213/215 stickers. Copy the link and write it as a URL record with a free app like NFC Tools.';

  @override
  String get never => 'never';

  @override
  String joinTagLabel(Object label) {
    return 'Join tag · $label';
  }

  @override
  String stampTagLabel(Object label) {
    return 'Stamp tag · $label';
  }

  @override
  String tapsSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taps',
      one: '1 tap',
    );
    return '$_temp0 · last $when';
  }

  @override
  String get disabled => 'Disabled';

  @override
  String get copyLink => 'Copy link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get joinQrCode => 'Join QR code';

  @override
  String get joinQrCodeSub => 'Print it for clients without NFC.';

  @override
  String get defaultJoinTagLabel => 'Entrance';

  @override
  String get defaultStampTagLabel => 'Counter';

  @override
  String get newJoinTag => 'New join tag';

  @override
  String get newStampTag => 'New stamp tag';

  @override
  String get whereIsTag => 'Where is this tag?';

  @override
  String get methodEmailPassword => 'Email and password';

  @override
  String get methodApple => 'Sign in with Apple';

  @override
  String get methodNotSaved => 'Not saved (this browser only)';

  @override
  String get yourAccount => 'Your account';

  @override
  String get signInMethod => 'Sign-in';

  @override
  String get memberSince => 'Member since';

  @override
  String get signInSecurity => 'Sign-in & security';

  @override
  String get changeEmail => 'Change email';

  @override
  String get changePassword => 'Change password';

  @override
  String noLoyiPassword(Object provider) {
    return 'You sign in with $provider, so there is no Loyi password. Manage your email and security in your $provider account.';
  }

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataBusiness =>
      'Loyi stores your account, your shop (name, colours, logo), your loyalty cards and tags, your subscription status and your clients\' stamps and rewards under anonymous IDs.';

  @override
  String get yourDataClient =>
      'Loyi stores your cards, stamps and rewards per shop. Shops only see an anonymous ID, never your email.';

  @override
  String get yourDataClientEmail =>
      'Loyi stores your cards, stamps and rewards per shop, and your email. Shops only see an anonymous ID, never your email.';

  @override
  String get readPrivacyPolicy => 'Read the privacy policy';

  @override
  String get deleteCardsOnDevice => 'Delete the cards on this device';

  @override
  String get downloadMyData => 'Download my data';

  @override
  String get newPasswordTooShort =>
      'Use at least 8 characters for your new password.';

  @override
  String get emailUsedByOther => 'Another account already uses this email.';

  @override
  String get signInAgainRetry => 'Please sign in again and retry.';

  @override
  String get thatDidntWork => 'That didn\'t work. Please try again.';

  @override
  String get passwordsDontMatch => 'The new passwords don\'t match.';

  @override
  String get passwordChanged => 'Your password is changed.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get repeatNewPassword => 'Repeat new password';

  @override
  String get checkInbox => 'Check your inbox';

  @override
  String emailChangeSent(Object newEmail, Object oldEmail) {
    return 'We sent a link to $newEmail. Your email changes as soon as you open it. Until then, keep signing in with $oldEmail.';
  }

  @override
  String get ok => 'OK';

  @override
  String get newEmail => 'New email';

  @override
  String get sendLink => 'Send link';

  @override
  String ofStamps(int total) {
    return ' / $total stamps';
  }

  @override
  String toGo(int count) {
    return '$count to go';
  }

  @override
  String cardSemantic(String business, String card, int stamps, int total) {
    return '$business, $card: $stamps of $total stamps';
  }

  @override
  String rewardsReadySuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count rewards ready',
      one: ', 1 reward ready',
    );
    return '$_temp0';
  }

  @override
  String rewardsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rewards',
      one: '1 reward',
    );
    return '$_temp0';
  }

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String rewardsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rewards ready',
      one: '1 reward ready',
    );
    return '$_temp0';
  }

  @override
  String get iHaveABusiness => 'I have a business';

  @override
  String get noCardsYet => 'No cards yet';

  @override
  String get noCardsYetSub =>
      'Hold your phone near a Loyi tag in a shop to get your first loyalty card.';

  @override
  String get cardsSaved => 'Your cards are saved.';

  @override
  String get emailOtherMethod =>
      'This email already has an account with another sign-in method. Use that one.';

  @override
  String get emailHasAccountChoose =>
      'This email already has an account. Choose \"I have an account\".';

  @override
  String get passwordTooShort6 =>
      'Use at least 6 characters for your password.';

  @override
  String get accountAndCardsDeleted => 'Your account and cards are deleted.';

  @override
  String get yourCardsAreSaved => 'Your cards are saved';

  @override
  String get yourCardsAreSavedSub =>
      'Sign in with this account on any device to see your cards.';

  @override
  String get keepCardsSafe => 'Keep your cards safe';

  @override
  String get keepCardsSafeSub =>
      'Your stamps are stored in this browser. Save them to an account and they follow you to any phone. Already have an account? Your cards from this device are added to it.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get newAccount => 'New account';

  @override
  String get iHaveAnAccount => 'I have an account';

  @override
  String get saveMyCards => 'Save my cards';

  @override
  String get addingToCard => 'Adding to your card…';

  @override
  String get onlyAMoment => 'This only takes a moment.';

  @override
  String get thatDidntWorkTitle => 'That didn\'t work';

  @override
  String get rewardRedeemed => 'Reward redeemed';

  @override
  String redeemedAtShowStaff(Object time) {
    return 'Redeemed at $time · show this screen to staff';
  }

  @override
  String get myCards => 'My cards';

  @override
  String get cardNotOnDevice => 'Card not found on this device';

  @override
  String get goToMyCards => 'Go to my cards';

  @override
  String get savedOnCard => 'Saved on your card. Use it now or later.';

  @override
  String get noRewardsNow => 'This shop has no rewards available right now.';

  @override
  String get moreToGo => 'more to go';

  @override
  String get thenChooseOne => 'Then choose one of these';

  @override
  String get stampsCollected => 'stamps collected';

  @override
  String get rewardsUsedLower => 'rewards used';

  @override
  String get useAReward => 'Use a reward';

  @override
  String get chooseYourReward => 'Choose your reward';

  @override
  String get usesOneFullCard => 'This uses one full card.';

  @override
  String get onlyAtCounter =>
      'Only do this at the counter. Staff need to see the confirmation screen.';

  @override
  String get useItNow => 'Use it now';

  @override
  String get notYet => 'Not yet';

  @override
  String get cardFull => 'Card full!';

  @override
  String get cardFullSub =>
      'You earned a reward. Use it now or on a later visit.';

  @override
  String get stampAdded => 'Stamp added';

  @override
  String get thanksForVisit => 'Thanks for your visit!';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeSub =>
      'Your card is ready. Tap the counter tag after each purchase.';

  @override
  String get yourCard => 'Your card';

  @override
  String get alreadyHaveCard => 'You already have this card.';

  @override
  String get alreadyStamped => 'Already stamped';

  @override
  String nextStampIn(Object wait) {
    return 'Your next stamp is possible in $wait.';
  }

  @override
  String waitHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String waitMinutes(int minutes) {
    return '$minutes min';
  }
}
