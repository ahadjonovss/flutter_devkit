import 'package:flutter_bloc/flutter_bloc.dart';

class ScenarioState {
  const ScenarioState([this.byRoute = const {}]);

  final Map<String, String> byRoute;

  int get count => byRoute.length;
}

class ScenarioCubit extends Cubit<ScenarioState> {
  ScenarioCubit() : super(const ScenarioState());

  void select(String routeId, String? caseId) {
    if (caseId == null) return clear(routeId);
    emit(ScenarioState({...state.byRoute, routeId: caseId}));
  }

  void clear(String routeId) {
    if (!state.byRoute.containsKey(routeId)) return;
    emit(ScenarioState({...state.byRoute}..remove(routeId)));
  }

  void clearAll() {
    if (state.count == 0) return;
    emit(const ScenarioState());
  }
}
