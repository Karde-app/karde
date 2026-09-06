import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/storage/settings_repository.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/data/auto_backup_recorder.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/presentation/add_card_screen.dart';
import '../../cards/presentation/vault_screen.dart';
import '../../ids/presentation/add_id_screen.dart';
import '../../ids/data/id_repository.dart';
import '../../ids/domain/virtual_id.dart';
import '../../ids/presentation/widgets/realistic_id_card.dart';
import '../../cards/domain/virtual_card.dart';
import 'widgets/dashboard_preview_card.dart';
import '../../../theme/theme.dart';
import '../../../core/security/device_security_service.dart';
import '../../../core/security/vault_health_provider.dart';

/// FIX 7-2: decorative placeholders for the empty / single-item dashboard stack.
/// These were rebuilt on every frame; they hold no data, so one instance each is
/// enough. `encryptedData` is empty by design — nothing ever decrypts them.
final _placeholderEpoch = DateTime.fromMillisecondsSinceEpoch(0);

final _placeholderVisa = VirtualCard(
  id: -1,
  nickname: 'ISSUER',
  cardBrand: 'VISA',
  encryptedData: '',
  lastFourDigits: '1234',
  createdAt: _placeholderEpoch,
  updatedAt: _placeholderEpoch,
);

final _placeholderMastercard = VirtualCard(
  id: -2,
  nickname: 'ISSUER',
  cardBrand: 'MASTERCARD',
  encryptedData: '',
  lastFourDigits: '4471',
  createdAt: _placeholderEpoch,
  updatedAt: _placeholderEpoch,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final cardsAsync = ref.watch(cardsProvider);
    final idsAsync = ref.watch(idsProvider);
    final vaultHealthAsync = ref.watch(vaultHealthProvider);
    
    final int cardsCount = cardsAsync.valueOrNull?.length ?? 0;
    final int idsCount = idsAsync.valueOrNull?.length ?? 0;
    final int totalItems = cardsCount + idsCount;

    // Failing first: someone whose backup has stopped needs to know that more
    // than someone who never started one needs to be asked.
    final Widget? backupNeedsAttention = ref.watch(autoBackupFailingProvider)
        ? _buildBackupFailing(context, loc, theme)
        : (totalItems > 0 &&
                !(ref.watch(autoBackupConfiguredProvider).valueOrNull ?? true))
            ? _buildSetUpBackup(context, loc, theme)
            : null;

    return Scaffold(
      body: SafeArea(
        // Scrollable, because this page grows. It was a fixed column that had to
        // fit the screen exactly, so anything that appeared — a security warning,
        // a fingerprint-change notice, the backup reminder — pushed the bottom of
        // the page off the screen and Flutter simply clipped it. Reported from
        // the device as the backup reminder "removing" the Add a card and Add an
        // ID buttons: they were not removed, they were cut off, with no way to
        // scroll to them. A large system font size would have done the same.
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                loc.welcomeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                )
              ),
              const SizedBox(height: 4),
              Text(
                loc.welcomeSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )
              ),
              const SizedBox(height: 16),
              
              // Security Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KardeColors.signalTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: KardeColors.signalTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: KardeColors.signalTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.offlineBadge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: KardeColors.signalTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Access Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.quickAccess,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultScreen()));
                    },
                    child: Text(
                      loc.seeAll,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: KardeColors.champagneGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quick Access Stack
              Builder(
                builder: (context) {
                  final bool isLoading = cardsAsync.isLoading || idsAsync.isLoading;
                  final bool hasError = cardsAsync.hasError || idsAsync.hasError;

                  if (isLoading) {
                    return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                  }
                  
                  if (hasError) {
                    return SizedBox(height: 220, child: Center(child: Text(loc.dashboardLoadError)));
                  }

                  final cards = cardsAsync.valueOrNull ?? [];
                  final ids = idsAsync.valueOrNull ?? [];
                  
                  List<dynamic> displayItems = [...cards, ...ids];
                  
                  final pinnedItems = displayItems.where((item) {
                    return (item is VirtualCard) ? item.isPinnedToHomescreen : (item as VirtualId).isPinnedToHomescreen;
                  }).toList();
                  
                  if (pinnedItems.isNotEmpty) {
                    displayItems = pinnedItems;
                  }
                  
                  displayItems.sort((a, b) {
                    final DateTime aTime = (a is VirtualCard) ? a.createdAt : (a as VirtualId).createdAt;
                    final DateTime bTime = (b is VirtualCard) ? b.createdAt : (b as VirtualId).createdAt;
                    return bTime.compareTo(aTime);
                  });
                  
                  bool isEmptyState = false;
                  
                  if (displayItems.isEmpty) {
                    isEmptyState = true;
                    displayItems = [_placeholderVisa, _placeholderMastercard];
                  } else if (displayItems.length == 1) {
                    displayItems.add(_placeholderMastercard);
                  }
                  
                  Widget buildItem(dynamic item, bool isFront) {
                    if (item is VirtualCard) {
                      return DashboardPreviewCard(
                        key: ValueKey('card_${item.id}'),
                        card: item, 
                        isFront: isFront
                      );
                    } else if (item is VirtualId) {
                      return RealisticIdCard(
                        key: ValueKey('id_${item.id}'),
                        idDoc: item,
                        isDecrypted: false,
                      );
                    }
                    return const SizedBox();
                  }
                  
                  final stackWidget = SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        if (displayItems.length > 1)
                          Positioned(
                            top: 20, left: 20, right: 0, bottom: 0,
                            child: Transform.rotate(
                              angle: 0.05,
                              child: buildItem(displayItems[1], false),
                            ),
                          ),
                        Positioned(
                          top: 0, left: 0, right: 15, bottom: 20,
                          child: Transform.rotate(
                            angle: -0.02,
                            child: buildItem(displayItems[0], true),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (isEmptyState) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen()));
                      },
                      child: AbsorbPointer(child: stackWidget),
                    );
                  }
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultScreen()));
                    },
                    child: AbsorbPointer(child: stackWidget),
                  );
                },
              ),
              
              const Spacer(),
              
              // The banner below sat flush against the bottom of the card stack
              // whenever neither notice was showing, because both of those
              // render nothing at all in that case and each carried its own
              // spacing. The gap belongs here, where it does not depend on
              // whether anything else happens to be on screen.
              const SizedBox(height: 32),

              // Fingerprint-change notice. Informational only: it never blocks
              // anything and nothing in the vault is touched. See
              // BiometricChangeNotice for why this is a message rather than a lock.
              ref.watch(biometricChangeNoticeProvider).maybeWhen(
                    data: (show) => show
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.fingerprint,
                                      color: Colors.orange, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.biometricChangeTitle,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.biometricChangeMessage,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () => ref
                                              .read(biometricChangeNoticeProvider
                                                  .notifier)
                                              .acknowledge(),
                                          child: Text(
                                            loc.gotIt,
                                            style: TextStyle(
                                              color:
                                                  KardeColors.champagneGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),

              // The state of the copy Karde keeps.
              //
              // Not a nag any more. Karde now takes the backup itself, so the old
              // "you have not backed up" reminder was telling the user off for
              // something the app had already done for them. What is left is the
              // two things it cannot do on its own: it has not been set up yet,
              // or it has stopped working.
              //
              // Neither is dismissible. The moment either one matters — a screen
              // lock switched off, a lost phone — arrives without warning, and
              // Android gives an app no chance to intervene at that point.
              if (backupNeedsAttention != null) ...[
                backupNeedsAttention,
                const SizedBox(height: 12),
              ],

              // Vault Health Banner
              vaultHealthAsync.when(
                data: (status) {
                  String title;
                  IconData mainIcon;
                  Color mainIconColor;
                  IconData? trailingIcon;
                  Color? trailingIconColor;
                  String subtitle = loc.vaultHealthItems(totalItems);

                  switch (status) {
                    case VaultHealthStatus.excellent:
                      title = loc.vaultHealthExcellent; // "Excellent"
                      mainIcon = Icons.shield_outlined;
                      mainIconColor = KardeColors.champagneGold;
                      trailingIcon = Icons.check;
                      trailingIconColor = KardeColors.signalTeal;
                      break;
                    case VaultHealthStatus.atRisk:
                      title = loc.securityRisk;
                      mainIcon = Icons.gpp_bad_outlined;
                      mainIconColor = Colors.red;
                      subtitle = loc.missingSecureLockScreen(subtitle);
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: status == VaultHealthStatus.excellent 
                          ? theme.dividerColor 
                          : mainIconColor.withOpacity(0.5)
                      ),
                      boxShadow: theme.brightness == Brightness.light ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      children: [
                        Icon(mainIcon, color: mainIconColor, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: status == VaultHealthStatus.excellent 
                                    ? theme.colorScheme.onSurface 
                                    : mainIconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: status == VaultHealthStatus.excellent 
                                    ? theme.textTheme.bodyMedium?.color
                                    : mainIconColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (trailingIcon != null)
                          Icon(trailingIcon, color: trailingIconColor),
                      ],
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              
              const SizedBox(height: 16),
              
              // Actions Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddCardScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: theme.brightness == Brightness.light ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : KardeColors.champagneGold.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: KardeColors.champagneGold, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.addACard,
                              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddIdScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: theme.brightness == Brightness.light ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : KardeColors.champagneGold.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.badge_outlined, color: KardeColors.champagneGold, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.addAnId,
                              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Shown when the copy has fallen behind the vault.
  ///
  /// The loud one, and the reason the whole feature needs a voice at all. A
  /// backup that quietly stopped working months ago is worse than no backup,
  /// because its owner believes they are covered and has stopped thinking about
  /// it. The commonest cause is dull rather than dramatic: a cloud folder and no
  /// signal at the moment a card was saved.
  Widget _buildBackupFailing(
      BuildContext context, AppLocalizations loc, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BackupScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KardeColors.ember.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KardeColors.ember.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: KardeColors.ember, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.backupFailedTitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.backupNotSavingShort,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown to somebody with items and no backup arranged.
  ///
  /// Only reachable by a vault that predates automatic backup, since setup is
  /// now part of onboarding. Kept short and calm: it is an offer, not a telling
  /// off, and it is on screen every time they open the app.
  Widget _buildSetUpBackup(
      BuildContext context, AppLocalizations loc, ThemeData theme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BackupScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: KardeColors.champagneGold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: KardeColors.champagneGold.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: KardeColors.champagneGold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.setUpBackupBody,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontSize: 12.5, height: 1.3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loc.setUpBackupAction,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: KardeColors.champagneGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
