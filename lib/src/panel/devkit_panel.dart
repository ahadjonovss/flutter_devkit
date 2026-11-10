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
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => Theme(
        data: devKitTheme,
        child: DevKitPanel(hostContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = DevKit.items;
    final hasScenarios = DevKit.scenarios.registry.routes.isNotEmpty;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 8),
              if (hasScenarios)
                ListTile(
                  leading: const Icon(Icons.alt_route_rounded),
                  title: const Text('Backend scenarios'),
                  subtitle: BlocBuilder<ScenarioCubit, ScenarioState>(
                    bloc: DevKit.scenarios.cubit,
                    builder: (_, state) => Text(
                      state.count == 0 ? 'All routes hit the real backend' : '${state.count} route(s) overridden',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScenarioPage.open(hostContext);
                  },
                ),
              if (DevKit.inspector.attached)
                ListTile(
                  leading: const Icon(Icons.network_check_rounded),
                  title: const Text('HTTP inspector'),
                  subtitle: StreamBuilder<List<HttpRecord>>(
                    initialData: DevKit.inspector.records,
                    stream: DevKit.inspector.stream,
                    builder: (_, snapshot) => Text('${snapshot.data!.length} request(s) captured'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    InspectorPage.open(hostContext);
                  },
                ),
              for (final item in items) _buildItem(context, item),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, DevKitItem item) {
    final builder = item.builder;
    if (builder != null) {
      return Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: builder(context));
    }
    return ListTile(
      leading: item.icon == null ? null : Icon(item.icon),
      title: Text(item.title),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      onTap: () {
        Navigator.pop(context);
        item.onTap?.call(hostContext);
      },
    );
  }
}
