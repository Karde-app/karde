import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/karde_alert.dart';
import 'alerts_sheet.dart';
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                  _buildAlertBell(context, ref, theme),
                ],
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

              // Nothing here any more. Every warning that used to stack up above
              // the cards — no screen lock, backup stopped, backup never set up,
              // fingerprints changed — now lives behind the bell in the header.
              //
              // They were all true and all worth saying, and together they pushed
              // the vault itself off the page. Collecting them means none has to
              // be dropped to make room for another, and the home screen can go
              // back to being a home screen.

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

  /// One place for everything Karde wants to say.
  ///
  /// A count rather than a dot, because "three things need looking at" and "one
  /// thing needs looking at" call for different amounts of urgency from the
  /// person reading it, and a dot says neither.
  ///
  /// Always on screen, badge or no badge. It used to disappear when all was
  /// well, which cost more than it saved: a bell that comes and goes gives
  /// nobody a way to ask "is everything all right?", so its absence reads as an
  /// app that has stopped watching rather than one with nothing to report. Quiet
  /// and unbadged, it answers that question every time it is looked at.
  Widget _buildAlertBell(BuildContext context, WidgetRef ref, ThemeData theme) {
    final alerts = ref.watch(kardeAlertsProvider);
    final hasAlerts = alerts.isNotEmpty;
    final urgent =
        alerts.any((a) => a.severity == KardeAlertSeverity.urgent);
    final accent = urgent ? KardeColors.ember : KardeColors.champagneGold;

    return GestureDetector(
      onTap: () => AlertsSheet.show(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 28,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: hasAlerts ? 0.75 : 0.45)),
            if (hasAlerts)
              PositionedDirectional(
                top: -4,
                end: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                  ),
                  child: Text(
                    '${alerts.length}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: urgent ? Colors.white : KardeColors.obsidian,
                    ),
                  ),
                ),
              ),
          ],
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
  
  /// Shown to somebody with items and no backup arranged.
  ///
  /// This is where backup is offered now. It was briefly the last step of
  /// onboarding, which asked someone who had not yet seen a single screen to
  /// invent a passphrase and choose a folder for a copy of an empty vault.
  /// Here it appears once there is something to lose, which is both the honest
  /// moment and the one where the offer makes sense.
  ///
  /// Kept short and calm: it is an offer, not a telling off, and it is on screen
  /// every time they open the app until it is taken.
  
}
