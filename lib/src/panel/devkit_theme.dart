import 'package:flutter/material.dart';

import 'package:flutter_devkit/src/inspector/http_record.dart';

/// Theme of DevKit's own pages, independent of the host app's theme.
final ThemeData devKitTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF5B4FD6),
  brightness: Brightness.light,
);

/// Colour that marks overridden routes and scenario-tagged requests.
const Color devKitWarningColor = Color(0xFFE65100);

/// Colour of a record's status: pending, error, redirect or success.
Color devKitStatusColor(HttpRecord record) {
  if (record.isPending) return Colors.grey;
  if (record.isError) return const Color(0xFFC62828);
  if ((record.statusCode ?? 0) >= 300) return const Color(0xFF1565C0);
  return const Color(0xFF2E7D32);
}

/// Formats [time] as `HH:mm:ss`.
String devKitTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}
