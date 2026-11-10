# flutter_devkit

In-app developer tools for Flutter apps that talk to their backend through [Dio](https://pub.dev/packages/dio):

- a **dev panel** with your own items,
- an **HTTP inspector** that records requests and responses,
- **backend scenarios**: QA picks, per route, which response the backend should return, without a special build — and can add their own on the device, with a mocked response, from any recorded request.

```yaml
dependencies:
  flutter_devkit: ^0.3.0
```

```dart
import 'package:flutter_devkit/flutter_devkit.dart';
```

The package knows nothing about the host app — everything comes through `DevKit.init(...)` and registration calls.

## Setup

```dart
final navigatorKey = GlobalKey<NavigatorState>();

DevKit.init(
  enabled: !isProduction,          // host decides; set once, cannot be changed later
  navigatorKey: navigatorKey,      // used by the banner to open the scenarios page
  log: (m) => myLogger.warning(m), // optional, defaults to debugPrint
  inspectorCapacity: 200,          // optional, how many requests the inspector keeps (default 100)
  scenarioStorage: myStorage,      // optional, where scenarios added on the device are saved (default SharedPreferences)
  scenarioFiles: myFiles,          // optional, export/import .json files (see "Scenario files")
);
```

Open the panel from anywhere, e.g. from a long-press or shake gesture of your own:

```dart
DevKit.show(context);
```

When `enabled` is false: the panel does not open, items and scenarios are not registered, the interceptor passes every request through, and the banner renders only its child.

## Panel items

```dart
DevKit.addItem(DevKitItem(
  title: 'Say hello',
  icon: Icons.waving_hand_outlined,
  onTap: (context) => showHello(context),
));

DevKit.addItem(DevKitItem.custom(builder: (_) => const ProxymanSettings()));
```

## HTTP inspector

Add the interceptor right after `ScenarioInterceptor`, so it sees the scenario headers and the `devkit.scenario` tag:

```dart
dio.interceptors.addAll([
  AuthInterceptor(),
  ScenarioInterceptor(),
  InspectorInterceptor(redact: (s) => myRedact(s)), // optional, defaults to no redaction
  LoggingInterceptor(),
]);
```

- Once an interceptor is created, the panel shows an **HTTP inspector** item. You can also open it with `InspectorPage.open(context)`.
- The last 100 requests are kept in memory (`DevKit.inspector`, which exposes a `stream`; change the limit with `inspectorCapacity`). Each body is cut at 64 KB (`maxBodyLength`).
- `redact` runs on the URL, on each header as a `name: value` line, on both bodies and on the error text before anything is stored. On a long body it runs on the first `2 × maxBodyLength` characters only, so a huge response does not stall the UI.
- The list has a URL search, status filters (All / Errors / Failed) and method filters. Requests changed by a scenario are marked.
- The detail screen shows headers and a pretty-printed JSON body for the request and the response. It has **Copy as cURL** and **Copy all** buttons (both copy to the clipboard). The copied cURL holds the redacted values, so a masked `Authorization` header has to be filled in before it can be replayed, and a multipart body is written as `key=value` lines rather than `-F` options.
- When `enabled` is false, nothing is recorded.

## Backend scenarios

A route has cases; each case is the full set of headers added to the matching request. Your backend (or a mock server in front of it) reads those headers and answers accordingly — the package only sends them.

```dart
DevKit.scenarios.register([
  ScenarioRoute(
    id: 'auth.login',
    label: 'POST /auth/login',
    match: RouteMatcher.endsWith('/auth/login', method: 'POST'),
    cases: const [
      ScenarioCase(id: 'success', label: 'Success', headers: {'X-Scenario': 'login-success'}),
      ScenarioCase(
        id: 'locked',
        label: 'Account locked',
        description: '423 with a retry-after',
        headers: {'X-Scenario': 'login-locked'},
      ),
    ],
  ),
]);
```

- `route.id` is the selection key and must be unique across all registrations — a duplicate throws `StateError` at startup. Namespace by convention (`auth.login`).
- `register` can be called many times; each call appends.
- Matchers: `RouteMatcher.exact`, `.endsWith`, `.regExp`, all with an optional `method`. Matching uses `options.uri.path`.

Add the interceptor after auth and before logging, so the added headers show up in logs and the inspector:

```dart
dio.interceptors.addAll([AuthInterceptor(), ScenarioInterceptor(), LoggingInterceptor()]);
```

Show the warning strip while any route is overridden:

```dart
MaterialApp(builder: (context, child) => ScenarioBanner(child: child!), ...);
```

Rules:

- Nothing selected for a route → the request is not changed at all. The default is always the real backend.
- A selection stays until reset — not one-shot.
- Selections live in memory only; restarting the app resets everything.
- If a selected case no longer exists, the request passes untouched.
- Every overridden request is logged, and tagged in `options.extra['devkit.scenario']` / `response.extra['devkit.scenario']`.

A case can also answer locally instead of sending headers: give it a `mock`, and matching requests never reach the backend.

```dart
ScenarioCase(
  id: 'empty',
  label: 'Empty list',
  mock: ScenarioMock(statusCode: 200, body: '{"items": []}', delay: Duration(milliseconds: 800)),
)
```

The body is decoded according to the request's `responseType` (JSON by default). A status that fails `validateStatus` throws a `DioException.badResponse`, like a real error. Mocked responses carry `response.extra['devkit.scenario.mocked'] == true` and still show up in the HTTP inspector.

### Adding scenarios on the device

QA can add scenarios without touching the code:

- In the HTTP inspector, open a request and tap **Add scenario**. The form is filled in from the request: method, path, and the recorded status, headers and body. The case is either a **mock response** (edit the status, headers, body and delay) or a set of **headers** for the backend. **Add scenario** on the scenarios page opens the same form, empty.
- A case whose method and path match an existing custom route joins that route. Otherwise a new route is created. Custom routes are tagged **CUSTOM**, can be deleted from their menu, and win over a route from the code that matches the same request.
- Custom routes are saved with `SharedPreferences` and come back on the next launch (pass `scenarioStorage` to `DevKit.init` to keep them somewhere else). Selections are still not saved.
- To share scenarios across devices and testers, use the scenarios page menu: **Copy as JSON** and **Paste JSON**. When an imported route has the id of a custom route, it replaces that route. When its id belongs to a route from the code, it is skipped.
- The same works from code: `DevKit.scenarios.exportCustom()` and `importCustom(json)`.

#### Scenario files (optional)

DevKit adds no file plugin to your app (its only plugin is `shared_preferences`). To export and import `.json` files instead of copying JSON, implement `ScenarioFiles` with a plugin you already use and pass it to `DevKit.init(scenarioFiles: ...)`. The menu then shows **Export as file** and **Import from file**. With [file_picker](https://pub.dev/packages/file_picker):

```dart
class FilePickerScenarioFiles implements ScenarioFiles {
  const FilePickerScenarioFiles();

  @override
  Future<bool> save(String fileName, String json) async {
    final bytes = utf8.encode(json);
    final path = await FilePicker.platform.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    if (kIsWeb) return true; // the web downloads the file and returns no path
    if (path == null) return false;
    // On desktop the dialog only picks a path; mobile has already written it.
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) await File(path).writeAsBytes(bytes);
    return true;
  }

  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = result?.files.singleOrNull?.bytes;
    return bytes == null ? null : utf8.decode(bytes);
  }
}
```

Flutter has no per-flavor dependencies, so a plugin you add for this is in every build. Leave `scenarioFiles` out if that matters to you; copy and paste work everywhere. On macOS, file_picker needs the `com.apple.security.files.user-selected.read-write` entitlement.

## For QA

1. Open the dev panel (however your app wires `DevKit.show`) → **Backend scenarios**.
2. Pick a case for the route you want to test. "Real backend" turns the override off. To make your own, open a request in the HTTP inspector and tap **Add scenario**.
3. An orange strip at the top shows how many routes are overridden. Tap it to change or **Reset all**.
4. The selection applies to every matching request until you reset it or restart the app.
5. Before filing a bug, check the strip: if it is visible, the response may be forced. Overridden requests are marked in the log and in the HTTP inspector.

## Example

`example/` is a blank app using the package. Generate platform folders with `flutter create .` inside `example/`, then run it.

## License

MIT — see [LICENSE](LICENSE).
