# Final battle and restoration music (proposal, 2026-11-02)

## What the game has (measured 2026-11-02)

- No background music anywhere: no music bus (no `default_bus_layout.tres`, no `bus` set on any player), no fight music, no region theme. Every `AudioStreamPlayer` is a note voice (`SongPerformance`, `MemorinaVoice`, guardian `Call/Voice`, `CallB/Voice`, creatures), a cutscene `sound()`/`melody()` or a story beat. Design 06 deferred "um barramento de música e o abafar ... para quando houver música".
- The mentor's `Call` and `CallB` use the Memorina's own note samples (`note_*_g4/c4/d4/e4.mp3`), so his calls and Ivo's answers both sound in C4..G4.
- `world_restoration.tres`: after bars, fade and a 0.6 s wait, `together_14` runs `mentor_winter.tres` (G E D C C C, beats 1 1 1 1 1 2.5 at 0.6 s = 100 BPM, 4.5 s) with the camera pull (4.5 s); then the lamp 1.6 s, wait 2, camera back 2, wait 1 (11.1 s from the melody's start). `CutsceneSound` blocks its sequence until the stream ends, so a cue under the melody must sit inside `together_14` and be no longer than the steps after it, or it delays them.
- `make_aiva_midis.py` used to write `batalha_final_esboco.mid` and `restauracao.mid` with GM programs and Portuguese track names; replaced by `make_finale_midis.py` (AIVA patch-id names).

## Proposal

- Fight loop `finale_luta.mid`: A minor, 80 BPM, 4/4, 16 bars = 48 s. Bars 1-2 (revised 2026-11-02, see Decisions): Am pedal on viola E3-A3 and piano A1-A2 (beats 1, 2.5, 4), taiko eighth-note ostinato, Congelar two octaves down in the basses (G2 E2 D2 C2 C2 C2); the flute first sings Congelar at bar 13. Bed Am Am | F | Dm | Em | Am | F G | Bb (bII, borrowed Phrygian, "the crack") | Esus4, back to bar 1. Spring stem: harp on a 1.5-beat grid (6/8 against 4/4, G Mixolydian cells G-D-B / F-C-A) and clarinet Enraizar at bar 5 and half a beat behind the flute's Congelar at bar 13.
- Device: A Aeolian and G Mixolydian use the same seven white keys, so the dissonance comes from two centres and two meters, not from wrong notes; removing the spring stem leaves a complete piece.
- Register rule: nothing but the lead (C5 and up) enters C4..G4 in any stem, so the call's note voices stay clear; the code should also drop the lead stem and duck the rest during a call.
- Final call underscore `finale_chamado.mid`: 60 BPM, 4 bars (16 s) loop, Am | Fmaj7 on basses and high viola only; phrase A ends on E, phrase B on C, both inside each chord.
- Restoration `finale_restauracao.mid`: 100 BPM (mentor_winter's beat), C pedal and high violas under his voice (beats 0-7.5), harp run at the lamp, flute phrase B (E G E D D C) over C Am F G C, ending on C with A above; ritardando to 84; last note-off ~11.4 s.
- Writer: `tools/audio/make_finale_midis.py`, importing `make_miniature_midis` (needs `sys.path` insert because `python -I` drops the script directory). Track names are "patch-id (stem)"; `build` reads the patch id before the first space.

## Decisions (user, 2026-11-02)

- A general music system, not a one-off: "Sistema de música geral (Recommended)". The final battle is its first use.
- Spring's voice in the revelation: "Clarinete (Recommended)".
- Restoration, when the lamp lights: Ivo's phrase, "A frase do Ivo (Recommended)".
- During calls the bed ducks about 6 dB: "Abafa ~6 dB (Recommended)".
- 2026-11-02, on the fight loop's opening: "eu não gosto da ideia do início ser exatamente igual ao da primavera. poderia dar uma diferenciadinha". Bars 1-2 had the flute state Congelar alone, the way every song piece opens, so the battle sounded like a song lesson. Changed: bars 1-2 now open with the winter bed already driving (Am pedal, taiko ostinato, Congelar low in the basses under C4); the flute is silent until bar 9. Bar 13 unchanged. Bar 16 (Esus4) returns to the Am pedal, a V-i into the loop. The "motif alone at beat 0" rule applies to song pieces only; no note cues are read from the fight cue.
