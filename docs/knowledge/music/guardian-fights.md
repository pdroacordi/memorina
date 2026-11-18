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

## Call voices (2026-11-03, proposal, not approved)
- A call voice is four single-note samples (G C D E pitch classes), not a piece; sketched one per 4/4 bar at 60 BPM, held 1.2 s, cut at 0/4/8/12 s (`tools/audio/make_call_note_midis.py`).
- Proposed: Frost alto flute an octave down (G3 C3 D3 E3; alto flute bottoms at G3, so C3..E3 needs a bass flute or a pitch-shifted render), Bloom pan flute at pitch, Summer piccolo an octave up, Autumn shakuhachi at pitch. AIVA patch ids are guesses until checked in its patch search.
- Any octave of G C D E is consonant over the lucid bed (C D E G A, outside MIDI 60..67).

## Call voices in the game (2026-11-03)

"Aprovar" the proposal, then "Troca próxima (Recommended)" when AIVA lacked the proposed flutes: Hulusi 1 (Frost, an octave down), Recorder (Bloom), Dizi (Summer, an octave up), Xiao (Autumn), all Sustain; "Aprovar, pôr no jogo" (user, 2026-11-03). AIVA's woodwinds: Bassoon, Clarinet, Dizi, Duduk, English Horn, Flute 1-3, Hulusi 1-2, Oboe, Recorder, Saxophone, Xiao (and a Lo-Fi Flute under Processed). One WAV render per guardian (4 downloads), cut at each onset to the -45 dB tail with a 0.25 s fade, normalised to -6 dB peak (the Dizi's C and D came out 10 dB under its G).

## Frost remake (2026-11-18)

"Sim, Inverno" (user, 2026-11-18): the Frost fight is remade first, under the rules the final battle's verdicts made binding for every fight: "a música já deveria começar um pouco mais frenética. algo estilo hollow knight ... isso serve para todas" and "a música de luta deve ser um loop enquanto há luta. isso vale para todas." (`docs/knowledge/music/final-battle.md`).

- Sketch `tools/audio/make_frost_fight_midis.py` writes `tools/audio/midi/luta_frost_epica.mid`: D Dorian, 7/8 grouped 2+2+3 at eighth = 360 (quarter 180), 120 bars of 7/6 s, one loop from beat 0 (140.0 s, `loop_offset` 0). The game cue counts eighths: `bpm` 360, `beats_per_bar` 7 (`BarClock` only needs a constant bar).
- Identity against the final battle (A minor with Bb, 4/4 at 200, horns and choir): another centre and mode (D Dorian, its B natural against the mentor's Bb), an odd meter, no brass or choir; the guardian's own Hulusi sings Congelar; glass timbres (Violins 1 Tremolo, harp and celesta high). Its line "guardar que virou parar" (`docs/design/drafts/guardian_talks.md`) is scored twice: the violins' seven-eighth figure is a palindrome (it ends where it began), and in the charge section every fourth bar (60-80) is a single tutti hit, then only the bed and the taiko kick on the group starts (the music stops, the pulse does not). The return (97-120) runs the violins up the scale instead ("Deixa correr").
- Form: A the still lake 1-32, B cracking 33-56 (accents regrouped 3+2+2, semitone neighbours), C the charge 57-80, D thin ice 81-96 (violas out, no taiko snare, soft running snare, celesta on four eighths), E let it run 97-120 (V into bar 1).
- Congelar fits the meter exactly: G E D on the group starts of one bar, C C C on the next. Quoted by the Hulusi at bars 5, 21, 41, 57, 69, 85, 101, 113 (octave 4), the celesta two octaves up at 57 and 101.
- The Frost call sounds an octave down (Hulusi G3 C3 D3 E3, MIDI 48..55), so its bed keeps out of 48..55 as well as 60..67; same pitch classes (C D E G A; F and B only as roots at MIDI 47 or under). `check()` enforces both ranges.
- Lesson from the finale's production (2026-11-18): AIVA's Violas ensemble has Spiccato, not Staccato; stems render "Group by layer", one WAV per track, so two tracks may share a patch. The call duck is now -12 dB for every fight.
- Decisions (user, 2026-11-18): "7/8 (Recommended)": the 2+2+3 meter stays. "Bumbo continua": a frozen bar keeps the taiko kick on the group starts (eighths 0, 2, 4) under the tutti hit, so the urgency never drops. "Sim, gerar": the sketch goes to AIVA.
- AIVA's Import MIDI refuses a 7/8 time signature ("Invalid time signature", 2026-11-18; 4/4, 3/4 and 6/8 work). The file therefore declares 4/4 at quarter 180 with every note at its 7/8 time: 120 bars of 7/8 = 420 quarters = 105 bars of 4/4 = 140.0 s. Section markers sit on the nearest 4/4 bar line. The game cue still counts the music's own bar (`bpm` 360, `beats_per_bar` 7).

## Frost in the game (2026-11-18)

- "Aprovar, fazer stems" (user, 2026-11-18). AIVA `luta_frost_epica.mid` (editor id 6afdb1c7f51fc831cb2fa342), 1 download.
- Patches after import: Hulusi 1 came as Legato (kept), `s.violins.trem.slur` came as Steinway D Piano (set to Violins 1 Tremolo), `s.solo-cello.nat.slur` as the Celli ensemble (set to solo Cello Sustain); Violins 1 Spiccato, Celli Spiccato, Epic Taikos Kit, Orchestral Kit with Crash Left set by hand.
- Stems by layer; lead-in 0.481 s cut, 6.05 s of tail folded, loop 140.0 s. Summed -15.6 LUFS, `gain_db` -6.4. `fight_frost.tres`: bpm 360, beats_per_bar 7.
