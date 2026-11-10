## 0.3.0

- `file_picker` is no longer a dependency, so no file plugin reaches the host's builds. Export and import of `.json` files now go through a `ScenarioFiles` the host passes to `DevKit.init(scenarioFiles: ...)`; the README has a file_picker implementation, and the example app uses it.
- Without `scenarioFiles`, the scenarios page offers **Copy as JSON** and **Paste JSON**.

## 0.2.0

- Scenarios can be added on the device: **Add scenario** on a recorded request (or on the scenarios page) opens a form prefilled from the request. A case is either a mock response or request headers.
- `ScenarioMock`: a case can answer locally with a status, headers, body and delay, without calling the backend. `ScenarioCase.headers` is now optional.
- Custom scenarios are saved with `SharedPreferences` (or a `ScenarioStorage` passed to `DevKit.init`) and load on start.
- Scenarios page: export to a `.json` file, import from a file or pasted JSON, delete custom routes and cases.
- A selected custom route wins over a route from the code that matches the same request. `ScenarioRegistry.allMatches`, `put` and `remove` were added.
- Scenarios, cases and matchers convert to and from JSON (`toJson` / `fromJson`). `RouteMatcher` exposes `kind` and `pattern`.
- The panel always shows **Backend scenarios**, so scenarios can be added before any are registered.
- New dependencies: `shared_preferences`, `file_picker`.
- Redesigned DevKit pages: card-based dev panel, inspector list with status and method badges, a detail page with Overview / Request / Response tabs, JSON syntax colouring and per-section copy buttons, and a scenarios page with case chips instead of dropdowns.
- DevKit pages follow the device's light or dark mode.
- Smoother under heavy traffic: the inspector list updates at most every 100 ms, a request's body is pretty-printed once instead of on every rebuild, and choosing a scenario case rebuilds only that route's card.

## 0.1.2

- README: install snippet points at the current version.

## 0.1.1

- Document the whole public API.
- Set the formatter page width to 120 in `analysis_options.yaml`.

## 0.1.0

- First release.
- Dev panel with host-registered items (`DevKit.addItem`).
- HTTP inspector for Dio: request list with search and filters, detail screen, copy as cURL, redaction hook.
- Backend scenarios: per-route header overrides picked by QA at runtime, with a warning strip while any route is overridden.
