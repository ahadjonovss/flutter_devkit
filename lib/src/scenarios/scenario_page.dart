import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';
import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_form_page.dart';
import 'package:flutter_devkit/src/scenarios/scenario_storage.dart';

part 'components/route_tile.dart';

/// Lets QA pick a case per route, or reset everything.
class ScenarioPage extends StatefulWidget {
  /// Creates the page; prefer [open].
  const ScenarioPage({super.key});

  /// Pushes the page on the root navigator.
  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => const DevKitTheme(child: ScenarioPage())));
  }

  @override
  State<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends State<ScenarioPage> {
  /// Routes beyond which the page shows a search field.
  static const int _searchThreshold = 5;

  String _query = '';

  @override
  Widget build(BuildContext context) {
    // Custom routes come and go while the page is open.
    return ListenableBuilder(listenable: DevKit.scenarios, builder: (context, _) => _buildPage(context));
  }

  Future<void> _export() async {
    final scenarios = DevKit.scenarios;
    final count = scenarios.customRoutes.length;
    if (count == 0) return _snack('No custom scenarios to export');
    final files = scenarios.files;
    if (files == null) {
      await Clipboard.setData(ClipboardData(text: scenarios.exportCustom()));
      return _snack('$count route(s) copied as JSON');
    }
    try {
      if (await files.save('devkit_scenarios.json', scenarios.exportCustom())) _snack('$count route(s) exported');
    } on Object catch (e) {
      _snack('Could not export: $e');
    }
  }

  Future<void> _importFile(ScenarioFiles files) async {
    try {
      final json = await files.pick();
      if (json == null) return;
      _reportImport(DevKit.scenarios.importCustom(json));
    } on FormatException catch (e) {
      _snack('Not a DevKit scenarios file: ${e.message.replaceFirst('DevKit: ', '')}');
    } on Object catch (e) {
      _snack('Could not import: $e');
    }
  }

  Future<void> _importText() async {
    final result = await showDialog<({int imported, int skipped})>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (result != null) _reportImport(result);
  }

  void _reportImport(({int imported, int skipped}) result) {
    _snack(
      [
        '${result.imported} route(s) imported',
        if (result.skipped > 0) '${result.skipped} skipped (id used by the app)',
      ].join(' · '),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteRoute(ScenarioRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text('"${route.label}" and its ${route.cases.length} case(s) are removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed ?? false) DevKit.scenarios.removeCustomRoute(route.id);
  }

  static PopupMenuItem<void Function()> _menuItem(void Function() action, IconData icon, String label) {
    return PopupMenuItem(
      value: action,
      child: ListTile(leading: Icon(icon), title: Text(label), contentPadding: EdgeInsets.zero),
    );
  }

  Widget _buildPage(BuildContext context) {
    final scenarios = DevKit.scenarios;
    final cubit = scenarios.cubit;
    final all = scenarios.registry.routes;
    final needle = _query.toLowerCase();
    final routes = needle.isEmpty
        ? all
        : [
            for (final r in all)
              if (r.label.toLowerCase().contains(needle) || r.id.toLowerCase().contains(needle)) r,
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend scenarios'),
        actions: [
          BlocSelector<ScenarioCubit, ScenarioState, int>(
            bloc: cubit,
            selector: (state) => state.count,
            builder: (context, count) =>
                TextButton(onPressed: count == 0 ? null : cubit.clearAll, child: const Text('Reset all')),
          ),
          PopupMenuButton<void Function()>(
            tooltip: 'More',
            onSelected: (action) => action(),
            itemBuilder: (_) {
              final files = scenarios.files;
              return [
                if (files != null) _menuItem(() => _importFile(files), Icons.file_open_outlined, 'Import from file'),
                _menuItem(_importText, Icons.content_paste_rounded, 'Paste JSON'),
                const PopupMenuDivider(),
                files == null
                    ? _menuItem(_export, Icons.copy_all_rounded, 'Copy as JSON')
                    : _menuItem(_export, Icons.save_alt_rounded, 'Export as file'),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScenarioFormPage.open(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add scenario'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList.list(
              children: [
                BlocSelector<ScenarioCubit, ScenarioState, int>(
                  bloc: cubit,
                  selector: (state) => state.count,
                  builder: (context, count) => _Summary(count: count),
                ),
                if (all.length > _searchThreshold)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search routes',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (routes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DevKitEmpty(
                icon: Icons.alt_route_rounded,
                message: all.isEmpty
                    ? 'No routes yet.\nAdd one here or from a request in the HTTP inspector, or import JSON.'
                    : 'No routes match "$_query"',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: routes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  // Each tile listens to its own route only, so picking a case
                  // rebuilds one card rather than the whole list.
                  return BlocSelector<ScenarioCubit, ScenarioState, String?>(
                    key: ValueKey(route.id),
                    bloc: cubit,
                    selector: (state) => state.byRoute[route.id],
                    builder: (context, selectedCaseId) => _RouteTile(
                      route: route,
                      selectedCaseId: selectedCaseId,
                      onChanged: (caseId) => cubit.select(route.id, caseId),
                      custom: scenarios.isCustom(route.id),
                      onDeleteCase: (caseId) => scenarios.removeCustomCase(route.id, caseId),
                      onDeleteRoute: () => _deleteRoute(route),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  late final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      Navigator.pop(context, DevKit.scenarios.importCustom(_controller.text));
    } on FormatException catch (e) {
      setState(() => _error = e.message.replaceFirst('DevKit: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Import scenarios'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste JSON exported from DevKit. Routes with the same id are replaced.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 6,
              maxLines: 12,
              style: devKitMono(theme.textTheme.bodySmall),
              decoration: InputDecoration(hintText: '{"version": 1, "routes": [...]}', errorText: _error),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Import')),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overridden = count > 0;
    final color = overridden ? devKitWarningColor : const Color(0xFF2E9D4A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(overridden ? Icons.warning_amber_rounded : Icons.cloud_done_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              overridden ? '$count route(s) overridden' : 'All routes hit the real backend',
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
