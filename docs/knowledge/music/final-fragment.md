# The final fragment's underscore (in game 2026-11-18, STORY-43)

## Measured in `resources/cutscene/story/final_fragment.tres` (2026-11-18)

- Scene seconds from the steps: opening together 0..1.0, hold to 2.2, paper fade to 3.4; panels start 3.4, 12.4, 21.4, 30.4, 37.4, 49.4, 56.4 (9, 9, 9, 7, 12, 7, 12.5 s); clear 68.9..70.4, black 70.4..71.2.
- Panel 2: `ermo_phrase` (G E D C D E, beats 1 1 1 1 1 2.5 x 0.6 s) starts 1.5 s in: onsets 13.9..16.9, last note held to 18.4.
- Panel 4: `ermo_phrase` count 4 from 31.4 (to 33.8) and `ermo_spring` (C D C E C G) count 4 from 31.7 (to 34.1).
- Panel 7 has three caption turns of ~4.17 s; "Seu nome era Ermo." shows ~64.7..68.9.
- The opening's inline cue `final_fragment_silence` is stream-less; `finale_restoration` (100 BPM, C pedal under C5-G5 violas) is asked by `world_restoration` after the black.

## Rules that apply

- The "six notes at beat 0" rule is for song pieces only; a cutscene cue is free in key, but a quote of a phrase quotes its notes exactly (systems/music, "A piece that carries no song").
- While the note steps sound (13.0..19.3 and 31.0..34.5 s) the sketch has no onset and nothing sounding in MIDI 60..67 or on F/B; `check()` in the sketch enforces it.

## Proposal

- One one-shot cue, 60 BPM so a sketch beat is a scene second, started in place of the silence cue at scene 0. A minor (white keys), Bb only on panel 4 (the battle's bII crack).
- Shape: thread (0-3.4), chorale (panel 1), low A only under his phrase then a high viola echo (2), clarinet flower over his held A, swell to Fmaj9, cut dead at 30.9 (3), silence under the break then Bb against A (4), a slowing harp walk whose notes are caught into held fourths A D G C, stopping one note short (5), silence (6), his phrase passed cello-viola-flute in doubled values, the flute's E alone under the name, Am with C on top at the clear handing C to the restoration's pedal (7). Last note-off 71.4.
- Sketch writer: scratchpad `make_final_fragment_midis.py` (imports `make_finale_midis`); a tenth pitched track needs channel 9 skipped (its local `build` does).

## Learned

- Writing a Python file through a Bash heredoc that itself contains `"\\xff"` inside a nested string turned the escape into raw 0xFF bytes; write such files with the Write tool or keep byte escapes out of nested strings.

## Made (2026-11-18)

- User: "Principal (Recommended)", "Sim, 1 download (Recommended)", then on the MP3 "Aprovar e colocar (Recommended)". Panel 6 silent and the flute alone under the name, as proposed (not asked).
- AIVA: Import MIDI of `fragmento_final_underscore.mid`; the `s.solo-cello.nat.slur` track arrived as "Celli | Legato (Auto-Staccato)" (the section), set to Strings/Solo/Cello/Legato by patch search; the other five patches arrived right by name. Saved once (Mix & Normalise). 1 download (253 left this month); the WAV and the Orchestrated MIDI after it cost nothing. The orchestrated MIDI is `tools/audio/aiva/fragmento_final_underscore_orchestrated.mid`; the sketch and its generator stay in the session scratchpad.
- The render's first onset is 1.115 s for the sketch's 0.6 s (AIVA's 0.5 s lead-in); `assets/audios/music/final_fragment.ogg` is the WAV from 0.5 s (`ffmpeg -ss 0.5 ... -c:a libvorbis -q:a 6`), 74.2 s. Per-second RMS confirms the gaps: 32-34 s (panel 4) and 51-56 s (panel 6) at -44 dB or below.
- Integrated -17.7 LUFS; `gain_db` -6.3 to the restoration's -24.
