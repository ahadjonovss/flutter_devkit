/// One response a route can be forced into, expressed as request headers.
class ScenarioCase {
  /// Creates a case sending [headers].
  const ScenarioCase({required this.id, required this.label, this.description, required this.headers});

  /// Unique id within its route.
  final String id;

  /// Name shown to QA.
  final String label;

  /// Optional detail shown under the picker.
  final String? description;

  /// Headers added to the matching request.
  final Map<String, String> headers;
}

/// A backend route QA can override, with the cases to choose from.
class ScenarioRoute {
  /// Creates a route matched by [match].
  const ScenarioRoute({required this.id, required this.label, required this.match, required this.cases});

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
}

/// Matches a request by path and, optionally, method.
class RouteMatcher {
  RouteMatcher._(this._matchesPath, String? method) : method = method?.toUpperCase();

  /// Matches when the path equals [path].
  factory RouteMatcher.exact(String path, {String? method}) => RouteMatcher._((p) => p == path, method);

  /// Matches when the path ends with [suffix].
  factory RouteMatcher.endsWith(String suffix, {String? method}) => RouteMatcher._((p) => p.endsWith(suffix), method);

  /// Matches when [pattern] matches the path.
  factory RouteMatcher.regExp(RegExp pattern, {String? method}) => RouteMatcher._(pattern.hasMatch, method);

  final bool Function(String path) _matchesPath;

  /// Method to require, upper-cased; null matches every method.
  final String? method;

  /// Whether a request with [requestMethod] and [path] matches.
  bool matches(String requestMethod, String path) {
    if (method != null && method != requestMethod.toUpperCase()) return false;
    return _matchesPath(path);
  }
}
