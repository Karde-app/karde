// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Karde';

  @override
  String get welcomeTitle => 'Welcome to Karde';

  @override
  String get welcomeSubtitle => 'Your secure, offline digital wallet';

  @override
  String get offlineBadge => 'Offline & Encrypted';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get seeAll => 'See all';

  @override
  String get addACard => 'Add a card';

  @override
  String get openVault => 'Open Vault';

  @override
  String get vaultHealthExcellent => 'Vault health: excellent';

  @override
  String vaultHealthItems(int count) {
    return '$count items encrypted with AES-256-GCM';
  }

  @override
  String get homeTab => 'Home';

  @override
  String get vaultTab => 'Vault';

  @override
  String get settingsTab => 'Settings';

  @override
  String get myVault => 'My Vault';

  @override
  String get allFilter => 'All';

  @override
  String get cardsFilter => 'Cards';

  @override
  String get idsFilter => 'IDs';

  @override
  String get addNewCard => 'Add New Card';

  @override
  String get identification => 'IDENTIFICATION';

  @override
  String get issuerLabel => 'ISSUER';

  @override
  String get issuerHint => 'e.g. Bank Name or Provider';

  @override
  String get cardNetworkLabel => 'Card Network';

  @override
  String get cardholderNameLabel => 'CARDHOLDER NAME';

  @override
  String get cardholderNameHint => 'Name on card';

  @override
  String get cardDetails => 'CARD DETAILS';

  @override
  String get cardNumberLabel => 'CARD NUMBER';

  @override
  String get cardNumberHint => '0000 0000 0000 0000';

  @override
  String get expiryLabel => 'EXPIRY';

  @override
  String get expiryHint => 'MM/YY';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get extraInfo => 'EXTRA INFO (OPTIONAL)';

  @override
  String get privateNotesLabel => 'PRIVATE NOTES';

  @override
  String get privateNotesHint => 'Bank phone numbers, PIN hints...';

  @override
  String get saveItem => 'Save Item';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidFormat => 'Invalid format';

  @override
  String get cardDetailsTitle => 'Card Details';

  @override
  String get editDetails => 'Edit details';

  @override
  String get deleteCard => 'Delete card';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get setupLockTitle => 'Secure Your Wallet';

  @override
  String get setupLockSubtitle => 'How would you like to protect your secrets?';

  @override
  String get phoneLock => 'Phone Lock';

  @override
  String get phoneLockDesc =>
      'Use your device\'s Face ID, Touch ID, or passcode.';

  @override
  String get kardePin => 'Karde PIN';

  @override
  String get kardePinDesc => 'Create a dedicated PIN just for this app.';

  @override
  String get bothLocks => 'Both';

  @override
  String get bothLocksDesc =>
      'Phone lock to open app, Karde PIN to view secrets.';

  @override
  String get continueBtn => 'Continue';

  @override
  String get createPin => 'Create PIN';

  @override
  String get enterPin => 'Enter your new PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get reEnterPin => 'Please re-enter your PIN';

  @override
  String get pinMismatch => 'PINs do not match. Try again.';

  @override
  String get enterKardePin => 'Enter Karde PIN';

  @override
  String get unlockToReveal => 'Unlock to reveal secrets';

  @override
  String get recoverySetupTitle => 'PIN Recovery';

  @override
  String get recoverySetupSubtitle =>
      'How would you like to recover your PIN if you forget it?';

  @override
  String get biometricRecovery => 'Phone Biometrics';

  @override
  String get biometricRecoveryDesc =>
      'Use your device\'s fingerprint or Face ID to reset your PIN.';

  @override
  String get securityQuestions => 'Security Questions';

  @override
  String get securityQuestionsDesc =>
      'Answer 2 personal questions to reset your PIN.';

  @override
  String get noRecovery => 'No Recovery';

  @override
  String get noRecoveryDesc =>
      'Maximum security. Forgetting your PIN means permanent data loss.';

  @override
  String get setupQuestionsTitle => 'Set Security Questions';

  @override
  String get setupQuestionsSubtitle => 'Choose 2 questions and answers';

  @override
  String get question1 => 'Question 1';

  @override
  String get question2 => 'Question 2';

  @override
  String get answer => 'Answer';

  @override
  String get answerRequired => 'Answer is required';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get resetPinTitle => 'Reset PIN';

  @override
  String get resetPinSubtitle => 'Choose a recovery method';

  @override
  String get wipeDataBtn => 'Wipe App Data (Danger)';

  @override
  String get wipeDataWarning =>
      'This will permanently delete all your saved cards and reset the app. Are you sure?';

  @override
  String get cancel => 'Cancel';

  @override
  String get wipe => 'Wipe';

  @override
  String get verifyQuestionsTitle => 'Answer Security Questions';

  @override
  String get verifyQuestionsSubtitle =>
      'Answer both questions to reset your PIN';

  @override
  String get verifyBtn => 'Verify';

  @override
  String get wrongAnswers => 'One or both answers are incorrect.';

  @override
  String get resetPinSuccess =>
      'Verification successful. You can now set a new PIN.';

  @override
  String get maxAttemptsReached =>
      'Maximum attempts reached. You must reset your PIN.';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get theme => 'Theme';

  @override
  String get themeDesc => 'System, Light or Dark';

  @override
  String get appDisplayLanguage => 'App display language';

  @override
  String get privacy => 'PRIVACY';

  @override
  String get autoHide => 'Auto-hide sensitive details';

  @override
  String get autoHideDesc => 'Mask card number & CVV automatically';

  @override
  String get security => 'SECURITY';

  @override
  String get appPinLock => 'App PIN lock';

  @override
  String get appPinLockDesc => 'Require a PIN to open Karde';

  @override
  String get biometricUnlockTitle => 'Biometric unlock';

  @override
  String get biometricUnlockDesc => 'Use fingerprint to open Karde';

  @override
  String get changePin => 'Change Karde PIN';

  @override
  String get changePinDesc => 'Update your master PIN';

  @override
  String get about => 'ABOUT';

  @override
  String get aboutKarde => 'About Karde';

  @override
  String get aboutKardeDesc => 'Version, credits & licenses';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'How your data stays on-device';

  @override
  String get mustKeepOneLock =>
      'You must keep at least one lock method enabled.';

  @override
  String get biometricsNotSupported =>
      'Biometrics are not supported on this device.';

  @override
  String get biometricsError => 'Error checking biometric support.';

  @override
  String get invalidCardLength => 'Invalid card length';

  @override
  String get invalidCardNumber => 'Invalid card number';

  @override
  String get invalidExpiryFormat => 'Format must be MM/YY';

  @override
  String get invalidMonth => 'Invalid month';

  @override
  String get cardExpired => 'Card has expired';

  @override
  String get invalidCvvLength => 'CVV must be 3 or 4 digits';

  @override
  String get numbersOnly => 'Numbers only';

  @override
  String get lettersAndSymbolsNotAllowed =>
      'Letters and symbols are not allowed';

  @override
  String get kardeIsLocked => 'Karde is Locked';

  @override
  String get authenticateToAccess => 'Authenticate to access your vault.';

  @override
  String get authenticating => 'Authenticating...';

  @override
  String get unlockKarde => 'Unlock Karde';

  @override
  String get exitApp => 'Exit App';

  @override
  String get enterCurrentPin => 'Enter your current Karde PIN';

  @override
  String get createKardePin => 'Create Karde PIN';

  @override
  String get pinChangedSuccess => 'PIN Successfully Changed';

  @override
  String get done => 'Done';

  @override
  String get addAnId => 'Add an ID';

  @override
  String get idDetails => 'ID Details';

  @override
  String get documentType => 'Document Type';

  @override
  String get documentNumber => 'Document Number';

  @override
  String get fullName => 'Full Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get sexGender => 'Sex / Gender';

  @override
  String get issuingAuthority => 'Issuing Country / Authority';

  @override
  String get issueDate => 'Issue Date';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get placeOfBirth => 'Place of Birth';

  @override
  String get personalId => 'Personal ID / SSN';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get tabAll => 'All';

  @override
  String get tabCards => 'Cards';

  @override
  String get tabIds => 'IDs';
}
