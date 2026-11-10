import 'package:flutter/material.dart';

import 'package:flutter_devkit/src/inspector/inspector_store.dart';
import 'package:flutter_devkit/src/panel/devkit_item.dart';
import 'package:flutter_devkit/src/panel/devkit_panel.dart';
import 'package:flutter_devkit/src/scenarios/scenarios.dart';

/// Receives the messages DevKit logs, such as each applied scenario.
typedef DevKitLogger = void Function(String message);

/// Entry point of the package: configuration, panel items and the shared
/// [scenarios] and [inspector] state.
///
/// Call [init] once at startup. Everything else is a no-op while [enabled] is
/// false, so the same code can ship in production builds.
abstract final class DevKit {
  static bool _initialized = false;
  static bool _enabled = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static DevKitLogger _log = debugPrint;
  static final List<DevKitItem> _items = [];

  /// Backend scenarios: the routes QA can override and the current selection.
  static final Scenarios scenarios = Scenarios(isEnabled: () => enabled);

  /// Requests recorded by `InspectorInterceptor`s.
  static final InspectorStore inspector = InspectorStore(isEnabled: () => enabled);

  /// Whether the tools are on, as passed to [init]. False until [init] runs.
  static bool get enabled => _enabled;

  /// The navigator passed to [init], used when no [BuildContext] is at hand.
  static GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Items added with [addItem], in the order they were added.
  static List<DevKitItem> get items => List.unmodifiable(_items);

  /// Configures DevKit. Can be called only once; a second call throws
  /// [StateError].
  ///
  /// - [enabled]: whether the tools are on. Usually `!isProduction`.
  /// - [navigatorKey]: lets `ScenarioBanner` and [show] open pages without a
  ///   context.
  /// - [log]: where DevKit messages go. Defaults to [debugPrint].
  /// - [inspectorCapacity]: how many requests [inspector] keeps (default 100).
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

  /// Adds [item] to the dev panel. Ignored while DevKit is disabled.
  static void addItem(DevKitItem item) {
    if (!_enabled) return;
    _items.add(item);
  }

  /// Sends [message] to the logger passed to [init], prefixed with `[DevKit]`.
  static void log(String message) => _log('[DevKit] $message');

  /// Opens the dev panel as a bottom sheet.
  ///
  /// Uses [context] when given, otherwise the [navigatorKey]'s context. Does
  /// nothing while DevKit is disabled or when neither is available.
  static Future<void> show([BuildContext? context]) async {
    if (!_enabled) return;
    final ctx = context ?? _navigatorKey?.currentContext;
    if (ctx == null) return;
    await DevKitPanel.show(ctx);
  }
}
