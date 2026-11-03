# Region themes (proposal, 2026-11-03)

Sketches only, not approved: `tools/audio/make_region_midis.py` writes `tools/audio/midi/regiao_<id>.mid`.

- Governing constraint (user, 2026-11-02): "O cinza é vazio... quanto mais cinza, mais vazio deve ser." Density is mapped to the region's starting memory level: frost_edge (0.05) has 5 notes in 96 s; the village (0.8) has a continuous harp.
- Two stems per region: `base` (always) and `memoria` (level follows the region's memory, a `MusicCue` level). Frost edge has no `memoria` stem.
- Rests are written into the loop (2-4 bars per 16), so the silence loops with the music.
- A guardian's motif is quoted once per loop, exactly, only in the `memoria` stem: restoring memory is what lets the region remember its song. Threshold, frost edge and the village quote nothing.
- Only a quoting lead enters C4..G4 (the Memorina's register); bed voices stay below C4 or at B4 and above.
- The track name must be the bare patch id; `build()` in `make_finale_midis.py` reads its `BEATS_PER_BAR` global, so the region script sets it per meter.

## Decisions (user, 2026-11-03)

- The guardian's quote lives only in the `memoria` stem: "Concordo, quando a cor volta. Porém temos de tomar cuidado para não ficar repetitivo ou chato (por ex., toda vez que a cor volta a música recomeça). O volume deve ser bem controlado e tal." So the theme never restarts when colour returns: the stems play in sync from the region's entry, the `memoria` stem's level follows the region's memory over several seconds, and the cue continues across the region's rooms.
- Frost edge: "Silêncio total até a batalha final". No theme there before the finale.
- The village does not hint at the wife's song: "não. a canção da esposa é a canção da esposa".

## In the game (2026-11-03)

- Generated in AIVA from the sketches (imported, Render Stems grouped by layer): 6 downloads. Stems built with `build_stems.py`: `base` and `memory` (`memoria` in the sketches) per region, `assets/audios/music/region_<id>_{base,memory}.ogg`, loop on. Loops: village 65.45 s, threshold 71.11 s, spring woods 40 s, frozen lake 76.8 s, wind orchards 72 s, summer caldera 66.21 s.
- AIVA ends a render at its last sound: a loop whose last bars rest came back short (lake, orchards, caldera). `build_stems.py` pads the loop to its full length.
- The memory stem's level is the region's memory squared (`RegionMusic.memory_level`): the village (0.8) starts at 0.64, the threshold and lake (0.3) at 0.09 (about -21 dB), the caldera (0.15) at 0.02. "Aprovar, pôr no jogo" (user, 2026-11-03). Not yet heard in the game.
