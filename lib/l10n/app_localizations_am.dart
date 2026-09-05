// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'Karde';

  @override
  String get welcomeTitle => 'እንኳን ወደ Karde በደህና መጡ';

  @override
  String get welcomeSubtitle => 'የእርስዎ ደህንነቱ የተጠበቀ ዲጂታል ዋሌት';

  @override
  String get offlineBadge => 'ከመስመር ውጭ እና የተመሰጠረ';

  @override
  String get quickAccess => 'ፈጣን መዳረሻ';

  @override
  String get seeAll => 'ሁሉንም ይመልከቱ';

  @override
  String get addACard => 'ካርድ ያክሉ';

  @override
  String get openVault => 'ካዝናውን ይክፈቱ';

  @override
  String get vaultHealthExcellent => 'የካዝና ጤና፡ እጅግ በጣም ጥሩ';

  @override
  String vaultHealthItems(int count) {
    return '$count ነገሮች በAES-256-GCM የተመሰጠሩ';
  }

  @override
  String get homeTab => 'ዋና ገጽ';

  @override
  String get vaultTab => 'ካዝና';

  @override
  String get settingsTab => 'ቅንብሮች';

  @override
  String get myVault => 'የእኔ ካዝና';

  @override
  String get allFilter => 'ሁሉም';

  @override
  String get cardsFilter => 'ካርዶች';

  @override
  String get idsFilter => 'መታወቂያዎች • በቅርቡ';

  @override
  String get addNewCard => 'አዲስ ካርድ ያክሉ';

  @override
  String get identification => 'መለያ';

  @override
  String get issuerLabel => 'አቅራቢ';

  @override
  String get issuerHint => 'ለምሳሌ፡ የባንክ ስም';

  @override
  String get cardNetworkLabel => 'የካርድ ኔትወርክ';

  @override
  String get cardholderNameLabel => 'የካርድ ባለቤት ስም';

  @override
  String get cardholderNameHint => 'በካርዱ ላይ ያለው ስም';

  @override
  String get cardDetails => 'የካርድ ዝርዝሮች';

  @override
  String get cardNumberLabel => 'የካርድ ቁጥር';

  @override
  String get cardNumberHint => '0000 0000 0000 0000';

  @override
  String get expiryLabel => 'የሚያበቃበት ጊዜ';

  @override
  String get expiryHint => 'ወር/ዓመት';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get extraInfo => 'ተጨማሪ መረጃ (አማራጭ)';

  @override
  String get privateNotesLabel => 'የግል ማስታወሻዎች';

  @override
  String get privateNotesHint => 'የባንክ ስልክ ቁጥሮች፣ የፒን ፍንጮች...';

  @override
  String get saveItem => 'አስቀምጥ';

  @override
  String get requiredField => 'ያስፈልጋል';

  @override
  String get invalidFormat => 'ትክክለኛ ያልሆነ ፎርማት';

  @override
  String get cardDetailsTitle => 'የካርድ ዝርዝሮች';

  @override
  String get editDetails => 'ዝርዝሮችን ያርትዑ';

  @override
  String get deleteCard => 'ካርዱን ይሰርዙ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get setupLockTitle => 'ዋሌትዎን ይጠብቁ';

  @override
  String get setupLockSubtitle => 'ሚስጥሮችዎን እንዴት መጠበቅ ይፈልጋሉ?';

  @override
  String get phoneLock => 'የስልክ ቁልፍ';

  @override
  String get phoneLockDesc => 'የስልክዎን Face ID፣ Touch ID ወይም የይለፍ ቃል ይጠቀሙ።';

  @override
  String get kardePin => 'የKarde ፒን';

  @override
  String get kardePinDesc => 'ለዚህ መተግበሪያ ብቻ የራስዎን ፒን ይፍጠሩ።';

  @override
  String get bothLocks => 'ሁለቱም';

  @override
  String get bothLocksDesc => 'መተግበሪያውን ለመክፈት የስልክ ቁልፍ፣ ሚስጥሮችን ለማየት የKarde ፒን።';

  @override
  String get continueBtn => 'ቀጥል';

  @override
  String get createPin => 'ፒን ይፍጠሩ';

  @override
  String get enterPin => 'አዲሱን ፒን ያስገቡ';

  @override
  String get confirmPin => 'ፒኑን ያረጋግጡ';

  @override
  String get reEnterPin => 'እባክዎ ፒንዎን እንደገና ያስገቡ';

  @override
  String get pinMismatch => 'ፒኖቹ አይመሳሰሉም። እንደገና ይሞክሩ።';

  @override
  String get enterKardePin => 'የKarde ፒንዎን ያስገቡ';

  @override
  String get unlockToReveal => 'ሚስጥሮችን ለማየት ይክፈቱ';

  @override
  String get recoverySetupTitle => 'የፒን ማግኛ';

  @override
  String get recoverySetupSubtitle => 'ፒንዎን ቢረሱ እንዴት ማግኘት ይፈልጋሉ?';

  @override
  String get biometricRecovery => 'የስልክ መቆለፊያ';

  @override
  String get biometricRecoveryDesc =>
      'ስልክዎን የሚከፍቱበትን መንገድ — የጣት አሻራ፣ ፊት፣ ንድፍ፣ ፒን ወይም የይለፍ ቃል — ተጠቅመው የካርዴ ፒንዎን ዳግም ያስጀምሩ።';

  @override
  String get securityQuestions => 'የደህንነት ጥያቄዎች';

  @override
  String get securityQuestionsDesc => 'ፒንዎን ዳግም ለማስጀመር 2 ጥያቄዎችን ይመልሱ።';

  @override
  String get noRecovery => 'ምንም ማግኛ የለም';

  @override
  String get noRecoveryDesc => 'ከፍተኛ ደህንነት። ፒንዎን ከረሱ መረጃዎ በዘላቂነት ይጠፋል።';

  @override
  String get setupQuestionsTitle => 'የደህንነት ጥያቄዎችን ያዘጋጁ';

  @override
  String get setupQuestionsSubtitle => '2 ጥያቄዎችን እና መልሶችን ይምረጡ';

  @override
  String get question1 => 'ጥያቄ 1';

  @override
  String get question2 => 'ጥያቄ 2';

  @override
  String get answer => 'መልስ';

  @override
  String get answerRequired => 'መልስ ያስፈልጋል';

  @override
  String get finishSetup => 'ማዋቀርን ጨርስ';

  @override
  String get forgotPin => 'ፒን ረሱ?';

  @override
  String get resetPinTitle => 'ፒን ዳግም ያስጀምሩ';

  @override
  String get resetPinSubtitle => 'የማግኛ ዘዴ ይምረጡ';

  @override
  String get wipeDataBtn => 'የመተግበሪያ ውሂብ አጥፋ (አደጋ)';

  @override
  String get wipeDataWarning =>
      'ይህ ሁሉንም የተቀመጡ ካርዶችዎን በዘላቂነት ያጠፋል እና መተግበሪያውን ዳግም ያስጀምራል። እርግጠኛ ነዎት?';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get wipe => 'አጥፋ';

  @override
  String get verifyQuestionsTitle => 'የደህንነት ጥያቄዎችን ይመልሱ';

  @override
  String get verifyQuestionsSubtitle => 'ፒንዎን ዳግም ለማስጀመር ሁለቱንም ጥያቄዎች ይመልሱ';

  @override
  String get verifyBtn => 'አረጋግጥ';

  @override
  String get wrongAnswers => 'አንድ ወይም ሁለቱም መልሶች ትክክል አይደሉም።';

  @override
  String get resetPinSuccess => 'ማረጋገጫው ተሳክቷል። አሁን አዲስ ፒን ማዘጋጀት ይችላሉ።';

  @override
  String get maxAttemptsReached => 'ከፍተኛ ሙከራዎች ደርሰዋል። ፒንዎን ዳግም ማስጀመር አለብዎት።';

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
