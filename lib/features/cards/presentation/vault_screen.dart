import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/virtual_card.dart';
import '../data/card_repository.dart';
import 'widgets/decryptable_card.dart';
import 'add_card_screen.dart';

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
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                    _selectedCardIndex = 0; // Reset selection on search
                  });
                },
              )
            : const Text('My Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFFC9A961)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFFC9A961)),
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
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
                      const Text(
                        'Your vault is empty',
                        style: TextStyle(
                          color: Color(0xFFF4F1EA),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first card and Karde will keep\nit encrypted, offline, forever.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9AA1B0),
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
                            children: const [
                              Icon(Icons.add, color: Color(0xFF0A0C11), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add your first item',
                                style: TextStyle(
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
                      const SizedBox(height: 16),
                      const Text(
                        'Nothing ever leaves this device',
                        style: TextStyle(
                          color: Color(0xFF5C6472),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
            );
          }

          List<VirtualCard> filteredCards = List.from(cards);

          // Category Filter
          if (_selectedCategory == 'ids') {
            filteredCards = [];
          }

          // Search Filter
          if (_searchQuery.isNotEmpty) {
            filteredCards = filteredCards.where((c) => 
              c.nickname.toLowerCase().contains(_searchQuery) ||
              c.cardBrand.toLowerCase().contains(_searchQuery)
            ).toList();
          }

          // Sorting
          if (_sortMode == 'newest') {
            filteredCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else if (_sortMode == 'oldest') {
            filteredCards.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          } else if (_sortMode == 'alphabetical') {
            filteredCards.sort((a, b) => a.nickname.compareTo(b.nickname));
          }

          if (_selectedCardIndex >= filteredCards.length) {
            _selectedCardIndex = 0;
          }
          
          final selectedCard = filteredCards.isNotEmpty ? filteredCards[_selectedCardIndex] : null;

          return Column(
            children: [
              // Hero Card
              if (selectedCard != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: DecryptableCard(
                    key: ValueKey(selectedCard.id),
                    card: selectedCard,
                  ),
                ),
              
              // Category Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryTab('All', 'all'),
                      const SizedBox(width: 12),
                      _buildCategoryTab('Cards', 'cards'),
                      const SizedBox(width: 12),
                      _buildCategoryTab('IDs · Soon', 'ids', disabled: true),
                    ],
                  ),
                ),
              ),

              // Compact List or Empty State
              Expanded(
                child: filteredCards.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No items found matching "$_searchQuery"' : 'No items in this category',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = filteredCards[index];
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
                          color: isSelected ? Colors.white.withOpacity(0.05) : const Color(0xFF161A23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFC9A961).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.credit_card, color: Colors.white70, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.nickname.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${card.cardBrand} •••• ${card.lastFourDigits}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontFamily: 'Roboto Mono',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFFC9A961), size: 20)
                            else
                              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
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
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: cardsAsync.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCardScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCategoryTab(String label, String value, {bool disabled = false}) {
    final isSelected = _selectedCategory == value;
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
          color: isSelected ? const Color(0xFFC9A961) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A0C11) : (disabled ? Colors.white.withOpacity(0.3) : Colors.white),
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
      backgroundColor: const Color(0xFF161A23),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Sort Items', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildSortOption('Newest First', 'newest'),
              _buildSortOption('Oldest First', 'oldest'),
              _buildSortOption('Alphabetical (A-Z)', 'alphabetical'),
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
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFC9A961) : Colors.white)),
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
