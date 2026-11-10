import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_registry.dart';

class Scenarios {
  Scenarios({required bool Function() isEnabled}) : _isEnabled = isEnabled;

  final bool Function() _isEnabled;
  final ScenarioRegistry registry = ScenarioRegistry();
  final ScenarioCubit cubit = ScenarioCubit();

  bool get enabled => _isEnabled();

  void register(List<ScenarioRoute> routes) {
    if (!enabled) return;
    registry.register(routes);
  }
}
