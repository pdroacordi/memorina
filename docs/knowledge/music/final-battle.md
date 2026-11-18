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

## Remake (2026-11-18, in the game)

User verdict on all four fight loops and the finale, 2026-11-18: "Pouco épicas/intensas", "Laços curtos/repetitivos", "Som/timbre fraco", "Não combinam com o guardião"; "vamos refazer as musicas de batalha com o aiva. todas as batalhas, mas principalmente a batalha final."

- Tempo: first proposed at 100 BPM (mentor_winter's beat); "100bpm não é muito lento para uma batalha intensa?", then "200, o dobro (Recommended)" (user, 2026-11-18): each beat of his song is two fight beats.
- Decisions (user, 2026-11-18): "Tema da luta (Recommended)": the mentor's phrase A of the final call (G E D C D E) is the fight's theme (horns); phrase B (Ivo's) is withheld. "Coro (Recommended)": the choir stays. "Fica (Recommended)": the spring layer still rises at the revelation. "na verdade, não inclua o chamado nessa música. a música de luta deve ser um loop enquanto há luta. isso vale para todas.": the fight loop never crosses to `finale_call`. During a call: "segue, só abaixa, mas mais do que apenas 6db" (the lead drops, the bed ducks deeper; game side).
- v1 (200 BPM, a 16-bar intro played once) was rendered in AIVA and refused for its opening: "não gosto que começa só com os graves e um início muito lento. pense que o jogador vai entrar no cenário e não tem tempo de pensar, a luta já começou, o guardião já o está atacando. isso serve para todas. a música já deveria começar um pouco mais frenética. algo estilo hollow knight" (user, 2026-11-18). The reference is the energy and the string writing (restless high strings over pounding low strings and drums), never a melody.
- v2, `tools/audio/make_finale_fight_midis.py` -> `tools/audio/midi/finale_luta_epica.mid`: A minor with Bb, 200 BPM, 4/4, 128 bars of 1.2 s, one loop from beat 0 (153.6 s, `loop_offset` 0, `build_stems.py` unchanged). Beat 0 is a tutti hit (bass trombones, timpani, crash) with every drive track already running. Sections: A winter 1-32, B the crack 33-64 (bII Bb, 3+3+2), C keeping 65-96 (Congelar broad, then its C hammered from 81, released to B), D breath 97-112 (violas out, kick on 1 and 3, soft running snare; pulse kept), E return 113-128 (V into bar 1). Drive onsets (violins, violas, cellos, kits) 10.5/s in A, C and E, 7.1-7.6/s in B and D.
- Writing: harmony and sung lines on a 64-unit plan in half-time (`bar()`, doubled by `half_time()`), drive at 200 (`fbar()`): Violins 1 Spiccato in eighths over a four-note chord cell (semitone neighbours E-F, A-Bb in the crack; a falling sixteenth burst every fourth bar), violas in eighth-two-sixteenths gallops (off-beats in the crack), celli spiccato eighths, taikos with fills every 4 and 8 bars, snare backbeat or running eighths.
- Male Choir sings only under C4 (bed rule), so it doubles the low voicing; the high bed is Violins 1 Sustain (MIDI 79+).
- Kits: AIVA's Epic Taikos Kit was mapped to two channels only (Kick, Snare Center), the Orchestral Kit to three (Kick, Snare Center, Crash Left), on notes 35, 38, 41 of the sketch; a note on an unmapped channel is silent, so `check()` refuses any other drum note (v1's taiko 41 was silent).
- Call-safe bed (stricter than the register rule): bed pitch classes only A C D E G Bb (no semitone against G C D E), F and B only as roots at MIDI 47 or under, nothing in 60..67; the spring stem holds only C D E G A, its B and F at most one beat (0.3 s). Bb is call-safe: a whole tone from C, a tritone from E. F-major and E-major colour lives in the lead and leaves with it during a call.
- AIVA patch ids verified in its exports: `w.flute2.nat.{slur,stac}`, `w.clarinet1.nat.slur`, `s.solo-viola.nat.slur`, `s.violas.nat.stac`, `s.basses.vib.slur`, `s.solo-bass.nat.slur`, `s.harp2.pizz.stac`, `k.pop-piano.nat.stac`, `p.taikos.nat.stac`, `p.orchestral-kit.nat.stac`. The other ids are guesses; `PATCHES` in the script names the patch each is set to by hand.
- With more than nine pitched tracks the writer must skip MIDI channel 9 (drums); `make_finale_midis.build` would put the tenth pitched track on it.

## v2 in the game (2026-11-18)

- "Sim, gerar", then "Aprovar, fazer stems" (user, 2026-11-18). AIVA composition `finale_luta_epica_v2.mid` (editor id 6afd9f1cf51fc831cb2fa322); 2 downloads in all (v1 and v2), 256 left.
- Patches set by hand after import: 9 Horns Legato, 3 Bass Trombones Sustain, Violins 1 Spiccato (lead) and Sustain (bed), Celli Spiccato, Male Choir Sustain (it came in as Masha Mnjoyan, a solo singer), Epic Taikos Kit, Orchestral Kit with its third channel set to Crash Left (Unassigned after the kit swap). Violas came in as Spiccato, the Violas ensemble has no Staccato.
- Stems: "Group by instrument" merges two tracks on the same patch (both Violins 1 lines came out as one WAV, mixing lead and bed); render "Group by layer" for one WAV per track. Chrome saved the zips to the Desktop, not Downloads.
- `build_stems.py` cut 0.475 s of lead-in (AIVA's 0.5 s pad) and folded 14.5 s of tail; loop 153.6 s. All stems summed -15.5 LUFS, so `gain_db` -6.5 (fight target -22). `finale_fight.tres` bpm 200.

## Restoration remake (2026-11-18, in the game)

- Sketch `tools/audio/make_restoration_midis.py` writes two one-shot single-stem sketches at 100 BPM (mentor_winter's beat), C major, cue time 0 = his first note (`together_14` starts the cue beside `mentor_winter.tres`, G E D C C C, last note held to 4.5 s; the lamp lights 4.5-6.1 s; the scene's steps end at 11.1 s).
- Under his song (0-4.5 s) nothing sounds in MIDI 60..67 and only C D E G A (`check()`): Am7 | G (no B) | C as his C C C holds, the fight's A minor resolving to C exactly when he lands on C; a timpani roll into the lamp.
- At the lamp (4.5 s): crash, timpani, harp sweep up C major, celesta sparks, horns and male choir open to C.
- `restauracao_epica.mid` (fits the scene as it is): Ivo's phrase B (E G E D D C, "A frase do Ivo (Recommended)") in flute with horns an octave under, from 4.8 s, over C Am F G C; plagal F/C at beat 14; C with A on top (her song's lost note) from beat 15; ritardando to 92; last note-off 10.69 s.
- `restauracao_epica_longa.mid` (needs 6 s more in the scene, 17.1 s): horns and choir sing phrase A (the fight's theme) in C from 4.8 s, its last E now over C (the fight's tritone over Bb healed into a major third); Ivo's phrase B in the flute from 9.0 s, its D D over G and its C on the score's first perfect cadence (12.0 s); F/C, then C with A on top; ritardando to 90; last note-off 15.87 s. Proposed waits: after the lamp 2 -> 5 s, the last 1 -> 4 s.
- AIVA ids that mapped by name in earlier imports: `w.flute2.nat.slur`, `s.basses.vib.slur`, `s.harp2.pizz.stac`, the orchestral kit; horns, choir, violins, celli, celesta and timpani are set by hand (`PATCHES`). The render's lead-in (about 0.5 s) must be cut so his first note and the cue's beat 0 coincide.

### In the game (2026-11-18)

- Choice: "Longa, +6 s", then "Aprovar, colocar no jogo" (user, 2026-11-18). `world_restoration.tres`: `wait_16` 2 -> 5 s, `wait_18` 1 -> 4 s; the scene's steps after his first note run 17.1 s.
- AIVA: `restauracao_epica_longa.mid` imported (editor `/editor/6afdf38ef51fc831cb2fa48d/composition`). Patches arrived wrong and were set by hand: celli as "Celli | Legato (Auto-Staccato)" -> Celli Sustain; choir as Masha Mnjoyan (a solo singer) -> Male Choir Sustain; violins as Violas -> Violins 1 Sustain; horns as Horn 1 -> 9 Horns Legato; the kit as Rock Drumkit 1 -> Orchestral Kit with its channel set to Crash Left (`form_input` on the channel's select; a click does not open it). Basses, timpani, harp, celesta and flute arrived right. One download (250 left this month); the WAV after it was free.
- `assets/audios/music/finale_restoration.ogg`: the WAV from 0.5 s, 19.2 s, a 0.6 s fade from 18.6 s (the reverb falls under -50 dB at 18.3 s). Measured -15.4 LUFS; `gain_db` -8.6 to the restoration's -24. The tail rings about 2 s past the scene's last step; a one-shot rings out (`systems/music`).
- Not heard in the game yet.
