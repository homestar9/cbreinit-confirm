# cbreinit-confirm

ColdBox answers `?fwreinit=<password>` with `200 OK` whether or not the password was right. A deploy tool that reloads an app after a release can't tell from the answer whether the new code is loaded.

This module adds a response header, by default `X-Fwreinit: true`, to the request that reinitialised the app. Other requests never get it, and neither does a reinit with a wrong password.

```text
GET /?fwreinit=right-password   200 OK   X-Fwreinit: true
GET /?fwreinit=wrong            200 OK   (no header)
GET /                           200 OK   (no header)
```

## How it works

ColdBox reloads inside the request that sent `fwreinit`, holding the application lock, before it handles that request. The module's `onLoad()` runs during that load and leaves a flag in the request scope, which belongs to that one request. On `preProcess`, which runs only after the load has succeeded (including the `applicationStartHandler`), an interceptor sends the header and clears the flag. Requests arriving during the reload wait on the lock, or get ColdBox's fail-fast 503. They never see the flag.

The app's first request after the server or application starts also loads ColdBox, so it gets the header too. That load is a real one.

## Requirements

- ColdBox 8
- Adobe ColdFusion 2023 or 2025, Lucee 6, or BoxLang 1 with `bx-compat-cfml`

## Install

```bash
box install cbreinit-confirm
```

No change to `Application.cfc` is needed.

## Settings

In `config/ColdBox.cfc`:

```js
moduleSettings = {
	"cbreinit-confirm" : {
		// letters, digits and "-"; any other name sends nothing
		headerName  : "X-Fwreinit",
		// control characters are removed
		headerValue : "true"
	}
};
```

The header says nothing a caller doesn't already know: getting it requires the right reinit password. You can still set a value of your own so the confirmation can't be confused with another app's.

## DeployBot

On the site's edit page in DeployBot, under **Reinit and health**, set **Reload confirmation header** to the module's `headerName` and **Reload confirmation value** to its `headerValue` (`reinit.confirmHeader` / `reinit.confirmValue` in `config.json`). A reinit that answers 200 without the header then fails the deploy, which catches a wrong reload password.

## Develop

```bash
box run-script install:dependencies
box run-script start:2023
box run-script test
```

Each engine has its own start and stop scripts: `2023`, `2025`, `lucee6` and `boxlang`. They all use port 60301, so run one at a time.

The specs call the harness app over HTTP (`test-harness/tests/specs/ReloadHeaderSpec.cfc`). The harness sets `reinitPassword = "harness-pw"`, sends `X-Harness-Reloaded: reloaded`, and turns on event caching so a spec can show a cached response never carries the header.

## License

Apache 2.0
