---
id: bugs/<slug>
type: bug
title: <one line, symptom-first>
status: active
severity: low | medium | high | crash
tags: []
related: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source_files:
  - path/to/file.gd
---

## Summary

One or two sentences: what breaks and under what condition.

## Symptom

What was observed — reproduction steps if known, or the playtest/review context it was
found in.

## Root cause

The actual mechanism, with file:line references. Not "seems to be" — trace it.

## Fix

What changed, where (file:line, and commit hash once committed).

## Prevention

What would have caught this earlier (a test, an assert, a review checklist item) — and
whether that safeguard was actually added.
