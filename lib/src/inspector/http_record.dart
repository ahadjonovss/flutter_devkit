import 'dart:convert';

typedef RecordHeaders = List<MapEntry<String, String>>;

class HttpRecord {
  const HttpRecord({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    required this.requestHeaders,
    this.requestBody,
    this.scenario,
    this.statusCode,
    this.responseHeaders = const [],
    this.responseBody,
    this.duration,
    this.error,
  });

  final int id;
  final String method;
  final String url;
  final DateTime startedAt;
  final RecordHeaders requestHeaders;
  final String? requestBody;
  final String? scenario;
  final int? statusCode;
  final RecordHeaders responseHeaders;
  final String? responseBody;
  final Duration? duration;
  final String? error;

  bool get isPending => duration == null;

  bool get isFailed => !isPending && statusCode == null;

  bool get isError => isFailed || (statusCode ?? 0) >= 400;

  String get path {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  HttpRecord complete({
    int? statusCode,
    RecordHeaders responseHeaders = const [],
    String? responseBody,
    String? error,
  }) {
    return HttpRecord(
      id: id,
      method: method,
      url: url,
      startedAt: startedAt,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      scenario: scenario,
      statusCode: statusCode,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      duration: DateTime.now().difference(startedAt),
      error: error,
    );
  }

  String toCurl() {
    final buffer = StringBuffer("curl -X $method '${_escape(url)}'");
    for (final header in requestHeaders) {
      buffer.write(" \\\n  -H '${_escape('${header.key}: ${header.value}')}'");
    }
    final body = requestBody;
    if (body != null && body.isNotEmpty) {
      buffer.write(" \\\n  --data-raw '${_escape(body)}'");
    }
    return buffer.toString();
  }

  String toText() {
    final buffer = StringBuffer()
      ..writeln('$method $url')
      ..writeln('Status: ${statusCode ?? error ?? 'pending'}')
      ..writeln('Time: ${startedAt.toIso8601String()}');
    if (duration != null) buffer.writeln('Duration: ${duration!.inMilliseconds} ms');
    if (scenario != null) buffer.writeln('Scenario: $scenario');
    buffer
      ..writeln()
      ..writeln('--- Request headers ---');
    for (final header in requestHeaders) {
      buffer.writeln('${header.key}: ${header.value}');
    }
    if (requestBody != null) {
      buffer
        ..writeln()
        ..writeln('--- Request body ---')
        ..writeln(prettyBody(requestBody!));
    }
    buffer
      ..writeln()
      ..writeln('--- Response headers ---');
    for (final header in responseHeaders) {
      buffer.writeln('${header.key}: ${header.value}');
    }
    if (responseBody != null) {
      buffer
        ..writeln()
        ..writeln('--- Response body ---')
        ..writeln(prettyBody(responseBody!));
    }
    return buffer.toString();
  }

  static String prettyBody(String body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } on FormatException {
      return body;
    }
  }

  static String _escape(String value) => value.replaceAll("'", r"'\''");
}
