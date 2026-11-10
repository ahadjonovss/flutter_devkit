import 'dart:io';
import 'dart:typed_data';

/// Writes [bytes] to [path] where the file picker leaves that to the caller.
///
/// On desktop the save dialog only returns a path; on Android and iOS the
/// picker has already written the bytes.
Future<void> writePickedFile(String path, Uint8List bytes) async {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) await File(path).writeAsBytes(bytes);
}
