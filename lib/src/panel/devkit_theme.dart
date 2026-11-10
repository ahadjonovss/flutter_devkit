import 'package:flutter/material.dart';

import 'package:flutter_devkit/src/inspector/http_record.dart';

const Color _seed = Color(0xFF5B4FD6);

/// Light theme of DevKit's own pages, independent of the host app's theme.
final ThemeData devKitTheme = _buildTheme(Brightness.light);

/// Dark counterpart of [devKitTheme].
final ThemeData devKitDarkTheme = _buildTheme(Brightness.dark);

/// The DevKit theme matching the device's light or dark setting.
ThemeData devKitThemeFor(BuildContext context) =>
    MediaQuery.platformBrightnessOf(context) == Brightness.dark ? devKitDarkTheme : devKitTheme;

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final radius = BorderRadius.circular(14);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: base.textTheme.labelLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1, thickness: 1),
    tabBarTheme: TabBarThemeData(
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.6),
      labelStyle: base.textTheme.titleSmall,
      indicatorSize: TabBarIndicatorSize.label,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: radius)),
  );
}

/// Wraps [child] in the DevKit theme that matches the device brightness.
class DevKitTheme extends StatelessWidget {
  /// Themes [child].
  const DevKitTheme({super.key, required this.child});

  /// The DevKit page.
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(data: devKitThemeFor(context), child: child);
}

/// Colour that marks overridden routes and scenario-tagged requests.
const Color devKitWarningColor = Color(0xFFE65100);

/// Colour of a record's status: pending, error, redirect or success.
Color devKitStatusColor(HttpRecord record) {
  if (record.isPending) return Colors.grey;
  if (record.isError) return const Color(0xFFD32F2F);
  if ((record.statusCode ?? 0) >= 300) return const Color(0xFF1E88E5);
  return const Color(0xFF2E9D4A);
}

/// Colour of an HTTP [method] badge.
Color devKitMethodColor(String method) => switch (method.toUpperCase()) {
  'GET' => const Color(0xFF1E88E5),
  'POST' => const Color(0xFF2E9D4A),
  'PUT' || 'PATCH' => const Color(0xFFEF6C00),
  'DELETE' => const Color(0xFFD32F2F),
  _ => const Color(0xFF757575),
};

/// [style] in a monospace font that exists on every platform.
TextStyle? devKitMono(TextStyle? style) =>
    style?.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['Menlo', 'Courier New', 'Roboto Mono']);

/// Formats [time] as `HH:mm:ss`.
String devKitTime(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

/// Formats [duration] as `850 ms` or `1.2 s`.
String devKitDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  return ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0)} s';
}

/// Formats a length in characters as `512 B`, `3.4 KB` or `1.2 MB`.
String devKitSize(int length) {
  if (length < 1024) return '$length B';
  if (length < 1024 * 1024) return '${(length / 1024).toStringAsFixed(1)} KB';
  return '${(length / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// A small tinted pill, e.g. an HTTP method or status code.
class DevKitBadge extends StatelessWidget {
  /// Shows [label] in [color] on a tint of it.
  const DevKitBadge({super.key, required this.label, required this.color, this.minWidth = 0});

  /// Badge text.
  final String label;

  /// Text colour; the background is a tint of it.
  final Color color;

  /// Minimum width, so a column of badges lines up.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: devKitMono(
          Theme.of(context).textTheme.labelSmall,
        )?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }
}

/// A titled card used for sections of DevKit pages.
class DevKitSection extends StatelessWidget {
  /// Shows [child] under [title], with optional [trailing] actions.
  const DevKitSection({super.key, required this.title, required this.child, this.trailing});

  /// Section title.
  final String title;

  /// Widget at the end of the title row, e.g. a copy button.
  final Widget? trailing;

  /// Section content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, trailing == null ? 12 : 4, 4, trailing == null ? 8 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: child),
          ],
        ),
      ),
    );
  }
}

/// An icon with a centred message, for empty lists.
class DevKitEmpty extends StatelessWidget {
  /// Shows [icon] above [message].
  const DevKitEmpty({super.key, required this.icon, required this.message});

  /// Large faded icon.
  final IconData icon;

  /// Text under the icon.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
