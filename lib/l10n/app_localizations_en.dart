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
  String get idsFilter => 'IDs • Soon';

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
}
