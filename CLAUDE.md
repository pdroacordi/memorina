# Memorina

Godot 4.7 (GDScript, Forward+ renderer), 2D metroidvania. Design source of truth lives in [`docs/design/`](docs/design/) — `01_lore_e_narrativa.md` (lore/narrative) and `02_mecanicas.md` (mechanics). Both are in Portuguese (working design language); read them for gameplay/story context before implementing a system that touches lore or mechanics.

## Architecture principles

Bias hard toward object-oriented design and SOLID/KISS. Concretely, in Godot terms:

- **Composition over inheritance.** Prefer small, single-purpose scripts wired together over deep `extends` chains. Reserve inheritance for genuinely "is-a" relationships on engine base classes; use it sparingly even then.
- **Single responsibility per script/node.** A script should do one thing. If a node's script is handling input, physics, *and* state bookkeeping, split it — see `PlayerInput` / `Player` in `scenes/characters/player/` as the reference pattern: the input node owns all knowledge of `Input`/`InputEvent` and action names, and the logic node owns state and behavior. Extend this same split for every future controller (guardians, enemies, UI controllers) rather than reading `Input` directly inside a logic node.
- **Continuous input is a property; discrete input is a signal.** On an input node, continuous state (movement axes, held modifiers, directional ocarina input) is exposed as a typed read-only property that the logic node polls — sampled on read, never cached in `_physics_process`, which would reintroduce a one-frame lag since Godot processes parents before children. Discrete events (jump pressed/released, dash, attack, pause) are signals. A past-tense "changed" signal carrying a *level* value is the anti-pattern: it fires every frame, forces every consumer to keep a shadow copy of the value, and makes downstream logic accidentally depend on the emission cadence.
- **Signals for decoupling (Observer).** Nodes that need to react to something emit or listen to signals rather than reaching into each other via `get_node()` chains or tight parent/child coupling.
- **Resources for interchangeable data/behavior (Strategy).** Data-driven variation (e.g. per-guardian attack patterns, per-season note-sequence definitions) belongs in custom `Resource` subclasses, not in branching logic inside a single script.
- **Shallow scene trees.** If a scene's node hierarchy is growing deep to express behavior rather than actual spatial/rendering structure, that's a sign to extract a script or sub-scene instead.
- **No god-classes, no god-autoloads.** Autoload singletons are for genuinely global state (e.g. game progress) — keep them thin, delegate logic elsewhere.
- **The character substrate.** `Character extends CharacterBody2D` (`scenes/characters/character.gd`) is the shared base. It owns only what every character has: facing, gravity, health/hurtbox wiring, knockback, and `_physics_process` as a template method (`_process_motion` -> `move_and_slide()` -> `_after_move`). Subclasses override those two hooks rather than `_physics_process`.
- `CharacterController extends Node` (`scenes/characters/character_controller.gd`) supplies movement intent. `PlayerInput` is one; enemy AI will be another. A `Character` never learns where its intent comes from. Its `direction` property uses the `get = _get_direction` form rather than an inline getter, because an inline getter cannot be overridden by a subclass.
- Behaviour split rule: generic behaviour goes in `scenes/characters/components/`; anything gated by `Enums.PlayerSkill` is a player ABILITY and goes in `scenes/characters/ivo/abilities/` instead, so enemies never inherit abilities they cannot use.
- The skill gate is pushed onto ability components via a plain `enabled` flag at the moment the ability is attempted. Components never reference `SaveSystem`.

## GDScript conventions

- **Static typing everywhere for new code.** Use `:` for variable/param types, `->` for return types, `:=` for inferred assignment. This is a static-typing-first codebase.
- **Naming:** snake_case for files, functions, variables; PascalCase for classes (`class_name`); CONSTANT_CASE for constants; signals in snake_case past tense (e.g. `door_opened`); private members/methods prefixed with `_`.
- **Code identifiers are English**, even where they name a design concept described in Portuguese in `docs/design/` (e.g. the "Congelar" sequence → `freeze_sequence`, not `congelar`). Keep a mental (or eventually written) glossary mapping design-doc terms to their code names as they get implemented.
- **Class body order** (official GDScript style guide): annotations → `class_name` → `extends` → docstring → signals/enums/consts → exported vars → other vars → `@onready` vars → `_init()`/static methods → virtual methods (`_ready`, `_process`, etc.) → public methods → private methods → inner classes.
- Tabs for indentation, double quotes for strings, trailing commas in multi-line literals — standard Godot style guide.

## Animation

**Code decides, the AnimationTree renders.** Each character's `AnimationTree` is a flat set of clips with NO transitions and NO `advance_expression` strings. Two components sit beside it: `AnimationDriver` (generic playback — starts a clip only when the name changes) and an `AnimationResolver` (one concrete subclass per character: `PlayerAnimationResolver`, `BruteShadowAnimationResolver`). Every frame `Character._physics_process` calls `resolve()` on the resolver and hands the result to the driver. `resolve()` is an ordered priority chain; its order is the only tie-break anywhere.

- **The resolver owns the character's entire clip vocabulary** as `const` StringNames at its top, and nothing else names a clip — not the character script, not `Character`. The resolver reads the character's public predicates (`is_rolling()`, `just_hit()`, ...) and the driver; gameplay that needs to know an animation finished asks the resolver in gameplay terms (`is_death_finished()`, `is_spawn_finished()`). Adding an animation is: author the clip, add its node to the tree, add a const and one line at the right priority in the resolver. Never write a clip name as a loose `&"..."` literal — a typo in a const name fails to compile, a typo in a literal silently plays nothing. Never add a transition to a state machine.

