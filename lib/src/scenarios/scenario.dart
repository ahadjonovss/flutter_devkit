/// A response returned locally instead of calling the backend.
class ScenarioMock {
  /// Creates a mock answering with [statusCode], [headers] and [body] after
  /// [delay].
  const ScenarioMock({this.statusCode = 200, this.headers = const {}, this.body = '', this.delay = Duration.zero});

  /// Reads a mock written by [toJson]. Throws [FormatException] on bad input.
  factory ScenarioMock.fromJson(Object? json) {
    final map = _map(json, 'mock');
    final statusCode = map['statusCode'] ?? 200;
    final delayMs = map['delayMs'] ?? 0;
    if (statusCode is! int || statusCode < 100 || statusCode > 599) {
      throw FormatException('DevKit: mock statusCode must be an integer between 100 and 599, got $statusCode.');
    }
    if (delayMs is! int || delayMs < 0) throw FormatException('DevKit: mock delayMs must be a positive integer.');
    return ScenarioMock(
      statusCode: statusCode,
      headers: _stringMap(map['headers'], 'mock headers'),
      body: _string(map['body'] ?? '', 'mock body'),
      delay: Duration(milliseconds: delayMs),
    );
  }

  /// Response status code.
  final int statusCode;

  /// Response headers.
  final Map<String, String> headers;

  /// Response body as text; JSON is decoded when the request expects JSON.
  final String body;

  /// How long to wait before answering, to imitate a slow backend.
  final Duration delay;

  /// A JSON-encodable form of this mock.
  Map<String, Object?> toJson() => {
    'statusCode': statusCode,
    'headers': headers,
    'body': body,
    'delayMs': delay.inMilliseconds,
  };
}

/// One response a route can be forced into: headers added to the request,
/// a local [mock] response, or both.
class ScenarioCase {
  /// Creates a case sending [headers] and, when [mock] is set, answering
  /// locally with it.
  const ScenarioCase({required this.id, required this.label, this.description, this.headers = const {}, this.mock});

  /// Reads a case written by [toJson]. Throws [FormatException] on bad input.
  factory ScenarioCase.fromJson(Object? json) {
    final map = _map(json, 'case');
    final description = map['description'];
    final mock = map['mock'];
    return ScenarioCase(
      id: _nonEmpty(map['id'], 'case id'),
      label: _nonEmpty(map['label'], 'case label'),
      description: description == null ? null : _string(description, 'case description'),
      headers: _stringMap(map['headers'], 'case headers'),
      mock: mock == null ? null : ScenarioMock.fromJson(mock),
    );
  }

  /// Unique id within its route.
  final String id;

  /// Name shown to QA.
  final String label;

  /// Optional detail shown under the picker.
  final String? description;

  /// Headers added to the matching request.
  final Map<String, String> headers;

  /// Local response returned instead of calling the backend; null sends the
  /// request as usual.
  final ScenarioMock? mock;

  /// A JSON-encodable form of this case.
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    if (description != null) 'description': description,
    if (headers.isNotEmpty) 'headers': headers,
    if (mock != null) 'mock': mock!.toJson(),
  };
}

/// A backend route QA can override, with the cases to choose from.
class ScenarioRoute {
  /// Creates a route matched by [match].
  const ScenarioRoute({required this.id, required this.label, required this.match, required this.cases});

  /// Reads a route written by [toJson]. Throws [FormatException] on bad
  /// input.
  factory ScenarioRoute.fromJson(Object? json) {
    final map = _map(json, 'route');
    final cases = map['cases'];
    if (cases is! List) throw const FormatException('DevKit: route cases must be a list.');
    return ScenarioRoute(
      id: _nonEmpty(map['id'], 'route id'),
      label: _nonEmpty(map['label'], 'route label'),
      match: RouteMatcher.fromJson(map['match']),
      cases: [for (final c in cases) ScenarioCase.fromJson(c)],
    );
  }

  /// Selection key; unique across all registrations.
  final String id;

  /// Name shown to QA, usually `METHOD /path`.
  final String label;

  /// Decides which requests belong to this route.
  final RouteMatcher match;

  /// Cases QA can pick from.
  final List<ScenarioCase> cases;

