// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Karde';

  @override
  String get welcomeTitle => 'مرحباً بك في كاردي';

  @override
  String get welcomeSubtitle => 'محفظتك الرقمية الآمنة وغير المتصلة';

  @override
  String get offlineBadge => 'غير متصل ومشفر';

  @override
  String get quickAccess => 'وصول سريع';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get addACard => 'إضافة بطاقة';

  @override
  String get openVault => 'فتح الخزنة';

  @override
  String get vaultHealthExcellent => 'صحة الخزنة: ممتازة';

  @override
  String vaultHealthItems(int count) {
    return '$count عناصر مشفرة باستخدام AES-256-GCM';
  }

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get vaultTab => 'الخزنة';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get myVault => 'خزنتي';

  @override
  String get allFilter => 'الكل';

  @override
  String get cardsFilter => 'البطاقات';

  @override
  String get idsFilter => 'الهويات • قريباً';

  @override
  String get addNewCard => 'إضافة بطاقة جديدة';

  @override
  String get identification => 'التعريف';

  @override
  String get issuerLabel => 'المُصدِر';

  @override
  String get issuerHint => 'مثال: اسم البنك أو المزود';

  @override
  String get cardNetworkLabel => 'شبكة البطاقة';

  @override
  String get cardholderNameLabel => 'اسم حامل البطاقة';

  @override
  String get cardholderNameHint => 'الاسم على البطاقة';

  @override
  String get cardDetails => 'تفاصيل البطاقة';

  @override
  String get cardNumberLabel => 'رقم البطاقة';

  @override
  String get cardNumberHint => '0000 0000 0000 0000';

  @override
  String get expiryLabel => 'الانتهاء';

  @override
  String get expiryHint => 'شهر/سنة';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get extraInfo => 'معلومات إضافية (اختياري)';

  @override
  String get privateNotesLabel => 'ملاحظات خاصة';

  @override
  String get privateNotesHint => 'أرقام هواتف البنك، تلميحات الرمز...';

  @override
  String get saveItem => 'حفظ العنصر';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get invalidFormat => 'تنسيق غير صالح';

  @override
  String get cardDetailsTitle => 'تفاصيل البطاقة';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get deleteCard => 'حذف البطاقة';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get amharic => 'አማርኛ';

  @override
  String get setupLockTitle => 'تأمين محفظتك';

  @override
  String get setupLockSubtitle => 'كيف تود حماية أسرارك؟';

  @override
  String get phoneLock => 'قفل الهاتف';

  @override
  String get phoneLockDesc =>
      'استخدم بصمة الوجه أو الإصبع أو الرمز السري للهاتف.';

  @override
  String get kardePin => 'رمز Karde';

  @override
  String get kardePinDesc => 'أنشئ رمزاً سرياً خاصاً بهذا التطبيق.';

  @override
  String get bothLocks => 'كلاهما';

  @override
  String get bothLocksDesc => 'قفل الهاتف للتطبيق، ورمز Karde للأسرار.';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get createPin => 'إنشاء الرمز السري';

  @override
  String get enterPin => 'أدخل رمزك الجديد';

  @override
  String get confirmPin => 'تأكيد الرمز السري';

  @override
  String get reEnterPin => 'يرجى إعادة إدخال الرمز';

  @override
  String get pinMismatch => 'الرموز غير متطابقة. حاول مرة أخرى.';

  @override
  String get enterKardePin => 'أدخل رمز Karde السري';

  @override
  String get unlockToReveal => 'افتح القفل للكشف عن الأسرار';

  @override
  String get recoverySetupTitle => 'استعادة رقم التعريف';

  @override
  String get recoverySetupSubtitle =>
      'كيف تود استعادة رقم التعريف الشخصي إذا نسيته؟';

  @override
  String get biometricRecovery => 'قفل الهاتف';

  @override
  String get biometricRecoveryDesc =>
      'استخدم الطريقة التي تفتح بها هاتفك — بصمة الإصبع أو الوجه أو النمط أو رمز PIN أو كلمة المرور — لإعادة تعيين رمز Karde الخاص بك.';

  @override
  String get securityQuestions => 'أسئلة الأمان';

  @override
  String get securityQuestionsDesc =>
      'أجب على سؤالين لإعادة تعيين رقم التعريف.';

  @override
  String get noRecovery => 'لا يوجد استرداد';

  @override
  String get noRecoveryDesc =>
      'حماية قصوى. نسيان رقم التعريف يعني فقدان البيانات نهائياً.';

  @override
  String get setupQuestionsTitle => 'إعداد أسئلة الأمان';

  @override
  String get setupQuestionsSubtitle => 'اختر سؤالين وأجب عليهما';

  @override
  String get question1 => 'السؤال 1';

  @override
  String get question2 => 'السؤال 2';

  @override
  String get answer => 'الإجابة';

  @override
  String get answerRequired => 'الإجابة مطلوبة';

  @override
  String get finishSetup => 'إنهاء الإعداد';

  @override
  String get forgotPin => 'هل نسيت رقم التعريف؟';

  @override
  String get resetPinTitle => 'إعادة تعيين';

  @override
  String get resetPinSubtitle => 'اختر طريقة استرداد';

  @override
  String get wipeDataBtn => 'مسح بيانات التطبيق (خطر)';

  @override
  String get wipeDataWarning =>
      'سيؤدي هذا إلى حذف جميع بطاقاتك بشكل دائم وإعادة تعيين التطبيق. هل أنت متأكد؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get wipe => 'مسح';

  @override
  String get verifyQuestionsTitle => 'أجب على أسئلة الأمان';

  @override
  String get verifyQuestionsSubtitle =>
      'أجب على السؤالين لإعادة تعيين رقم التعريف';

  @override
  String get verifyBtn => 'تحقق';

  @override
  String get wrongAnswers => 'إحدى الإجابتين أو كلتاهما غير صحيحة.';

  @override
  String get resetPinSuccess =>
      'تم التحقق بنجاح. يمكنك الآن تعيين رقم تعريف جديد.';

  @override
  String get maxAttemptsReached =>
      'تم الوصول إلى الحد الأقصى للمحاولات. يجب عليك إعادة تعيين رقم التعريف.';

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
