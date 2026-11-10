import 'package:dio/dio.dart';

import 'package:flutter_devkit/src/scenarios/scenario.dart';

/// Every route registered for scenarios.
class ScenarioRegistry {
  /// Creates an empty registry.
  ScenarioRegistry();

  final List<ScenarioRoute> _routes = [];

  /// Registered routes, in registration order.
  List<ScenarioRoute> get routes => List.unmodifiable(_routes);

  /// Adds [routes]. Throws [StateError] on a route id that is already
  /// registered or a case id repeated within a route.
  void register(List<ScenarioRoute> routes) {
    for (final route in routes) {
      if (_routes.any((r) => r.id == route.id)) {
        throw StateError('DevKit: scenario route "${route.id}" is already registered.');
      }
      final caseIds = <String>{};
      for (final scenario in route.cases) {
        if (!caseIds.add(scenario.id)) {
          throw StateError('DevKit: case "${scenario.id}" is declared twice in route "${route.id}".');
        }
      }
      _routes.add(route);
    }
  }

  /// The first registered route matching the request in [options].
  ScenarioRoute? firstMatch(RequestOptions options) {
    final path = options.uri.path;
    for (final route in _routes) {
      if (route.match.matches(options.method, path)) return route;
    }
    return null;
  }

  /// The route with [id], or null.
  ScenarioRoute? byId(String id) {
    for (final route in _routes) {
      if (route.id == id) return route;
    }
    return null;
  }

  /// Removes every route.
  void clear() => _routes.clear();
}
