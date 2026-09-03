import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/data/card_repository.dart';
import '../../cards/presentation/add_card_screen.dart';
import '../../cards/presentation/vault_screen.dart';
import '../../cards/domain/virtual_card.dart';
import 'widgets/dashboard_preview_card.dart';
import '../../../theme/theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to Karde', 
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KardeColors.warmIvory,
                )
              ),
              const SizedBox(height: 4),
              Text(
                'Your secure, offline digital wallet', 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: KardeColors.slate,
                )
              ),
              const SizedBox(height: 16),
              
              // Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KardeColors.signalTeal.withOpacity(0.3)),
                  color: KardeColors.signalTeal.withOpacity(0.1),
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
                      'Offline & Encrypted',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: KardeColors.signalTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Access
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Quick Access', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      final cards = cardsAsync.valueOrNull;
                      if (cards == null || cards.isEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const VaultScreen()));
                      }
                    },
                    child: Text(
                      'See all', 
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: KardeColors.champagneGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Cards Stack
              cardsAsync.when(
                data: (cards) {
                  List<VirtualCard> displayCards = List.from(cards);
                  displayCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  bool isEmptyState = false;
                  
                  if (displayCards.isEmpty) {
                    isEmptyState = true;
                    displayCards = [
                      VirtualCard(
                        id: -1,
                        nickname: 'ISSUER',
                        cardBrand: 'VISA',
                        encryptedCardNumber: '',
                        encryptedExpiry: '',
                        encryptedCvv: '',
                        encryptedCardholderName: '',
                        encryptedNotes: '',
                        lastFourDigits: '1234',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      VirtualCard(
                        id: -2,
                        nickname: 'ISSUER',
                        cardBrand: 'MASTERCARD',
                        encryptedCardNumber: '',
                        encryptedExpiry: '',
                        encryptedCvv: '',
                        encryptedCardholderName: '',
                        encryptedNotes: '',
                        lastFourDigits: '4471',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    ];
                  } else if (displayCards.length == 1) {
                    displayCards.add(
                      VirtualCard(
                        id: -2,
                        nickname: 'ISSUER',
                        cardBrand: 'MASTERCARD',
                        encryptedCardNumber: '',
                        encryptedExpiry: '',
                        encryptedCvv: '',
                        encryptedCardholderName: '',
                        encryptedNotes: '',
                        lastFourDigits: '4471',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                  }
                  
                  final stackWidget = SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        if (displayCards.length > 1)
                          Positioned(
                            top: 20,
                            left: 20,
                            right: 0,
                            bottom: 0,
                            child: Transform.rotate(
                              angle: 0.05,
                              child: DashboardPreviewCard(
                                key: ValueKey(displayCards[1].id),
                                card: displayCards[1], 
                                isFront: false
                              ),
                            ),
                          ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 15,
                          bottom: 20,
                          child: Transform.rotate(
                            angle: -0.02,
                            child: DashboardPreviewCard(
                              key: ValueKey(displayCards[0].id),
                              card: displayCards[0], 
                              isFront: true
                            ),
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
                loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                error: (e, st) => const SizedBox(height: 220, child: Center(child: Text('Error loading cards'))),
              ),
              
              const Spacer(),
              
              // Vault Health Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: KardeColors.graphite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: KardeColors.champagneGold, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vault health: excellent',
                            style: TextStyle(
                              color: KardeColors.warmIvory,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cardsAsync.valueOrNull?.length ?? 0} items encrypted with AES-256-GCM',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check, color: KardeColors.signalTeal),
                  ],
                ),
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
                          color: KardeColors.graphite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: KardeColors.champagneGold, size: 20),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add a card',
                              style: TextStyle(color: KardeColors.warmIvory, fontWeight: FontWeight.bold, fontSize: 14),
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
                          MaterialPageRoute(builder: (context) => const VaultScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: KardeColors.graphite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: KardeColors.signalTeal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.all_inbox, color: KardeColors.signalTeal, size: 20),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Open Vault',
                              style: TextStyle(color: KardeColors.warmIvory, fontWeight: FontWeight.bold, fontSize: 14),
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
    );
  }
}
