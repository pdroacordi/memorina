# Title-screen theme (proposal, 2026-11-03)

- Sketch: `tools/audio/midi/menu_titulo.mid` from `tools/audio/make_menu_midis.py` (reuses `make_region_midis.write`). Approved and in the game (below).
- Constraints: no guardian six-note motif in full (taught in game), no wife's song quote (user 2026-11-03). Introspective grey (user).
- Device: four 4-bar sections in the seasons' modes (winter A Aeolian, spring G Mixolydian, summer C Lydian, autumn E Phrygian), matching the logo's four-colour flute pulse; each flute phrase lands on one Memorina note (G, C, D, E), so the four notes are heard only as phrase endings, never as a motif. 56 BPM 4/4, 16 bars, 68.6 s, one stem.
- The environment's plain `python -I` has no `mido`; verify MIDI another way.

## In the game (2026-11-03)

Approved as drafted ("Aprovar", user, 2026-11-03; the two open questions, section order and a flute-only first section, were not answered and nothing changed). Generated in AIVA (1 download), built to `assets/audios/music/menu_title.ogg` (68.57 s, loop on) with `build_stems.py`; no ring past the loop. Wired on `Title.music`.
