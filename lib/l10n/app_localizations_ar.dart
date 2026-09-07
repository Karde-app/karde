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
  String get welcomeSubtitle => 'خزنتك الآمنة، دون اتصال بالإنترنت';

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
      other: '$count عناصر محفوظة بأمان',
      one: 'عنصر واحد محفوظ بأمان',
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
  String get setupLockTitle => 'أمّن خزنتك';

  @override
  String get setupLockSubtitle => 'كيف تريد فتح Karde؟';

  @override
  String get phoneLock => 'قفل الهاتف';

  @override
  String get phoneLockDesc => 'بصمة الوجه أو الإصبع أو رمز جهازك.';

  @override
  String get lockChoiceChangeableLater =>
      'يمكنك تغيير هذا الاختيار لاحقاً من الإعدادات.';

  @override
  String get kardePin => 'رمز Karde';

  @override
  String get kardePinDesc => 'أنشئ رمزاً سرياً خاصاً بهذا التطبيق.';

  @override
  String get bothLocks => 'كلاهما';

  @override
  String get bothLocksDesc =>
      'قفل هاتفك لفتح Karde، ورمز Karde للإجراءات الحسّاسة.';

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
  String get recoverySetupTitle => 'إذا نسيت رمز Karde السري';

  @override
  String get recoverySetupSubtitle =>
      'اختر طريقة إعادة تعيينه للعودة إلى Karde.';

  @override
  String get biometricRecovery => 'قفل الهاتف';

  @override
  String get biometricRecoveryDesc => 'بصمة الوجه أو الإصبع أو رمز جهازك.';

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
  String get appPinLock => 'رمز Karde السري';

  @override
  String get appPinLockDesc => 'طلبه عند فتح Karde وعند تغيير هذه الإعدادات';

  @override
  String get biometricUnlockTitle => 'قفل الهاتف';

  @override
  String get biometricUnlockDesc => 'افتح Karde ببصمتك أو وجهك أو قفل الشاشة';

  @override
  String get keepPinTitle => 'هل تريد الاحتفاظ برمز Karde السري؟';

  @override
  String get keepPinMessage =>
      'سيتوقف Karde عن طلبه في الحالتين. إن احتفظت به، فإعادة التشغيل لاحقاً تستخدم الرمز نفسه. وإن حذفته، فستختار رمزاً جديداً في المرة القادمة.';

  @override
  String get keepPinKeep => 'الاحتفاظ به';

  @override
  String get keepPinDelete => 'حذفه';

  @override
  String get pinDeleted => 'تم حذف رمز Karde السري.';

  @override
  String get changePin => 'تغيير رمز Karde';

  @override
  String get changePinDesc => 'اختر رمزاً سرياً جديداً لفتح Karde';

  @override
  String get createKardePinDesc => 'اختر رمزاً سرياً خاصاً بك لفتح Karde';

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
  String get noScreenLockTitle => 'هاتفك بلا قفل شاشة';

  @override
  String get noScreenLockBody =>
      'بدون قفل شاشة، لا يستطيع Karde فتح أي شيء أو حفظه. اضبط رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، ثم عد.';

  @override
  String get openPhoneSettings => 'فتح إعدادات الهاتف';

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
  String get pinCreatedSuccess => 'تم إنشاء رمز Karde السري';

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
  String get backupSetupTitle => 'الاحتفاظ بنسخة';

  @override
  String get backupSetupIntro =>
      'يحفظ Karde نسخة من كل ما تحتفظ به هنا، حتى تتمكن من استعادة كل شيء إذا فُقد هذا الهاتف أو تعطّل أو استبدلته. تذهب النسخة إلى المكان الذي تختاره. لا يُرسَل أي شيء إلى Karde أو إلى أي جهة أخرى.';

  @override
  String get backupSetupPassphraseTitle => 'اختر عبارة مرور';

  @override
  String get backupSetupPassphraseBody =>
      'ستحتاج إليها لاستعادة بياناتك على هاتف جديد. ولا يستطيع Karde إعادة تعيينها، فاكتبها واحفظها في مكان آمن.';

  @override
  String get backupSetupPassphraseDone => 'تم اختيار عبارة المرور';

  @override
  String get passphraseTooWeakForBackup =>
      'اختر عبارة مرور أطول، أو نوّع في الحروف قليلاً.';

  @override
  String get passphraseNeedsMixForBackup =>
      'استخدم أكثر من مجرد أرقام — أضف حروفاً أو بضع كلمات.';

  @override
  String get backupSetupFolderTitle => 'اختر مكان الحفظ';

  @override
  String get backupSetupFolderBody =>
      'اختر مجلداً على هاتفك. إذا اخترت مجلداً متزامناً مع التخزين السحابي، فستبقى نسختك سليمة حتى لو فقدت الهاتف.';

  @override
  String get backupSetupFolderAction => 'اختيار مجلد';

  @override
  String get backupSetupFinish => 'إنهاء';

  @override
  String get backupSetupLater => 'الإعداد لاحقاً';

  @override
  String get backupSetupLaterNote =>
      'لم يتمكن Karde من فتح أداة اختيار المجلدات على هذا الهاتف. يمكنك المتابعة وإعداد النسخ الاحتياطي من الإعدادات، لكن لن يُنسخ أي شيء تحفظه حتى تفعل ذلك.';

  @override
  String get backupSetupWorking => 'يجري إعداد نسختك الاحتياطية…';

  @override
  String get backupSetupDoneTitle => 'نسختك الاحتياطية تعمل';

  @override
  String backupSetupDoneBody(String folder) {
    return 'يحفظ Karde نسخة في كل مرة تضيف فيها شيئاً أو تغيّره أو تحذفه. وتذهب إلى $folder.';
  }

  @override
  String get backupSetupFolderFailed =>
      'لم يتمكن Karde من الحفظ في ذلك المجلد. اختر مجلداً آخر من فضلك.';

  @override
  String get backupSelfTestFailed =>
      'لم يتمكن هذا الهاتف من قراءة النسخة التي حفظها للتو، لذلك لم يفعّل Karde النسخ الاحتياطي. حاول مرة أخرى من فضلك.';

  @override
  String get backupUpdated => 'تم تحديث النسخة الاحتياطية.';

  @override
  String get backupFailedTitle => 'لا يتم حفظ نسختك الاحتياطية';

  @override
  String get alertsTitle => 'يحتاج انتباهك';

  @override
  String get alertsTitleCalm => 'كل شيء على ما يرام';

  @override
  String get alertsNone => 'لا شيء يحتاج انتباهك.';

  @override
  String get alertsNoneBody =>
      'سيخبرك Karde هنا إذا كان هناك ما يستدعي المراجعة.';

  @override
  String get alertsFix => 'إصلاح';

  @override
  String get alertsSetUp => 'إعداد';

  @override
  String get alertsGotIt => 'حسناً';

  @override
  String get backupNotSavingShort =>
      'لا يتم نسخ التغييرات الجديدة إلى مجلد النسخ الاحتياطي.';

  @override
  String backupFailedBody(String folder) {
    return 'لم يتمكن Karde من الحفظ في $folder. ربما نُقل المجلد أو أُعيدت تسميته أو حُذف. وإلى أن يُحل هذا، لا تُنسخ التغييرات الجديدة في أي مكان.';
  }

  @override
  String get backupFailedAction => 'اختيار مجلد';

  @override
  String settingsAutoBackupNote(String folder) {
    return 'يحفظ Karde نسخة في كل مرة تضيف فيها شيئاً أو تغيّره أو تحذفه. وتذهب إلى $folder. ويمكنك أيضاً حفظ نسخة بنفسك في أي وقت.';
  }

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
      'لم يعد بالإمكان فتح العناصر الموجودة على هذا الهاتف. أما الاستعادة من نسخة احتياطية فما زالت تعمل.';

  @override
  String get backupExplainerPassphrase =>
      'نسختك الاحتياطية مقفلة بعبارة مرور تختارها. ولا يستطيع Karde استرجاعها، فاحفظها في مكان آمن.';

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
      'احفظ ملف النسخة الاحتياطية في مكان تثق به. فمن يملك الملف وعبارة المرور يستطيع فتحه.';

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
      'لا يستطيع Karde حفظ أي شيء أو فتحه ما لم يكن لهذا الهاتف قفل شاشة.\n\nأضف رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، ثم عد.';

  @override
  String get vaultKeyChangedItemsLost =>
      'تغيّرت إعدادات الأمان في هاتفك، ولم يعد بالإمكان فتح العناصر المحفوظة هنا. ولا يمكن استعادتها.';

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
  String get cardAddedSecurely => 'تمت إضافة البطاقة بأمان.';

  @override
  String get cardUpdatedSecurely => 'تم تحديث البطاقة بأمان.';

  @override
  String get cardRemoved => 'تم حذف البطاقة.';

  @override
  String get idRemoved => 'تم حذف وثيقة الهوية.';

  @override
  String andBackedUp(String message) {
    return '$message تم تحديث النسخة الاحتياطية.';
  }

  @override
  String savedButNotBackedUp(String message) {
    return '$message لم يتم نسخها بعد إلى مجلد النسخ الاحتياطي.';
  }

  @override
  String get setUpBackupTitle => 'لا توجد نسخة احتياطية';

  @override
  String get setUpBackupBody =>
      'يمكن لـ Karde الاحتفاظ بنسخة من كل شيء، حتى لا يضيع شيء مع هذا الهاتف.';

  @override
  String get setUpBackupAction => 'إعداد';

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
      'تعذّر فتح هذا المستند، لذا لا تظهر تفاصيله والحفظ معطّل. ارجع وحاول مرة أخرى.';

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
  String get settingsSecurityQuestions => 'تغيير أسئلة الأمان';

  @override
  String get settingsSecurityQuestionsAdd => 'إضافة أسئلة الأمان';

  @override
  String get settingsSecurityQuestionsDesc =>
      'غيّر الأسئلة المستخدمة لاستعادة رمزك السري';

  @override
  String get settingsSecurityQuestionsAddDesc =>
      'أضف أسئلة تتيح لك إعادة تعيين رمزك السري في Karde';

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
    return '$name v$version\n\nخزنة تعمل دون اتصال بالإنترنت، للبطاقات والمستندات التي تفضّل ألا تحملها معك.\n\nكل ما تحفظه مشفّر على هذا الهاتف ويُفتح ببصمتك. لا يملك Karde حساباً ولا وصولاً إلى الإنترنت، لذا لا يمكن لأي شيء تخزّنه أن يغادر جهازك — لا إلينا ولا إلى أي جهة أخرى.\n\nولأنه لا يُحفظ شيء في أي مكان آخر، فإن النسخة الاحتياطية المشفّرة هي الطريقة الوحيدة لنقل خزنتك إلى هاتف جديد.';
  }

  @override
  String get eraseEverythingTitle => 'محو كل شيء؟';

  @override
  String get eraseEverythingMessage =>
      'ستُحذف نهائياً كل بطاقة ومستند هوية وصورة، إلى جانب رمزك السري وإعداداتك. لا يمكن التراجع عن هذا، ولا يحتفظ Karde بأي نسخة في أي مكان.';

  @override
  String get backUpFirst => 'انسخ احتياطياً أولاً';

  @override
  String get settingsLockExplainer =>
      'سيطلب منك هاتفك أيضاً بصمتك أو قفل الشاشة كلما فتحت عنصراً.';

  @override
  String get settingsNoScreenLockWarning =>
      'لا يوجد قفل شاشة على هذا الهاتف، لذا لا يستطيع Karde حفظ عناصرك أو فتحها. أضف رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك، ثم عد.';

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
      'إذا نسيتها، لن يمكن فتح النسخة الاحتياطية. ولا يستطيع Karde إعادة تعيينها.';

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
  String get securityQuestionsSaved => 'تم حفظ أسئلة الأمان.';

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
      'لا يمكن إظهار إجاباتك الحالية، بل استبدالها فقط. والحفظ يستبدل كلتيهما.';

  @override
  String get securityAnswersHashNoteNew =>
      'لا فرق بين الأحرف الكبيرة والصغيرة ولا في المسافات.';

  @override
  String get alreadyUsedAbove => 'مستخدم بالفعل أعلاه';

  @override
  String get notesDecryptError => 'خطأ أثناء فك تشفير الملاحظات.';

  @override
  String get deleteCardTitle => 'حذف هذه البطاقة؟';

  @override
  String get deleteCardMessage =>
      'لا يمكن التراجع عن هذا. ستُحذف البطاقة نهائياً.';

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
      'لا يمكن التراجع عن هذا. سيُحذف المستند نهائياً.';

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
  String get biometricLockedOut =>
      'أوقف هاتفك مؤقتاً فتح القفل بالبصمة بعد محاولات كثيرة. انتظر قليلاً أو استخدم قفل الشاشة.';

  @override
  String get biometricUnavailableNow =>
      'لم يتمكن هاتفك من التحقق من بصمتك الآن.';

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
      'اخترت فتح Karde بقفل هاتفك، فلا يوجد بعد رمز Karde لاستعادته. وإعداد هذا الآن يعني أن طريق العودة جاهز إن أضفت رمزاً لاحقاً.';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get confirm => 'تأكيد';

  @override
  String get noScreenLockWarning =>
      'لا يوجد قفل شاشة على هذا الهاتف، لذا لا يستطيع Karde حفظ أي عناصر أو فتحها.\n\nأضف رمزاً أو نقشاً أو كلمة مرور أو بصمة في إعدادات هاتفك.\n\nيمكنك إكمال الإعداد الآن والعودة إلى ذلك لاحقاً.';

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
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'رمز غير صحيح. أعد المحاولة بعد $seconds ثانية.',
      one: 'رمز غير صحيح. أعد المحاولة بعد ثانية واحدة.',
    );
    return '$_temp0';
  }

  @override
  String pinLockedTryAgainInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'رمز غير صحيح. أعد المحاولة بعد $minutes دقيقة.',
      one: 'رمز غير صحيح. أعد المحاولة بعد دقيقة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get pinInvalid => 'رمز غير صحيح.';

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
  String get vaultReadyWithNewPin => 'يمكنك الآن فتح Karde بهذا الرمز.';

  @override
  String get creditCard => 'بطاقة ائتمان';

  @override
  String get cardholderPlaceholder => 'الاسم واللقب';

  @override
  String get privacySection7Title => '7. حافظ على قفل شاشتك';

  @override
  String get privacySection7Body =>
      'يوجد مفتاح التشفير الخاص بـ Karde في شريحة الأمان داخل هاتفك، وهو لا يبقى إلا ما دام لهاتفك قفل شاشة. تغيير رمزك أو نقشك أو كلمة مرورك أو بصماتك آمن — وتبقى عناصرك المحفوظة قابلة للقراءة. لكن إذا أوقفت قفل الشاشة تماماً، فسيُدمَّر ذلك المفتاح ولن يتمكن أحد من فتح عناصرك، بمن فينا نحن. والنسخة الاحتياطية المشفّرة هي الشيء الوحيد الذي ينجو من ذلك، لذا أنشئ واحدة قبل إزالة قفل شاشتك.';

  @override
  String get privacySection8Title => '8. التواصل';

  @override
  String get privacySection8Body =>
      'لأي أسئلة حول هذه السياسة أو أي نقطة غير واضحة: support@getgubae.com.';

  @override
  String get biometricCouldNotConfirm =>
      'تعذّر التأكد من هويتك. حاول مرة أخرى.';

  @override
  String get noBackupTitle => 'لا توجد نسخة احتياطية';

  @override
  String get noBackupShort =>
      'لا توجد نسخة احتياطية — كل شيء موجود على هذا الهاتف فقط.';

  @override
  String get noBackupBody =>
      'كل ما حفظته موجود على هذا الهاتف فقط. تتيح لك النسخة الاحتياطية استعادة كل شيء على هاتف جديد.';

  @override
  String get copyLabel => 'نسخ';

  @override
  String get passphraseSectionTitle => 'عبارة المرور لنسختك الاحتياطية';

  @override
  String get passphraseSectionBody =>
      'هي الشيء الوحيد الذي يفتح نسختك الاحتياطية على هاتف جديد. ولا يستطيع Karde إعادة تعيينها لك.';

  @override
  String get passphraseShowTitle => 'إظهار عبارة المرور';

  @override
  String get passphraseShowBody => 'افتح القفل ببصمتك أو بقفل الشاشة لرؤيتها.';

  @override
  String get passphraseSaveTitle => 'الاحتفاظ بعبارة المرور على هذا الهاتف';

  @override
  String get passphraseSaveBody =>
      'عندها يمكنك مراجعتها هنا كلما لم تكن متأكدًا.';

  @override
  String get passphraseChangeTitle => 'تغيير عبارة المرور';

  @override
  String get passphraseChangeBody => 'ستحتاج إلى كتابة العبارة الحالية أولًا.';

  @override
  String get passphraseChangeWarning =>
      'تنتقل نسختك الاحتياطية إلى عبارة المرور الجديدة على الفور. أما النسخ المؤرخة من الأيام السابقة فتبقى مقفلة بالعبارة القديمة، فاحتفظ بها ما دمت تحتاج إليها.';

  @override
  String get passphraseChanged => 'تم تغيير عبارة المرور لنسختك الاحتياطية.';

  @override
  String get passphraseUnchanged => 'هذه هي عبارة المرور التي لديك بالفعل.';

  @override
  String get passphraseNotOnThisPhone =>
      'لم تعد لدى Karde نسخة من عبارة المرور على هذا الهاتف.';

  @override
  String get passphraseCouldNotSave =>
      'تعذّر على Karde الاحتفاظ بنسخة على هذا الهاتف. أما نسختك الاحتياطية نفسها فبخير.';

  @override
  String get passphraseSavedOnPhone =>
      'تم الحفظ. يمكنك مراجعتها من هذه الشاشة وقتما تشاء.';

  @override
  String get passphraseRevealTitle => 'عبارة المرور لنسختك الاحتياطية';

  @override
  String get passphraseRevealWarning =>
      'دوّنها في مكان غير هذا الهاتف، أو احفظها في مدير كلمات مرور. فإذا ضاع الهاتف ضاعت معه هذه النسخة.';

  @override
  String get passphraseCopied =>
      'تم نسخ عبارة المرور. ستُمسح الحافظة خلال 60 ثانية.';

  @override
  String get passphraseReuseTitle => 'هل تستخدم عبارة مرور نسختك الاحتياطية؟';

  @override
  String get passphraseReuseMessage =>
      'يمكن لـ Karde قفل هذا الملف بعبارة المرور نفسها التي تستخدمها نسختك الاحتياطية التلقائية، فتكون لديك عبارة واحدة فقط لتتذكرها.';

  @override
  String get passphraseReuseConfirm => 'استخدامها';

  @override
  String get passphraseReuseAlternative => 'كتابة عبارة أخرى';

  @override
  String get backupIncompleteTitle => 'تنقص نسختك الاحتياطية بعض العناصر';

  @override
  String backupIncompleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'هناك $count عناصر ليست في نسختك الاحتياطية بعد.',
      one: 'هناك عنصر واحد ليس في نسختك الاحتياطية بعد.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingTitle => 'انسخ ما لديك بالفعل';

  @override
  String backupCopyExistingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توجد $count عناصر في خزنتك وليست في نسختك الاحتياطية.',
      one: 'يوجد عنصر واحد في خزنتك وليس في نسختك الاحتياطية.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingAction => 'انسخها الآن';

  @override
  String backupCopyConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نسخ $count عناصر',
      one: 'نسخ عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyConfirmMessage =>
      'سيطلب منك هاتفك تأكيد هويتك مرة واحدة لكل عنصر. أما ما تحفظه بعد ذلك فيُنسخ دون أن يطلب منك شيئاً.';

  @override
  String get backupCopying => 'جارٍ النسخ إلى نسختك الاحتياطية…';

  @override
  String backupCopyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت إضافة $count عناصر إلى نسختك الاحتياطية.',
      one: 'تمت إضافة عنصر واحد إلى نسختك الاحتياطية.',
    );
    return '$_temp0';
  }

  @override
  String expiryCardSoon(String when) {
    return 'تنتهي صلاحية هذه البطاقة في $when.';
  }

  @override
  String expiryCardPast(String when) {
    return 'انتهت صلاحية هذه البطاقة في $when.';
  }

  @override
  String expiryDocumentSoon(String when) {
    return 'تنتهي صلاحية هذا المستند في $when.';
  }

  @override
  String expiryDocumentPast(String when) {
    return 'انتهت صلاحية هذا المستند في $when.';
  }

  @override
  String get settingsExpiryReminders => 'تنبيهات انتهاء الصلاحية';

  @override
  String get settingsExpiryRemindersDesc =>
      'نبّهني قبل انتهاء صلاحية بطاقة أو مستند';

  @override
  String get notifyExpiringTitle => 'شيء في Karde أوشك على الانتهاء';

  @override
  String notifyExpiringBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'تنتهي صلاحية $count بطاقات أو مستندات قريباً. افتح Karde لمعرفة أيها.',
      one: 'تنتهي صلاحية بطاقة أو مستند واحد قريباً. افتح Karde لمعرفة أيها.',
    );
    return '$_temp0';
  }

  @override
  String get notifyExpiredTitle => 'شيء في Karde انتهت صلاحيته';

  @override
  String notifyExpiredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انتهت صلاحية $count بطاقات أو مستندات. افتح Karde لمعرفة أيها.',
      one: 'انتهت صلاحية بطاقة أو مستند واحد. افتح Karde لمعرفة أيها.',
    );
    return '$_temp0';
  }

  @override
  String get settingsExpiryNotifyBlocked =>
      'لا يستطيع Karde إرسال التنبيهات ما لم تسمح له بالإشعارات في إعدادات هاتفك.';

  @override
  String get settingsAutoBackupTitle => 'النسخ الاحتياطي التلقائي';

  @override
  String get settingsAutoBackupDesc => 'الاحتفاظ بنسخة محدَّثة عند كل تغيير';

  @override
  String get settingsAutoBackupOffTitle => 'إيقاف النسخ الاحتياطي التلقائي؟';

  @override
  String get settingsAutoBackupOffMessage =>
      'سيتوقف Karde عن تحديث نسختك الاحتياطية. أما الملف الموجود في مجلدك فيبقى كما هو تماماً — ولا يُحذف شيء.';

  @override
  String get settingsAutoBackupOffConfirm => 'إيقاف';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get activityTitle => 'النشاط الأخير';

  @override
  String get activityEmpty =>
      'لا شيء بعد. ستظهر هنا عمليات إضافة بطاقة أو مستند أو تغييرهما أو حذفهما.';

  @override
  String get activityClear => 'مسح';

  @override
  String activityCardAdded(String name) {
    return 'أضفت البطاقة $name';
  }

  @override
  String activityCardChanged(String name) {
    return 'غيّرت البطاقة $name';
  }

  @override
  String activityCardRemoved(String name) {
    return 'حذفت البطاقة $name';
  }

  @override
  String activityDocumentAdded(String name) {
    return 'أضفت المستند $name';
  }

  @override
  String activityDocumentChanged(String name) {
    return 'غيّرت المستند $name';
  }

  @override
  String activityDocumentRemoved(String name) {
    return 'حذفت المستند $name';
  }

  @override
  String get cameraTitle => 'التقاط صورة';

  @override
  String get cameraGuideHint => 'حاذِ البطاقة أو المستند داخل الإطار';

  @override
  String get cameraRetake => 'إعادة الالتقاط';

  @override
  String get cameraUsePhoto => 'استخدام هذه الصورة';

  @override
  String get cameraCaptureFailed =>
      'تعذّر التقاط هذه الصورة. يرجى المحاولة مرة أخرى.';

  @override
  String get cameraUnavailable =>
      'ليس لدى Karde إذن باستخدام الكاميرا. يمكنك التقاط الصورة بتطبيق الكاميرا في هاتفك بدلاً من ذلك.';

  @override
  String get cameraUsePhoneCamera => 'استخدام كاميرا الهاتف';
}
