import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_registry.dart';

/// Scenario routes and the current selection, reached through
/// `DevKit.scenarios`.
class Scenarios {
  /// Creates scenarios that are active while [isEnabled] returns true.
  Scenarios({required bool Function() isEnabled}) : _isEnabled = isEnabled;

  final bool Function() _isEnabled;

  /// Registered routes.
  final ScenarioRegistry registry = ScenarioRegistry();

  /// Current selection.
  final ScenarioCubit cubit = ScenarioCubit();

  /// Whether scenarios are active.
  bool get enabled => _isEnabled();

  /// Registers [routes]; ignored while disabled. See
  /// [ScenarioRegistry.register].
  void register(List<ScenarioRoute> routes) {
    if (!enabled) return;
    registry.register(routes);
  }
}
