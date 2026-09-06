import 'encryption_service.dart';

/// How well protected the vault is by the phone it lives on.
enum VaultHealthStatus {
  /// The phone has a secure lock screen, so the vault key exists and is
  /// hardware-protected.
  excellent,

  /// The phone has no secure lock screen. The vault key cannot be created, and
  /// any key that already existed has been destroyed by Android.
  atRisk,
}

class DeviceSecurityService {
  /// Reports whether the phone can protect the vault.
  ///
  /// There is exactly one question worth asking here, and it is not about
  /// fingerprints. The vault key is created with
  /// `setUserAuthenticationRequired(true)`, which accepts a strong biometric
  /// **or** the phone's own PIN, pattern or password. A phone secured with a PIN
  /// and no fingerprint enrolled protects the vault completely.
  ///
  /// This used to check `getAvailableBiometrics()` and call an empty list a
  /// "Security Warning — no biometrics enrolled". That was simply wrong, and the
  /// user reported it: a PIN-only phone was told its vault was at risk when
  /// nothing was at risk at all. Biometrics are a convenience, not a level of
  /// protection; a good PIN is arguably the stronger of the two. Frightening
  /// someone about a choice that costs them nothing teaches them to ignore the
  /// banner, which is the one thing it cannot afford.
  ///
  /// So it asks the Keystore the same question the vault itself depends on —
  /// can this key exist and be used — and reports that. The one honest bad
  /// answer is "no secure lock screen at all", which is real: nothing can be
  /// saved, and anything already saved has already been lost.
  Future<VaultHealthStatus> getVaultHealthStatus() async {
    final canProtect = await EncryptionService().canUseVault();
    return canProtect ? VaultHealthStatus.excellent : VaultHealthStatus.atRisk;
  }
}
