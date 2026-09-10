// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Karde';

  @override
  String get welcomeTitle => 'Bienvenue sur Karde';

  @override
  String get welcomeSubtitle => 'Votre coffre sécurisé, hors ligne';

  @override
  String get offlineBadge => 'Hors ligne & Chiffré';

  @override
  String get quickAccess => 'Accès Rapide';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get addACard => 'Ajouter une carte';

  @override
  String get openVault => 'Ouvrir le coffre';

  @override
  String get vaultHealthExcellent => 'Santé du coffre : excellente';

  @override
  String vaultHealthItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments, bien protégés',
      one: '1 élément, bien protégé',
    );
    return '$_temp0';
  }

  @override
  String get homeTab => 'Accueil';

  @override
  String get vaultTab => 'Coffre';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get myVault => 'Mon Coffre';

  @override
  String get allFilter => 'Tout';

  @override
  String get cardsFilter => 'Cartes';

  @override
  String get idsFilter => 'Pièces d\'identité';

  @override
  String get addNewCard => 'Ajouter';

  @override
  String get identification => 'IDENTIFICATION';

  @override
  String get issuerLabel => 'ÉMETTEUR';

  @override
  String get issuerHint => 'ex. Nom de la banque';

  @override
  String get cardNetworkLabel => 'Réseau de carte';

  @override
  String get cardholderNameLabel => 'NOM DU TITULAIRE';

  @override
  String get cardholderNameHint => 'Nom sur la carte';

  @override
  String get cardDetails => 'DÉTAILS';

  @override
  String get cardNumberLabel => 'NUMÉRO';

  @override
  String get cardNumberHint => '0000 0000 0000 0000';

  @override
  String get expiryLabel => 'EXPIRATION';

  @override
  String get expiryHint => 'MM/AA';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get cvvHint => '123';

  @override
  String get extraInfo => 'INFOS SUPPLÉMENTAIRES';

  @override
  String get privateNotesLabel => 'NOTES PRIVÉES';

  @override
  String get privateNotesHint => 'Numéros, indices PIN...';

  @override
  String get saveItem => 'Enregistrer';

  @override
  String get requiredField => 'Requis';

  @override
  String get invalidFormat => 'Format invalide';

  @override
  String get cardDetailsTitle => 'Détails de la carte';

  @override
  String get editDetails => 'Modifier';

  @override
  String get deleteCard => 'Supprimer';

  @override
  String get language => 'Langue';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get setupLockTitle => 'Sécurisez votre coffre';

  @override
  String get setupLockSubtitle => 'Comment souhaitez-vous ouvrir Karde ?';

  @override
  String get phoneLock => 'Verrouillage du téléphone';

  @override
  String get phoneLockDesc => 'Face ID, Touch ID ou le code de votre appareil.';

  @override
  String get lockChoiceChangeableLater =>
      'Vous pourrez modifier ce choix plus tard dans les Réglages.';

  @override
  String get kardePin => 'Code Karde';

  @override
  String get kardePinDesc => 'Créez un code PIN dédié.';

  @override
  String get bothLocks => 'Les deux';

  @override
  String get bothLocksDesc =>
      'Le verrouillage du téléphone pour ouvrir Karde, et un code Karde pour les actions sensibles.';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get createPin => 'Créer le code';

  @override
  String get enterPin => 'Entrez votre nouveau code';

  @override
  String get confirmPin => 'Confirmer le code';

  @override
  String get reEnterPin => 'Veuillez saisir à nouveau';

  @override
  String get pinMismatch => 'Les codes ne correspondent pas.';

  @override
  String get enterKardePin => 'Entrez le code Karde';

  @override
  String get unlockToReveal => 'Déverrouillez pour révéler';

  @override
  String get recoverySetupTitle => 'Si vous oubliez votre code PIN Karde';

  @override
  String get recoverySetupSubtitle =>
      'Choisissez comment le réinitialiser pour revenir dans Karde.';

  @override
  String get biometricRecovery => 'Verrouillage du téléphone';

  @override
  String get biometricRecoveryDesc =>
      'Face ID, Touch ID ou le code de votre appareil.';

  @override
  String get securityQuestions => 'Questions de sécurité';

  @override
  String get securityQuestionsDesc =>
      'Répondez à 2 questions pour réinitialiser votre code PIN.';

  @override
  String get noRecovery => 'Aucune récupération';

  @override
  String get noRecoveryDesc =>
      'Sécurité maximale. Oublier votre code PIN entraîne une perte de données permanente.';

  @override
  String get setupQuestionsTitle => 'Définir les questions de sécurité';

  @override
  String get setupQuestionsSubtitle => 'Choisissez 2 questions et réponses';

  @override
  String get question1 => 'Question 1';

  @override
  String get question2 => 'Question 2';

  @override
  String get answer => 'Réponse';

  @override
  String get answerRequired => 'La réponse est requise';

  @override
  String get finishSetup => 'Terminer la configuration';

  @override
  String get forgotPin => 'Code PIN oublié ?';

  @override
  String get resetPinTitle => 'Réinitialiser le code PIN';

  @override
  String get resetPinSubtitle => 'Choisissez une méthode de récupération';

  @override
  String get wipeDataBtn => 'Effacer les données (Danger)';

  @override
  String get wipeDataWarning =>
      'Cela supprimera définitivement toutes vos cartes et réinitialisera l\'application. Êtes-vous sûr ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get wipe => 'Effacer';

  @override
  String get verifyQuestionsTitle => 'Répondre aux questions';

  @override
  String get verifyQuestionsSubtitle =>
      'Répondez aux deux questions pour réinitialiser votre code PIN';

  @override
  String get verifyBtn => 'Vérifier';

  @override
  String get wrongAnswers => 'L\'une ou les deux réponses sont incorrectes.';

  @override
  String get resetPinSuccess =>
      'Vérification réussie. Vous pouvez maintenant définir un nouveau code PIN.';

  @override
  String get appearance => 'APPARENCE';

  @override
  String get theme => 'Thème';

  @override
  String get themeDesc => 'Système, Clair ou Sombre';

  @override
  String get appDisplayLanguage => 'Langue d\'affichage de l\'application';

  @override
  String get privacy => 'CONFIDENTIALITÉ';

  @override
  String get autoHide => 'Masquer automatiquement les détails sensibles';

  @override
  String get autoHideDesc =>
      'Masquer le numéro de carte et le CVV automatiquement';

  @override
  String get security => 'SÉCURITÉ';

  @override
  String get appPinLock => 'Code PIN Karde';

  @override
  String get appPinLockDesc =>
      'Le demander à l\'ouverture de Karde et pour modifier ces réglages';

  @override
  String get biometricUnlockTitle => 'Verrouillage du téléphone';

  @override
  String get biometricUnlockDesc =>
      'Ouvrir Karde avec votre empreinte, votre visage ou le verrouillage de l\'écran';

  @override
  String get keepPinTitle => 'Conserver votre code PIN Karde ?';

  @override
  String get keepPinMessage =>
      'Karde cessera de le demander dans les deux cas. Conservez-le, et le réactiver plus tard utilisera le même code. Supprimez-le, et vous en choisirez un nouveau la prochaine fois.';

  @override
  String get keepPinKeep => 'Le conserver';

  @override
  String get keepPinDelete => 'Le supprimer';

  @override
  String get pinDeleted => 'Votre code PIN Karde a été supprimé.';

  @override
  String get changePin => 'Modifier le code PIN';

  @override
  String get changePinDesc => 'Choisir un nouveau code PIN pour ouvrir Karde';

  @override
  String get createKardePinDesc =>
      'Définir un code PIN qui vous est propre pour ouvrir Karde';

  @override
  String get about => 'À PROPOS';

  @override
  String get aboutKarde => 'À propos de Karde';

  @override
  String get aboutKardeDesc => 'Version, crédits & licences';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyDesc => 'Comment vos données restent sur l\'appareil';

  @override
  String get mustKeepOneLock =>
      'Vous devez conserver au moins une méthode de verrouillage activée.';

  @override
  String get biometricsNotSupported =>
      'La biométrie n\'est pas prise en charge sur cet appareil.';

  @override
  String get biometricsError =>
      'Erreur lors de la vérification du support biométrique.';

  @override
  String get invalidCardLength => 'Longueur de carte invalide';

  @override
  String get invalidCardNumber => 'Numéro de carte invalide';

  @override
  String get invalidExpiryFormat => 'Le format doit être MM/AA';

  @override
  String get invalidMonth => 'Mois invalide';

  @override
  String get cardExpired => 'La carte a expiré';

  @override
  String get invalidCvvLength => 'Le CVV doit comporter 3 ou 4 chiffres';

  @override
  String get numbersOnly => 'Chiffres uniquement';

  @override
  String get numbersNotAllowed => 'Les chiffres ne sont pas autorisés';

  @override
  String get symbolsNotAllowed => 'Les symboles ne sont pas autorisés';

  @override
  String get kardeIsLocked => 'Karde est verrouillé';

  @override
  String get noScreenLockTitle =>
      'Votre téléphone n’a aucun verrouillage d’écran';

  @override
  String get noScreenLockBody =>
      'Sans verrouillage d\'écran, Karde ne peut rien ouvrir ni enregistrer. Définissez un code, un schéma, un mot de passe ou une empreinte dans les réglages de votre téléphone, puis revenez.';

  @override
  String get openPhoneSettings => 'Ouvrir les réglages du téléphone';

  @override
  String get authenticateToAccess =>
      'Authentifiez-vous pour accéder à votre coffre.';

  @override
  String get authenticating => 'Authentification…';

  @override
  String get unlockKarde => 'Déverrouiller Karde';

  @override
  String get exitApp => 'Quitter l\'application';

  @override
  String get enterCurrentPin => 'Saisissez votre code Karde actuel';

  @override
  String get createKardePin => 'Créer un code Karde';

  @override
  String get pinChangedSuccess => 'Code modifié avec succès';

  @override
  String get pinCreatedSuccess => 'Code PIN Karde créé';

  @override
  String get done => 'Terminé';

  @override
  String get addAnId => 'Ajouter une pièce d\'identité';

  @override
  String get idDetails => 'Détails du document';

  @override
  String get documentType => 'Type de document';

  @override
  String get documentNumber => 'Numéro du document';

  @override
  String get fullName => 'Nom complet';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get sexGender => 'Sexe / Genre';

  @override
  String get issuingAuthority => 'Pays / autorité de délivrance';

  @override
  String get issueDate => 'Date de délivrance';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get placeOfBirth => 'Lieu de naissance';

  @override
  String get personalId => 'Identifiant personnel';

  @override
  String get bloodGroup => 'Groupe sanguin';

  @override
  String get tabAll => 'Tout';

  @override
  String get tabCards => 'Cartes';

  @override
  String get tabIds => 'Documents';

  @override
  String get idCardNotAvailable => 'N/D';

  @override
  String get idCardPassportTitle => 'PASSEPORT INTERNATIONAL';

  @override
  String get idCardType => 'TYPE';

  @override
  String get idCardCodeOfIssuingState => 'CODE DE L\'ÉTAT ÉMETTEUR';

  @override
  String get idCardPassportNo => 'N° DE PASSEPORT';

  @override
  String get idCardSurname => 'NOM';

  @override
  String get idCardGivenNames => 'PRÉNOMS';

  @override
  String get idCardNationalityUpper => 'NATIONALITÉ';

  @override
  String get idCardDobUpper => 'DATE DE NAISSANCE';

  @override
  String get idCardSexUpper => 'SEXE';

  @override
  String get idCardPlaceOfBirthUpper => 'LIEU DE NAISSANCE';

  @override
  String get idCardAuthorityUpper => 'AUTORITÉ';

  @override
  String get idCardDateOfIssueUpper => 'DATE DE DÉLIVRANCE';

  @override
  String get idCardDateOfExpiryUpper => 'DATE D\'EXPIRATION';

  @override
  String get idCardHoldersSignature => 'SIGNATURE DU TITULAIRE';

  @override
  String get idCardResidencePermitTitle => 'TITRE DE SÉJOUR BIOMÉTRIQUE';

  @override
  String get idCardName => 'Nom';

  @override
  String get idCardGender => 'Genre';

  @override
  String get idCardNationality => 'Nationalité';

  @override
  String get idCardDocumentNo => 'N° du document';

  @override
  String get idCardNationalFallback => 'NATIONAL';

  @override
  String get idCardIdCard => 'CARTE D\'IDENTITÉ';

  @override
  String get idCardNationalIdLogo => 'Identité nationale';

  @override
  String get idCardEthiopianDigitalId =>
      'Carte d\'identité numérique éthiopienne';

  @override
  String get idCardEthiopianFullName => 'Prénom, second prénom, nom';

  @override
  String get idCardFullNameUpper => 'NOM COMPLET';

  @override
  String get idCardDateOfExpiry => 'Date d\'expiration';

  @override
  String get idCardCountryOfCitizenship => 'Pays de citoyenneté (auto-déclaré)';

  @override
  String get idCardIssuingAuthorityUpper => 'AUTORITÉ DE DÉLIVRANCE';

  @override
  String get idCardIdNo => 'N° D\'IDENTITÉ';

  @override
  String get idCardDrivingLicenceTitle => 'PERMIS DE CONDUIRE';

  @override
  String get idCardNameUpper => 'NOM';

  @override
  String get idCardPassportNoShort => 'N° passeport';

  @override
  String get idCardDlNo => 'N° permis';

  @override
  String get idCardDocNo => 'N° doc';

  @override
  String get idCardDocumentFallback => 'DOCUMENT';

  @override
  String get idCardDocumentHolder => 'TITULAIRE DU DOCUMENT';

  @override
  String get idCardDocumentNumberUpper => 'NUMÉRO DU DOCUMENT';

  @override
  String get idCardValidFrom => 'VALABLE À PARTIR DU';

  @override
  String get idCardExpires => 'EXPIRE LE';

  @override
  String get genericError => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get backupTitle => 'Sauvegarde et restauration';

  @override
  String get backupSetupTitle => 'Garder une copie';

  @override
  String get backupSetupIntro =>
      'Karde enregistre une copie de tout ce que vous conservez ici, afin que vous puissiez tout récupérer si ce téléphone est perdu, cassé ou remplacé. La copie va là où vous le choisissez. Rien n\'est jamais envoyé à Karde ni à qui que ce soit.';

  @override
  String get backupSetupPassphraseTitle => 'Choisissez une phrase secrète';

  @override
  String get backupSetupPassphraseBody =>
      'Vous en aurez besoin pour récupérer vos données sur un nouveau téléphone. Karde ne peut pas la réinitialiser : notez-la et gardez-la en lieu sûr.';

  @override
  String get backupSetupPassphraseDone => 'Phrase secrète choisie';

  @override
  String get passphraseTooWeakForBackup =>
      'Choisissez une phrase secrète plus longue, ou variez un peu les caractères.';

  @override
  String get passphraseNeedsMixForBackup =>
      'Utilisez autre chose que des chiffres — ajoutez des lettres ou quelques mots.';

  @override
  String get backupSetupFolderTitle => 'Choisissez l\'emplacement';

  @override
  String get backupSetupFolderBody =>
      'Choisissez un dossier sur votre téléphone. Si vous en choisissez un synchronisé avec le cloud, votre copie survivra aussi à la perte du téléphone.';

  @override
  String get backupSetupFolderAction => 'Choisir un dossier';

  @override
  String get backupSetupFinish => 'Terminer';

  @override
  String get backupSetupLater => 'Configurer plus tard';

  @override
  String get backupSetupLaterNote =>
      'Karde n\'a pas pu ouvrir de sélecteur de dossier sur ce téléphone. Vous pouvez continuer et configurer votre sauvegarde depuis les Réglages, mais rien de ce que vous enregistrez ne sera copié tant que ce ne sera pas fait.';

  @override
  String get backupSetupWorking => 'Configuration de votre sauvegarde…';

  @override
  String get backupSetupDoneTitle => 'Votre sauvegarde est active';

  @override
  String backupSetupDoneBody(String folder) {
    return 'Karde enregistre une copie chaque fois que vous ajoutez, modifiez ou supprimez quelque chose. Elle va dans $folder.';
  }

  @override
  String get backupSetupFolderFailed =>
      'Karde n\'a pas pu enregistrer dans ce dossier. Veuillez en choisir un autre.';

  @override
  String get backupSelfTestFailed =>
      'Ce téléphone n\'a pas pu relire la copie qu\'il venait d\'enregistrer ; Karde n\'a donc pas activé la sauvegarde. Veuillez réessayer.';

  @override
  String get backupUpdated => 'Sauvegarde mise à jour.';

  @override
  String get backupFailedTitle => 'Votre sauvegarde n\'est plus enregistrée';

  @override
  String get alertsTitle => 'À votre attention';

  @override
  String get alertsTitleCalm => 'Tout va bien';

  @override
  String get alertsNone => 'Rien ne requiert votre attention.';

  @override
  String get alertsNoneBody =>
      'Karde vous préviendra ici si quelque chose doit être vérifié.';

  @override
  String get alertsFix => 'Corriger';

  @override
  String get alertsSetUp => 'Configurer';

  @override
  String get alertsGotIt => 'Compris';

  @override
  String get alertsAllow => 'Autoriser';

  @override
  String get backupNotSavingShort =>
      'Les nouvelles modifications ne sont pas copiées dans votre dossier de sauvegarde.';

  @override
  String backupFailedBody(String folder) {
    return 'Karde n\'a pas pu enregistrer dans $folder. Le dossier a peut-être été déplacé, renommé ou supprimé. Tant que ce n\'est pas corrigé, les nouvelles modifications ne sont copiées nulle part.';
  }

  @override
  String get backupFailedAction => 'Choisir un dossier';

  @override
  String settingsAutoBackupNote(String folder) {
    return 'Karde enregistre une copie chaque fois que vous ajoutez, modifiez ou supprimez quelque chose. Elle va dans $folder. Vous pouvez aussi en enregistrer une vous-même à tout moment.';
  }

  @override
  String get backupCouldNotReadVault =>
      'Impossible de lire votre coffre. Veuillez réessayer.';

  @override
  String get backupVaultEmpty =>
      'Votre coffre ne contient encore rien à sauvegarder.';

  @override
  String backupConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sauvegarder $count éléments',
      one: 'Sauvegarder 1 élément',
    );
    return '$_temp0';
  }

  @override
  String get backupConfirmMessage =>
      'Votre téléphone vous demandera de confirmer votre identité à plusieurs reprises pendant l\'opération.\n\nVous choisirez ensuite une phrase secrète et l\'emplacement du fichier.';

  @override
  String get backupPreparing => 'Préparation de la sauvegarde';

  @override
  String get backupUnlockingVault => 'Déverrouillage de votre coffre';

  @override
  String backupSavedAs(String fileName) {
    return 'Sauvegarde enregistrée sous $fileName.';
  }

  @override
  String get backupOpening => 'Ouverture de la sauvegarde';

  @override
  String get backupAllDuplicates =>
      'Tout ce que contient cette sauvegarde se trouve déjà dans votre coffre.';

  @override
  String get backupNoItems => 'Cette sauvegarde ne contient aucun élément.';

  @override
  String backupSkippedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éléments se trouvent déjà dans votre coffre et seront ignorés.',
      one: '1 élément se trouve déjà dans votre coffre et sera ignoré.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restaurer $count éléments',
      one: 'Restaurer 1 élément',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreConfirmMessage(String skipped) {
    return 'Votre téléphone vous demandera de confirmer votre identité à plusieurs reprises pendant l\'opération.$skipped\n\nRien de ce qui se trouve déjà dans votre coffre n\'est supprimé ni modifié.';
  }

  @override
  String get backupRestoreConfirmAction => 'Restaurer';

  @override
  String get backupRestoring => 'Restauration';

  @override
  String backupRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments restaurés dans votre coffre.',
      one: '1 élément restauré dans votre coffre.',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreCancelled =>
      'Restauration annulée. Rien n\'a été modifié.';

  @override
  String get backupWrongPassphrase =>
      'Cette phrase secrète n\'ouvre pas cette sauvegarde. Vérifiez-la et réessayez.';

  @override
  String get backupFileChooseAgain =>
      'Ce fichier n\'a pas pu être lu. Essayez de le sélectionner à nouveau.';

  @override
  String get backupNeedsScreenLock =>
      'Définissez un verrouillage d\'écran sur votre appareil avant de sauvegarder ou de restaurer.';

  @override
  String get backupKeyInvalidated =>
      'Les éléments déjà présents sur ce téléphone ne peuvent plus être ouverts. La restauration depuis une sauvegarde fonctionne toujours.';

  @override
  String get backupExplainerPassphrase =>
      'Votre sauvegarde est verrouillée par une phrase secrète que vous choisissez. Karde ne peut pas la récupérer : gardez-la en lieu sûr.';

  @override
  String get backupExplainerOffline =>
      'Rien n\'est envoyé en ligne. Vous choisissez où va le fichier, et il peut être restauré sur ce téléphone ou sur un nouveau.';

  @override
  String get backupCreateTitle => 'Créer une sauvegarde';

  @override
  String get backupCreateSubtitle =>
      'Enregistrez une copie verrouillée de tout ce que contient votre coffre, où vous le souhaitez.';

  @override
  String get backupCreateAction => 'Sauvegarder maintenant';

  @override
  String get backupRestoreCardTitle => 'Restaurer une sauvegarde';

  @override
  String get backupRestoreCardSubtitle =>
      'Ajoutez à ce coffre les éléments d\'un fichier de sauvegarde. Les éléments existants sont conservés, et tout ce qui est déjà là est ignoré.';

  @override
  String get backupRestoreCardAction => 'Choisir un fichier';

  @override
  String get backupKeepFileSafe =>
      'Conservez le fichier de sauvegarde dans un endroit de confiance. Toute personne disposant du fichier et de la phrase secrète peut l\'ouvrir.';

  @override
  String backupProgressCount(String label, int completed, int total) {
    return '$label — $completed sur $total';
  }

  @override
  String get backupConfirmIdentityHint =>
      'Confirmez votre identité lorsque votre téléphone vous le demande. Annuler arrête tout en toute sécurité — rien n\'est modifié.';

  @override
  String get backupProblemDamaged =>
      'Le contenu de la sauvegarde est endommagé.';

  @override
  String get backupProblemNotKardeBackup =>
      'Ce fichier n\'est pas une sauvegarde de coffre Karde.';

  @override
  String get backupProblemNewerVersion =>
      'Cette sauvegarde a été créée par une version plus récente de Karde. Mettez l\'application à jour et réessayez.';

  @override
  String get backupProblemPhotoDamaged =>
      'Une photo de la sauvegarde est endommagée.';

  @override
  String backupProblemMissingValue(String key) {
    return 'Il manque la valeur « $key » dans la sauvegarde.';
  }

  @override
  String backupProblemUnreadableValue(String key) {
    return 'La valeur « $key » de la sauvegarde est illisible.';
  }

  @override
  String get backupProblemRecordUnreadable =>
      'Un enregistrement du coffre n\'a pas pu être lu.';

  @override
  String get backupProblemFileDamaged =>
      'Ce fichier de sauvegarde n\'a pas pu être lu. Il est peut-être endommagé.';

  @override
  String get otherOption => 'Autre';

  @override
  String get goBack => 'Retour';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get loadingDetails => 'Chargement des détails';

  @override
  String get setScreenLockFirst =>
      'Définissez d\'abord un verrouillage d\'écran';

  @override
  String get screenLockExplainer =>
      'Karde ne peut rien enregistrer ni ouvrir tant que ce téléphone n\'a pas de verrouillage d\'écran.\n\nAjoutez un code, un schéma, un mot de passe ou une empreinte dans les réglages de votre téléphone, puis revenez.';

  @override
  String get vaultKeyChangedItemsLost =>
      'Les réglages de sécurité de votre téléphone ont changé, et les éléments enregistrés ici ne peuvent plus être ouverts. Ils sont irrécupérables.';

  @override
  String get addCardDecryptFailed =>
      'Impossible de déchiffrer les données de la carte existante.';

  @override
  String get addCardNeedsScreenLock =>
      'Définissez un verrouillage d\'écran (code, schéma ou biométrie) sur votre appareil pour enregistrer les cartes en toute sécurité.';

  @override
  String get addCardSaveFailed =>
      'Une erreur s\'est produite lors de l\'enregistrement de cette carte. Veuillez réessayer.';

  @override
  String get selectCardNetwork => 'Choisir le réseau de la carte';

  @override
  String get editCard => 'Modifier la carte';

  @override
  String get issuerFieldLabel => 'Émetteur';

  @override
  String get issuerTooltip =>
      'Le nom de la banque ou de l\'établissement qui a émis cette carte.\n\nExemple : BNP Paribas';

  @override
  String get customNetworkFieldLabel => 'Réseau personnalisé';

  @override
  String get customNetworkHint => 'ex. UnionPay, JCB';

  @override
  String get secureDetails => 'DONNÉES SÉCURISÉES';

  @override
  String get cardNumberFieldLabel => 'Numéro de carte';

  @override
  String get cardholderNameFieldLabel => 'Nom du titulaire';

  @override
  String get privateNotesFieldLabel => 'Notes privées';

  @override
  String get privateNotesTooltip =>
      'Tout détail, adresse ou contexte supplémentaire.\n\nExemple : Téléphone de la banque : 01 23 45 67 89';

  @override
  String get cardExpiredStillSave =>
      'Cette carte a expiré. Vous pouvez tout de même l\'enregistrer.';

  @override
  String get cardPhotoLabel => 'PHOTO DE LA CARTE';

  @override
  String get cardPhotoHint =>
      'Facultatif. Conservée sous clé avec le reste de la carte.';

  @override
  String get cardPhotoViewerTitle => 'Photo de la carte';

  @override
  String requiredFieldMarker(String label) {
    return '$label *';
  }

  @override
  String get idTypePassport => 'Passeport';

  @override
  String get idTypeDriversLicense => 'Permis de conduire';

  @override
  String get idTypeNationalId => 'Carte nationale d\'identité';

  @override
  String get idTypeResidentPermit => 'Titre de séjour';

  @override
  String get selectDocumentType => 'Choisir le type de document';

  @override
  String get addIdDocument => 'Ajouter un document d\'identité';

  @override
  String get editDocument => 'Modifier le document';

  @override
  String get idExpiryAfterIssue =>
      'L\'expiration doit être postérieure à la date de délivrance';

  @override
  String get idDobNotInFuture =>
      'La date de naissance ne peut pas être dans le futur';

  @override
  String get idIssueDateNotInFuture =>
      'La date de délivrance ne peut pas être dans le futur';

  @override
  String get idUpdatedSecurely =>
      'Document d\'identité mis à jour en toute sécurité.';

  @override
  String get idAddedSecurely =>
      'Document d\'identité ajouté en toute sécurité.';

  @override
  String get cardAddedSecurely => 'Carte ajoutée en toute sécurité.';

  @override
  String get cardUpdatedSecurely => 'Carte mise à jour en toute sécurité.';

  @override
  String get cardRemoved => 'Carte supprimée.';

  @override
  String get idRemoved => 'Document d\'identité supprimé.';

  @override
  String andBackedUp(String message) {
    return '$message Sauvegarde mise à jour.';
  }

  @override
  String savedButNotBackedUp(String message) {
    return '$message La copie n\'a pas encore pu être enregistrée dans votre dossier de sauvegarde.';
  }

  @override
  String get setUpBackupTitle => 'Aucune sauvegarde';

  @override
  String get setUpBackupBody =>
      'Karde peut conserver une copie de tout, afin que rien ne disparaisse avec ce téléphone.';

  @override
  String get setUpBackupAction => 'Configurer';

  @override
  String get addIdNeedsScreenLock =>
      'Définissez un verrouillage d\'écran sur votre appareil pour enregistrer les documents en toute sécurité.';

  @override
  String get addIdSaveFailed =>
      'Une erreur s\'est produite lors de l\'enregistrement de ce document. Veuillez réessayer.';

  @override
  String get issuingAuthorityTooltip =>
      'L\'organisme, la région ou le pays qui a délivré le document.\n\nExemple : Préfecture de Paris';

  @override
  String get personalIdTooltip =>
      'Un identifiant personnel secondaire.\n\nExemple : 1 85 12 75 108 123';

  @override
  String get idNotesTooltip =>
      'Tout détail ou adresse supplémentaire figurant sur le document.\n\nExemple : Donneur d\'organes, permis catégorie B';

  @override
  String get idUnlockFailedWarning =>
      'Ce document n\'a pas pu être déverrouillé : ses détails ne sont pas affichés et l\'enregistrement est désactivé. Revenez en arrière et réessayez.';

  @override
  String get customDocumentType => 'Type de document personnalisé';

  @override
  String get customDocumentTypeHint => 'ex. carte d\'étudiant';

  @override
  String get customDocumentTypeTooltip =>
      'Le nom précis de ce type de document personnalisé.\n\nExemple : carte de salle de sport';

  @override
  String get nicknameLabel => 'Surnom';

  @override
  String get nicknameHint => 'ex. mon passeport';

  @override
  String get nicknameTooltip =>
      'Un surnom personnel pour repérer facilement ce document dans votre coffre.\n\nExemple : mon passeport';

  @override
  String get documentPhotoLabel => 'PHOTO DU DOCUMENT';

  @override
  String get documentPhotoHint =>
      'Facultatif. Conservée sous clé avec le reste du document.';

  @override
  String get documentPhotoViewerTitle => 'Photo du document';

  @override
  String get searchItems => 'Rechercher…';

  @override
  String get pinToTop => 'Épingler en haut';

  @override
  String get unpinFromTop => 'Détacher du haut';

  @override
  String get pinToHomescreen => 'Épingler à l\'accueil';

  @override
  String get unpinFromHomescreen => 'Détacher de l\'accueil';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get photoBadge => 'Photo';

  @override
  String get tapCardForDetails => 'Touchez la carte pour tous les détails';

  @override
  String get noMatches => 'Aucun résultat';

  @override
  String noMatchesMessage(String query) {
    return 'Rien ici ne correspond à « $query ». Essayez un autre mot.';
  }

  @override
  String get noIdsYet => 'Aucun document pour l\'instant';

  @override
  String get noIdsYetMessage =>
      'Les passeports, permis et autres documents que vous ajoutez apparaîtront ici.';

  @override
  String get noCardsYet => 'Aucune carte pour l\'instant';

  @override
  String get noCardsYetMessage =>
      'Les cartes bancaires, cartes de fidélité et tout ce que vous ajoutez apparaîtront ici.';

  @override
  String get addNewId => 'Ajouter un document';

  @override
  String get sortItems => 'Trier les éléments';

  @override
  String get sortNewestFirst => 'Plus récents d\'abord';

  @override
  String get sortOldestFirst => 'Plus anciens d\'abord';

  @override
  String get sortAlphabetical => 'Alphabétique (A-Z)';

  @override
  String get settingsSecurityQuestions => 'Modifier les questions de sécurité';

  @override
  String get settingsSecurityQuestionsAdd =>
      'Ajouter des questions de sécurité';

  @override
  String get settingsSecurityQuestionsDesc =>
      'Modifier les questions servant à récupérer votre code';

  @override
  String get settingsSecurityQuestionsAddDesc =>
      'Créez des questions qui vous permettront de réinitialiser votre code PIN Karde';

  @override
  String get settingsBackupSection => 'SAUVEGARDE';

  @override
  String get settingsBackupRestoreDesc =>
      'Enregistrer une copie chiffrée de votre coffre, ou en restaurer une';

  @override
  String get settingsDangerZone => 'ZONE SENSIBLE';

  @override
  String get settingsEraseVault => 'Effacer le coffre';

  @override
  String get settingsEraseVaultDesc =>
      'Supprimer définitivement chaque carte, document, photo et réglage';

  @override
  String aboutDialogBody(String name, String version) {
    return '$name v$version\n\nUn coffre hors ligne pour les cartes et documents que vous préférez ne pas transporter.\n\nTout ce que vous enregistrez est chiffré sur ce téléphone et déverrouillé par votre empreinte. Karde n\'a ni compte ni accès à Internet : rien de ce que vous y mettez ne peut quitter votre appareil — ni vers nous, ni vers qui que ce soit.\n\nComme rien n\'est conservé ailleurs, une sauvegarde chiffrée est le seul moyen de transférer votre coffre vers un nouveau téléphone.';
  }

  @override
  String get eraseEverythingTitle => 'Tout effacer ?';

  @override
  String get eraseEverythingMessage =>
      'Chaque carte, document d\'identité et photo sera définitivement supprimé, ainsi que votre code et vos réglages. Cette action est irréversible, et Karde n\'en conserve aucune copie nulle part.';

  @override
  String get backUpFirst => 'Sauvegarder d\'abord';

  @override
  String get settingsLockExplainer =>
      'Votre téléphone vous demandera aussi votre empreinte ou le verrouillage de l\'écran chaque fois que vous ouvrez un élément.';

  @override
  String get settingsNoScreenLockWarning =>
      'Ce téléphone n\'a pas de verrouillage d\'écran, Karde ne peut donc ni enregistrer ni ouvrir vos éléments. Ajoutez un code, un schéma, un mot de passe ou une empreinte dans les réglages de votre téléphone, puis revenez.';

  @override
  String get passphraseTooShort => 'Trop courte';

  @override
  String get passphraseWeak => 'Faible';

  @override
  String get passphraseReasonable => 'Correcte';

  @override
  String get passphraseStrong => 'Robuste';

  @override
  String passphraseWeakHint(String label) {
    return '$label — plus longue vaut bien mieux que plus compliquée';
  }

  @override
  String get passphraseChooseTitle => 'Choisissez une phrase secrète';

  @override
  String get passphraseEnterTitle => 'Saisissez la phrase secrète';

  @override
  String get passphraseCreateExplainer =>
      'Si vous l\'oubliez, la sauvegarde ne pourra pas être ouverte. Karde ne peut pas la réinitialiser.';

  @override
  String get passphraseUnlockExplainer =>
      'Saisissez la phrase secrète que vous avez choisie lors de la création de cette sauvegarde.';

  @override
  String get passphraseFieldLabel => 'Phrase secrète';

  @override
  String get passphraseShow => 'Afficher la phrase secrète';

  @override
  String get passphraseHide => 'Masquer la phrase secrète';

  @override
  String get passphraseRequired => 'Saisissez une phrase secrète.';

  @override
  String passphraseMinimumLength(int count) {
    return 'Utilisez au moins $count caractères.';
  }

  @override
  String get passphraseConfirmLabel => 'Confirmez la phrase secrète';

  @override
  String get passphraseMismatch => 'Les deux saisies ne correspondent pas.';

  @override
  String get passphraseAdvice =>
      'Quelques mots sans rapport entre eux sont plus faciles à retenir et plus difficiles à deviner qu\'un seul mot court et compliqué.';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get securityQuestionFirstPet =>
      'Quel était le nom de votre premier animal de compagnie ?';

  @override
  String get securityQuestionMothersMaidenName =>
      'Quel est le nom de jeune fille de votre mère ?';

  @override
  String get securityQuestionElementarySchool =>
      'Quel était le nom de votre école primaire ?';

  @override
  String get securityQuestionCityOfBirth =>
      'Dans quelle ville êtes-vous né(e) ?';

  @override
  String get securityQuestionFirstCar =>
      'Quelle était la marque de votre première voiture ?';

  @override
  String get securityQuestionFavouriteBook => 'Quel est votre livre préféré ?';

  @override
  String get chooseBothQuestions => 'Choisissez les deux questions.';

  @override
  String get chooseTwoDifferentQuestions =>
      'Choisissez deux questions différentes.';

  @override
  String get securityQuestionsUpdated => 'Questions de sécurité mises à jour.';

  @override
  String get securityQuestionsSaved => 'Questions de sécurité enregistrées.';

  @override
  String get changeSecurityQuestionsTitle =>
      'Modifier vos questions de sécurité';

  @override
  String get changeSecurityQuestionsSubtitle =>
      'Elles vous permettent de revenir si vous oubliez votre code Karde.';

  @override
  String get saveQuestions => 'Enregistrer les questions';

  @override
  String get chooseAQuestion => 'Choisissez une question';

  @override
  String get securityAnswersHashNoteChanging =>
      'Vos réponses actuelles ne peuvent pas être affichées, seulement remplacées. L\'enregistrement remplace les deux.';

  @override
  String get securityAnswersHashNoteNew =>
      'Les majuscules et les espaces n\'ont pas d\'importance.';

  @override
  String get alreadyUsedAbove => 'Déjà utilisée ci-dessus';

  @override
  String get notesDecryptError => 'Erreur lors du déchiffrement des notes.';

  @override
  String get deleteCardTitle => 'Supprimer cette carte ?';

  @override
  String get deleteCardMessage =>
      'Cette action est irréversible. La carte sera définitivement supprimée.';

  @override
  String get deletePermanently => 'Supprimer définitivement';

  @override
  String get privateNotesAndPhoto => 'NOTES PRIVÉES ET PHOTO';

  @override
  String get cardMetadata => 'INFORMATIONS DE LA CARTE';

  @override
  String get notesAndPhoto => 'Notes et photo';

  @override
  String get privateNotesTitle => 'Notes privées';

  @override
  String get tapToUnlock => 'Touchez pour déverrouiller';

  @override
  String get photoCouldNotBeDisplayed =>
      'Cette photo n\'a pas pu être affichée.';

  @override
  String get addedOn => 'Ajouté le';

  @override
  String get lastUpdated => 'Dernière mise à jour';

  @override
  String get idOpenFailed => 'Impossible d\'ouvrir ce document. Réessayez.';

  @override
  String get deleteIdTitle => 'Supprimer ce document ?';

  @override
  String get deleteIdMessage =>
      'Cette action est irréversible. Le document sera définitivement supprimé.';

  @override
  String get additionalDetails => 'DÉTAILS SUPPLÉMENTAIRES';

  @override
  String get detailsSection => 'DÉTAILS';

  @override
  String get deleteId => 'Supprimer';

  @override
  String get documentDetails => 'Détails du document';

  @override
  String get noExtraDetails =>
      'Ce document ne comporte aucun détail supplémentaire.';

  @override
  String get dashboardLoadError => 'Impossible de charger vos éléments.';

  @override
  String get biometricChangeTitle => 'Le déverrouillage du téléphone a changé';

  @override
  String get biometricChangeMessage =>
      'Une empreinte digitale ou un visage a été ajouté ou supprimé sur ce téléphone. Si c\'était vous, il n\'y a aucun problème.';

  @override
  String get gotIt => 'J\'ai compris';

  @override
  String get securityWarning => 'Avertissement de sécurité';

  @override
  String get securityRisk => 'Risque de sécurité';

  @override
  String noBiometricsEnrolled(String details) {
    return 'Aucune donnée biométrique enregistrée. $details';
  }

  @override
  String missingSecureLockScreen(String details) {
    return 'L\'appareil n\'a pas de verrouillage d\'écran sécurisé. $details';
  }

  @override
  String get authReasonRevealCard =>
      'Veuillez vous authentifier pour afficher les informations sensibles de la carte.';

  @override
  String get authReasonOpenKarde =>
      'Veuillez vous authentifier pour ouvrir Karde.';

  @override
  String get authRequiredTitle => 'Authentification requise';

  @override
  String get useKardePin => 'Utiliser le code Karde';

  @override
  String get biometricsNotEnrolled =>
      'La biométrie n\'est pas prise en charge ou n\'est pas configurée sur cet appareil.';

  @override
  String get biometricLockedOut =>
      'Votre téléphone a suspendu le déverrouillage par empreinte après trop de tentatives. Patientez un instant ou utilisez le verrouillage de votre écran.';

  @override
  String get biometricUnavailableNow =>
      'Votre téléphone n\'a pas pu vérifier votre empreinte pour le moment.';

  @override
  String get biometricAuthFailedUsePin =>
      'L\'authentification biométrique a échoué. Veuillez utiliser votre code.';

  @override
  String get resetPinBiometricReason =>
      'Scannez votre empreinte (ou votre visage) pour réinitialiser votre code';

  @override
  String get verificationNotCompleted =>
      'La vérification n\'a pas abouti. Réessayez, ou utilisez une autre option de récupération ci-dessous.';

  @override
  String get biometricVerificationUnavailable =>
      'La vérification biométrique est indisponible pour le moment. Utilisez une autre option de récupération ci-dessous.';

  @override
  String get privacyPolicyHeading => 'Politique de confidentialité de Karde';

  @override
  String get privacyPolicyEffectiveDate =>
      'Date d\'entrée en vigueur : septembre 2026';

  @override
  String get privacySection1Title => '1. Stockage local uniquement';

  @override
  String get privacySection1Body =>
      'Tout ce que vous enregistrez — numéros de carte, codes de sécurité, notes et photos — est chiffré et conservé sur cet appareil. Karde n’a aucun accès à Internet, il ne peut donc rien envoyer où que ce soit, et nous ne voyons jamais vos données. Si vous activez la sauvegarde, Karde écrit un seul fichier chiffré dans un dossier que vous choisissez ; si ce dossier appartient à un service cloud, ce service synchronise le fichier, et seule votre phrase secrète permet de l’ouvrir.';

  @override
  String get privacySection2Title => '2. Chiffrement';

  @override
  String get privacySection2Body =>
      'Vos données sont protégées par un chiffrement AES-256-GCM. Les clés de chiffrement sont générées et conservées de façon sécurisée dans le Keystore matériel de votre appareil.';

  @override
  String get privacySection3Title => '3. Authentification';

  @override
  String get privacySection3Body =>
      'Pour accéder à vos données sensibles, Karde exige une authentification locale par la biométrie de votre appareil (Face ID ou empreinte digitale) ou par votre code Karde. Nous n\'avons accès ni à votre code ni à vos données biométriques.';

  @override
  String get privacySection4Title => '4. Suppression des données';

  @override
  String get privacySection4Body =>
      'Vous pouvez supprimer définitivement toutes vos données à tout moment via « Effacer le coffre » dans les Réglages, ou en désinstallant l’application. Rien de ce qui vous appartient n’est conservé ailleurs, l’une ou l’autre action est donc définitive. Les fichiers de sauvegarde que vous avez enregistrés vous-même ne sont pas touchés — supprimez-les là où vous les avez placés.';

  @override
  String get privacySection5Title => '5. Autorisations';

  @override
  String get privacySection5Body =>
      'Karde ne demande une autorisation qu’au moment où il en a besoin, jamais à l’ouverture de l’application. Votre empreinte ou le verrouillage de votre écran est ce qui déverrouille vos éléments. L’appareil photo est demandé lorsque vous touchez « Prendre une photo », et l’image reste sur cet appareil. Les notifications sont demandées la première fois que Karde a un rappel d’expiration à programmer, et chaque rappel est créé et affiché sur cet appareil. Karde ne demande pas l’accès à Internet, vos informations ne peuvent donc être envoyées nulle part.';

  @override
  String get privacySection6Title => '6. Modifications de cette politique';

  @override
  String get privacySection6Body =>
      'Nous pouvons mettre cette politique à jour de temps à autre. Toute modification sera répercutée dans l\'application. En continuant à l\'utiliser, vous acceptez la politique mise à jour.';

  @override
  String get recoveryNoPinNote =>
      'Vous avez choisi de déverrouiller Karde avec le verrouillage de votre téléphone : il n\'y a donc pas encore de code Karde à récupérer. Le configurer maintenant garantit qu\'un moyen de revenir existe déjà si vous en ajoutez un.';

  @override
  String get areYouSure => 'Êtes-vous sûr(e) ?';

  @override
  String get confirm => 'Confirmer';

  @override
  String get noScreenLockWarning =>
      'Ce téléphone n\'a pas de verrouillage d\'écran, Karde ne peut donc ni enregistrer ni ouvrir d\'éléments.\n\nAjoutez un code, un schéma, un mot de passe ou une empreinte dans les réglages de votre téléphone.\n\nVous pouvez terminer la configuration maintenant et y revenir ensuite.';

  @override
  String get backToLanguage => 'Retour à la langue';

  @override
  String get imageNoSource =>
      'Aucune application de cet appareil ne peut fournir d\'image.';

  @override
  String get imageUnreadable =>
      'Cette image n\'a pas pu être lue. Essayez-en une autre.';

  @override
  String get imageNotAvailable =>
      'L\'ajout de photos n\'est pas disponible sur cet appareil.';

  @override
  String get photoCouldNotBeAdded =>
      'Cette photo n\'a pas pu être ajoutée. Essayez-en une autre.';

  @override
  String get tapToViewFullSize => 'Touchez pour voir en grand';

  @override
  String get replacePhoto => 'Remplacer';

  @override
  String get removePhoto => 'Retirer';

  @override
  String get addAPhoto => 'Ajouter une photo';

  @override
  String get takeAPhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get photoClosesAutomatically =>
      'Se ferme automatiquement. Les captures d\'écran sont bloquées.';

  @override
  String get unlockNeedsScreenLock =>
      'Définissez un verrouillage d\'écran sur votre appareil pour déverrouiller votre coffre.';

  @override
  String get itemNoLongerDecryptable =>
      'Les réglages de sécurité de votre appareil ont changé : cet élément ne peut plus être déchiffré.';

  @override
  String get couldNotUnlockCard =>
      'Impossible de déverrouiller cette carte. Veuillez réessayer.';

  @override
  String get couldNotUnlockDocument =>
      'Impossible de déverrouiller ce document. Veuillez réessayer.';

  @override
  String get cardNumberCopied =>
      'Numéro de carte copié. Le presse-papiers sera vidé dans 60 s.';

  @override
  String pinLockedTryAgainIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Code incorrect. Réessayez dans $seconds secondes.',
      one: 'Code incorrect. Réessayez dans 1 seconde.',
    );
    return '$_temp0';
  }

  @override
  String pinLockedTryAgainInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Code incorrect. Réessayez dans $minutes minutes.',
      one: 'Code incorrect. Réessayez dans 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get pinInvalid => 'Code incorrect.';

  @override
  String pinDigitSemantic(String digit) {
    return 'Chiffre $digit du code';
  }

  @override
  String get deleteLastDigit => 'Supprimer le dernier chiffre';

  @override
  String get vaultUpdatedWithNewPin =>
      'Votre coffre sécurisé a été mis à jour avec le nouveau code.';

  @override
  String get vaultReadyWithNewPin =>
      'Vous pouvez désormais ouvrir Karde avec ce code PIN.';

  @override
  String get creditCard => 'Carte bancaire';

  @override
  String get cardholderPlaceholder => 'PRÉNOM NOM';

  @override
  String get privacySection7Title => '7. Conservez votre verrouillage d\'écran';

  @override
  String get privacySection7Body =>
      'La clé de chiffrement de Karde réside dans la puce de sécurité de votre téléphone et n\'existe que tant que celui-ci possède un verrouillage d\'écran. Changer votre code, votre schéma, votre mot de passe ou vos empreintes ne pose aucun problème — vos éléments restent lisibles. En revanche, si vous désactivez complètement le verrouillage d\'écran, cette clé est détruite et vos éléments ne peuvent plus être ouverts par personne, nous y compris. Une sauvegarde chiffrée est la seule chose qui y survive : créez-en une avant de retirer votre verrouillage d\'écran.';

  @override
  String get privacySection8Title => '8. Nous contacter';

  @override
  String get privacySection8Body =>
      'Questions sur cette politique, ou tout point qui vous semble flou : support@getgubae.com.';

  @override
  String get biometricCouldNotConfirm =>
      'Impossible de confirmer votre identité. Réessayez.';

  @override
  String get noBackupTitle => 'Aucune sauvegarde';

  @override
  String get noBackupShort =>
      'Aucune sauvegarde — tout se trouve uniquement sur ce téléphone.';

  @override
  String get noBackupBody =>
      'Tout ce que vous avez enregistré se trouve uniquement sur ce téléphone. Une sauvegarde vous permet de tout retrouver sur un nouveau téléphone.';

  @override
  String get copyLabel => 'Copier';

  @override
  String get passphraseSectionTitle => 'Votre phrase secrète de sauvegarde';

  @override
  String get passphraseSectionBody =>
      'C\'est la seule chose qui ouvre votre sauvegarde sur un nouveau téléphone. Karde ne peut pas la réinitialiser pour vous.';

  @override
  String get passphraseShowTitle => 'Afficher ma phrase secrète';

  @override
  String get passphraseShowBody =>
      'Déverrouillez avec votre empreinte ou le verrouillage de l\'écran pour la voir.';

  @override
  String get passphraseSaveTitle =>
      'Conserver ma phrase secrète sur ce téléphone';

  @override
  String get passphraseSaveBody =>
      'Vous pourrez la consulter ici en cas de doute.';

  @override
  String get passphraseChangeTitle => 'Changer ma phrase secrète';

  @override
  String get passphraseChangeBody => 'Vous devrez d\'abord saisir l\'actuelle.';

  @override
  String get passphraseChangeWarning =>
      'Votre sauvegarde passe immédiatement à la nouvelle phrase secrète. Les copies datées des jours précédents restent verrouillées avec l\'ancienne : conservez-la tant que vous en avez besoin.';

  @override
  String get passphraseChanged =>
      'Votre phrase secrète de sauvegarde a été changée.';

  @override
  String get passphraseUnchanged =>
      'C\'est déjà votre phrase secrète actuelle.';

  @override
  String get passphraseNotOnThisPhone =>
      'Karde n\'a plus de copie de votre phrase secrète sur ce téléphone.';

  @override
  String get passphraseCouldNotSave =>
      'Karde n\'a pas pu en conserver une copie sur ce téléphone. Votre sauvegarde elle-même n\'est pas affectée.';

  @override
  String get passphraseSavedOnPhone =>
      'Enregistrée. Vous pouvez la consulter sur cet écran quand vous voulez.';

  @override
  String get passphraseRevealTitle => 'Votre phrase secrète de sauvegarde';

  @override
  String get passphraseRevealWarning =>
      'Notez-la ailleurs que sur ce téléphone, ou conservez-la dans un gestionnaire de mots de passe. Si le téléphone disparaît, cette copie disparaît avec lui.';

  @override
  String get passphraseCopied =>
      'Phrase secrète copiée. Le presse-papiers s\'efface dans 60 s.';

  @override
  String get passphraseReuseTitle =>
      'Utiliser votre phrase secrète de sauvegarde ?';

  @override
  String get passphraseReuseMessage =>
      'Karde peut verrouiller ce fichier avec la phrase secrète que votre sauvegarde automatique utilise déjà : vous n\'en aurez qu\'une seule à retenir.';

  @override
  String get passphraseReuseConfirm => 'L\'utiliser';

  @override
  String get passphraseReuseAlternative => 'En saisir une autre';

  @override
  String get backupIncompleteTitle =>
      'Il manque des éléments à votre sauvegarde';

  @override
  String backupIncompleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ne sont pas encore dans votre sauvegarde.',
      one: 'Un élément n\'est pas encore dans votre sauvegarde.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingTitle => 'Copier ce que vous aviez déjà';

  @override
  String backupCopyExistingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éléments se trouvent dans votre coffre mais pas dans votre sauvegarde.',
      one:
          'Un élément se trouve dans votre coffre mais pas dans votre sauvegarde.',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyExistingAction => 'Les copier maintenant';

  @override
  String backupCopyConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copier $count éléments',
      one: 'Copier 1 élément',
    );
    return '$_temp0';
  }

  @override
  String get backupCopyConfirmMessage =>
      'Votre téléphone vous demandera de confirmer votre identité une fois par élément. Tout ce que vous enregistrerez ensuite sera copié sans rien demander.';

  @override
  String get backupCopying => 'Copie vers votre sauvegarde…';

  @override
  String backupCopyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés à votre sauvegarde.',
      one: '1 élément ajouté à votre sauvegarde.',
    );
    return '$_temp0';
  }

  @override
  String expiryCardSoon(String when) {
    return 'Cette carte expire en $when.';
  }

  @override
  String expiryCardPast(String when) {
    return 'Cette carte a expiré en $when.';
  }

  @override
  String expiryDocumentSoon(String when) {
    return 'Ce document expire le $when.';
  }

  @override
  String expiryDocumentPast(String when) {
    return 'Ce document a expiré le $when.';
  }

  @override
  String get settingsExpiryReminders => 'Rappels d\'expiration';

  @override
  String get settingsExpiryRemindersDesc =>
      'Me prévenir avant qu\'une carte ou un document n\'expire';

  @override
  String get remindersBlockedTitle => 'Recevoir les rappels';

  @override
  String get remindersBlockedBody =>
      'Votre téléphone empêche Karde de vous prévenir avant qu\'une carte ou un document n\'expire.';

  @override
  String notifyExpiringBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count cartes ou documents expirent bientôt. Ouvrez Karde pour voir lesquels.',
      one: '1 carte ou document expire bientôt. Ouvrez Karde pour voir lequel.',
    );
    return '$_temp0';
  }

  @override
  String notifyExpiredBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count cartes ou documents ont expiré. Ouvrez Karde pour voir lesquels.',
      one: '1 carte ou document a expiré. Ouvrez Karde pour voir lequel.',
    );
    return '$_temp0';
  }

  @override
  String get settingsExpiryNotifyBlocked =>
      'Karde ne peut pas envoyer de rappels tant que les notifications ne lui sont pas autorisées dans les réglages de votre téléphone.';

  @override
  String get settingsAutoBackupTitle => 'Sauvegarde automatique';

  @override
  String get settingsAutoBackupDesc =>
      'Garder une copie à jour à chaque changement';

  @override
  String get settingsAutoBackupOffTitle =>
      'Désactiver la sauvegarde automatique ?';

  @override
  String get settingsAutoBackupOffMessage =>
      'Karde cessera de tenir votre sauvegarde à jour. Le fichier déjà présent dans votre dossier reste exactement tel quel : rien n\'est supprimé.';

  @override
  String get settingsAutoBackupOffConfirm => 'Désactiver';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get activityTitle => 'Activité récente';

  @override
  String get activityEmpty =>
      'Rien pour l\'instant. L\'ajout, la modification ou la suppression d\'une carte ou d\'un document apparaîtra ici.';

  @override
  String get activityClear => 'Effacer';

  @override
  String activityCardAdded(String name) {
    return 'Vous avez ajouté la carte $name';
  }

  @override
  String activityCardChanged(String name) {
    return 'Vous avez modifié la carte $name';
  }

  @override
  String activityCardRemoved(String name) {
    return 'Vous avez supprimé la carte $name';
  }

  @override
  String activityDocumentAdded(String name) {
    return 'Vous avez ajouté le document $name';
  }

  @override
  String activityDocumentChanged(String name) {
    return 'Vous avez modifié le document $name';
  }

  @override
  String activityDocumentRemoved(String name) {
    return 'Vous avez supprimé le document $name';
  }

  @override
  String get cameraTitle => 'Prendre une photo';

  @override
  String get cameraGuideHint => 'Alignez la carte ou le document dans le cadre';

  @override
  String get cameraCropHint =>
      'Faites glisser les coins pour choisir ce que vous gardez';

  @override
  String get cameraRetake => 'Reprendre';

  @override
  String get cameraUsePhoto => 'Utiliser cette photo';

  @override
  String get cameraCaptureFailed =>
      'Cette photo n\'a pas pu être prise. Veuillez réessayer.';

  @override
  String get cameraUnavailable =>
      'Karde a besoin de l’autorisation d’utiliser l’appareil photo pour pouvoir prendre une photo.';

  @override
  String get cameraAllow => 'Autoriser l\'appareil photo';

  @override
  String get startupFailedTitle => 'Karde n’a pas pu démarrer';

  @override
  String get startupFailedBody =>
      'Un problème est survenu à l’ouverture de Karde. Vos éléments enregistrés sont intacts — rien n’a été modifié ni perdu. Réessayez, et si cela se reproduit, redémarrer votre téléphone suffit généralement.';

  @override
  String get startupFailedRetry => 'Réessayer';

  @override
  String get closeLabel => 'Fermer';

  @override
  String get searchLabel => 'Rechercher';

  @override
  String get searchStopLabel => 'Arrêter la recherche';

  @override
  String get sortLabel => 'Trier';

  @override
  String get cvvShowLabel => 'Afficher le CVV';

  @override
  String get cvvHideLabel => 'Masquer le CVV';
}