- **Intro / one-shot clips** (`jump_start`, `fall_start`, `wall_landing`, `land`, `air_spin`, `hurt`, `spawn`) are held until they finish via `AnimationDriver.holding()` / `sequence()`; the resolver never needs their durations. An event that must restart the *same* clip (a pogo chain, a second hit mid-flinch) calls `AnimationDriver.request_replay()`. Events that arrive from the physics flush (hits, area triggers) land *after* the frame's `_physics_process`, so a pulse for them (`Character.just_hit()`) is cleared after the resolve, not before.
- **`RESET` is the default pose, and the tree owns every property it declares.** Each clip keys only what it changes (hitbox geometry per swing, i-frames); everything else blends back to `RESET`. Consequence: a script write to any property with a `RESET` track (`Hurtbox:monitorable`, `Hitbox:*`) is silently overwritten every frame. Gate the *decision* in script instead (`Character._on_hit_received` ignores hits while dead), or key it in the clip. `BruteShadow` keeps its tree inactive until spawn for exactly this reason.
- **Durations that must equal a clip's length are asserted at startup** in debug builds (`Character._assert_clip_length`): `roll_time + roll_recovery_time` vs the roll clip, every `AttackPhaseData.duration` vs its swing, `BruteShadowAttackStats.attack_duration` vs `attack`. Retune either side and the assert says which pair drifted.
- When a component takes over logic that previously emitted a signal from `Player`, `Player` must RE-EMIT that signal, because `ivo.tscn`'s connections are declared with `from="."`. This is why `Player` relays `jumped`, `double_jumped` and `hard_landed`.

## The greyhush (memory field)

The world's state at any point is a memory value from 0 to 1 (`docs/design/03_mundo_e_ambiente.md` sections 2-4). **It is not a colour filter.** A place at 0 is not merely grey, it is STOPPED — a branch caught mid-sway stays caught, and resumes from exactly there when colour returns. Lowering an animation's amplitude would be the wrong fix: that still leaves a cycle running.

