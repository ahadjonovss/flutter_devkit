import 'package:flutter/material.dart';
import 'package:flutter_devkit/flutter_devkit.dart';
import 'package:flutter_devkit/src/scenarios/scenario_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  setUpAll(() {
    DevKit.init(enabled: true, navigatorKey: navigatorKey, log: (_) {});
    DevKit.scenarios.register([
      ScenarioRoute(
        id: 'auth.login',
        label: 'POST /auth/login',
        match: RouteMatcher.endsWith('/auth/login', method: 'POST'),
        cases: const [
          ScenarioCase(id: 'locked', label: 'Account locked', description: '423 locked', headers: {'X': 'locked'}),
        ],
      ),
    ]);
    DevKit.inspector.attach();
    DevKit.inspector.add(
      HttpRecord(
        id: DevKit.inspector.nextId(),
        method: 'GET',
        url: 'https://h.test/users?page=1',
        startedAt: DateTime(2026),
        requestHeaders: const [MapEntry('Accept', 'application/json')],
      ).complete(statusCode: 200, responseBody: '{"users":[{"id":1,"active":true,"name":null}]}'),
    );
  });

  tearDown(DevKit.scenarios.cubit.clearAll);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()));
  }

  testWidgets('the panel lists the built-in tools', (tester) async {
    await pumpApp(tester);
    DevKit.show();
    await tester.pumpAndSettle();
    expect(find.text('Backend scenarios'), findsOneWidget);
    expect(find.text('HTTP inspector'), findsOneWidget);
    expect(find.text('1 request(s) captured'), findsOneWidget);
  });

  testWidgets('picking a case on the scenarios page selects it', (tester) async {
    await pumpApp(tester);
    ScenarioPage.open(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    expect(find.text('All routes hit the real backend'), findsOneWidget);

    await tester.tap(find.text('Account locked'));
    await tester.pumpAndSettle();
    expect(DevKit.scenarios.cubit.state.byRoute, {'auth.login': 'locked'});
    expect(find.text('423 locked'), findsOneWidget);

    await tester.tap(find.text('Real backend'));
    await tester.pumpAndSettle();
    expect(DevKit.scenarios.cubit.state.count, 0);
  });

  testWidgets('the inspector opens a record and shows its body', (tester) async {
    await pumpApp(tester);
    InspectorPage.open(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    expect(find.text('/users?page=1'), findsOneWidget);

    await tester.tap(find.text('/users?page=1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Response'));
    await tester.pumpAndSettle();
    expect(find.textContaining('"active": true', findRichText: true), findsOneWidget);
  });
}
