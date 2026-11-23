# Changelog

## [Unreleased]

## [1.1.0] - 2026-11-23

### Added

- `rejectedValue` setting: a request that sends the reinit key with a wrong password gets the header with this value, so a deploy tool can tell "password refused" from "no answer". Off by default (`""`), which keeps 1.0.0's behaviour. Honours a renamed `reinitKey`.

## [1.0.0] - 2026-10-29

### Added

- The request that reinitialises the app gets a response header, `X-Fwreinit: true` by default; `headerName` and `headerValue` in `moduleSettings` change it. Ordinary requests, a reinit with a wrong password, and responses served from ColdBox's event cache get none.
- Requires ColdBox 8. Tested on Adobe ColdFusion 2023 and 2025, Lucee 6, and BoxLang 1 with `bx-compat-cfml`.
