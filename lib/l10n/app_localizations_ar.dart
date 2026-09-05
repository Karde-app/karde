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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر مشفّر باستخدام AES-256-GCM',
      many: '$count عنصراً مشفّراً باستخدام AES-256-GCM',
      few: '$count عناصر مشفّرة باستخدام AES-256-GCM',
      two: 'عنصران مشفّران باستخدام AES-256-GCM',
      one: 'عنصر واحد مشفّر باستخدام AES-256-GCM',
      zero: '$count عنصر مشفّر باستخدام AES-256-GCM',
    );
    return '$_temp0';
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
  String get idsFilter => 'الهويات';

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
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeDesc => 'النظام أو فاتح أو داكن';

  @override
  String get appDisplayLanguage => 'لغة عرض التطبيق';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get autoHide => 'إخفاء التفاصيل الحساسة تلقائياً';

  @override
  String get autoHideDesc => 'إخفاء رقم البطاقة ورمز CVV تلقائياً';

  @override
  String get security => 'الأمان';

  @override
  String get appPinLock => 'قفل التطبيق برمز سري';

  @override
  String get appPinLockDesc => 'طلب رمز سري لفتح Karde';

  @override
  String get biometricUnlockTitle => 'الفتح بالبصمة';

  @override
  String get biometricUnlockDesc => 'استخدم بصمة إصبعك لفتح Karde';

  @override
  String get changePin => 'تغيير رمز Karde';

  @override
  String get changePinDesc => 'تحديث رمزك الرئيسي';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutKarde => 'حول Karde';

  @override
  String get aboutKardeDesc => 'الإصدار والاعتمادات والتراخيص';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyDesc => 'كيف تبقى بياناتك على جهازك';

  @override
  String get mustKeepOneLock => 'يجب إبقاء طريقة قفل واحدة على الأقل مفعّلة.';

  @override
  String get biometricsNotSupported =>
      'القياسات الحيوية غير مدعومة على هذا الجهاز.';

  @override
  String get biometricsError => 'تعذر التحقق من دعم القياسات الحيوية.';

  @override
  String get invalidCardLength => 'طول رقم البطاقة غير صالح';

  @override
  String get invalidCardNumber => 'رقم البطاقة غير صالح';

  @override
  String get invalidExpiryFormat => 'يجب أن يكون التنسيق شهر/سنة';

  @override
  String get invalidMonth => 'شهر غير صالح';

  @override
  String get cardExpired => 'انتهت صلاحية البطاقة';

  @override
  String get invalidCvvLength => 'يجب أن يتكون رمز CVV من 3 أو 4 أرقام';

  @override
  String get numbersOnly => 'أرقام فقط';

  @override
  String get lettersAndSymbolsNotAllowed => 'الحروف والرموز غير مسموح بها';

  @override
  String get kardeIsLocked => 'Karde مقفل';

  @override
  String get authenticateToAccess => 'تحقق من هويتك للوصول إلى خزنتك.';

  @override
  String get authenticating => 'جارٍ التحقق…';

  @override
  String get unlockKarde => 'فتح Karde';

  @override
  String get exitApp => 'إغلاق التطبيق';

  @override
  String get enterCurrentPin => 'أدخل رمز Karde الحالي';

  @override
  String get createKardePin => 'إنشاء رمز Karde';

  @override
  String get pinChangedSuccess => 'تم تغيير الرمز بنجاح';

  @override
  String get done => 'تم';

  @override
  String get addAnId => 'إضافة هوية';

  @override
  String get idDetails => 'تفاصيل الهوية';

  @override
  String get documentType => 'نوع المستند';

  @override
  String get documentNumber => 'رقم المستند';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get sexGender => 'الجنس';

  @override
  String get issuingAuthority => 'بلد أو جهة الإصدار';

  @override
  String get issueDate => 'تاريخ الإصدار';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get placeOfBirth => 'مكان الميلاد';

  @override
  String get personalId => 'المعرّف الشخصي';

  @override
  String get bloodGroup => 'فصيلة الدم';

  @override
  String get tabAll => 'الكل';

  @override
  String get tabCards => 'البطاقات';

  @override
  String get tabIds => 'الهويات';

  @override
  String get idCardNotAvailable => 'غير متاح';

  @override
  String get idCardPassportTitle => 'جواز سفر دولي';

  @override
  String get idCardType => 'النوع';

  @override
  String get idCardCodeOfIssuingState => 'رمز الدولة المُصدِرة';

  @override
  String get idCardPassportNo => 'رقم جواز السفر';

  @override
  String get idCardSurname => 'اللقب';

  @override
  String get idCardGivenNames => 'الأسماء الشخصية';

  @override
  String get idCardNationalityUpper => 'الجنسية';

  @override
  String get idCardDobUpper => 'تاريخ الميلاد';

  @override
  String get idCardSexUpper => 'الجنس';

  @override
  String get idCardPlaceOfBirthUpper => 'مكان الميلاد';

  @override
  String get idCardAuthorityUpper => 'الجهة المُصدِرة';

  @override
  String get idCardDateOfIssueUpper => 'تاريخ الإصدار';

  @override
  String get idCardDateOfExpiryUpper => 'تاريخ الانتهاء';

  @override
  String get idCardHoldersSignature => 'توقيع حامل الوثيقة';

  @override
  String get idCardResidencePermitTitle => 'تصريح إقامة بيومتري';

  @override
  String get idCardName => 'الاسم';

  @override
  String get idCardGender => 'النوع';

  @override
  String get idCardNationality => 'الجنسية';

  @override
  String get idCardDocumentNo => 'رقم المستند';

  @override
  String get idCardNationalFallback => 'وطنية';

  @override
  String get idCardIdCard => 'بطاقة هوية';

  @override
  String get idCardNationalIdLogo => 'الهوية الوطنية';

  @override
  String get idCardEthiopianDigitalId => 'بطاقة الهوية الرقمية الإثيوبية';

  @override
  String get idCardEthiopianFullName => 'الاسم الأول والأوسط واللقب';

  @override
  String get idCardFullNameUpper => 'الاسم الكامل';

  @override
  String get idCardDateOfExpiry => 'تاريخ الانتهاء';

  @override
  String get idCardCountryOfCitizenship => 'بلد المواطنة (حسب التصريح الذاتي)';

  @override
  String get idCardIssuingAuthorityUpper => 'الجهة المُصدِرة';

  @override
  String get idCardIdNo => 'رقم الهوية';

  @override
  String get idCardDrivingLicenceTitle => 'رخصة قيادة';

  @override
  String get idCardNameUpper => 'الاسم';

  @override
  String get idCardPassportNoShort => 'رقم الجواز';

  @override
  String get idCardDlNo => 'رقم الرخصة';

  @override
  String get idCardDocNo => 'رقم المستند';

  @override
  String get idCardDocumentFallback => 'مستند';

  @override
  String get idCardDocumentHolder => 'حامل المستند';

  @override
  String get idCardDocumentNumberUpper => 'رقم المستند';

  @override
  String get idCardValidFrom => 'صالحة من';

  @override
  String get idCardExpires => 'تنتهي في';

  @override
  String get genericError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupCouldNotReadVault =>
      'تعذّرت قراءة خزنتك. يرجى المحاولة مرة أخرى.';

  @override
  String get backupVaultEmpty => 'لا يوجد شيء في خزنتك لنسخه احتياطياً بعد.';

  @override
  String backupConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نسخ $count عنصر احتياطياً',
      many: 'نسخ $count عنصراً احتياطياً',
      few: 'نسخ $count عناصر احتياطياً',
      two: 'نسخ عنصرين احتياطياً',
      one: 'نسخ عنصر واحد احتياطياً',
      zero: 'نسخ $count عنصر احتياطياً',
    );
    return '$_temp0';
  }

  @override
  String get backupConfirmMessage =>
      'سيطلب منك هاتفك تأكيد هويتك عدة مرات أثناء تنفيذ هذه العملية.\n\nبعد ذلك ستختار عبارة مرور ومكان حفظ الملف.';

  @override
  String get backupPreparing => 'جارٍ تجهيز النسخة الاحتياطية';

  @override
  String get backupUnlockingVault => 'جارٍ فتح خزنتك';

  @override
  String backupSavedAs(String fileName) {
    return 'تم حفظ النسخة الاحتياطية باسم $fileName.';
  }

  @override
  String get backupOpening => 'جارٍ فتح النسخة الاحتياطية';

  @override
  String get backupAllDuplicates =>
      'كل ما في تلك النسخة الاحتياطية موجود بالفعل في خزنتك.';

  @override
  String get backupNoItems => 'لا تحتوي تلك النسخة الاحتياطية على أي عناصر.';

  @override
  String backupSkippedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر موجود بالفعل في خزنتك وسيتم تخطيه.',
      many: '$count عنصراً موجودة بالفعل في خزنتك وسيتم تخطيها.',
      few: '$count عناصر موجودة بالفعل في خزنتك وسيتم تخطيها.',
      two: 'عنصران موجودان بالفعل في خزنتك وسيتم تخطيهما.',
      one: 'عنصر واحد موجود بالفعل في خزنتك وسيتم تخطيه.',
      zero: '$count عنصر موجود بالفعل في خزنتك وسيتم تخطيه.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استعادة $count عنصر',
      many: 'استعادة $count عنصراً',
      few: 'استعادة $count عناصر',
      two: 'استعادة عنصرين',
      one: 'استعادة عنصر واحد',
      zero: 'استعادة $count عنصر',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmMessage(String skipped) {
    return 'سيطلب منك هاتفك تأكيد هويتك عدة مرات أثناء تنفيذ هذه العملية.$skipped\n\nلن يُحذف أو يُعدَّل أي شيء موجود بالفعل في خزنتك.';
  }

  @override
  String get backupRestoreConfirmAction => 'استعادة';

  @override
  String get backupRestoring => 'جارٍ الاستعادة';

  @override
  String backupRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت استعادة $count عنصر إلى خزنتك.',
      many: 'تمت استعادة $count عنصراً إلى خزنتك.',
      few: 'تمت استعادة $count عناصر إلى خزنتك.',
      two: 'تمت استعادة عنصرين إلى خزنتك.',
      one: 'تمت استعادة عنصر واحد إلى خزنتك.',
      zero: 'تمت استعادة $count عنصر إلى خزنتك.',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreCancelled => 'تم إلغاء الاستعادة. لم يتغيّر أي شيء.';

  @override
  String get backupWrongPassphrase =>
      'عبارة المرور هذه لا تفتح هذه النسخة الاحتياطية. تحقق منها وحاول مرة أخرى.';

  @override
  String get backupFileChooseAgain =>
      'تعذّرت قراءة هذا الملف. حاول اختياره مرة أخرى.';

  @override
  String get backupNeedsScreenLock =>
      'اضبط قفل شاشة على جهازك قبل النسخ الاحتياطي أو الاستعادة.';

  @override
  String get backupKeyInvalidated =>
      'لم يعد مفتاح خزنتك صالحاً، لذا لا يمكن قراءة العناصر الموجودة. لا تزال الاستعادة من نسخة احتياطية تعمل.';

  @override
  String get backupExplainerPassphrase =>
      'نسختك الاحتياطية مقفلة بعبارة مرور تختارها أنت. بدونها يصبح الملف غير قابل للقراءة — ولا يستطيع Karde استرجاعها لك، لذا احتفظ بها في مكان آمن.';

  @override
  String get backupExplainerOffline =>
      'لا يُرفع أي شيء إلى الإنترنت. أنت تختار مكان الملف، ويمكن استعادته على هذا الهاتف أو على هاتف جديد.';

  @override
  String get backupCreateTitle => 'إنشاء نسخة احتياطية';

  @override
  String get backupCreateSubtitle =>
      'احفظ نسخة مقفلة من كل ما في خزنتك، في المكان الذي تختاره.';

  @override
  String get backupCreateAction => 'انسخ احتياطياً الآن';

  @override
  String get backupRestoreCardTitle => 'استعادة نسخة احتياطية';

  @override
  String get backupRestoreCardSubtitle =>
      'أضف العناصر من ملف نسخة احتياطية إلى هذه الخزنة. تبقى العناصر الموجودة كما هي، ويُتخطى كل ما هو موجود بالفعل.';

  @override
  String get backupRestoreCardAction => 'اختر ملفاً';

  @override
  String get backupKeepFileSafe =>
      'احتفظ بملف النسخة الاحتياطية في مكان تثق به. فهو يحوي كل ما في خزنتك، ولا يحميه سوى عبارة المرور التي اخترتها.';

  @override
  String backupProgressCount(String label, int completed, int total) {
    return '$label — $completed من $total';
  }

  @override
  String get backupConfirmIdentityHint =>
      'أكّد هويتك عندما يطلب منك هاتفك ذلك. يوقف الإلغاء كل شيء بأمان — ولا يتغيّر أي شيء.';

  @override
  String get backupProblemDamaged => 'محتويات النسخة الاحتياطية تالفة.';

  @override
  String get backupProblemNotKardeBackup =>
      'هذا الملف ليس نسخة احتياطية لخزنة Karde.';

  @override
  String get backupProblemNewerVersion =>
      'أُنشئت هذه النسخة الاحتياطية بإصدار أحدث من Karde. حدّث التطبيق وحاول مرة أخرى.';

  @override
  String get backupProblemPhotoDamaged =>
      'إحدى الصور في النسخة الاحتياطية تالفة.';

  @override
  String backupProblemMissingValue(String key) {
    return 'تفتقر النسخة الاحتياطية إلى القيمة \"$key\".';
  }

  @override
  String backupProblemUnreadableValue(String key) {
    return 'القيمة \"$key\" في النسخة الاحتياطية غير قابلة للقراءة.';
  }

  @override
  String get backupProblemRecordUnreadable => 'تعذّرت قراءة أحد سجلات الخزنة.';

  @override
  String get backupProblemFileDamaged =>
      'تعذّرت قراءة ملف النسخة الاحتياطية هذا. قد يكون تالفاً.';

  @override
  String get otherOption => 'أخرى';

  @override
  String get goBack => 'رجوع';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get loadingDetails => 'جارٍ تحميل التفاصيل';

  @override
  String get setScreenLockFirst => 'اضبط قفل الشاشة أولاً';

  @override
  String get screenLockExplainer =>
      'يشفّر Karde كل عنصر بمفتاح محفوظ في العتاد الآمن داخل هاتفك، وهذا العتاد لا يحتفظ بأي مفتاح ما لم يكن الهاتف نفسه مقفلاً.\n\nأضف رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، ثم عد إلى هنا.';

  @override
  String get vaultKeyChangedItemsLost =>
      'تغيّرت إعدادات الأمان في جهازك، لذا لم يعد مفتاح الخزنة صالحاً. لا يمكن استرجاع العناصر الموجودة.';

  @override
  String get addCardDecryptFailed => 'تعذّر فك تشفير بيانات البطاقة الحالية.';

  @override
  String get addCardNeedsScreenLock =>
      'اضبط قفل شاشة (رمز أو نقش أو بصمة) على جهازك لحفظ البطاقات بأمان.';

  @override
  String get addCardSaveFailed =>
      'حدث خطأ أثناء حفظ هذه البطاقة. يرجى المحاولة مرة أخرى.';

  @override
  String get selectCardNetwork => 'اختر شبكة البطاقة';

  @override
  String get editCard => 'تعديل البطاقة';

  @override
  String get issuerFieldLabel => 'المُصدِر';

  @override
  String get issuerTooltip =>
      'اسم البنك أو المؤسسة التي أصدرت هذه البطاقة.\n\nمثال: البنك الأهلي';

  @override
  String get customNetworkFieldLabel => 'شبكة مخصّصة';

  @override
  String get customNetworkHint => 'مثال: UnionPay أو JCB';

  @override
  String get secureDetails => 'التفاصيل المحمية';

  @override
  String get cardNumberFieldLabel => 'رقم البطاقة';

  @override
  String get cardholderNameFieldLabel => 'اسم حامل البطاقة';

  @override
  String get privateNotesFieldLabel => 'ملاحظات خاصة';

  @override
  String get privateNotesTooltip =>
      'أي تفاصيل أو عناوين أو ملاحظات إضافية.\n\nمثال: هاتف البنك: 19666';

  @override
  String get cardExpiredStillSave =>
      'انتهت صلاحية هذه البطاقة. لا يزال بإمكانك حفظها.';

  @override
  String get cardPhotoLabel => 'صورة البطاقة';

  @override
  String get cardPhotoHint => 'اختياري. تُحفظ مقفلة مع بقية بيانات البطاقة.';

  @override
  String get cardPhotoViewerTitle => 'صورة البطاقة';

  @override
  String requiredFieldMarker(String label) {
    return '$label *';
  }

  @override
  String get idTypePassport => 'جواز سفر';

  @override
  String get idTypeDriversLicense => 'رخصة قيادة';

  @override
  String get idTypeNationalId => 'بطاقة هوية وطنية';

  @override
  String get idTypeResidentPermit => 'تصريح إقامة';

  @override
  String get selectDocumentType => 'اختر نوع المستند';

  @override
  String get addIdDocument => 'إضافة مستند هوية';

  @override
  String get editDocument => 'تعديل المستند';

  @override
  String get idExpiryAfterIssue =>
      'يجب أن يكون تاريخ الانتهاء بعد تاريخ الإصدار';

  @override
  String get idDobNotInFuture => 'لا يمكن أن يكون تاريخ الميلاد في المستقبل';

  @override
  String get idIssueDateNotInFuture =>
      'لا يمكن أن يكون تاريخ الإصدار في المستقبل';

  @override
  String get idUpdatedSecurely => 'تم تحديث مستند الهوية بأمان.';

  @override
  String get idAddedSecurely => 'تمت إضافة مستند الهوية بأمان.';

  @override
  String get addIdNeedsScreenLock =>
      'اضبط قفل شاشة على جهازك لحفظ المستندات بأمان.';

  @override
  String get addIdSaveFailed =>
      'حدث خطأ أثناء حفظ هذا المستند. يرجى المحاولة مرة أخرى.';

  @override
  String get issuingAuthorityTooltip =>
      'الجهة أو الولاية أو الدولة التي أصدرت المستند.\n\nمثال: وزارة الداخلية';

  @override
  String get personalIdTooltip => 'معرّف شخصي ثانوي.\n\nمثال: 123-45-6789';

  @override
  String get idNotesTooltip =>
      'أي تفاصيل أو معلومات عنوان إضافية من المستند.\n\nمثال: متبرع بالأعضاء، رخصة فئة ب';

  @override
  String get idUnlockFailedWarning =>
      'تعذّر فتح هذا المستند، لذا لا تظهر تفاصيله. تم تعطيل الحفظ لتفادي الكتابة فوق بياناتك. عد إلى الخلف وحاول مرة أخرى.';

  @override
  String get customDocumentType => 'نوع مستند مخصّص';

  @override
  String get customDocumentTypeHint => 'مثال: بطاقة طالب';

  @override
  String get customDocumentTypeTooltip =>
      'الاسم المحدد لنوع المستند المخصّص هذا.\n\nمثال: بطاقة نادٍ رياضي';

  @override
  String get nicknameLabel => 'اسم مختصر';

  @override
  String get nicknameHint => 'مثال: جواز سفري';

  @override
  String get nicknameTooltip =>
      'اسم مختصر شخصي يسهّل تمييز هذا المستند داخل خزنتك.\n\nمثال: جواز سفري';

  @override
  String get documentPhotoLabel => 'صورة المستند';

  @override
  String get documentPhotoHint =>
      'اختياري. تُحفظ مقفلة مع بقية بيانات المستند.';

  @override
  String get documentPhotoViewerTitle => 'صورة المستند';

  @override
  String get searchItems => 'ابحث في العناصر…';

  @override
  String get pinToTop => 'تثبيت في الأعلى';

  @override
  String get unpinFromTop => 'إلغاء التثبيت من الأعلى';

  @override
  String get pinToHomescreen => 'تثبيت في الشاشة الرئيسية';

  @override
  String get unpinFromHomescreen => 'إلغاء التثبيت من الشاشة الرئيسية';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get photoBadge => 'صورة';

  @override
  String get tapCardForDetails => 'اضغط على البطاقة لعرض كل التفاصيل';

  @override
  String get noMatches => 'لا توجد نتائج';

  @override
  String noMatchesMessage(String query) {
    return 'لا يوجد هنا ما يطابق \"$query\". جرّب كلمة أخرى.';
  }

  @override
  String get noIdsYet => 'لا توجد هويات بعد';

  @override
  String get noIdsYetMessage =>
      'ستظهر هنا جوازات السفر والرخص والمستندات الأخرى التي تضيفها.';

  @override
  String get noCardsYet => 'لا توجد بطاقات بعد';

  @override
  String get noCardsYetMessage =>
      'ستظهر هنا البطاقات المصرفية وبطاقات الولاء وكل ما تضيفه.';

  @override
  String get addNewId => 'إضافة هوية جديدة';

  @override
  String get sortItems => 'ترتيب العناصر';

  @override
  String get sortNewestFirst => 'الأحدث أولاً';

  @override
  String get sortOldestFirst => 'الأقدم أولاً';

  @override
  String get sortAlphabetical => 'أبجدياً (أ-ي)';

  @override
  String get settingsSecurityQuestions => 'أسئلة الأمان';

  @override
  String get settingsSecurityQuestionsDesc =>
      'غيّر الأسئلة المستخدمة لاستعادة رمزك السري';

  @override
  String get settingsBackupSection => 'النسخ الاحتياطي';

  @override
  String get settingsBackupRestoreDesc =>
      'احفظ نسخة مشفّرة من خزنتك، أو استعد واحدة';

  @override
  String get settingsDangerZone => 'منطقة الخطر';

  @override
  String get settingsEraseVault => 'محو الخزنة';

  @override
  String get settingsEraseVaultDesc =>
      'احذف نهائياً كل بطاقة ومستند وصورة وإعداد';

  @override
  String aboutDialogBody(String name, String version) {
    return '$name v$version\n\nمحفظة تعمل دون اتصال بالإنترنت، للبطاقات والمستندات التي تفضّل ألا تحملها معك.\n\nكل ما تحفظه مشفّر على هذا الهاتف ويُفتح ببصمتك. لا يملك Karde حساباً ولا وصولاً إلى الإنترنت، لذا لا يمكن لأي شيء تخزّنه أن يغادر جهازك — لا إلينا ولا إلى أي جهة أخرى.\n\nولأنه لا يُحفظ شيء في أي مكان آخر، فإن النسخة الاحتياطية المشفّرة هي الطريقة الوحيدة لنقل خزنتك إلى هاتف جديد.';
  }

  @override
  String get zeroKnowledge => 'بدون أي معرفة ببياناتك';

  @override
  String get eraseEverythingTitle => 'محو كل شيء؟';

  @override
  String get eraseEverythingMessage =>
      'ستُحذف نهائياً كل بطاقة ومستند هوية وصورة، إلى جانب رمزك السري وإعداداتك. لا يمكن التراجع عن هذا، ولا يحتفظ Karde بأي نسخة في أي مكان.';

  @override
  String get backUpFirst => 'انسخ احتياطياً أولاً';

  @override
  String get settingsLockExplainer =>
      'تتحكم هذه الإعدادات في طريقة قفل Karde لنفسه. كما سيطلب منك هاتفك بصمتك أو قفل شاشتك في كل مرة تفتح فيها عنصراً، مهما كان اختيارك هنا.';

  @override
  String get settingsNoScreenLockWarning =>
      'لا يحتوي هذا الهاتف على قفل شاشة، لذا لا يستطيع Karde حفظ عناصرك أو فتحها. أضف رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، ثم عد إلى هنا.';

  @override
  String get passphraseTooShort => 'قصيرة جداً';

  @override
  String get passphraseWeak => 'ضعيفة';

  @override
  String get passphraseReasonable => 'مقبولة';

  @override
  String get passphraseStrong => 'قوية';

  @override
  String passphraseWeakHint(String label) {
    return '$label — الأطول أفضل بكثير من الأكثر تعقيداً';
  }

  @override
  String get passphraseChooseTitle => 'اختر عبارة مرور';

  @override
  String get passphraseEnterTitle => 'أدخل عبارة المرور';

  @override
  String get passphraseCreateExplainer =>
      'تشفّر عبارة المرور هذه ملف نسختك الاحتياطية. لا يحفظها Karde أبداً ولا يستطيع استرجاعها — وإذا نسيتها، ضاعت النسخة الاحتياطية.';

  @override
  String get passphraseUnlockExplainer =>
      'أدخل عبارة المرور التي اخترتها عند إنشاء هذه النسخة الاحتياطية.';

  @override
  String get passphraseFieldLabel => 'عبارة المرور';

  @override
  String get passphraseShow => 'إظهار عبارة المرور';

  @override
  String get passphraseHide => 'إخفاء عبارة المرور';

  @override
  String get passphraseRequired => 'أدخل عبارة مرور.';

  @override
  String passphraseMinimumLength(int count) {
    return 'استخدم $count أحرف على الأقل.';
  }

  @override
  String get passphraseConfirmLabel => 'تأكيد عبارة المرور';

  @override
  String get passphraseMismatch => 'الإدخالان غير متطابقين.';

  @override
  String get passphraseAdvice =>
      'بضع كلمات غير مترابطة أسهل في التذكّر وأصعب في التخمين من كلمة واحدة قصيرة ومعقّدة.';

  @override
  String get unlock => 'فتح';

  @override
  String get securityQuestionFirstPet => 'ما اسم أول حيوان أليف امتلكته؟';

  @override
  String get securityQuestionMothersMaidenName => 'ما اسم والدتك قبل الزواج؟';

  @override
  String get securityQuestionElementarySchool => 'ما اسم مدرستك الابتدائية؟';

  @override
  String get securityQuestionCityOfBirth => 'في أي مدينة وُلدت؟';

  @override
  String get securityQuestionFirstCar => 'ما ماركة سيارتك الأولى؟';

  @override
  String get securityQuestionFavouriteBook => 'ما كتابك المفضّل؟';

  @override
  String get chooseBothQuestions => 'اختر كلا السؤالين.';

  @override
  String get chooseTwoDifferentQuestions => 'اختر سؤالين مختلفين.';

  @override
  String get securityQuestionsUpdated => 'تم تحديث أسئلة الأمان.';

  @override
  String get changeSecurityQuestionsTitle => 'تغيير أسئلة الأمان';

  @override
  String get changeSecurityQuestionsSubtitle =>
      'تتيح لك هذه الأسئلة العودة إذا نسيت رمز Karde.';

  @override
  String get saveQuestions => 'حفظ الأسئلة';

  @override
  String get chooseAQuestion => 'اختر سؤالاً';

  @override
  String get securityAnswersHashNoteChanging =>
      'لا يمكن عرض إجاباتك الحالية. فهي محفوظة كبصمات أحادية الاتجاه، لذا لا يستطيع Karde قراءتها — بل استبدالها فقط. الحفظ يستبدل كلتيهما.';

  @override
  String get securityAnswersHashNoteNew =>
      'تُحفظ الإجابات كبصمات أحادية الاتجاه، فلا يستطيع أحد — ولا حتى Karde — قراءتها. لا يهمّ استخدام الأحرف الكبيرة أو المسافات.';

  @override
  String get alreadyUsedAbove => 'مستخدم بالفعل أعلاه';

  @override
  String get notesDecryptError => 'خطأ أثناء فك تشفير الملاحظات.';

  @override
  String get deleteCardTitle => 'حذف هذه البطاقة؟';

  @override
  String get deleteCardMessage =>
      'لا يمكن التراجع عن هذا. ستُحذف بيانات البطاقة نهائياً من الخزنة المشفّرة.';

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String get privateNotesAndPhoto => 'ملاحظات خاصة وصورة';

  @override
  String get cardMetadata => 'بيانات البطاقة';

  @override
  String get notesAndPhoto => 'الملاحظات والصورة';

  @override
  String get privateNotesTitle => 'ملاحظات خاصة';

  @override
  String get tapToUnlock => 'اضغط لفتح القفل';

  @override
  String get photoCouldNotBeDisplayed => 'تعذّر عرض هذه الصورة.';

  @override
  String get addedOn => 'أُضيف في';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get idOpenFailed => 'تعذّر فتح هذا المستند. حاول مرة أخرى.';

  @override
  String get deleteIdTitle => 'حذف هذه الهوية؟';

  @override
  String get deleteIdMessage =>
      'لا يمكن التراجع عن هذا. ستُحذف بيانات الهوية نهائياً من الخزنة المشفّرة.';

  @override
  String get additionalDetails => 'تفاصيل إضافية';

  @override
  String get detailsSection => 'التفاصيل';

  @override
  String get deleteId => 'حذف الهوية';

  @override
  String get documentDetails => 'تفاصيل المستند';

  @override
  String get noExtraDetails => 'لا يحتوي هذا المستند على تفاصيل إضافية.';

  @override
  String get dashboardLoadError => 'تعذّر تحميل عناصرك.';

  @override
  String get biometricChangeTitle => 'تغيّرت طريقة فتح الهاتف';

  @override
  String get biometricChangeMessage =>
      'تمت إضافة أو إزالة بصمة أو وجه على هذا الهاتف. إذا كنت أنت من فعل ذلك، فلا يوجد أي خطأ.';

  @override
  String get gotIt => 'حسناً';

  @override
  String get securityWarning => 'تحذير أمني';

  @override
  String get securityRisk => 'خطر أمني';

  @override
  String noBiometricsEnrolled(String details) {
    return 'لم يتم تسجيل أي بيانات حيوية. $details';
  }

  @override
  String missingSecureLockScreen(String details) {
    return 'لا يحتوي الجهاز على قفل شاشة آمن. $details';
  }

  @override
  String get authReasonRevealCard =>
      'يرجى التحقق من هويتك لعرض بيانات البطاقة الحساسة.';

  @override
  String get authReasonOpenKarde => 'يرجى التحقق من هويتك لفتح Karde.';

  @override
  String get authRequiredTitle => 'مطلوب التحقق من الهوية';

  @override
  String get useKardePin => 'استخدم رمز Karde';

  @override
  String get biometricsNotEnrolled =>
      'القياسات الحيوية غير مدعومة أو غير مسجّلة على هذا الجهاز.';

  @override
  String get biometricAuthFailedUsePin =>
      'فشل التحقق بالقياسات الحيوية. يرجى استخدام الرمز السري.';

  @override
  String get resetPinBiometricReason =>
      'امسح بصمتك (أو وجهك) لإعادة تعيين رمزك السري';

  @override
  String get verificationNotCompleted =>
      'لم يكتمل التحقق. حاول مرة أخرى، أو استخدم خيار استعادة آخر أدناه.';

  @override
  String get biometricVerificationUnavailable =>
      'التحقق بالقياسات الحيوية غير متاح حالياً. استخدم خيار استعادة آخر أدناه.';

  @override
  String get privacyPolicyHeading => 'سياسة الخصوصية لتطبيق Karde';

  @override
  String get privacyPolicyEffectiveDate => 'تاريخ السريان: سبتمبر 2026';

  @override
  String get privacySection1Title => '1. التخزين محلياً فقط';

  @override
  String get privacySection1Body =>
      'جميع بياناتك، بما فيها أرقام البطاقات ورموز CVV والملاحظات، مشفّرة ومخزَّنة محلياً على جهازك. نحن لا ننقل بياناتك ولا ننسخها احتياطياً ولا نخزّنها على أي خوادم خارجية أو خدمات سحابية. تبقى السيطرة الكاملة على بياناتك بين يديك.';

  @override
  String get privacySection2Title => '2. التشفير';

  @override
  String get privacySection2Body =>
      'بياناتك محمية بتشفير AES-256-GCM. تُنشأ مفاتيح التشفير وتُحفظ بشكل آمن داخل مخزن المفاتيح المدعوم بعتاد جهازك.';

  @override
  String get privacySection3Title => '3. التحقق من الهوية';

  @override
  String get privacySection3Body =>
      'للوصول إلى بياناتك الحساسة، يطلب Karde تحققاً محلياً عبر القياسات الحيوية في جهازك (بصمة الوجه أو الإصبع) أو عبر رمز Karde الخاص بك. لا يمكننا الوصول إلى رمزك السري ولا إلى بياناتك الحيوية.';

  @override
  String get privacySection4Title => '4. حذف البيانات';

  @override
  String get privacySection4Body =>
      'يمكنك حذف جميع بياناتك نهائياً في أي وقت باستخدام خاصية \"محو الخزنة\" في الإعدادات، أو بإلغاء تثبيت التطبيق. وبما أنه لا تُخزَّن أي بيانات في السحابة، فإن إلغاء التثبيت يعني حذف خزنتك نهائياً.';

  @override
  String get privacySection5Title => '5. الأذونات';

  @override
  String get privacySection5Body =>
      'لا يطلب التطبيق سوى الأذونات اللازمة لوظائفه الأساسية، مثل التحقق بالقياسات الحيوية. وهو لا يطلب الوصول إلى الإنترنت، ما يضمن استحالة نقل بياناتك.';

  @override
  String get privacySection6Title => '6. التغييرات على هذه السياسة';

  @override
  String get privacySection6Body =>
      'قد نحدّث هذه السياسة من حين لآخر. وستظهر أي تغييرات داخل التطبيق. وباستمرارك في استخدام التطبيق، فإنك توافق على السياسة المحدَّثة.';

  @override
  String get recoveryNoPinNote =>
      'لقد اخترت فتح Karde باستخدام قفل هاتفك، لذا لا يوجد بعد رمز Karde يمكن استعادته. وإعداد هذا الآن يعني وجود طريق للعودة جاهز إن أضفت رمزاً لاحقاً.\n\nوبشكل منفصل، وهو الأهم: عناصرك مشفّرة بمفتاح محفوظ في شريحة الأمان داخل هاتفك. وإذا أزلت قفل شاشة هاتفك أو أعدت ضبطه، فسيُدمَّر ذلك المفتاح ولن يستطيع أي شيء هنا استرجاع عناصرك. والنسخة الاحتياطية المشفّرة، من الإعدادات، هي الشيء الوحيد الذي ينجو من ذلك.';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get confirm => 'تأكيد';

  @override
  String get noScreenLockWarning =>
      'لا يحتوي هذا الهاتف على قفل شاشة.\n\nيحفظ Karde مفتاح التشفير الخاص بك في شريحة الأمان داخل الهاتف، وهذه الشريحة لا تحتفظ بأي مفتاح ما لم يكن الهاتف نفسه مقفلاً. وإلى أن تضبط رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، لن يستطيع Karde حفظ أي عنصر أو فتحه.\n\nيمكنك إكمال الإعداد الآن، ثم إضافة قفل شاشة والعودة.';

  @override
  String get backToLanguage => 'العودة إلى اللغة';

  @override
  String get imageNoSource =>
      'لا يوجد على هذا الجهاز أي تطبيق يمكنه توفير صورة.';

  @override
  String get imageUnreadable => 'تعذّرت قراءة هذه الصورة. جرّب صورة أخرى.';

  @override
  String get imageNotAvailable => 'إضافة الصور غير متاحة على هذا الجهاز.';

  @override
  String get photoCouldNotBeAdded => 'تعذّرت إضافة هذه الصورة. جرّب صورة أخرى.';

  @override
  String get tapToViewFullSize => 'اضغط للعرض بالحجم الكامل';

  @override
  String get replacePhoto => 'استبدال';

  @override
  String get removePhoto => 'إزالة';

  @override
  String get addAPhoto => 'إضافة صورة';

  @override
  String get takeAPhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'الاختيار من المعرض';

  @override
  String get photoClosesAutomatically => 'يُغلق تلقائياً. لقطات الشاشة محظورة.';

  @override
  String get unlockNeedsScreenLock => 'اضبط قفل شاشة على جهازك لفتح خزنتك.';

  @override
  String get itemNoLongerDecryptable =>
      'تغيّرت إعدادات الأمان في جهازك، لذا لم يعد بالإمكان فك تشفير هذا العنصر.';

  @override
  String get couldNotUnlockCard =>
      'تعذّر فتح هذه البطاقة. يرجى المحاولة مرة أخرى.';

  @override
  String get couldNotUnlockDocument =>
      'تعذّر فتح هذا المستند. يرجى المحاولة مرة أخرى.';

  @override
  String get cardNumberCopied =>
      'تم نسخ رقم البطاقة. ستُمسح الحافظة خلال 60 ثانية.';

  @override
  String pinLockedTryAgainIn(int seconds) {
    return 'محاولات فاشلة كثيرة. أعد المحاولة خلال $seconds ثانية.';
  }

  @override
  String get pinLockedOut => 'محاولات فاشلة كثيرة. تم القفل لمدة 30 ثانية.';

  @override
  String pinInvalidAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رمز غير صحيح. بقيت $count محاولة.',
      many: 'رمز غير صحيح. بقيت $count محاولة.',
      few: 'رمز غير صحيح. بقيت $count محاولات.',
      two: 'رمز غير صحيح. بقيت محاولتان.',
      one: 'رمز غير صحيح. بقيت محاولة واحدة.',
      zero: 'رمز غير صحيح. بقيت $count محاولة.',
    );
    return '$_temp0';
  }

  @override
  String pinDigitSemantic(String digit) {
    return 'رقم $digit من الرمز السري';
  }

  @override
  String get deleteLastDigit => 'حذف آخر رقم';

  @override
  String get vaultUpdatedWithNewPin =>
      'تم تحديث خزنتك الآمنة بالرمز السري الجديد.';

  @override
  String get creditCard => 'بطاقة ائتمان';

  @override
  String get cardholderPlaceholder => 'الاسم واللقب';

  @override
  String get privacySection7Title => '7. حافظ على قفل شاشتك';

  @override
  String get privacySection7Body =>
      'يوجد مفتاح التشفير الخاص بـ Karde داخل شريحة الأمان في هاتفك وهو مرتبط بقفل شاشتك. وإذا أزلت أو أعدت ضبط رمز هاتفك أو نقشه أو كلمة مروره أو بصمته، فسيُدمَّر ذلك المفتاح ولن يعود بالإمكان فتح عناصرك المحفوظة — لا من قبل أحد، بمن فينا نحن. والنسخة الاحتياطية المشفّرة هي الشيء الوحيد الذي ينجو من ذلك، لذا أنشئ واحدة قبل تغيير طريقة فتح هاتفك.';

  @override
  String get privacySection8Title => '8. التواصل';

  @override
  String get privacySection8Body =>
      'لأي أسئلة حول هذه السياسة أو أي نقطة غير واضحة: support@getgubae.com. السياسة الكاملة منشورة على getgubae.com/privacy.';
}
