import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';
import 'package:flutter_devkit/src/scenarios/scenario.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

enum _CaseKind { mock, headers }

/// Form that adds a custom scenario case, prefilled from a recorded request
/// when there is one.
class ScenarioFormPage extends StatefulWidget {
  /// Creates the form; prefer [open].
  const ScenarioFormPage({super.key, this.record});

  /// Request the form is prefilled from, or null for an empty form.
  final HttpRecord? record;

  /// Pushes the form on the root navigator.
  static Future<void> open(BuildContext context, {HttpRecord? record}) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => DevKitTheme(child: ScenarioFormPage(record: record)),
      ),
    );
  }

  @override
  State<ScenarioFormPage> createState() => _ScenarioFormPageState();
}

class _ScenarioFormPageState extends State<ScenarioFormPage> {
  static const List<String> _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

  /// Response headers that describe the original transfer and would be wrong
  /// for a body served from memory.
  static const Set<String> _transferHeaders = {'content-length', 'content-encoding', 'transfer-encoding', 'connection'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _path;
  late final TextEditingController _label;
  late final TextEditingController _name;
  final TextEditingController _description = TextEditingController();
  late final TextEditingController _status;
  final TextEditingController _delay = TextEditingController(text: '0');
  late final TextEditingController _mockHeaders;
  late final TextEditingController _body;
  final TextEditingController _requestHeaders = TextEditingController();

  String? _method;
  RouteMatchKind _matchKind = RouteMatchKind.exact;
  _CaseKind _kind = _CaseKind.mock;
  bool _turnOn = true;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    final uri = record == null ? null : Uri.tryParse(record.url);
    _method = record?.method.toUpperCase() ?? 'GET';
    if (!_methods.contains(_method)) _method = null;
    _path = TextEditingController(text: uri?.path ?? '');
    _label = TextEditingController();
    _name = TextEditingController(text: record?.statusCode == null ? 'Mock' : 'Recorded response');
    _status = TextEditingController(text: '${record?.statusCode ?? 200}');
    _mockHeaders = TextEditingController(
      text: [
        for (final h in record?.responseHeaders ?? const <MapEntry<String, String>>[])
          if (!_transferHeaders.contains(h.key.toLowerCase())) '${h.key}: ${h.value}',
      ].join('\n'),
    );
    final body = record?.responseBody;
    _body = TextEditingController(text: body == null || _truncated ? '' : HttpRecord.prettyBody(body));
  }

  bool get _truncated => widget.record?.responseBody?.contains('\n… truncated (') ?? false;

  @override
  void dispose() {
    for (final c in [_path, _label, _name, _description, _status, _delay, _mockHeaders, _body, _requestHeaders]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _defaultLabel => [?_method, _path.text.trim()].join(' ');

  static Map<String, String> _parseHeaders(String text) {
    final headers = <String, String>{};
    for (final raw in const LineSplitter().convert(text)) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final index = line.indexOf(':');
      headers[line.substring(0, index).trim()] = line.substring(index + 1).trim();
    }
    return headers;
  }

  static String? _validateHeaders(String? text) {
    for (final raw in const LineSplitter().convert(text ?? '')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.indexOf(':') < 1) return 'Each line must look like "Name: value"';
    }
    return null;
  }

  String? _validatePath(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a path';
    if (_matchKind == RouteMatchKind.regExp) {
      try {
        RegExp(text);
      } on FormatException catch (e) {
        return 'Invalid expression: ${e.message}';
      }
    }
    return null;
  }

