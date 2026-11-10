import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

/// Dio interceptor that adds the selected case's headers to matching
/// requests, and answers them locally when the case has a [ScenarioMock].
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

  /// Key set to true in `response.extra` when the response came from a
  /// [ScenarioMock] rather than the backend.
  static const String mockedKey = 'devkit.scenario.mocked';

  final Scenarios _scenarios;
  final void Function(String message) _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_scenarios.enabled) return handler.next(options);

    final active = _scenarios.activeFor(options);
    if (active == null) return handler.next(options);
    final (route, scenario) = active;

    scenario.headers.forEach((k, v) => options.headers[k] = v);
    final tag = '${route.id} → ${scenario.id}';
    options.extra[extraKey] = tag;

    final mock = scenario.mock;
    if (mock == null) {
      _log('Scenario applied: $tag (${options.method} ${options.uri.path})');
      return handler.next(options);
    }

    _log('Scenario mocked: $tag (${options.method} ${options.uri.path}) → ${mock.statusCode}');
    void answer() {
      final response = _response(options, mock);
      // Following interceptors still see the answer, so it is logged and
      // recorded like a real one.
      if (options.validateStatus(mock.statusCode)) {
        handler.resolve(response, true);
      } else {
        handler.reject(
          DioException.badResponse(statusCode: mock.statusCode, requestOptions: options, response: response),
          true,
        );
      }
    }

    if (mock.delay == Duration.zero) return answer();
    Future<void>.delayed(mock.delay, answer);
  }

  Response<Object?> _response(RequestOptions options, ScenarioMock mock) {
    final headers = Headers.fromMap({
      for (final e in mock.headers.entries) e.key: [e.value],
    });
    return Response<Object?>(
      requestOptions: options,
      statusCode: mock.statusCode,
      headers: headers,
      data: _data(options, mock),
      extra: {mockedKey: true},
    );
  }

  /// [mock]'s body in the shape the request asked for with `responseType`.
  Object? _data(RequestOptions options, ScenarioMock mock) {
    final body = mock.body;
    return switch (options.responseType) {
      ResponseType.plain => body,
      ResponseType.bytes => utf8.encode(body),
      ResponseType.stream => ResponseBody.fromString(body, mock.statusCode),
      ResponseType.json => _decodeJson(body),
    };
  }

  static Object? _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
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
