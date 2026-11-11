---
id: performance/2026-11-11-tech12-baseline
type: measurement
title: TECH-12 baseline - frame cost per region, per pass and per room load, on the RTX 3060 desktop, scaled to an Iris Xe
status: active
tags: [performance, profiling, tech-12, gpu, backdrops, room-load, greyhush]
related: [gotchas/showing-a-canvas-item-drops-its-rendering-server-clip, architecture/release-build, systems/backdrops, systems/greyhush, systems/grass, systems/water, systems/world, systems/rooms, systems/foreground, gotchas/fullscreen-does-nothing-in-an-editor-run]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - tools/profiling/tech12_probe_driver.gd
  - tools/profiling/tech12_timeline.json
  - scenes/world/rooms/room_residency.gd
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/memory/dissonance/dissonance_fx.gd
---

# TECH-12 baseline (2026-11-11)

Target (user, 2026-11-11): 60 fps steady (16.6 ms per frame) in every region, no frame over 33 ms outside a room load, on an i5-1135G7 / Iris Xe / 8 GB notebook at 1280x720 to 1920x1080.

## Headline

- **Steady state is about 10x under budget on the desktop.** Uncapped, every region renders in 0.6-0.9 ms per frame at 1280x720 and 0.8-1.7 ms at 1920x1080. GPU time is 0.26-0.64 ms at 720p and 0.59-1.50 ms at 1080p. With vsync on (180 Hz screen) every region holds 5.55 ms per frame; the worst steady frame was 9.2 ms and none passed 16 ms.
- **GPU cost is mostly backdrops.** Backdrop layers take 55-70% of GPU time: 0.6-1.0 ms of 1.0-1.5 ms at 1080p. Most of the rest is the full-screen passes (0.2-0.4 ms together). Grass, particles, props, the season mask and both CanvasPasses are within noise.
- **The frames that break the target are room loads.**
  - A teleport or door arrival peaks at 26-51 ms. A warm revisit costs the same, so the hitch is building rooms, not compiling shaders.
  - Walking across a room boundary costs one 13-16 ms frame. Scaled to the laptop that is 26-31 ms, close to the 33 ms ceiling, and it is a visible dropped frame mid-walk.
- **Scaled to an Iris Xe** (assumptions below), the worst region (orchard_mill_town at 1080p) needs about 10 ms of GPU time (range 9-15 ms). It probably fits 16.6 ms, with little margin. 720p needs about 4.5 ms.
- **What these numbers do not show.** The user's "even my computer suffers" is not reproduced by the steady state of any region measured here. The likely causes are the editor run (TECH-11: frames about 0.16 s apart with the editor open), room-load hitches, or scenarios this probe does not visit (see "Not measured").

## Method

- **Probe.** `tools/profiling/tech12_probe_driver.gd` is a SceneTree script. It boots `tools/playtest/playtest_runner.tscn` (a MEMORY session, `BootPolicy`) on a 3000 s dummy timeline (`tech12_timeline.json`), with `APPDATA` pointed at a scratch folder. It changes only runtime state: visibility, SubViewport update modes, the root cull mask and `MemoryField.baseline`.
- **Visits.** For each room the probe teleports Ivo there (`Player.teleport`) and records 4 s of arrival frames. It then waits 3 s and samples 5 s. For attribution it turns one candidate off, waits 0.6 s, samples 3 s and restores the candidate; it re-samples the base at the end to check for drift.
- **What is recorded per frame:**
  - real frame dt (ticks between `process_frame`s);
  - `viewport_get_measured_render_time_gpu`/`_cpu` for the root and the three SubViewports (CreatureMask, ForegroundPass, SeasonMask), summed;
  - `get_frame_setup_time_cpu`;
  - draw calls, objects and primitives in the frame;
  - video and texture memory, node count, and active/loaded rooms.
