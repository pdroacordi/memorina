---
id: gotchas/logger-log-error-also-receives-warnings
type: gotcha
title: A custom Logger's _log_error() also receives push_warning() (error_type 1), not just errors
status: active
tags: [logger, smoke-test, warnings, tooling]
related: []
created: 2026-09-30
updated: 2026-09-30
source_files:
  - tools/smoke/smoke.gd
---

## Summary

`Logger._log_error(function, file, line, code, rationale, editor_notify, error_type,
script_backtraces)` is called for engine warnings and `push_warning()` as well as for
errors. Only `error_type` tells them apart: 0 error, 1 warning, 2 script, 3 shader.
Measured on 4.7.2: a logger added with `OS.add_logger()` received `push_warning("just a
warning")` as `error_type=1`.

## Details

`tools/smoke/smoke.gd` counts every `_log_error` call as an error and exits 1. So a
smoke run fails on warnings too: `WaterLayer`'s "water painted ... is not drawn", an
`ArtPrompt` unknown field, any engine performance warning. Its docstring and CLAUDE.md
say "any logged error". That is either an undocumented strictness or a false FAIL,
depending on intent.

## Gotchas / pitfalls

- Filter on `error_type` if you mean only errors. Keep warnings in a separate list if the
  tool should show them without failing.
