import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/settings_repository.dart';
import '../domain/activity_entry.dart';

/// The vault's recent history, newest first.
///
/// In preferences rather than the database, and unencrypted, for the same reason
/// the entries hold only nicknames: a log you need a fingerprint to read is a log
/// nobody checks, and the point of it is to be glanced at. See [ActivityEntry]
/// for what is and is not written here.
///
/// Capped, and deliberately short. This is "did I do that?", answered over the
/// last few weeks of use — not an audit trail, which would need to survive the
/// person trying to hide something and cannot, since anyone who can open Karde
/// can also clear it.
class ActivityLogNotifier extends StateNotifier<List<ActivityEntry>> {
  ActivityLogNotifier(this._repository) : super(_read(_repository));

  final SettingsRepository _repository;

  /// How many entries are kept. Fifty is a few months for most people and a few
  /// weeks for somebody actively tidying their vault.
  static const int maxEntries = 50;

  static List<ActivityEntry> _read(SettingsRepository repository) {
    final raw = repository.getActivityLog();
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(ActivityEntry.fromJson)
          .whereType<ActivityEntry>()
          .toList();
    } catch (_) {
      // Unreadable is the same as empty. Nothing here is worth an error message.
      return const [];
    }
  }

  Future<void> record(ActivityKind kind, String name) async {
    final entry = ActivityEntry(
      kind: kind,
      name: name.trim().isEmpty ? '—' : name.trim(),
      at: DateTime.now(),
    );
    state = [entry, ...state].take(maxEntries).toList();
    await _save();
  }

  Future<void> clear() async {
    state = const [];
    await _save();
  }

  Future<void> _save() async {
    await _repository.setActivityLog(
      jsonEncode(state.map((entry) => entry.toJson()).toList()),
    );
  }
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, List<ActivityEntry>>((ref) {
  return ActivityLogNotifier(ref.watch(settingsRepositoryProvider));
});
