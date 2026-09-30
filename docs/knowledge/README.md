# Engineering knowledge base

This directory is **not** `docs/design/`. `docs/design/` is the design source of truth
(lore, mechanics — Portuguese, written by the designer). This directory is the
**engineering** memory of the project: how things were actually built, what broke, what
the engine surprised us with, and how the game played the last time someone tested it.
It exists so that any agent (or human) opening this project cold can retrieve exactly the
prior knowledge relevant to the task at hand, instead of re-discovering it — or worse,
silently re-making a mistake already paid for once.

It is written **for retrieval**, not for reading front-to-back. Every file is one atomic,
self-contained unit — one architectural decision, one bug, one engine gotcha, one playtest
session. A future agent (or a RAG layer over this repo) should be able to pull a single
file and have everything it needs, without having to also load three other files first.

## The self-improvement rule

This is what makes the Godot skills "improve themselves": **every agent that touches this
codebase reads before it acts, and writes after it learns something new.**

- `godot-architect` greps `architecture/` and `gotchas/` for prior art before planning a
  new system, and adds an `architecture/` entry when a plan establishes a genuinely new
  reusable pattern (not for every plan — only when the pattern isn't already documented).
- `godot-reviewer` greps `bugs/` and `gotchas/` for the area under review before reviewing,
  and adds a `bugs/` entry for every confirmed bug (not style nits), and a `gotchas/` entry
  whenever it discovers a non-obvious Godot/GDScript behavior while reviewing.
- `godot-playtester` always adds a `playtests/` entry — that is its entire output.
- Any agent may add a `features/` entry once a gameplay system is implemented and stable
  enough to describe (not while it's still being iterated on).

If you are an agent reading this: **do not skip the write step because the task felt
small.** A gotcha that costs you 20 minutes to figure out will cost the next agent another
20 minutes unless it's written down here. That repeated cost is exactly what this
directory exists to eliminate.

## File format (all categories)

Every entry is a single Markdown file with this frontmatter:

```yaml
---
id: <category>/<slug>              # matches the file's path, e.g. architecture/character-controller-input-split
type: architecture | feature | bug | gotcha | playtest
title: One line, human-readable
status: active | superseded | deprecated   # superseded entries stay, but point to what replaced them
tags: [lowercase, kebab-case, keywords]
related: [other/entry-ids]         # link liberally; a dangling id is fine, it marks a gap
created: YYYY-MM-DD
updated: YYYY-MM-DD
source_files:                      # the files this entry is *about*, so it can be invalidated
  - path/to/file.gd
---
```

Body sections (skip any that don't apply, never leave one empty):

- **Summary** — one or two sentences. This alone should let a retriever decide if the
  file is relevant.
- **Details** — the actual content. Concrete: file:line references, not vague description.
- **Why** — the reasoning, especially if it's not obvious from the code.
- **Gotchas / pitfalls** — traps a future change could fall into.

`architecture/` entries that record an actual **decision** (not just "how this part of the
codebase works") use the ADR shape instead of Details/Why, because a decision without its
rejected alternatives is unfalsifiable — a future agent can't tell whether an option was
considered and rejected for a reason, or just never came up:

- **Context** — the problem/constraint that forced a choice.
- **Options considered** — the real alternatives, including the ones rejected, with why.
- **Decision** — which option, stated plainly.
- **Consequences** — what this commits future code to; what it makes harder.

**Revising a decision**: don't just flip `status` to `superseded` and lose the history.
Append a dated `## Revision (YYYY-MM-DD)` section to the *same* file describing what
changed, why the original Context/Decision no longer holds, and what's true now. Only
create a new file (and mark the old one `superseded` with a `related` link forward) when
the revision is big enough that the original Context section stops being accurate context
for the new state. The default is revise-in-place; a new file is the exception.

Bug entries additionally use:

```yaml
severity: low | medium | high | crash
```

and body sections **Symptom**, **Root cause**, **Fix** (file:line or commit), **Prevention**.

Playtest entries additionally use:

```yaml
build: <git commit short hash>
area_tested: e.g. "Bloom Guardian fight, home_village/bloom_hollow"
ratings: { fun: 1-5, fluidity: 1-5, aesthetics: 1-5 }
```

and body sections **What was tested**, **Findings** (bulleted, each with a screenshot
reference if visual), **Ratings rationale** — the ratings alone are not useful without the
reasoning, since a "3/5" from one session isn't comparable to a "3/5" from another unless
you can read why.

## Naming and structure rules (what keeps this RAG-friendly)

- One concept per file. If you're tempted to write "and also," make a second file and
  link it via `related` instead.
- Filenames are the slug: lowercase kebab-case, descriptive enough to guess the content
  without opening it (`animationtree-reset-track-overwrites-script-writes.md`, not
  `bug-3.md`).
- Keep files short — if it's pushing past ~150 lines it's probably two entries.
- Never delete an entry because it's outdated; set `status: superseded` and link forward.
  History of *why something changed* is as valuable as the current state.
- Update `INDEX.md` in the same edit that adds or changes an entry. The index is the fast
  scan path; an entry that isn't indexed is effectively invisible to a quick lookup.
- English, even though `docs/design/` is Portuguese — see the Glossary in the root
  `CLAUDE.md` for design-term-to-code-identifier mappings; use those identifiers here too.

## Directories

- `architecture/` — durable structural decisions and reusable patterns (the "how this
  kind of thing gets built here" knowledge).
- `features/` — one file per implemented gameplay system, describing what it does and
  where its pieces live, once it's stable.
- `bugs/` — confirmed bugs: symptom, root cause, fix, prevention. Not style feedback.
- `gotchas/` — Godot/GDScript engine behavior that surprised someone, independent of any
  one bug (the kind of thing that *causes* bugs if unknown).
- `playtests/` — dated playtest session reports, each with its own `screenshots/<slug>/`
  subfolder holding only the handful of frames that matter, not raw dumps.
