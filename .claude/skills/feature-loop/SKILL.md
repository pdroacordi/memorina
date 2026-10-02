---
name: feature-loop
description: Work through one or more roadmap items end to end - study, plan, implement, gates, playtest, knowledge, roadmap, commit - with a RUN-PLAN in the scratchpad that survives context compaction. Use when the user says "do the next items", "work through PZL-02 to PZL-05", "continue the roadmap", or asks for a multi-step feature run.
---

# feature-loop

The orchestrator (you) stays lean: it decides, keeps the RUN-PLAN current and hands heavy work to the project agents. Invoking this skill is the user's go-ahead to use those agents.

## Step 0: the RUN-PLAN

Write `RUN-PLAN.md` in the session scratchpad (never in the repo). Re-read it after any compaction before doing anything else. It holds:

1. The ordered items, by roadmap ID (`docs/roadmap.md`), respecting `Needs`.
2. Per item: status (todo / doing / done / handed back) and the commit hash when done.
3. Decisions taken and where they were recorded.
4. Questions waiting for the user.

Confirm the list with the user at the start: what is in, what is out, what needs them (art they must approve, a `[?]` decision).

## Per item, one at a time

Items run in sequence, never in parallel: most of them touch `game.tscn`, `player.gd` or `project.godot`.

1. **Study.** Read the item's row, its design sections in `docs/design/`, and the `docs/knowledge/systems/` entry for every system it touches. Grep `docs/knowledge/bugs/` and `gotchas/` for the files involved.
2. **Plan.** For a new system or a non-trivial change, run the `godot-architect` agent. Write down what will change. A question only the user can answer (design intent, feel, scope) goes to the RUN-PLAN and the item is handed back; skip to the next independent item.
3. **Mark it.** Set the roadmap row to `[~]` with today's date.
4. **Implement.** Pure logic first, in a `RefCounted` with a gdUnit4 suite under `tests/`. Follow `CLAUDE.md`; the comment rules apply to new code.
5. **Gates.** Run the `verify-gates` skill. Red means back to step 4 with the concrete failure.
6. **Review.** Run the `godot-reviewer` agent on the diff. Fix confirmed findings; it files bugs in the knowledge base itself.
7. **Playtest.** If the item is gameplay-visible, run the `godot-playtest` skill and read the screenshots against what the item should show. A bug goes back to step 4.
8. **Knowledge.** Update the `docs/knowledge/systems/` entry the item changed (or create one for a new system), add any new gotcha, keep `docs/knowledge/INDEX.md` in sync. A user decision is recorded in their words, with the date.
9. **Roadmap.** Set the row to `[x]`, today's date, link the systems entry in Notes. Add any follow-up the work exposed as a new `[ ]` row.
10. **Commit.** Stage explicit paths, only the files this item touched (never `git add -A`: another session may have work in progress). Semantic message, `type(scope): summary`, body ending `Roadmap: <ID>`. No co-author trailer, no mention of Claude. Do not push unless the user asked.
11. **Update the RUN-PLAN** and continue.

## At the end

A short report: items done with their commit hashes, items handed back with the question each needs, follow-ups added to the roadmap.
