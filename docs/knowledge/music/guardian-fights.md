# Guardian fight loops (proposal, 2026-11-03)

Sketches only, not approved: `tools/audio/make_guardian_fight_midis.py` writes `tools/audio/midi/luta_{frost,bloom,summer,autumn}.mid`.

- Stem split that lets `GuardianMusic` work unchanged: `lead` carries all the drive (taiko, staccato ostinato, the flute or clarinet, every modal colour note: B/F in winter, B/F in spring, F# in summer, F/B in autumn); `bed` is sustained harmony only. Muting `lead` at `lucid_landed` therefore turns the fight into a calm pad by itself, no extra stem needed.
- The bed is built only from C D E G A (the major pentatonic holding the Memorina's G4 C4 D4 E4), never in MIDI 60..67, so any call or echo note is consonant with it. Checked by script over every bed note.
- Each fight uses its arena region's key and meter at about double speed: frost A Aeolian 120 (lake A minor 50), bloom G Mixolydian 6/8 144 (woods 72), summer C Lydian on G pedal 132 (caldera 58), autumn E Phrygian 3/4 156 (orchards 60).
- Motif quoted once, exactly, in the lead at the loop's middle; the ostinato rests there so the quote is heard.
- Gotcha: `make_finale_midis.build` and any `at()` helper read the global `BEATS_PER_BAR`; set the meter before computing any beat, not only in `write()`, or a 3/4 piece is laid out in 4/4 (happened here on the first run).

## In the game (2026-11-03)

- Proposal approved as drafted ("Aprovar", user, 2026-11-03); the composer's open questions (doubling the loops, a soft taiko in the lucid bed, the guardians' call flutes) were left unanswered and nothing was changed for them.
- AIVA mapped `p.taikos.nat.stac` to "Rock Drumkit 1" in all four; set to "Epic Taikos Kit" by hand (patch search, Save, Mix & Normalise) before Render Stems. 4 downloads.
- Loops: frost 32 s, bloom 20 s, summer 29.09 s, autumn 27.69 s; about 6 s of ring past each loop is folded onto its start (`build_stems.py`).
- A `.tres` property written before `script = ...` is dropped on load: keep `script` first under `[resource]`.