- **CPU columns are per-second worst cases.** `Performance.TIME_PROCESS` and `TIME_PHYSICS_PROCESS` hold the worst step of the previous second (Godot updates them once a second), so the `proc` and `phys` columns are upper bounds, not means.
- **Runs.** The window was 1280x720 (canvas scale 2) and 1920x1080 (borderless at the screen origin, canvas scale 3). Vsync was off (`--disable-vsync` plus a runtime `VSYNC_DISABLED`, `max_fps` 0) so frame time shows headroom. One more pass at 1080p kept vsync on.
- **Room loads** were measured three ways:
  - the arrival window of each teleport;
  - two warm revisits (village_mill, orchard_mill_town) after eviction;
  - a 16 s walk right from village_square (x 1616) across two boundaries, keeping every frame.
- Each visited room's contents were also instantiated again, hidden and outside the world, timing `instantiate()` and `add_child` (enter tree plus `_ready`).
- **Machine.** i7-12700F, RTX 3060, 32 GB, D3D12 (the project's Windows driver), 1920x1080 at 180 Hz. Debug build (Godot 4.7.2 console). No editor was running.
- **Run it again:**

```bash
APPDATA=<scratch> "$GODOT" --path . --disable-vsync -s res://tools/profiling/tech12_probe_driver.gd -- \
  --script=res://tools/profiling/tech12_timeline.json --out=<abs dir> --perf_out=<abs json> --size=1920x1080 --attrib=all --walk
```

`--attrib=none` skips attribution (about 2 min). `--attrib=<room,room>` limits it. `--vsync` keeps vsync on.

## Per region (steady state, base sample)

Rooms: village_mill (HomeVillage), threshold_fields, frost_shore (FrostEdge), woods_edge (SpringWoods), lake_fishing_village (FrozenLake), orchard_mill_town (WindOrchards), caldera_open_crater (SummerCaldera), village_house (interior).

### 1920x1080 (scale 3)

| Room | dt mean / p99 / max ms | GPU total ms | proc / phys ms (per-s worst) | draws | objects | primitives | nodes | rooms active/loaded | VRAM MB |
|---|---|---|---|---|---|---|---|---|---|
| orchard_mill_town | 1.72 / 3.94 / 4.30 | 1.44 | 2.39 / 1.93 | 55 | 486 | 1270 | 1510 | 7/9 | 325 |
| woods_edge | 1.55 / 3.20 / 3.52 | 1.23 | 2.25 / 1.97 | 43 | 391 | 940 | 1354 | 5/7 | 308 |
| lake_fishing_village | 1.48 / 3.27 / 3.68 | 1.17 | 2.21 / 1.55 | 35 | 266 | 810 | 1333 | 4/6 | 311 |
| village_mill | 1.42 / 2.76 / 6.29 | 1.04 | 2.35 / 1.58 | 48 | 212 | 582 | 1341 | 4/5 | 263 |
| threshold_fields | 1.34 / 2.85 / 3.29 | 1.06 | 2.01 / 1.38 | 42 | 180 | 638 | 1330 | 5/7 | 308 |
| caldera_open_crater | 1.31 / 2.25 / 3.08 | 1.05 | 2.38 / 0.94 | 40 | 455 | 1027 | 1120 | 3/5 | 307 |
| frost_shore | 1.30 / 2.58 / 3.05 | 1.06 | 2.19 / 0.95 | 30 | 331 | 940 | 1167 | 3/5 | 296 |
| village_house | 0.82 / 1.48 / 10.30 | 0.59 | 1.55 / 0.74 | 22 | 114 | 228 | 1109 | 1/3 | 300 |

### 1280x720 (scale 2)

| Room | dt mean / p99 / max ms | GPU total ms | proc / phys ms (per-s worst) |
|---|---|---|---|
| orchard_mill_town | 0.89 / 3.17 / 3.55 | 0.64 | 1.63 / 1.95 |
| woods_edge | 0.87 / 2.70 / 3.44 | 0.59 | 1.55 / 2.38 |
| lake_fishing_village | 0.80 / 1.93 / 4.71 | 0.57 | 1.98 / 1.67 |
| village_mill | 0.79 / 1.97 / 2.33 | 0.50 | 1.52 / 1.54 |
| threshold_fields | 0.72 / 1.77 / 2.17 | 0.50 | 1.38 / 1.29 |
| frost_shore | 0.70 / 1.93 / 3.10 | 0.50 | 1.68 / 0.98 |
| caldera_open_crater | 0.68 / 1.30 / 1.66 | 0.47 | 1.35 / 0.86 |
| village_house | 0.60 / 1.05 / 1.49 | 0.26 | 1.16 / 0.65 |

- **Window size.** GPU time grows 2.1-2.4x from 720p to 1080p, in step with the 2.25x pixels. This is because `window/stretch/mode="canvas_items"` draws every canvas item and full-screen pass at window resolution, not at 640x360. CPU time does not change with window size.
- **SubViewports cost nothing measurable.** All three are 640x360 and each measures 0.003-0.016 ms. Nearly all GPU time is the root viewport.
- **Memory level.** village_mill at memory 0.0, 0.6, 0.8 (authored) and 1.0 measures the same GPU time within 0.04 ms at both sizes. The greyhush costs the same grey or coloured.
- **Memory use.** Video memory is 252-325 MB and static memory about 176 MB. On an 8 GB notebook with shared graphics memory this is fine.
- **One-off spikes.** village_house showed a single 19 ms process step on the first trial run and a 10.3 ms frame at 1080p. Neither repeated in its other samples. The cause was not found.

## Per pass (GPU and frame-time delta when turned off)

Each value is GPU total change / frame dt change, in ms, against the mean of the base sample and the base re-sampled after the toggles, at **1920x1080**. Run-to-run noise is about ±0.03 ms GPU and ±0.1 ms dt (the toggles that change nothing scatter that much).

| Turned off | orchard_mill_town | woods_edge | lake_fishing_village | village_mill | threshold_fields | caldera_open_crater | frost_shore | village_house |
|---|---|---|---|---|---|---|---|---|
| backdrops (every active room's `Backdrop`) | **-0.99 / -0.96** | -0.76 / -0.81 | -0.63 / -0.67 | -0.59 / -0.70 | -0.69 / -0.59 | -0.64 / -0.58 | -0.58 / -0.63 | -0.23 / -0.11 |
| neighbours (deactivate every active room but the current) | -0.73 / -0.74 | -0.47 / -0.53 | -0.26 / -0.36 | -0.23 / -0.34 | -0.38 / -0.38 | -0.20 / -0.21 | -0.26 / -0.29 | (none) |
| all five full-screen passes | -0.33 / -0.39 | -0.25 / -0.38 | -0.39 / -0.43 | -0.19 / -0.35 | -0.32 / -0.36 | -0.34 / -0.38 | -0.35 / -0.40 | -0.31 / -0.27 |
| greyhush (`CanvasLayer/Greyhush`) | -0.25 / -0.24 | -0.16 / -0.18 | -0.20 / -0.25 | -0.11 / -0.18 | -0.15 / -0.19 | -0.20 / -0.22 | -0.18 / -0.24 | -0.18 / -0.08 |
| water (`RoomMap/Water*`) | 0 | 0 | -0.10 / -0.13 | 0 | 0 | 0 | -0.12 / -0.17 | 0 |
| dissonance copy (`BackBufferCopy`, veil hidden) | 0 | -0.06 / -0.07 | -0.04 / -0.07 | 0 | -0.05 / -0.06 | -0.06 / -0.09 | -0.08 / -0.13 | -0.07 / -0.06 |
| creature pass (`CreatureMask`) | -0.08 / -0.10 | -0.05 | -0.02 | 0 | -0.02 | -0.02 | -0.05 / -0.10 | -0.03 |
| foreground pass (`ForegroundPass`) | -0.04 / -0.08 | -0.03 | 0 | 0 | -0.02 | -0.03 | -0.05 / -0.10 | -0.03 |
| grass (`RoomMap/Grass`) | -0.06 / -0.11 | -0.07 / -0.11 | 0 | 0 | 0 | 0 | -0.03 | 0 |
| season mask (`SeasonMask` update off) | -0.03 | 0 | 0 | 0 | 0 | 0 | -0.03 | 0 |
| particles (all `CPUParticles2D`) | 0 | 0 | -0.02 | 0 | 0 | 0 | -0.02 | 0 |
| region weather | -0.03 | 0 | 0 | 0 | 0 | 0 | -0.03 | 0 |
| ambient motion (`AmbientMotion` physics off) | 0 | 0 | 0 | 0 | 0 | 0 | -0.02 | -0.02 |
| world hidden (`World`, upper bound of all world drawing) | -1.16 / -1.14 | -0.93 / -0.95 | -0.85 / -0.90 | -0.78 / -0.85 | -0.75 / -0.74 | -0.72 / -0.66 | -0.77 / -0.78 | -0.28 / -0.26 |

0 means within noise (under 0.03 ms).

- **720p.** Every pass costs about 0.45x its 1080p cost. Backdrops are -0.28 to -0.41 ms and greyhush -0.05 to -0.12 ms. All five full-screen passes together are -0.10 to -0.21 ms, and neighbours -0.12 to -0.29 ms.
- **Draw calls.** Backdrops are 13-29 of the 30-55 draw calls per region, and neighbours another 11-29 (mostly their backdrop layers and tiles).
- **Why backdrops cost per room.** Each layer is a quad over its room grown by `RoomRing.WIDTH` (160 px), and every fragment runs the owner loop over up to 8 `neighbour_rects` before it discards (`backdrop_layer.gdshader`). So every touching room draws all its layers over the screen edges it may own, and the cost grows with the active room count: 7 in orchard_mill_town.
- **The dissonance copy.** `CanvasLayer/DissonanceCopy` copies the whole screen every frame while the veil is hidden. That costs 0.04-0.08 ms at 1080p for nothing.

## Room loads

| Event | 1280x720 worst frame | 1920x1080 worst frame | Frames over 33 ms |
|---|---|---|---|
| teleport into orchard_mill_town (7 active rooms) | 50.7 ms | 51.5 ms | 1 |
| teleport into woods_edge | 45.2 | 45.6 | 1 |
| teleport into lake_fishing_village | 38.4 | 39.6 | 1 |
| teleport into threshold_fields | 31.5 | 37.6 | 0-1 |
| teleport into village_mill / frost_shore / caldera_open_crater | 26.5-32.7 | 30.0-32.2 | 0 |
| teleport into village_house (1 room) | 8.7 | 8.7 | 0 |
| warm revisit orchard_mill_town / village_mill | 48.1 / 25.7 | 48.4 / 26.0 | 1 / 0 |
| walk village_square to village_mill (x 1934) | 12.8 | 14.0 | 0 |
| walk village_mill to village_gate_east (x 3214) | 13.4 | 15.7 | 0 |

- **One frame per arrival.** Each load is one long frame, and the next frames are back to normal.
- **Not shader compilation.** Warm revisits cost the same as first visits, so compiling shaders is not the cause.
- **Cost per room.** A room's contents take 0.01-0.28 ms to `instantiate()` and 2.8-5.0 ms to enter the tree and run `_ready` (warm):

| Contents | nodes | instantiate ms | enter tree + `_ready` ms |
|---|---|---|---|
| lake_fishing_village | 84 | 0.11 | 4.9-5.0 |
| frost_shore | 65 | 0.03-0.06 | 4.5 |
| caldera_open_crater | 29 | 0.02 | 4.1-4.4 |
| village_mill | 64 | 0.12-0.15 | 3.7-3.8 |
| orchard_mill_town | 48 | 0.02 | 3.5-3.6 |
| threshold_fields | 36 | 0.03 | 3.3 |
| woods_edge | 50 | 0.03 | 3.1 |
| village_house | 114 | 0.27-0.28 | 2.8-3.0 |

- **How the hitch builds up.** `Room.activate()` instantiates and adds every newly resident room in the same frame. An arrival activates the room and all its neighbours, about 4 ms each, which is the 26-51 ms. A walk across a boundary activates the 2-3 newly touching rooms, which is the 13-16 ms. The `_ready` work (by node count, the RoomMap build: tiles, grass, water, the backdrop's meshes and materials) was not split further.

## Release build

- **Only the title could be compared.** The exported `builds/windows/memorina.exe` cannot run the probe: `tools/` is excluded, and a release build boots the title. So the comparison is the title screen, `--disable-vsync --print-fps` at 1280x720, 20 s each.
- **Result.** Debug was 0.24-0.29 ms per frame (3357-4058 fps) and release 0.23-0.29 ms (3394-4171 fps), the same within noise.
- **What this means.** On the title, the debug build adds no measurable frame cost. In-game the debug build carries GDScript debug checks, so the probe's CPU numbers are an upper bound for release. The GPU numbers should match.

## Scaling to the target notebook

Assumptions, not measured:

- **GPU about 7x slower (range 6-10x).** The RTX 3060 has 360 GB/s of its own memory bandwidth. The Iris Xe 96 EU shares dual-channel DDR4-3200 (about 51 GB/s) with the CPU, and 3DMark Time Spy is about 8.7k against about 1.5k. These passes are fill and bandwidth bound (full-screen quads, overdraw, discard), so bandwidth sets the ratio. Fragment loops with discard can scale worse on Intel, hence the upper bound of 10x.
- **CPU about 2x slower.** An i7-12700F P-core runs at up to 4.9 GHz. An i5-1135G7 runs at up to 4.2 GHz, but sustains less under a 15-28 W limit, on battery, and while sharing that power with the GPU.
- **D3D12 on Intel graphics.** The project uses D3D12 on Windows. Its behaviour on Intel graphics is not measured here and is a risk of its own; Vulkan is the alternative to test on the notebook.

| Case | Desktop | Notebook (estimate) | Target |
|---|---|---|---|
| GPU, worst region (orchard_mill_town) 1080p | 1.44-1.50 ms | ~10 ms (9-15) | 16.6 ms, fits with little margin |
| GPU, worst region 720p | 0.64 ms | ~4.5 ms (4-6.4) | fits |
| CPU per frame, worst second (proc + phys) | ≤ 4.4 ms | ≤ ~9 ms | fits; runs alongside the GPU |
| walk across a room boundary | 13-16 ms | ~26-31 ms | under 33, but a dropped frame at 60 Hz |
| arrival after a door or teleport | 26-51 ms | ~50-100 ms | allowed (room load; doors fade) |

## What to fix first (ranked by expected gain on the notebook)

1. **Spread room activation over frames and cut the ~4 ms `_ready` per room.**
   - *Why first:* it is the only measured cause of frames near or over 33 ms outside a door fade.
   - *Change:* activate the current room first, then one neighbour per frame. Also find out what in the contents' `_ready` takes 3-5 ms (the RoomMap build of tiles, grass and water, or the Backdrop's mesh and material setup) and cache or prebuild it.
   - *Expected:* a walking crossing drops from 13-16 ms to about 4-5 ms on the desktop (about 8-10 ms on the notebook), and arrivals from 26-51 ms to about 5-10 ms plus a few cheap frames.
2. **Backdrop overdraw from the ring.**
   - *Why:* the largest GPU item, 0.6-1.0 ms of 1.0-1.5 ms at 1080p, about 4-7 ms on the Iris Xe.
   - *Change:* clip each layer's quad on the CPU to what the room can own on screen (its own rect plus the void cells it owns), so the inside needs no owner loop and the ring draws only where void is. Also skip a touching room's layers when it owns nothing in the camera view.
   - *Expected:* about half of the backdrop cost plus most of the "neighbours" delta in busy regions, 0.4-0.7 ms at 1080p, or **about 3-5 ms per frame on the Iris Xe in orchard_mill_town and woods_edge**.
   - *Constraint:* the change must keep `void_owner` and the hard seams identical (`systems/backdrops`, `backdrop_seams_test`).
3. **Render the world at game resolution instead of window resolution.**
   - *Why:* `canvas_items` stretch makes every pass pay for 1920x1080 pixels while the game draws 640x360.
   - *Change:* use `viewport` stretch mode, or a 640x360 world SubViewport scaled up with the HUD on top.
   - *Expected:* GPU time at 1080p falls by about 2.25x (1.44 to about 0.65 ms on the desktop; **about 10 to 4.5 ms on the Iris Xe**), and resolution stops mattering.
   - *Cost:* it is a project setting that changes how the camera's sub-pixel motion and the HUD text look, so it is the user's call. It is also the cheapest way to give TECH-14 its low-end headroom.
4. **Hide `DissonanceCopy` while the veil is hidden.**
   - *Why and change:* it copies the screen for nothing; a one-line fix.
   - *Expected:* 0.04-0.08 ms at 1080p, about 0.3-0.6 ms on the Iris Xe.
5. **Leave alone for now.**
   - The greyhush pass (0.11-0.25 ms, about 1-1.8 ms on the Iris Xe) is the game's look and already one pass.
   - Water reflection costs 0.10-0.12 ms where there is a lake.
   - Grass, CPU particles, `AmbientMotion`, the season mask, the two CanvasPasses and the region weather are each within noise (under 0.05-0.08 ms GPU). Optimizing them gains nothing measurable.

## Not measured

- **The editor run.** The user's reports most likely come from running inside the editor (TECH-11 saw frames 0.16 s apart with the editor open). It needs a run started from the editor with the remote debugger attached.
- **Gameplay effects.** The probe does not cover:
  - songs and pulses (colour-pulse particles, the Solstice);
  - guardian fights and the dissonance veil while visible;
  - the helix stair's SubViewport (village_bell_tower, lighthouse_interior);
  - the gale and wind zones;
  - many creatures at once;
  - larger rooms such as woods_deep.
- **A real Intel GPU.** Every notebook figure above is scaled. A run of the probe on the notebook itself (debug export or editor build) would replace the assumptions.

## After the fixes (2026-11-11)

The user chose three fixes on 2026-11-11: "Carregar salas aos poucos (Recommended)", "Fundo sem sobreposição (Recommended)" and "Desligar cópia do véu (Recommended)". Rendering the world at 640x360 was not chosen, so the stretch mode is unchanged. The user had felt the slowdowns "Rodando pelo editor" and "Ao trocar de sala".

- **Room loads** (`systems/rooms`, "Staggered builds"). A neighbour that needs a build waits and is built one per frame, or in the same frame once the view or Ivo reaches it. A door, a bench, a death or a hazard respawn builds the waiting rooms behind the black before fading in. `RoomMapNode` memoises each map's tile data and grass runs.
- **Backdrop overdraw** (`systems/backdrops`, "Clipped quads"). Each Backdrop is scissored to the bounding rect of `BackdropMath.drawn_cells`, a superset of the pixels it keeps.
- **Dissonance copy** (`systems/greyhush`). `DissonanceCopy` is visible only while the veil is.
- **Probe fix.** `_vis` in the probe now restores the visibility a node had, so toggling the dissonance copy no longer turns it on for good.

### Same machine, same session

Run with the method above, `--attrib=none --walk`, at 1280x720 and 1920x1080 with vsync off. "HEAD" is a clean checkout of the commit before the fixes, measured in the same session. It runs 5-15% below the first table above, so compare each "after" with HEAD, not with the first table.

GPU total ms (base sample mean):

| Room | 1080p HEAD | 1080p after | 720p HEAD | 720p after |
|---|---|---|---|---|
| orchard_mill_town | 1.24 | 0.64 | 0.59 | 0.33 |
| woods_edge | 1.11 | 0.66 | 0.54 | 0.34 |
| lake_fishing_village | 1.04 | 0.72 | 0.50 | 0.36 |
| village_mill | 1.03 | 0.69 | 0.51 | 0.35 |
| threshold_fields | 0.94 | 0.59 | 0.45 | 0.29 |
| frost_shore | 0.92 | 0.68 | 0.45 | 0.34 |
| caldera_open_crater | 0.89 | 0.67 | 0.43 | 0.33 |
| village_house | 0.53 | 0.38 | 0.26 | 0.20 |

- Draw calls fell from 55 to 32 in orchard_mill_town and from 43 to 31 in woods_edge (1080p), because off-screen clips cull their layers.
- **Frame dt mean at 1080p** fell from 1.29-1.53 ms (HEAD) to 0.60-1.01 ms.
- **Attribution at 1080p** (orchard_mill_town, woods_edge, lake_fishing_village; base and base_after now agree within 0.001 ms):
  - backdrops: -0.29 to -0.30 ms (before -0.63 to -0.99 ms);
  - neighbours: within noise (before -0.26 to -0.73 ms);
  - dissonance copy: 0 (before -0.04 to -0.08 ms);
  - all five full-screen passes: -0.18 to -0.25 ms (before -0.33 to -0.39 ms).

Room loads, worst frame in ms:

| Event | 1080p HEAD | 1080p after | 720p HEAD | 720p after |
|---|---|---|---|---|
| teleport into orchard_mill_town | 51.8 | 17.5 | 57.3 | 16.9 |
| teleport into woods_edge | 55.9 | 16.4 | 44.1 | 21.5 |
| teleport into lake_fishing_village | 38.4 | 19.5 | 43.5 | 19.3 |
| teleport into the other five rooms | 10.8-37.2 | 8.6-19.4 | 8.9-33.3 | 9.3-24.3 |
| frames over 33 ms, all eight teleports | 4 | 0 | 4 | 0 |
| warm revisit orchard_mill_town / village_mill | 48.9 / 28.3 | 16.3 / 12.5 | 50.1 / 26.6 | 15.1 / 11.2 |
| walk village_square to village_mill (x 1934) | 17.1 | 6.4 | 13.9 | 5.4 |
| walk village_mill to village_gate_east (x 3214) | 13.8 | 6.0 | 13.0 | 4.8 |

- A teleport's worst frame is now the arrival frame. It builds the current room plus the nearest waiting one (the room under or beside the view, if the view meets it). The next one to three frames each build one more room, at 4-16 ms on the desktop.
- **Two one-off steady frames.** The 720p base samples had a 17.0 ms frame (frost_shore) and a 19.4 ms frame (lake_fishing_village). Neither repeated at 1080p (worst steady frame 8.6 ms). Like village_house's spike in the first run, the cause was not found.
- **Warm build cost** (enter tree plus `_ready`): 0.9-3.9 ms, down from 2.8-5.0. The memo saves the tile and grass loops on a revisit or a death's rebuild. A first visit in a session still pays them.

### Scaled to the Iris Xe

The assumptions are unchanged from "Scaling to the target notebook": GPU about 7x (range 6-10), CPU about 2x.

| Case | Desktop after | Notebook estimate after | Notebook estimate before | Target |
|---|---|---|---|---|
| GPU, worst region (orchard_mill_town) 1080p | 0.64 ms | ~4.5 ms (3.8-6.4) | ~10 ms (9-15) | 16.6 ms, fits with margin |
| GPU, worst region 720p | 0.33-0.36 ms | ~2.5 ms (2-3.6) | ~4.5 ms | fits |
| walk across a room boundary | 4.8-6.4 ms | ~10-13 ms | ~26-31 ms | under 16.6 ms |
| teleport arrival | 8.6-24.3 ms | ~17-49 ms | ~50-100 ms | room load (allowed) |
| door, bench or death arrival | one build per frame behind the black (4-16 ms each) | ~8-32 ms per black frame | one 50-100 ms frame | room load (allowed) |

- **Against the target.** Steady 60 fps now has about 3.5x headroom on the GPU estimate at 1080p, and no measured frame outside a room load passes 33 ms even scaled (worst steady desktop frame 19.4 ms, about 39 ms scaled, a one-off). A walked boundary, the case the user felt ("Ao trocar de sala"), now fits a 60 Hz frame on the estimate.
- **Still open.**
  - A teleport's arrival frame can still reach about 49 ms on the notebook estimate. Doors fade, so it shows only on F10 and cutscene teleports.
  - The editor run ("Rodando pelo editor", TECH-11) was not measured again.
  - The estimates remain estimates until the probe runs on the notebook itself.

### Proof that the backdrop pixels did not change

- `backdrop_clip_test` checks every room the game and DebugTrials place (keeps implies within the cells, per part; no cell inside a neighbour). `backdrop_math_test` checks four small layouts pixel by pixel. `backdrop_seams_test` is unchanged and green.
- Screenshots were taken of only the backdrops: everything else hidden, Ivo and the camera's script stopped, the tree paused. Nine frames per room (the resting centre and the eight frames at the ring limit), each captured with the clip on, lifted, and on again. They are bit-identical in 71 of 81 frames:
  - village_house, village_mill, village_square, lake_chasm and frost_cliffs (both with a split `Sky`), lake_fishing_village, threshold_fields: 9 of 9 each;
  - woods_edge: 8 of 9;
  - orchard_mill_town: 0 of 9.
- **The orchard and the one woods_edge frame are not evidence against the clip.** In each of them the two captures with the clip on also differed from each other (a shift of the whole picture while paused), so they measure the scene moving, not the clip. The orchard's proof rests on `backdrop_clip_test`.

### Fix round: no extra build in the frame a room is entered (2026-11-11)

- **Finding.** The playtest (`playtests/2026-11-11-tech12-room-loading`, finding 1) found that the frame Ivo enters a room also built one waiting room. On a first visit that frame cost 16-20 ms (lake_waterfall_path when entering village_mill: 19.4-19.7 ms).
- **Change.** `Game` now passes `entered` to `RoomResidency.build_due`, so that frame builds only the due rooms, the ones the view or Ivo reaches.
- **Measure.** Re-measured like the playtest: `tools/playtest/scripts/room_residency_probe_driver.gd`, windowed with vsync on (180 Hz), dt between `frame_pre_draw`s, first visit in a fresh session, three runs each. The timelines are `tech12_village_ns` and `tech12_lane_woods_ns` (new: spawn (-1000, 280) and hold left).

| Crossing | Entry frame, playtest | Entry frame now | Frames after (one build each) |
|---|---|---|---|
| village_square -> village_mill | 19.4 / 19.7 | 7.0 / 7.0 / 7.5 | lake_waterfall_path 15.2-17.1, then village_gate_east 7.9-8.1 |
| village_mill -> village_gate_east | 15.7 / 16.5 / 18.0 | 7.2 / 7.6 / 7.6 | caldera_sun_stair 13.7-14.4, then threshold_fields 10.8-12.5 |
| village_lane_west -> woods_edge | 11.8 / 16.7 / 14.2 | 8.3 / 8.3 / 13.1 | woods_crown 6.3-16.1, woods_deep 16.1-16.8, woods_root_caves 14.9-15.1 (one run: 40.4 and 38.7) |

- **What moved.** The entry frame now costs 7-13 ms. The first-visit build of a large neighbour moved to the next frame, where it alone costs 14-17 ms. So the worst frame of a crossing fell only from about 19.7 to 17.1 ms (square -> mill) and from 18.0 to 14.4 ms (mill -> gate_east).
- **The outlier.** One lane_west -> woods_edge run spent 40 ms each building woods_deep and woods_root_caves. The other two runs spent about 16 ms on the same rooms, so the cost depends on the run, not on the code path; that run was likely loading the woods' assets for the first time in the session. The cause was not isolated.
- **Scaled to the Iris Xe** (CPU about 2x): a crossing's worst frame is about 28-34 ms on a first visit, and about 12-16 ms once the room has been built in the session (the tile and grass memo). It stays over 16.6 ms on the notebook for the first build of a large room.
- **The next lever.** Split a large room's build across frames (the RoomMap layers, then the entities), or prebuild the tile data at import. Not done here.
