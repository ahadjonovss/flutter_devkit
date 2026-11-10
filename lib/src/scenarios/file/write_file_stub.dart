import 'dart:typed_data';

/// Writes [bytes] to [path] where the file picker leaves that to the caller.
/// Nothing to do on the web, where saving downloads the file.
Future<void> writePickedFile(String path, Uint8List bytes) async {}
