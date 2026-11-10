import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_store.dart';
import 'package:flutter_devkit/src/scenarios/scenario_interceptor.dart';

/// Dio interceptor that records each request and its response in an
/// [InspectorStore].
///
/// Add it after `ScenarioInterceptor` so it sees scenario headers and tags.
/// Nothing is recorded while DevKit is disabled.
class InspectorInterceptor extends Interceptor {
  /// Records into [store], or `DevKit.inspector` when null.
  ///
  /// [redact] runs on the URL, each `name: value` header line, both bodies and
  /// the error text before anything is stored. Bodies are cut at
  /// [maxBodyLength] characters.
  InspectorInterceptor({InspectorStore? store, String Function(String value)? redact, this.maxBodyLength = 64 * 1024})
    : _store = store ?? DevKit.inspector,
      _redact = redact ?? _identity {
    _store.attach();
  }

  static const String _idKey = 'devkit.inspector.id';

  final InspectorStore _store;
  final String Function(String value) _redact;

  /// Longest body kept, in characters; longer bodies are truncated.
  final int maxBodyLength;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_store.enabled) _start(options);
    handler.next(options);
  }

  HttpRecord _start(RequestOptions options) {
    final id = _store.nextId();
    options.extra[_idKey] = id;
    final record = HttpRecord(
      id: id,
      method: options.method,
      url: _redact(options.uri.toString()),
      startedAt: DateTime.now(),
      requestHeaders: _headers(options.headers.map((k, v) => MapEntry(k, '$v'))),
      requestBody: _body(options.data),
      scenario: options.extra[ScenarioInterceptor.extraKey] as String?,
    );
    _store.add(record);
    return record;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _complete(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = err.message;
    _complete(err.requestOptions, err.response, error: message == null ? err.type.name : '${err.type.name}: $message');
    handler.next(err);
  }

  void _complete(RequestOptions options, Response? response, {String? error}) {
    final id = options.extra[_idKey];
    final HttpRecord? record;
    if (id is int) {
      record = _store.byId(id);
    } else {
      // An earlier interceptor answered before this one saw the request, e.g.
      // a scenario mock: record it now.
      record = _store.enabled ? _start(options) : null;
    }
    if (record == null) return;
    _store.update(
      record.complete(
        statusCode: response?.statusCode,
        responseHeaders: response == null
            ? const []
            : _headers(response.headers.map.map((k, v) => MapEntry(k, v.join(', ')))),
        responseBody: _body(response?.data),
        error: error == null ? null : _redact(error),
      ),
    );
  }

  RecordHeaders _headers(Map<String, String> headers) {
    return [for (final entry in headers.entries) _splitHeader(_redact('${entry.key}: ${entry.value}'))];
  }

  MapEntry<String, String> _splitHeader(String line) {
    final index = line.indexOf(': ');
    if (index == -1) return MapEntry(line, '');
    return MapEntry(line.substring(0, index), line.substring(index + 2));
  }

  String? _body(Object? data) {
    final text = _stringify(data);
    if (text == null) return null;
    // Redaction runs on a slice twice the kept length rather than the whole
    // body: a multi-megabyte response would otherwise go through every
    // pattern. The margin keeps a secret that straddles the cut recognisable.
    final slice = text.length > maxBodyLength * 2 ? text.substring(0, maxBodyLength * 2) : text;
    final redacted = _redact(slice);
    if (redacted.length <= maxBodyLength && slice.length == text.length) return redacted;
    final kept = redacted.length <= maxBodyLength ? redacted : redacted.substring(0, maxBodyLength);
    return '$kept\n… truncated (${text.length} chars)';
  }

  String? _stringify(Object? data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is List<int>) return '<binary ${data.length} bytes>';
    if (data is FormData) {
      return [
        for (final field in data.fields) '${field.key}=${field.value}',
        for (final file in data.files) '${file.key}=<file ${file.value.filename ?? ''}>',
      ].join('\n');
    }
    if (data is ResponseBody || data is Stream) return '<stream>';
    if (data is Map || data is List) {
      try {
        return jsonEncode(data);
      } on JsonUnsupportedObjectError {
        return data.toString();
      }
    }
    return data.toString();
  }

  static String _identity(String value) => value;
}
