import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database.dart';
import '../domain/virtual_id.dart';
import '../../backup/data/auto_backup_recorder.dart';
import '../../home/data/activity_log.dart';
import '../../home/domain/activity_entry.dart';

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

  /// Saves an ID and records it in the automatic backup.
  ///
  /// [payload] is the record as it was before encryption. See
  /// [CardsNotifier.addCard] for why it is handed in rather than read back.
  Future<void> addId(VirtualId idDoc, {Map<String, dynamic>? payload}) async {
    final repository = ref.read(idRepositoryProvider);
    final id = await repository.insertId(idDoc);
    ref.invalidateSelf();
    // See CardsNotifier.addCard: one choke point, one log entry.
    _log(ActivityKind.documentAdded, idDoc.nickname);
    if (payload == null) return;
    await ref
        .read(autoBackupRecorderProvider)
        .idSaved(idDoc.copyWith(id: id), payload);
  }

  Future<void> updateId(VirtualId idDoc, {Map<String, dynamic>? payload}) async {
    final repository = ref.read(idRepositoryProvider);
    await repository.updateId(idDoc);
    ref.invalidateSelf();
    _log(ActivityKind.documentChanged, idDoc.nickname);
    if (payload == null) return;
    await ref.read(autoBackupRecorderProvider).idSaved(idDoc, payload);
  }

  Future<void> deleteId(int id) async {
    final repository = ref.read(idRepositoryProvider);
    final name =
        state.valueOrNull?.where((doc) => doc.id == id).firstOrNull?.nickname;

    await repository.deleteId(id);
    ref.invalidateSelf();
    _log(ActivityKind.documentRemoved, name ?? '');
    await ref.read(autoBackupRecorderProvider).idDeleted(id);
  }

  /// Never allowed to fail a save. See [CardsNotifier].
  void _log(ActivityKind kind, String name) {
    try {
      ref.read(activityLogProvider.notifier).record(kind, name);
    } catch (_) {}
  }
}

final idsProvider = AsyncNotifierProvider<IdsNotifier, List<VirtualId>>(IdsNotifier.new);
