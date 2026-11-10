import 'package:flutter_devkit/flutter_devkit.dart';
import 'package:flutter_devkit/src/inspector/inspector_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

HttpRecord _record(int id, {String method = 'GET', String url = 'https://h.test/a', int? status}) {
  final record = HttpRecord(id: id, method: method, url: url, startedAt: DateTime(2026), requestHeaders: const []);
  return status == null ? record : record.complete(statusCode: status);
}

void main() {
  group('HttpRecord', () {
    test('status flags', () {
      expect(_record(0).isPending, isTrue);
      expect(_record(0, status: 200).isError, isFalse);
      expect(_record(0, status: 404).isError, isTrue);
      final failed = _record(0).complete(error: 'timeout');
      expect(failed.isFailed, isTrue);
      expect(failed.isError, isTrue);
    });

    test('path keeps the query', () {
      expect(_record(0, url: 'https://h.test/a/b?x=1').path, '/a/b?x=1');
    });

    test('toCurl escapes single quotes', () {
      final record = HttpRecord(
        id: 0,
        method: 'POST',
        url: "https://h.test/it's",
        startedAt: DateTime(2026),
        requestHeaders: const [MapEntry('X-A', 'b')],
        requestBody: '{"name":"O\'Brien"}',
      );
      expect(
        record.toCurl(),
        "curl -X POST 'https://h.test/it'\\''s' \\\n"
        "  -H 'X-A: b' \\\n"
        "  --data-raw '{\"name\":\"O'\\''Brien\"}'",
      );
    });

    test('prettyBody indents JSON and leaves anything else alone', () {
      expect(HttpRecord.prettyBody('{"a":1}'), '{\n  "a": 1\n}');
      expect(HttpRecord.prettyBody('plain'), 'plain');
    });
  });

  group('InspectorStore', () {
    test('keeps the newest records up to capacity', () {
      final store = InspectorStore(isEnabled: () => true, capacity: 2);
      for (var i = 0; i < 3; i++) {
        store.add(_record(i));
      }
      expect(store.records.map((r) => r.id), [2, 1]);
    });

    test('shrinking capacity drops the oldest records', () {
      final store = InspectorStore(isEnabled: () => true);
      for (var i = 0; i < 5; i++) {
        store.add(_record(i));
      }
      store.capacity = 2;
      expect(store.records.map((r) => r.id), [4, 3]);
      expect(() => store.capacity = 0, throwsArgumentError);
    });
  });

  group('InspectorState', () {
    final records = [
      _record(0, status: 200),
      _record(1, method: 'POST', url: 'https://h.test/login', status: 500),
      _record(2).complete(error: 'timeout'),
    ];

    test('filters by status, method and query', () {
      final state = InspectorState(records: records);
      expect(state.visible.length, 3);
      expect(state.copyWith(status: StatusFilter.errors).visible.map((r) => r.id), [1, 2]);
      expect(state.copyWith(status: StatusFilter.failed).visible.map((r) => r.id), [2]);
      expect(state.copyWith(method: () => 'POST').visible.map((r) => r.id), [1]);
      expect(state.copyWith(query: 'LOGIN').visible.map((r) => r.id), [1]);
      expect(state.methods, ['GET', 'POST']);
    });
  });

  group('InspectorInterceptor', () {
    late InspectorStore store;

    Dio dioReturning(Object body, {String Function(String)? redact, int maxBodyLength = 64 * 1024}) {
      return Dio(BaseOptions(baseUrl: 'https://h.test'))
        ..httpClientAdapter = _Adapter(body)
        ..interceptors.add(InspectorInterceptor(store: store, redact: redact, maxBodyLength: maxBodyLength));
    }

    setUp(() => store = InspectorStore(isEnabled: () => true));

    test('records a completed request', () async {
      await dioReturning('{"ok":true}').post<String>('/a', data: {'x': 1});
      final record = store.records.single;
      expect(record.method, 'POST');
      expect(record.statusCode, 200);
      expect(record.requestBody, '{"x":1}');
      expect(record.responseBody, '{"ok":true}');
      expect(store.attached, isTrue);
    });

    test('redacts the url, headers and bodies', () async {
      await dioReturning(
        'secret',
        redact: (s) => s.replaceAll('secret', '***'),
      ).get<String>('/secret', options: Options(headers: {'X-Token': 'secret'}));
      final record = store.records.single;
      expect(record.url, 'https://h.test/***');
      expect(
        record.requestHeaders,
        contains(
          isA<MapEntry<String, String>>().having((e) => e.key, 'key', 'X-Token').having((e) => e.value, 'value', '***'),
        ),
      );
      expect(record.responseBody, '***');
    });

    test('truncates a long body and reports its original length', () async {
      final body = 'a' * 1000;
      await dioReturning(body, maxBodyLength: 100).get<String>('/a');
      expect(store.records.single.responseBody, '${'a' * 100}\n… truncated (1000 chars)');
    });

    test('redacts a secret that straddles the cut', () async {
      final body = '${'a' * 95}secret${'b' * 1000}';
      await dioReturning(body, maxBodyLength: 100, redact: (s) => s.replaceAll('secret', '******')).get<String>('/a');
      expect(store.records.single.responseBody, startsWith('${'a' * 95}*****'));
    });

    test('records nothing when disabled', () async {
      store = InspectorStore(isEnabled: () => false);
      await dioReturning('x').get<String>('/a');
      expect(store.records, isEmpty);
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);

  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('$body', 200);
  }

  @override
  void close({bool force = false}) {}
}