  /// The case with [caseId], or null when there is none.
  ScenarioCase? caseById(String caseId) {
    for (final scenario in cases) {
      if (scenario.id == caseId) return scenario;
    }
    return null;
  }

  /// A copy of this route with [cases] replaced.
  ScenarioRoute copyWith({List<ScenarioCase>? cases}) =>
      ScenarioRoute(id: id, label: label, match: match, cases: cases ?? this.cases);

  /// A JSON-encodable form of this route.
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'match': match.toJson(),
    'cases': [for (final c in cases) c.toJson()],
  };
}

/// How a [RouteMatcher] compares the request path with its pattern.
enum RouteMatchKind {
  /// The path equals the pattern.
  exact,

  /// The path ends with the pattern.
  endsWith,

  /// The pattern is a regular expression that matches the path.
  regExp,
}

/// Matches a request by path and, optionally, method.
class RouteMatcher {
  RouteMatcher._(this.kind, this.pattern, this._matchesPath, String? method) : method = method?.toUpperCase();

  /// Matches when the path equals [path].
  factory RouteMatcher.exact(String path, {String? method}) =>
      RouteMatcher._(RouteMatchKind.exact, path, (p) => p == path, method);

  /// Matches when the path ends with [suffix].
  factory RouteMatcher.endsWith(String suffix, {String? method}) =>
      RouteMatcher._(RouteMatchKind.endsWith, suffix, (p) => p.endsWith(suffix), method);

  /// Matches when [pattern] matches the path.
  factory RouteMatcher.regExp(RegExp pattern, {String? method}) =>
      RouteMatcher._(RouteMatchKind.regExp, pattern.pattern, pattern.hasMatch, method);

  /// A matcher of the given [kind]. Throws [FormatException] when [kind] is
  /// [RouteMatchKind.regExp] and [pattern] is not a valid expression.
  factory RouteMatcher.of(RouteMatchKind kind, String pattern, {String? method}) => switch (kind) {
    RouteMatchKind.exact => RouteMatcher.exact(pattern, method: method),
    RouteMatchKind.endsWith => RouteMatcher.endsWith(pattern, method: method),
    RouteMatchKind.regExp => RouteMatcher.regExp(RegExp(pattern), method: method),
  };

  /// Reads a matcher written by [toJson]. Throws [FormatException] on bad
  /// input.
  factory RouteMatcher.fromJson(Object? json) {
    final map = _map(json, 'match');
    final kindName = map['kind'];
    final kind = RouteMatchKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) throw FormatException('DevKit: unknown match kind "$kindName".');
    final method = map['method'];
    return RouteMatcher.of(
      kind,
      _nonEmpty(map['pattern'], 'match pattern'),
      method: method == null ? null : _string(method, 'match method'),
    );
  }

  /// How the path is compared with [pattern].
  final RouteMatchKind kind;

  /// The path, suffix or regular expression source this matcher was made
  /// from.
  final String pattern;

  final bool Function(String path) _matchesPath;

  /// Method to require, upper-cased; null matches every method.
  final String? method;

  /// Whether a request with [requestMethod] and [path] matches.
  bool matches(String requestMethod, String path) {
    if (method != null && method != requestMethod.toUpperCase()) return false;
    return _matchesPath(path);
  }

  /// Whether [other] matches the same requests by construction.
  bool sameAs(RouteMatcher other) => kind == other.kind && pattern == other.pattern && method == other.method;

  /// A JSON-encodable form of this matcher.
  Map<String, Object?> toJson() => {'kind': kind.name, 'pattern': pattern, if (method != null) 'method': method};
}

Map<String, Object?> _map(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  if (json is Map) return json.cast<String, Object?>();
  throw FormatException('DevKit: $what must be a JSON object.');
}

String _string(Object? value, String what) {
  if (value is String) return value;
  throw FormatException('DevKit: $what must be a string.');
}

String _nonEmpty(Object? value, String what) {
  final text = _string(value, what);
  if (text.isEmpty) throw FormatException('DevKit: $what must not be empty.');
  return text;
}

Map<String, String> _stringMap(Object? json, String what) {
  if (json == null) return const {};
  final map = _map(json, what);
  return {for (final e in map.entries) e.key: _string(e.value, '$what value')};
}
