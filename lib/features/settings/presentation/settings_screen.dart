import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final autoHideDuration = ref.watch(autoHideDurationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref.read(themeModeProvider.notifier).updateThemeMode(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Auto-hide', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Hide sensitive details after'),
            trailing: DropdownButton<int>(
              value: autoHideDuration,
              underline: const SizedBox(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  ref.read(autoHideDurationProvider.notifier).updateDuration(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 seconds')),
                DropdownMenuItem(value: 30, child: Text('30 seconds')),
                DropdownMenuItem(value: 60, child: Text('60 seconds')),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Card details are protected using your Android device authentication. '
              'The information is encrypted at rest using Android Keystore and AES-256-GCM.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About iBank'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('About iBank'),
                  content: Text('iBank Secure Wallet v1.0.0\n\nA totally offline, encrypted secure vault for your cards.'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Privacy Policy'),
                  content: Text('Your data never leaves your device. Everything is encrypted locally using AES-256 and Android Keystore. We collect no analytics and have no servers.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
