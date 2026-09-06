import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database.dart';
import '../domain/virtual_card.dart';
import '../../backup/data/auto_backup_recorder.dart';

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

  /// Saves a card and records it in the automatic backup.
  ///
  /// [secrets] is the payload as it was before encryption. It is passed in
  /// rather than read back out of the vault because reading it back would cost
  /// an authentication prompt, and one prompt per save is precisely what makes
  /// an automatic backup unusable.
  ///
  /// Null means "do not touch the backup for this one" — for callers that have
  /// no plaintext to give, such as a restore, which writes its own records.
  ///
  /// The backup is written after the vault, and its failure is allowed out. A
  /// card that saved but did not reach the backup is a card the user believes is
  /// safe in two places and is safe in one.
  Future<void> addCard(VirtualCard card, {Map<String, dynamic>? secrets}) async {
    final repository = ref.read(cardRepositoryProvider);
    final id = await repository.insertCard(card);
    ref.invalidateSelf();
    if (secrets == null) return;
    await ref
        .read(autoBackupRecorderProvider)
        .cardSaved(card.copyWith(id: id), secrets);
  }

  Future<void> updateCard(VirtualCard card, {Map<String, dynamic>? secrets}) async {
    final repository = ref.read(cardRepositoryProvider);
    await repository.updateCard(card);
    ref.invalidateSelf();
    if (secrets == null) return;
    await ref.read(autoBackupRecorderProvider).cardSaved(card, secrets);
  }

  Future<void> deleteCard(int id) async {
    final repository = ref.read(cardRepositoryProvider);
    await repository.deleteCard(id);
    ref.invalidateSelf();
    await ref.read(autoBackupRecorderProvider).cardDeleted(id);
  }
}

final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<VirtualCard>>(CardsNotifier.new);
