import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_registry.dart';
import 'package:flutter_devkit/src/scenarios/scenario_storage.dart';

/// Scenario routes and the current selection, reached through
/// `DevKit.scenarios`.
///
/// Routes come from two places: [register], called by the host's code, and
/// custom routes QA adds at runtime ([addCustomCase], [importCustom]). Custom
/// routes are saved to [storage] and come back with [load]; selections are
/// never saved. Listeners are notified whenever the list of routes changes.
class Scenarios extends ChangeNotifier {
  /// Creates scenarios that are active while [isEnabled] returns true.
  Scenarios({required bool Function() isEnabled, ScenarioStorage? storage})
    : _isEnabled = isEnabled,
      storage = storage ?? const SharedPreferencesScenarioStorage();

  /// Prefix of the ids of routes added at runtime.
  static const String customPrefix = 'custom.';

  /// Version written into exported JSON.
  static const int exportVersion = 1;

  final bool Function() _isEnabled;
  final Set<String> _customIds = {};

  /// Where custom routes are saved.
  ScenarioStorage storage;

  /// Saves and opens scenario files; null leaves only copy and paste.
  ScenarioFiles? files;

  /// Receives save failures; `DevKit.init` points it at `DevKit.log`.
  void Function(String message) log = debugPrint;

  /// Registered routes.
  final ScenarioRegistry registry = ScenarioRegistry();

  /// Current selection.
  final ScenarioCubit cubit = ScenarioCubit();

  /// Whether scenarios are active.
  bool get enabled => _isEnabled();

  /// Routes added at runtime, in the order they were added.
  List<ScenarioRoute> get customRoutes => [
    for (final route in registry.routes)
      if (_customIds.contains(route.id)) route,
  ];

  /// Whether the route with [routeId] was added at runtime.
  bool isCustom(String routeId) => _customIds.contains(routeId);

  /// Registers [routes]; ignored while disabled. See
  /// [ScenarioRegistry.register].
  void register(List<ScenarioRoute> routes) {
    if (!enabled) return;
    registry.register(routes);
    notifyListeners();
  }

  /// The route and case to apply to the request in [options]: the first
  /// matching route with a selected case that still exists, custom routes
  /// first.
  (ScenarioRoute, ScenarioCase)? activeFor(RequestOptions options) {
    final selection = cubit.state.byRoute;
    final matches = registry.allMatches(options).toList();
    // A route QA added on the device wins over one from the app's code.
    final ordered = [...matches.where((r) => isCustom(r.id)), ...matches.where((r) => !isCustom(r.id))];
    for (final route in ordered) {
      final caseId = selection[route.id];
      if (caseId == null) continue;
      final scenario = route.caseById(caseId);
      if (scenario != null) return (route, scenario);
    }
    return null;
  }

  /// Loads the custom routes saved in [storage]. Ignored while disabled.
  Future<void> load() async {
    if (!enabled) return;
    final json = await storage.read();
    if (json == null || json.isEmpty) return;
    _import(json);
    notifyListeners();
  }

  /// Adds [scenario] to the custom route matching like [match], creating the
  /// route with [label] when there is none, and saves. Returns the route.
  ScenarioRoute addCustomCase({required RouteMatcher match, required String label, required ScenarioCase scenario}) {
    final existing = customRoutes.where((r) => r.match.sameAs(match)).firstOrNull;
    final ScenarioRoute route;
    if (existing == null) {
      route = ScenarioRoute(id: newCustomId(), label: label, match: match, cases: [scenario]);
    } else {
      route = existing.copyWith(cases: [...existing.cases.where((c) => c.id != scenario.id), scenario]);
    }
    registry.put(route);
    _customIds.add(route.id);
    _changed();
    return route;
  }

  /// Removes the custom route with [routeId] and its selection.
  void removeCustomRoute(String routeId) {
    if (!_customIds.remove(routeId)) return;
    registry.remove(routeId);
    cubit.clear(routeId);
    _changed();
  }

  /// Removes one case of a custom route; the route goes too when it was the
  /// last case.
  void removeCustomCase(String routeId, String caseId) {
    final route = registry.byId(routeId);
    if (route == null || !_customIds.contains(routeId)) return;
    final cases = route.cases.where((c) => c.id != caseId).toList();
    if (cases.isEmpty) return removeCustomRoute(routeId);
    registry.put(route.copyWith(cases: cases));
    if (cubit.state.byRoute[routeId] == caseId) cubit.clear(routeId);
    _changed();
  }

  /// Custom routes as indented JSON, for sharing with [importCustom].
  String exportCustom() => const JsonEncoder.withIndent('  ').convert({
    'version': exportVersion,
    'routes': [for (final route in customRoutes) route.toJson()],
  });

  /// Adds the routes in [json], written by [exportCustom], and saves.
  ///
  /// A route with the id of a custom route replaces it; one with the id of a
  /// route registered in code is skipped. Throws [FormatException] when
  /// [json] is not a valid export, in which case nothing changes.
  ({int imported, int skipped}) importCustom(String json) {
    final result = _import(json);
    _changed();
    return result;
  }

  /// A fresh id for a custom route or case.
  static String newCustomId() => '$customPrefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  ({int imported, int skipped}) _import(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('DevKit: scenarios must be JSON.');
    }
    final Object? list = switch (decoded) {
      {'routes': final Object? routes} => routes,
      List() => decoded,
      _ => null,
    };
    if (list is! List) throw const FormatException('DevKit: expected an object with a "routes" list.');
    // Parse everything before touching the registry, so a bad entry changes
    // nothing.
    final routes = [for (final r in list) ScenarioRoute.fromJson(r)];
    var imported = 0;
    var skipped = 0;
    for (final route in routes) {
      if (registry.byId(route.id) != null && !_customIds.contains(route.id)) {
        skipped++;
        continue;
      }
      registry.put(route);
      _customIds.add(route.id);
      imported++;
    }
    return (imported: imported, skipped: skipped);
  }

  void _changed() {
    notifyListeners();
    unawaited(storage.write(exportCustom()).catchError((Object e) => log('Could not save scenarios: $e')));
  }
}
