import 'dart:convert';

/// Headers as ordered `name: value` pairs; a name can repeat.
typedef RecordHeaders = List<MapEntry<String, String>>;

/// One request captured by `InspectorInterceptor`, with its response once it
/// completes.
///
/// Records are immutable: completing a request replaces the record with the
/// one [complete] returns.
class HttpRecord {
  /// Creates a pending record; [complete] fills in the response.
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

  /// Unique, increasing id within the store that recorded it.
  final int id;

  /// HTTP method, e.g. `GET`.
  final String method;

  /// Full request URL, after redaction.
  final String url;

  /// When the request was sent.
  final DateTime startedAt;

  /// Request headers, after redaction.
  final RecordHeaders requestHeaders;

  /// Request body as text, after redaction and truncation; null when empty.
  final String? requestBody;

  /// The `route → case` tag when a scenario changed this request.
  final String? scenario;

  /// Response status code; null while pending or when no response arrived.
  final int? statusCode;

  /// Response headers, after redaction.
  final RecordHeaders responseHeaders;

  /// Response body as text, after redaction and truncation.
  final String? responseBody;

  /// Time from sending to completion; null while pending.
  final Duration? duration;

  /// Error description when the request failed, after redaction.
  final String? error;

  /// Whether the request is still in flight.
  bool get isPending => duration == null;

  /// Whether the request completed without any response, e.g. a timeout.
  bool get isFailed => !isPending && statusCode == null;

  /// Whether the request failed or got a 4xx/5xx status.
  bool get isError => isFailed || (statusCode ?? 0) >= 400;

  /// The URL path with its query, without scheme and host.
  String get path {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }

  /// Returns a completed copy of this record, with [duration] measured now.
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

  /// A `curl` command that repeats the request, using the redacted values.
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

  /// A plain-text dump of the request and response, for sharing.
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

  /// Pretty-prints [body] when it is JSON and returns it unchanged otherwise.
  static String prettyBody(String body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } on FormatException {
      return body;
    }
  }

  static String _escape(String value) => value.replaceAll("'", r"'\''");
}
