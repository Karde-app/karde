import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('am'),
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Karde'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Karde'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your secure, offline digital wallet'**
  String get welcomeSubtitle;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline & Encrypted'**
  String get offlineBadge;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @addACard.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get addACard;

  /// No description provided for @openVault.
  ///
  /// In en, this message translates to:
  /// **'Open Vault'**
  String get openVault;

  /// No description provided for @vaultHealthExcellent.
  ///
  /// In en, this message translates to:
  /// **'Vault health: excellent'**
  String get vaultHealthExcellent;

  /// No description provided for @vaultHealthItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items encrypted with AES-256-GCM'**
  String vaultHealthItems(int count);

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @vaultTab.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @myVault.
  ///
  /// In en, this message translates to:
  /// **'My Vault'**
  String get myVault;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @cardsFilter.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsFilter;

  /// No description provided for @idsFilter.
  ///
  /// In en, this message translates to:
  /// **'IDs • Soon'**
  String get idsFilter;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// No description provided for @identification.
  ///
  /// In en, this message translates to:
  /// **'IDENTIFICATION'**
  String get identification;

  /// No description provided for @issuerLabel.
  ///
  /// In en, this message translates to:
  /// **'ISSUER'**
  String get issuerLabel;

  /// No description provided for @issuerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bank Name or Provider'**
  String get issuerHint;

  /// No description provided for @cardNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Network'**
  String get cardNetworkLabel;

  /// No description provided for @cardholderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'CARDHOLDER NAME'**
  String get cardholderNameLabel;

  /// No description provided for @cardholderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get cardholderNameHint;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'CARD DETAILS'**
  String get cardDetails;

  /// No description provided for @cardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'CARD NUMBER'**
  String get cardNumberLabel;

  /// No description provided for @cardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'0000 0000 0000 0000'**
  String get cardNumberHint;

  /// No description provided for @expiryLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPIRY'**
  String get expiryLabel;

  /// No description provided for @expiryHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryHint;

  /// No description provided for @cvvLabel.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvvLabel;

  /// No description provided for @cvvHint.
  ///
  /// In en, this message translates to:
  /// **'123'**
  String get cvvHint;

  /// No description provided for @extraInfo.
  ///
  /// In en, this message translates to:
  /// **'EXTRA INFO (OPTIONAL)'**
  String get extraInfo;

  /// No description provided for @privateNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE NOTES'**
  String get privateNotesLabel;

  /// No description provided for @privateNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Bank phone numbers, PIN hints...'**
  String get privateNotesHint;

  /// No description provided for @saveItem.
  ///
  /// In en, this message translates to:
  /// **'Save Item'**
  String get saveItem;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// No description provided for @cardDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetailsTitle;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @deleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete card'**
  String get deleteCard;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// No description provided for @setupLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Wallet'**
  String get setupLockTitle;

  /// No description provided for @setupLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to protect your secrets?'**
  String get setupLockSubtitle;

  /// No description provided for @phoneLock.
  ///
  /// In en, this message translates to:
  /// **'Phone Lock'**
  String get phoneLock;

  /// No description provided for @phoneLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your device\'s Face ID, Touch ID, or passcode.'**
  String get phoneLockDesc;

  /// No description provided for @kardePin.
  ///
  /// In en, this message translates to:
  /// **'Karde PIN'**
  String get kardePin;

  /// No description provided for @kardePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a dedicated PIN just for this app.'**
  String get kardePinDesc;

  /// No description provided for @bothLocks.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get bothLocks;

  /// No description provided for @bothLocksDesc.
  ///
  /// In en, this message translates to:
  /// **'Phone lock to open app, Karde PIN to view secrets.'**
  String get bothLocksDesc;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your new PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @reEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter your PIN'**
  String get reEnterPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @enterKardePin.
  ///
  /// In en, this message translates to:
  /// **'Enter Karde PIN'**
  String get enterKardePin;

  /// No description provided for @unlockToReveal.
  ///
  /// In en, this message translates to:
  /// **'Unlock to reveal secrets'**
  String get unlockToReveal;

  /// No description provided for @recoverySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN Recovery'**
  String get recoverySetupTitle;

  /// No description provided for @recoverySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to recover your PIN if you forget it?'**
  String get recoverySetupSubtitle;

  /// No description provided for @biometricRecovery.
  ///
  /// In en, this message translates to:
  /// **'Phone Biometrics'**
  String get biometricRecovery;

  /// No description provided for @biometricRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your device\'s fingerprint or Face ID to reset your PIN.'**
  String get biometricRecoveryDesc;

  /// No description provided for @securityQuestions.
  ///
  /// In en, this message translates to:
  /// **'Security Questions'**
  String get securityQuestions;

  /// No description provided for @securityQuestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Answer 2 personal questions to reset your PIN.'**
  String get securityQuestionsDesc;

  /// No description provided for @noRecovery.
  ///
  /// In en, this message translates to:
  /// **'No Recovery'**
  String get noRecovery;

  /// No description provided for @noRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum security. Forgetting your PIN means permanent data loss.'**
  String get noRecoveryDesc;

  /// No description provided for @setupQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Security Questions'**
  String get setupQuestionsTitle;

  /// No description provided for @setupQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose 2 questions and answers'**
  String get setupQuestionsSubtitle;

  /// No description provided for @question1.
  ///
  /// In en, this message translates to:
  /// **'Question 1'**
  String get question1;

  /// No description provided for @question2.
  ///
  /// In en, this message translates to:
  /// **'Question 2'**
  String get question2;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @answerRequired.
  ///
  /// In en, this message translates to:
  /// **'Answer is required'**
  String get answerRequired;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @resetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPinTitle;

  /// No description provided for @resetPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a recovery method'**
  String get resetPinSubtitle;

  /// No description provided for @wipeDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Wipe App Data (Danger)'**
  String get wipeDataBtn;

  /// No description provided for @wipeDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your saved cards and reset the app. Are you sure?'**
  String get wipeDataWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @wipe.
  ///
  /// In en, this message translates to:
  /// **'Wipe'**
  String get wipe;

  /// No description provided for @verifyQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer Security Questions'**
  String get verifyQuestionsTitle;

  /// No description provided for @verifyQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer both questions to reset your PIN'**
  String get verifyQuestionsSubtitle;

  /// No description provided for @verifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyBtn;

  /// No description provided for @wrongAnswers.
  ///
  /// In en, this message translates to:
  /// **'One or both answers are incorrect.'**
  String get wrongAnswers;

  /// No description provided for @resetPinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification successful. You can now set a new PIN.'**
  String get resetPinSuccess;

  /// No description provided for @maxAttemptsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum attempts reached. You must reset your PIN.'**
  String get maxAttemptsReached;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
