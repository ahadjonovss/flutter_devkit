import 'package:flutter/material.dart';

import 'package:flutter_devkit/src/inspector/inspector_store.dart';
import 'package:flutter_devkit/src/panel/devkit_item.dart';
import 'package:flutter_devkit/src/panel/devkit_panel.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

typedef DevKitLogger = void Function(String message);

abstract final class DevKit {
  static bool _initialized = false;
  static bool _enabled = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static DevKitLogger _log = debugPrint;
  static final List<DevKitItem> _items = [];

  static final Scenarios scenarios = Scenarios(isEnabled: () => enabled);

  static final InspectorStore inspector = InspectorStore(isEnabled: () => enabled);

  static bool get enabled => _enabled;

  static GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  static List<DevKitItem> get items => List.unmodifiable(_items);

  static void init({
    required bool enabled,
    GlobalKey<NavigatorState>? navigatorKey,
    DevKitLogger? log,
    int? inspectorCapacity,
  }) {
    if (_initialized) {
      throw StateError('DevKit.init() can only be called once.');
    }
    _initialized = true;
    _enabled = enabled;
    _navigatorKey = navigatorKey;
    if (log != null) _log = log;
    if (inspectorCapacity != null) inspector.capacity = inspectorCapacity;
  }

  static void addItem(DevKitItem item) {
    if (!_enabled) return;
    _items.add(item);
  }

  static void log(String message) => _log('[DevKit] $message');

  static Future<void> show([BuildContext? context]) async {
    if (!_enabled) return;
    final ctx = context ?? _navigatorKey?.currentContext;
    if (ctx == null) return;
    await DevKitPanel.show(ctx);
  }
}
