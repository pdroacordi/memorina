# Music

Updated 2026-11-02. How the game's music is made (AIVA), what each piece must keep, and what the existing pieces are.

## Contract

- **The Memorina's four notes** are G4 (UP), C4 (DOWN), D4 (LEFT), E4 (RIGHT) (`Enums.Note`, `assets/audios/sfx/memorina/`). A song's motif and the lead around it stay on the white keys, so those notes always fit; the mode gives the season its colour (below). Harmony may borrow (Solstício's violas use F#).
- **A song's piece opens with its motif.** The lead (flute in every existing piece) states the song's six notes, an octave up (C5 D5 E5 G5), from beat 0, before any harmony. The game lights each glyph on `Song.note_cues`, so the motif's timing is part of the contract.
- **Two lengths per song** (`resources/songs/song.gd`): `track` (the full piece, heard once at the lesson) and `excerpt` (heard each time the song is played in the world, the world frozen while it plays). The excerpt is a composed miniature, not a cut: the motif with the track's exact timing, an answering phrase, a cadence that arrives, and the season's closing gesture (`tools/audio/make_miniature_midis.py`, `docs/knowledge/music/reduced-versions.md`). It plays whole (`excerpt_duration = 0`, `excerpt_fade = 0`), 9-12 s, trimmed where the sound falls below -35 dB with a 0.4 s fade against a click. Its first note is aligned to the track's (within 2 ms), so one `note_cues` serves both. Sombra's excerpt is still the 7 s opening of its track (`excerpt_duration` 7, fade 0.5).
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

Sombra's old track (`chant_of_the_noon_sun.mp3`, AIVA "Chant of the Waking Sun") played the retired Sol Concentrado's notes (C D E E G A); it was replaced on 2026-11-02 by "Meio-dia sobre Sol" (`docs/knowledge/music/sombra-remake.md`): the flute's motif with a solo cello mirroring it below, one beat late (the shadow), ending suspended on G. 

## Runtime (SONG-15, 2026-11-02)

- **Buses** (`default_bus_layout.tres`, names in `AudioBuses`): `Music`, `Notes` (every played or sung note: Memorina, performances, calls, teachers, melodies, the guitar), `Sfx` (story sounds). Every scene `AudioStreamPlayer` names one (`audio_buses_test`); a player made in code sets `bus` from `AudioBuses`.
- **`Music`** (autoload, ALWAYS, `globals/music/music.gd`) plays the top `MusicRequest` (layers REGION < FIGHT < SCENE < MENU, newest wins a tie) on two crossfading decks. A request lives while its owner is in the tree; the same cue on top keeps playing (no restart). It knows no game rules, writes no `WorldFreeze`, reads no input. Paused while `WorldFreeze.is_held()` ("Para junto", user) and while hushed; fades and ducks step on real time.
- **`MusicCue`** (`resources/music/*.tres`): an `AudioStreamSynchronized` of stems (or one stream), stem names, starting levels, bpm, loop, fades. Stem volumes are set on a per-play copy. A looping cue's stems are OGGs with loop on, one length, a whole number of bars (`music_cue_test`); `tools/audio/build_stems.py` cuts them from an AIVA stems zip (lead-in cut, tail folded onto the start).
- **Ducks** are named and only touch Music; the deepest wins (`MusicMix`). The call duck is -6 dB; the final call's underscore is never ducked.
- **Fights:** `GuardianStats.music` and a `GuardianMusic` child: the cue starts when the fight leaves DORMANT, the `lead` stem leaves and the bus ducks while a call is open; on the mentor the `spring` stem rises at the revelation, the freeze frame hushes, a chosen track fades spring and crosses to `FinaleStats.call_music` on the next bar. A death frees the request: the cue fades over its `fade_out` (1 s).
- **Cutscenes:** `CutsceneMusic` (non-blocking) asks at SCENE layer; the scene's end lets a one-shot ring out, a skip fades over 0.8 s. `world_restoration` plays `finale_restoration` beside the mentor's melody.
- **Regions** (SONG-16, 2026-11-03): `Region.music` (stems `base`, `memory`) and `RegionMusic` in `game.tscn`, on `Game.room_changed`. Entering a region requests its cue at REGION layer, owned by the region; its other rooms keep the request; another region crossfades (3 s). The `memory` stem is the region's memory squared, following it over 4 real seconds, so colour returning lifts it without a restart. A region without a cue (frost edge, "Silêncio total até a batalha final", user, 2026-11-03; the trials) is silence. Six themes, `region_<id>.tres`; pieces `docs/knowledge/music/region-themes.md`.
- **Guardian fights** (SONG-17, 2026-11-03): `fight_<guardian>.tres` on each `GuardianStats.music`, stems `bed` (held harmony on C D E G A, clear of C4..G4) and `lead` (taiko, ostinato, melody, the motif quote), and a `GuardianMusic` child in each guardian scene. Lucidity drops `lead`, leaving the bed under the call. "Aprovar, pôr no jogo" (user, 2026-11-03). Pieces `docs/knowledge/music/guardian-fights.md`.
- Not yet: menu, the guardians' calls on their own flutes.

## The wife's song

`assets/audios/soundtrack/wife_song_{full,lullaby,epilogue}.ogg` (2026-11-02), Ashley Lawless "Ouh" with vibrato, the morning song's first eight notes exactly (`resources/story/morning_song.tres`, 143 BPM), the lost ending rising to A (a note the Memorina lacks). Not wired yet: they wait for the flashbacks (STORY-05) and the epilogue (STORY-07). Sketches `tools/audio/make_wife_song_midis.py`; decisions `docs/knowledge/music/wifes-song.md`.

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
- The reduced versions: the first cut-and-fade versions were refused ("Elas estão apenas iguais as versões normais, porém cortadas e com um fade", user, 2026-11-02); the miniature form was approved ("Sim, faça as 7"), "10 a 14 s", "Um por estação"; the ending silence must go ("todas tem um tempo longo de silêncio ao final... devemos cortar para não afetar a gameplay"); Vendaval rewritten ("Vendaval ainda tem o fade final") and approved ("Aprovar e pôr no jogo"), all 2026-11-02.
- `note_cues` of the 7 songs are measured: the AIVA MIDI's flute onsets through its tempo map, offset by the track's measured first onset (closes SONG-10 for them).
- The final song: G E D C D E, then E G E D D C ("Aprovar a sequência", user, 2026-11-02; `systems/guardians`).
- All the game's music next, in this session (user, 2026-11-02): "Façamos todas as músicas do jogo: Menu, Regiões, Bosses". Regions with the most care: "O cinza é vazio. Precisamos ter muito cuidado para não acabar com a sensação de vazio. A música tem que ser suave e, quanto mais cinza, mais vazio deve ser. Não podemos tirar esse clima mais introspectivo e reflexivo do jogo." Bosses: "acho que deve ser mais agitada, concorda?"
