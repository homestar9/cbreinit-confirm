# cbreinit-confirm: ColdBox 8, engine support and ForgeBox readiness

## Context

The module itself is finished: `ModuleConfig.cfc` + `interceptors/ReloadConfirmation.cfc`, a README,
an `[Unreleased]` changelog entry, and four HTTP specs that pass on Adobe 2023. It is **not ready to
publish yet**:

- **Wrong ColdBox target.** The harness pins `coldbox: ^7.0.0` (`test-harness/box.json`), which
  resolved to 7.5.2. This is meant to be a **ColdBox 8** module. ColdBox 8.4 supports Adobe 2023+,
  Lucee 5+ and BoxLang 1, so all four target engines are covered.
- **Not a Git repo**, no `origin`. `commandbox-release` (`box release check`) fails without both.
  `box.json` points at `github.com/homestar9/cbreinit-confirm`, which must exist before release.
- **No `release.json`.**
- **Only Adobe 2023 is tested.** Targets: Adobe 2023, Adobe 2025, Lucee 6, BoxLang 1 (bx-compat-cfml).
- **Version drift:** `ModuleConfig.cfc` hard-codes `this.version = "0.1.0"`. `box release bump`
  changes only `box.json`.
- **Likely BoxLang/Java-regex bug:** `ReloadConfirmation.cfc:21` strips `[[:cntrl:]]`. Java
  regex reads that as the set `[:cntrl]`, so `true` would come out as `ue`. The harness value `yes`
  has none of those letters, so the specs can't catch this.
- `plans/` isn't in the `box.json` ignore list.

### Event caching (user question): not a bug, but unguarded
I checked against the ColdBox 8.4 source (`coldbox-platform/system/Bootstrap.cfc:236-395`,
`RequestContext.cfc:2412`) and the harness's 7.5.2 copy:
- The event cache stores `event.getResponseHeaders()`. That holds **only headers set through
  `event.setHTTPHeader()`**. The interceptor uses raw `cfheader()`, so its header never enters the
  cache entry.
- `preProcess` is announced **before** the cache lookup, so a reinit request answered from cache
  still gets the header. The flag lives in `request` scope, so a later cache hit sees no flag and
  sends nothing.
- The worst case is an action with `cacheExclude="fwreinit"` (ColdBox 8 annotation), or a
  `cacheFilter`. Then a reinit request and a plain request share one cache key, and the reinit
  response gets cached. The header is still not replayed, because of the `cfheader` choice.

So this is safe today, but only because of `cfheader`. Someone switching to the more "ColdBox-y"
`event.setHTTPHeader()` would bring the bug in. The plan adds a comment and a regression spec.

The user chose: first release is **1.0.0**, plus a **GitHub Actions matrix** like cbAccessibility's.

## Changes

### 1. Move the harness to ColdBox 8
- `test-harness/box.json`: `"coldbox": "^8.0.0"`, then reinstall (`box run-script install:dependencies`).
- `test-harness/config/Coldbox.cfc`: set `eventCaching = true`. This is required for step 6.
  Check that the harness's `afterAspectsLoad` module registration still works on 8. The specs
  passing proves it.
- `README.md`: add a **Requirements** section: ColdBox 8+, Adobe 2023/2025, Lucee 6, BoxLang 1
  with bx-compat-cfml.

### 2. Engine configs (copy the pattern from `D:\Dropbox\Repositories\appdotenv\server-*.json`)
Keep port **60301** and the `"/moduleroot/cbreinit-confirm":"../"` alias from `server-adobe@2023.json`.
- `server-adobe@2025.json`: `adobe@2025`, `.engine/adobe2025`, `openjdk21_jre`,
  `onServerInstall: cfpm install zip`, `cfconfig.file: .cfconfig.json`.
