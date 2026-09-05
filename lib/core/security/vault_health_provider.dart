import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/settings_repository.dart';
import 'device_security_service.dart';
import 'encryption_service.dart';

final deviceSecurityServiceProvider = Provider<DeviceSecurityService>((ref) {
  return DeviceSecurityService();
});

final vaultHealthProvider = FutureProvider<VaultHealthStatus>((ref) async {
  final service = ref.watch(deviceSecurityServiceProvider);
  return await service.getVaultHealthStatus();
});

/// Whether to show the "fingerprints on this phone changed" notice.
///
/// Deliberately a notice and nothing more. Enrolling a fingerprint requires the
/// phone's own screen lock, so it is an act the owner consented to, and Karde's
/// vault key already accepts that same screen lock — a new fingerprint therefore
/// grants no access that the screen lock did not already grant. Locking the vault
/// over it would destroy data to prevent nothing. Telling the owner is useful;
/// acting on their behalf is not.
class BiometricChangeNotice extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final settings = ref.read(settingsRepositoryProvider);

    // Ask the canary once per app start. It answers true exactly once per real
    // change, so the answer is latched into settings rather than recomputed.
    if (await EncryptionService().biometricsChanged()) {
      await settings.setBiometricChangePending(true);
      return true;
    }
    return settings.getBiometricChangePending();
  }

  /// The user has seen it. Clear it until the next genuine change.
  Future<void> acknowledge() async {
    await ref.read(settingsRepositoryProvider).setBiometricChangePending(false);
    state = const AsyncValue.data(false);
  }
}

final biometricChangeNoticeProvider =
    AsyncNotifierProvider<BiometricChangeNotice, bool>(BiometricChangeNotice.new);
