# cbreinit-confirm

ColdBox answers `?fwreinit=<password>` with `200 OK` whether or not the password was right. Was the reinit successful? Who knows?

This module solves that problem by adding a special response header to the request that reinitialised the app. It defaults to `X-Fwreinit: true`.

The header is only sent when the request carries a reinit key (`fwreinit`, or your `reinitKey`, in the URL or a form field). Requests without one never get it, so the module adds nothing to ordinary traffic. The one exception is the app's first request after a start, which loads ColdBox (see [What about server restarts?](#what-about-server-restarts)). A request with the wrong password gets no header unless you set `rejectedValue`.

| Request | Response header |
| --- | --- |
| `?fwreinit=right-password` | `X-Fwreinit: true` |
| `?fwreinit=wrong` | none, or `X-Fwreinit: <rejectedValue>` when that is set |
| No `fwreinit` | none |
| The app's first request, even with `?fwreinit=wrong` | `X-Fwreinit: true` (ColdBox loads without checking the password) |
| A 503 while another request is reloading, an error page, a non-`index.cfm` request | none |

Treat anything other than the success value (or the rejected value) as unconfirmed: a missing header can also mean a proxy stripped it. Don't let a CDN cache `?fwreinit=` responses, or it can replay the success header without reaching the app.

## How it works

ColdBox reloads inside the request that sent `fwreinit`, holding the application lock, before it handles that request. The module's `onLoad()` runs during that load and leaves a flag in the request scope, which belongs to that one request. On `preProcess`, which runs only after the load has succeeded (including the `applicationStartHandler`), an interceptor sends the header and clears the flag. Requests arriving during the reload wait on the lock, or get ColdBox's fail-fast 503. They never see the flag.

## What about server restarts?

The app's first request after the server or application starts also loads ColdBox, so it gets the header too, even without the `fwreinit` query string. 

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
		headerName    : "X-Fwreinit",
		// control characters are removed
		headerValue   : "true",
		// sent when the reinit key arrives with a wrong password; "" (the default) sends nothing
		rejectedValue : ""
	}
};
```

`rejectedValue` is off by default. When it is on, anyone who sends `?fwreinit=x` learns that the site runs ColdBox with a reinit password. With no `reinitPassword` set, every reinit succeeds, so the rejected value never appears. The module reads ColdBox's `reinitKey` setting, so a renamed key works.

## Develop

```bash
box run-script install:dependencies
box run-script start:2023
box run-script test
```

Each engine has its own start and stop scripts: `2023`, `2025`, `lucee6` and `boxlang`. They all use port 60302, so run one at a time.

The specs call the harness app over HTTP (`test-harness/tests/specs/ReloadHeaderSpec.cfc`). The harness sets `reinitPassword = "harness-pw"` and renames the reinit key to `harness-reinit` (so a hard-coded `fwreinit` would fail), sends `X-Harness-Reloaded: reloaded` (or `refused` for a wrong password), and turns on event caching so a spec can show a cached response never carries the header.

## License

[Apache License 2.0](LICENSE). Copyright 2026 David Levin, Angry Sam Productions, Inc.
