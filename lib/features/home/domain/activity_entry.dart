/// What happened to an item in the vault.
///
/// Deliberately coarse. "Changed" covers a corrected digit and a replaced photo
/// alike, because recording which field moved would mean writing the field names
/// of somebody's passport into a log, and the whole value of this log is that it
/// can be read without unlocking anything.
enum ActivityKind {
  cardAdded,
  cardChanged,
  cardRemoved,
  documentAdded,
  documentChanged,
  documentRemoved,
}

/// One line of the vault's history.
///
/// The user asked for this: "the notification should also show when cards are
/// deleted, added or modified, maybe it can also help as a log."
///
/// It answers a question nothing else in Karde could — *did I do that?* A vault
/// whose contents can change silently is a vault you have to take on trust, and
/// the one entry that matters is the one the owner does not recognise.
///
/// What it holds is the nickname and nothing else. That is already in the clear
/// in the row it describes, and on the home screen, so the log gives away
/// nothing new. The card number, the security code and the document number are
/// never written here, which is why the log itself needs no key to read.
///
/// It is history, not a demand. Activity never badges the bell — see
/// `unseenAlertsProvider`. Mixing "you added a card" into a count that means
/// "something needs your attention" would make the count mean nothing, and the
/// day the count matters is the day it must still be believed.
class ActivityEntry {
  const ActivityEntry({
    required this.kind,
    required this.name,
    required this.at,
  });

  final ActivityKind kind;

  /// The item's nickname, as it was at the time.
  ///
  /// Copied rather than looked up, because half of these describe items that no
  /// longer exist — and "something was deleted" is the least useful version of
  /// the one entry a person most needs to read.
  final String name;

  final DateTime at;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'name': name,
        'at': at.toIso8601String(),
      };

  /// Null for anything unrecognised, so one bad row cannot take the log with it.
  static ActivityEntry? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'];
    final name = json['name'];
    final at = json['at'];
    if (kindName is! String || name is! String || at is! String) return null;

    final when = DateTime.tryParse(at);
    if (when == null) return null;

    for (final kind in ActivityKind.values) {
      if (kind.name == kindName) {
        return ActivityEntry(kind: kind, name: name, at: when);
      }
    }
    return null;
  }
}
