import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_page.dart';

class ScenarioBanner extends StatelessWidget {
  const ScenarioBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!DevKit.enabled) return child;

    // The tree keeps the same shape whether the strip is shown or not: moving
    // [child] to another parent would recreate the app's Router and everything
    // above its navigator.
    return BlocBuilder<ScenarioCubit, ScenarioState>(
      bloc: DevKit.scenarios.cubit,
      builder: (context, state) {
        final visible = state.count > 0;
        return Column(
          children: [
            if (visible) _Strip(count: state.count),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visible,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: devKitWarningColor,
      child: InkWell(
        onTap: _openScenarios,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            width: double.infinity,
            height: 22,
            child: Center(
              child: Text(
                '$count route(s) overridden · tap to change',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openScenarios() {
    final context = DevKit.navigatorKey?.currentContext;
    if (context == null) {
      DevKit.log('ScenarioBanner: pass navigatorKey to DevKit.init() to open scenarios from the strip.');
      return;
    }
    ScenarioPage.open(context);
  }
}
