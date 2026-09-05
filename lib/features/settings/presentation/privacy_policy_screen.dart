import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for Karde',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: September 2026',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Local Storage Only', 'All your data, including card numbers, CVVs, and notes, is encrypted and stored locally on your device. We do not transmit, back up, or store your data on any external servers or cloud services. You have complete control over your data.'),
            _buildSection('2. Encryption', 'Your data is secured using AES-256-GCM encryption. The encryption keys are securely generated and stored in your device\'s hardware-backed Keystore.'),
            _buildSection('3. Authentication', 'To access your sensitive data, Karde requires local authentication via your device\'s Biometrics (Face ID/Fingerprint) or your custom Karde PIN. We do not have access to your PIN or biometric data.'),
            _buildSection('4. Data Deletion', 'You can permanently delete all your data at any time using the "Wipe App Data" feature in Settings, or by uninstalling the application. Since no data is stored in the cloud, uninstallation results in permanent deletion of your vault.'),
            _buildSection('5. Permissions', 'The app only requests permissions necessary for its core functionality, such as Biometric authentication. It does not request internet access, ensuring your data cannot be transmitted.'),
            _buildSection('6. Changes to this Policy', 'We may update this policy occasionally. Any changes will be reflected in the app. By continuing to use the app, you agree to the updated policy.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}
