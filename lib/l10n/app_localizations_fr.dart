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
  String get idsFilter => 'Pièces d\'identité • Bientôt';

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
  String get amharic => 'አማርኛ';

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
