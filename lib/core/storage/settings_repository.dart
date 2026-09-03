import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database.dart';

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

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return LanguageNotifier(repository);
});

final autoHideDurationProvider = StateNotifierProvider<AutoHideDurationNotifier, int>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return AutoHideDurationNotifier(repository);
});

class SettingsRepository {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  SettingsRepository(this._prefs, this._secureStorage);

  static const _themeKey = 'theme_mode';
  static const _autoHideKey = 'auto_hide_duration';
  static const _firstLaunchKey = 'is_first_launch';
  static const _languageKey = 'app_language';
  static const _lockTypeKey = 'lock_type'; // 'phone', 'dedicated', 'both'
  static const _hashedPinKey = 'hashed_pin';
  static const _failedAttemptsKey = 'failed_attempts';
  static const _lockoutUntilKey = 'lockout_until';
  static const _isPermanentlyLockedKey = 'is_permanently_locked';
  
  static const _recoveryPreferenceKey = 'recovery_preference'; // 'biometrics', 'questions', 'none'
  static const _securityQuestion1Key = 'security_question_1';
  static const _securityAnswer1Key = 'security_answer_1';
  static const _securityQuestion2Key = 'security_question_2';
  static const _securityAnswer2Key = 'security_answer_2';

  ThemeMode getThemeMode() {
    final index = _prefs.getInt(_themeKey);
    if (index != null && index >= 0 && index < ThemeMode.values.length) {
      return ThemeMode.values[index];
    }
    return ThemeMode.system; // Default
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeKey, mode.index);
  }

  int getAutoHideDuration() {
    return _prefs.getInt(_autoHideKey) ?? 30; // Default 30 seconds
  }

  Future<void> setAutoHideDuration(int seconds) async {
    await _prefs.setInt(_autoHideKey, seconds);
  }

  // First Launch
  bool getIsFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setIsFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }

  // Language
  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'en';
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
  Future<void> setSecurityQuestions(String q1, String a1, String q2, String a2) async {
    await _secureStorage.write(key: _securityQuestion1Key, value: q1);
    await _secureStorage.write(key: _securityAnswer1Key, value: a1);
    await _secureStorage.write(key: _securityQuestion2Key, value: q2);
    await _secureStorage.write(key: _securityAnswer2Key, value: a2);
  }

  Future<Map<String, String?>> getSecurityQuestions() async {
    return {
      'q1': await _secureStorage.read(key: _securityQuestion1Key),
      'a1': await _secureStorage.read(key: _securityAnswer1Key),
      'q2': await _secureStorage.read(key: _securityQuestion2Key),
      'a2': await _secureStorage.read(key: _securityAnswer2Key),
    };
  }

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

class LanguageNotifier extends StateNotifier<String> {
  final SettingsRepository _repository;

  LanguageNotifier(this._repository) : super(_repository.getLanguage());

  Future<void> updateLanguage(String languageCode) async {
    state = languageCode;
    await _repository.setLanguage(languageCode);
  }
}
