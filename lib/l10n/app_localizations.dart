import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  /// **'Your secure, offline vault'**
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
  /// **'{count, plural, =1{1 item encrypted with AES-256-GCM} other{{count} items encrypted with AES-256-GCM}}'**
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
  /// **'IDs'**
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

  /// No description provided for @setupLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Vault'**
  String get setupLockTitle;

  /// No description provided for @setupLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to open Karde?'**
  String get setupLockSubtitle;

  /// No description provided for @phoneLock.
  ///
  /// In en, this message translates to:
  /// **'Phone Lock'**
  String get phoneLock;

  /// No description provided for @phoneLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s Face ID, Touch ID or passcode.'**
  String get phoneLockDesc;

  /// No description provided for @lockChoiceChangeableLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get lockChoiceChangeableLater;

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
  /// **'Your phone\'s lock to open Karde, and a Karde PIN for sensitive actions.'**
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
  /// **'If you forget your Karde PIN'**
  String get recoverySetupTitle;

  /// No description provided for @recoverySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would reset it and get back into Karde.'**
  String get recoverySetupSubtitle;

  /// No description provided for @biometricRecovery.
  ///
  /// In en, this message translates to:
  /// **'Phone Lock'**
  String get biometricRecovery;

  /// No description provided for @biometricRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your device\'s Face ID, Touch ID or passcode.'**
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

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDesc.
  ///
  /// In en, this message translates to:
  /// **'System, Light or Dark'**
  String get themeDesc;

  /// No description provided for @appDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get appDisplayLanguage;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacy;

  /// No description provided for @autoHide.
  ///
  /// In en, this message translates to:
  /// **'Auto-hide sensitive details'**
  String get autoHide;

  /// No description provided for @autoHideDesc.
  ///
  /// In en, this message translates to:
  /// **'Mask card number & CVV automatically'**
  String get autoHideDesc;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security;

  /// No description provided for @appPinLock.
  ///
  /// In en, this message translates to:
  /// **'Karde PIN'**
  String get appPinLock;

  /// No description provided for @appPinLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask for it when opening Karde and changing these settings'**
  String get appPinLockDesc;

  /// No description provided for @biometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone lock'**
  String get biometricUnlockTitle;

  /// No description provided for @biometricUnlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Open Karde with your fingerprint, face or screen lock'**
  String get biometricUnlockDesc;

  /// No description provided for @keepPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your Karde PIN?'**
  String get keepPinTitle;

  /// No description provided for @keepPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Karde will stop asking for it either way. Keep it, and switching this back on later uses the same PIN — so you would need to remember it. Delete it, and you choose a new one next time.'**
  String get keepPinMessage;

  /// No description provided for @keepPinKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepPinKeep;

  /// No description provided for @keepPinDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete it'**
  String get keepPinDelete;

  /// No description provided for @pinDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your Karde PIN has been deleted.'**
  String get pinDeleted;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change Karde PIN'**
  String get changePin;

  /// No description provided for @changePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN for opening Karde'**
  String get changePinDesc;

  /// No description provided for @createKardePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN of your own for opening Karde'**
  String get createKardePinDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @aboutKarde.
  ///
  /// In en, this message translates to:
  /// **'About Karde'**
  String get aboutKarde;

  /// No description provided for @aboutKardeDesc.
  ///
  /// In en, this message translates to:
  /// **'Version, credits & licenses'**
  String get aboutKardeDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'How your data stays on-device'**
  String get privacyPolicyDesc;

  /// No description provided for @mustKeepOneLock.
  ///
  /// In en, this message translates to:
  /// **'You must keep at least one lock method enabled.'**
  String get mustKeepOneLock;

  /// No description provided for @biometricsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not supported on this device.'**
  String get biometricsNotSupported;

  /// No description provided for @biometricsError.
  ///
  /// In en, this message translates to:
  /// **'Error checking biometric support.'**
  String get biometricsError;

  /// No description provided for @invalidCardLength.
  ///
  /// In en, this message translates to:
  /// **'Invalid card length'**
  String get invalidCardLength;

  /// No description provided for @invalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid card number'**
  String get invalidCardNumber;

  /// No description provided for @invalidExpiryFormat.
  ///
  /// In en, this message translates to:
  /// **'Format must be MM/YY'**
  String get invalidExpiryFormat;

  /// No description provided for @invalidMonth.
  ///
  /// In en, this message translates to:
  /// **'Invalid month'**
  String get invalidMonth;

  /// No description provided for @cardExpired.
  ///
  /// In en, this message translates to:
  /// **'Card has expired'**
  String get cardExpired;

  /// No description provided for @invalidCvvLength.
  ///
  /// In en, this message translates to:
  /// **'CVV must be 3 or 4 digits'**
  String get invalidCvvLength;

  /// No description provided for @numbersOnly.
  ///
  /// In en, this message translates to:
  /// **'Numbers only'**
  String get numbersOnly;

  /// No description provided for @lettersAndSymbolsNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Letters and symbols are not allowed'**
  String get lettersAndSymbolsNotAllowed;

  /// No description provided for @kardeIsLocked.
  ///
  /// In en, this message translates to:
  /// **'Karde is Locked'**
  String get kardeIsLocked;

  /// No description provided for @noScreenLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone has no screen lock'**
  String get noScreenLockTitle;

  /// No description provided for @noScreenLockBody.
  ///
  /// In en, this message translates to:
  /// **'Karde keeps everything locked with your phone’s own security, so without a screen lock it cannot open or save anything. Set a PIN, pattern, password or fingerprint in your phone’s settings, then come back.'**
  String get noScreenLockBody;

  /// No description provided for @openPhoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Open phone settings'**
  String get openPhoneSettings;

  /// No description provided for @authenticateToAccess.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your vault.'**
  String get authenticateToAccess;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @unlockKarde.
  ///
  /// In en, this message translates to:
  /// **'Unlock Karde'**
  String get unlockKarde;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current Karde PIN'**
  String get enterCurrentPin;

  /// No description provided for @createKardePin.
  ///
  /// In en, this message translates to:
  /// **'Create Karde PIN'**
  String get createKardePin;

  /// No description provided for @pinChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN Successfully Changed'**
  String get pinChangedSuccess;

  /// No description provided for @pinCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Karde PIN Created'**
  String get pinCreatedSuccess;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addAnId.
  ///
  /// In en, this message translates to:
  /// **'Add an ID'**
  String get addAnId;

  /// No description provided for @idDetails.
  ///
  /// In en, this message translates to:
  /// **'ID Details'**
  String get idDetails;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @documentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document Number'**
  String get documentNumber;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @sexGender.
  ///
  /// In en, this message translates to:
  /// **'Sex / Gender'**
  String get sexGender;

  /// No description provided for @issuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issuing Country / Authority'**
  String get issuingAuthority;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @placeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Place of Birth'**
  String get placeOfBirth;

  /// No description provided for @personalId.
  ///
  /// In en, this message translates to:
  /// **'Personal ID / SSN'**
  String get personalId;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get tabCards;

  /// No description provided for @tabIds.
  ///
  /// In en, this message translates to:
  /// **'IDs'**
  String get tabIds;

  /// No description provided for @idCardNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get idCardNotAvailable;

  /// No description provided for @idCardPassportTitle.
  ///
  /// In en, this message translates to:
  /// **'INTERNATIONAL PASSPORT'**
  String get idCardPassportTitle;

  /// No description provided for @idCardType.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get idCardType;

  /// No description provided for @idCardCodeOfIssuingState.
  ///
  /// In en, this message translates to:
  /// **'CODE OF ISSUING STATE'**
  String get idCardCodeOfIssuingState;

  /// No description provided for @idCardPassportNo.
  ///
  /// In en, this message translates to:
  /// **'PASSPORT NO.'**
  String get idCardPassportNo;

  /// No description provided for @idCardSurname.
  ///
  /// In en, this message translates to:
  /// **'SURNAME'**
  String get idCardSurname;

  /// No description provided for @idCardGivenNames.
  ///
  /// In en, this message translates to:
  /// **'GIVEN NAMES'**
  String get idCardGivenNames;

  /// No description provided for @idCardNationalityUpper.
  ///
  /// In en, this message translates to:
  /// **'NATIONALITY'**
  String get idCardNationalityUpper;

  /// No description provided for @idCardDobUpper.
  ///
  /// In en, this message translates to:
  /// **'DATE OF BIRTH'**
  String get idCardDobUpper;

  /// No description provided for @idCardSexUpper.
  ///
  /// In en, this message translates to:
  /// **'SEX'**
  String get idCardSexUpper;

  /// No description provided for @idCardPlaceOfBirthUpper.
  ///
  /// In en, this message translates to:
  /// **'PLACE OF BIRTH'**
  String get idCardPlaceOfBirthUpper;

  /// No description provided for @idCardAuthorityUpper.
  ///
  /// In en, this message translates to:
  /// **'AUTHORITY'**
  String get idCardAuthorityUpper;

  /// No description provided for @idCardDateOfIssueUpper.
  ///
  /// In en, this message translates to:
  /// **'DATE OF ISSUE'**
  String get idCardDateOfIssueUpper;

  /// No description provided for @idCardDateOfExpiryUpper.
  ///
  /// In en, this message translates to:
  /// **'DATE OF EXPIRY'**
  String get idCardDateOfExpiryUpper;

  /// No description provided for @idCardHoldersSignature.
  ///
  /// In en, this message translates to:
  /// **'HOLDERS SIGNATURE'**
  String get idCardHoldersSignature;

  /// No description provided for @idCardResidencePermitTitle.
  ///
  /// In en, this message translates to:
  /// **'BIOMETRIC RESIDENCE PERMIT'**
  String get idCardResidencePermitTitle;

  /// No description provided for @idCardName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get idCardName;

  /// No description provided for @idCardGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get idCardGender;

  /// No description provided for @idCardNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get idCardNationality;

  /// No description provided for @idCardDocumentNo.
  ///
  /// In en, this message translates to:
  /// **'Document No.'**
  String get idCardDocumentNo;

  /// No description provided for @idCardNationalFallback.
  ///
  /// In en, this message translates to:
  /// **'NATIONAL'**
  String get idCardNationalFallback;

  /// No description provided for @idCardIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID CARD'**
  String get idCardIdCard;

  /// No description provided for @idCardNationalIdLogo.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get idCardNationalIdLogo;

  /// No description provided for @idCardEthiopianDigitalId.
  ///
  /// In en, this message translates to:
  /// **'Ethiopian Digital ID Card'**
  String get idCardEthiopianDigitalId;

  /// No description provided for @idCardEthiopianFullName.
  ///
  /// In en, this message translates to:
  /// **'First, Middle, Surname'**
  String get idCardEthiopianFullName;

  /// No description provided for @idCardFullNameUpper.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get idCardFullNameUpper;

  /// No description provided for @idCardDateOfExpiry.
  ///
  /// In en, this message translates to:
  /// **'Date of Expiry'**
  String get idCardDateOfExpiry;

  /// No description provided for @idCardCountryOfCitizenship.
  ///
  /// In en, this message translates to:
  /// **'Country of Citizenship (Self-declared)'**
  String get idCardCountryOfCitizenship;

  /// No description provided for @idCardIssuingAuthorityUpper.
  ///
  /// In en, this message translates to:
  /// **'ISSUING AUTHORITY'**
  String get idCardIssuingAuthorityUpper;

  /// No description provided for @idCardIdNo.
  ///
  /// In en, this message translates to:
  /// **'ID NO'**
  String get idCardIdNo;

  /// No description provided for @idCardDrivingLicenceTitle.
  ///
  /// In en, this message translates to:
  /// **'DRIVING LICENCE'**
  String get idCardDrivingLicenceTitle;

  /// No description provided for @idCardNameUpper.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get idCardNameUpper;

  /// No description provided for @idCardPassportNoShort.
  ///
  /// In en, this message translates to:
  /// **'Passport No'**
  String get idCardPassportNoShort;

  /// No description provided for @idCardDlNo.
  ///
  /// In en, this message translates to:
  /// **'DL No'**
  String get idCardDlNo;

  /// No description provided for @idCardDocNo.
  ///
  /// In en, this message translates to:
  /// **'Doc No'**
  String get idCardDocNo;

  /// No description provided for @idCardDocumentFallback.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT'**
  String get idCardDocumentFallback;

  /// No description provided for @idCardDocumentHolder.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT HOLDER'**
  String get idCardDocumentHolder;

  /// No description provided for @idCardDocumentNumberUpper.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT NUMBER'**
  String get idCardDocumentNumberUpper;

  /// No description provided for @idCardValidFrom.
  ///
  /// In en, this message translates to:
  /// **'VALID FROM'**
  String get idCardValidFrom;

  /// No description provided for @idCardExpires.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES'**
  String get idCardExpires;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Keeping a copy'**
  String get backupSetupTitle;

  /// No description provided for @backupSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'Karde saves a copy of everything you keep here, so you can get it all back if this phone is lost, broken or replaced. The copy goes where you choose. Nothing is ever sent to Karde or to anyone else.'**
  String get backupSetupIntro;

  /// No description provided for @backupSetupPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase'**
  String get backupSetupPassphraseTitle;

  /// No description provided for @backupSetupPassphraseBody.
  ///
  /// In en, this message translates to:
  /// **'You will need it to get your things back on a new phone. Karde will keep a copy on this phone that you can look up with your fingerprint, but it can never reset the passphrase — and that copy goes when the phone does. Write it down and keep it somewhere safe.'**
  String get backupSetupPassphraseBody;

  /// No description provided for @backupSetupPassphraseDone.
  ///
  /// In en, this message translates to:
  /// **'Passphrase chosen'**
  String get backupSetupPassphraseDone;

  /// No description provided for @passphraseTooWeakForBackup.
  ///
  /// In en, this message translates to:
  /// **'Please choose a longer passphrase, or add some variety. This copy is kept up to date all the time, so it is worth a moment.'**
  String get passphraseTooWeakForBackup;

  /// No description provided for @passphraseNeedsMixForBackup.
  ///
  /// In en, this message translates to:
  /// **'Please use more than just numbers — add some letters, or a few words. Numbers alone are the first thing anyone guessing would try.'**
  String get passphraseNeedsMixForBackup;

  /// No description provided for @backupSetupFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where it goes'**
  String get backupSetupFolderTitle;

  /// No description provided for @backupSetupFolderBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder on your phone. If you pick one that syncs to cloud storage, your copy survives losing the phone as well.'**
  String get backupSetupFolderBody;

  /// No description provided for @backupSetupFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get backupSetupFolderAction;

  /// No description provided for @backupSetupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get backupSetupFinish;

  /// No description provided for @backupSetupLater.
  ///
  /// In en, this message translates to:
  /// **'Set this up later'**
  String get backupSetupLater;

  /// No description provided for @backupSetupLaterNote.
  ///
  /// In en, this message translates to:
  /// **'Karde could not open a folder picker on this phone. You can carry on and set your backup up from Settings, but nothing you save will be copied anywhere until you do.'**
  String get backupSetupLaterNote;

  /// No description provided for @backupSetupWorking.
  ///
  /// In en, this message translates to:
  /// **'Setting up your backup…'**
  String get backupSetupWorking;

  /// No description provided for @backupSetupDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup is on'**
  String get backupSetupDoneTitle;

  /// No description provided for @backupSetupDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Karde saves a copy every time you add, change or remove something. It goes to {folder}.'**
  String backupSetupDoneBody(String folder);

  /// No description provided for @backupSetupFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Karde could not save to that folder. Please choose another one.'**
  String get backupSetupFolderFailed;

  /// No description provided for @backupSelfTestFailed.
  ///
  /// In en, this message translates to:
  /// **'This phone could not read back the copy it had just saved, so Karde has not switched backup on. Please try again.'**
  String get backupSelfTestFailed;

  /// No description provided for @backupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Backup updated.'**
  String get backupUpdated;

  /// No description provided for @backupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup is not being saved'**
  String get backupFailedTitle;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get alertsTitle;

  /// No description provided for @alertsTitleCalm.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get alertsTitleCalm;

  /// No description provided for @alertsNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your attention.'**
  String get alertsNone;

  /// No description provided for @alertsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Karde will tell you here if something needs looking at.'**
  String get alertsNoneBody;

  /// No description provided for @alertsFix.
  ///
  /// In en, this message translates to:
  /// **'Fix this'**
  String get alertsFix;

  /// No description provided for @alertsSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get alertsSetUp;

  /// No description provided for @alertsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get alertsGotIt;

  /// No description provided for @backupNotSavingShort.
  ///
  /// In en, this message translates to:
  /// **'New changes are not being copied to your backup folder.'**
  String get backupNotSavingShort;

  /// No description provided for @backupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Karde could not save to {folder}. The folder may have been moved, renamed or deleted. Until this is fixed, new changes are not being copied anywhere.'**
  String backupFailedBody(String folder);

  /// No description provided for @backupFailedAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get backupFailedAction;

  /// No description provided for @settingsAutoBackupNote.
  ///
  /// In en, this message translates to:
  /// **'Karde saves a copy every time you add, change or remove something. It goes to {folder}. You can also save one yourself at any time.'**
  String settingsAutoBackupNote(String folder);

  /// No description provided for @backupCouldNotReadVault.
  ///
  /// In en, this message translates to:
  /// **'Could not read your vault. Please try again.'**
  String get backupCouldNotReadVault;

  /// No description provided for @backupVaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is nothing in your vault to back up yet.'**
  String get backupVaultEmpty;

  /// No description provided for @backupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Back up 1 item} other{Back up {count} items}}'**
  String backupConfirmTitle(int count);

  /// No description provided for @backupConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask you to confirm your identity a few times while this runs.\n\nNext you will choose a passphrase and where to save the file.'**
  String get backupConfirmMessage;

  /// No description provided for @backupPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup'**
  String get backupPreparing;

  /// No description provided for @backupUnlockingVault.
  ///
  /// In en, this message translates to:
  /// **'Unlocking your vault'**
  String get backupUnlockingVault;

  /// No description provided for @backupSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Backup saved as {fileName}.'**
  String backupSavedAs(String fileName);

  /// No description provided for @backupOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening backup'**
  String get backupOpening;

  /// No description provided for @backupAllDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Everything in that backup is already in your vault.'**
  String get backupAllDuplicates;

  /// No description provided for @backupNoItems.
  ///
  /// In en, this message translates to:
  /// **'That backup does not contain any items.'**
  String get backupNoItems;

  /// No description provided for @backupSkippedNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is already in your vault and will be skipped.} other{{count} items are already in your vault and will be skipped.}}'**
  String backupSkippedNote(int count);

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restore 1 item} other{Restore {count} items}}'**
  String backupRestoreConfirmTitle(int count);

  /// No description provided for @backupRestoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask you to confirm your identity a few times while this runs.{skipped}\n\nNothing already in your vault is removed or changed.'**
  String backupRestoreConfirmMessage(String skipped);

  /// No description provided for @backupRestoreConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreConfirmAction;

  /// No description provided for @backupRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring'**
  String get backupRestoring;

  /// No description provided for @backupRestoredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restored 1 item to your vault.} other{Restored {count} items to your vault.}}'**
  String backupRestoredCount(int count);

  /// No description provided for @backupRestoreCancelled.
  ///
  /// In en, this message translates to:
  /// **'Restore cancelled. Nothing was changed.'**
  String get backupRestoreCancelled;

  /// No description provided for @backupWrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'That passphrase does not open this backup. Check it and try again.'**
  String get backupWrongPassphrase;

  /// No description provided for @backupFileChooseAgain.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read. Try choosing it again.'**
  String get backupFileChooseAgain;

  /// No description provided for @backupNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock on your device before backing up or restoring.'**
  String get backupNeedsScreenLock;

  /// No description provided for @backupKeyInvalidated.
  ///
  /// In en, this message translates to:
  /// **'Your vault key is no longer valid, so existing items cannot be read. Restoring from a backup will still work.'**
  String get backupKeyInvalidated;

  /// No description provided for @backupExplainerPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Your backup is locked with a passphrase you choose. Without it the file is unreadable — and Karde cannot recover it for you, so keep it somewhere safe.'**
  String get backupExplainerPassphrase;

  /// No description provided for @backupExplainerOffline.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded. You pick where the file goes, and it can be restored on this phone or on a new one.'**
  String get backupExplainerOffline;

  /// No description provided for @backupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a backup'**
  String get backupCreateTitle;

  /// No description provided for @backupCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a locked copy of everything in your vault, wherever you choose.'**
  String get backupCreateSubtitle;

  /// No description provided for @backupCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupCreateAction;

  /// No description provided for @backupRestoreCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get backupRestoreCardTitle;

  /// No description provided for @backupRestoreCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the items from a backup file to this vault. Existing items are kept, and anything already here is skipped.'**
  String get backupRestoreCardSubtitle;

  /// No description provided for @backupRestoreCardAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get backupRestoreCardAction;

  /// No description provided for @backupKeepFileSafe.
  ///
  /// In en, this message translates to:
  /// **'Keep the backup file somewhere you trust. It holds everything in your vault, protected only by the passphrase you chose.'**
  String get backupKeepFileSafe;

  /// No description provided for @backupProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{label} — {completed} of {total}'**
  String backupProgressCount(String label, int completed, int total);

  /// No description provided for @backupConfirmIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity when your phone asks. Cancelling stops everything safely — nothing is changed.'**
  String get backupConfirmIdentityHint;

  /// No description provided for @backupProblemDamaged.
  ///
  /// In en, this message translates to:
  /// **'The backup contents are damaged.'**
  String get backupProblemDamaged;

  /// No description provided for @backupProblemNotKardeBackup.
  ///
  /// In en, this message translates to:
  /// **'That file is not a Karde vault backup.'**
  String get backupProblemNotKardeBackup;

  /// No description provided for @backupProblemNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'That backup was made by a newer version of Karde. Update the app and try again.'**
  String get backupProblemNewerVersion;

  /// No description provided for @backupProblemPhotoDamaged.
  ///
  /// In en, this message translates to:
  /// **'A photo in the backup is damaged.'**
  String get backupProblemPhotoDamaged;

  /// No description provided for @backupProblemMissingValue.
  ///
  /// In en, this message translates to:
  /// **'The backup is missing its \"{key}\" value.'**
  String backupProblemMissingValue(String key);

  /// No description provided for @backupProblemUnreadableValue.
  ///
  /// In en, this message translates to:
  /// **'The backup has an unreadable \"{key}\" value.'**
  String backupProblemUnreadableValue(String key);

  /// No description provided for @backupProblemRecordUnreadable.
  ///
  /// In en, this message translates to:
  /// **'A vault record could not be read.'**
  String get backupProblemRecordUnreadable;

  /// No description provided for @backupProblemFileDamaged.
  ///
  /// In en, this message translates to:
  /// **'That backup file could not be read. It may be damaged.'**
  String get backupProblemFileDamaged;

  /// No description provided for @otherOption.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherOption;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @loadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading Details'**
  String get loadingDetails;

  /// No description provided for @setScreenLockFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock first'**
  String get setScreenLockFirst;

  /// No description provided for @screenLockExplainer.
  ///
  /// In en, this message translates to:
  /// **'Karde encrypts every item with a key held in your phone\'s secure hardware, and that hardware will not hold a key unless the phone itself is locked.\n\nAdd a PIN, pattern, password or fingerprint in your phone\'s settings, then come back.'**
  String get screenLockExplainer;

  /// No description provided for @vaultKeyChangedItemsLost.
  ///
  /// In en, this message translates to:
  /// **'Your device security settings changed, so the vault key is no longer valid. Existing items cannot be recovered.'**
  String get vaultKeyChangedItemsLost;

  /// No description provided for @addCardDecryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decrypt existing card data.'**
  String get addCardDecryptFailed;

  /// No description provided for @addCardNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock (PIN, pattern, or biometrics) on your device to save cards securely.'**
  String get addCardNeedsScreenLock;

  /// No description provided for @addCardSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong saving this card. Please try again.'**
  String get addCardSaveFailed;

  /// No description provided for @selectCardNetwork.
  ///
  /// In en, this message translates to:
  /// **'Select Card Network'**
  String get selectCardNetwork;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Card'**
  String get editCard;

  /// No description provided for @issuerFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuerFieldLabel;

  /// No description provided for @issuerTooltip.
  ///
  /// In en, this message translates to:
  /// **'The name of the bank or institution that issued this card.\n\nExample: Chase Bank'**
  String get issuerTooltip;

  /// No description provided for @customNetworkFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Network'**
  String get customNetworkFieldLabel;

  /// No description provided for @customNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. UnionPay, JCB'**
  String get customNetworkHint;

  /// No description provided for @secureDetails.
  ///
  /// In en, this message translates to:
  /// **'SECURE DETAILS'**
  String get secureDetails;

  /// No description provided for @cardNumberFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumberFieldLabel;

  /// No description provided for @cardholderNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderNameFieldLabel;

  /// No description provided for @privateNotesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Notes'**
  String get privateNotesFieldLabel;

  /// No description provided for @privateNotesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Any additional details, addresses, or context.\n\nExample: Bank Phone: 1-800-123-4567'**
  String get privateNotesTooltip;

  /// No description provided for @cardExpiredStillSave.
  ///
  /// In en, this message translates to:
  /// **'This card has expired. You can still save it.'**
  String get cardExpiredStillSave;

  /// No description provided for @cardPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'CARD PHOTO'**
  String get cardPhotoLabel;

  /// No description provided for @cardPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Kept locked with the rest of the card.'**
  String get cardPhotoHint;

  /// No description provided for @cardPhotoViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Card photo'**
  String get cardPhotoViewerTitle;

  /// Wraps a form field label to mark it as required. The asterisk position is the only thing that varies.
  ///
  /// In en, this message translates to:
  /// **'{label} *'**
  String requiredFieldMarker(String label);

  /// No description provided for @idTypePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get idTypePassport;

  /// No description provided for @idTypeDriversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get idTypeDriversLicense;

  /// No description provided for @idTypeNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get idTypeNationalId;

  /// No description provided for @idTypeResidentPermit.
  ///
  /// In en, this message translates to:
  /// **'Resident Permit'**
  String get idTypeResidentPermit;

  /// No description provided for @selectDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Select Document Type'**
  String get selectDocumentType;

  /// No description provided for @addIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Add ID Document'**
  String get addIdDocument;

  /// No description provided for @editDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit Document'**
  String get editDocument;

  /// No description provided for @idExpiryAfterIssue.
  ///
  /// In en, this message translates to:
  /// **'Expiry must be after the issue date'**
  String get idExpiryAfterIssue;

  /// No description provided for @idDobNotInFuture.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future'**
  String get idDobNotInFuture;

  /// No description provided for @idIssueDateNotInFuture.
  ///
  /// In en, this message translates to:
  /// **'Issue date cannot be in the future'**
  String get idIssueDateNotInFuture;

  /// No description provided for @idUpdatedSecurely.
  ///
  /// In en, this message translates to:
  /// **'ID document updated securely.'**
  String get idUpdatedSecurely;

  /// No description provided for @idAddedSecurely.
  ///
  /// In en, this message translates to:
  /// **'ID document added securely.'**
  String get idAddedSecurely;

  /// No description provided for @cardAddedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Card added securely.'**
  String get cardAddedSecurely;

  /// No description provided for @cardUpdatedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Card updated securely.'**
  String get cardUpdatedSecurely;

  /// No description provided for @cardRemoved.
  ///
  /// In en, this message translates to:
  /// **'Card removed.'**
  String get cardRemoved;

  /// No description provided for @idRemoved.
  ///
  /// In en, this message translates to:
  /// **'ID document removed.'**
  String get idRemoved;

  /// No description provided for @andBackedUp.
  ///
  /// In en, this message translates to:
  /// **'{message} Backup updated.'**
  String andBackedUp(String message);

  /// No description provided for @savedButNotBackedUp.
  ///
  /// In en, this message translates to:
  /// **'{message} It could not be copied to your backup folder yet.'**
  String savedButNotBackedUp(String message);

  /// No description provided for @setUpBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get setUpBackupTitle;

  /// No description provided for @setUpBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Karde can keep a copy of everything, so nothing is lost with this phone.'**
  String get setUpBackupBody;

  /// No description provided for @setUpBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUpBackupAction;

  /// No description provided for @addIdNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock on your device to save documents securely.'**
  String get addIdNeedsScreenLock;

  /// No description provided for @addIdSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong saving this document. Please try again.'**
  String get addIdSaveFailed;

  /// No description provided for @issuingAuthorityTooltip.
  ///
  /// In en, this message translates to:
  /// **'The organization, state, or country that issued the ID.\n\nExample: State of California'**
  String get issuingAuthorityTooltip;

  /// No description provided for @personalIdTooltip.
  ///
  /// In en, this message translates to:
  /// **'A secondary personal identifier.\n\nExample: 123-45-6789'**
  String get personalIdTooltip;

  /// No description provided for @idNotesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Any additional details or address information from the ID.\n\nExample: Organ donor, Class C driver'**
  String get idNotesTooltip;

  /// No description provided for @idUnlockFailedWarning.
  ///
  /// In en, this message translates to:
  /// **'This document could not be unlocked, so its details are not shown. Saving is disabled to avoid overwriting your data. Go back and try again.'**
  String get idUnlockFailedWarning;

  /// No description provided for @customDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Custom Document Type'**
  String get customDocumentType;

  /// No description provided for @customDocumentTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Student ID'**
  String get customDocumentTypeHint;

  /// No description provided for @customDocumentTypeTooltip.
  ///
  /// In en, this message translates to:
  /// **'The specific name of this custom document type.\n\nExample: Gym Pass'**
  String get customDocumentTypeTooltip;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Passport'**
  String get nicknameHint;

  /// No description provided for @nicknameTooltip.
  ///
  /// In en, this message translates to:
  /// **'A personal nickname to easily identify this document in your vault.\n\nExample: My Passport'**
  String get nicknameTooltip;

  /// No description provided for @documentPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT PHOTO'**
  String get documentPhotoLabel;

  /// No description provided for @documentPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Kept locked with the rest of the document.'**
  String get documentPhotoHint;

  /// No description provided for @documentPhotoViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Document photo'**
  String get documentPhotoViewerTitle;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchItems;

  /// No description provided for @pinToTop.
  ///
  /// In en, this message translates to:
  /// **'Pin to Top'**
  String get pinToTop;

  /// No description provided for @unpinFromTop.
  ///
  /// In en, this message translates to:
  /// **'Unpin from Top'**
  String get unpinFromTop;

  /// No description provided for @pinToHomescreen.
  ///
  /// In en, this message translates to:
  /// **'Pin to Homescreen'**
  String get pinToHomescreen;

  /// No description provided for @unpinFromHomescreen.
  ///
  /// In en, this message translates to:
  /// **'Unpin from Homescreen'**
  String get unpinFromHomescreen;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @photoBadge.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoBadge;

  /// No description provided for @tapCardForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap the card for full details'**
  String get tapCardForDetails;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing here matches \"{query}\". Try a different word.'**
  String noMatchesMessage(String query);

  /// No description provided for @noIdsYet.
  ///
  /// In en, this message translates to:
  /// **'No IDs yet'**
  String get noIdsYet;

  /// No description provided for @noIdsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Passports, licences and other documents you add will appear here.'**
  String get noIdsYetMessage;

  /// No description provided for @noCardsYet.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get noCardsYet;

  /// No description provided for @noCardsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Bank cards, loyalty cards and anything else you add will appear here.'**
  String get noCardsYetMessage;

  /// No description provided for @addNewId.
  ///
  /// In en, this message translates to:
  /// **'Add New ID'**
  String get addNewId;

  /// No description provided for @sortItems.
  ///
  /// In en, this message translates to:
  /// **'Sort Items'**
  String get sortItems;

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get sortOldestFirst;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (A-Z)'**
  String get sortAlphabetical;

  /// No description provided for @settingsSecurityQuestions.
  ///
  /// In en, this message translates to:
  /// **'Change security questions'**
  String get settingsSecurityQuestions;

  /// No description provided for @settingsSecurityQuestionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add security questions'**
  String get settingsSecurityQuestionsAdd;

  /// No description provided for @settingsSecurityQuestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Change the questions used to recover your PIN'**
  String get settingsSecurityQuestionsDesc;

  /// No description provided for @settingsSecurityQuestionsAddDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up questions that let you reset your Karde PIN'**
  String get settingsSecurityQuestionsAddDesc;

  /// No description provided for @settingsBackupSection.
  ///
  /// In en, this message translates to:
  /// **'BACKUP'**
  String get settingsBackupSection;

  /// No description provided for @settingsBackupRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Save an encrypted copy of your vault, or restore one'**
  String get settingsBackupRestoreDesc;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get settingsDangerZone;

  /// No description provided for @settingsEraseVault.
  ///
  /// In en, this message translates to:
  /// **'Erase vault'**
  String get settingsEraseVault;

  /// No description provided for @settingsEraseVaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete every card, ID, photo and setting'**
  String get settingsEraseVaultDesc;

  /// No description provided for @aboutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'{name} v{version}\n\nAn offline vault for the cards and documents you would rather not carry.\n\nEverything you save is encrypted on this phone and unlocked with your fingerprint. Karde has no account and no internet access, so nothing you store can leave your device — not to us, not to anyone.\n\nBecause nothing is kept anywhere else, an encrypted backup is the only way to move your vault to a new phone.'**
  String aboutDialogBody(String name, String version);

  /// No description provided for @eraseEverythingTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase everything?'**
  String get eraseEverythingTitle;

  /// No description provided for @eraseEverythingMessage.
  ///
  /// In en, this message translates to:
  /// **'Every card, ID document and photo will be permanently deleted, along with your PIN and settings. This cannot be undone, and Karde keeps no copy anywhere.'**
  String get eraseEverythingMessage;

  /// No description provided for @backUpFirst.
  ///
  /// In en, this message translates to:
  /// **'Back up first'**
  String get backUpFirst;

  /// No description provided for @settingsLockExplainer.
  ///
  /// In en, this message translates to:
  /// **'These settings control how Karde locks itself. Your phone will also ask for your fingerprint or screen lock whenever you open an item, whichever of these you choose.'**
  String get settingsLockExplainer;

  /// No description provided for @settingsNoScreenLockWarning.
  ///
  /// In en, this message translates to:
  /// **'This phone has no screen lock, so Karde cannot store or open your items. Add a PIN, pattern, password or fingerprint in your phone\'s settings, then come back.'**
  String get settingsNoScreenLockWarning;

  /// No description provided for @passphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get passphraseTooShort;

  /// No description provided for @passphraseWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passphraseWeak;

  /// No description provided for @passphraseReasonable.
  ///
  /// In en, this message translates to:
  /// **'Reasonable'**
  String get passphraseReasonable;

  /// No description provided for @passphraseStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passphraseStrong;

  /// No description provided for @passphraseWeakHint.
  ///
  /// In en, this message translates to:
  /// **'{label} — longer is far better than more complicated'**
  String passphraseWeakHint(String label);

  /// No description provided for @passphraseChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase'**
  String get passphraseChooseTitle;

  /// No description provided for @passphraseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase'**
  String get passphraseEnterTitle;

  /// No description provided for @passphraseCreateExplainer.
  ///
  /// In en, this message translates to:
  /// **'This passphrase encrypts your backup file. Karde cannot reset it or work it out — if it is forgotten and written down nowhere, the backup is gone.'**
  String get passphraseCreateExplainer;

  /// No description provided for @passphraseUnlockExplainer.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase you chose when this backup was created.'**
  String get passphraseUnlockExplainer;

  /// No description provided for @passphraseFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseFieldLabel;

  /// No description provided for @passphraseShow.
  ///
  /// In en, this message translates to:
  /// **'Show passphrase'**
  String get passphraseShow;

  /// No description provided for @passphraseHide.
  ///
  /// In en, this message translates to:
  /// **'Hide passphrase'**
  String get passphraseHide;

  /// No description provided for @passphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a passphrase.'**
  String get passphraseRequired;

  /// No description provided for @passphraseMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String passphraseMinimumLength(int count);

  /// No description provided for @passphraseConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get passphraseConfirmLabel;

  /// No description provided for @passphraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two entries do not match.'**
  String get passphraseMismatch;

  /// No description provided for @passphraseAdvice.
  ///
  /// In en, this message translates to:
  /// **'A few unrelated words are easier to remember and harder to guess than one short complicated word.'**
  String get passphraseAdvice;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @securityQuestionFirstPet.
  ///
  /// In en, this message translates to:
  /// **'What was the name of your first pet?'**
  String get securityQuestionFirstPet;

  /// No description provided for @securityQuestionMothersMaidenName.
  ///
  /// In en, this message translates to:
  /// **'What is your mother\'s maiden name?'**
  String get securityQuestionMothersMaidenName;

  /// No description provided for @securityQuestionElementarySchool.
  ///
  /// In en, this message translates to:
  /// **'What was the name of your elementary school?'**
  String get securityQuestionElementarySchool;

  /// No description provided for @securityQuestionCityOfBirth.
  ///
  /// In en, this message translates to:
  /// **'In what city were you born?'**
  String get securityQuestionCityOfBirth;

  /// No description provided for @securityQuestionFirstCar.
  ///
  /// In en, this message translates to:
  /// **'What was the make of your first car?'**
  String get securityQuestionFirstCar;

  /// No description provided for @securityQuestionFavouriteBook.
  ///
  /// In en, this message translates to:
  /// **'What is your favorite book?'**
  String get securityQuestionFavouriteBook;

  /// No description provided for @chooseBothQuestions.
  ///
  /// In en, this message translates to:
  /// **'Choose both questions.'**
  String get chooseBothQuestions;

  /// No description provided for @chooseTwoDifferentQuestions.
  ///
  /// In en, this message translates to:
  /// **'Choose two different questions.'**
  String get chooseTwoDifferentQuestions;

  /// No description provided for @securityQuestionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Security questions updated.'**
  String get securityQuestionsUpdated;

  /// No description provided for @securityQuestionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Security questions saved.'**
  String get securityQuestionsSaved;

  /// No description provided for @changeSecurityQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Change your security questions'**
  String get changeSecurityQuestionsTitle;

  /// No description provided for @changeSecurityQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These let you back in if you forget your Karde PIN.'**
  String get changeSecurityQuestionsSubtitle;

  /// No description provided for @saveQuestions.
  ///
  /// In en, this message translates to:
  /// **'Save questions'**
  String get saveQuestions;

  /// No description provided for @chooseAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Choose a question'**
  String get chooseAQuestion;

  /// No description provided for @securityAnswersHashNoteChanging.
  ///
  /// In en, this message translates to:
  /// **'Your current answers cannot be shown. They are scrambled when saved, so Karde can only replace them, never read them. Saving replaces both.'**
  String get securityAnswersHashNoteChanging;

  /// No description provided for @securityAnswersHashNoteNew.
  ///
  /// In en, this message translates to:
  /// **'Your answers are scrambled before they are saved, so nobody can read them back — not even Karde. Capitalisation and spacing do not matter.'**
  String get securityAnswersHashNoteNew;

  /// No description provided for @alreadyUsedAbove.
  ///
  /// In en, this message translates to:
  /// **'Already used above'**
  String get alreadyUsedAbove;

  /// No description provided for @notesDecryptError.
  ///
  /// In en, this message translates to:
  /// **'Error decrypting notes.'**
  String get notesDecryptError;

  /// No description provided for @deleteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this card?'**
  String get deleteCardTitle;

  /// No description provided for @deleteCardMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. The card data will be permanently deleted from the encrypted vault.'**
  String get deleteCardMessage;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @privateNotesAndPhoto.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE NOTES & PHOTO'**
  String get privateNotesAndPhoto;

  /// No description provided for @cardMetadata.
  ///
  /// In en, this message translates to:
  /// **'CARD METADATA'**
  String get cardMetadata;

  /// No description provided for @notesAndPhoto.
  ///
  /// In en, this message translates to:
  /// **'Notes and photo'**
  String get notesAndPhoto;

  /// No description provided for @privateNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Private notes'**
  String get privateNotesTitle;

  /// No description provided for @tapToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get tapToUnlock;

  /// No description provided for @photoCouldNotBeDisplayed.
  ///
  /// In en, this message translates to:
  /// **'This photo could not be displayed.'**
  String get photoCouldNotBeDisplayed;

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added On'**
  String get addedOn;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @idOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this document. Try again.'**
  String get idOpenFailed;

  /// No description provided for @deleteIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this ID?'**
  String get deleteIdTitle;

  /// No description provided for @deleteIdMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. The ID data will be permanently deleted from the encrypted vault.'**
  String get deleteIdMessage;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL DETAILS'**
  String get additionalDetails;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get detailsSection;

  /// No description provided for @deleteId.
  ///
  /// In en, this message translates to:
  /// **'Delete ID'**
  String get deleteId;

  /// No description provided for @documentDetails.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get documentDetails;

  /// No description provided for @noExtraDetails.
  ///
  /// In en, this message translates to:
  /// **'This document has no extra details.'**
  String get noExtraDetails;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your items.'**
  String get dashboardLoadError;

  /// No description provided for @biometricChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone unlock changed'**
  String get biometricChangeTitle;

  /// No description provided for @biometricChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'A fingerprint or face was added or removed on this phone. If that was you, nothing is wrong.'**
  String get biometricChangeMessage;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @securityWarning.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get securityWarning;

  /// No description provided for @securityRisk.
  ///
  /// In en, this message translates to:
  /// **'Security Risk'**
  String get securityRisk;

  /// No description provided for @noBiometricsEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled. {details}'**
  String noBiometricsEnrolled(String details);

  /// No description provided for @missingSecureLockScreen.
  ///
  /// In en, this message translates to:
  /// **'Device is missing secure lock screen. {details}'**
  String missingSecureLockScreen(String details);

  /// No description provided for @authReasonRevealCard.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to reveal sensitive card information.'**
  String get authReasonRevealCard;

  /// No description provided for @authReasonOpenKarde.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to open Karde.'**
  String get authReasonOpenKarde;

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequiredTitle;

  /// No description provided for @useKardePin.
  ///
  /// In en, this message translates to:
  /// **'Use Karde PIN'**
  String get useKardePin;

  /// No description provided for @biometricsNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not supported or not enrolled on this device.'**
  String get biometricsNotEnrolled;

  /// No description provided for @biometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Your phone has paused fingerprint unlock after too many tries. Wait a moment, or use your screen lock.'**
  String get biometricLockedOut;

  /// No description provided for @biometricUnavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Your phone could not check your fingerprint just now.'**
  String get biometricUnavailableNow;

  /// No description provided for @biometricAuthFailedUsePin.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed. Please use PIN.'**
  String get biometricAuthFailedUsePin;

  /// No description provided for @resetPinBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Scan your fingerprint (or face) to reset your PIN'**
  String get resetPinBiometricReason;

  /// No description provided for @verificationNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Verification was not completed. Try again, or use another recovery option below.'**
  String get verificationNotCompleted;

  /// No description provided for @biometricVerificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric verification is unavailable right now. Use another recovery option below.'**
  String get biometricVerificationUnavailable;

  /// No description provided for @privacyPolicyHeading.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy for Karde'**
  String get privacyPolicyHeading;

  /// No description provided for @privacyPolicyEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date: September 2026'**
  String get privacyPolicyEffectiveDate;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Local Storage Only'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'All your data, including card numbers, CVVs, and notes, is encrypted and stored locally on your device. We do not transmit, back up, or store your data on any external servers or cloud services. You have complete control over your data.'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Encryption'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'Your data is secured using AES-256-GCM encryption. The encryption keys are securely generated and stored in your device\'s hardware-backed Keystore.'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Authentication'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'To access your sensitive data, Karde requires local authentication via your device\'s Biometrics (Face ID/Fingerprint) or your custom Karde PIN. We do not have access to your PIN or biometric data.'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Deletion'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In en, this message translates to:
  /// **'You can permanently delete all your data at any time using the \"Erase vault\" feature in Settings, or by uninstalling the application. Since no data is stored in the cloud, uninstallation results in permanent deletion of your vault.'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Permissions'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In en, this message translates to:
  /// **'The app only requests permissions necessary for its core functionality, such as Biometric authentication. It does not request internet access, ensuring your data cannot be transmitted.'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Changes to this Policy'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this policy occasionally. Any changes will be reflected in the app. By continuing to use the app, you agree to the updated policy.'**
  String get privacySection6Body;

  /// No description provided for @recoveryNoPinNote.
  ///
  /// In en, this message translates to:
  /// **'You chose to unlock Karde with your phone\'s own lock, so there is no Karde PIN to recover yet. Setting this up now means a way back in already exists if you ever add one.\n\nSeparately, and worth knowing: your items are encrypted with a key held in your phone\'s security chip. Changing your PIN, pattern, password or fingerprints is safe — your items stay readable. But if you turn your screen lock off completely, that key is destroyed and nothing here can bring your items back. An encrypted backup, from Settings, is the only thing that survives it.'**
  String get recoveryNoPinNote;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noScreenLockWarning.
  ///
  /// In en, this message translates to:
  /// **'This phone has no screen lock.\n\nKarde keeps your encryption key in the phone\'s security chip, and that chip will not hold a key unless the phone itself is locked. Until you set a PIN, pattern, password or fingerprint in your phone\'s settings, Karde cannot save or open any items.\n\nYou can finish setting up now, then add a screen lock and come back.'**
  String get noScreenLockWarning;

  /// No description provided for @backToLanguage.
  ///
  /// In en, this message translates to:
  /// **'Back to language'**
  String get backToLanguage;

  /// No description provided for @imageNoSource.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can provide an image.'**
  String get imageNoSource;

  /// No description provided for @imageUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That image could not be read. Try another one.'**
  String get imageUnreadable;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Adding photos is not available on this device.'**
  String get imageNotAvailable;

  /// No description provided for @photoCouldNotBeAdded.
  ///
  /// In en, this message translates to:
  /// **'That photo could not be added. Try another.'**
  String get photoCouldNotBeAdded;

  /// No description provided for @tapToViewFullSize.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full size'**
  String get tapToViewFullSize;

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replacePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @addAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addAPhoto;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoClosesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Closes automatically. Screenshots are blocked.'**
  String get photoClosesAutomatically;

  /// No description provided for @unlockNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock on your device to unlock your vault.'**
  String get unlockNeedsScreenLock;

  /// No description provided for @itemNoLongerDecryptable.
  ///
  /// In en, this message translates to:
  /// **'Your device security settings changed, so this item can no longer be decrypted.'**
  String get itemNoLongerDecryptable;

  /// No description provided for @couldNotUnlockCard.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock this card. Please try again.'**
  String get couldNotUnlockCard;

  /// No description provided for @couldNotUnlockDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock this document. Please try again.'**
  String get couldNotUnlockDocument;

  /// No description provided for @cardNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Card number copied. Clipboard clears in 60s.'**
  String get cardNumberCopied;

  /// No description provided for @pinLockedTryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {seconds}s.'**
  String pinLockedTryAgainIn(int seconds);

  /// No description provided for @pinLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Locked out for 30 seconds.'**
  String get pinLockedOut;

  /// No description provided for @pinInvalidAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Invalid PIN. 1 attempt left.} other{Invalid PIN. {count} attempts left.}}'**
  String pinInvalidAttemptsLeft(int count);

  /// No description provided for @pinDigitSemantic.
  ///
  /// In en, this message translates to:
  /// **'PIN digit {digit}'**
  String pinDigitSemantic(String digit);

  /// No description provided for @deleteLastDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get deleteLastDigit;

  /// No description provided for @vaultUpdatedWithNewPin.
  ///
  /// In en, this message translates to:
  /// **'Your secure vault has been updated with the new PIN.'**
  String get vaultUpdatedWithNewPin;

  /// No description provided for @vaultReadyWithNewPin.
  ///
  /// In en, this message translates to:
  /// **'You can now use this PIN to open Karde.'**
  String get vaultReadyWithNewPin;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @cardholderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'NAME SURNAME'**
  String get cardholderPlaceholder;

  /// No description provided for @privacySection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Keep Your Screen Lock'**
  String get privacySection7Title;

  /// No description provided for @privacySection7Body.
  ///
  /// In en, this message translates to:
  /// **'Karde\'s encryption key lives in your phone\'s security chip, and it exists only while your phone has a screen lock. Changing your PIN, pattern, password or fingerprints is safe — your saved items stay readable. But if you turn your screen lock off completely, that key is destroyed and your items can no longer be opened by anyone, including us. An encrypted backup is the only thing that survives it, so make one before removing your screen lock.'**
  String get privacySection7Body;

  /// No description provided for @privacySection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Contact'**
  String get privacySection8Title;

  /// No description provided for @privacySection8Body.
  ///
  /// In en, this message translates to:
  /// **'Questions about this policy, or anything unclear: support@getgubae.com.'**
  String get privacySection8Body;

  /// No description provided for @biometricCouldNotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm it was you. Try again.'**
  String get biometricCouldNotConfirm;

  /// No description provided for @noBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get noBackupTitle;

  /// No description provided for @noBackupShort.
  ///
  /// In en, this message translates to:
  /// **'No backup yet — everything is only on this phone.'**
  String get noBackupShort;

  /// No description provided for @noBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you have saved is only on this phone. A backup lets you get it all back on a new phone.'**
  String get noBackupBody;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @passphraseSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup passphrase'**
  String get passphraseSectionTitle;

  /// No description provided for @passphraseSectionBody.
  ///
  /// In en, this message translates to:
  /// **'This is the only thing that opens your backup on a new phone. Karde cannot reset it for you.'**
  String get passphraseSectionBody;

  /// No description provided for @passphraseShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Show my passphrase'**
  String get passphraseShowTitle;

  /// No description provided for @passphraseShowBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your fingerprint or screen lock to see it.'**
  String get passphraseShowBody;

  /// No description provided for @passphraseSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep my passphrase on this phone'**
  String get passphraseSaveTitle;

  /// No description provided for @passphraseSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Then you can look it up here whenever you are unsure.'**
  String get passphraseSaveBody;

  /// No description provided for @passphraseChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change my passphrase'**
  String get passphraseChangeTitle;

  /// No description provided for @passphraseChangeBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to type the current one first.'**
  String get passphraseChangeBody;

  /// No description provided for @passphraseChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Your backup moves to the new passphrase straight away. The dated copies from earlier days stay locked with the old one, so keep the old passphrase until you no longer need them.'**
  String get passphraseChangeWarning;

  /// No description provided for @passphraseChanged.
  ///
  /// In en, this message translates to:
  /// **'Your backup passphrase has been changed.'**
  String get passphraseChanged;

  /// No description provided for @passphraseUnchanged.
  ///
  /// In en, this message translates to:
  /// **'That is the passphrase you already have.'**
  String get passphraseUnchanged;

  /// No description provided for @passphraseNotOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Karde no longer has a copy of your passphrase on this phone.'**
  String get passphraseNotOnThisPhone;

  /// No description provided for @passphraseCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Karde could not keep a copy on this phone. Your backup itself is fine.'**
  String get passphraseCouldNotSave;

  /// No description provided for @passphraseSavedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved. You can look it up on this screen whenever you need it.'**
  String get passphraseSavedOnPhone;

  /// No description provided for @passphraseRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup passphrase'**
  String get passphraseRevealTitle;

  /// No description provided for @passphraseRevealWarning.
  ///
  /// In en, this message translates to:
  /// **'This copy only exists on this phone, so it goes when the phone does — which is exactly when you would need it. Write it down somewhere else, or keep it in a password manager.'**
  String get passphraseRevealWarning;

  /// No description provided for @passphraseCopied.
  ///
  /// In en, this message translates to:
  /// **'Passphrase copied. Clipboard clears in 60s.'**
  String get passphraseCopied;

  /// No description provided for @passphraseReuseTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your backup passphrase?'**
  String get passphraseReuseTitle;

  /// No description provided for @passphraseReuseMessage.
  ///
  /// In en, this message translates to:
  /// **'Karde can lock this file with the same passphrase your automatic backup already uses, so there is only one for you to remember.'**
  String get passphraseReuseMessage;

  /// No description provided for @passphraseReuseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get passphraseReuseConfirm;

  /// No description provided for @passphraseReuseAlternative.
  ///
  /// In en, this message translates to:
  /// **'Type a different one'**
  String get passphraseReuseAlternative;

  /// No description provided for @backupIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup is missing things'**
  String get backupIncompleteTitle;

  /// No description provided for @backupIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One item was saved before backup was switched on, so it was never copied.} other{{count} items were saved before backup was switched on, so they were never copied.}}'**
  String backupIncompleteBody(int count);

  /// No description provided for @backupCopyExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy what you already had'**
  String get backupCopyExistingTitle;

  /// No description provided for @backupCopyExistingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One item is in your vault but not in your backup.} other{{count} items are in your vault but not in your backup.}}'**
  String backupCopyExistingSubtitle(int count);

  /// No description provided for @backupCopyExistingAction.
  ///
  /// In en, this message translates to:
  /// **'Copy them now'**
  String get backupCopyExistingAction;

  /// No description provided for @backupCopyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 item} other{Copy {count} items}}'**
  String backupCopyConfirmTitle(int count);

  /// No description provided for @backupCopyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask you to confirm your identity once per item. Anything you save from now on is copied without asking.'**
  String get backupCopyConfirmMessage;

  /// No description provided for @backupCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying to your backup…'**
  String get backupCopying;

  /// No description provided for @backupCopyDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added to your backup.} other{{count} items added to your backup.}}'**
  String backupCopyDone(int count);

  /// No description provided for @expiryCardSoon.
  ///
  /// In en, this message translates to:
  /// **'This card expires in {when}.'**
  String expiryCardSoon(String when);

  /// No description provided for @expiryCardPast.
  ///
  /// In en, this message translates to:
  /// **'This card expired in {when}.'**
  String expiryCardPast(String when);

  /// No description provided for @expiryDocumentSoon.
  ///
  /// In en, this message translates to:
  /// **'This document expires on {when}.'**
  String expiryDocumentSoon(String when);

  /// No description provided for @expiryDocumentPast.
  ///
  /// In en, this message translates to:
  /// **'This document expired on {when}.'**
  String expiryDocumentPast(String when);

  /// No description provided for @settingsExpiryReminders.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get settingsExpiryReminders;

  /// No description provided for @settingsExpiryRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell me before a card or document runs out'**
  String get settingsExpiryRemindersDesc;

  /// No description provided for @settingsExpiryRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'To warn you, Karde keeps the expiry date where it can read it, next to the nickname and last four digits already stored that way. The card number, security code, document number and photo stay encrypted. Turning this off erases every date Karde kept.'**
  String get settingsExpiryRemindersNote;

  /// No description provided for @settingsExpiryOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off expiry reminders?'**
  String get settingsExpiryOffTitle;

  /// No description provided for @settingsExpiryOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Karde will forget the expiry dates it stored and stop warning you. Nothing else about your cards or documents changes.'**
  String get settingsExpiryOffMessage;

  /// No description provided for @settingsExpiryOffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get settingsExpiryOffConfirm;

  /// No description provided for @settingsExpiryReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Check what you already saved'**
  String get settingsExpiryReadTitle;

  /// No description provided for @settingsExpiryReadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One item was saved before reminders existed, so Karde cannot see when it expires.} other{{count} items were saved before reminders existed, so Karde cannot see when they expire.}}'**
  String settingsExpiryReadSubtitle(int count);

  /// No description provided for @settingsExpiryReadAction.
  ///
  /// In en, this message translates to:
  /// **'Read them now'**
  String get settingsExpiryReadAction;

  /// No description provided for @settingsExpiryReadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 item} other{Read {count} items}}'**
  String settingsExpiryReadConfirmTitle(int count);

  /// No description provided for @settingsExpiryReadConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask you to confirm your identity once per item. Karde takes the expiry date and nothing else.'**
  String get settingsExpiryReadConfirmMessage;

  /// No description provided for @settingsExpiryReading.
  ///
  /// In en, this message translates to:
  /// **'Reading expiry dates…'**
  String get settingsExpiryReading;

  /// No description provided for @settingsExpiryReadDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expiry date saved.} other{{count} expiry dates saved.}}'**
  String settingsExpiryReadDone(int count);
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
