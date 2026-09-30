# Playtest capture harness

Used by the `godot-playtester` agent (see `.claude/agents/godot-playtester.md`) and the
`godot-playtest` skill. Not part of the shipped game.

## Running it

```
"<godot>" --path . res://tools/playtest/playtest_runner.tscn -- --script=res://tools/playtest/scripts/<name>.json --out=<absolute output dir>
```

- Must run **windowed** (no `--headless`) — screenshot capture needs a real rendering
  device. A game window will briefly appear and drive itself; this is expected.
- `--script` points at a JSON timeline (see `scripts/example_walk_jump_roll.json`):
  `{ "scene": "res://...", "max_duration": <seconds>, "player_position": [x, y], "steps": [...] }`
  (`player_position` is optional: it teleports Ivo there right after the scene loads;
  optional `"known_songs": [0]` teaches those `Enums.Song` ids through the save first, so
  a timeline can play a song without sitting its lesson). Each step has a
  `t` (seconds since load) and either `"screenshot": "<name>"`, or
  `"action": "<input action name>", "pressed": true|false` to simulate a press/release via
  `Input.parse_input_event()` with a constructed `InputEventAction` — this drives both
  polled state (`Input.is_action_pressed`/`get_axis`, what movement reads) and the
  `_input()` callback chain (what `PlayerInput`'s discrete signals — jump, roll, attack —
  actually fire from). `Input.action_press()`/`action_release()` alone is NOT enough: it
  only sets polled state and silently never triggers `_input()` (see
  `docs/knowledge/gotchas/input-action-press-does-not-reach-input-callbacks.md`) — this
  cost a full debug cycle on the first real run, don't reintroduce it.
- `--out` must be an **absolute filesystem path** (not `res://`); the runner creates it if
  missing and writes `<name>.png` for every `screenshot` step there, then quits on its own
  once the timeline ends or `max_duration` is hit (default 60s safety cap).

## Writing a new timeline

Copy `scripts/example_walk_jump_roll.json`. Action names must exist in `project.godot`'s
input map (`move_left`, `move_right`, `jump`, `roll`, `attack`, `draw_memorina`,
`note_up`/`note_down`/`note_left`/`note_right`, `look_up`, `look_down`). Space steps far
enough apart that an animation/transition actually finishes before the next input lands —
check clip durations in the relevant `AnimationResolver` if timing looks off in the
captured frames.

## What this cannot do

It cannot judge *feel* — input latency, camera smoothing, the subjective sense of weight
— from static frames alone. It's good for: layout/aesthetic regressions, animation glitches
across a sequence of frames, HUD placement, obviously broken states. See the
`godot-playtester` agent's "What this cannot judge" section before writing playtest
findings that claim more confidence than screenshots can support.
