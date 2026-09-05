import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_security_service.dart';

final deviceSecurityServiceProvider = Provider<DeviceSecurityService>((ref) {
  return DeviceSecurityService();
});

final vaultHealthProvider = FutureProvider<VaultHealthStatus>((ref) async {
  final service = ref.watch(deviceSecurityServiceProvider);
  return await service.getVaultHealthStatus();
});
