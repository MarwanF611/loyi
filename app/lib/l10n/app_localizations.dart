import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('nl'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple didn\'t work. Check that you\'re signed in to your Apple Account in Settings, or use email.'**
  String get appleSignInFailed;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// No description provided for @confirmSameAccount.
  ///
  /// In en, this message translates to:
  /// **'Confirm with the same account you are signed in with.'**
  String get confirmSameAccount;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get tooManyAttempts;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account.'**
  String get couldNotDeleteAccount;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountBusinessBody.
  ///
  /// In en, this message translates to:
  /// **'Your shop, its loyalty cards and tags, your clients\' stamps for your shop and your activity history are permanently deleted. Your tags stop working.'**
  String get deleteAccountBusinessBody;

  /// No description provided for @deleteAccountClientBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved cards, stamps and rewards are permanently deleted. This can\'t be undone.'**
  String get deleteAccountClientBody;

  /// No description provided for @deleteAccountSubscriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is cancelled too, so you won\'t be charged again.'**
  String get deleteAccountSubscriptionNote;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @confirmWithApple.
  ///
  /// In en, this message translates to:
  /// **'You\'ll confirm with Apple.'**
  String get confirmWithApple;

  /// No description provided for @confirmWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll confirm with Google.'**
  String get confirmWithGoogle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @customColour.
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get customColour;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex code'**
  String get hexCode;

  /// No description provided for @hexCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Use 6 hex digits, e.g. E8553D'**
  String get hexCodeHint;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @colourNumber.
  ///
  /// In en, this message translates to:
  /// **'colour {number}'**
  String colourNumber(int number);

  /// No description provided for @cardsLiveInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Your cards live in this browser only. Add your email to keep them on a new phone or when you open Loyi from your home screen.'**
  String get cardsLiveInBrowser;

  /// No description provided for @shopNoLongerUsesLoyi.
  ///
  /// In en, this message translates to:
  /// **'This shop no longer uses Loyi.'**
  String get shopNoLongerUsesLoyi;

  /// No description provided for @messageTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your title'**
  String get messageTitlePlaceholder;

  /// No description provided for @messageBodyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get messageBodyPlaceholder;

  /// No description provided for @hideThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Hide this message'**
  String get hideThisMessage;

  /// No description provided for @couldNotLoadBusiness.
  ///
  /// In en, this message translates to:
  /// **'Could not load your business.'**
  String get couldNotLoadBusiness;

  /// No description provided for @stampsPerWeekdayAndHour.
  ///
  /// In en, this message translates to:
  /// **'Stamps per weekday and hour'**
  String get stampsPerWeekdayAndHour;

  /// No description provided for @couldNotCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t cancel your subscription, so nothing was deleted. Check your connection and try again.'**
  String get couldNotCancelSubscription;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @tagNotActive.
  ///
  /// In en, this message translates to:
  /// **'This tag is not active.'**
  String get tagNotActive;

  /// No description provided for @cardPaused.
  ///
  /// In en, this message translates to:
  /// **'This loyalty card is paused.'**
  String get cardPaused;

  /// No description provided for @cardNotFound.
  ///
  /// In en, this message translates to:
  /// **'Card not found.'**
  String get cardNotFound;

  /// No description provided for @noFullCardYet.
  ///
  /// In en, this message translates to:
  /// **'No full card to redeem yet.'**
  String get noFullCardYet;

  /// No description provided for @rewardNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This reward is no longer available.'**
  String get rewardNoLongerAvailable;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get noConnection;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @signInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in first.'**
  String get signInFirst;

  /// No description provided for @logoWrongType.
  ///
  /// In en, this message translates to:
  /// **'Use a PNG, JPG or WebP image.'**
  String get logoWrongType;

  /// No description provided for @logoTooBig.
  ///
  /// In en, this message translates to:
  /// **'The logo must be smaller than 200 KB.'**
  String get logoTooBig;

  /// No description provided for @exportAbout.
  ///
  /// In en, this message translates to:
  /// **'Your data in Loyi. What it means and your rights: {url}'**
  String exportAbout(Object url);

  /// No description provided for @exportBusinessNote.
  ///
  /// In en, this message translates to:
  /// **'Clients appear only as anonymous IDs. Your logo image is not included.'**
  String get exportBusinessNote;

  /// No description provided for @accountAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Account & privacy'**
  String get accountAndPrivacy;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account is deleted.'**
  String get accountDeleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dontLoseCards.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Don\'t lose your stamps} other{Don\'t lose your {count} cards}}'**
  String dontLoseCards(int count);

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get noPermission;

  /// No description provided for @shopNotActive.
  ///
  /// In en, this message translates to:
  /// **'This shop\'s Loyi cards aren\'t active right now. Your stamps are safe.'**
  String get shopNotActive;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again.'**
  String get signInAgain;

  /// No description provided for @onlyBusinessCanSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Only business accounts can subscribe.'**
  String get onlyBusinessCanSubscribe;

  /// No description provided for @alreadySubscribed.
  ///
  /// In en, this message translates to:
  /// **'You\'re already subscribed.'**
  String get alreadySubscribed;

  /// No description provided for @noSubscriptionToManage.
  ///
  /// In en, this message translates to:
  /// **'There is no subscription to manage yet.'**
  String get noSubscriptionToManage;

  /// No description provided for @audienceAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get audienceAll;

  /// No description provided for @audienceAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Everyone with the card'**
  String get audienceAllDesc;

  /// No description provided for @audienceNew.
  ///
  /// In en, this message translates to:
  /// **'New clients'**
  String get audienceNew;

  /// No description provided for @audienceNewDesc.
  ///
  /// In en, this message translates to:
  /// **'Joined in the last 14 days'**
  String get audienceNewDesc;

  /// No description provided for @audienceAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get audienceAlmost;

  /// No description provided for @audienceAlmostDesc.
  ///
  /// In en, this message translates to:
  /// **'1 or 2 stamps from a reward'**
  String get audienceAlmostDesc;

  /// No description provided for @audienceReward.
  ///
  /// In en, this message translates to:
  /// **'Reward waiting'**
  String get audienceReward;

  /// No description provided for @audienceRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Have a reward they haven\'t used yet'**
  String get audienceRewardDesc;

  /// No description provided for @audienceSlipping.
  ///
  /// In en, this message translates to:
  /// **'Slipping away'**
  String get audienceSlipping;

  /// No description provided for @audienceSlippingDesc.
  ///
  /// In en, this message translates to:
  /// **'Last visit 30 to 90 days ago'**
  String get audienceSlippingDesc;

  /// No description provided for @audienceLost.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t been back'**
  String get audienceLost;

  /// No description provided for @audienceLostDesc.
  ///
  /// In en, this message translates to:
  /// **'No visit in more than 90 days'**
  String get audienceLostDesc;

  /// No description provided for @statusReward.
  ///
  /// In en, this message translates to:
  /// **'Reward waiting'**
  String get statusReward;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get statusAlmost;

  /// No description provided for @statusRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get statusRegular;

  /// No description provided for @statusOccasional.
  ///
  /// In en, this message translates to:
  /// **'Occasional'**
  String get statusOccasional;

  /// No description provided for @statusSlipping.
  ///
  /// In en, this message translates to:
  /// **'Slipping away'**
  String get statusSlipping;

  /// No description provided for @statusLost.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t been back'**
  String get statusLost;

  /// No description provided for @stampIconCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get stampIconCheck;

  /// No description provided for @stampIconStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get stampIconStar;

  /// No description provided for @stampIconHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get stampIconHeart;

  /// No description provided for @stampIconCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get stampIconCoffee;

  /// No description provided for @stampIconBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get stampIconBakery;

  /// No description provided for @stampIconSandwich.
  ///
  /// In en, this message translates to:
  /// **'Sandwich'**
  String get stampIconSandwich;

  /// No description provided for @stampIconPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get stampIconPizza;

  /// No description provided for @stampIconIceCream.
  ///
  /// In en, this message translates to:
  /// **'Ice cream'**
  String get stampIconIceCream;

  /// No description provided for @stampIconCake.
  ///
  /// In en, this message translates to:
  /// **'Cake'**
  String get stampIconCake;

  /// No description provided for @stampIconDrink.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get stampIconDrink;

  /// No description provided for @stampIconHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get stampIconHair;

  /// No description provided for @stampIconBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get stampIconBeauty;

  /// No description provided for @stampIconFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get stampIconFlowers;

  /// No description provided for @stampIconPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get stampIconPets;

  /// No description provided for @stampIconCarWash.
  ///
  /// In en, this message translates to:
  /// **'Car wash'**
  String get stampIconCarWash;

  /// No description provided for @stampIconShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get stampIconShopping;

  /// No description provided for @enterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name.'**
  String get enterBusinessName;

  /// No description provided for @chooseOneColour.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one colour.'**
  String get chooseOneColour;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @businessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bakkerij Peeters'**
  String get businessNameHint;

  /// No description provided for @brandColours.
  ///
  /// In en, this message translates to:
  /// **'Brand colours'**
  String get brandColours;

  /// No description provided for @brandColoursHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}. New cards start in these colours.'**
  String brandColoursHint(int max);

  /// No description provided for @cardColour.
  ///
  /// In en, this message translates to:
  /// **'Card colour'**
  String get cardColour;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @styleSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get styleSolid;

  /// No description provided for @styleGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get styleGradient;

  /// No description provided for @stylePattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get stylePattern;

  /// No description provided for @secondColour.
  ///
  /// In en, this message translates to:
  /// **'Second colour'**
  String get secondColour;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @stampColour.
  ///
  /// In en, this message translates to:
  /// **'Stamp colour'**
  String get stampColour;

  /// No description provided for @stampIcon.
  ///
  /// In en, this message translates to:
  /// **'Stamp icon'**
  String get stampIcon;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get tabClients;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @tabCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get tabCards;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUp;

  /// No description provided for @whoToReachOut.
  ///
  /// In en, this message translates to:
  /// **'Who to reach out to'**
  String get whoToReachOut;

  /// No description provided for @whoToReachOutSub.
  ///
  /// In en, this message translates to:
  /// **'Groups update by themselves. Your message appears on their card in Loyi.'**
  String get whoToReachOutSub;

  /// No description provided for @addYourLogo.
  ///
  /// In en, this message translates to:
  /// **'Add your logo'**
  String get addYourLogo;

  /// No description provided for @addYourLogoSub.
  ///
  /// In en, this message translates to:
  /// **'It appears on every card your clients carry.'**
  String get addYourLogoSub;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @allInsights.
  ///
  /// In en, this message translates to:
  /// **'All insights'**
  String get allInsights;

  /// No description provided for @stampsToday.
  ///
  /// In en, this message translates to:
  /// **'Stamps today'**
  String get stampsToday;

  /// No description provided for @thisWeekCount.
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String thisWeekCount(int count);

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'{change} vs last week'**
  String vsLastWeek(Object change);

  /// No description provided for @vsBefore.
  ///
  /// In en, this message translates to:
  /// **'{change} vs before'**
  String vsBefore(Object change);

  /// No description provided for @stampsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Stamps per day, last 7 days: {values}'**
  String stampsLast7Days(Object values);

  /// No description provided for @kpiClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get kpiClients;

  /// No description provided for @kpiJoinedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'+{count} this month'**
  String kpiJoinedThisMonth(int count);

  /// No description provided for @kpiActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get kpiActive;

  /// No description provided for @kpiActiveNote.
  ///
  /// In en, this message translates to:
  /// **'visited in 30 days'**
  String get kpiActiveNote;

  /// No description provided for @kpiRewardsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Rewards waiting'**
  String get kpiRewardsWaiting;

  /// No description provided for @kpiRewardsWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'earned, not used yet'**
  String get kpiRewardsWaitingNote;

  /// No description provided for @kpiRewardsGiven.
  ///
  /// In en, this message translates to:
  /// **'Rewards given'**
  String get kpiRewardsGiven;

  /// No description provided for @kpiRewardsGivenNote.
  ///
  /// In en, this message translates to:
  /// **'since you started'**
  String get kpiRewardsGivenNote;

  /// No description provided for @pitchSlipping.
  ///
  /// In en, this message translates to:
  /// **'Invite them back with a small treat.'**
  String get pitchSlipping;

  /// No description provided for @pitchAlmost.
  ///
  /// In en, this message translates to:
  /// **'One more visit gets them a reward.'**
  String get pitchAlmost;

  /// No description provided for @pitchReward.
  ///
  /// In en, this message translates to:
  /// **'Remind them a reward is waiting.'**
  String get pitchReward;

  /// No description provided for @pitchNew.
  ///
  /// In en, this message translates to:
  /// **'Welcome them and tell them how it works.'**
  String get pitchNew;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get writeAMessage;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(Object time);

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Stamps and redeemed rewards will show up here as clients tap your tags.'**
  String get activityEmpty;

  /// No description provided for @activityReward.
  ///
  /// In en, this message translates to:
  /// **'Reward: {title}'**
  String activityReward(Object title);

  /// No description provided for @activityStamp.
  ///
  /// In en, this message translates to:
  /// **'Stamp given'**
  String get activityStamp;

  /// No description provided for @csvHeader.
  ///
  /// In en, this message translates to:
  /// **'client,status,joined,last_visit,total_stamps,rewards_waiting,rewards_used'**
  String get csvHeader;

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your clients'**
  String get clientsTitle;

  /// No description provided for @clientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} with a card · anonymous by design'**
  String clientsSubtitle(int count);

  /// No description provided for @downloadCsv.
  ///
  /// In en, this message translates to:
  /// **'Download as CSV'**
  String get downloadCsv;

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newShort;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @findClientHint.
  ///
  /// In en, this message translates to:
  /// **'Find a client code, e.g. K7Q2'**
  String get findClientHint;

  /// No description provided for @clientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clients appear here after their first tap.'**
  String get clientsEmpty;

  /// No description provided for @noClientsMatch.
  ///
  /// In en, this message translates to:
  /// **'No clients match.'**
  String get noClientsMatch;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more ({count})'**
  String showMore(int count);

  /// No description provided for @clientsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Clients are anonymous: each has a code that only works in your shop. Loyi never shares names, emails or phone numbers, and visits older than 2 years are deleted automatically.'**
  String get clientsPrivacyNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String daysAgo(int days);

  /// No description provided for @clientRowSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stamp} other{{count} stamps}} · last visit {when}'**
  String clientRowSummary(int count, String when);

  /// No description provided for @factJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get factJoined;

  /// No description provided for @factLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get factLastVisit;

  /// No description provided for @factStamps.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get factStamps;

  /// No description provided for @factRewardsUsed.
  ///
  /// In en, this message translates to:
  /// **'Rewards used'**
  String get factRewardsUsed;

  /// No description provided for @rewardsWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String rewardsWaitingCount(int count);

  /// No description provided for @stampsOfRequired.
  ///
  /// In en, this message translates to:
  /// **'{stamps} of {required} stamps'**
  String stampsOfRequired(int required, int stamps);

  /// No description provided for @recentVisits.
  ///
  /// In en, this message translates to:
  /// **'Recent visits'**
  String get recentVisits;

  /// No description provided for @couldNotLoadVisits.
  ///
  /// In en, this message translates to:
  /// **'Could not load visits.'**
  String get couldNotLoadVisits;

  /// No description provided for @noStampsYet.
  ///
  /// In en, this message translates to:
  /// **'No stamps yet.'**
  String get noStampsYet;

  /// No description provided for @whyNoName.
  ///
  /// In en, this message translates to:
  /// **'Why no name? Clients use Loyi without telling shops who they are. Reach them with a message on their card instead.'**
  String get whyNoName;

  /// No description provided for @noLinksAllowed.
  ///
  /// In en, this message translates to:
  /// **'Links aren\'t allowed: they make messages look like phishing.'**
  String get noLinksAllowed;

  /// No description provided for @messageIsLive.
  ///
  /// In en, this message translates to:
  /// **'Message is live'**
  String get messageIsLive;

  /// No description provided for @messageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Message updated'**
  String get messageUpdated;

  /// No description provided for @couldNotSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save the message. Please try again.'**
  String get couldNotSaveMessage;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @whoSeesIt.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get whoSeesIt;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @allCards.
  ///
  /// In en, this message translates to:
  /// **'All cards'**
  String get allCards;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @messageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'We miss you!'**
  String get messageTitleHint;

  /// No description provided for @messageBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Show this card at the counter this week for a free coffee with your next sandwich.'**
  String get messageBodyHint;

  /// No description provided for @addShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a short title.'**
  String get addShortTitle;

  /// No description provided for @writeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Write your message.'**
  String get writeYourMessage;

  /// No description provided for @showItFor.
  ///
  /// In en, this message translates to:
  /// **'Show it for'**
  String get showItFor;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get oneWeek;

  /// No description provided for @twoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get twoWeeks;

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get oneMonth;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @messagePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Shown inside Loyi only, never by email or push. Each client\'s phone decides if the message is for them, so you never see who read it.'**
  String get messagePrivacyNote;

  /// No description provided for @publishMessage.
  ///
  /// In en, this message translates to:
  /// **'Publish message'**
  String get publishMessage;

  /// No description provided for @deleteMessageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteMessageQuestion;

  /// No description provided for @deleteMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Clients won\'t see it anymore.'**
  String get deleteMessageBody;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'Invite clients back, nudge those close to a reward, or welcome newcomers. Your message appears on their card in Loyi.'**
  String get noMessagesBody;

  /// No description provided for @messageEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get messageEnded;

  /// No description provided for @messagePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get messagePaused;

  /// No description provided for @messageEndedOn.
  ///
  /// In en, this message translates to:
  /// **'ended {date}'**
  String messageEndedOn(Object date);

  /// No description provided for @messageReachUntil.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{reaches 1 client now} other{reaches {count} clients now}} · until {date}'**
  String messageReachUntil(int count, String date);

  /// No description provided for @messageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageOptions;

  /// No description provided for @editAndRunAgain.
  ///
  /// In en, this message translates to:
  /// **'Edit and run again'**
  String get editAndRunAgain;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get days90;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'How your cards do'**
  String get insightsTitle;

  /// No description provided for @couldNotLoadInsights.
  ///
  /// In en, this message translates to:
  /// **'Could not load your insights.'**
  String get couldNotLoadInsights;

  /// No description provided for @weekTo.
  ///
  /// In en, this message translates to:
  /// **'Week to {date}'**
  String weekTo(Object date);

  /// No description provided for @chartNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get chartNow;

  /// No description provided for @weeksAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w'**
  String weeksAgoShort(int weeks);

  /// No description provided for @busyShop.
  ///
  /// In en, this message translates to:
  /// **'Busy shop! This period has more than {count} stamps, so the charts show the first part only. Pick a shorter period for exact numbers.'**
  String busyShop(Object count);

  /// No description provided for @kpiStamps.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get kpiStamps;

  /// No description provided for @noEarlierData.
  ///
  /// In en, this message translates to:
  /// **'no earlier data yet'**
  String get noEarlierData;

  /// No description provided for @kpiActiveClients.
  ///
  /// In en, this message translates to:
  /// **'Active clients'**
  String get kpiActiveClients;

  /// No description provided for @cameBackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 came back} other{{count} came back}}'**
  String cameBackCount(int count);

  /// No description provided for @kpiNewClients.
  ///
  /// In en, this message translates to:
  /// **'New clients'**
  String get kpiNewClients;

  /// No description provided for @joinedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'joined in this period'**
  String get joinedInPeriod;

  /// No description provided for @kpiRewardsUsed.
  ///
  /// In en, this message translates to:
  /// **'Rewards used'**
  String get kpiRewardsUsed;

  /// No description provided for @stillWaitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} still waiting'**
  String stillWaitingCount(int count);

  /// No description provided for @stampsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Stamps per day'**
  String get stampsPerDay;

  /// No description provided for @stampsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Stamps appear here as clients tap your tags.'**
  String get stampsAppearHere;

  /// No description provided for @busiestAt.
  ///
  /// In en, this message translates to:
  /// **'Busiest: {day} around {time}'**
  String busiestAt(Object day, Object time);

  /// No description provided for @stampsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stamp} other{{count} stamps}}'**
  String stampsCount(int count);

  /// No description provided for @newClientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new client} other{{count} new clients}}'**
  String newClientsCount(int count);

  /// No description provided for @rewardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reward} other{{count} rewards}}'**
  String rewardsCount(int count);

  /// No description provided for @clientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 client} other{{count} clients}}'**
  String clientsCount(int count);

  /// No description provided for @stampsPerDaySemantic.
  ///
  /// In en, this message translates to:
  /// **'Stamps per day over the last {days} days, {total} in total'**
  String stampsPerDaySemantic(int days, int total);

  /// No description provided for @perWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get perWeek;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get perDay;

  /// No description provided for @legendNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get legendNew;

  /// No description provided for @legendRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get legendRewards;

  /// No description provided for @newClientsSemantic.
  ///
  /// In en, this message translates to:
  /// **'New clients: {values}'**
  String newClientsSemantic(Object values);

  /// No description provided for @rewardsUsedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rewards used: {values}'**
  String rewardsUsedSemantic(Object values);

  /// No description provided for @busyTimes.
  ///
  /// In en, this message translates to:
  /// **'Busy times'**
  String get busyTimes;

  /// No description provided for @busyTimesNote.
  ///
  /// In en, this message translates to:
  /// **'Stamps by weekday and hour, so you know when to plan an extra hand.'**
  String get busyTimesNote;

  /// No description provided for @clientMix.
  ///
  /// In en, this message translates to:
  /// **'Client mix'**
  String get clientMix;

  /// No description provided for @clientMixNote.
  ///
  /// In en, this message translates to:
  /// **'Where your {count} clients are now'**
  String clientMixNote(Object count);

  /// No description provided for @clientsWord.
  ///
  /// In en, this message translates to:
  /// **'clients'**
  String get clientsWord;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @loyaltyNote.
  ///
  /// In en, this message translates to:
  /// **'How often clients come back'**
  String get loyaltyNote;

  /// No description provided for @cameBackAfterFirst.
  ///
  /// In en, this message translates to:
  /// **'Came back after their first visit'**
  String get cameBackAfterFirst;

  /// No description provided for @cameBackAfterFirstHint.
  ///
  /// In en, this message translates to:
  /// **'Clients who joined at least 30 days ago'**
  String get cameBackAfterFirstHint;

  /// No description provided for @visitsPerActive.
  ///
  /// In en, this message translates to:
  /// **'Visits per active client'**
  String get visitsPerActive;

  /// No description provided for @inThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'In this period'**
  String get inThisPeriod;

  /// No description provided for @daysBetweenVisits.
  ///
  /// In en, this message translates to:
  /// **'Days between visits'**
  String get daysBetweenVisits;

  /// No description provided for @daysBetweenVisitsHint.
  ///
  /// In en, this message translates to:
  /// **'Average, for clients who came more than once'**
  String get daysBetweenVisitsHint;

  /// No description provided for @rewardsWaitingToUse.
  ///
  /// In en, this message translates to:
  /// **'Rewards waiting to be used'**
  String get rewardsWaitingToUse;

  /// No description provided for @rewardsWaitingToUseHint.
  ///
  /// In en, this message translates to:
  /// **'A good reason to send a reminder'**
  String get rewardsWaitingToUseHint;

  /// No description provided for @programInsightNote.
  ///
  /// In en, this message translates to:
  /// **'{clients} clients · {stamps} stamps and {rewards} rewards in this period. Bars: clients by stamps collected.'**
  String programInsightNote(int clients, int rewards, int stamps);

  /// No description provided for @stampsOfRequiredShort.
  ///
  /// In en, this message translates to:
  /// **'{stamps} of {required} stamps'**
  String stampsOfRequiredShort(int required, int stamps);

  /// No description provided for @programDistributionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Clients by stamps collected on {card}: {values}'**
  String programDistributionSemantic(Object card, Object values);

  /// No description provided for @insightsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Insights are counts, not people: Loyi never knows who your clients are. Stamp and reward logs older than 2 years are deleted automatically.'**
  String get insightsPrivacyNote;

  /// No description provided for @seeClients.
  ///
  /// In en, this message translates to:
  /// **'See clients'**
  String get seeClients;

  /// No description provided for @loyaltyCards.
  ///
  /// In en, this message translates to:
  /// **'Loyalty cards'**
  String get loyaltyCards;

  /// No description provided for @yourCards.
  ///
  /// In en, this message translates to:
  /// **'Your cards'**
  String get yourCards;

  /// No description provided for @yourCardsSub.
  ///
  /// In en, this message translates to:
  /// **'Stamps per card, rewards and design. Open a card to manage its NFC tags.'**
  String get yourCardsSub;

  /// No description provided for @newCard.
  ///
  /// In en, this message translates to:
  /// **'New card'**
  String get newCard;

  /// No description provided for @howTagsWork.
  ///
  /// In en, this message translates to:
  /// **'How the tags work'**
  String get howTagsWork;

  /// No description provided for @howTagsWorkBody.
  ///
  /// In en, this message translates to:
  /// **'A join tag at the entrance lets clients pick up the card. The stamp tag at the counter gives one stamp per tap, with the waiting time you set. Pause a tag any time.'**
  String get howTagsWorkBody;

  /// No description provided for @createFirstCard.
  ///
  /// In en, this message translates to:
  /// **'Create your first loyalty card'**
  String get createFirstCard;

  /// No description provided for @createFirstCardSub.
  ///
  /// In en, this message translates to:
  /// **'Choose how many stamps fill a card, your rewards and your colours.'**
  String get createFirstCardSub;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @programTileSummary.
  ///
  /// In en, this message translates to:
  /// **'{stamps} stamps · {rewards, plural, =1{1 reward} other{{rewards} rewards}}'**
  String programTileSummary(int rewards, int stamps);

  /// No description provided for @yourShop.
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get yourShop;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @logoHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on all your loyalty cards. A square PNG with a transparent background works best.'**
  String get logoHint;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Light is the default. Device follows your phone or computer.'**
  String get appearanceHint;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Nederlands is the default.'**
  String get languageHint;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @accountSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Email, password, your data, delete account'**
  String get accountSettingsSub;

  /// No description provided for @couldNotUpdateLogo.
  ///
  /// In en, this message translates to:
  /// **'Could not update the logo. Please try again.'**
  String get couldNotUpdateLogo;

  /// No description provided for @replaceLogo.
  ///
  /// In en, this message translates to:
  /// **'Replace logo'**
  String get replaceLogo;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get uploadLogo;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters for your password.'**
  String get passwordTooShort;

  /// No description provided for @wrongEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get wrongEmailOrPassword;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get emailInUse;

  /// No description provided for @emailHasAccount.
  ///
  /// In en, this message translates to:
  /// **'This email already has a Loyi account. Sign in with your email and password.'**
  String get emailHasAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @signInMethodDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled yet.'**
  String get signInMethodDisabled;

  /// No description provided for @couldNotSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in.'**
  String get couldNotSignIn;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address first.'**
  String get enterEmailFirst;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account, a link to reset the password is on its way.'**
  String resetLinkSent(Object email);

  /// No description provided for @startWithLoyi.
  ///
  /// In en, this message translates to:
  /// **'Start with Loyi'**
  String get startWithLoyi;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signUpSteps.
  ///
  /// In en, this message translates to:
  /// **'Three steps: your account, your colours, your subscription. Then your dashboard is ready.'**
  String get signUpSteps;

  /// No description provided for @signInSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your loyalty cards.'**
  String get signInSub;

  /// No description provided for @orWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or with email'**
  String get orWithEmail;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the terms of use, including the data processing agreement, and the privacy policy.'**
  String get agreeToTerms;

  /// No description provided for @collectingStamps.
  ///
  /// In en, this message translates to:
  /// **'Collecting stamps? Go to your cards'**
  String get collectingStamps;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Stamp cards your\nclients actually keep.'**
  String get heroTitle;

  /// No description provided for @heroSub.
  ///
  /// In en, this message translates to:
  /// **'One tap on an NFC tag. No app to install. Your logo, your colours, your rewards.'**
  String get heroSub;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

  /// No description provided for @yourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get yourBusiness;

  /// No description provided for @yourBusinessSub.
  ///
  /// In en, this message translates to:
  /// **'The name your clients see on their loyalty card.'**
  String get yourBusinessSub;

  /// No description provided for @yourColours.
  ///
  /// In en, this message translates to:
  /// **'Your colours'**
  String get yourColours;

  /// No description provided for @yourColoursSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up to {max}: the card, its gradient and the stamps. You can fine-tune each card later.'**
  String yourColoursSub(int max);

  /// No description provided for @loyaltyCard.
  ///
  /// In en, this message translates to:
  /// **'Loyalty card'**
  String get loyaltyCard;

  /// No description provided for @coloursChosen.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} chosen. Tap a colour again to remove it.'**
  String coloursChosen(int count, int max);

  /// No description provided for @subscriptionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has ended'**
  String get subscriptionEnded;

  /// No description provided for @startSubscription.
  ///
  /// In en, this message translates to:
  /// **'Start your subscription'**
  String get startSubscription;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get almostThere;

  /// No description provided for @tagsPausedSub.
  ///
  /// In en, this message translates to:
  /// **'Your tags are paused. Clients keep their stamps and can still use rewards they earned.'**
  String get tagsPausedSub;

  /// No description provided for @dashboardOpensWhenPaid.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard opens and your tags work as soon as the payment is confirmed. Cancel anytime.'**
  String get dashboardOpensWhenPaid;

  /// No description provided for @dashboardOpensWhenActive.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard opens as soon as this account has an active subscription.'**
  String get dashboardOpensWhenActive;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @switchingOn.
  ///
  /// In en, this message translates to:
  /// **'Switching on your account. This takes a few seconds.'**
  String get switchingOn;

  /// No description provided for @takingLonger.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than usual. Your dashboard opens by itself as soon as the payment is confirmed. If you left the payment page without paying, go back to the payment step.'**
  String get takingLonger;

  /// No description provided for @backToPayment.
  ///
  /// In en, this message translates to:
  /// **'Back to payment'**
  String get backToPayment;

  /// No description provided for @paymentProblem.
  ///
  /// In en, this message translates to:
  /// **'Payment problem'**
  String get paymentProblem;

  /// No description provided for @paymentProblemSub.
  ///
  /// In en, this message translates to:
  /// **'Update your payment method to keep your tags working.'**
  String get paymentProblemSub;

  /// No description provided for @loyiForBusiness.
  ///
  /// In en, this message translates to:
  /// **'Loyi for business'**
  String get loyiForBusiness;

  /// No description provided for @planTagline.
  ///
  /// In en, this message translates to:
  /// **'Digital stamp cards your clients actually keep.'**
  String get planTagline;

  /// No description provided for @perkTags.
  ///
  /// In en, this message translates to:
  /// **'Your NFC join and stamp tags, switched on'**
  String get perkTags;

  /// No description provided for @perkUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited loyalty cards and rewards'**
  String get perkUnlimited;

  /// No description provided for @perkBrand.
  ///
  /// In en, this message translates to:
  /// **'Your logo, colours and card design'**
  String get perkBrand;

  /// No description provided for @perkDashboard.
  ///
  /// In en, this message translates to:
  /// **'Live overview, client follow-up and insights'**
  String get perkDashboard;

  /// No description provided for @perkNoInstall.
  ///
  /// In en, this message translates to:
  /// **'Nothing for your clients to install'**
  String get perkNoInstall;

  /// No description provided for @youreSubscribed.
  ///
  /// In en, this message translates to:
  /// **'You\'re subscribed'**
  String get youreSubscribed;

  /// No description provided for @tagsLive.
  ///
  /// In en, this message translates to:
  /// **'Your tags are live.'**
  String get tagsLive;

  /// No description provided for @tagsLiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Your tags are live until {date}.'**
  String tagsLiveUntil(Object date);

  /// No description provided for @lastPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Your last payment didn\'t go through. Update your payment method before {date} to keep your tags working.'**
  String lastPaymentFailed(Object date);

  /// No description provided for @renewsOn.
  ///
  /// In en, this message translates to:
  /// **'Your tags are live. Renews on {date}.'**
  String renewsOn(Object date);

  /// No description provided for @wontRenew.
  ///
  /// In en, this message translates to:
  /// **'Your tags are live until {date}. The subscription won\'t renew.'**
  String wontRenew(Object date);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @manageSubscriptionSub.
  ///
  /// In en, this message translates to:
  /// **'Change your payment method, download invoices or cancel.'**
  String get manageSubscriptionSub;

  /// No description provided for @switchingOnTags.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Switching on your tags…'**
  String get switchingOnTags;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @perMonthExclVat.
  ///
  /// In en, this message translates to:
  /// **' / month excl. VAT'**
  String get perMonthExclVat;

  /// No description provided for @cardOrBancontact.
  ///
  /// In en, this message translates to:
  /// **'Card or Bancontact. Cancel anytime.'**
  String get cardOrBancontact;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @stripeNote.
  ///
  /// In en, this message translates to:
  /// **'You pay securely with Stripe. The subscription renews every month until you cancel; cancel anytime under Subscription → Manage subscription. You get an invoice for every payment.'**
  String get stripeNote;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get noActiveSubscription;

  /// No description provided for @noActiveSubscriptionSub.
  ///
  /// In en, this message translates to:
  /// **'This account doesn\'t have an active Loyi subscription.'**
  String get noActiveSubscriptionSub;

  /// No description provided for @subscriptionsNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t set up in this build.'**
  String get subscriptionsNotSetUp;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutesCount(int count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @giveCardName.
  ///
  /// In en, this message translates to:
  /// **'Give your card a name.'**
  String get giveCardName;

  /// No description provided for @addOneReward.
  ///
  /// In en, this message translates to:
  /// **'Add at least one reward.'**
  String get addOneReward;

  /// No description provided for @cardCreated.
  ///
  /// In en, this message translates to:
  /// **'Card created. Now add your NFC tags below.'**
  String get cardCreated;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save. {reason}'**
  String couldNotSave(Object reason);

  /// No description provided for @yourCardName.
  ///
  /// In en, this message translates to:
  /// **'Your card name'**
  String get yourCardName;

  /// No description provided for @newLoyaltyCard.
  ///
  /// In en, this message translates to:
  /// **'New loyalty card'**
  String get newLoyaltyCard;

  /// No description provided for @editLoyaltyCard.
  ///
  /// In en, this message translates to:
  /// **'Edit loyalty card'**
  String get editLoyaltyCard;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// No description provided for @cardNameSub.
  ///
  /// In en, this message translates to:
  /// **'Short and descriptive; clients see it under your business name.'**
  String get cardNameSub;

  /// No description provided for @cardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Koffiekaart'**
  String get cardNameHint;

  /// No description provided for @design.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// No description provided for @stampsForFullCard.
  ///
  /// In en, this message translates to:
  /// **'Stamps for a full card'**
  String get stampsForFullCard;

  /// No description provided for @stampsForFullCardSub.
  ///
  /// In en, this message translates to:
  /// **'6 to 10 stamps feels achievable for most clients; more can feel out of reach.'**
  String get stampsForFullCardSub;

  /// No description provided for @fewerStamps.
  ///
  /// In en, this message translates to:
  /// **'Fewer stamps'**
  String get fewerStamps;

  /// No description provided for @moreStamps.
  ///
  /// In en, this message translates to:
  /// **'More stamps'**
  String get moreStamps;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @rewardsSub.
  ///
  /// In en, this message translates to:
  /// **'Clients with a full card choose one of the active rewards. Switch rewards on or off anytime, e.g. a different reward each week.'**
  String get rewardsSub;

  /// No description provided for @rewardHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Free coffee'**
  String get rewardHint;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @hiddenFromClients.
  ///
  /// In en, this message translates to:
  /// **'Hidden from clients'**
  String get hiddenFromClients;

  /// No description provided for @addReward.
  ///
  /// In en, this message translates to:
  /// **'Add reward'**
  String get addReward;

  /// No description provided for @timeBetweenStamps.
  ///
  /// In en, this message translates to:
  /// **'Time between stamps'**
  String get timeBetweenStamps;

  /// No description provided for @timeBetweenStampsSub.
  ///
  /// In en, this message translates to:
  /// **'The minimum wait before the same client can get another stamp. Stops double taps.'**
  String get timeBetweenStampsSub;

  /// No description provided for @cardIsLive.
  ///
  /// In en, this message translates to:
  /// **'Card is live'**
  String get cardIsLive;

  /// No description provided for @cardIsLiveSub.
  ///
  /// In en, this message translates to:
  /// **'When paused, taps are refused but clients keep their stamps.'**
  String get cardIsLiveSub;

  /// No description provided for @createCard.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get createCard;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @nfcTags.
  ///
  /// In en, this message translates to:
  /// **'NFC tags'**
  String get nfcTags;

  /// No description provided for @nfcTagsSub.
  ///
  /// In en, this message translates to:
  /// **'Every tag is a link. Write it onto an NFC sticker.'**
  String get nfcTagsSub;

  /// No description provided for @noTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Create one join tag and one stamp tag to get started.'**
  String get noTagsYet;

  /// No description provided for @addJoinTag.
  ///
  /// In en, this message translates to:
  /// **'Add join tag'**
  String get addJoinTag;

  /// No description provided for @addStampTag.
  ///
  /// In en, this message translates to:
  /// **'Add stamp tag'**
  String get addStampTag;

  /// No description provided for @tagStep1.
  ///
  /// In en, this message translates to:
  /// **'Join tag, where clients can see it'**
  String get tagStep1;

  /// No description provided for @tagStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'At the door or on the counter. Tapping it adds the card.'**
  String get tagStep1Sub;

  /// No description provided for @tagStep2.
  ///
  /// In en, this message translates to:
  /// **'Stamp tag, behind the counter'**
  String get tagStep2;

  /// No description provided for @tagStep2Sub.
  ///
  /// In en, this message translates to:
  /// **'Hold it out after a purchase. Every tap gives one stamp.'**
  String get tagStep2Sub;

  /// No description provided for @programStickers.
  ///
  /// In en, this message translates to:
  /// **'Program the stickers'**
  String get programStickers;

  /// No description provided for @programStickersSub.
  ///
  /// In en, this message translates to:
  /// **'Use NTAG213/215 stickers. Copy the link and write it as a URL record with a free app like NFC Tools.'**
  String get programStickersSub;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get never;

  /// No description provided for @joinTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Join tag · {label}'**
  String joinTagLabel(Object label);

  /// No description provided for @stampTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Stamp tag · {label}'**
  String stampTagLabel(Object label);

  /// No description provided for @tapsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tap} other{{count} taps}} · last {when}'**
  String tapsSummary(int count, String when);

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQrCode;

  /// No description provided for @joinQrCode.
  ///
  /// In en, this message translates to:
  /// **'Join QR code'**
  String get joinQrCode;

  /// No description provided for @joinQrCodeSub.
  ///
  /// In en, this message translates to:
  /// **'Print it for clients without NFC.'**
  String get joinQrCodeSub;

  /// No description provided for @defaultJoinTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get defaultJoinTagLabel;

  /// No description provided for @defaultStampTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get defaultStampTagLabel;

  /// No description provided for @newJoinTag.
  ///
  /// In en, this message translates to:
  /// **'New join tag'**
  String get newJoinTag;

  /// No description provided for @newStampTag.
  ///
  /// In en, this message translates to:
  /// **'New stamp tag'**
  String get newStampTag;

  /// No description provided for @whereIsTag.
  ///
  /// In en, this message translates to:
  /// **'Where is this tag?'**
  String get whereIsTag;

  /// No description provided for @methodEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email and password'**
  String get methodEmailPassword;

  /// No description provided for @methodApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get methodApple;

  /// No description provided for @methodNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved (this browser only)'**
  String get methodNotSaved;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @signInMethod.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get signInMethod;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @signInSecurity.
  ///
  /// In en, this message translates to:
  /// **'Sign-in & security'**
  String get signInSecurity;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @noLoyiPassword.
  ///
  /// In en, this message translates to:
  /// **'You sign in with {provider}, so there is no Loyi password. Manage your email and security in your {provider} account.'**
  String noLoyiPassword(Object provider);

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataBusiness.
  ///
  /// In en, this message translates to:
  /// **'Loyi stores your account, your shop (name, colours, logo), your loyalty cards and tags, your subscription status and your clients\' stamps and rewards under anonymous IDs.'**
  String get yourDataBusiness;

  /// No description provided for @yourDataClient.
  ///
  /// In en, this message translates to:
  /// **'Loyi stores your cards, stamps and rewards per shop. Shops only see an anonymous ID, never your email.'**
  String get yourDataClient;

  /// No description provided for @yourDataClientEmail.
  ///
  /// In en, this message translates to:
  /// **'Loyi stores your cards, stamps and rewards per shop, and your email. Shops only see an anonymous ID, never your email.'**
  String get yourDataClientEmail;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read the privacy policy'**
  String get readPrivacyPolicy;

  /// No description provided for @deleteCardsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete the cards on this device'**
  String get deleteCardsOnDevice;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters for your new password.'**
  String get newPasswordTooShort;

  /// No description provided for @emailUsedByOther.
  ///
  /// In en, this message translates to:
  /// **'Another account already uses this email.'**
  String get emailUsedByOther;

  /// No description provided for @signInAgainRetry.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and retry.'**
  String get signInAgainRetry;

  /// No description provided for @thatDidntWork.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Please try again.'**
  String get thatDidntWork;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords don\'t match.'**
  String get passwordsDontMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password is changed.'**
  String get passwordChanged;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPassword;

  /// No description provided for @checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get checkInbox;

  /// No description provided for @emailChangeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {newEmail}. Your email changes as soon as you open it. Until then, keep signing in with {oldEmail}.'**
  String emailChangeSent(Object newEmail, Object oldEmail);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @newEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get newEmail;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @ofStamps.
  ///
  /// In en, this message translates to:
  /// **' / {total} stamps'**
  String ofStamps(int total);

  /// No description provided for @toGo.
  ///
  /// In en, this message translates to:
  /// **'{count} to go'**
  String toGo(int count);

  /// No description provided for @cardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{business}, {card}: {stamps} of {total} stamps'**
  String cardSemantic(String business, String card, int stamps, int total);

  /// No description provided for @rewardsReadySuffix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{, 1 reward ready} other{, {count} rewards ready}}'**
  String rewardsReadySuffix(int count);

  /// No description provided for @rewardsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reward} other{{count} rewards}}'**
  String rewardsBadge(int count);

  /// No description provided for @cardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card} other{{count} cards}}'**
  String cardsCount(int count);

  /// No description provided for @rewardsReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reward ready} other{{count} rewards ready}}'**
  String rewardsReady(int count);

  /// No description provided for @iHaveABusiness.
  ///
  /// In en, this message translates to:
  /// **'I have a business'**
  String get iHaveABusiness;

  /// No description provided for @noCardsYet.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get noCardsYet;

  /// No description provided for @noCardsYetSub.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone near a Loyi tag in a shop to get your first loyalty card.'**
  String get noCardsYetSub;

  /// No description provided for @cardsSaved.
  ///
  /// In en, this message translates to:
  /// **'Your cards are saved.'**
  String get cardsSaved;

  /// No description provided for @emailOtherMethod.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account with another sign-in method. Use that one.'**
  String get emailOtherMethod;

  /// No description provided for @emailHasAccountChoose.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Choose \"I have an account\".'**
  String get emailHasAccountChoose;

  /// No description provided for @passwordTooShort6.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters for your password.'**
  String get passwordTooShort6;

  /// No description provided for @accountAndCardsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account and cards are deleted.'**
  String get accountAndCardsDeleted;

  /// No description provided for @yourCardsAreSaved.
  ///
  /// In en, this message translates to:
  /// **'Your cards are saved'**
  String get yourCardsAreSaved;

  /// No description provided for @yourCardsAreSavedSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with this account on any device to see your cards.'**
  String get yourCardsAreSavedSub;

  /// No description provided for @keepCardsSafe.
  ///
  /// In en, this message translates to:
  /// **'Keep your cards safe'**
  String get keepCardsSafe;

  /// No description provided for @keepCardsSafeSub.
  ///
  /// In en, this message translates to:
  /// **'Your stamps are stored in this browser. Save them to an account and they follow you to any phone. Already have an account? Your cards from this device are added to it.'**
  String get keepCardsSafeSub;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @iHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'I have an account'**
  String get iHaveAnAccount;

  /// No description provided for @saveMyCards.
  ///
  /// In en, this message translates to:
  /// **'Save my cards'**
  String get saveMyCards;

  /// No description provided for @addingToCard.
  ///
  /// In en, this message translates to:
  /// **'Adding to your card…'**
  String get addingToCard;

  /// No description provided for @onlyAMoment.
  ///
  /// In en, this message translates to:
  /// **'This only takes a moment.'**
  String get onlyAMoment;

  /// No description provided for @thatDidntWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work'**
  String get thatDidntWorkTitle;

  /// No description provided for @rewardRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed'**
  String get rewardRedeemed;

  /// No description provided for @redeemedAtShowStaff.
  ///
  /// In en, this message translates to:
  /// **'Redeemed at {time} · show this screen to staff'**
  String redeemedAtShowStaff(Object time);

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get myCards;

  /// No description provided for @cardNotOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Card not found on this device'**
  String get cardNotOnDevice;

  /// No description provided for @goToMyCards.
  ///
  /// In en, this message translates to:
  /// **'Go to my cards'**
  String get goToMyCards;

  /// No description provided for @savedOnCard.
  ///
  /// In en, this message translates to:
  /// **'Saved on your card. Use it now or later.'**
  String get savedOnCard;

  /// No description provided for @noRewardsNow.
  ///
  /// In en, this message translates to:
  /// **'This shop has no rewards available right now.'**
  String get noRewardsNow;

  /// No description provided for @moreToGo.
  ///
  /// In en, this message translates to:
  /// **'more to go'**
  String get moreToGo;

  /// No description provided for @thenChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Then choose one of these'**
  String get thenChooseOne;

  /// No description provided for @stampsCollected.
  ///
  /// In en, this message translates to:
  /// **'stamps collected'**
  String get stampsCollected;

  /// No description provided for @rewardsUsedLower.
  ///
  /// In en, this message translates to:
  /// **'rewards used'**
  String get rewardsUsedLower;

  /// No description provided for @useAReward.
  ///
  /// In en, this message translates to:
  /// **'Use a reward'**
  String get useAReward;

  /// No description provided for @chooseYourReward.
  ///
  /// In en, this message translates to:
  /// **'Choose your reward'**
  String get chooseYourReward;

  /// No description provided for @usesOneFullCard.
  ///
  /// In en, this message translates to:
  /// **'This uses one full card.'**
  String get usesOneFullCard;

  /// No description provided for @onlyAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Only do this at the counter. Staff need to see the confirmation screen.'**
  String get onlyAtCounter;

  /// No description provided for @useItNow.
  ///
  /// In en, this message translates to:
  /// **'Use it now'**
  String get useItNow;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @cardFull.
  ///
  /// In en, this message translates to:
  /// **'Card full!'**
  String get cardFull;

  /// No description provided for @cardFullSub.
  ///
  /// In en, this message translates to:
  /// **'You earned a reward. Use it now or on a later visit.'**
  String get cardFullSub;

  /// No description provided for @stampAdded.
  ///
  /// In en, this message translates to:
  /// **'Stamp added'**
  String get stampAdded;

  /// No description provided for @thanksForVisit.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your visit!'**
  String get thanksForVisit;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Your card is ready. Tap the counter tag after each purchase.'**
  String get welcomeSub;

  /// No description provided for @yourCard.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get yourCard;

  /// No description provided for @alreadyHaveCard.
  ///
  /// In en, this message translates to:
  /// **'You already have this card.'**
  String get alreadyHaveCard;

  /// No description provided for @alreadyStamped.
  ///
  /// In en, this message translates to:
  /// **'Already stamped'**
  String get alreadyStamped;

  /// No description provided for @nextStampIn.
  ///
  /// In en, this message translates to:
  /// **'Your next stamp is possible in {wait}.'**
  String nextStampIn(Object wait);

  /// No description provided for @waitHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String waitHoursMinutes(int hours, int minutes);

  /// No description provided for @waitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String waitMinutes(int minutes);

  /// No description provided for @shopMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages from shops'**
  String get shopMessagesTitle;

  /// No description provided for @shopMessagesSub.
  ///
  /// In en, this message translates to:
  /// **'Shops can show a short message on your card, for example when a reward is waiting. Your phone picks them from your own card; shops never see who reads them.'**
  String get shopMessagesSub;

  /// No description provided for @showShopMessages.
  ///
  /// In en, this message translates to:
  /// **'Show messages from shops'**
  String get showShopMessages;

  /// No description provided for @turnOffShopMessages.
  ///
  /// In en, this message translates to:
  /// **'Turn off messages from shops'**
  String get turnOffShopMessages;

  /// No description provided for @shopMessagesTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Messages from shops are off. You can turn them on again under Account & privacy.'**
  String get shopMessagesTurnedOff;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'fr':
      return L10nFr();
    case 'nl':
      return L10nNl();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
