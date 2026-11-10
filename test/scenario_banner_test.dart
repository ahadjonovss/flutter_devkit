import 'package:flutter_devkit/flutter_devkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => DevKit.init(enabled: true, log: (_) {}));

  testWidgets('the app keeps its state when the strip appears and goes', (tester) async {
    // An unkeyed child, like the Router MaterialApp.router hands to builder; a
    // Navigator child would survive a move through its GlobalKey and hide the bug.
    await tester.pumpWidget(MaterialApp(
      builder: (context, _) => const ScenarioBanner(child: _Counter()),
      home: const SizedBox(),
    ));

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    DevKit.scenarios.cubit.select('route', 'case');
    await tester.pump();
    expect(find.textContaining('1 route(s) overridden'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    DevKit.scenarios.cubit.clearAll();
    await tester.pump();
    expect(find.textContaining('overridden'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => _count++),
          child: Text('$_count'),
        ),
      ),
    );
  }
}
