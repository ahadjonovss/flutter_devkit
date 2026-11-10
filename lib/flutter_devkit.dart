/// In-app developer tools for Flutter apps that talk to their backend through
/// Dio: a dev panel with host-registered items, an HTTP inspector, and
/// per-route backend scenario switching for QA.
///
/// Start with [DevKit.init], add [ScenarioInterceptor] and
/// [InspectorInterceptor] to your Dio client, and open the panel with
/// [DevKit.show].
library;

export 'package:flutter_devkit/src/devkit.dart';
export 'package:flutter_devkit/src/inspector/http_record.dart';
export 'package:flutter_devkit/src/inspector/inspector_interceptor.dart';
export 'package:flutter_devkit/src/inspector/inspector_page.dart' show InspectorPage;
export 'package:flutter_devkit/src/inspector/inspector_store.dart';
export 'package:flutter_devkit/src/panel/devkit_item.dart';
export 'package:flutter_devkit/src/scenarios/scenario.dart';
export 'package:flutter_devkit/src/scenarios/scenario_banner.dart';
export 'package:flutter_devkit/src/scenarios/scenario_cubit.dart';
export 'package:flutter_devkit/src/scenarios/scenario_interceptor.dart';
export 'package:flutter_devkit/src/scenarios/scenario_registry.dart';
export 'package:flutter_devkit/src/scenarios/scenarios.dart';
