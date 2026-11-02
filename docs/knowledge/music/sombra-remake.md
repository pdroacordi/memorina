# Sombra remake (proposal, 2026-11-02)

- The game's Sombra track (`chant_of_the_noon_sun.mp3`, AIVA "Chant of the Waking Sun") opens C D E E G A; Sombra is C D E G G G. Measured from `tools/audio/aiva/existing/chant_of_the_waking_sun.mid`: flute onsets 0,1,2,3,4,5 at 104 BPM; harp enters only at beat 44; viola at 18.5; basses at 30.25.
- `shadow.tres` note_cues are 0.5..5.5 s at 1 s spacing; any remake changes them (the 90 BPM proposal: 0, 0.67, 1.33, 2.0, 2.67, 3.33 s).
- Diatonic mirror device: on the white keys only an axis of D (or G#/Ab) maps white keys to white keys. Mirroring a motif around D gives its "shadow" without accidentals (C D E G -> E D C A). Used for Sombra's viola canon.
- Solstício (`call_of_the_lightning.mid`) is C Lydian with F# in the violas, so the "white keys" rule is already broken there in harmony; the motif itself stays white.
- `make_aiva_midis.py` now runs `main()` only under `__main__`, so other scripts can import `Track` and `save`. Sombra sketches: `tools/audio/make_sombra_midis.py`.
- Chosen 2026-11-02: the main proposal (90 BPM, G pedal, suspended end), imported exactly. The sundial alternative was not taken; its code was removed.
- In AIVA the shadow line went to "Solo Cello | Legato": the mirror reaches A2 and AIVA's "Violas" stop at C3. The generator now writes a cello.
- Rendered: both pieces start their first note at 0.56 s (AIVA's lead-in); note_cues 0.56, 1.23, 1.9, 2.56, 3.23, 3.9.
