# Reduced versions (excerpts), proposal 2026-11-02

- An excerpt is the existing piece's own opening, cut and closed by a chord, so it shares the track's `note_cues`. Sketches: `tools/audio/make_reduced_midis.py` copies the existing MIDI's notes, tempo map and meter before the cut, clips held notes at the cut, then appends the closing. `make_aiva_midis.py` no longer writes `reduzida_*` (its generic 100 BPM versions were not the pieces' openings).
- `tools/audio/aiva/existing/*.mid` have tpq 720 and put tempo and meter in track 0; beats in 6/8 pieces are still counted in quarters by the file.
- Measured motif ends (sixth note off): Hymn of Frost 3.83 s (rubato 52-62), Restless Wind 1.64 s, Hollow Bark 2.95 s, Bare Branches 5.42 s, Green Reaching 2.76 s, Cracking Shell 4.20 s, Lightning 0.64 s. No motif runs past 6 s; 52 BPM is fine because the tempo rises to 62 by beat 3.5.
- Harmony entries in the originals: Frost F major at beat 4 (4.31 s), Am at 8; Restless Wind violas at beat 6, its own Am arrival with basses and taiko at beat 12 (6.55 s); Hollow Bark viola Esus2 at beat 3, Em at 6, F at 8 (Phrygian bII); Bare Branches piano E1 from 0, C chord at 5; Green Reaching C chord over a C2 pedal at beat 6 (the opening sits on C, not G, despite the "G Mixolydian" label); Cracking Shell viola F major at beat 8, no harp or bass before 8.4 s; Lightning bass walks C A D B C D E D from 0, violas only at beat 16 (6.86 s).
- Resulting sketch ends: Congelar 6.24 s, Redoma 7.36 s (needs excerpt_duration 7.5), Soltar 6.88 s, Vendaval 6.67 s, Enraizar 6.35 s, Chuva 6.60 s, Solsticio 6.00 s.

## Refused: the cut opening (2026-11-02)

- The user refused the cut-and-closed openings (`reduzida_*.mid`, rendered in AIVA): "não gostei muito... Elas estão apenas iguais as versões normais, porém cortadas e com um fade... para não dar apenas a impressão de ser apenas cortada e um fade, mas ser de fato uma versão reduzida? talvez aumentar um pouco a música ao invés de apenas 7 segundos? Podemos até pesquisar como zelda ocarina of time faz". Do not re-propose a cut of the full piece, with or without a closing chord.

## Proposal: the miniature (2026-11-02)

- Form: bar 1 is the full piece's motif with its exact rhythm and tempo map (so one `note_cues` still serves track and excerpt, no code change); bar 2 an answering phrase with the piece's harmony entering; bar 3 a cadence to the tonic held under a ritardando, then a soft high "chime" and release. Reference: Zelda (OoT, MM, Wind Waker) replays a played song as a complete short phrase with accompaniment while the world waits, and it ends on a held final note, not a fade.
- `tools/audio/make_miniature_midis.py` writes `midi/miniatura_<song>.mid` at tpq 480 with AIVA patch-id track names; it is self-contained (`make_reduced_midis.py` and the `reduzida_*` sketches of the seven songs were removed 2026-11-02).
- Congelar sketch measured: motif G E D C C C, sixth note off at 3.82 s (the original's 3.83 s), last note off 13.66 s. `excerpt_duration` would be ~14.5 s with the tail, `excerpt_fade` ~0 (the piece ends itself).
- Cadence used for winter: F - Dm - Esus4 - Em - Am, minor v with no G# (white keys), tonic held by ritardando 62 -> 40 BPM.

## The seven miniatures (2026-11-02)

- User decisions: "Sim, faça as 7"; length "10 a 14 s" with the world frozen (slow songs near 13-14 s, fast near 9-11 s); final gesture "Um por estação".
- Measured on the Congelar AIVA render: ~0.57 s lead-in, last note ~13.7 s, reverb of the held final chord audible to 16.3 s (~2.6 s tail). Budget: MIDI last note-off + 0.57 + 2.6 <= 14, so last note-off <= ~10.9 s.
- Last note-off per sketch (s): Congelar 10.83, Soltar 10.91, Vendaval 10.41, Enraizar 9.76, Chuva 9.03, Redoma 8.78, Solsticio 7.91.
- Cadences: Congelar F Dm Esus4 Em Am (minor v); Redoma Am G D Am (Dorian IV, plagal); Soltar Am F Em (Phrygian bII, flute F5-E5); Vendaval C Am Bm7 Em (minor v); Enraizar C F G (Mixolydian bVII-I, flute F5-G5); Chuva F C D G (borrowed bVII, then V); Solsticio C D/C C D/C C (Lydian II over a tonic pedal).
- Gestures: winter = high detached notes on the held tonic (piano A5+E6; violas E5, A5); autumn = a falling arpeggio B4 G4 E4 B3 under the held E5 (viola in Soltar, quicker clarinet in Vendaval); spring = 3-4 high harp plucks unevenly spaced; summer = violas alternating F#5/E5 in sixteenths, fading, drums stopped.
- Percussion tracks go on channel 9 with no program change: Redoma taiko B1 (35) on the dotted-quarter pulse as in the original, Solsticio taiko + orchestral kit F2 with the original's pattern.
- Verification: the six motif onsets equal the originals' to 0.01 s; note-offs are 1 tick (~1 ms) short by the writer's design.

## Vendaval miniature refused, rewritten (2026-11-02)

- User: "Vendaval ainda tem o fade final e não parece ser uma versão reduzida ainda". The AIVA render read as the full piece's opening fading out.
- Causes: a ritardando 72 -> 46 over the last four beats, a held Em under a falling clarinet B4 G4 E4 B3 at decreasing velocity. Slowing + decaying + falling = a fade, not an ending.
- Rewrite: constant 72 BPM (no tempo change, so the motif at beats 0-5 keeps the original's timing; the original's first tempo change is at beat 12). Answer in driving eighths over Am (iv) and Bm (minor v), piano octaves A1/A2, B1/B2 crescendo 58 -> 72; a rising sixteenth gust (flute B4 C5 D5 E5, clarinet G3 B3 D4 F#4) lands on a short accented Em (0.75 beat, velocity 96-100) at beat 10.
- Last note-off 10.75 beats = 8.96 s; with AIVA's ~0.57 s lead-in and ~1 s trimmed tail, ~10.5 s audible.
- Rule learned: a miniature's cadence must arrive by crescendo and attack, not by ritardando and decay, or it sounds like an excerpt fading out.
