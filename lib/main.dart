import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Frees anybody left permanently locked out by an earlier build. Karde no
  // longer has a permanent lock at all, and someone still carrying the old flag
  // cannot reach their own cards until it goes.
  await SettingsRepository(sharedPreferences, const FlutterSecureStorage())
      .releaseAnyPermanentLock();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const IBankApp(),
    ),
  );
}
