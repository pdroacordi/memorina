---
id: playtests/<date>-<slug>
type: playtest
title: <area tested, one line>
status: active
build: <git short hash>
area_tested: <e.g. "Bloom Guardian fight, home_village/bloom_hollow">
tags: []
related: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/<date>-<slug>/<name>.png
---

## What was tested

The scripted timeline or manual actions actually performed this session.

## Findings

- Bulleted, concrete. Reference a screenshot filename where the finding is visual.
- Distinguish a confirmed bug (file a bugs/ entry and link it here) from a subjective feel
  note (belongs only here).

## Ratings rationale

Explain each number in `ratings` — a bare score is not useful without why. Be honest
about what a screenshot-based evaluation cannot judge (see the godot-playtester agent's
"What this cannot judge" section) rather than overclaiming confidence in the fun/fluidity
scores.
