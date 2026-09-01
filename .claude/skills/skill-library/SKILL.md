---
name: skill-library
description: Router into ECC's full skill/agent/rule catalog for Memorina (Godot/GDScript). Use when a task needs something outside the small DAILY set — e.g. security review, PR creation once a remote exists, cost reporting, or any off-stack reference (web/React/Python/etc patterns) that shows up while researching an idea.
metadata:
  origin: project (agent-sort)
---

# Skill Library — Memorina

Memorina is a solo-dev, GDScript-only Godot 4.7 project (no JS/Python/Go/Rust/etc, no CI yet,
no test framework yet, no GitHub remote yet). ECC ships ~286 skills, 94 commands, 68 agents,
mostly for stacks this repo doesn't use. This router keeps the daily context small and points
at everything else on demand.

## DAILY (already loaded / invoked directly every session)

- `ecc:git-workflow` — commit/branch discipline (git repo, no remote yet)
- `ecc:plan` — restate requirements + step plan before touching code
- `ecc:code-review` — generic local-diff review (pairs with the project's own
  `.claude/agents/godot-reviewer.md` for Godot-specific checks; this skill is the
  language-agnostic workflow wrapper, not a duplicate reviewer)
- `ecc:checkpoint` — verification checkpoints for a solo dev with no CI
- `ecc:save-session` / `ecc:resume-session` — carry narrative/design context across sessions
- `rules/common/*` (git-workflow, code-review, coding-style, development-workflow, patterns,
  testing, security, performance, agents, hooks) — the only rule set that isn't language-locked
- Plugin-level hooks already active regardless of stack: `gateguard-fact-force`,
  `mcp-health-check`, `config-protection`, `doc-file-warning`, `suggest-compact`,
  `observe` (continuous-learning capture) — nothing to install, just confirmed compatible

Project-specific agents `godot-reviewer` and `godot-architect` already cover Godot code
review and architecture planning — do not add ECC's generic `architect`/`code-architect`/
`code-reviewer`/`planner` agents on top of them.

## LIBRARY (search or invoke on demand — not loaded by default)

Trigger keywords → where to look:

- **"PR", "pull request", "GitHub"** → `ecc:pr`, `ecc:review-pr` (dormant until a remote exists)
- **"security", "vuln", "secrets scan"** → `ecc:security-review`, `ecc:security-scan`
- **"cost", "spend", "token budget"** → `ecc:cost-tracking`, `ecc:cost-report`, `ecc:token-budget-advisor`
- **"ADR", "decision record"** → `ecc:architecture-decision-records`
- **"dead code", "refactor cleanup"** → `ecc:refactor-clean`
- **"codemap", "architecture doc"** → `ecc:update-codemaps`, `ecc:update-docs`
- **"tests", "coverage", "TDD"** → `ecc:test-coverage`, `ecc:tdd-workflow` (no test framework
  configured yet in this repo — install a GDScript test runner like GUT before these apply)
- **"instincts", "learned patterns"** → `ecc:instinct-status`, `ecc:learn`, `ecc:learn-eval`,
  `ecc:promote`, `ecc:prune`
- **"hookify", "custom hook"** → `ecc:hookify`, `ecc:hookify-configure`, `ecc:hookify-list`
- **"model routing", "which model"** → `ecc:model-route`
- **"self-eval", "quality scorecard"** → `ecc:agent-self-evaluation`
- **"onboard ECC", "reinstall", "repair install"** → `ecc:configure-ecc`, `ecc:project-init`
- **"overlap", "skill catalog cleanup"** → `ecc:skill-stocktake`
- **"context trimming"** → `ecc:strategic-compact`

Everything else — every per-language reviewer/build-resolver/TDD/pattern skill and agent
(React, Vue, Python, Django, Go, Rust, Kotlin, Swift, Java/Spring, PHP/Laravel, C++, C#,
Flutter/Dart, network/homelab, healthcare, finance, etc.) is off-stack for a pure-GDScript
project. It is not deleted — ECC still has it — it's just never loaded here. If a task
genuinely needs one (e.g. researching how another engine's community solved something),
search ECC's `skills/` or `agents/` directory directly by name rather than asking for it
to be added to DAILY.

## Where the full catalog lives

`C:\Users\Pedro\.claude\plugins\cache\ecc\ecc\2.2.1\` — `skills/`, `agents/`, `commands/`,
`rules/`, `hooks/hooks.json`. Full bodies are not duplicated here; read them directly when
a LIBRARY item is actually needed.
