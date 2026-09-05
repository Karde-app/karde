import 'package:local_auth/local_auth.dart';

enum VaultHealthStatus {
  excellent,
  warning,
  atRisk,
}

class DeviceSecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<VaultHealthStatus> getVaultHealthStatus() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        // Device lacks secure hardware or lock screen entirely
        return VaultHealthStatus.atRisk;
      }

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();

      if (canCheckBiometrics && availableBiometrics.isNotEmpty) {
        // Device has secure hardware AND biometrics are enrolled
        return VaultHealthStatus.excellent;
      } else {
        // Device is supported (has a PIN/Pattern/Password) but NO biometrics enrolled
        return VaultHealthStatus.warning;
      }
    } catch (e) {
      // In case of error (e.g. platform exception), fallback to warning
      return VaultHealthStatus.warning;
    }
  }
}
