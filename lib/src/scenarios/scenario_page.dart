import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';
import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';

part 'components/route_tile.dart';

/// Lets QA pick a case per route, or reset everything.
class ScenarioPage extends StatelessWidget {
  /// Creates the page; prefer [open].
  const ScenarioPage({super.key});

  /// Pushes the page on the root navigator.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(data: devKitTheme, child: const ScenarioPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = DevKit.scenarios;
    final routes = scenarios.registry.routes;

    return BlocBuilder<ScenarioCubit, ScenarioState>(
      bloc: scenarios.cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Backend scenarios'),
          actions: [
            TextButton(onPressed: state.count == 0 ? null : scenarios.cubit.clearAll, child: const Text('Reset all')),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: routes.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final route = routes[index];
            return _RouteTile(
              route: route,
              selectedCaseId: state.byRoute[route.id],
              onChanged: (caseId) => scenarios.cubit.select(route.id, caseId),
            );
          },
        ),
      ),
    );
  }
}
