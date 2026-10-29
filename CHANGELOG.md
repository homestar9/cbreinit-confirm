# Changelog

## [Unreleased]

### Added

- The request that reinitialises the app gets a response header, `X-Fwreinit: true` by default; `headerName` and `headerValue` in `moduleSettings` change it. Ordinary requests, a reinit with a wrong password, and responses served from ColdBox's event cache get none.
- Requires ColdBox 8. Tested on Adobe ColdFusion 2023 and 2025, Lucee 6, and BoxLang 1 with `bx-compat-cfml`.
