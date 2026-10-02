---
id: playtests/2026-10-02-pause-menu
type: playtest
title: The pause menu (UI-02) - opens dimmed and still, resumes without a jump or a roll, refuses a performance; a release made in the menu is lost
status: active
build: b2ce006 + uncommitted UI-02 working tree
area_tested: "Pause menu over the winter trial (TrialSpawn 160, 5960) and the summer trial's bench (2470, 5990); keyboard, pad buttons and left stick"
tags: [pause, menu, ui, input, gamepad, worldfreeze, performance, playtest]
related: [architecture/pause-menu-worldfreeze-reuse, bugs/player-input-edge-state-goes-stale-across-a-pause-menu, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/a-stick-is-pressed-on-every-motion-event]
created: 2026-10-02
updated: 2026-10-02
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-02-pause-menu/open_dim_and_still.png
  - screenshots/2026-10-02-pause-menu/focus_and_confirm.png
  - screenshots/2026-10-02-pause-menu/song_ringout_refused_after.png
  - screenshots/2026-10-02-pause-menu/roll_and_air_resume.png
  - screenshots/2026-10-02-pause-menu/bench_down_lost.png
  - screenshots/2026-10-02-pause-menu/no_button_tilde.png
---

## What was tested

Eight timelines in `tools/playtest/scripts/pause_menu_*.json`, all `"clock": "real"`, Godot
4.7.2 windowed, locale pt_BR. The runner gained raw `key` / `joy_button` / `joy_axis` steps,
a `log` step and a `skills` field for this session (`tools/playtest/README.md`). An `action`
step cannot test this menu: `jump` as an `InputEventAction` never matches `ui_accept`, so the
Z overlap is invisible to it. Every claim about focus, pause state and Ivo's motion below
comes from the `log` lines, not from reading frames.

- `keyboard`: Esc while running, three frames 0.5 s apart, Esc to close; Down/Up; resume
  by Enter and by Z; the quit confirmation with Left/Right, Esc and Enter on No.
- `gamepad` (roll unlocked): Start, stick down and up (seven motion events per tilt), A,
  Start twice, B, A on Quit game, B twice. An unpaused B at the end checks that B rolls.
- `song_refused` / `song_ringout` (FREEZE known): draw, play up-right-left-down-down-down,
  Esc at several moments of the performance, then after it.
- `roll_air` (roll unlocked): Esc mid-roll; Esc mid-rise with Z held through the menu; Esc
  mid-rise with Z released inside the menu; unpaused tap and hold jumps for reference.
- `bench_down_release` / `bench_stick_held`: the stale input edge at the summer bench.
- `quit_yes`: Yes on the confirmation, run last.

## Findings

Pass or fail per check:

1. **Esc opens the menu dimmed and still: pass** (`open_dim_and_still.png`). The banner
   reads PAUSA, Continuar has the orange Selected look with the yellow rim, Sair do jogo sits
   below it. Sampled world pixels drop to 0.45 of their unpaused value, which is the 55 %
   black `Dim`. Three frames 0.5 s apart under the menu are pixel-identical (0 changed
   pixels over the whole frame) while Ivo is mid-run; the log holds `run` at clip position
   0.433. In other runs the life-note flags in the HUD keep swaying under the dim
   (`LifeHud` is ALWAYS) and a pulse ring keeps spreading. That is the expected exception.
2. **One focus move per press: pass.** Down moves to QuitGame and Up back to Resume. Each
   left-stick tilt of seven motion events (0.25 to 1.0) moves focus once, in both
   directions. With two entries a double move could not show on screen, so a headless
   probe with five buttons confirmed the engine moves once per deadzone crossing
   (`gotchas/gui-focus-moves-once-per-stick-tilt`).
