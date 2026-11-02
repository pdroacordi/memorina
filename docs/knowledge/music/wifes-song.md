# The wife's song (proposal, 2026-11-02)

- Tempo is fixed by `morning_song.tres`: beat_seconds 0.42 = quarter 142.86 BPM (MIDI tempo 420000 us). The earlier sketch (`cancao_da_esposa_*`, 76 BPM) played the morning phrase at almost half the guitar's speed; it was removed with `wife_song()` in `make_aiva_midis.py`.
- The guitar scene's gap is at note 5 (`guitar_first`, after E G E D C) or 4 (`guitar_again`). Ivo's final phrase B (E G E D D C) differs from her line exactly at note 5: his D where she sang C. That is "the same wrong note" of design 01 §9.4; the epilogue sketch sounds his D against her C there.
- Her lost ending is `...E G | A G E | D. E C`: it peaks on A4, the one white key the Memorina cannot play (its notes are C D E G). In the epilogue the flute holds G under her A. Ivo's ending (D D C) steps down; hers lifts D-E before landing on C.
- Where it is heard: the mentor's flicker (`wife_hum_opening.wav`, built, synth placeholder: four notes); flashbacks 1 and 5 (STORY-05, planned); the epilogue (STORY-07, planned). The guitar and the daughter's hums are not music tracks (player-played samples; a child's voice AIVA does not have).
- Sketches: `tools/audio/make_wife_song_midis.py` -> `midi/esposa_{inteira,ninar,sopro,epilogo}.mid`, tpq 480, tracks named by AIVA patch id. The voice (`v.solo-soprano.nat.slur`) and guitar (`g.nylon-guitar.nat.stac`) ids are guesses; no existing AIVA MIDI has a voice or guitar track, so the patch must be set by search after import and the real id recorded here.
- Device: in the epilogue the flute follows her voice one beat late (heterophony, the inverse of Sombra's late shadow); her voice ends 2.5 beats before the flute's last C, so the piece ends with him alone.

## Decisions (user, 2026-11-02)

- The lost ending rises to A: "Sim, o Lá (Recommended)".
- The lullaby of flashback 5 is the same melody: "A mesma (Recommended)".
- The epilogue is a scene, one piece: "Cena (Recommended)".
- The daughter's hums: the synthesized placeholder sounds forced ("o hum dela ta meio forçado no momento acho"); another singing-voice tool is being looked for. AIVA has no child voice.

- Her voice: Ashley Lawless, "Mmh", Sustain (user, 2026-11-02: "Ashley"), chosen over Kiera "Mmh" and Masha "Hmm".
- The voice changed after listening: "Mmh" sounded like heavy autotune ("os hums estão muito estranhos... parecem autotune demais"); chosen instead: Ashley Lawless "Ouh" Sustain (Vibrato) ("Ashley Ouh", user, 2026-11-02), over a female choir. Vibrato and an open vowel hide the sample's fixed pitch.
