import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database.dart';
import '../domain/virtual_id.dart';

final idRepositoryProvider = Provider<IdRepository>((ref) {
  return IdRepository(DatabaseHelper.instance);
});

class IdRepository {
  final DatabaseHelper _dbHelper;

  IdRepository(this._dbHelper);

  Future<int> insertId(VirtualId idDoc) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableIds, idDoc.toMap());
  }

  /// Every ID document, without its encrypted payload — see [payloadFor].
  Future<List<VirtualId>> getAllIds() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryIdSummaries();
    return List.generate(maps.length, (i) {
      return VirtualId.fromMap(maps[i]);
    });
  }

  /// The encrypted payload for [idDoc], fetched on demand. See
  /// `CardRepository.payloadFor` for why the list does not carry it.
  Future<String> payloadFor(VirtualId idDoc) async {
    if (idDoc.encryptedData.isNotEmpty) return idDoc.encryptedData;
    final id = idDoc.id;
    if (id == null) return '';
    return await _dbHelper.idPayload(id) ?? '';
  }

  Future<int> updateId(VirtualId idDoc) async {
    // Routed through the helper so an update carrying no payload cannot blank the
    // stored one — see DatabaseHelper._keepPayload.
    return await _dbHelper.updateId(idDoc.toMap());
  }

  Future<int> deleteId(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableIds, where: 'id = ?', whereArgs: [id]);
  }
}

class IdsNotifier extends AsyncNotifier<List<VirtualId>> {
  @override
  Future<List<VirtualId>> build() async {
    final repository = ref.watch(idRepositoryProvider);
    return repository.getAllIds();
  }

  Future<void> addId(VirtualId idDoc) async {
    final repository = ref.read(idRepositoryProvider);
    await repository.insertId(idDoc);
    ref.invalidateSelf();
  }

  Future<void> updateId(VirtualId idDoc) async {
    final repository = ref.read(idRepositoryProvider);
    await repository.updateId(idDoc);
    ref.invalidateSelf();
  }

  Future<void> deleteId(int id) async {
    final repository = ref.read(idRepositoryProvider);
    await repository.deleteId(id);
    ref.invalidateSelf();
  }
}

final idsProvider = AsyncNotifierProvider<IdsNotifier, List<VirtualId>>(IdsNotifier.new);
