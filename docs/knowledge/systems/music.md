# Music

Updated 2026-11-02. How the game's music is made (AIVA), what each piece must keep, and what the existing pieces are.

## Contract

- **The Memorina's four notes** are G4 (UP), C4 (DOWN), D4 (LEFT), E4 (RIGHT) (`Enums.Note`, `assets/audios/sfx/memorina/`). A song's motif and the lead around it stay on the white keys, so those notes always fit; the mode gives the season its colour (below). Harmony may borrow (Solstício's violas use F#).
- **A song's piece opens with its motif.** The lead (flute in every existing piece) states the song's six notes, an octave up (C5 D5 E5 G5), from beat 0, before any harmony. The game lights each glyph on `Song.note_cues`, so the motif's timing is part of the contract.
- **Two lengths per song** (`resources/songs/song.gd`): `track` (the full piece, heard once at the lesson) and `excerpt` (heard each time the song is played in the world, the world frozen for `excerpt_duration`, 7 s, then a 0.5 s fade; null cuts the track instead, mid-phrase). An excerpt must start at the same instant as its track, so one `note_cues` serves both. Trim an excerpt to `excerpt_duration`: AIVA rounds a piece up to whole sections, with silence after.
- **AIVA adds a lead-in** before the first note (0.56 s on Sombra's two pieces). Measure the onsets in the rendered WAV and set `note_cues` from them, never from the sketch's beats.
- **No melody note of a motif changes in an arrangement.** Timbre, harmony, register of the accompaniment and tempo may change; the six notes and their order may not.
- **A piece that carries no song** (a region theme, the wife's song, a cutscene) is free in key and notes, but a theme quoting a song quotes its motif exactly.

## The existing pieces

AIVA account (creators.aiva.ai, v1), all made 2026-09-19/20 with the custom style "Memorina" (folder in Styles). MIDIs downloaded to `tools/audio/aiva/existing/` on 2026-11-02. The AIVA titles and "source" names are from the retired song matrix (design 02 section 7.1); the game file names were given later.

| Game file | AIVA title (source) | Key, tempo, meter | Opening motif | Song | Match |
|---|---|---|---|---|---|
| `hymn_of_frost.mp3` | Hymn of Frost (FREEZE) | A minor, 52, 4/4, rubato | G E D C C C | Congelar | yes |
| `lullaby_under_glass.mp3` | Song of the Restless Wind (BLIZZARD) | A Dorian, 110, 6/8 | D E D E G C | Redoma | yes |
| `song_of_falling_leaves.mp3` | Dirge of Hollow Bark (WEAKEN) | E Phrygian, 61, 3/4 | G C D C E C | Soltar | yes |
| `song_of_the_restless_wind.mp3` | Song of Bare Branches (STRIP) | E minor, 72, 4/4 | E E D D G E | Vendaval | yes |
| `song_of_the_green_reaching.mp3` | Song of the Green Reaching (SPROUT) | G Mixolydian, 76, 6/8 | C D C E C G | Enraizar | yes |
| `song_of_the_first_rain.mp3` | Song of the Cracking Shell (HATCH) | G major, 100, 4/4 | E E E G C G | Chuva | yes |
| `song_of_the_noon_shadow.ogg` + `_excerpt.ogg` | sombra_completa.mid / sombra_reduzida.mid (imported sketch) | C major on a G pedal, 90, 4/4 | C D E G G G | Sombra | yes (2026-11-02) |
| `song_of_the_longest_day.mp3` | Call of the Lightning (SUDDEN STORM) | C Lydian, 140, 2/4 | E C G E C G | Solstício | yes |
| `memorina/note_*.mp3` | Memorina Notes (Alone Notes) | A minor, 52 | C D E G | the four notes | yes |

Matched by MD5 of the AIVA MP3 against the game file (Redoma and Vendaval) and by duration plus opening motif (the rest). The two winter/autumn names are crossed: the game's `song_of_the_restless_wind.mp3` is AIVA's "Song of Bare Branches".

What the pieces share: flute lead (`w.flute2`), a solo viola or violas for harmony, contrabass or a low piano for the bass; harp in spring and summer; taiko and orchestral kit in the fast pieces (Redoma's piece, Solstício). Bars 1-2 are the motif alone; the harmony enters after it.

Sombra's old track (`chant_of_the_noon_sun.mp3`, AIVA "Chant of the Waking Sun") played the retired Sol Concentrado's notes (C D E E G A); it was replaced on 2026-11-02 by "Meio-dia sobre Sol" (`docs/knowledge/music/sombra-remake.md`): the flute's motif with a solo cello mirroring it below, one beat late (the shadow), ending suspended on G. No other song has an `excerpt` yet.

## Tools

- `tools/audio/make_aiva_midis.py` writes the MIDI sketches (`tools/audio/midi/`, its README says how each is used in AIVA).
- The `aiva` skill drives AIVA in Chrome; the `composer` agent proposes music; the `song-loop` skill runs one piece from proposal to the game, with the user's approval at each gate.

## Decisions

- "Eu aprovo essas coisas" (user, 2026-11-02): the `aiva` skill, the `composer` agent and the `song-loop`, consulting the user before anything is finished or generated.
- "Vou assinar um plano" / "Agora temos 300 downloads disponíveis" (user, 2026-11-02): reduced versions are made in AIVA, not rendered locally.
- "Se o agente tiver uma ideia melhor para elas, eu topo!" (user, 2026-11-02): existing pieces may be remade when the composer proposes better, with the user's approval.
- Sombra: "Meio-dia sobre Sol (Recommended)", "Suspensa em Sol (Recommended)", "Importar o esboço exato (Recommended)"; then "a versão completa está ótima" (user, 2026-11-02).
- "Descartar (Recommended)" (user, 2026-11-02): no answer stinger; a song has a track and an excerpt only.
- "No chamado da luta" (user, 2026-11-02): each guardian's call sounds in its own instrument, not the Memorina's flute ("a versão de como fosse o guardião tocando em seu respectivo instrumento antes de nós aprendermos"). Not built yet. "Cada guardião toca flautas também" (user, 2026-11-02): every guardian's instrument is a flute, each its own kind.
- "Eu assinei a versão que nos dá autoria total. Não precisamos dar créditos ao AIVA" (user, 2026-11-02): AIVA music takes no `CREDITS.md` line.
- The final song: G E D C D E, then E G E D D C ("Aprovar a sequência", user, 2026-11-02; `systems/guardians`).
