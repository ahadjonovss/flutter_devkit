import 'package:dio/dio.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

class ScenarioInterceptor extends Interceptor {
  ScenarioInterceptor({Scenarios? scenarios, void Function(String message)? log})
      : _scenarios = scenarios ?? DevKit.scenarios,
        _log = log ?? DevKit.log;

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
