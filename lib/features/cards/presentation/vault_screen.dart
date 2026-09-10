import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/virtual_card.dart';
import '../data/card_repository.dart';
import '../../ids/domain/virtual_id.dart';
import '../../ids/data/id_repository.dart';
import '../../ids/presentation/id_details_screen.dart';
import '../../ids/presentation/widgets/decryptable_id_card.dart';
import 'widgets/decryptable_card.dart';
import 'add_card_screen.dart';
import '../../ids/presentation/add_id_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';

enum VaultItemType { card, id }

class VaultItem {
  final VaultItemType type;
  final dynamic item;
  final int id;
  final String nickname;
  final String subtitle;
  final DateTime createdAt;
  final bool isPinnedToTop;
  final bool isPinnedToHomescreen;

  VaultItem({
    required this.type,
    required this.item,
    required this.id,
    required this.nickname,
    required this.subtitle,
    required this.createdAt,
    this.isPinnedToTop = false,
    this.isPinnedToHomescreen = false,
  });
}

final allVaultItemsProvider = Provider<AsyncValue<List<VaultItem>>>((ref) {
  final cards = ref.watch(cardsProvider);
  final ids = ref.watch(idsProvider);
  
  return cards.whenData((c) {
    return ids.whenData((i) {
      final merged = [
        ...c.map((card) => VaultItem(
          type: VaultItemType.card,
          item: card,
          id: card.id!,
          nickname: card.nickname,
          subtitle: '${card.cardBrand} •••• ${card.lastFourDigits}',
          createdAt: card.createdAt,
          isPinnedToTop: card.isPinnedToTop,
          isPinnedToHomescreen: card.isPinnedToHomescreen,
        )),
        ...i.map((idDoc) => VaultItem(
          type: VaultItemType.id,
          item: idDoc,
          id: idDoc.id!,
          nickname: idDoc.nickname,
          subtitle: idDoc.idType,
          createdAt: idDoc.createdAt,
          isPinnedToTop: idDoc.isPinnedToTop,
          isPinnedToHomescreen: idDoc.isPinnedToHomescreen,
        )),
      ]..sort((a, b) {
          if (a.isPinnedToTop && !b.isPinnedToTop) return -1;
          if (!a.isPinnedToTop && b.isPinnedToTop) return 1;
          final cmp = b.createdAt.compareTo(a.createdAt);
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
        });
      return merged;
    }).value ?? [];
  });
});

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  int _selectedCardIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortMode = 'newest'; // newest, oldest, alphabetical
  String _selectedCategory = 'all'; // all, cards, ids

  @override
  Widget build(BuildContext context) {
    final allItemsAsync = ref.watch(allVaultItemsProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: loc.searchItems,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                    _selectedCardIndex = 0; // Reset selection on search
                  });
                },
              )
            : Text(loc.myVault, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFFC9A961)),
            tooltip: _isSearching ? loc.searchStopLabel : loc.searchLabel,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFFC9A961)),
            tooltip: loc.sortLabel,
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: allItemsAsync.when(
        data: (allItems) {
          if (allItems.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing background
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF2BD1C4).withOpacity(0.14),
                                    const Color(0xFF2BD1C4).withOpacity(0),
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            ),
                            // Rotated Cards
                            Transform.translate(
                              offset: const Offset(34, 30),
                              child: Transform.rotate(
                                angle: 10 * 3.14159 / 180,
                                child: _buildMockCard(opacity: 0.55),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-30, 12),
                              child: Transform.rotate(
                                angle: -8 * 3.14159 / 180,
                                child: _buildMockCard(opacity: 0.75),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(2, -14),
                              child: Transform.rotate(
                                angle: 2 * 3.14159 / 180,
                                child: _buildMockCard(opacity: 1.0),
                              ),
                            ),
                            // Sparkle Icon in Center
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFC9A961),
                              size: 42,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.myVault,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.welcomeSubtitle, // Closest match, can add custom if needed
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 286,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE7D4A0), Color(0xFFC9A961), Color(0xFF9C7C41)],
                            stops: [0.0, 0.55, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddCardScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: Color(0xFF0A0C11), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.addNewCard,
                                style: const TextStyle(
                                  color: Color(0xFF0A0C11),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Karde holds cards and IDs, and an empty vault offering
                      // only one of them tells a new user the other does not
                      // exist. Second rather than side by side because the gold
                      // button is the page's one strong element and splitting it
                      // in half would leave neither looking like the way in.
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 286,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddIdScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: KardeColors.champagneGold.withOpacity(0.55),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.badge_outlined,
                                  color: KardeColors.champagneGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                loc.addNewId,
                                style: const TextStyle(
                                  color: KardeColors.champagneGold,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.offlineBadge,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
            );
          }

          List<VaultItem> filteredItems = _applyFilters(allItems);

          // Sorting — pinned items always float to top, then sort within each group
          filteredItems.sort((a, b) {
            // Pinned items first
            if (a.isPinnedToTop && !b.isPinnedToTop) return -1;
            if (!a.isPinnedToTop && b.isPinnedToTop) return 1;
            // Within same pin group, apply user's chosen sort
            if (_sortMode == 'newest') {
              return b.createdAt.compareTo(a.createdAt);
            } else if (_sortMode == 'oldest') {
              return a.createdAt.compareTo(b.createdAt);
            } else if (_sortMode == 'alphabetical') {
              return a.nickname.compareTo(b.nickname);
            }
            return 0;
          });

          if (_selectedCardIndex >= filteredItems.length) {
            _selectedCardIndex = 0;
          }
          
          final selectedItem = filteredItems.isNotEmpty ? filteredItems[_selectedCardIndex] : null;

          return Column(
            children: [
              // Hero Card or ID Viewer. When the chosen category is empty this
              // slot keeps its place and shows the placeholder illustration, so
              // switching to an empty tab does not collapse the layout and jump
              // the category tabs up the screen.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: selectedItem == null
                    ? _buildEmptyPreview()
                    : Column(
                        children: [
                          selectedItem.type == VaultItemType.card
                              ? DecryptableCard(
                                  key: ValueKey('card_${selectedItem.id}'),
                                  card: selectedItem.item as VirtualCard,
                                )
                              : DecryptableIdCard(
                                  key: ValueKey('id_${selectedItem.id}'),
                                  idDoc: selectedItem.item as VirtualId,
                                ),
                          _buildHeroHint(selectedItem),
                        ],
                      ),
              ),

              // Category Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryTab(loc.allFilter, 'all'),
                      const SizedBox(width: 12),
                      _buildCategoryTab(loc.cardsFilter, 'cards'),
                      const SizedBox(width: 12),
                      _buildCategoryTab(loc.idsFilter, 'ids'),
                    ],
                  ),
                ),
              ),

              // Compact List or Empty State
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildCategoryEmptyPrompt(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = index == _selectedCardIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCardIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFC9A961).withOpacity(0.1))
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFC9A961).withOpacity(0.5) : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: Theme.of(context).brightness == Brightness.light && !isSelected ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.type == VaultItemType.card ? Icons.credit_card : Icons.badge_outlined, 
                                color: Theme.of(context).textTheme.bodyMedium?.color, 
                                size: 20
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nickname.toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontFamily: 'Roboto Mono',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.isPinnedToTop)
                                  const Icon(Icons.push_pin, color: Color(0xFFC9A961), size: 16),
                                if (item.isPinnedToHomescreen)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(Icons.home, color: Color(0xFFC9A961), size: 16),
                                  ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFFC9A961), size: 20)
                                else
                                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 20),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
                                  onSelected: (value) {
                                    if (value == 'pin_top') {
                                      _togglePinToTop(item);
                                    } else if (value == 'pin_home') {
                                      _togglePinToHomescreen(item);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'pin_top',
                                      child: Text(item.isPinnedToTop ? loc.unpinFromTop : loc.pinToTop),
                                    ),
                                    PopupMenuItem(
                                      value: 'pin_home',
                                      child: Text(item.isPinnedToHomescreen ? loc.unpinFromHomescreen : loc.pinToHomescreen),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(loc.genericError)),
      ),
      // Hidden whenever nothing is listed. An empty category already offers its
      // own "Add New …" button, and the floating + both overlapped that button
      // and duplicated it.
      floatingActionButton: _applyFilters(allItemsAsync.valueOrNull ?? const []).isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showAddOptionsBottomSheet();
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _togglePinToTop(VaultItem item) async {
    if (item.type == VaultItemType.card) {
      final VirtualCard card = item.item;
      final updatedCard = card.copyWith(isPinnedToTop: !card.isPinnedToTop);
      await ref.read(cardsProvider.notifier).updateCard(updatedCard);
    } else if (item.type == VaultItemType.id) {
      final VirtualId idDoc = item.item;
      final updatedId = idDoc.copyWith(isPinnedToTop: !idDoc.isPinnedToTop);
      await ref.read(idsProvider.notifier).updateId(updatedId);
    }
  }

  Future<void> _togglePinToHomescreen(VaultItem item) async {
    final bool newValue;
    
    if (item.type == VaultItemType.card) {
      final VirtualCard card = item.item;
      newValue = !card.isPinnedToHomescreen;
    } else {
      final VirtualId idDoc = item.item;
      newValue = !idDoc.isPinnedToHomescreen;
    }
    
    // If pinning (not unpinning), unpin all other items first
    if (newValue) {
      final cards = ref.read(cardsProvider).valueOrNull ?? [];
      final ids = ref.read(idsProvider).valueOrNull ?? [];
      final cardRepo = ref.read(cardRepositoryProvider);
      final idRepo = ref.read(idRepositoryProvider);
      
      for (final c in cards) {
        if (c.isPinnedToHomescreen && c.id != item.id) {
          await cardRepo.updateCard(c.copyWith(isPinnedToHomescreen: false));
        }
      }
      for (final i in ids) {
        if (i.isPinnedToHomescreen && i.id != item.id) {
          await idRepo.updateId(i.copyWith(isPinnedToHomescreen: false));
        }
      }
    }
    
    // Now toggle the selected item
    if (item.type == VaultItemType.card) {
      final VirtualCard card = item.item;
      await ref.read(cardsProvider.notifier).updateCard(card.copyWith(isPinnedToHomescreen: newValue));
    } else {
      final VirtualId idDoc = item.item;
      await ref.read(idsProvider.notifier).updateId(idDoc.copyWith(isPinnedToHomescreen: newValue));
    }
    
    // Force refresh both providers since we may have updated items in both tables
    ref.invalidate(cardsProvider);
    ref.invalidate(idsProvider);
  }

  void _showAddOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(AppLocalizations.of(context)!.addItem, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Color(0xFFC9A961)),
                title: Text(AppLocalizations.of(context)!.addACard, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge, color: Color(0xFFC9A961)),
                title: Text(AppLocalizations.of(context)!.addAnId, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIdScreen()));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Applies the active category tab and search query.
  ///
  /// Shared by the list and by the floating action button, so the two can never
  /// disagree about whether anything is on screen. Sorting stays with the list,
  /// which is the only caller that cares about order.
  List<VaultItem> _applyFilters(List<VaultItem> allItems) {
    Iterable<VaultItem> items = allItems;

    if (_selectedCategory == 'cards') {
      items = items.where((i) => i.type == VaultItemType.card);
    } else if (_selectedCategory == 'ids') {
      items = items.where((i) => i.type == VaultItemType.id);
    }

    if (_searchQuery.isNotEmpty) {
      items = items.where((i) =>
          i.nickname.toLowerCase().contains(_searchQuery) ||
          i.subtitle.toLowerCase().contains(_searchQuery));
    }

    return items.toList();
  }

  /// Placeholder that stands in for the hero card when the chosen category is
  /// empty.
  ///
  /// Sized to roughly the height of a real card so the category tabs beneath it
  /// stay put: switching to an empty tab should not make the rest of the screen
  /// jump upwards. It reuses the all-empty vault's glow and fanned mock cards so
  /// an empty tab reads as the same app rather than a second, plainer design.
  /// The strip under the hero card.
  ///
  /// Solves two things the card face cannot say for itself. Tapping it opens the
  /// details page, which was entirely undiscoverable — nothing on screen
  /// suggested the card was a button at all. And an attached photo was invisible
  /// until you got to that page, so there was no way to tell which items had one.
  ///
  /// The photo badge reads [hasPhoto], which is stored unencrypted precisely so
  /// this can be drawn without spending an authentication prompt per item.
  Widget _buildHeroHint(VaultItem item) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final hasPhoto = item.type == VaultItemType.card
        ? (item.item as VirtualCard).hasPhoto
        : (item.item as VirtualId).hasPhoto;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasPhoto) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: KardeColors.champagneGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: KardeColors.champagneGold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_back_outlined,
                      size: 13, color: KardeColors.champagneGold),
                  const SizedBox(width: 5),
                  Text(
                    loc.photoBadge,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: KardeColors.champagneGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          Icon(Icons.touch_app_outlined, size: 13, color: muted),
          const SizedBox(width: 5),
          Text(
            loc.tapCardForDetails,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview() {
    final bool isIds = _selectedCategory == 'ids';
    final bool isSearching = _searchQuery.isNotEmpty;

    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2BD1C4).withOpacity(0.14),
                  const Color(0xFF2BD1C4).withOpacity(0),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(30, 26),
            child: Transform.rotate(
              angle: 10 * 3.14159 / 180,
              child: _buildMockCard(opacity: 0.55),
            ),
          ),
          Transform.translate(
            offset: const Offset(-26, 10),
            child: Transform.rotate(
              angle: -8 * 3.14159 / 180,
              child: _buildMockCard(opacity: 0.75),
            ),
          ),
          Transform.translate(
            offset: const Offset(2, -12),
            child: Transform.rotate(
              angle: 2 * 3.14159 / 180,
              child: _buildMockCard(opacity: 1.0),
            ),
          ),
          Icon(
            isSearching
                ? Icons.search_off
                : (isIds ? Icons.badge_outlined : Icons.credit_card),
            color: const Color(0xFFC9A961),
            size: 40,
          ),
        ],
      ),
    );
  }

  /// Empty state for a category that has nothing in it, while the vault as a
  /// whole is not empty.
  ///
  /// The all-empty vault has its own full-page illustration earlier in `build`.
  /// This is the case where the user holds cards but no IDs (or the reverse) and
  /// switches to the empty tab. It previously fell through to a single centred
  /// line of hardcoded `Colors.white` text — which said nothing about what to do
  /// next, and was invisible against the light theme's near-white background.
  ///
  /// A search that matches nothing is a different situation from a category that
  /// is genuinely empty: the fix there is to change the query, not to add an
  /// item, so it gets its own wording and no add button.
  ///
  /// The illustration lives in the hero slot above the tabs
  /// ([_buildEmptyPreview]); this is only the wording and the call to action,
  /// which sit in the list area where the items themselves would be. Splitting
  /// them keeps the screen's normal three-part shape — preview, tabs, list —
  /// instead of replacing the whole page with a takeover.
  Widget _buildCategoryEmptyPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final bool isSearching = _searchQuery.isNotEmpty;
    final bool isIds = _selectedCategory == 'ids';

    final String title;
    final String message;
    if (isSearching) {
      title = loc.noMatches;
      message = loc.noMatchesMessage(_searchQuery);
    } else if (isIds) {
      title = loc.noIdsYet;
      message = loc.noIdsYetMessage;
    } else {
      title = loc.noCardsYet;
      message = loc.noCardsYetMessage;
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 32),
              Container(
                width: 286,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE7D4A0), Color(0xFFC9A961), Color(0xFF9C7C41)],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isIds ? const AddIdScreen() : const AddCardScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Color(0xFF0A0C11), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isIds ? loc.addNewId : loc.addNewCard,
                        style: const TextStyle(
                          color: Color(0xFF0A0C11),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String label, String value, {bool disabled = false}) {
    final isSelected = _selectedCategory == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: disabled ? null : () {
        setState(() {
          _selectedCategory = value;
          _selectedCardIndex = 0;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC9A961) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (isDark ? const Color(0xFF0A0C11) : Colors.white) 
                : (disabled ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3) : Theme.of(context).colorScheme.onSurface),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(AppLocalizations.of(context)!.sortItems, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildSortOption(AppLocalizations.of(context)!.sortNewestFirst, 'newest'),
              _buildSortOption(AppLocalizations.of(context)!.sortOldestFirst, 'oldest'),
              _buildSortOption(AppLocalizations.of(context)!.sortAlphabetical, 'alphabetical'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortMode == value;
    return ListTile(
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFC9A961) : Theme.of(context).colorScheme.onSurface)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFC9A961)) : null,
      onTap: () {
        setState(() {
          _sortMode = value;
          _selectedCardIndex = 0;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildMockCard({required double opacity}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 200,
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
            width: 1.3,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 26,
              child: Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A961).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 80,
              child: Container(
                width: 90,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