3. **Resume without a jump or a roll: pass.** Enter, Z and pad A resume on the release.
   The log shows `paused=true` 0.05 s after the press and `paused=false` 0.05 s after the
   release. While Z is held, Continuar wears the darker Pressed look
   (`focus_and_confirm.png`, third frame). After each resume Ivo stays at y 6000 with
   `vel.y = 0` and `jump=false` for 0.85 s. Esc closes the menu, Start opens and closes
   it, and B closes it with `roll=false` throughout. The B check is real: in the same
   run, with roll unlocked, an unpaused B rolls him at 345.9 px/s.
4. **Quit confirmation: pass** (`focus_and_confirm.png`). Confirming Quit game shows the
   question with Não focused. Left focuses Sim and Right returns to Não. Esc (or B) goes
   back to the menu with Sair do jogo focused, and so does Enter on Não. Yes quits the
   app: the log line due 0.7 s later never printed, and the process exited 0 with no
   errors.
5. **Pause refused during a performance: pass** (`song_ringout_refused_after.png`). Esc
   pressed four times during the excerpt opens nothing: `focus=none`, and the pause stays
   the performance's. Once the excerpt ends, Esc opens the menu over the spreading pulse.
   After the close, `paused=false` and `time_scale=1.00`, and Ivo walks 115 px in 0.6 s
   at 192 px/s. **Also: Esc in the ring-out opens the menu.** Between the last note and
   the performance's freeze (at least 0.9 s), the tree is not paused, so the menu opens over
   the instrument sheet (first frame). The performance does not start under the menu. It
   starts within 0.2 s of the close (`paused=true, focus=none`), runs its full length and thaws. The sheet sits dimmed beside the panel, which
   overlaps its left end. Cosmetic.
6. **Mid-roll and mid-air: pass, with the known input bug.** `roll_and_air_resume.png`
   shows mid-roll paused at clip 0.083: frozen, then completing at 345.9 px/s and returning
   to `run` within 0.6 s of the resume. Mid-rise with Z held through the menu, the frame is
   frozen and the rise resumes at -337 px/s, peaking at y 5850. An unpaused held jump
   peaks at 5848.7, so the pause cost nothing.
   **Fail: a jump released inside the menu is never cut.** It peaks at y 5849.2, a full
   jump. An unpaused tap released at the same 0.15 s peaks at 5911.5.
7. **The stale down edge reproduces** (`bench_down_lost.png`). With Down released inside
   the menu, the first Down at the bench after resuming does nothing and the second sits
   him. With the stick held down from menu navigation when B closes the menu, one more
   motion event sits Ivo unasked. Both are
   `bugs/player-input-edge-state-goes-stale-across-a-pause-menu`, which predicted them
   from the code. It now has the reproductions; this report does not file a new bug.
8. **Text** (`no_button_tilde.png`). At this font size the tilde of "Não" reads as an
   umlaut ("Näo") with a gap before the o. The confirmation has no title or question: the
   body says only that progress since the last bench will be lost, and Sim/Não answer an
   implied "quit?". Both are readable, but a player has to infer what Sim does.

What frames cannot show: input latency, how the resume-on-release feels (it adds the
hold time of the press before the world moves; inferred to be under 0.1 s for a normal
tap), and any audio while paused. Opening on the press and closing on the release is
taken from the log timing, not felt.

## Ratings rationale

- **Fun 0**: not applicable to a pause menu. This is the life-loop session's convention for
  a system that is not play.
- **Fluidity 4**: every open, close and focus move landed on the first press, and no
  resume leaked a jump or a roll. The pause is exact, with not a pixel of drift. It is not
  a 5 because a release made inside the menu is lost (the jump cut and the down edge).
  Those are edge cases, but a player will meet them by pausing mid-jump.
- **Aesthetics 4**: the wood panel, the banner and the orange Selected state read clearly
  against the 55 % dim in both the grey and the remembered world. The tilde glyph and the
  question-less confirmation hold it below 5. The menu also covers Ivo when the camera
  centres him, which is normal for a pause screen.
