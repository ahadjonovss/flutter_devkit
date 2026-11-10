import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';
import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';

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
          const SizedBox(width: 4),
        ],
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
                message: all.isEmpty ? 'No routes registered' : 'No routes match "$_query"',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
