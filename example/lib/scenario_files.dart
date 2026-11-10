import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_devkit/flutter_devkit.dart';

/// Scenario files through file_picker. Lives in the app, so the package itself
/// stays free of file plugins.
class FilePickerScenarioFiles implements ScenarioFiles {
  const FilePickerScenarioFiles();

  @override
  Future<bool> save(String fileName, String json) async {
    final bytes = utf8.encode(json);
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    // The web downloads the file and returns no path.
    if (kIsWeb) return true;
    if (path == null) return false;
    // On desktop the dialog only picks a path; mobile has already written it.
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) await File(path).writeAsBytes(bytes);
    return true;
  }

  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = result?.files.singleOrNull?.bytes;
    return bytes == null ? null : utf8.decode(bytes);
  }
}
