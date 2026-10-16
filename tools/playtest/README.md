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
- **`t` is unpaused time.** The runner runs ALWAYS but counts `t` only while the
  tree is not paused, so the seconds a performance freezes the world (the excerpt,
  ~7 s) do not count: a pulse appears about 1.6 s after its last note in `t`, not
  9 s later. A timeline that waits in `t` for the performance to end is idling in
  the world, and a song's pulse runs out while it waits (the first
  Soltar-then-Vendaval run did). A timeline that opens a menu (the pause menu
  freezes the tree) sets `"clock": "real"` so its steps keep firing while paused.
  `max_duration` is measured on the same clock as `t`. A separate real-time watchdog
  (`max_duration * 3 + 30` s) ends a hung run with an error and exit code 1.
- **Raw device steps.** An `"action"` step matches only its own action, so it cannot
  reproduce a key bound to several (Z is `jump` and `ui_accept`) and GUI buttons ignore
  it. `"key": "<name>"` (an `OS.find_keycode_from_string` name: `Z`, `Escape`, `Enter`,
  `Down`, `Shift`), `"joy_button": <index>` and `"joy_axis": [axis, value]` send the real
  event, with `"pressed"` as for actions. `"log": "<label>"` prints pause, time scale, GUI
  focus, Ivo's motion, sit and animation state, hp, attack/climb/drawn, whether `PlayerInput`
  is blocked, the open screen, the map's centre and zoom, and the seen map cells per room key
  to stdout. A timeline's
  `"skills": [ids]` unlocks `Enums.PlayerSkill`s (roll is 2) the way `known_songs` teaches
  songs. `"met_guardians"` / `"restored_guardians": [ids]` (`Enums.Guardian`) and
  `"notebook_read": ["<entry id>"]` seed the save the same way; `"owned_items": [ids]` (`Enums.PlayerItem`: 0 the
  sword, 1 the Memorina) sets the owned items to exactly that list, so a run can start without the items a debug new
  game owns (`[]` owns nothing); `"dialogues_heard": ["<dialogue id>"]` marks talks heard and
  `"responses": {"<ask id>": "<choice id>"}` records answers, so a run can start mid-story (`systems/story`), and `"locale": "en"` sets
  the locale before the scene loads (the default is the OS locale). `log` also prints the
  notebook: phase, section, the entry on the right page, its rows (`>` focused, `*` unread,
  `()` hidden), the scroll cues, tab marks, read ids, the HUD quill's alpha and the
  watcher's queue. It also prints the current room id and `interior`, the camera bounds and
  centre, the fade's alpha, `transitioning`, Ivo's facing and process mode, whether the region weather
  is visible, every loaded door (`link@x:open|sealed[+prompt] shake=<sprite x>`), and the region title's
  alpha, text and the count of announced regions (`title=<alpha> '<name>' announced=<n>`).
- **Teleport.** `"teleport": [x, y]` moves Ivo mid-run with `Character.teleport`, as `player_position` does at the
  start, so one timeline can visit several rooms (the opening's errand, `systems/story`). The game enters the room under
  him with a cut.
- **`debug_trials` presses.** Every F10 (`debug_trials`) the runner sees prints a `[playtest] debug_trials` line: the time, the event's text, class and device, whether the timeline sent it, and whether the window had focus (an unexplained F10 once moved Ivo to the song trials: `playtests/2026-10-16-story15-cutscenes`).
- **Per-frame trace.** `"trace": true` prints one `[playtest] trace` line every physics frame until a
  `"trace": false` step: Ivo's position, velocity, floor, helix ride and progress `u`, the camera's centre and hp.
- **Foes.** `log` and `trace` lines end with `foes=[...]`: every enemy and guardian within 600 px of Ivo, its
  offset from him, a brute's hp, `swing` and `knocked`, or a guardian's phase, hit progress (0..1) and
  `telegraph`/`swing`. Combat timelines read hits and dodges from it (`core09_*.json`).
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
