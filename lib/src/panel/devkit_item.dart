import 'package:flutter/widgets.dart';

/// An entry the host app adds to the dev panel with `DevKit.addItem`.
class DevKitItem {
  /// A list tile that closes the panel and calls [onTap].
  const DevKitItem({
    required this.title,
    this.subtitle,
    this.icon,
    required void Function(BuildContext context) this.onTap,
  }) : builder = null;

  /// An arbitrary widget built by [builder], shown in the panel as is.
  const DevKitItem.custom({required WidgetBuilder this.builder})
    : title = '',
      subtitle = null,
      icon = null,
      onTap = null;

  /// Tile title. Empty for [DevKitItem.custom].
  final String title;

  /// Optional second line of the tile.
  final String? subtitle;

  /// Optional leading icon of the tile.
  final IconData? icon;

  /// Called with the context the panel was opened from, after the panel
  /// closes. Null for [DevKitItem.custom].
  final void Function(BuildContext context)? onTap;

  /// Builds the custom widget. Null for a tile.
  final WidgetBuilder? builder;
}
