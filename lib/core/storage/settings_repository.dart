import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database.dart';
import '../security/secret_hasher.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const secureStorage = FlutterSecureStorage();
  return SettingsRepository(prefs, secureStorage);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repository);
});

/// Null until the user has exported a backup at least once.
final lastBackupProvider = StateNotifierProvider<LastBackupNotifier, DateTime?>((ref) {
  return LastBackupNotifier(ref.watch(settingsRepositoryProvider));
});

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return LanguageNotifier(repository);
});

final autoHideDurationProvider = StateNotifierProvider<AutoHideDurationNotifier, int>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return AutoHideDurationNotifier(repository);
});

final requirePinLockProvider = StateNotifierProvider<RequirePinLockNotifier, bool>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return RequirePinLockNotifier(repository);
});

final biometricUnlockProvider = StateNotifierProvider<BiometricUnlockNotifier, bool>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return BiometricUnlockNotifier(repository);
});

/// Whether a Karde PIN has actually been created.
///
/// Deliberately separate from [requirePinLockProvider]. That one reports the
/// *setting*; this one reports the fact. They disagree for anyone who chose
/// Phone Lock at onboarding, and reading the setting as though it answered this
/// question caused a real security hole — see [SettingsRepository.hasKardePin].
///
/// Invalidate it after any flow that creates a PIN, so wording that depends on
/// it is not left describing the state before the change.
final hasKardePinProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepositoryProvider).hasKardePin();
});

/// Whether both security questions have been answered.
///
/// Drives the difference between offering to *add* questions and offering to
/// *change* them. Invalidate after saving questions.
final hasSecurityQuestionsProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepositoryProvider).hasSecurityQuestions();
});

class SettingsRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  SettingsRepository(this._prefs, this._secureStorage);

  static const _themeKey = 'theme_mode';
  static const _autoHideKey = 'auto_hide_duration';
  static const _firstLaunchKey = 'is_first_launch';
  static const _languageKey = 'app_language';
  static const _lastBackupKey = 'last_backup_at';
  static const _lockTypeKey = 'lock_type'; // 'phone', 'dedicated', 'both'
  static const _hashedPinKey = 'hashed_pin';
  static const _failedAttemptsKey = 'failed_attempts';
  static const _lockoutUntilKey = 'lockout_until';
  static const _isPermanentlyLockedKey = 'is_permanently_locked';
  
  static const _requirePinLockKey = 'require_pin_lock';
  static const _biometricUnlockKey = 'biometric_unlock';
  
  static const _recoveryPreferenceKey = 'recovery_preference'; // 'biometrics', 'questions', 'none'

  /// Set when the biometric canary reports an enrolment change, cleared when the
  /// user acknowledges the notice. Persisted because the canary reports a given
  /// change exactly once — it replants itself immediately — so without this the
  /// notice would vanish on the next app start whether or not it was ever read.
  static const _biometricNoticeKey = 'biometric_change_pending';
  static const _securityQuestion1Key = 'security_question_1';
  static const _securityAnswer1Key = 'security_answer_1';
  static const _securityQuestion2Key = 'security_question_2';
  static const _securityAnswer2Key = 'security_answer_2';

  ThemeMode getThemeMode() {
    final index = _prefs.getInt(_themeKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      return ThemeMode.values[index];
    }
    return ThemeMode.dark; // Default
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeKey, mode.index);
  }

  int getAutoHideDuration() {
    return _prefs.getInt(_autoHideKey) ?? 15; // Default 15 seconds
  }

  Future<void> setAutoHideDuration(int seconds) async {
    await _prefs.setInt(_autoHideKey, seconds);
  }

  // Security Toggles
  bool getRequirePinLock() {
    return _prefs.getBool(_requirePinLockKey) ?? true; // Default to true
  }

  Future<void> setRequirePinLock(bool value) async {
    await _prefs.setBool(_requirePinLockKey, value);
  }

  bool getBiometricUnlock() {
    return _prefs.getBool(_biometricUnlockKey) ?? false; // Default to false
  }

  Future<void> setBiometricUnlock(bool value) async {
    await _prefs.setBool(_biometricUnlockKey, value);
  }

  // First Launch
  bool getIsFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  bool getBiometricChangePending() {
    return _prefs.getBool(_biometricNoticeKey) ?? false;
  }

  Future<void> setBiometricChangePending(bool pending) async {
    await _prefs.setBool(_biometricNoticeKey, pending);
  }

  Future<void> setIsFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }

  /// When the user last exported a backup, or null if they never have.
  ///
  /// Karde previously had no idea, so it could not tell the one user who most
  /// needs reminding — somebody with a full vault and no copy of it anywhere —
  /// from somebody who is already safe.
  DateTime? getLastBackupAt() {
    final ms = _prefs.getInt(_lastBackupKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime when) async {
    await _prefs.setInt(_lastBackupKey, when.millisecondsSinceEpoch);
  }

  // Language
  /// Languages Karde actually ships translations for. Anything else — including
  /// 'am', which was offered in an earlier build and has since been withdrawn —
  /// reads back as English, so a phone that still has the old value saved shows
  /// English rather than crashing the settings language dropdown.
  static const supportedLanguages = <String>{'en', 'fr', 'ar'};

  String getLanguage() {
    final saved = _prefs.getString(_languageKey);
    if (saved == null || !supportedLanguages.contains(saved)) return 'en';
    return saved;
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
  }

  // Secure Storage - Lock Type & PIN
  Future<String?> getLockType() async {
    return await _secureStorage.read(key: _lockTypeKey);
  }

  Future<void> setLockType(String lockType) async {
    await _secureStorage.write(key: _lockTypeKey, value: lockType);
  }

  Future<String?> getHashedPin() async {
    return await _secureStorage.read(key: _hashedPinKey);
  }

  Future<void> setHashedPin(String hash) async {
    await _secureStorage.write(key: _hashedPinKey, value: hash);
  }

  /// Whether a Karde PIN has actually been set.
  ///
  /// [getRequirePinLock] only says the setting is on; it says nothing about
  /// whether a PIN was ever created. The two disagree for anyone who chose Phone
  /// Lock, who has a lock but no PIN — and once, reading the setting as though it
  /// answered this question let that user decline the fingerprint prompt, be
  /// offered the PIN screen, be sent to CREATE a PIN because none existed, and
  /// have that creation counted as a successful authentication.
  ///
  /// Whenever the question is "does a PIN exist", ask this, never the setting.
  Future<bool> hasKardePin() async {
    final stored = await getHashedPin();
    return stored != null && stored.isNotEmpty;
  }

  // Lockout State
  int getFailedAttempts() {
    return _prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  Future<void> setFailedAttempts(int attempts) async {
    await _prefs.setInt(_failedAttemptsKey, attempts);
  }

  DateTime? getLockoutUntil() {
    final timestamp = _prefs.getInt(_lockoutUntilKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLockoutUntil(DateTime? time) async {
    if (time == null) {
      await _prefs.remove(_lockoutUntilKey);
    } else {
      await _prefs.setInt(_lockoutUntilKey, time.millisecondsSinceEpoch);
    }
  }

  bool getIsPermanentlyLocked() {
    return _prefs.getBool(_isPermanentlyLockedKey) ?? false;
  }

  Future<void> setIsPermanentlyLocked(bool locked) async {
    await _prefs.setBool(_isPermanentlyLockedKey, locked);
  }

  // Recovery Preference
  Future<String?> getRecoveryPreference() async {
    return await _secureStorage.read(key: _recoveryPreferenceKey);
  }

  Future<void> setRecoveryPreference(String preference) async {
    await _secureStorage.write(key: _recoveryPreferenceKey, value: preference);
  }

  // Security Questions
  /// FIX 2-3: answers are hashed, never stored in readable form. They are
  /// normalised (trimmed, lowercased) first so that capitalisation or a stray
  /// space does not lock the user out of their own recovery flow.
  Future<void> setSecurityQuestions(String q1, String a1, String q2, String a2) async {
    await _secureStorage.write(key: _securityQuestion1Key, value: q1);
    await _secureStorage.write(
      key: _securityAnswer1Key,
      value: SecretHasher.hash(SecretHasher.normaliseAnswer(a1)),
    );
    await _secureStorage.write(key: _securityQuestion2Key, value: q2);
    await _secureStorage.write(
      key: _securityAnswer2Key,
      value: SecretHasher.hash(SecretHasher.normaliseAnswer(a2)),
    );
  }

  /// Verifies both answers against their stored hashes.
  ///
  /// Both are always checked, and the results combined at the end, so the time
  /// taken does not reveal which of the two answers was wrong.
  Future<bool> verifySecurityAnswers(String a1, String a2) async {
    final stored1 = await _secureStorage.read(key: _securityAnswer1Key);
    final stored2 = await _secureStorage.read(key: _securityAnswer2Key);

    final ok1 = SecretHasher.verify(SecretHasher.normaliseAnswer(a1), stored1);
    final ok2 = SecretHasher.verify(SecretHasher.normaliseAnswer(a2), stored2);
    return ok1 && ok2;
  }

  Future<Map<String, String?>> getSecurityQuestions() async {
    return {
      'q1': await _secureStorage.read(key: _securityQuestion1Key),
      'a1': await _secureStorage.read(key: _securityAnswer1Key),
      'q2': await _secureStorage.read(key: _securityQuestion2Key),
      'a2': await _secureStorage.read(key: _securityAnswer2Key),
    };
  }

  /// Whether both security questions are configured.
  ///
  /// Both, not either: recovery asks for the pair, so one on its own is not a way
  /// back in and must not be described to the user as though it were.
  Future<bool> hasSecurityQuestions() async {
    final stored = await getSecurityQuestions();
    final q1 = stored['q1'];
    final q2 = stored['q2'];
    return q1 != null && q1.isNotEmpty && q2 != null && q2.isNotEmpty;
  }

  /// Removes everything Karde holds: settings, the PIN and security answers, and
  /// the database.
  ///
  /// Photos need no separate step. They live inside each record's encrypted
  /// payload rather than as files of their own, so deleting the database deletes
  /// them with it.
  Future<void> wipeAllData() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
    await DatabaseHelper.instance.deleteDatabaseFile();
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repository;

  ThemeModeNotifier(this._repository) : super(_repository.getThemeMode());

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = mode;
    await _repository.setThemeMode(mode);
  }
}

class AutoHideDurationNotifier extends StateNotifier<int> {
  final SettingsRepository _repository;

  AutoHideDurationNotifier(this._repository) : super(_repository.getAutoHideDuration());

  Future<void> updateDuration(int seconds) async {
    state = seconds;
    await _repository.setAutoHideDuration(seconds);
  }
}

class LastBackupNotifier extends StateNotifier<DateTime?> {
  final SettingsRepository _repository;

  LastBackupNotifier(this._repository) : super(_repository.getLastBackupAt());

  Future<void> recordBackup() async {
    final now = DateTime.now();
    state = now;
    await _repository.setLastBackupAt(now);
  }
}

class LanguageNotifier extends StateNotifier<String> {
  final SettingsRepository _repository;

  LanguageNotifier(this._repository) : super(_repository.getLanguage());

  Future<void> updateLanguage(String languageCode) async {
    state = languageCode;
    await _repository.setLanguage(languageCode);
  }
}

class RequirePinLockNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  RequirePinLockNotifier(this._repository) : super(_repository.getRequirePinLock());

  Future<void> updateRequirePinLock(bool value) async {
    state = value;
    await _repository.setRequirePinLock(value);
  }
}

class BiometricUnlockNotifier extends StateNotifier<bool> {
  final SettingsRepository _repository;

  BiometricUnlockNotifier(this._repository) : super(_repository.getBiometricUnlock());

  Future<void> updateBiometricUnlock(bool value) async {
    state = value;
    await _repository.setBiometricUnlock(value);
  }
}
