import 'dart:async';

import 'package:flutter_devkit/src/inspector/http_record.dart';

class InspectorStore {
  InspectorStore({required bool Function() isEnabled, int capacity = 100})
      : _isEnabled = isEnabled,
        _capacity = capacity;

  final bool Function() _isEnabled;
  int _capacity;
  final List<HttpRecord> _records = [];
  final StreamController<List<HttpRecord>> _controller = StreamController.broadcast();
  int _nextId = 0;
  bool _attached = false;

  bool get enabled => _isEnabled();

  bool get attached => _attached;

  int get capacity => _capacity;

  set capacity(int value) {
    if (value < 1) throw ArgumentError.value(value, 'capacity', 'must be at least 1');
    _capacity = value;
    if (_records.length <= value) return;
    _records.removeRange(value, _records.length);
    _emit();
  }

  List<HttpRecord> get records => List.unmodifiable(_records);

  Stream<List<HttpRecord>> get stream => _controller.stream;

  void attach() => _attached = true;

  int nextId() => _nextId++;

  HttpRecord? byId(int id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  void add(HttpRecord record) {
    _records.insert(0, record);
    if (_records.length > _capacity) _records.removeLast();
    _emit();
  }

  void update(HttpRecord record) {
    final index = _records.indexWhere((e) => e.id == record.id);
    if (index == -1) return;
    _records[index] = record;
    _emit();
  }

  void clear() {
    if (_records.isEmpty) return;
    _records.clear();
    _emit();
  }

  void _emit() => _controller.add(records);
}
