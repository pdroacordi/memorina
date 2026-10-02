---
id: gotchas/csv-translations-unescape-backslash-n
type: gotcha
title: A literal \n in i18n/translations.csv becomes a newline in the imported translation; a real line break splits the CSV row
status: active
tags: [i18n, translation, csv, import, newline, label]
related: [systems/screens]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - i18n/translations.csv
---

## Summary

Godot 4.7's CSV translation importer unescapes `\n` (the two characters backslash, n) in a
value into a newline. Measured 2026-10-02: `tr("CONFIRM_QUIT_GAME")` in pt_BR printed
through `JSON.stringify` as `"Sair do jogo?\nO progresso…"`, a real newline (an
unconverted backslash would print as `\\n`).

## Details

- Use `\n` to force a line break where autowrap would leave a bad one (the quit question
  sits on its own line in both languages).
- A real line break inside a value ends the CSV row. The rest of the text becomes a
  malformed next row, and the key is cut short.

## Gotchas / pitfalls

- Shell heredocs and some tools turn `\n` into a real newline while writing the CSV. Check
  the row with `grep -n KEY i18n/translations.csv` after any scripted edit.
- Re-run `--import` after editing the CSV; the `.translation` files are build output.
