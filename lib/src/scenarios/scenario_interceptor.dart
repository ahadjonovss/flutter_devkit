import 'package:dio/dio.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

/// Dio interceptor that adds the selected case's headers to matching
/// requests.
///
/// Add it after auth and before logging. Requests pass through untouched while
/// DevKit is disabled or nothing is selected for their route.
class ScenarioInterceptor extends Interceptor {
  /// Uses [scenarios], or `DevKit.scenarios` when null, and logs through [log],
  /// or `DevKit.log` when null.
  ScenarioInterceptor({Scenarios? scenarios, void Function(String message)? log})
    : _scenarios = scenarios ?? DevKit.scenarios,
      _log = log ?? DevKit.log;

  /// Key of the `route → case` tag in `options.extra` and `response.extra`.
  static const String extraKey = 'devkit.scenario';

  final Scenarios _scenarios;
  final void Function(String message) _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_scenarios.enabled) return handler.next(options);

    final route = _scenarios.registry.firstMatch(options);
    if (route == null) return handler.next(options);

    final caseId = _scenarios.cubit.state.byRoute[route.id];
    if (caseId == null) return handler.next(options);

    final scenario = route.caseById(caseId);
    if (scenario == null) return handler.next(options);

    scenario.headers.forEach((k, v) => options.headers[k] = v);
    final tag = '${route.id} → ${scenario.id}';
    options.extra[extraKey] = tag;
    _log('Scenario applied: $tag (${options.method} ${options.uri.path})');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final tag = response.requestOptions.extra[extraKey];
    if (tag != null) {
      response.extra[extraKey] = tag;
      _log('Scenario response: $tag ← ${response.statusCode}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final tag = err.requestOptions.extra[extraKey];
    if (tag != null) {
      err.response?.extra[extraKey] = tag;
      _log('Scenario response: $tag ← ${err.response?.statusCode ?? err.type.name}');
    }
    handler.next(err);
  }
}
