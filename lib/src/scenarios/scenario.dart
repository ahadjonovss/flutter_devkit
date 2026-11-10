class ScenarioCase {
  const ScenarioCase({
    required this.id,
    required this.label,
    this.description,
    required this.headers,
  });

  final String id;
  final String label;
  final String? description;
  final Map<String, String> headers;
}

class ScenarioRoute {
  const ScenarioRoute({
    required this.id,
    required this.label,
    required this.match,
    required this.cases,
  });

  final String id;
  final String label;
  final RouteMatcher match;
  final List<ScenarioCase> cases;

  ScenarioCase? caseById(String caseId) {
    for (final scenario in cases) {
      if (scenario.id == caseId) return scenario;
    }
    return null;
  }
}

class RouteMatcher {
  RouteMatcher._(this._matchesPath, String? method) : method = method?.toUpperCase();

  factory RouteMatcher.exact(String path, {String? method}) =>
      RouteMatcher._((p) => p == path, method);

  factory RouteMatcher.endsWith(String suffix, {String? method}) =>
      RouteMatcher._((p) => p.endsWith(suffix), method);

  factory RouteMatcher.regExp(RegExp pattern, {String? method}) =>
      RouteMatcher._(pattern.hasMatch, method);

  final bool Function(String path) _matchesPath;
  final String? method;

  bool matches(String requestMethod, String path) {
    if (method != null && method != requestMethod.toUpperCase()) return false;
    return _matchesPath(path);
  }
}
