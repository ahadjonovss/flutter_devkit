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
        () => ScenarioRegistry().register([
          _route('a', cases: ['x', 'x']),
        ]),
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
      scenarios = Scenarios(isEnabled: () => true, storage: _MemoryStorage())
        ..register([
          _route('r', match: RouteMatcher.exact('/r'), cases: ['a', 'b']),
        ]);
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

    test('answers locally with a mock and skips the backend', () async {
      scenarios.addCustomCase(
        match: RouteMatcher.exact('/m', method: 'GET'),
        label: 'GET /m',
        scenario: const ScenarioCase(
          id: 'empty',
          label: 'Empty',
          mock: ScenarioMock(body: '{"items":[]}', headers: {'content-type': 'application/json'}),
        ),
      );
      scenarios.cubit.select(scenarios.customRoutes.single.id, 'empty');
      final response = await dio.get<Map<String, dynamic>>('/m');
      expect(sent, isEmpty);
      expect(response.statusCode, 200);
      expect(response.data, {'items': <Object?>[]});
      expect(response.extra[ScenarioInterceptor.mockedKey], isTrue);
    });

    test('a mock with an error status throws like a real one, and is recorded', () async {
      final store = InspectorStore(isEnabled: () => true);
      dio.interceptors.add(InspectorInterceptor(store: store));
      scenarios.addCustomCase(
        match: RouteMatcher.exact('/r'),
        label: '/r',
        scenario: const ScenarioCase(
          id: 'down',
          label: 'Down',
          mock: ScenarioMock(statusCode: 503, body: 'down'),
        ),
      );
      final id = scenarios.customRoutes.single.id;
      scenarios.cubit.select(id, 'down');
      await expectLater(
        dio.get<String>('/r'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 503)),
      );
      expect(sent, isEmpty);
      expect(store.records.single.statusCode, 503);
      expect(store.records.single.scenario, '$id → down');
    });

    test('a selected custom route wins over an unselected code route for the same path', () async {
      scenarios.addCustomCase(
        match: RouteMatcher.exact('/r'),
        label: '/r',
        scenario: const ScenarioCase(id: 'h', label: 'H', headers: {'X-Custom': '1'}),
      );
      scenarios.cubit.select(scenarios.customRoutes.single.id, 'h');
      await dio.get<String>('/r');
      expect(sent.single.headers['X-Custom'], '1');
    });
  });

  group('custom scenarios', () {
    late Scenarios scenarios;
    late _MemoryStorage storage;

    setUp(() {
      storage = _MemoryStorage();
      scenarios = Scenarios(isEnabled: () => true, storage: storage)..register([_route('code')]);
    });

    ScenarioRoute add(String path, String caseId) => scenarios.addCustomCase(
      match: RouteMatcher.exact(path, method: 'GET'),
      label: 'GET $path',
      scenario: ScenarioCase(
        id: caseId,
        label: caseId,
        description: 'about $caseId',
        headers: const {'X-A': '1'},
        mock: const ScenarioMock(statusCode: 201, body: 'b', delay: Duration(milliseconds: 5)),
      ),
    );

    test('a case for the same match joins the existing route', () {
      add('/u', 'a');
      add('/u', 'b');
      add('/v', 'a');
      expect(scenarios.customRoutes.map((r) => r.cases.length), [2, 1]);
      expect(scenarios.isCustom('code'), isFalse);
    });

    test('saves on every change and loads back', () async {
      add('/u', 'a');
      await Future<void>.delayed(Duration.zero);
      final restored = Scenarios(isEnabled: () => true, storage: storage);
      await restored.load();
      final route = restored.customRoutes.single;
      expect(route.label, 'GET /u');
      expect(route.match.matches('GET', '/u'), isTrue);
      expect(route.match.matches('POST', '/u'), isFalse);
      final scenario = route.cases.single;
      expect(scenario.description, 'about a');
      expect(scenario.headers, {'X-A': '1'});
      expect(scenario.mock!.statusCode, 201);
      expect(scenario.mock!.delay, const Duration(milliseconds: 5));
    });

    test('export and import round-trip, skipping ids of code routes', () {
      add('/u', 'a');
      final json = scenarios.exportCustom();
      final other = Scenarios(isEnabled: () => true, storage: _MemoryStorage())..register([_route('code')]);
      final withCodeId = json.replaceFirst(
        '"routes": [',
        '"routes": [{"id":"code","label":"x","match":{"kind":"exact","pattern":"/x"},"cases":[]},',
      );
      expect(other.importCustom(withCodeId), (imported: 1, skipped: 1));
      expect(other.customRoutes.single.toJson(), scenarios.customRoutes.single.toJson());
      expect(other.importCustom(json), (imported: 1, skipped: 0));
      expect(other.customRoutes.length, 1);
    });

    test('a bad import changes nothing', () {
      add('/u', 'a');
      expect(() => scenarios.importCustom('nope'), throwsFormatException);
      expect(
        () => scenarios.importCustom(
          '{"routes":[{"id":"x","label":"x","match":{"kind":"regExp","pattern":"("},"cases":[]}]}',
        ),
        throwsFormatException,
      );
      expect(scenarios.customRoutes.length, 1);
    });

    test('removing cases and routes clears their selection', () {
      final route = add('/u', 'a');
      add('/u', 'b');
      scenarios.cubit.select(route.id, 'b');
      scenarios.removeCustomCase(route.id, 'b');
      expect(scenarios.cubit.state.count, 0);
      scenarios.cubit.select(route.id, 'a');
      scenarios.removeCustomCase(route.id, 'a');
      expect(scenarios.customRoutes, isEmpty);
      expect(scenarios.cubit.state.count, 0);
    });
  });
}

class _MemoryStorage implements ScenarioStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String json) async => value = json;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.sent);

  final List<RequestOptions> sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(options);
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}
