import 'package:flutter_devkit/flutter_devkit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'))
  ..interceptors.addAll([ScenarioInterceptor(), InspectorInterceptor()]);

void main() {
  DevKit.init(enabled: true, navigatorKey: navigatorKey);

  DevKit.scenarios.register([
    ScenarioRoute(
      id: 'echo',
      label: 'GET /anything/echo',
      match: RouteMatcher.endsWith('/anything/echo', method: 'GET'),
      cases: const [
        ScenarioCase(id: 'a', label: 'Case A', description: 'Adds X-Demo: A', headers: {'X-Demo': 'A'}),
        ScenarioCase(id: 'b', label: 'Case B', description: 'Adds X-Demo: B', headers: {'X-Demo': 'B'}),
      ],
    ),
  ]);

  DevKit.addItem(
    DevKitItem(
      title: 'Say hello',
      icon: Icons.waving_hand_outlined,
      onTap: (context) =>
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hello from a host item'))),
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => ScenarioBanner(child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _result = 'Long-press anywhere to open DevKit';

  Future<void> _send() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/anything/echo');
      setState(() => _result = 'X-Demo: ${response.data?['headers']?['X-Demo'] ?? '—'}');
    } on DioException catch (e) {
      setState(() => _result = 'Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => DevKit.show(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('DevKit example')),
        body: Center(child: Text(_result)),
        floatingActionButton: FloatingActionButton.extended(onPressed: _send, label: const Text('Send request')),
      ),
    );
  }
}
