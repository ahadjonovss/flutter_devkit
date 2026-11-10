import 'package:flutter/widgets.dart';

class DevKitItem {
  const DevKitItem({
    required this.title,
    this.subtitle,
    this.icon,
    required void Function(BuildContext context) this.onTap,
  }) : builder = null;

  const DevKitItem.custom({required WidgetBuilder this.builder})
      : title = '',
        subtitle = null,
        icon = null,
        onTap = null;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final void Function(BuildContext context)? onTap;
  final WidgetBuilder? builder;
}
