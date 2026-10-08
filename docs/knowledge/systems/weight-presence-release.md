---
id: systems/weight-presence-release
type: system
title: Weight, presence, Sombra and Soltar
status: active
tags: [weight, presence, shadow, release, seesaw]
related: [architecture/weight-and-presence]
created: 2026-10-02
updated: 2026-10-07
source_files: []
---

# Weight, presence, Sombra and Soltar

Moved verbatim from `CLAUDE.md` ("Weight, presence and release") on 2026-10-02.

Design 02 sections 7.1 and 8: Sombra (`SHADOW`) and Soltar (`RELEASE`) act through three small channels any puzzle piece can use.

- **Weight** is a `Weight` child named `Weight` (mass in Ivos: Ivo is 1.0). A `WeightSensor` sums the weights of every body AND area overlapping it and emits `load_changed`; it knows nothing of what presses. `PressurePlate` holds while the sum reaches `required_mass`. A `Mechanism` (gate, lift; an `AnimatableBody2D`) follows its `trigger_path`, and its `second_trigger_path` too when set (both must hold: the empty house, design 02 §8.4 Combinado 4), and is jammed at rest while its `lock_path` holds - the wrong counterweight. `Seesaw` settles at `SeesawBalance.settle_angle` (pure, tested) and has `length` and `pivot_at`: **a shadow puzzle needs an off-centre pivot** - on a centred one the shadow at one end and Ivo at the other balance, and the end he walked up to sinks level under him.
- **Presence** is the group `EnemySight.PRESENCE`: whatever a creature takes for the hero (Ivo's body, the burned shadow's area). `EnemySight.player` is Ivo alone - a guardian fights HIM - and `visible_presence()` is the nearest presence in plain sight, which `EnemyAI` picks once per tick (`_target`) before its state, so every state and range check agree.
- **Sombra is `CastShadow`**, the song's `PulseEffect`: `Character.silhouette()` copies the frame Ivo shows when the song ends, drawn as world art (`burned_shadow.gdshader`: dark, a rim burning in the summer tint that shimmers row by row in whole texels, a dithered fade, the effect's own clock - never `TIME`). Its `Presence` is a `Hurtbox` with a `Weight`, so plates and seesaws count it and creatures' hitboxes land on it with no new wiring; **the first blow breaks it** into ash (out of the group, shape disabled, so whatever it held lets go). It rides what it was cast on (the floor under its feet, found in its first physics frame): a shadow on a seesaw tilts with the plank instead of floating off it.
- **Soltar is `Releasable` + `ReleaseState`** (pure, tested): a RELEASE pulse lets a thing go once; when the last pulse has left it, the grey gives the old state back, deferred while something holds it (`hold()` / `let_go()` - Ivo standing on it). **"Left" includes the thing being carried out of the disc**: a load blown out of Soltar's colour is back in the grey and goes back to its rope, so where the song is played is the puzzle. Both signals are emitted DEFERRED, because a pulse reaches a receiver from inside the physics flush, where a body may not change state. `HangingLoad` falls for real (a `RigidBody2D` on Props, rides the air), slides rather than tumbles (rotation locked, silk friction, bottom corners cut so tile seams do not catch it); `LeafCover` drops and regrows; `Drawbridge` falls across its gap. Soltar's pulse is its own: small (288 px - its radius is how it chooses) and long (16 s sustain - its loads must still be down when the next song arrives).
- **A song Ivo played holds still under a pause** (`PulseEmitter.holds_in_pause`, true on Ivo, false on both guardians): a pulse is world time, like the water and the ice, so the next song's performance does not eat it (Soltar's load is still down when Vendaval blows). Its root stays `PROCESS_MODE_ALWAYS`; only its clock and particles stop. A guardian's lesson pulse keeps spreading - a lesson freezes time, not memory.
- **The trials prove the puzzles**: `summer_trial_test.gd`, `autumn_trial_test.gd` and `empty_house_test.gd` read the real maps, seesaw, gate, loads, pulse stats and Ivo's reach and assert each puzzle is closed without its song and open with it; the timelines `tools/playtest/scripts/song_shadow_*.json` and `song_release_*.json` play them for real.
