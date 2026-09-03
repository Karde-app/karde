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
    return await _dbHelper.insert(card.toMap());
  }

  Future<List<VirtualCard>> getAllCards() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAllRows();
    return List.generate(maps.length, (i) {
      return VirtualCard.fromMap(maps[i]);
    });
  }

  Future<int> updateCard(VirtualCard card) async {
    return await _dbHelper.update(card.toMap());
  }

  Future<int> deleteCard(int id) async {
    return await _dbHelper.delete(id);
  }
}

final cardsProvider = FutureProvider<List<VirtualCard>>((ref) async {
  final repository = ref.watch(cardRepositoryProvider);
  return repository.getAllCards();
});
