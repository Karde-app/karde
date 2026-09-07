import 'package:flutter/material.dart';
import '../../../core/widgets/karde_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/storage/settings_repository.dart';
import '../../../core/storage/vault_reset.dart';
import '../../../core/app_info.dart';
import '../../../theme/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/security/authentication_service.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/widgets/karde_confirm_dialog.dart';
import '../../onboarding/presentation/pin_setup_screen.dart';
import '../../onboarding/presentation/language_screen.dart';
import '../../onboarding/presentation/recovery_setup_screen.dart';
import '../../onboarding/presentation/security_questions_setup_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/presentation/backup_setup_screen.dart';
import '../../backup/data/auto_backup_recorder.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final autoHideDuration = ref.watch(autoHideDurationProvider);
    final requirePinLock = ref.watch(requirePinLockProvider);
    final biometricUnlock = ref.watch(biometricUnlockProvider);
    // What is actually configured, as opposed to what the switches above ask
    // for. Both are read from storage, so the rows describe the vault the user
    // really has. Until the read completes, assume the thing does not exist:
    // "Create" and "Add" are the safe wordings to be briefly wrong about, where
    // "Change" would name something that may not be there.
    final hasKardePin = ref.watch(hasKardePinProvider).valueOrNull ?? false;
    final hasSecurityQuestions =
        ref.watch(hasSecurityQuestionsProvider).valueOrNull ?? false;
    final language = ref.watch(languageProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTab),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader(loc.appearance, context),
          _buildGlassContainer(
            context: context,
            child: Column(
              children: [
                _buildSettingRow(
                  context: context,
                  title: loc.theme,
                  subtitle: loc.themeDesc,
                  trailing: _buildThemeSegmentedControl(context, ref, themeMode),
                ),
                _buildSettingRow(
                  context: context,
                  title: loc.language,
                  subtitle: loc.appDisplayLanguage,
                  trailing: _buildLanguageDropdown(context, ref, language),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(loc.privacy, context),
          _buildGlassContainer(
            context: context,
            child: _buildSettingRow(
              context: context,
              title: loc.autoHide,
              subtitle: loc.autoHideDesc,
              trailing: _buildTimerSegmentedControl(context, ref, autoHideDuration),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(loc.security, context),
          _buildGlassContainer(
            context: context,
            child: Column(
              children: [
                _buildSettingRow(
                  context: context,
                  title: loc.appPinLock,
                  subtitle: loc.appPinLockDesc,
                  leadingIcon: Icons.lock_outline,
                  trailing: _buildCustomSwitch(
                    context: context,
                    value: requirePinLock,
                    onChanged: (val) async {
                      if (!val && !biometricUnlock) {
                        _showErrorSnackBar(loc.mustKeepOneLock, context);
                        return;
                      }

                      // Turning this on when no Karde PIN has ever been created
                      // locked the user out of their own app: the lock screen
                      // demanded a PIN that did not exist, every attempt failed,
                      // and five failures triggered the permanent lock whose only
                      // escape is wiping the vault. Users who chose "Phone Lock"
                      // at onboarding never set a PIN, so this was reachable from
                      // a single settings tap. Create the PIN first.
                      //
                      // Only the lock is turned on here. Creating the PIN, and
                      // the recovery options that follow it, are _manageKardePin.
                      if (val) {
                        final settings = ref.read(settingsRepositoryProvider);
                        if (!await settings.hasKardePin()) {
                          if (!await _manageKardePin()) return;
                        }
                      } else {
                        // Cancel means cancel. Asking a question and then doing
                        // the thing anyway makes the question a lie, and the
                        // dialog's Cancel button an ornament.
                        if (!await _offerToForgetPin()) return;
                        if (!mounted) return;
                      }

                      ref.read(requirePinLockProvider.notifier).updateRequirePinLock(val);
                    },
                  ),
                ),
                _buildSettingRow(
                  context: context,
                  title: loc.biometricUnlockTitle,
                  subtitle: loc.biometricUnlockDesc,
                  leadingIcon: Icons.fingerprint,
                  trailing: _buildCustomSwitch(
                    context: context,
                    value: biometricUnlock,
                    onChanged: (val) async {
                      if (!val && !requirePinLock) {
                        _showErrorSnackBar(loc.mustKeepOneLock, context);
                        return;
                      }

                      if (val) {
                        // Check if device supports biometrics before enabling
                        try {
                          final canCheck = await _auth.canCheckBiometrics;
                          final isSupported = await _auth.isDeviceSupported();
                          if (!canCheck && !isSupported) {
                            if (!mounted) return;
                            _showErrorSnackBar(loc.biometricsNotSupported, context);
                            return;
                          }
                        } catch (_) {
                          if (!mounted) return;
                          _showErrorSnackBar(loc.biometricsError, context);
                          return;
                        }
                      }
                      ref.read(biometricUnlockProvider.notifier).updateBiometricUnlock(val);
                    },
                  ),
                ),
                // "Change Karde PIN" offered someone who has never had one the
                // chance to change a thing that does not exist. The row now says
                // what it will actually do, and creating a PIN carries on to
                // recovery setup — the first moment recovery means anything.
                _buildNavigationRow(
                  context: context,
                  title: hasKardePin ? loc.changePin : loc.createKardePin,
                  subtitle:
                      hasKardePin ? loc.changePinDesc : loc.createKardePinDesc,
                  leadingIcon: Icons.password,
                  onTap: _manageKardePin,
                ),
                // "Change the questions" is equally wrong for someone who has
                // none. That state is reachable from Phone Lock onboarding, and
                // from anyone who chose Phone Lock or No Recovery at the recovery
                // step.
                _buildNavigationRow(
                  context: context,
                  title: hasSecurityQuestions
                      ? loc.settingsSecurityQuestions
                      : loc.settingsSecurityQuestionsAdd,
                  subtitle: hasSecurityQuestions
                      ? loc.settingsSecurityQuestionsDesc
                      : loc.settingsSecurityQuestionsAddDesc,
                  leadingIcon: Icons.quiz_outlined,
                  onTap: _changeSecurityQuestions,
                ),
              ],
            ),
          ),
          _buildVaultKeyNote(context),
          const SizedBox(height: 24),

          _buildSectionHeader(loc.settingsBackupSection, context),
          _buildGlassContainer(
            context: context,
            child: _buildNavigationRow(
              context: context,
              title: loc.backupTitle,
              subtitle: loc.settingsBackupRestoreDesc,
              leadingIcon: Icons.backup_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                );
              },
            ),
          ),
          if (ref.watch(autoBackupSetupProvider).valueOrNull == null)
            _buildGlassContainer(
              context: context,
              child: _buildNavigationRow(
                context: context,
                title: loc.backupSetupTitle,
                subtitle: loc.setUpBackupBody,
                leadingIcon: Icons.cloud_upload_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupSetupScreen()),
                ),
              ),
            ),
          _buildAutoBackupNote(context),
          const SizedBox(height: 24),

          // Kept apart from Security, and last before About, so a destructive
          // action is never adjacent to the toggles people come here to flip.
          _buildSectionHeader(loc.settingsDangerZone, context),
          _buildGlassContainer(
            context: context,
            child: _buildNavigationRow(
              context: context,
              title: loc.settingsEraseVault,
              subtitle: loc.settingsEraseVaultDesc,
              leadingIcon: Icons.delete_forever_outlined,
              isDestructive: true,
              onTap: _eraseVault,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(loc.about, context),
          _buildGlassContainer(
            context: context,
            child: Column(
              children: [
                _buildNavigationRow(
                  context: context,
                  title: loc.aboutKarde,
                  subtitle: loc.aboutKardeDesc,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(loc.aboutKarde),
                        // FIX 9-4: version comes from a single constant.
                        content: Text(
                          loc.aboutDialogBody(AppInfo.name, AppInfo.version),
                        ),
                      ),
                    );
                  },
                ),
                _buildNavigationRow(
                  context: context,
                  title: loc.privacyPolicy,
                  subtitle: loc.privacyPolicyDesc,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              '${AppInfo.nameWithVersion} · ${loc.offlineBadge}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // FIX 5-2: routed through the shared helper so settings errors look the same
  // as errors everywhere else in the app.
  void _showErrorSnackBar(String message, BuildContext context) {
    KardeFeedback.error(context, message);
  }

  /// Lets the user change their security questions after onboarding.
  ///
  /// Says what Karde is already doing about backups, and where.
  ///
  /// The durable home for this. The home screen used to nag about taking a
  /// backup, which became a telling off for something the app now does by
  /// itself; that reminder is gone, and this is what replaces it. It names the
  /// folder because "your backup is safe somewhere" is not reassurance — knowing
  /// which folder is what lets someone go and look.
  ///
  /// Shows nothing at all when backup has not been set up. The dashboard says
  /// that, once, and saying it twice would be the nagging this replaced.
  Widget _buildAutoBackupNote(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final setup = ref.watch(autoBackupSetupProvider).valueOrNull;
    if (setup == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 17,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.settingsAutoBackupNote(setup.folderLabel),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12.5,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Asks what should happen to the PIN now that Karde will stop asking for it.
  ///
  /// Switching the PIN off used to leave it sitting in storage, unused and
  /// invisible. Switching back on months later then silently reinstated a PIN
  /// the user had every reason to have forgotten, and five wrong guesses at it
  /// is the permanent lockout whose only escape is erasing the vault.
  ///
  /// Keeping is the safe answer and the one a dismissed dialog gives, because it
  /// destroys nothing. Deleting is offered because "I am done with this PIN" is
  /// a perfectly ordinary thing to mean, and leaving no way to say it is how the
  /// forgotten PIN got there in the first place.
  ///
  /// Not gated behind authentication: the user has already authenticated to be
  /// in Settings changing security, deleting a PIN reveals nothing, and the
  /// vault's own protection does not depend on it.
  ///
  /// Returns whether to go on and switch the PIN off. Cancel means cancel — the
  /// switch stays as it was and nothing is deleted. A dialog whose Cancel button
  /// still performs the action it asked about is worse than no dialog, because
  /// it teaches the user that reading them is pointless.
  Future<bool> _offerToForgetPin() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (!await settings.hasKardePin()) return true;
    if (!mounted) return false;

    final loc = AppLocalizations.of(context)!;
    final choice = await KardeConfirmDialog.showWithAlternative(
      context,
      title: loc.keepPinTitle,
      message: loc.keepPinMessage,
      confirmLabel: loc.keepPinKeep,
      alternativeLabel: loc.keepPinDelete,
      isDestructive: false,
    );
    if (!mounted) return false;
    if (choice == KardeConfirmChoice.cancelled) return false;
    if (choice == KardeConfirmChoice.confirmed) return true;

    await settings.deleteHashedPin();
    if (!mounted) return true;
    ref.invalidate(hasKardePinProvider);
    KardeFeedback.success(context, loc.pinDeleted);
    return true;
  }

  /// Sets the Karde PIN: creating a first one, or replacing the one there is.
  ///
  /// Shared by the "App PIN lock" switch and the PIN row, because both are the
  /// same request arriving through different doors.
  ///
  /// Identity is checked first, with whatever the user is actually using today.
  /// [AuthenticationService.authenticate] picks it: the Karde PIN where one is
  /// required, the phone's own lock otherwise. Without that gate, anyone holding
  /// an unlocked phone could set a PIN of their own and shut the owner out of
  /// their own vault.
  ///
  /// Whether a PIN already existed is read here rather than taken from the row
  /// that was tapped. The row is painted from a value that may still have been
  /// loading, and this is the difference between changing a PIN and creating
  /// one — which decides whether recovery options follow.
  ///
  /// They follow only a PIN that has just come into existence. Onboarding used to
  /// show recovery to Phone Lock users who had no PIN to recover; this is the
  /// moment a PIN exists and the question becomes a real one. For a PIN being
  /// replaced, whatever recovery the user already chose still stands, and the
  /// security questions row is where they change it.
  ///
  /// Returns whether a Karde PIN exists by the time it finishes.
  Future<bool> _manageKardePin() async {
    final settings = ref.read(settingsRepositoryProvider);
    final hadPin = await settings.hasKardePin();
    if (!mounted) return hadPin;

    final authenticated =
        await AuthenticationService().authenticate(context, settings);
    if (!authenticated || !mounted) return hadPin;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupScreen(isChangingPin: true)),
    );

    // Ask storage, not the screen. The PIN screen can be backed out of, and its
    // success dialog pops without returning anything that would tell the two
    // apart.
    final hasPin = await settings.hasKardePin();
    if (!mounted) return hasPin;
    ref.invalidate(hasKardePinProvider);
    if (hadPin || !hasPin) return hasPin;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecoverySetupScreen(fromSettings: true),
      ),
    );
    if (mounted) ref.invalidate(hasSecurityQuestionsProvider);
    return true;
  }

  /// Previously there was no way to. The questions were set once during setup
  /// and could never be revisited — so a user who had forgotten their own
  /// answers, or who realised the answers were guessable by anyone who knew
  /// them, had no remedy at all.
  ///
  /// Identity is checked first. These answers are a way back into the vault, so
  /// being able to overwrite them is equivalent to being able to reset the PIN:
  /// anyone who picked up an unlocked phone could otherwise quietly replace the
  /// recovery credentials with their own.
  Future<void> _changeSecurityQuestions() async {
    final authenticated = await AuthenticationService().authenticate(
      context,
      ref.read(settingsRepositoryProvider),
    );
    if (!authenticated || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SecurityQuestionsSetupScreen(isChanging: true),
      ),
    );
    if (mounted) ref.invalidate(hasSecurityQuestionsProvider);
  }

  /// Erases everything and returns the app to a first-run state.
  ///
  /// [SettingsRepository.wipeAllData] has existed all along but was reachable
  /// only by failing the PIN enough times to trigger the permanent lockout and
  /// then choosing to wipe. A user who simply wanted to hand the phone on, or
  /// start over, had no way to do it from inside the app.
  ///
  /// Two gates, in this order: an explicit confirmation that spells out what
  /// goes, and then the app's own authentication. The confirmation comes first
  /// so nobody is asked to authenticate before they know what they are agreeing
  /// to; the authentication comes second so a tap by someone holding an unlocked
  /// phone is not enough on its own.
  Future<void> _eraseVault() async {
    final loc = AppLocalizations.of(context)!;
    final choice = await KardeConfirmDialog.showWithAlternative(
      context,
      title: loc.eraseEverythingTitle,
      message: loc.eraseEverythingMessage,
      alternativeLabel: loc.backUpFirst,
      confirmLabel: loc.settingsEraseVault,
    );
    if (!mounted) return;

    // Telling someone to go and make a backup is not much help when they are
    // already standing in front of the warning. The way out is offered here, and
    // they are returned to Settings afterwards rather than being tipped straight
    // back into the erase they may no longer want.
    if (choice == KardeConfirmChoice.alternative) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BackupScreen()),
      );
      return;
    }
    if (choice != KardeConfirmChoice.confirmed) return;

    final authenticated = await AuthenticationService().authenticate(
      context,
      ref.read(settingsRepositoryProvider),
    );
    if (!authenticated || !mounted) return;

    await ref.read(settingsRepositoryProvider).wipeAllData();

    // The database is gone, but the providers still hold the vault they built
    // from it. Without this the user walks back through onboarding and finds
    // every card and ID still listed.
    resetAllVaultState(ref);
    if (!mounted) return;

    // Back to the very beginning, with no route left to go back to: the
    // providers behind the screens underneath now describe a vault that no
    // longer exists.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
      (route) => false,
    );
  }

  /// Explains the one authentication step the toggles above do NOT control.
  ///
  /// Users read "Biometric unlock: off" as "Karde will never ask me for a
  /// fingerprint", then got a device prompt anyway when revealing a card and
  /// reported it as a bug. The toggles govern Karde's own checks; the prompt they
  /// were seeing comes from Android enforcing the vault key, which is created
  /// with `setUserAuthenticationRequired(true)` and cannot be used without it.
  ///
  /// The same note carries the warning for a device with no screen lock at all.
  /// That case is not a nuisance but a hard stop: without a secure lock screen
  /// the Keystore will not hold the key, so nothing can be encrypted or opened.
  /// Saying so here means the user finds out in Settings rather than after
  /// typing a full card in.
  Widget _buildVaultKeyNote(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<bool>(
      future: EncryptionService().canUseVault(),
      builder: (context, snapshot) {
        // Say nothing until the answer is known, rather than flashing a warning
        // at a user whose device is perfectly well configured.
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bool hasSecureLock = snapshot.data!;
        final Color accent =
            hasSecureLock ? theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface : theme.colorScheme.error;
        final IconData icon =
            hasSecureLock ? Icons.info_outline : Icons.warning_amber_rounded;
        final String message = hasSecureLock
            ? loc.settingsLockExplainer
            : loc.settingsNoScreenLockWarning;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    height: 1.45,
                    color: accent,
                    fontWeight: hasSecureLock ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.045) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 1,
        ) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    IconData? leadingIcon,
    required Widget trailing,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required String title,
    required String subtitle,
    IconData? leadingIcon,
    required VoidCallback onTap,
    required BuildContext context,
    bool isDestructive = false,
  }) {
    // A row that destroys data is drawn in the error colour, so it cannot be
    // mistaken at a glance for the navigation rows around it.
    final accent = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: accent, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? accent
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSegmentedControl(BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeSegment(
            icon: Icons.brightness_auto,
            isSelected: currentTheme == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).updateThemeMode(ThemeMode.system),
            context: context,
          ),
          _buildThemeSegment(
            icon: Icons.light_mode,
            isSelected: currentTheme == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).updateThemeMode(ThemeMode.light),
            context: context,
          ),
          _buildThemeSegment(
            icon: Icons.dark_mode,
            isSelected: currentTheme == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).updateThemeMode(ThemeMode.dark),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegment({required IconData icon, required bool isSelected, required VoidCallback onTap, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? const LinearGradient(
            colors: [Color(0xFFE7D4A0), Color(0xFFC9A961), Color(0xFF9C7C41)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          boxShadow: (isSelected && !isDark) ? [
            BoxShadow(
              color: const Color(0xFFC9A961).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected 
              ? (isDark ? KardeColors.obsidian : Colors.white) 
              : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTimerSegmentedControl(BuildContext context, WidgetRef ref, int currentDuration) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimerSegment(
            label: '15s',
            isSelected: currentDuration == 15,
            onTap: () => ref.read(autoHideDurationProvider.notifier).updateDuration(15),
            context: context,
          ),
          _buildTimerSegment(
            label: '30s',
            isSelected: currentDuration == 30,
            onTap: () => ref.read(autoHideDurationProvider.notifier).updateDuration(30),
            context: context,
          ),
          _buildTimerSegment(
            label: '60s',
            isSelected: currentDuration == 60,
            onTap: () => ref.read(autoHideDurationProvider.notifier).updateDuration(60),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSegment({required String label, required bool isSelected, required VoidCallback onTap, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isSelected ? const LinearGradient(
            colors: [Color(0xFFE7D4A0), Color(0xFFC9A961), Color(0xFF9C7C41)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          boxShadow: (isSelected && !isDark) ? [
            BoxShadow(
              color: const Color(0xFFC9A961).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? (isDark ? KardeColors.obsidian : Colors.white) 
                : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSwitch({required bool value, required ValueChanged<bool> onChanged, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: value ? const LinearGradient(
            colors: [Color(0xFF57E9DC), Color(0xFF12746C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: value ? null : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          boxShadow: (value && !isDark) ? [
            BoxShadow(
              color: const Color(0xFF12746C).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, WidgetRef ref, String currentLanguage) {
    return DropdownButton<String>(
      value: currentLanguage,
      underline: const SizedBox(),
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'fr', child: Text('Français')),
        DropdownMenuItem(value: 'ar', child: Text('العربية')),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(languageProvider.notifier).updateLanguage(newValue);
        }
      },
    );
  }
}