- `server-lucee@6.json`: `lucee@6`, `.engine/lucee6`, `openjdk21_jre`, cfconfig file.
- `server-boxlang-cfml@1.json`: `boxlang@1`, `.engine/boxlang-cfml`, `openjdk21_jre`,
  `fusionreactor.enable:false`, `onServerInitialInstall: install bx-compat-cfml --noSave`.

### 3. `box.json`
- Add the `start/stop:2025`, `start/stop:lucee6`, `start/stop:boxlang` scripts (same names as appdotenv).
- `ignore`: add `/plans/`, `/release.json`, `/CLAUDE.md`, `/AGENTS.md`, and use `/test-harness/`.
- Leave `version` at 0.1.0. The release step bumps it to 1.0.0.

### 4. `ModuleConfig.cfc`: read the version from `box.json`
Change `this.version` to `readPackageVersion()`, copying the method from
`D:\Dropbox\Repositories\appdotenv\ModuleConfig.cfc:82-101`.

### 5. `interceptors/ReloadConfirmation.cfc`
- Line 21: change `"[[:cntrl:]]"` to `"[\x00-\x1F\x7F]"` (same meaning in ORO/Perl5 and Java regex).
- At the `cfheader` call, add a one-line comment: it uses `cfheader`, not `event.setHTTPHeader()`,
  because ColdBox's event cache replays headers set through the event to later requests.

### 6. Specs and harness
- `config/Coldbox.cfc`: change the harness `headerValue` from `"yes"` to `"reloaded"`, so the
  specs can catch regex mangling. Update the spec's expectations, its doc comment, and README line 56.
- `handlers/Main.cfc`: add a `cached` action with `cache="true" cacheTimeout="5"
  cacheExclude="fwreinit"` that renders a short string. The reinit request and the plain request
  then share one cache key, which is the worst case.
- `ReloadHeaderSpec.cfc`: new spec, "does not replay the header from ColdBox's event cache". It sends
  `GET /index.cfm/main/cached?fwreinit=harness-pw` (header present; the reinit cleared CacheBox, so
  this response gets cached), then `GET /index.cfm/main/cached`. The second response must have
  `x-coldbox-cache-response: true` (proving it came from cache) and must **not** have the header.
  Change `send()` only if it needs to.

### 7. CI: `.github/workflows/tests.yml`
Adapt `D:\Dropbox\Repositories\cbAccessibility\.github\workflows\tests.yml`, unit-job shape only:
- A matrix over the 4 server configs, `fail-fast: false`, Temurin 21.
- `box install` + `cd test-harness && box install`, then start the server.
- Poll `http://127.0.0.1:60301/` before running the tests.
- Run `box testbox run runner=http://127.0.0.1:60301/tests/runner.cfm`.
- Print the server log on failure.

### 8. Release setup
- `release.json`, modeled on appdotenv's: 4 `engines`, `runTests: true`,
  `testRunner: http://127.0.0.1:60301/tests/runner.cfm`, `branch: master`, ForgeBox + GitHub, and
  `requires` set to the installed commandbox-release version.
- `CHANGELOG.md` `[Unreleased]`: note the supported engines and that ColdBox 8 is required.
- `git init` + commit. **Ask the user before** creating the GitHub repo or adding `origin`.

## Verification

1. `box run-script install:dependencies`, then confirm `test-harness/coldbox/box.json` shows 8.x.
2. For each of `2023`, `2025`, `lucee6` and `boxlang`, run `box run-script start:<engine>`, then
   `box run-script test`, then `box run-script stop:<engine>`. All 5 specs must pass on every
   engine, including the new event-cache spec.
3. Sanity-check the regression spec: temporarily switch the interceptor to `event.setHTTPHeader()`
   and confirm the cache spec fails. Then revert.
4. `box run-script format:check`.
5. `box release check`. It should be clean once the repo and remote exist.
6. `box release publish major --dryRun` should build 1.0.0. The zip should hold only
   `ModuleConfig.cfc`, `interceptors/`, `box.json`, `README.md` and `CHANGELOG.md`.
7. The real `box release publish major` runs only after the user says so.
