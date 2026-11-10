import 'package:flutter_devkit/flutter_devkit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

ScenarioRoute _route(String id, {RouteMatcher? match, List<String> cases = const ['a']}) {
  return ScenarioRoute(
    id: id,
    label: id,
    match: match ?? RouteMatcher.exact('/$id'),
    cases: [
      for (final c in cases) ScenarioCase(id: c, label: c, headers: {'X-Case': c}),
    ],
  );
}

void main() {
  group('RouteMatcher', () {
    test('exact matches the whole path only', () {
      final m = RouteMatcher.exact('/a/b');
      expect(m.matches('GET', '/a/b'), isTrue);
      expect(m.matches('GET', '/x/a/b'), isFalse);
    });

    test('endsWith matches a suffix', () {
      final m = RouteMatcher.endsWith('/b');
      expect(m.matches('GET', '/api/v1/b'), isTrue);
      expect(m.matches('GET', '/api/v1/c'), isFalse);
    });

    test('regExp matches a pattern', () {
      final m = RouteMatcher.regExp(RegExp(r'^/users/\d+$'));
      expect(m.matches('GET', '/users/42'), isTrue);
      expect(m.matches('GET', '/users/me'), isFalse);
    });

    test('method is compared case-insensitively', () {
      final m = RouteMatcher.exact('/a', method: 'post');
      expect(m.matches('POST', '/a'), isTrue);
      expect(m.matches('post', '/a'), isTrue);
      expect(m.matches('GET', '/a'), isFalse);
    });
  });

  group('ScenarioRegistry', () {
    test('rejects a duplicate route id', () {
      final registry = ScenarioRegistry()..register([_route('a')]);
      expect(() => registry.register([_route('a')]), throwsStateError);
    });

    test('rejects a duplicate case id within a route', () {
      expect(
        () => ScenarioRegistry().register([_route('a', cases: ['x', 'x'])]),
        throwsStateError,
      );
    });

    test('firstMatch returns the first registered route that matches', () {
      final registry = ScenarioRegistry()
        ..register([
          _route('first', match: RouteMatcher.endsWith('/b')),
          _route('second', match: RouteMatcher.exact('/a/b')),
        ]);
      final route = registry.firstMatch(RequestOptions(path: 'https://h.test/a/b'));
      expect(route?.id, 'first');
    });
  });

  group('ScenarioCubit', () {
    test('select, clear and clearAll', () {
      final cubit = ScenarioCubit();
      cubit.select('r1', 'a');
      cubit.select('r2', 'b');
      expect(cubit.state.byRoute, {'r1': 'a', 'r2': 'b'});

      cubit.select('r1', null);
      expect(cubit.state.byRoute, {'r2': 'b'});

      cubit.clearAll();
      expect(cubit.state.count, 0);
    });
  });

  group('ScenarioInterceptor', () {
    late Scenarios scenarios;
    late Dio dio;
    late List<RequestOptions> sent;

    setUp(() {
      scenarios = Scenarios(isEnabled: () => true)
        ..register([_route('r', match: RouteMatcher.exact('/r'), cases: ['a', 'b'])]);
      sent = [];
      dio = Dio(BaseOptions(baseUrl: 'https://h.test'))
        ..httpClientAdapter = _Adapter(sent)
        ..interceptors.add(ScenarioInterceptor(scenarios: scenarios, log: (_) {}));
    });

    test('passes the request untouched when nothing is selected', () async {
      await dio.get<String>('/r');
      expect(sent.single.headers.containsKey('X-Case'), isFalse);
      expect(sent.single.extra.containsKey(ScenarioInterceptor.extraKey), isFalse);
    });

    test('adds the selected case headers and tags the request', () async {
      scenarios.cubit.select('r', 'b');
      final response = await dio.get<String>('/r');
      expect(sent.single.headers['X-Case'], 'b');
      expect(response.extra[ScenarioInterceptor.extraKey], 'r → b');
    });

    test('passes through when disabled', () async {
      final disabled = Scenarios(isEnabled: () => false);
      dio.interceptors
        ..clear()
        ..add(ScenarioInterceptor(scenarios: disabled, log: (_) {}));
      disabled.registry.register([_route('r', match: RouteMatcher.exact('/r'))]);
      disabled.cubit.select('r', 'a');
      await dio.get<String>('/r');
      expect(sent.single.headers.containsKey('X-Case'), isFalse);
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.sent);

  final List<RequestOptions> sent;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    sent.add(options);
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}