  static String? _validateInt(String? value, {required int min, required int max}) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < min || number > max) return '$min–$max';
    return null;
  }

  void _formatBody() {
    try {
      _body.text = const JsonEncoder.withIndent('  ').convert(jsonDecode(_body.text));
    } on FormatException {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Body is not valid JSON')));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final scenarios = DevKit.scenarios;
    final mock = _kind == _CaseKind.mock
        ? ScenarioMock(
            statusCode: int.parse(_status.text.trim()),
            headers: _parseHeaders(_mockHeaders.text),
            body: _body.text,
            delay: Duration(milliseconds: int.parse(_delay.text.trim())),
          )
        : null;
    final description = _description.text.trim();
    final scenario = ScenarioCase(
      id: Scenarios.newCustomId(),
      label: _name.text.trim(),
      description: description.isEmpty ? null : description,
      headers: _kind == _CaseKind.headers ? _parseHeaders(_requestHeaders.text) : const {},
      mock: mock,
    );
    final label = _label.text.trim();
    final route = scenarios.addCustomCase(
      match: RouteMatcher.of(_matchKind, _path.text.trim(), method: _method),
      label: label.isEmpty ? _defaultLabel : label,
      scenario: scenario,
    );
    if (_turnOn) scenarios.cubit.select(route.id, scenario.id);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_turnOn ? 'Scenario saved and turned on' : 'Scenario saved')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = devKitMono(theme.textTheme.bodyMedium);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: const Text('New scenario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DevKitSection(
              title: 'Route',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: _method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Any method')),
                      for (final m in _methods)
                        DropdownMenuItem<String?>(
                          value: m,
                          child: Text(
                            m,
                            style: TextStyle(color: devKitMethodColor(m), fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _method = value),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<RouteMatchKind>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: RouteMatchKind.exact, label: Text('Exact')),
                      ButtonSegment(value: RouteMatchKind.endsWith, label: Text('Ends with')),
                      ButtonSegment(value: RouteMatchKind.regExp, label: Text('Regex')),
                    ],
                    selected: {_matchKind},
                    onSelectionChanged: (value) => setState(() => _matchKind = value.single),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _path,
                    style: mono,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: _matchKind == RouteMatchKind.regExp ? 'Path pattern' : 'Path',
                      hintText: '/api/users',
                    ),
                    validator: _validatePath,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _label,
                    decoration: InputDecoration(labelText: 'Label (optional)', hintText: _defaultLabel),
                  ),
                ],
              ),
            ),
            DevKitSection(
              title: 'Case',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name', hintText: 'Empty list'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_CaseKind>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _CaseKind.mock,
                        icon: Icon(Icons.inventory_2_outlined),
                        label: Text('Mock response'),
                      ),
                      ButtonSegment(value: _CaseKind.headers, icon: Icon(Icons.tune_rounded), label: Text('Headers')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (value) => setState(() => _kind = value.single),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _kind == _CaseKind.mock
                        ? 'The request never reaches the backend; this response is returned instead.'
                        : 'These headers are added to the request; the backend decides the response.',
                    style: muted,
                  ),
                ],
              ),
            ),
            if (_kind == _CaseKind.mock)
              DevKitSection(
                title: 'Mock response',
                trailing: TextButton(onPressed: _formatBody, child: const Text('Format JSON')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _status,
                            style: mono,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Status'),
                            validator: (v) => _validateInt(v, min: 100, max: 599),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _delay,
                            style: mono,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Delay', suffixText: 'ms'),
                            validator: (v) => _validateInt(v, min: 0, max: 60000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mockHeaders,
                      style: mono,
                      minLines: 2,
                      maxLines: 6,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Headers',
                        hintText: 'content-type: application/json',
                        alignLabelWithHint: true,
                      ),
                      validator: _validateHeaders,
                    ),
                    const SizedBox(height: 12),
                    if (_truncated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'The recorded body was cut by the inspector, so it is left empty. Paste the full body.',
                          style: muted?.copyWith(color: devKitWarningColor),
                        ),
                      ),
                    TextFormField(
                      controller: _body,
                      style: devKitMono(theme.textTheme.bodySmall),
                      minLines: 6,
                      maxLines: 18,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Body', alignLabelWithHint: true),
                    ),
                  ],
                ),
              )
            else
              DevKitSection(
                title: 'Request headers',
                child: TextFormField(
                  controller: _requestHeaders,
                  style: mono,
                  minLines: 3,
                  maxLines: 8,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'X-Scenario: login-locked', alignLabelWithHint: true),
                  validator: (v) {
                    if (_parseHeaders(v ?? '').isEmpty) return 'Add at least one header';
                    return _validateHeaders(v);
                  },
                ),
              ),
            Card(
              child: SwitchListTile(
                title: const Text('Turn on after saving'),
                subtitle: const Text('Matching requests use this case right away'),
                value: _turnOn,
                onChanged: (value) => setState(() => _turnOn = value),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save scenario'),
          ),
        ),
      ),
    );
  }
}
