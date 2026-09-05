import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.privacyPolicy),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.privacyPolicyHeading,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 16),
            Text(
              loc.privacyPolicyEffectiveDate,
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection(loc.privacySection1Title, loc.privacySection1Body),
            _buildSection(loc.privacySection2Title, loc.privacySection2Body),
            _buildSection(loc.privacySection3Title, loc.privacySection3Body),
            _buildSection(loc.privacySection4Title, loc.privacySection4Body),
            _buildSection(loc.privacySection5Title, loc.privacySection5Body),
            _buildSection(loc.privacySection6Title, loc.privacySection6Body),
            _buildSection(loc.privacySection7Title, loc.privacySection7Body),
            _buildSection(loc.privacySection8Title, loc.privacySection8Body),
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
