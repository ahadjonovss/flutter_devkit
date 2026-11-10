import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_page.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_page.dart';
import 'package:flutter_devkit/src/panel/devkit_item.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';

/// The dev panel: built-in tools and the host's items.
class DevKitPanel extends StatelessWidget {
  /// Creates the panel; items open their pages from [hostContext].
  const DevKitPanel({super.key, required this.hostContext});

  /// Context the panel was opened from, still valid after it closes.
  final BuildContext hostContext;

  /// Opens the panel as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    final theme = devKitThemeFor(context);
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      builder: (_) => Theme(
        data: theme,
        child: DevKitPanel(hostContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = DevKit.items;
    final hasScenarios = DevKit.scenarios.registry.routes.isNotEmpty;
    final hasInspector = DevKit.inspector.attached;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IconTile(icon: Icons.developer_mode_rounded, color: theme.colorScheme.primary, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DevKit', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Developer tools',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (hasScenarios || hasInspector) ...[
              const _SectionLabel('Tools'),
              _Group(
                children: [
                  if (hasScenarios)
                    _ToolTile(
                      icon: Icons.alt_route_rounded,
                      color: devKitWarningColor,
                      title: 'Backend scenarios',
                      subtitle: BlocBuilder<ScenarioCubit, ScenarioState>(
                        bloc: DevKit.scenarios.cubit,
                        buildWhen: (a, b) => a.count != b.count,
                        builder: (_, state) => Text(
                          state.count == 0 ? 'All routes hit the real backend' : '${state.count} route(s) overridden',
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScenarioPage.open(hostContext);
                      },
                    ),
                  if (hasInspector)
                    _ToolTile(
                      icon: Icons.network_check_rounded,
                      color: theme.colorScheme.primary,
                      title: 'HTTP inspector',
                      subtitle: StreamBuilder<List<HttpRecord>>(
                        initialData: DevKit.inspector.records,
                        stream: DevKit.inspector.stream,
                        builder: (_, snapshot) {
                          final records = snapshot.data!;
                          final errors = records.where((r) => r.isError).length;
                          return Text(
                            ['${records.length} request(s) captured', if (errors > 0) '$errors error(s)'].join(' · '),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        InspectorPage.open(hostContext);
                      },
                    ),
                ],
              ),
            ],
            if (items.isNotEmpty) ...[const _SectionLabel('App'), ..._buildItems(context, items)],
          ],
        ),
      ),
    );
  }

  /// Host items in their order: runs of tiles share a card, custom items stand
  /// on their own.
  List<Widget> _buildItems(BuildContext context, List<DevKitItem> items) {
    final color = Theme.of(context).colorScheme.tertiary;
    final widgets = <Widget>[];
    final tiles = <Widget>[];

    void flush() {
      if (tiles.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _Group(children: [...tiles]),
        ),
      );
      tiles.clear();
    }

    for (final item in items) {
      final builder = item.builder;
      if (builder != null) {
        flush();
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: builder(context)));
        continue;
      }
      tiles.add(
        _ToolTile(
          icon: item.icon ?? Icons.extension_rounded,
          color: color,
          title: item.title,
          subtitle: item.subtitle == null ? null : Text(item.subtitle!),
          onTap: () {
            Navigator.pop(context);
            item.onTap?.call(hostContext);
          },
        ),
      );
    }
    flush();
    return widgets;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tiles in one card, separated by inset dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[if (index > 0) const Divider(indent: 68), child],
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.color, required this.title, this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final Widget? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconTile(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
