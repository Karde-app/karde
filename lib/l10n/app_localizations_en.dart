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
  String get biometricRecovery => 'Phone Lock';

  @override
  String get biometricRecoveryDesc =>
      'Use however you unlock your phone — fingerprint, face, pattern, PIN or password — to reset your Karde PIN.';

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

  @override
  String get idCardNotAvailable => 'N/A';

  @override
  String get idCardPassportTitle => 'INTERNATIONAL PASSPORT';

  @override
  String get idCardType => 'TYPE';

  @override
  String get idCardCodeOfIssuingState => 'CODE OF ISSUING STATE';

  @override
  String get idCardPassportNo => 'PASSPORT NO.';

  @override
  String get idCardSurname => 'SURNAME';

  @override
  String get idCardGivenNames => 'GIVEN NAMES';

  @override
  String get idCardNationalityUpper => 'NATIONALITY';

  @override
  String get idCardDobUpper => 'DATE OF BIRTH';

  @override
  String get idCardSexUpper => 'SEX';

  @override
  String get idCardPlaceOfBirthUpper => 'PLACE OF BIRTH';

  @override
  String get idCardAuthorityUpper => 'AUTHORITY';

  @override
  String get idCardDateOfIssueUpper => 'DATE OF ISSUE';

  @override
  String get idCardDateOfExpiryUpper => 'DATE OF EXPIRY';

  @override
  String get idCardHoldersSignature => 'HOLDERS SIGNATURE';

  @override
  String get idCardResidencePermitTitle => 'BIOMETRIC RESIDENCE PERMIT';

  @override
  String get idCardName => 'Name';

  @override
  String get idCardGender => 'Gender';

  @override
  String get idCardNationality => 'Nationality';

  @override
  String get idCardDocumentNo => 'Document No.';

  @override
  String get idCardNationalFallback => 'NATIONAL';

  @override
  String get idCardIdCard => 'ID CARD';

  @override
  String get idCardNationalIdLogo => 'National ID';

  @override
  String get idCardEthiopianDigitalId => 'Ethiopian Digital ID Card';

  @override
  String get idCardEthiopianFullName => 'First, Middle, Surname';

  @override
  String get idCardFullNameUpper => 'FULL NAME';

  @override
  String get idCardDateOfExpiry => 'Date of Expiry';

  @override
  String get idCardCountryOfCitizenship =>
      'Country of Citizenship (Self-declared)';

  @override
  String get idCardIssuingAuthorityUpper => 'ISSUING AUTHORITY';

  @override
  String get idCardIdNo => 'ID NO';

  @override
  String get idCardDrivingLicenceTitle => 'DRIVING LICENCE';

  @override
  String get idCardNameUpper => 'NAME';

  @override
  String get idCardPassportNoShort => 'Passport No';

  @override
  String get idCardDlNo => 'DL No';

  @override
  String get idCardDocNo => 'Doc No';

  @override
  String get idCardDocumentFallback => 'DOCUMENT';

  @override
  String get idCardDocumentHolder => 'DOCUMENT HOLDER';

  @override
  String get idCardDocumentNumberUpper => 'DOCUMENT NUMBER';

  @override
  String get idCardValidFrom => 'VALID FROM';

  @override
  String get idCardExpires => 'EXPIRES';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupCouldNotReadVault =>
      'Could not read your vault. Please try again.';

  @override
  String get backupVaultEmpty =>
      'There is nothing in your vault to back up yet.';

  @override
  String backupConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Back up $count items',
      one: 'Back up 1 item',
    );
    return '$_temp0';
  }

  @override
  String get backupConfirmMessage =>
      'Your phone will ask you to confirm your identity a few times while this runs.\n\nNext you will choose a passphrase and where to save the file.';

  @override
  String get backupPreparing => 'Preparing backup';

  @override
  String get backupUnlockingVault => 'Unlocking your vault';

  @override
  String backupSavedAs(String fileName) {
    return 'Backup saved as $fileName.';
  }

  @override
  String get backupOpening => 'Opening backup';

  @override
  String get backupAllDuplicates =>
      'Everything in that backup is already in your vault.';

  @override
  String get backupNoItems => 'That backup does not contain any items.';

  @override
  String backupSkippedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are already in your vault and will be skipped.',
      one: '1 item is already in your vault and will be skipped.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restore $count items',
      one: 'Restore 1 item',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmMessage(String skipped) {
    return 'Your phone will ask you to confirm your identity a few times while this runs.$skipped\n\nNothing already in your vault is removed or changed.';
  }

  @override
  String get backupRestoreConfirmAction => 'Restore';

  @override
  String get backupRestoring => 'Restoring';

  @override
  String backupRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restored $count items to your vault.',
      one: 'Restored 1 item to your vault.',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreCancelled =>
      'Restore cancelled. Nothing was changed.';

  @override
  String get backupWrongPassphrase =>
      'That passphrase does not open this backup. Check it and try again.';

  @override
  String get backupFileChooseAgain =>
      'That file could not be read. Try choosing it again.';

  @override
  String get backupNeedsScreenLock =>
      'Set a screen lock on your device before backing up or restoring.';

  @override
  String get backupKeyInvalidated =>
      'Your vault key is no longer valid, so existing items cannot be read. Restoring from a backup will still work.';

  @override
  String get backupExplainerPassphrase =>
      'Your backup is locked with a passphrase you choose. Without it the file is unreadable — and Karde cannot recover it for you, so keep it somewhere safe.';

  @override
  String get backupExplainerOffline =>
      'Nothing is uploaded. You pick where the file goes, and it can be restored on this phone or on a new one.';

  @override
  String get backupCreateTitle => 'Create a backup';

  @override
  String get backupCreateSubtitle =>
      'Save a locked copy of everything in your vault, wherever you choose.';

  @override
  String get backupCreateAction => 'Back up now';

  @override
  String get backupRestoreCardTitle => 'Restore a backup';

  @override
  String get backupRestoreCardSubtitle =>
      'Add the items from a backup file to this vault. Existing items are kept, and anything already here is skipped.';

  @override
  String get backupRestoreCardAction => 'Choose a file';

  @override
  String get backupKeepFileSafe =>
      'Keep the backup file somewhere you trust. It holds everything in your vault, protected only by the passphrase you chose.';

  @override
  String backupProgressCount(String label, int completed, int total) {
    return '$label — $completed of $total';
  }

  @override
  String get backupConfirmIdentityHint =>
      'Confirm your identity when your phone asks. Cancelling stops everything safely — nothing is changed.';

  @override
  String get backupProblemDamaged => 'The backup contents are damaged.';

  @override
  String get backupProblemNotKardeBackup =>
      'That file is not a Karde vault backup.';

  @override
  String get backupProblemNewerVersion =>
      'That backup was made by a newer version of Karde. Update the app and try again.';

  @override
  String get backupProblemPhotoDamaged => 'A photo in the backup is damaged.';

  @override
  String backupProblemMissingValue(String key) {
    return 'The backup is missing its \"$key\" value.';
  }

  @override
  String backupProblemUnreadableValue(String key) {
    return 'The backup has an unreadable \"$key\" value.';
  }

  @override
  String get backupProblemRecordUnreadable =>
      'A vault record could not be read.';

  @override
  String get backupProblemFileDamaged =>
      'That backup file could not be read. It may be damaged.';
}