- **`MemoryField` (in `game.tscn`, found by group) answers the CPU side; `GreyhushRenderer` feeds the GPU side.** The field never learns it is being drawn, and the renderer is the only place that converts world coordinates into game pixels.
- **`MemoryFieldMath.source_distance()` / `disc_influence()` and `gh_shape_distance()` / `gh_influence()` in `greyhush_common.gdshaderinc` are the same formulas written twice**, because GDScript and GLSL cannot share code. Change one and you MUST change the other. Every tunable reaches the shader as a uniform from `MemoryFieldMath`'s constants — never re-type a number into the shader.
- **The dithered, ragged edge is GPU-only.** The CPU field is a clean disc. Nothing in gameplay may depend on where a ragged sector happened to fall.
- **The boundary is an ordered (Bayer) dither, never a gradient**, computed in game-pixel space via `UV * game_size` rather than `FRAGCOORD` — the project stretches with integer scaling, so `FRAGCOORD` would dither at window resolution and the speckle would change size with the window.
- **Environment freezes; characters never.** `MemoryClock` drives a neighbour's `speed_scale` from the field and asserts in `_ready()` that its target has no `Character` ancestor.
- New field sources (death marks, flashbacks, the hero's aura in the final fight) compose `MemorySource`. New world effects compose `SongReceiver`. Neither requires touching the song, pulse or field code.

## Songs and the Memorina

- **A song is data** (`resources/songs/*.tres`): its id, its season palette, its note sequence and its pulse tuning. Adding one is a `.tres` plus an `Enums.Song` member appended at the end.
- **`SongMatcher` is pure logic and carries no timing.** The guardian call-and-response needs the same matching with a window on top; that will wrap the matcher and call `reset()`, rather than the matcher growing two modes.
- **No song's note sequence may be a prefix of another's** — the longer one would become unreachable. `SongCatalog.validate()` asserts this at startup in debug builds.
- **`MemorinaComponent` holds the instrument's state and nothing else.** Whether Ivo is standing still enough is the body's judgement, pushed in through `try_draw(can_play)` and `interrupt()`, the same way `enabled` carries the item gate.
- **A new note cuts the one still ringing.** The samples ring ~1.6 s, far longer than a phrase is played at, so `MemorinaVoice.play_note()` retriggers once `min_note_gap` (0.25 s) has passed and `Player` gates presses on `MemorinaVoice.can_play_note()`; presses inside the gap are mashing and are dropped. Never gate on `is_busy()` for a press - a silently swallowed press reads as "the game got it wrong" (see `docs/knowledge/bugs/memorina-notes-dropped-while-previous-rings.md`).
- **Interruption reuses the failure vocabulary that already exists.** Being hit or stepping off a ledge mid-sequence emits `sequence_failed`, exactly as a wrong note does — no second kind of failure for the player to learn. A wrong note never sounds: the component emits `note_rejected` (drawn, not played) and then `sequence_failed`, and the mistake SFX plays in its place; an interruption lets the ringing note finish first (`MemorinaVoice.play_mistake_after_note()`). `sequence_reset` (the sheet clears) fires when the mistake has been heard.
- **A completed sequence starts a PERFORMANCE, not the song.** `MemorinaComponent` emits `song_matched` and locks; `Player` lets the last note ring out (`MemorinaVoice.note_finished`), then `SongPerformance.play()`s the song's `performance_stream()` (the excerpt, or the track cut at `excerpt_duration`). `performance_started` → `WorldFreeze.freeze()` (`get_tree().paused`), `cue_reached(i)` lights sheet slot `i`, `finished` → thaw → `finish_performance()` → `song_played` → the pulse, then the component sheathes itself (the answer ends the gesture). The freeze is never set at match time, so a hit during the ring-out aborts through `interrupt()` and nothing is left paused. A lesson (`debug_learn_song`, F9, debug builds) is a performance started by hand on the whole track.
- **Pause-mode map.** `World` is PAUSABLE. `PROCESS_MODE_ALWAYS` on exactly: `MemorinaHud` (in its own scene), `Ivo/AnimationTree` (so `memorina_idle` keeps looping on a frozen body; it also means Ivo animates under any future pause menu), `Ivo/MemorinaVoice`, `Ivo/SongPerformance`, `LessonCinematic`, and **the memory layer**: `SeasonMask`, the `Greyhush` renderer, `CreatureMask`, every `ColorPulse` (its scene root) and `RegionWeather`. `CreatureMask` is in that list because it MIRRORS the camera every frame: the camera still moves while the world is frozen (a lesson pushes in), and a creature pass left on the last transform draws every body where it used to be - characters floating off the floor. A lesson freezes TIME, not MEMORY: while the track plays the well of forgetting lifts, the baseline climbs, colour spreads from the guardian and the weather wakes - that is the scene. `MemoryClock` stays pausable (environment time is what is frozen). Never the whole `CanvasLayer`. Camera zoom tweens use `TWEEN_PAUSE_PROCESS`.
- **`SongPerformance` and `CueTracker` carry no song knowledge.** They play a stream and report crossed cue times; `Song.note_cues` (seconds, one per note, hand-tuned against the audio) is the only place timing lives. A future reduced excerpt must start at the same instant as the track so the cues stay shared; adding `excerpt_cues` later is an additive change.
- **The glyph a note is drawn with is decided in `PlayerInput`** (`glyph_set_for(event, joy_name)`, pure and tested) and travels as `Enums.GlyphSet` beside the note. `MemorinaComponent` never sees it — `Player` remembers the pressed glyph and relays `note_played(note, glyph_set)`. The HUD maps a set to textures through `NoteGlyphSet` resources (`resources/ui/memorina/`); no script names a glyph PNG.
- **The sheet is geometry, not layout.** `NoteSheet` authors the staff in `memorina_hud.png`'s own pixels (`LINE_Y`, `STAFF_LEFT/RIGHT`) and scales them by the `Frame` TextureRect's actual width, so the frame's offsets in `memorina_hud.tscn` are the one place that picks 1× (128×64) or 2× (256×128, current); the glyphs have their own `icon_scale` (1.5). The frame is placed by code on the side Ivo faces (`MemorinaHud._place_frame`), but only once `GameCamera.focused` reports the zoom and any in-flight look-ahead have landed, with Ivo's final screen position — a frame laid out earlier would cover where he is about to be. The camera is the one node that converts world to screen for UI. The title's outline is the Label's `outline_size`, not the outline `.ttf` (two fonts never overlay glyph for glyph). No nested `scale`, so nothing is left for pixel snapping to round.

## Guardians (boss fights)

A guardian encounter is `docs/design/02_mecanicas.md` sections 3 and 4: pressure → lucidity window (call-and-response) → consequence, with the emergency QTE riding on one unavoidable attack, and restoration as the sync that teaches the song. Everything generic lives in `scenes/characters/guardians/`; **a concrete guardian is a scene plus a `GuardianStats`** (`resources/characters/guardians/<name>/`), never a subclass, unless it does something no resource can describe.

- **`GuardianFight` is the phase logic and is pure** (`RefCounted`, tested): `DORMANT → PRESSURE → LUCIDITY → RELAPSE → PRESSURE … → RESTORED`, the hit threshold, the answer window, the relapse clock and the aggression that every failure adds. `Guardian` drives it and does all the sounding, moving and saving; nothing else reads the phase except the resolver. **The recall is a gate**: `set_recall_pending(true)` (the guardian reads the save for it) makes hits saturate at the threshold without opening a window, and `skill_recalled()` is then the blow that opens it - the design's guarantee that no one leaves without the skill. Every answer short of the last passes through `RELAPSE` (`GuardianStats.relapse_time`, `FAILED_RELAPSE_SCALE` of it after a failure): the guardian stands lost, hits do not count, and pressure resumes on its own clock.
- **Hits destabilise, they never wound.** `Guardian._on_hit_received` skips `Health` and knockback and counts the hit into the fight. `Health` on a guardian is inert. **Touching a fighting guardian hurts**: `ContactHitbox` (a `Hitbox` with `continuous = true`, re-applied to whoever stays inside as their i-frames lapse) is phase-owned - `monitoring` is written by the script every frame, on under PRESSURE only, never keyed in a clip. Mashing is answered: every `counter_after_hits` hits between moves, `GuardianAI.provoke()` drops the cooldown and the next move comes at once; and once the hits saturate on a pending recall, `request_recall()` makes the recall move the next one, cadence or not.
- **The call borrows Ivo's instrument.** `Guardian` calls `Player.open_call(song, revealed)`, which sets `MemorinaComponent.call_song`: while it is set the phrase is the only candidate, and matching it emits `call_answered` and leaves the instrument out instead of starting a performance. `Player.close_call(success)` sheathes silently on success and `interrupt()`s otherwise, so a failed answer is the wrong-note vocabulary the player already knows. `GuardianCall` sounds the phrase through its own `MemorinaVoice` on a fixed `note_interval` (0.55 s, a melody rather than six ringing tones) and reports its length; **the answer window is that length plus `GuardianStats.window`**, because the reply cannot be played faster than the call was.
- **The Player↔Guardian contract is small**: the guardian calls `open_call` / `sound_call_note` / `close_call` / `begin_recall` / `learn_song`; it listens to `call_answered`, `sequence_failed`, `skill_recalled`, `skill_recall_missed`. Ivo relays the call to the HUD (`call_opened`, `call_note_sounded`, `call_window_opened`, `call_progress`, `call_answered`, `call_closed`) so the HUD keeps listening to one node.
- **The encounter is staged by `LessonCinematic` and the camera.** `Player.stage_call(caller)` / `unstage_call()` (relayed as `call_staged` / `call_unstaged`) bracket one lucid moment from the window opening to the end of its relapse (or restoration): `GameCamera.frame_pair(other)` eases the frame to the midpoint of Ivo and the guardian (no zoom - `focus()` while paired only settles `focused`), `LessonCinematic.on_call_staged` dims the world to `call_dim_alpha`, and `MemorinaHud` hides its sheet while the guardian sings. The lesson goes further (`scenes/ui/lesson_cinematic/`, PROCESS_MODE_ALWAYS, sits UNDER the `Creatures` pass in `game.tscn` so the dim spotlights Ivo and the guardian): letterbox bars, a dimmed world and the piece's title card (`MEMORINA_LEARNED` + `Song.title_key`) (it STAYS for the whole track - naming the piece is the point - and leaves with the letterbox), the camera pushes in slowly for `lesson_push_time` (45 s, longer than any beat so the frame is still closing in at the end of the track), the sheet beside Ivo bows out once the last note cue has lit (`MemorinaHud._close_lesson_sheet`) because a track runs a minute and the notes are done in six seconds, the guardian's own colour is born at the first cue with a slow, wide pulse (`Guardian.lesson_pulse`, `resources/memory/lesson_pulse_stats.tres`), its well of forgetting and the region's baseline tween to 1.0 across `corruption_lift_time`, and the pair stays framed until the track ends; the guardian answers the finished lesson with its usual pulse. `MemorinaHud` shows only the notes lighting; it no longer carries a banner.
- **Hit feedback**: guardians flash on every hit (`hit_flash_color`), Ivo's landed blows call `WorldFreeze.hit_stop()` (`Player.hit_landed`), a few real milliseconds at near-zero time scale that always return to whatever the recall had set, and both `hit_landed` and `Player.hurt` shake the camera (`GameCamera.shake`, bound strengths in `game.tscn`).
- **LISTEN on the guardian's sheet, ANSWER on Ivo's.** `GuardianCallHud` (`scenes/ui/guardian_call_hud/`) slides in at the top on the side away from the guardian (`call_opened` carries `side`, so a tall guardian's head is never covered), tinted in its season: "Listen" while the revealed notes light and pop as they sound, `CurePips` under the message showing `cure_done` of `cure_total` answers - and it slides away when the window opens. The answer is given on `MemorinaHud`, the sheet the player already knows, placed beside Ivo on the side away from the guardian (`answer_center_y`, clear of his head) and pre-filled with the phrase dimmed, a time bar draining gold to red, and the `draw_memorina` key blinking (`KeyGlyph`) until the instrument is out; `call_progress` lights the phrase back note by note, a failure flashes it, success tints it green. **The instrument stays in while the guardian sings**: `Player.open_call` sheathes it and `_call_listening` refuses the draw until `open_call_window` - a call is heard out before it is answered. `KeyGlyph` (`scenes/ui/key_glyph/`) is the one place that turns an action into a key on screen; both prompts use it.
- **The recall (QTE) is a phase, not a dice roll.** `GuardianAI` schedules the move carrying an `AbilityRecallStats` every `GuardianStats.recall_after_attacks` ordinary moves (its `weight` is 0, so it is never picked at random), and every move first TELEGRAPHS (`GuardianAttack.telegraph` seconds standing still while the sprite pulses `telegraph_color`) before it swings - a swing nobody could read is a sucker punch, not a challenge. The hitbox takes each move's `damage`/`knockback_*` at swing start. The recall only opens when it makes sense: `AbilityRecallStats.requires_airborne` makes `Player.begin_recall` wait for the launch (the Bloom burst does no damage and lifts Ivo) and never opens if Ivo stays grounded; a miss costs `miss_damage` straight through `Health` (i-frames must not hide it). **A move reaches inside a BOX**: `GuardianAttack.attack_range` to the side and `attack_height` up or down from the guardian's own feet, never a radius - a swing that landed on someone 60px overhead because the hypotenuse was short is how a boss looks silly, and a player bouncing on its head must not be inside a ground sweep. **A guardian never stands still, and never dithers.** It picks the move that SUITS the moment (`GuardianAI._situational_pick`): one that reaches a player overhead if it owns one, its longest when they are well beyond its spacing, the weighted roll otherwise - and then KEEPS that choice until it is thrown or a new opinion arrives. Re-rolling every frame looks like variety and is the opposite: whichever move happens to be in range wins every race, so the long one is all you ever see. Between swings it holds spacing (`GuardianStats.comfort_distance`): gives ground to a player who closes in, drifts back toward one who backs off, paces when neither, at `pace_speed` of its walk. A player on its head is LUNGED out from under (`step_out_speed`) and punished on the landing - the cooldown it was hiding behind is dropped the moment they come down - and it never walks under one it cannot reach.

  **Every decision taken from a distance is COMMITTED**, because a player pogoing on a guardian crosses its thresholds three times a second and an AI that re-decides on each crossing turns on the spot: the chase and the facing keep their side inside `TURN_BAND`; "out of reach overhead" is sticky in both axes (`_update_reach`: true the instant they rise past the tallest move, false only after `REACH_RELEASE` of that height for `ESCAPE_RELEASE_TIME`); the escape has a minimum dwell and a wider exit band than its entry; the spacing mode is entered at `COMFORT_NEAR`/`COMFORT_FAR` and left only back at the comfort distance. Measured: the same bouncing player took a guardian from 32 facing flips in 6 s to 0. **A move's `attack_range` must not exceed the reach its clip's hitbox keys** - the burst was thrown from 140 px with a 70 px hitbox and the recall never came (`docs/knowledge/bugs/recall-move-range-exceeds-hitbox-reach.md`).
- **`AbilityRecallComponent`** is the player ability itself, armed with the attack's stats and ticked in **real** seconds (`delta / Engine.time_scale`). `WorldFreeze.slow()` / `restore()` / `hit_stop()` are the only writers of `Engine.time_scale`. The same press that recalls the skill performs it: `PlayerInput.roll_pressed`/`jump_pressed` feed the recall before `_try_roll`/`_try_jump` run, and `SaveSystem.unlock_skill` happens in that handler. `WorldFreeze.slow()` eases the clock over `slow_ramp` with a tween that ignores the time scale it drives. The recall opens on its CUE, never merely at swing start: `AbilityRecallStats.trigger_distance` waits for the body throwing the move to come that close (`Player.begin_recall` takes the `source`), so the world slows when the blow is about to land and the window is not spent watching a charge cross the arena. Show, not tell: no caption. `RecallAura` (`scenes/characters/ivo/recall_aura/`, a child of Ivo on the creature layer, wired from Ivo's own signals in `ivo.tscn`) draws the colour born around the head - wavy rays trembling in real time, flaring white on a recall, dropping red on a miss - and `RecallPrompt` is only the bound key (`KeyGlyph`) blinking inside a ring that drains with the real-time window, floating above Ivo's head (it samples the canvas transform itself: a prompt that rides a moving body cannot wait for `focused`).
- **`GuardianAnimationResolver` is shared**: `IDLE, WALK, ATTACK_1..3, HURT, LUCID, RESTORED`. `GuardianAttack.clip_index` maps to `attack_clip_for()`, and `Guardian._assert_clip_durations` walks that mapping. The phase outranks everything in `resolve()`.
- **A guardian's colour is the fight made visible, script-owned, never keyed in a clip** (`Guardian._update_shield`): the rest level is `lerp(corrupted, 1.0, lucidity())`, hits climb a little above it under pressure, each note of the call *breathes* the shield to full and swells its radius (`note_swell`) with the sprite bobbing, the open window trembles slowly (`tremble_hz`, a sine) above a floor that climbs with every note answered, a relapse holds bright then drains to the new rest (or snaps to it with a hard burst after a failure), and restoration keeps it all. The guardian's voice is the same notes an octave down (`Call/Voice/AudioStreamPlayer.pitch_scale = 0.5`) and it groans the mistake sound as it relapses. **Every guardian carries a well of forgetting** (`Corruption`, a negative `MemorySource`, `top_level` so it stays put while the guardian paces): in a mostly remembered region a shield only lifts memory toward 1, so without the well none of this reads; the well is hidden for a restored guardian and tweened out (`corruption_lift_time`) at restoration.
- **Restoration is persistent** (`Enums.Guardian`, `PlayerData.restored_guardians`, `SaveSystem.restore_guardian`). `Region.current_baseline()` answers 1.0 once its guardian is restored, and `Guardian._restore()` sets `MemoryField.baseline` for the current visit. A restored guardian starts in `RESTORED` on every later visit and never fights again.
- **Three moves each, and one of them is a leap.** `GuardianAttack.leap_impulse` with `lunge_speed` is a jump at the player that lands past them, which is how a light guardian changes sides; a heavy one leaves it at 0 - not every boss should jump. Bloom: lash (close), burst (the launcher carrying the recall), pounce (a leap, 48px up and 192px across). Frost: swipe (close), charge (the lunge carrying the recall), slam (a tall keyed hitbox and `attack_height` 150, so the golem swats a player bouncing just above it instead of leaving). The asymmetry is the point: Bloom has no answer overhead and escapes, Frost has one and uses it.
- Arenas: `home_village/bloom_hollow` (Bloom Guardian, SPROUT + DOUBLE_JUMP) and the `frost_edge` region's `lighthouse` (Frost Guardian, FREEZE + ROLL). Sprite credits in `CREDITS.md`.
- Guardian sheets: frames side by side, body **centred in the frame** (`flip_h` mirrors about the frame centre; an off-centre body jumps on every turn), authored facing left. Missing clips (`lucid`, `restored` are idle frames today) can be generated with the `pixellab` skill (`tools/pixellab/pixellab.ps1`, key only ever in `PIXELLAB_API_KEY`).

## Seasonal art

A pulse does not tint the world into its season; it **redraws** it. Every seasonal drawable is a **stacked sheet**: the same drawing repeated in equal vertical bands, one per season, and the scene always references **band 0** (`floor_tiles.png` rows 0–5; a background `region_rect` inside the top 346 px). Which band is which season is declared on the material, not by a global rule — `floor_tiles.png` and the backgrounds are both spring / autumn / winter top to bottom, so both materials carry `band_of_season = (2, 0, 1, 0)` in `Enums.Season` order. Summer has no art and points at spring's band; a summer pulse is spring art plus summer's tint.

- **`SeasonMask` (`scenes/world/memory/seasonal/`) evaluates the field once per frame** into a 640×360 texture: one byte per game pixel saying which pulse season owns it, dithered across the feather with the same Bayer cell as the greyhush. `GreyhushRenderer` feeds it the same uniforms as the two colour passes and publishes its texture as the `greyhush_season_mask` global, plus `MemoryField.season` (the region's native season, from `Region.season`) as `greyhush_region_season`. Giving a sprite or `TileMapLayer` seasons is assigning `seasonal_art.gdshader` in a material with `band_count` and `band_of_season` — no script, no registration.
- **`gh_source_influence()` in the include is the only place a source's geometry is evaluated.** The mask and the colour passes call it, so the snow cannot stop a pixel short of the colour.
- **In a canvas_item fragment `COLOR` already holds `texture(TEXTURE, UV) * modulate`.** Any shader that samples the texture elsewhere must carry modulate as a varying from `vertex()`, or it multiplies its sample by the band-0 texel.
- Backgrounds are authored one season per file under `assets/sprites/world/background/<season>/` and stacked by `tools/stack_seasonal_sheets.gd` (`"<godot>" --headless --path . -s res://tools/stack_seasonal_sheets.gd`) into `background/seasonal/`, which is what the scenes reference. Rerun it after touching a source PNG; a missing season stands in with spring. Tiles are stacked by hand in the sheet itself.
- **The grey is empty, not dark.** Two things sell it, both static: `black_lift` (the faded print — forgotten blacks rise toward a cold tone, white stays white) in the greyhush pass, and `distance` on each seasonal material (the sky is 1, the ground 0), which dissolves far layers into the haze by how forgotten the pixel is, so a dead place loses its horizon before its floor. The mask's G channel carries the SMOOTH memory for that — never the dithered value, or the world material and the screen pass dither the same pixels twice and every rounded-up pixel pops out as a bright square; `greyhush_haze_color` / `greyhush_distance_fade` are globals pushed by the renderer so one knob rules every layer. Backgrounds therefore have one material per layer (`background_layer_N_material.tres`), differing only in `distance`.
- The pulse's leading ring (`PulseTimeline.ring()`, packed into `tints[i].a`) and the slow per-sector re-roll of the ragged edge (`edge_reroll_period`) are `GreyhushRenderer` exports; at 0 the frame is what it was before them. **Do not add high-frequency texture to the grey**: a per-pixel "deserting pixels" speckle was tried and cut — at any density that registers it reads as static and is tiring to look at. Emptiness is low-frequency.
- A season's particles are a `CPUParticles2D` scene on `SeasonPalette.pulse_particles`, mounted under the pulse, wearing `seasonal_particles.gdshader` so they are clipped to the mask: they exist exactly where the art has swapped, and nowhere else.
- **A region wears its season in proportion to its memory** (`docs/design/03_mundo_e_ambiente.md` section 5.2). `Game` hands `MemoryField` the region's `SeasonPalette` (`SongCatalog.palette_for(season)`) beside its season and baseline. `GreyhushRenderer` pushes the palette's tint as `region_tint` at `region_tint_amount = baseline`, applied in `gh_shade` wherever no source tints the pixel - so a restored region keeps its season's colour cast and a pulse of another season still overrides it. `RegionWeather` (`scenes/world/environment/region_weather/`, in `game.tscn` under `World`, PROCESS_MODE_ALWAYS) mounts the same particle scene a pulse would, with the shader's `ambient` uniform set so it lives wherever NO pulse has swapped the art (and inside pulses of its own season), follows the camera, and reads `MemoryField.sample()` AT THE CAMERA - not the bare baseline - so a well of forgetting stills the sky above it and a pulse makes the flakes fall again inside itself ("dentro do pulso os flocos voltam a cair"). **The grey stays empty**: that one number drives `speed_scale` (the fall stops), `modulate.a` (`quiet_alpha`) and the emission box, which is SPREAD wider than the screen as memory drops (`quiet_spread`) so the same flakes scatter thin and most fall out of frame - a forgotten sky is not a sky full of stopped specks. None of the three restarts the emitter (CPUParticles2D has no `amount_ratio` in 4.7, and writing `amount` respawns the whole sky mid-lesson). Restoring a guardian is what wakes it.

## Testing

gdUnit4 lives in `addons/gdUnit4/`. Pure logic goes in a `RefCounted` class and gets a suite under `tests/`, mirroring its source path.

```
"<godot>" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests
```

`--ignoreHeadlessMode` is required: gdUnit4 refuses headless runs by default because input-driven tests cannot work there. None of these suites use input.

After adding a script with a new `class_name`, run `--headless --path . --import` once, or nothing else will resolve the new type.

## Engineering knowledge base (self-improving)

`docs/knowledge/` (start at `docs/knowledge/README.md`) is a separate, English,
RAG-shaped knowledge base for **engineering** memory — architecture decisions, confirmed
bugs, Godot/GDScript engine gotchas, and playtest reports. It is not `docs/design/`:
`docs/design/` is the Portuguese design source of truth (lore, mechanics); `docs/knowledge/`
is how the project's own agents get smarter about *this codebase and this engine* over
time instead of re-deriving the same lessons every session.

The rule that makes this self-improving: **every agent reads the relevant part of
`docs/knowledge/` before acting, and writes a new entry after learning something not
already captured there.** `godot-architect` checks and contributes to `architecture/`;
`godot-reviewer` checks and contributes to `bugs/` and `gotchas/`; `godot-playtester`
(below) always writes a `playtests/` entry. Skipping the write step because a task felt
small defeats the entire point — the next agent (or the next session) pays the same cost
again if it isn't written down.

## Playtesting

A green test suite and a clean `godot-reviewer` pass verify correctness, not whether a
gameplay-visible change is actually fun, fluid, or looks right in motion — those require
watching the game run. `tools/playtest/` (see `tools/playtest/README.md`) is a capture
harness: it runs the real game windowed (not headless — screenshots need a real rendering
device), drives it through a scripted, data-driven input timeline
(`tools/playtest/scripts/*.json`) via `Input.action_press`/`action_release` — the same
calls a live keyboard/pad produces — and saves viewport screenshots at chosen moments.

Use the `godot-playtester` agent (directly, or via the `godot-playtest` skill) after
implementing or changing anything gameplay-visible: movement, abilities, a guardian fight,
HUD, seasonal art, the Memorina. It reports fun/fluidity/aesthetics with an honest
accounting of what a screenshot sequence can and can't actually establish (see the agent's
"What this cannot judge" section — camera feel and input latency are not visible in a
still frame, and the report says so rather than guessing a confident number), and files
any confirmed bug it finds to `docs/knowledge/bugs/`.

## Internationalization

**This game ships in multiple languages — build for that from the start, don't retrofit it.**

- Never hardcode user-facing strings (dialogue, UI labels, notebook text) directly in scripts or scenes. Route everything through Godot's translation system (`tr()` with a key, backed by CSV or gettext `.po` files).
- Portuguese design-doc prose is source *content* to translate, not a hardcoded default — treat every user-facing string as a translation key from the first line of code that uses it.

## Project structure

**Every file and folder is lowercase `snake_case`** — no spaces, no PascalCase, no kebab-case. `res://` paths are case-sensitive on Linux/web exports, so mixed casing produces builds that work on Windows and break everywhere else.

- `globals/` — autoload singletons and global enums (`save_system.gd`, `enums.gd`, `player_data.gd`). These are scripts with no owning scene, which is why they are exempt from the "scripts live beside their scene" rule below.
- `scenes/characters/` (the root itself) — the generic character substrate shared by every character: `character.gd`, `character_controller.gd`, `character_state_machine.gd`.
- `scenes/characters/components/` — reusable behaviour components any character can mount (locomotion, jump, landing).
- `scenes/characters/<name>/` — one folder per character, containing its scene(s) *and* its scripts (e.g. `scenes/characters/ivo/`).
- `scenes/characters/<name>/abilities/` — components specific to ONE character, e.g. gated player abilities.
- `scenes/combat/<kind>/` — hurtbox, hitbox, health.
- `scenes/world/` — `game.tscn`, the main scene: the composition root holding player, camera and HUD, and swapping levels underneath.
- `scenes/particles/<kind>/` — reusable one-shot effect scenes, spawned by whoever triggers them.
- `scenes/world/memory/` — the greyhush: the memory field, its sources, the screen shader that draws it, the clock that stops time inside it, and the colour pulse a song lights. `memory/seasonal/` is the season mask and the shaders/materials that swap art by season.
- `tools/` — Godot scripts run by hand from the project root: headless asset-pipeline steps (stacking seasonal sheets), plus `tools/playtest/` (see Playtesting above), whose runner is the one exception that IS a scene, because screenshot capture needs a real rendering device — this is a dev-only tool, never shipped, never referenced from game scenes.
- `scenes/world/environment/<kind>/` — ambient set dressing that answers to the memory field (drifting motes, swaying growth). Distinct from `scenes/particles/`, which is fire-and-forget feedback for an action.
- `scenes/world/interactables/<kind>/` — world objects a song acts on. Each composes a `SongReceiver`; none of them is known to the song system.
- `scenes/ui/<screen>/` — HUD and menu scenes.
- `i18n/` — `translations.csv` and the `.translation` files Godot imports from it.
- `tests/` — gdUnit4 suites, mirroring the path of what they test (`tests/scenes/world/memory/...`).
- `addons/` — vendored third-party plugins (gdUnit4). Committed, not fetched at build time.
- `assets/sprites/<category>/<name>/` — art, mirroring the `scenes/` layout (e.g. `assets/sprites/characters/ivo/`).
- `resources/` — custom `Resource` SCRIPTS defining tuning data plus the `.tres` instances of them, e.g. `resources/characters/`. Both the class definitions and their data live here; the exception is `player_data.gd`, which is the save-file schema owned by the `SaveSystem` autoload and so lives in `globals/` instead.
- `docs/design/` — design docs (lore, mechanics), source of truth for game intent.

Song and pulse data lives under `resources/songs/` and `resources/memory/`, following the same schema-plus-`.tres` rule as `resources/characters/`.

**Scripts live beside the scene they belong to — never in a shared `scripts/` folder.** Grouping is by feature, not by file type. A `scripts/` directory would make every new file a coin flip between two conventions.

**Rooms are a three-level pattern** — easy to get wrong, so spelled out explicitly:

```
scenes/world/rooms/<region>.tscn                            composition: places the rooms
scenes/world/rooms/<region>/<room>.tscn                     the Room trigger (Area2D, room.gd), with contents_scene exported
scenes/world/rooms/<region>/contents/<room>_contents.tscn   the actual tilemap/background, loaded lazily
```

The `_contents` suffix exists specifically so the two `<room>.tscn` files are distinguishable by filename alone.

Rename and move files **from inside the Godot editor** (FileSystem dock), so it rewrites `uid://` references, `path=` entries and `.import` sidecars for you.

## Known gaps (not yet implemented)

- Input map (`project.godot`) defines `move_left`, `move_right`, `jump`, `look_up`, `look_down`, `roll`, `attack`, `draw_memorina`, `note_up`/`note_down`/`note_left`/`note_right` and the debug-only `debug_learn_song` (F9). Only the notes (face buttons: Y/△ up, A/✕ down, X/□ left, B/○ right) and `draw_memorina` (right shoulder) have joypad bindings; movement, jump, roll and attack are keyboard-only. The design still calls for open-notebook, pause and open-map — add these when that work actually starts, matching the existing signal-based `PlayerInput` pattern.
- Only `FREEZE` has a world effect (`FreezableWater`). The other seven songs light a pulse, swap the seasonal art and spawn their season's particles, and nothing more.
- Nothing in the world grants `PlayerItem.SWORD` or `PlayerItem.MEMORINA`; there are no pickups and no benches, and `save_game()` is still never called. Debug builds start a new game owning both (`SaveSystem.new_game()`), so a guardian can be fought from a clean launch. The debug action `debug_learn_song` (F9, debug builds only) still teaches the next unknown song through `Player.learn_song()`; it stays until every song has a guardian.
- Guardians: only two exist (FREEZE/ROLL and SPROUT/DOUBLE_JUMP). The notebook confirmation of a recalled skill is not built (there is no notebook); arenas have no doors, so the player can walk out mid-fight; dying mid-fight has no respawn to return to; the final fight's revelation and dissonance (design section 5) are not started. The Frost Guardian's free sprite tier has one attack clip, so both its moves share it. Regional weather (`RegionWeather`) is visual only - design section 5 wants it to push the player physically - and its only art is each palette's pulse particle scene.
- No song has a dedicated reduced excerpt yet: `Song.excerpt` is null everywhere and the world hears the full track cut at `excerpt_duration` (7 s). `note_cues` are placeholders (0.5 s apart) awaiting tuning against each track.
- The freeze placeholder is on-while-lit. The design's thaw-from-the-origin front, hardening-before-solid, and water reflections are not built.
- The greyhush shader is screen-space, so it desaturates Ivo along with the world. The lore wants colour to originate from the body in flashbacks and the QTE; excluding characters means giving them their own CanvasLayer, which is not done.
- `docs/design/03_mundo_e_ambiente.md` section 7 records an unresolved conflict: Winter is described with three sequences (Congelar, Ventania/Nevasca, Hibernação) but the instrument has a fixed eight-slot grid, two per season. `Enums.Song` omits Hibernação until that is settled.
- The `tools/playtest/` capture harness (see Playtesting above) was shaken down against a
  real Godot 4.7.2 launch on 2026-09-20 (`D:\Godot_v4.7.2-stable_win64.exe` — not on PATH;
  located by filesystem search, so an agent needing it should search rather than assume a
  fixed path). That run found and fixed a real bug: input must be simulated via
  `Input.parse_input_event()`, not `Input.action_press()`/`action_release()` (see
  `docs/knowledge/gotchas/input-action-press-does-not-reach-input-callbacks.md`). The
  harness now reliably drives movement, jump, and roll and captures correct frames — see
  `docs/knowledge/playtests/2026-09-20-harness-shakedown.md`. `tools/playtest/scripts/bloom_guardian_call.json` drives a full Bloom Guardian
  call-and-response (report: `docs/knowledge/playtests/2026-09-20-bloom-guardian-call.md`);
  Ivo must be spawned near the arena for it. Seasonal art has no run yet; the Frost fight's opening acts (contact, the charge with the roll recall, lucidity) were driven state by state in `docs/knowledge/playtests/2026-09-21-bloom-fight-acts.md`, its later cycles have not been played.

## Glossary (design term → code identifier)

The design docs are written in Portuguese; code identifiers are English. Extend this table whenever a design concept gets implemented.

| Design doc (pt) | Code |
|---|---|
| cinzesquecimento / the Greyhush | `greyhush` |
| campo de memória | `MemoryField` |
| pulso de cor | `ColorPulse` |
| sacar / guardar (o instrumento) | `draw` / `sheathe` |
| Congelar | `Enums.Song.FREEZE` |
| Ventania / Nevasca | `Enums.Song.BLIZZARD` |
| Sol Concentrado | `Enums.Song.CONCENTRATED_SUN` |
| Tempestade Repentina | `Enums.Song.SUDDEN_STORM` |
| Fragilizar | `Enums.Song.WEAKEN` |
| Despir | `Enums.Song.STRIP` |
| Brotar | `Enums.Song.SPROUT` |
| Eclodir | `Enums.Song.HATCH` |
| Inverno / Verão / Outono / Primavera | `Enums.Season.WINTER` / `SUMMER` / `AUTUMN` / `SPRING` |
| estação nativa (de uma região) | `Region.season` / `MemoryField.season` |
| título da canção (Hino do Gelo…) | `Song.title_key` (`SONG_TITLE_*`) |
| resposta do instrumento / trecho | `SongPerformance`, `Song.excerpt` |
| congelar o mundo (durante a resposta) | `WorldFreeze` |
| guardião / fase de pressão / janela de lucidez | `Guardian` / `GuardianFight.Phase.PRESSURE` / `GuardianFight.Phase.LUCIDITY` |
| chamado (call-and-response) / resposta | `GuardianCall`, `MemorinaComponent.call_song` / `call_answered` |
| QTE de emergência / habilidade recuperada | `AbilityRecallComponent`, `AbilityRecallStats` / `SaveSystem.unlock_skill` |
| restaurar o guardião | `SaveSystem.restore_guardian`, `Region.current_baseline()` |
| tempo desacelera | `WorldFreeze.slow()` |
| recaída (o guardião volta à loucura) | `GuardianFight.Phase.RELAPSE` |
| poço de esquecimento (em volta do guardião) | `Guardian` `Corruption` (`MemorySource` negativo) |
| clima regional (escala com a memória) | `RegionWeather`, `MemoryField.palette`, `region_tint` |
| cor nasce ao redor da cabeça (QTE) | `RecallAura` |

### Terms no longer used

When a code identifier or design term is renamed or retired, add it here instead of just
deleting the old row above — a stale name showing up in an old comment, commit message, or
someone's memory of the project is exactly what causes an accidental regression back to it.

| Retired term | What replaced it |
|---|---|
| "Lembre-se!" / `RECALL_PROMPT` (the recall banner) | retired 2026-09-21: the recall shows instead of telling (`RecallAura`, `RecallPrompt` key only) |
| `GUARDIAN_CALL_ANSWER` ("Answer on the Memorina") | retired 2026-09-21: the answer moved to Ivo's own sheet with the key blinking; no prose |
| "one sheet at the top for the whole call" (round 4 rule) | replaced 2026-09-21 by LISTEN on the guardian's sheet, ANSWER on Ivo's |

