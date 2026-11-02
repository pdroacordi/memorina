---
name: song-loop
description: Make one or more pieces of Memorina's music end to end - study, composer proposal, user approval, AIVA generation, user choice, check, into the game, commit - asking the user at every gate. Use when the user says "faça a música de X", "as versões reduzidas", "continue as canções", or asks for a run over several pieces.
---

# song-loop

The feature-loop for music. The orchestrator (you) keeps a RUN-PLAN, hands composing to the `composer` agent and AIVA work to the `aiva` skill, and **asks the user before anything is generated, downloaded as new, put into the game or committed** ("sempre antes de finalizar ou fazer qualquer coisa, me consultar para ver se eu aprovo", user, 2026-11-02).

## Step 0: the RUN-PLAN

`RUN-PLAN.md` in the session scratchpad (never the repo), re-read after any compaction. It holds the pieces in order, each one's status (todo / proposed / approved / generated / chosen / in game / committed), the user's decisions verbatim with the date, the downloads spent, and open questions. Confirm the list with the user first.

## Per piece, one at a time

| # | Step | Who | Gate |
|---|---|---|---|
| 1 | **Study.** The piece's design, where it plays, what it must carry; `systems/music` and `docs/knowledge/music/`. | you | |
| 2 | **Propose.** Run the `composer` agent with the piece, its use and its constraints. | composer | |
| 3 | **Show.** Send the user the proposal in Portuguese and the MIDI sketches (SendUserFile). | you | **user approves, changes or refuses** |
| 4 | **Generate.** In AIVA (`aiva` skill): the approved recipe, 2-4 variants. Say the downloads it costs before starting. | aiva | **user approves the spend** |
| 5 | **Choose.** Download the variants' MP3 (scratchpad) and send them to the user. | you | **user picks one or asks another round** |
| 6 | **Check.** Download the chosen piece's MIDI; verify against `systems/music`: the motif's six notes in order at beat 0, white keys, length; for an excerpt, the same start as its track. A failure goes back to step 4. | you | |
| 7 | **Into the game.** WAV → OGG under `assets/audios/soundtrack/`; wire it (`Song.track`, `excerpt`, the cutscene's sound); measure and set `note_cues` from the onsets measured in the rendered WAV (AIVA adds a lead-in); trim the excerpt to `excerpt_duration`; no `CREDITS.md` line (full authorship); import; the `verify-gates` skill; a playtest when it plays in a scene the player sees. | you | |
| 8 | **Record.** `systems/music` (the table, the decision in the user's words with the date), `docs/knowledge/music/` (what was learned), the roadmap row. | you | |
| 9 | **Commit.** Show the file list and message. | you | **user approves** |

Stage explicit paths only (another session may have work in progress). Semantic message, body ending `Roadmap: <ID>` when there is one. No co-author trailer, no push unless asked.

## At the end

Report per piece: its status, the files, the downloads spent and left, the commit hash, and what waits on the user.
