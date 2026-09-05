import '../../l10n/app_localizations.dart';

/// The questions Karde offers for PIN recovery, identified by a stable code.
///
/// The code is what gets written to secure storage, never the sentence. Storing
/// the sentence would pin the question to the language it was chosen in, so a
/// user who set recovery up in English and later switched to French would be
/// asked in English forever — and rewording a question in a later release would
/// orphan the answer already hashed against it.
enum SecurityQuestion {
  firstPet('first_pet'),
  mothersMaidenName('mothers_maiden_name'),
  elementarySchool('elementary_school'),
  cityOfBirth('city_of_birth'),
  firstCar('first_car'),
  favouriteBook('favourite_book');

  const SecurityQuestion(this.code);

  /// The value persisted in secure storage.
  final String code;

  static SecurityQuestion? fromCode(String? code) {
    for (final question in values) {
      if (question.code == code) return question;
    }
    return null;
  }
}

/// The sentence to show for a stored question value.
///
/// A value that is not one of the codes is shown exactly as it was stored.
/// Builds before this change wrote the English sentence itself, and those users
/// must keep seeing the question they actually answered — their answer hash is
/// the only thing that can unlock recovery, and it was made against that
/// wording.
String securityQuestionText(String stored, AppLocalizations loc) {
  switch (SecurityQuestion.fromCode(stored)) {
    case SecurityQuestion.firstPet:
      return loc.securityQuestionFirstPet;
    case SecurityQuestion.mothersMaidenName:
      return loc.securityQuestionMothersMaidenName;
    case SecurityQuestion.elementarySchool:
      return loc.securityQuestionElementarySchool;
    case SecurityQuestion.cityOfBirth:
      return loc.securityQuestionCityOfBirth;
    case SecurityQuestion.firstCar:
      return loc.securityQuestionFirstCar;
    case SecurityQuestion.favouriteBook:
      return loc.securityQuestionFavouriteBook;
    case null:
      return stored;
  }
}
