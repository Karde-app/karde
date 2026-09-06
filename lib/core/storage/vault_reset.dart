import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/vault_health_provider.dart';
import '../../features/cards/data/card_repository.dart';
import '../../features/ids/data/id_repository.dart';
import 'settings_repository.dart';

/// Drops every provider that holds vault or settings state in memory.
///
/// Must be called immediately after [SettingsRepository.wipeAllData], and this
/// is not optional tidying — without it the wipe only half works.
///
/// `cardsProvider` and `idsProvider` are ordinary [AsyncNotifierProvider]s
/// rather than auto-disposing ones, so the list each one builds lives in the
/// root `ProviderScope` for the entire life of the process. Deleting the
/// database file does nothing to that cached list. The user therefore erased
/// their vault, walked back through onboarding, and found every card and ID
/// still sitting on the vault screen — read from memory, backed by a database
/// that no longer existed. Alarming, and easy to mistake for "erase does not
/// work".
///
/// The settings notifiers have the same defect for a different reason: each one
/// reads SharedPreferences once in its constructor and holds the value as state,
/// so the old theme, language, auto-hide duration and lock toggles all survive a
/// `_prefs.clear()` until something forces them to be rebuilt.
///
/// Kept in one place because both wipe paths — Settings → Erase vault, and the
/// Forgot-PIN escape hatch — need exactly the same treatment, and a fix applied
/// to only one of them would leave the other quietly broken.
void resetAllVaultState(WidgetRef ref) {
  // Vault contents.
  ref.invalidate(cardsProvider);
  ref.invalidate(idsProvider);
  ref.invalidate(vaultHealthProvider);
  // Caches a SharedPreferences flag in memory, so it has the same defect as the
  // settings notifiers below: without this an erased vault could still be
  // showing a fingerprint-change notice belonging to the previous owner.
  ref.invalidate(biometricChangeNoticeProvider);

  // Everything seeded from SharedPreferences at construction time.
  ref.invalidate(themeModeProvider);
  ref.invalidate(languageProvider);
  ref.invalidate(autoHideDurationProvider);
  ref.invalidate(requirePinLockProvider);
  ref.invalidate(biometricUnlockProvider);
  // Holds the date of the last backup, so without this an erased vault claims a
  // copy was taken of items it no longer has — and the dashboard prompt that
  // would have told the user to make a real one stays hidden.
  ref.invalidate(lastBackupProvider);

  // Answers about what is actually configured, cached from secure storage.
  //
  // Seen on the device: after erasing the vault and walking onboarding again
  // with Phone Lock, Settings still offered to "Change Karde PIN" — the answer
  // cached before the wipe, describing a PIN that no longer existed.
  ref.invalidate(hasKardePinProvider);
  ref.invalidate(hasSecurityQuestionsProvider);
}
