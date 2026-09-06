import 'dart:convert';

import 'package:flutter/services.dart';

/// The user closed the folder picker without choosing.
class BackupFolderNotChosen implements Exception {
  const BackupFolderNotChosen();
}

/// Karde cannot reach the folder backups go to.
///
/// One exception for every way it can happen — the folder deleted or moved, the
/// permission revoked in Android's settings, the storage full, a memory card
/// pulled out, a cloud provider offline — because they all mean the same thing
/// to the person holding the phone and all need the same answer from them.
///
/// This is the failure that matters most in the whole feature. A backup that
/// quietly stopped working months ago is worse than no backup at all, because
/// its owner believes they are covered and has stopped thinking about it.
class BackupFolderUnavailable implements Exception {
  final String? details;
  const BackupFolderUnavailable([this.details]);

  @override
  String toString() => 'BackupFolderUnavailable($details)';
}

/// Where the user chose to keep their backups.
class BackupFolderChoice {
  const BackupFolderChoice({required this.uri, required this.label});

  /// Android's handle for the folder. Meaningless to a person; never shown.
  final String uri;

  /// What to show the user, e.g. "Documents/Karde".
  final String label;
}

/// Reading and writing inside the folder the user picked.
///
/// Karde needs somewhere it can write on every change without asking each time.
/// Its own private directory would need no permission and is useless, because
/// Android deletes it when the app is uninstalled — precisely the moment a
/// backup exists for. A folder the user picks survives that, is visible to them
/// in their own file manager, and if they choose a synced folder the backup
/// leaves the phone by itself.
///
/// It also asks for no permission in the manifest. The grant comes from the user
/// pointing at a folder, which is better for them and one less thing to declare
/// on the Play Store data-safety form.
class BackupFolderService {
  static const MethodChannel _channel =
      MethodChannel('com.ibank.security/backup');

  /// Asks the user to choose, and keeps the right to write there afterwards.
  Future<BackupFolderChoice> choose() async {
    try {
      final raw = await _channel.invokeMethod<String>('chooseBackupFolder');
      if (raw == null) throw const BackupFolderNotChosen();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BackupFolderChoice(
        uri: json['uri'] as String,
        label: json['label'] as String,
      );
    } on PlatformException catch (e) {
      if (e.code == 'FOLDER_CANCELLED') throw const BackupFolderNotChosen();
      throw BackupFolderUnavailable(e.message ?? e.code);
    }
  }

  /// Whether the folder is still there and still writable.
  ///
  /// Asked rather than assumed. Every part of this arrangement can be taken away
  /// without the app being told, and the whole point of an automatic backup is
  /// that nobody is watching it.
  Future<bool> isUsable(String treeUri) async {
    try {
      return await _channel.invokeMethod<bool>(
            'backupFolderUsable',
            {'treeUri': treeUri},
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> write(String treeUri, String name, String content) async {
    await _invoke('writeBackupFile', {
      'treeUri': treeUri,
      'name': name,
      'data': content,
    });
  }

  /// The file's contents, or null if it is not there.
  Future<String?> read(String treeUri, String name) async {
    return _invoke('readBackupFile', {'treeUri': treeUri, 'name': name});
  }

  /// Every file name in the folder, so older copies can be pruned.
  Future<List<String>> list(String treeUri) async {
    final raw = await _invoke('listBackupFiles', {'treeUri': treeUri});
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<bool> delete(String treeUri, String name) async {
    final raw = await _invoke('deleteBackupFile', {
      'treeUri': treeUri,
      'name': name,
    });
    return raw == 'true';
  }

  Future<String?> _invoke(String method, Map<String, dynamic> arguments) async {
    try {
      return await _channel.invokeMethod<String>(method, arguments);
    } on PlatformException catch (e) {
      throw BackupFolderUnavailable(e.message ?? e.code);
    }
  }
}
