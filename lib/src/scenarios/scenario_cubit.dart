import 'package:flutter_bloc/flutter_bloc.dart';

/// Selected case id per route id. A route without an entry hits the real
/// backend.
class ScenarioState {
  /// Creates a state with the given selection.
  const ScenarioState([this.byRoute = const {}]);

  /// Route id to selected case id.
  final Map<String, String> byRoute;

  /// Number of overridden routes.
  int get count => byRoute.length;
}

/// Holds the scenario selection. It lives in memory only.
class ScenarioCubit extends Cubit<ScenarioState> {
  /// Starts with nothing selected.
  ScenarioCubit() : super(const ScenarioState());

  /// Selects [caseId] for [routeId], or clears the route when null.
  void select(String routeId, String? caseId) {
    if (caseId == null) return clear(routeId);
    emit(ScenarioState({...state.byRoute, routeId: caseId}));
  }

  /// Sends [routeId] back to the real backend.
  void clear(String routeId) {
    if (!state.byRoute.containsKey(routeId)) return;
    emit(ScenarioState({...state.byRoute}..remove(routeId)));
  }

  /// Sends every route back to the real backend.
  void clearAll() {
    if (state.count == 0) return;
    emit(const ScenarioState());
  }
}
