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
  String get welcomeSubtitle =>
      'Votre portefeuille numérique sécurisé hors ligne';

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
    return '$count éléments chiffrés avec AES-256-GCM';
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
  String get setupLockTitle => 'Sécurisez';

  @override
  String get setupLockSubtitle =>
      'Comment souhaitez-vous protéger vos secrets?';

  @override
  String get phoneLock => 'Verrouillage du téléphone';

  @override
  String get phoneLockDesc => 'Utilisez Face ID, Touch ID ou le code.';

  @override
  String get kardePin => 'Code Karde';

  @override
  String get kardePinDesc => 'Créez un code PIN dédié.';

  @override
  String get bothLocks => 'Les deux';

  @override
  String get bothLocksDesc => 'Téléphone pour l\'appli, Code pour les secrets.';

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
  String get recoverySetupTitle => 'Récupération du code PIN';

  @override
  String get recoverySetupSubtitle =>
      'Comment souhaitez-vous récupérer votre code PIN si vous l\'oubliez ?';

  @override
  String get biometricRecovery => 'Verrouillage du téléphone';

  @override
  String get biometricRecoveryDesc =>
      'Utilisez la méthode qui déverrouille votre téléphone — empreinte digitale, visage, schéma, code PIN ou mot de passe — pour réinitialiser votre code PIN Karde.';

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
  String get maxAttemptsReached =>
      'Nombre maximal de tentatives atteint. Vous devez réinitialiser votre code PIN.';

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
  String get appPinLock => 'Verrouillage par code PIN';

  @override
  String get appPinLockDesc => 'Exiger un code PIN pour ouvrir Karde';

  @override
  String get biometricUnlockTitle => 'Déverrouillage biométrique';

  @override
  String get biometricUnlockDesc => 'Utiliser l\'empreinte digitale ou Face ID';

  @override
  String get changePin => 'Modifier le code PIN';

  @override
  String get changePinDesc => 'Mettre à jour votre code PIN principal';

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
  String get lettersAndSymbolsNotAllowed =>
      'Les lettres et les symboles ne sont pas autorisés';

  @override
  String get kardeIsLocked => 'Karde est verrouillé';

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
      'La clé de votre coffre n\'est plus valide, les éléments existants ne peuvent donc pas être lus. La restauration à partir d\'une sauvegarde fonctionne toujours.';

  @override
  String get backupExplainerPassphrase =>
      'Votre sauvegarde est verrouillée par une phrase secrète que vous choisissez. Sans elle, le fichier est illisible — et Karde ne peut pas la récupérer pour vous, alors conservez-la en lieu sûr.';

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
      'Conservez le fichier de sauvegarde dans un endroit sûr. Il contient tout ce que renferme votre coffre, protégé uniquement par la phrase secrète que vous avez choisie.';

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
}
