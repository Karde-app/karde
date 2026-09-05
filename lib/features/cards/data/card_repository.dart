import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database.dart';
import '../domain/virtual_card.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(DatabaseHelper.instance);
});

class CardRepository {
  final DatabaseHelper _dbHelper;

  CardRepository(this._dbHelper);

  Future<int> insertCard(VirtualCard card) async {
    return await _dbHelper.insertCard(card.toMap());
  }

  /// Every card, without its encrypted payload — see [payloadFor].
  Future<List<VirtualCard>> getAllCards() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryCardSummaries();
    return List.generate(maps.length, (i) {
      return VirtualCard.fromMap(maps[i]);
    });
  }

  /// The encrypted payload for [card], fetched on demand.
  ///
  /// Cards from [getAllCards] carry no payload, because it holds the card photo
  /// and would be dragged through memory on every list rebuild. Every caller of
  /// this is about to raise an authentication prompt, so a read by primary key is
  /// free by comparison.
  ///
  /// Falls back to whatever the model already holds, so a card that did come with
  /// its payload — from a fresh save, or a test — still works.
  Future<String> payloadFor(VirtualCard card) async {
    if (card.encryptedData.isNotEmpty) return card.encryptedData;
    final id = card.id;
    if (id == null) return '';
    return await _dbHelper.cardPayload(id) ?? '';
  }

  Future<int> updateCard(VirtualCard card) async {
    return await _dbHelper.updateCard(card.toMap());
  }

  Future<int> deleteCard(int id) async {
    return await _dbHelper.deleteCard(id);
  }
}

// FIX 6: AsyncNotifierProvider replaces FutureProvider for proper auto-refresh
class CardsNotifier extends AsyncNotifier<List<VirtualCard>> {
  @override
  Future<List<VirtualCard>> build() async {
    final repository = ref.watch(cardRepositoryProvider);
    return repository.getAllCards();
  }

  Future<void> addCard(VirtualCard card) async {
    final repository = ref.read(cardRepositoryProvider);
    await repository.insertCard(card);
    ref.invalidateSelf();
  }

  Future<void> updateCard(VirtualCard card) async {
    final repository = ref.read(cardRepositoryProvider);
    await repository.updateCard(card);
    ref.invalidateSelf();
  }

  Future<void> deleteCard(int id) async {
    final repository = ref.read(cardRepositoryProvider);
    await repository.deleteCard(id);
    ref.invalidateSelf();
  }
}

final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<VirtualCard>>(CardsNotifier.new);
