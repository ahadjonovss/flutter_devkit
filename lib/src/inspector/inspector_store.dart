import 'dart:async';

import 'package:flutter_devkit/src/inspector/http_record.dart';

/// In-memory list of recorded requests, newest first, capped at [capacity].
class InspectorStore {
  /// Creates a store that records while [isEnabled] returns true.
  InspectorStore({required bool Function() isEnabled, int capacity = 100})
    : _isEnabled = isEnabled,
      _capacity = capacity;

  final bool Function() _isEnabled;
  int _capacity;
  final List<HttpRecord> _records = [];
  final StreamController<List<HttpRecord>> _controller = StreamController.broadcast();
  int _nextId = 0;
  bool _attached = false;

  /// Whether recording is on.
  bool get enabled => _isEnabled();

  /// Whether an `InspectorInterceptor` uses this store; the panel shows the
  /// inspector only then.
  bool get attached => _attached;

  /// How many records are kept; the oldest are dropped beyond it.
  int get capacity => _capacity;

  /// Changes the limit, dropping the oldest records that no longer fit.
  /// Throws [ArgumentError] below 1.
  set capacity(int value) {
    if (value < 1) throw ArgumentError.value(value, 'capacity', 'must be at least 1');
    _capacity = value;
    if (_records.length <= value) return;
    _records.removeRange(value, _records.length);
    _emit();
  }

  /// Current records, newest first.
  List<HttpRecord> get records => List.unmodifiable(_records);

  /// Emits the full record list after every change.
  Stream<List<HttpRecord>> get stream => _controller.stream;

  /// Marks the store as used by an interceptor.
  void attach() => _attached = true;

  /// Returns the next record id.
  int nextId() => _nextId++;

  /// The record with [id], or null when it was dropped or cleared.
  HttpRecord? byId(int id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// Adds [record] as the newest, dropping the oldest beyond [capacity].
  void add(HttpRecord record) {
    _records.insert(0, record);
    if (_records.length > _capacity) _records.removeLast();
    _emit();
  }

  /// Replaces the record with the same id; ignored when it is gone.
  void update(HttpRecord record) {
    final index = _records.indexWhere((e) => e.id == record.id);
    if (index == -1) return;
    _records[index] = record;
    _emit();
  }

  /// Removes every record.
  void clear() {
    if (_records.isEmpty) return;
    _records.clear();
    _emit();
  }

  void _emit() => _controller.add(records);
}
