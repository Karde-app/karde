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
  String get welcomeSubtitle => 'Your secure, offline vault';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items, safely locked',
      one: '1 item, safely locked',
    );
    return '$_temp0';
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
  String get setupLockTitle => 'Secure Your Vault';

  @override
  String get setupLockSubtitle => 'How would you like to open Karde?';

  @override
  String get phoneLock => 'Phone Lock';

  @override
  String get phoneLockDesc => 'Your device\'s Face ID, Touch ID or passcode.';

  @override
  String get lockChoiceChangeableLater =>
      'You can change this later in Settings.';

  @override
  String get kardePin => 'Karde PIN';

  @override
  String get kardePinDesc => 'Create a dedicated PIN just for this app.';

  @override
  String get bothLocks => 'Both';

  @override
  String get bothLocksDesc =>
      'Your phone\'s lock to open Karde, and a Karde PIN for sensitive actions.';

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
  String get recoverySetupTitle => 'If you forget your Karde PIN';

  @override
  String get recoverySetupSubtitle =>
      'Choose how you would reset it and get back into Karde.';

  @override
  String get biometricRecovery => 'Phone Lock';

  @override
  String get biometricRecoveryDesc =>
      'Your device\'s Face ID, Touch ID or passcode.';

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
  String get appPinLock => 'Karde PIN';

  @override
  String get appPinLockDesc =>
      'Ask for it when opening Karde and changing these settings';

  @override
  String get biometricUnlockTitle => 'Phone lock';

  @override
  String get biometricUnlockDesc =>
      'Open Karde with your fingerprint, face or screen lock';

  @override
  String get keepPinTitle => 'Keep your Karde PIN?';

  @override
  String get keepPinMessage =>
      'Karde will stop asking for it either way. Keep it, and switching this back on later uses the same PIN. Delete it, and you choose a new one next time.';

  @override
  String get keepPinKeep => 'Keep it';

  @override
  String get keepPinDelete => 'Delete it';

  @override
  String get pinDeleted => 'Your Karde PIN has been deleted.';

  @override
  String get changePin => 'Change Karde PIN';

  @override
  String get changePinDesc => 'Choose a new PIN for opening Karde';

  @override
  String get createKardePinDesc => 'Set a PIN of your own for opening Karde';

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
  String get numbersNotAllowed => 'Numbers are not allowed';

  @override
  String get symbolsNotAllowed => 'Symbols are not allowed';

  @override
  String get kardeIsLocked => 'Karde is Locked';

  @override
  String get noScreenLockTitle => 'Your phone has no screen lock';

  @override
  String get noScreenLockBody =>
      'Without a screen lock, Karde cannot open or save anything. Set a PIN, pattern, password or fingerprint in your phone\'s settings, then come back.';

  @override
  String get openPhoneSettings => 'Open phone settings';

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
  String get pinCreatedSuccess => 'Karde PIN Created';

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
  String get backupSetupTitle => 'Keeping a copy';

  @override
  String get backupSetupIntro =>
      'Karde saves a copy of everything you keep here, so you can get it all back if this phone is lost, broken or replaced. The copy goes where you choose. Nothing is ever sent to Karde or to anyone else.';

  @override
  String get backupSetupPassphraseTitle => 'Choose a passphrase';

  @override
  String get backupSetupPassphraseBody =>
      'You will need it to get your things back on a new phone. Karde cannot reset it, so write it down and keep it somewhere safe.';

  @override
  String get backupSetupPassphraseDone => 'Passphrase chosen';

  @override
  String get passphraseTooWeakForBackup =>
      'Please choose a longer passphrase, or add some variety.';

  @override
  String get passphraseNeedsMixForBackup =>
      'Please use more than just numbers — add some letters, or a few words.';

  @override
  String get backupSetupFolderTitle => 'Choose where it goes';

  @override
  String get backupSetupFolderBody =>
      'Pick a folder on your phone. If you pick one that syncs to cloud storage, your copy survives losing the phone as well.';

  @override
  String get backupSetupFolderAction => 'Choose a folder';

  @override
  String get backupSetupFinish => 'Finish';

  @override
  String get backupSetupLater => 'Set this up later';

  @override
  String get backupSetupLaterNote =>
      'Karde could not open a folder picker on this phone. You can carry on and set your backup up from Settings, but nothing you save will be copied anywhere until you do.';

  @override
  String get backupSetupWorking => 'Setting up your backup…';

  @override
  String get backupSetupDoneTitle => 'Your backup is on';

  @override
  String backupSetupDoneBody(String folder) {
    return 'Karde saves a copy every time you add, change or remove something. It goes to $folder.';
  }

  @override
  String get backupSetupFolderFailed =>
      'Karde could not save to that folder. Please choose another one.';

  @override
  String get backupSelfTestFailed =>
      'This phone could not read back the copy it had just saved, so Karde has not switched backup on. Please try again.';

  @override
  String get backupUpdated => 'Backup updated.';

  @override
  String get backupFailedTitle => 'Your backup is not being saved';

  @override
  String get alertsTitle => 'Needs your attention';

  @override
  String get alertsTitleCalm => 'All good';

  @override
  String get alertsNone => 'Nothing needs your attention.';

  @override
  String get alertsNoneBody =>
      'Karde will tell you here if something needs looking at.';

  @override
  String get alertsFix => 'Fix this';

  @override
  String get alertsSetUp => 'Set up';

  @override
  String get alertsGotIt => 'Got it';

  @override
  String get alertsAllow => 'Allow';

  @override
  String get backupNotSavingShort =>
      'New changes are not being copied to your backup folder.';

  @override
  String backupFailedBody(String folder) {
    return 'Karde could not save to $folder. The folder may have been moved, renamed or deleted. Until this is fixed, new changes are not being copied anywhere.';
  }

  @override
  String get backupFailedAction => 'Choose a folder';

  @override
  String settingsAutoBackupNote(String folder) {
    return 'Karde saves a copy every time you add, change or remove something. It goes to $folder. You can also save one yourself at any time.';
  }

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
      'The items already on this phone can no longer be opened. Restoring from a backup will still work.';

  @override
  String get backupExplainerPassphrase =>
      'Your backup is locked with a passphrase you choose. Karde cannot recover it, so keep it somewhere safe.';

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
      'Keep the backup file somewhere you trust. Anyone with the file and the passphrase can open it.';

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

  @override
  String get otherOption => 'Other';

  @override
  String get goBack => 'Go back';

  @override
  String get saving => 'Saving...';

  @override
  String get loadingDetails => 'Loading Details';

  @override
  String get setScreenLockFirst => 'Set a screen lock first';

  @override
  String get screenLockExplainer =>
      'Karde cannot save or open anything until this phone has a screen lock.\n\nAdd a PIN, pattern, password or fingerprint in your phone\'s settings, then come back.';

  @override
  String get vaultKeyChangedItemsLost =>
      'Your phone\'s security settings changed, and the items saved here can no longer be opened. They cannot be recovered.';

  @override
  String get addCardDecryptFailed => 'Failed to decrypt existing card data.';

  @override
  String get addCardNeedsScreenLock =>
      'Set a screen lock (PIN, pattern, or biometrics) on your device to save cards securely.';

  @override
  String get addCardSaveFailed =>
      'Something went wrong saving this card. Please try again.';

  @override
  String get selectCardNetwork => 'Select Card Network';

  @override
  String get editCard => 'Edit Card';

  @override
  String get issuerFieldLabel => 'Issuer';

  @override
  String get issuerTooltip =>
      'The name of the bank or institution that issued this card.\n\nExample: Chase Bank';

  @override
  String get customNetworkFieldLabel => 'Custom Network';

  @override
  String get customNetworkHint => 'e.g. UnionPay, JCB';

  @override
  String get secureDetails => 'SECURE DETAILS';

  @override
  String get cardNumberFieldLabel => 'Card Number';

  @override
  String get cardholderNameFieldLabel => 'Cardholder Name';

  @override
  String get privateNotesFieldLabel => 'Private Notes';

  @override
  String get privateNotesTooltip =>
      'Any additional details, addresses, or context.\n\nExample: Bank Phone: 1-800-123-4567';

  @override
  String get cardExpiredStillSave =>
      'This card has expired. You can still save it.';

  @override
  String get cardPhotoLabel => 'CARD PHOTO';

  @override
  String get cardPhotoHint =>
      'Optional. Kept locked with the rest of the card.';

  @override
  String get cardPhotoViewerTitle => 'Card photo';

  @override
  String requiredFieldMarker(String label) {
    return '$label *';
  }

  @override
  String get idTypePassport => 'Passport';

  @override
  String get idTypeDriversLicense => 'Driver\'s License';

  @override
  String get idTypeNationalId => 'National ID';

  @override
  String get idTypeResidentPermit => 'Resident Permit';

  @override
  String get selectDocumentType => 'Select Document Type';

  @override
  String get addIdDocument => 'Add ID Document';

  @override
  String get editDocument => 'Edit Document';

  @override
  String get idExpiryAfterIssue => 'Expiry must be after the issue date';

  @override
  String get idDobNotInFuture => 'Date of birth cannot be in the future';

  @override
  String get idIssueDateNotInFuture => 'Issue date cannot be in the future';

  @override
  String get idUpdatedSecurely => 'ID document updated securely.';

  @override
  String get idAddedSecurely => 'ID document added securely.';

  @override
  String get cardAddedSecurely => 'Card added securely.';

  @override
  String get cardUpdatedSecurely => 'Card updated securely.';

  @override
  String get cardRemoved => 'Card removed.';

  @override
  String get idRemoved => 'ID document removed.';

  @override
  String andBackedUp(String message) {
    return '$message Backup updated.';
  }

  @override
  String savedButNotBackedUp(String message) {
    return '$message It could not be copied to your backup folder yet.';
  }

  @override
  String get setUpBackupTitle => 'No backup yet';

  @override
  String get setUpBackupBody =>
      'Karde can keep a copy of everything, so nothing is lost with this phone.';

  @override
  String get setUpBackupAction => 'Set up';

  @override
  String get addIdNeedsScreenLock =>
      'Set a screen lock on your device to save documents securely.';

  @override
  String get addIdSaveFailed =>
      'Something went wrong saving this document. Please try again.';

  @override
  String get issuingAuthorityTooltip =>
      'The organization, state, or country that issued the ID.\n\nExample: State of California';

  @override
  String get personalIdTooltip =>
      'A secondary personal identifier.\n\nExample: 123-45-6789';

  @override
  String get idNotesTooltip =>
      'Any additional details or address information from the ID.\n\nExample: Organ donor, Class C driver';

  @override
  String get idUnlockFailedWarning =>
      'This document could not be unlocked, so its details are not shown and saving is turned off. Go back and try again.';

  @override
  String get customDocumentType => 'Custom Document Type';

  @override
  String get customDocumentTypeHint => 'e.g., Student ID';

  @override
  String get customDocumentTypeTooltip =>
      'The specific name of this custom document type.\n\nExample: Gym Pass';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get nicknameHint => 'e.g., My Passport';

  @override
  String get nicknameTooltip =>
      'A personal nickname to easily identify this document in your vault.\n\nExample: My Passport';

  @override
  String get documentPhotoLabel => 'DOCUMENT PHOTO';

  @override
  String get documentPhotoHint =>
      'Optional. Kept locked with the rest of the document.';

  @override
  String get documentPhotoViewerTitle => 'Document photo';

  @override
  String get searchItems => 'Search items...';

  @override
  String get pinToTop => 'Pin to Top';

  @override
  String get unpinFromTop => 'Unpin from Top';

  @override
  String get pinToHomescreen => 'Pin to Homescreen';

  @override
  String get unpinFromHomescreen => 'Unpin from Homescreen';

  @override
  String get addItem => 'Add Item';

  @override
  String get photoBadge => 'Photo';

  @override
  String get tapCardForDetails => 'Tap the card for full details';

  @override
  String get noMatches => 'No matches';

  @override
  String noMatchesMessage(String query) {
    return 'Nothing here matches \"$query\". Try a different word.';
  }

  @override
  String get noIdsYet => 'No IDs yet';

  @override
  String get noIdsYetMessage =>
      'Passports, licences and other documents you add will appear here.';

  @override
  String get noCardsYet => 'No cards yet';

  @override
  String get noCardsYetMessage =>
      'Bank cards, loyalty cards and anything else you add will appear here.';

  @override
  String get addNewId => 'Add New ID';

  @override
  String get sortItems => 'Sort Items';

  @override
  String get sortNewestFirst => 'Newest First';

  @override
  String get sortOldestFirst => 'Oldest First';

  @override
  String get sortAlphabetical => 'Alphabetical (A-Z)';

  @override
  String get settingsSecurityQuestions => 'Change security questions';

  @override
  String get settingsSecurityQuestionsAdd => 'Add security questions';

  @override
  String get settingsSecurityQuestionsDesc =>
      'Change the questions used to recover your PIN';

  @override
  String get settingsSecurityQuestionsAddDesc =>
      'Set up questions that let you reset your Karde PIN';

  @override
  String get settingsBackupSection => 'BACKUP';

  @override
  String get settingsBackupRestoreDesc =>
      'Save an encrypted copy of your vault, or restore one';

  @override
  String get settingsDangerZone => 'DANGER ZONE';

  @override
  String get settingsEraseVault => 'Erase vault';

  @override
  String get settingsEraseVaultDesc =>
      'Permanently delete every card, ID, photo and setting';

  @override
  String aboutDialogBody(String name, String version) {
    return '$name v$version\n\nAn offline vault for the cards and documents you would rather not carry.\n\nEverything you save is encrypted on this phone and unlocked with your fingerprint. Karde has no account and no internet access, so nothing you store can leave your device — not to us, not to anyone.\n\nBecause nothing is kept anywhere else, an encrypted backup is the only way to move your vault to a new phone.';
  }

  @override
  String get eraseEverythingTitle => 'Erase everything?';

  @override
  String get eraseEverythingMessage =>
      'Every card, ID document and photo will be permanently deleted, along with your PIN and settings. This cannot be undone, and Karde keeps no copy anywhere.';

  @override
  String get backUpFirst => 'Back up first';

  @override
  String get settingsLockExplainer =>
      'Your phone will also ask for your fingerprint or screen lock whenever you open an item.';

  @override
  String get settingsNoScreenLockWarning =>
      'This phone has no screen lock, so Karde cannot save or open your items. Add a PIN, pattern, password or fingerprint in your phone\'s settings, then come back.';

  @override
  String get passphraseTooShort => 'Too short';

  @override
  String get passphraseWeak => 'Weak';

  @override
  String get passphraseReasonable => 'Reasonable';

  @override
  String get passphraseStrong => 'Strong';

  @override
  String passphraseWeakHint(String label) {
    return '$label — longer is far better than more complicated';
  }

  @override
  String get passphraseChooseTitle => 'Choose a passphrase';

  @override
  String get passphraseEnterTitle => 'Enter the passphrase';

  @override
  String get passphraseCreateExplainer =>
      'If you forget this, the backup cannot be opened. Karde cannot reset it for you.';

  @override
  String get passphraseUnlockExplainer =>
      'Enter the passphrase you chose when this backup was created.';

  @override
  String get passphraseFieldLabel => 'Passphrase';

  @override
  String get passphraseShow => 'Show passphrase';

  @override
  String get passphraseHide => 'Hide passphrase';

  @override
  String get passphraseRequired => 'Enter a passphrase.';

  @override
  String passphraseMinimumLength(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String get passphraseConfirmLabel => 'Confirm passphrase';

  @override
  String get passphraseMismatch => 'The two entries do not match.';

  @override
  String get passphraseAdvice =>
      'A few unrelated words are easier to remember and harder to guess than one short complicated word.';

  @override
  String get unlock => 'Unlock';

  @override
  String get securityQuestionFirstPet => 'What was the name of your first pet?';

  @override
  String get securityQuestionMothersMaidenName =>
      'What is your mother\'s maiden name?';

  @override
  String get securityQuestionElementarySchool =>
      'What was the name of your elementary school?';

  @override
  String get securityQuestionCityOfBirth => 'In what city were you born?';

  @override
  String get securityQuestionFirstCar => 'What was the make of your first car?';

  @override
  String get securityQuestionFavouriteBook => 'What is your favorite book?';

  @override
  String get chooseBothQuestions => 'Choose both questions.';

  @override
  String get chooseTwoDifferentQuestions => 'Choose two different questions.';

  @override
  String get securityQuestionsUpdated => 'Security questions updated.';

  @override
  String get securityQuestionsSaved => 'Security questions saved.';

  @override
  String get changeSecurityQuestionsTitle => 'Change your security questions';

  @override
  String get changeSecurityQuestionsSubtitle =>
      'These let you back in if you forget your Karde PIN.';

  @override
  String get saveQuestions => 'Save questions';

  @override
  String get chooseAQuestion => 'Choose a question';

  @override
  String get securityAnswersHashNoteChanging =>
      'Your current answers cannot be shown, only replaced. Saving replaces both.';

  @override
  String get securityAnswersHashNoteNew =>
      'Capitalisation and spacing do not matter.';

  @override
  String get alreadyUsedAbove => 'Already used above';

  @override
  String get notesDecryptError => 'Error decrypting notes.';

  @override
  String get deleteCardTitle => 'Delete this card?';

  @override
  String get deleteCardMessage =>
      'This cannot be undone. The card will be permanently deleted.';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get privateNotesAndPhoto => 'PRIVATE NOTES & PHOTO';

  @override
  String get cardMetadata => 'CARD METADATA';

  @override
  String get notesAndPhoto => 'Notes and photo';

  @override
  String get privateNotesTitle => 'Private notes';

  @override
  String get tapToUnlock => 'Tap to unlock';

  @override
  String get photoCouldNotBeDisplayed => 'This photo could not be displayed.';

  @override
  String get addedOn => 'Added On';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get idOpenFailed => 'Could not open this document. Try again.';

  @override
  String get deleteIdTitle => 'Delete this ID?';

  @override
  String get deleteIdMessage =>
      'This cannot be undone. The document will be permanently deleted.';

  @override
  String get additionalDetails => 'ADDITIONAL DETAILS';

  @override
  String get detailsSection => 'DETAILS';

  @override
  String get deleteId => 'Delete ID';

  @override
  String get documentDetails => 'Document details';

  @override
  String get noExtraDetails => 'This document has no extra details.';

  @override
  String get dashboardLoadError => 'Could not load your items.';

  @override
  String get biometricChangeTitle => 'Phone unlock changed';

  @override
  String get biometricChangeMessage =>
      'A fingerprint or face was added or removed on this phone. If that was you, nothing is wrong.';

  @override
  String get gotIt => 'Got it';

  @override
  String get securityWarning => 'Security Warning';

  @override
  String get securityRisk => 'Security Risk';

  @override
  String noBiometricsEnrolled(String details) {
    return 'No biometrics enrolled. $details';
  }

  @override
  String missingSecureLockScreen(String details) {
    return 'Device is missing secure lock screen. $details';
  }

  @override
  String get authReasonRevealCard =>
      'Please authenticate to reveal sensitive card information.';

  @override
  String get authReasonOpenKarde => 'Please authenticate to open Karde.';

  @override
  String get authRequiredTitle => 'Authentication Required';

  @override
  String get useKardePin => 'Use Karde PIN';

  @override
  String get biometricsNotEnrolled =>
      'Biometrics not supported or not enrolled on this device.';

  @override
  String get biometricLockedOut =>
      'Your phone has paused fingerprint unlock after too many tries. Wait a moment, or use your screen lock.';

  @override
  String get biometricUnavailableNow =>
      'Your phone could not check your fingerprint just now.';

  @override
  String get biometricAuthFailedUsePin =>
      'Biometric authentication failed. Please use PIN.';

  @override
  String get resetPinBiometricReason =>
      'Scan your fingerprint (or face) to reset your PIN';

  @override
  String get verificationNotCompleted =>
      'Verification was not completed. Try again, or use another recovery option below.';

  @override
  String get biometricVerificationUnavailable =>
      'Biometric verification is unavailable right now. Use another recovery option below.';

  @override
  String get privacyPolicyHeading => 'Privacy Policy for Karde';

  @override
  String get privacyPolicyEffectiveDate => 'Effective Date: September 2026';

  @override
  String get privacySection1Title => '1. Local Storage Only';

  @override
  String get privacySection1Body =>
      'All your data, including card numbers, CVVs, and notes, is encrypted and stored locally on your device. We do not transmit, back up, or store your data on any external servers or cloud services. You have complete control over your data.';

  @override
  String get privacySection2Title => '2. Encryption';

  @override
  String get privacySection2Body =>
      'Your data is secured using AES-256-GCM encryption. The encryption keys are securely generated and stored in your device\'s hardware-backed Keystore.';

  @override
  String get privacySection3Title => '3. Authentication';

  @override
  String get privacySection3Body =>
      'To access your sensitive data, Karde requires local authentication via your device\'s Biometrics (Face ID/Fingerprint) or your custom Karde PIN. We do not have access to your PIN or biometric data.';

  @override
  String get privacySection4Title => '4. Data Deletion';

  @override
  String get privacySection4Body =>
      'You can permanently delete all your data at any time using the \"Erase vault\" feature in Settings, or by uninstalling the application. Since no data is stored in the cloud, uninstallation results in permanent deletion of your vault.';

  @override
  String get privacySection5Title => '5. Permissions';

  @override
  String get privacySection5Body =>
      'The app only requests permissions necessary for its core functionality, such as Biometric authentication. It does not request internet access, ensuring your data cannot be transmitted.';

  @override
  String get privacySection6Title => '6. Changes to this Policy';

  @override
  String get privacySection6Body =>
      'We may update this policy occasionally. Any changes will be reflected in the app. By continuing to use the app, you agree to the updated policy.';

  @override
  String get recoveryNoPinNote =>
      'You chose to unlock Karde with your phone\'s own lock, so there is no Karde PIN to recover yet. Setting this up now means a way back in already exists if you ever add one.';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get confirm => 'Confirm';

  @override
  String get noScreenLockWarning =>
      'This phone has no screen lock, so Karde cannot save or open any items.\n\nAdd a PIN, pattern, password or fingerprint in your phone\'s settings.\n\nYou can finish setting up now and come back to it.';

  @override
  String get backToLanguage => 'Back to language';

  @override
  String get imageNoSource => 'No app on this device can provide an image.';

  @override
  String get imageUnreadable =>
      'That image could not be read. Try another one.';

  @override
  String get imageNotAvailable =>
      'Adding photos is not available on this device.';

  @override
  String get photoCouldNotBeAdded =>
      'That photo could not be added. Try another.';

  @override
  String get tapToViewFullSize => 'Tap to view full size';

  @override
  String get replacePhoto => 'Replace';

  @override
  String get removePhoto => 'Remove';

  @override
  String get addAPhoto => 'Add a photo';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get photoClosesAutomatically =>
      'Closes automatically. Screenshots are blocked.';

  @override
  String get unlockNeedsScreenLock =>
      'Set a screen lock on your device to unlock your vault.';

  @override
  String get itemNoLongerDecryptable =>
      'Your device security settings changed, so this item can no longer be decrypted.';

  @override
  String get couldNotUnlockCard =>
      'Could not unlock this card. Please try again.';

  @override
  String get couldNotUnlockDocument =>
      'Could not unlock this document. Please try again.';

  @override
  String get cardNumberCopied => 'Card number copied. Clipboard clears in 60s.';

  @override
  String pinLockedTryAgainIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Wrong PIN. Try again in $seconds seconds.',
      one: 'Wrong PIN. Try again in 1 second.',
    );
    return '$_temp0';
  }

  @override
  String pinLockedTryAgainInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Wrong PIN. Try again in $minutes minutes.',
      one: 'Wrong PIN. Try again in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get pinInvalid => 'Wrong PIN.';

  @override
  String pinDigitSemantic(String digit) {
    return 'PIN digit $digit';
  }

  @override
  String get deleteLastDigit => 'Delete last digit';

  @override
  String get vaultUpdatedWithNewPin =>
      'Your secure vault has been updated with the new PIN.';

  @override
  String get vaultReadyWithNewPin => 'You can now use this PIN to open Karde.';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get cardholderPlaceholder => 'NAME SURNAME';

  @override
  String get privacySection7Title => '7. Keep Your Screen Lock';

  @override
  String get privacySection7Body =>
      'Karde\'s encryption key lives in your phone\'s security chip, and it exists only while your phone has a screen lock. Changing your PIN, pattern, password or fingerprints is safe — your saved items stay readable. But if you turn your screen lock off completely, that key is destroyed and your items can no longer be opened by anyone, including us. An encrypted backup is the only thing that survives it, so make one before removing your screen lock.';

  @override
  String get privacySection8Title => '8. Contact';

  @override
  String get privacySection8Body =>
      'Questions about this policy, or anything unclear: support@getgubae.com.';

  @override
  String get biometricCouldNotConfirm =>
      'Could not confirm it was you. Try again.';

  @override
  String get noBackupTitle => 'No backup yet';

  @override
  String get noBackupShort =>
      'No backup yet — everything is only on this phone.';

  @override
  String get noBackupBody =>
      'Everything you have saved is only on this phone. A backup lets you get it all back on a new phone.';

  @override
  String get copyLabel => 'Copy';

  @override
  String get passphraseSectionTitle => 'Your backup passphrase';

  @override
  String get passphraseSectionBody =>
      'This is the only thing that opens your backup on a new phone. Karde cannot reset it for you.';

  @override
  String get passphraseShowTitle => 'Show my passphrase';

  @override
  String get passphraseShowBody =>
      'Unlock with your fingerprint or screen lock to see it.';

  @override
  String get passphraseSaveTitle => 'Keep my passphrase on this phone';

  @override
  String get passphraseSaveBody =>
      'Then you can look it up here whenever you are unsure.';

  @override
  String get passphraseChangeTitle => 'Change my passphrase';

  @override
  String get passphraseChangeBody =>
      'You will need to type the current one first.';

  @override
  String get passphraseChangeWarning =>
      'Your backup moves to the new passphrase straight away. The dated copies from earlier days stay locked with the old one, so keep the old passphrase until you no longer need them.';

  @override
  String get passphraseChanged => 'Your backup passphrase has been changed.';

  @override
  String get passphraseUnchanged => 'That is the passphrase you already have.';

  @override
  String get passphraseNotOnThisPhone =>
      'Karde no longer has a copy of your passphrase on this phone.';

  @override
  String get passphraseCouldNotSave =>
      'Karde could not keep a copy on this phone. Your backup itself is fine.';

  @override
  String get passphraseSavedOnPhone =>
      'Saved. You can look it up on this screen whenever you need it.';

  @override
  String get passphraseRevealTitle => 'Your backup passphrase';

  @override
  String get passphraseRevealWarning =>
      'Write it down somewhere other than this phone, or keep it in a password manager. If the phone goes, this copy goes with it.';

  @override
  String get passphraseCopied => 'Passphrase copied. Clipboard clears in 60s.';

  @override
  String get passphraseReuseTitle => 'Use your backup passphrase?';

  @override
  String get passphraseReuseMessage =>
      'Karde can lock this file with the same passphrase your automatic backup already uses, so there is only one for you to remember.';

  @override
  String get passphraseReuseConfirm => 'Use it';

  @override
  String get passphraseReuseAlternative => 'Type a different one';

  @override
  String get backupIncompleteTitle => 'Your backup is missing things';

  @override
  String backupIncompleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are not in your backup yet.',
      one: 'One item is not in your backup yet.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingTitle => 'Copy what you already had';

  @override
  String backupCopyExistingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are in your vault but not in your backup.',
      one: 'One item is in your vault but not in your backup.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingAction => 'Copy them now';

  @override
  String backupCopyConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $count items',
      one: 'Copy 1 item',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyConfirmMessage =>
      'Your phone will ask you to confirm your identity once per item. Anything you save from now on is copied without asking.';

  @override
  String get backupCopying => 'Copying to your backup…';

  @override
  String backupCopyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to your backup.',
      one: '1 item added to your backup.',
    );
    return '$_temp0';
  }

  @override
  String expiryCardSoon(String when) {
    return 'This card expires in $when.';
  }

  @override
  String expiryCardPast(String when) {
    return 'This card expired in $when.';
  }

  @override
  String expiryDocumentSoon(String when) {
    return 'This document expires on $when.';
  }

  @override
  String expiryDocumentPast(String when) {
    return 'This document expired on $when.';
  }

  @override
  String get settingsExpiryReminders => 'Expiry reminders';

  @override
  String get settingsExpiryRemindersDesc =>
      'Tell me before a card or document runs out';

  @override
  String get remindersBlockedTitle => 'Receive reminders';

  @override
  String get remindersBlockedBody =>
      'Your phone is stopping Karde from telling you before a card or document runs out.';

  @override
  String notifyExpiringBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards or documents expire soon. Open Karde to see which.',
      one: '1 card or document expires soon. Open Karde to see which.',
    );
    return '$_temp0';
  }

  @override
  String notifyExpiredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards or documents have expired. Open Karde to see which.',
      one: '1 card or document has expired. Open Karde to see which.',
    );
    return '$_temp0';
  }

  @override
  String get settingsExpiryNotifyBlocked =>
      'Karde cannot send reminders until notifications are allowed for it in your phone\'s settings.';

  @override
  String get settingsAutoBackupTitle => 'Automatic backup';

  @override
  String get settingsAutoBackupDesc =>
      'Keep a copy up to date every time something changes';

  @override
  String get settingsAutoBackupOffTitle => 'Turn off automatic backup?';

  @override
  String get settingsAutoBackupOffMessage =>
      'Karde will stop keeping your backup up to date. The file already in your folder is left exactly as it is — nothing is deleted.';

  @override
  String get settingsAutoBackupOffConfirm => 'Turn off';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get activityTitle => 'Recent activity';

  @override
  String get activityEmpty =>
      'Nothing yet. Adding, changing or removing a card or document will show up here.';

  @override
  String get activityClear => 'Clear';

  @override
  String activityCardAdded(String name) {
    return 'You added the card $name';
  }

  @override
  String activityCardChanged(String name) {
    return 'You changed the card $name';
  }

  @override
  String activityCardRemoved(String name) {
    return 'You deleted the card $name';
  }

  @override
  String activityDocumentAdded(String name) {
    return 'You added the document $name';
  }

  @override
  String activityDocumentChanged(String name) {
    return 'You changed the document $name';
  }

  @override
  String activityDocumentRemoved(String name) {
    return 'You deleted the document $name';
  }

  @override
  String get cameraTitle => 'Take a photo';

  @override
  String get cameraGuideHint => 'Line the card or document up inside the frame';

  @override
  String get cameraCropHint => 'Drag the corners to choose what to keep';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraUsePhoto => 'Use this photo';

  @override
  String get cameraCaptureFailed =>
      'That photo could not be taken. Please try again.';

  @override
  String get cameraUnavailable =>
      'Karde does not have permission to use the camera. You can take the photo with your phone\'s camera app instead.';

  @override
  String get cameraUsePhoneCamera => 'Use my phone\'s camera';
}
