## Unreleased

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
