import 'package:flutter/services.dart';

import '../security/system_interaction_guard.dart';

/// The user dismissed the system file picker without choosing anything.
class FileTransferCancelled implements Exception {
  const FileTransferCancelled();
}

/// The chosen document could not be read or written.
class FileTransferFailure implements Exception {
  final String message;
  const FileTransferFailure(this.message);
}

/// Reads and writes a single user-chosen document through Android's Storage
/// Access Framework.
///
/// Karde holds no storage permission and does not browse the filesystem. The
/// user picks one document in the system picker, and the app is handed access to
/// exactly that document and nothing else.
class FileTransferService {
  static const MethodChannel _channel = MethodChannel('com.ibank.security/files');

  /// Asks the user where to save, writes [content] there, and returns the
  /// display name of the file that was written.
  ///
  /// Throws [FileTransferCancelled] if the picker was dismissed.
  Future<String> save({
    required String suggestedName,
    required String content,
  }) {
    // The picker is a system window on top of Karde, so the auto-lock timer must
    // stand down — a user browsing to a Drive folder can easily take longer than
    // the grace period.
    return SystemInteractionGuard.run(() async {
      try {
        final name = await _channel.invokeMethod<String>('saveFile', {
          'suggestedName': suggestedName,
          'content': content,
        });
        if (name == null) throw const FileTransferCancelled();
        return name;
      } on PlatformException catch (e) {
        throw FileTransferFailure(e.message ?? e.code);
      }
    });
  }

  /// Asks the user to choose a file and returns its contents as text.
  ///
  /// Throws [FileTransferCancelled] if the picker was dismissed.
  Future<String> open() {
    return SystemInteractionGuard.run(() async {
      try {
        final content = await _channel.invokeMethod<String>('openFile');
        if (content == null) throw const FileTransferCancelled();
        return content;
      } on PlatformException catch (e) {
        throw FileTransferFailure(e.message ?? e.code);
      }
    });
  }
}
