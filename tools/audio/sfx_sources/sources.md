# Sound-effect sources (SND-01)

Downloaded 2026-11-16 with the user's approval ("Baixe tudo (Recommended)"). The files live in `raw/`, which git ignores (52 MB); this list is enough to fetch them again. Every source is CC0 1.0 (checked on each page and in the packs' licence files). Cut, trimmed and normalised files go to `assets/audios/sfx/<group>/`, each credited in `CREDITS.md`.

| Use | Source | Author | Page |
|---|---|---|---|
| Cloth, books, doors, pouch, creaks | RPG Audio (50 files) | Kenney | https://kenney.nl/assets/rpg-audio |
| Menu tick, select, back, open, close | Interface Sounds (100 files) | Kenney | https://kenney.nl/assets/interface-sounds |
| Steps on earth; jump and landing | Footsteps_Mountain_Boots_Grass_Mono | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/556042/ |
| Steps on mud; landings | Footsteps_Mountain_Boots_Mud_Mono | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/548384/ |
| Steps on stone | Footsteps_Mountain_Boots_Rock_Walk_Sequence_Mono | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/558472/ |
| Steps on snow | Footsteps_Mountain_Boots_Snow_Walk_Mono | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/613849/ |
| Steps on wood | Footsteps_Wood_Walk_Mono | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/543685/ |
| Steps in shallow water | Water Footsteps (pack) | RomanKolachnik | https://freesound.org/people/RomanKolachnik/packs/37492/ |
| Sword swing | Swings And Whooshes (pack) | Joao_Janz | https://freesound.org/people/Joao_Janz/packs/27423/ |
| Ivo hurt (grunt) | Voice_AdultMale_PainGrunts_09 | MrFossy | https://freesound.org/people/MrFossy/sounds/547209/ |
| Creature death | Bag Of Flour Dropped On Counter Top | bbrocer | https://freesound.org/people/bbrocer/sounds/382642/ |
| Ivo death (fall) | Bodyfall_wood surface | speedygonzo | https://freesound.org/people/speedygonzo/sounds/235702/ |
| Bench rest | Wood creak, low, sit down on loose park bench and get up | kyles | https://freesound.org/people/kyles/sounds/454378/ |
| Door | Old.Wooden.Door.Open.and.Close | MorenaLuz | https://freesound.org/people/MorenaLuz/sounds/814857/ |
| Item pickup | Kalimba | PanPiper5 | https://freesound.org/people/PanPiper5/sounds/659909/ |
| Letter, songbook | Opening and closing a letter | Aurelon | https://freesound.org/people/Aurelon/sounds/698199/ |
| Seeds taken | Seed in Envelope Shake | REACTORFACTORY | https://freesound.org/people/REACTORFACTORY/sounds/531829/ |
| Small splash | Small_Splashes | N-RAZM | https://freesound.org/people/N-RAZM/sounds/390391/ |
| Large splash | jump-into-water-02 | yurkobb | https://freesound.org/people/yurkobb/sounds/280220/ |
| Wind gust (MEM-15) | wind 8 | ZIP.Creates | https://freesound.org/people/ZIP.Creates/sounds/726319/ |
| Root climbing | VEGEMisc Ext (bush rustle) | Joshua_van_Zyl | https://freesound.org/people/Joshua_van_Zyl/sounds/764900/ |
| Notebook page turn | Quiet Page Turn - 8 | SpaceJoe | https://freesound.org/people/SpaceJoe/sounds/484968/ |
| Notice slide-in | PaperSlide | eyesonlegs | https://freesound.org/people/eyesonlegs/sounds/464302/ |

## Game files

Written by `python -I tools/audio/cut_sfx.py tools/audio/sfx_sources/raw assets/audios/sfx` (ffmpeg, numpy, scipy), which prints this table. Every file is mono 16-bit 44.1 kHz WAV, 60 Hz high-passed, cut at the onset (lead under 1 ms; steps and landings at their impact, the first sample 14 dB under the peak read from 30 ms before their slice, with at least 4 ms faded in, SND-07), tail cut 45 dB under its loudest frame, capped and faded out. Each file is then gained to -24 LUFS at its loudest 400 ms (momentary, `tools/audio/loudness.py`); the files of one cue share one gain set by the one whose peak would first pass -1 dBFS, so a cue's variants play alike and its `volume_db` alone sets its level (`tools/audio/measure_levels.py`). Steps are capped at 0.35 s, world one-shots at 1.0 s, `songbook` at 0.5 s and `creature_death` at 0.6 s; `gust` is the 3 s exception (MEM-15). Earth, stone and snow steps are the six walk steps nearest the median RMS; wood has only three Mountain Boots steps, so 04-06 are pitched copies. A slice is in source seconds; "whole" is the file from its onset. `st` is semitones (resampled, so length changes).

| File | Source | Slice (s) | Processing | Length (s) | Peak (dBFS) | Loudest (LUFS) |
|---|---|---|---|---|---|---|
| `ivo/step_earth_01.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 4.290-4.740 |  | 0.350 | -4.6 | -24.3 |
| `ivo/step_earth_02.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 7.595-8.045 |  | 0.350 | -3.0 | -24.3 |
| `ivo/step_earth_03.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 8.580-9.030 |  | 0.350 | -5.2 | -24.3 |
| `ivo/step_earth_04.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 10.550-11.000 |  | 0.350 | -5.5 | -24.3 |
| `ivo/step_earth_05.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 12.500-12.950 |  | 0.350 | -3.9 | -24.3 |
| `ivo/step_earth_06.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 14.605-15.055 |  | 0.350 | -1.0 | -24.3 |
| `ivo/step_stone_01.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 7.465-7.915 |  | 0.289 | -1.0 | -26.9 |
| `ivo/step_stone_02.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 9.300-9.750 |  | 0.350 | -5.8 | -26.9 |
| `ivo/step_stone_03.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 10.290-10.740 |  | 0.350 | -2.8 | -26.9 |
| `ivo/step_stone_04.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 12.265-12.715 |  | 0.350 | -5.4 | -26.9 |
| `ivo/step_stone_05.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 16.070-16.520 |  | 0.350 | -1.3 | -26.9 |
| `ivo/step_stone_06.wav` | `558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav` | 18.045-18.495 |  | 0.350 | -2.3 | -26.9 |
| `ivo/step_snow_01.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 0.010-0.425 |  | 0.350 | -5.5 | -24.0 |
| `ivo/step_snow_02.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 1.025-1.475 |  | 0.350 | -7.6 | -24.0 |
| `ivo/step_snow_03.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 3.675-4.125 |  | 0.279 | -4.7 | -24.0 |
| `ivo/step_snow_04.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 4.515-4.965 |  | 0.350 | -8.4 | -24.0 |
| `ivo/step_snow_05.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 5.510-5.960 |  | 0.324 | -7.4 | -24.0 |
| `ivo/step_snow_06.wav` | `613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav` | 9.385-9.835 |  | 0.350 | -5.0 | -24.0 |
| `ivo/step_wood_01.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 21.190-21.600 |  | 0.350 | -1.2 | -24.2 |
| `ivo/step_wood_02.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 22.165-22.600 |  | 0.350 | -1.2 | -24.2 |
| `ivo/step_wood_03.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 23.095-23.500 |  | 0.350 | -2.7 | -24.2 |
| `ivo/step_wood_04.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 21.190-21.600 | -1.0 st | 0.350 | -1.3 | -24.2 |
| `ivo/step_wood_05.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 22.165-22.600 | +1.0 st | 0.339 | -1.0 | -24.2 |
| `ivo/step_wood_06.wav` | `543685__nox_sound__footsteps_wood_walk_mono.wav` | 23.095-23.500 | -0.5 st | 0.350 | -2.7 | -24.2 |
| `ivo/step_mud_01.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 0.000-0.410 |  | 0.350 | -2.6 | -25.8 |
| `ivo/step_mud_02.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 1.005-1.455 |  | 0.350 | -5.9 | -25.8 |
| `ivo/step_mud_03.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 2.105-2.555 |  | 0.350 | -7.5 | -25.8 |
| `ivo/step_mud_04.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 3.075-3.460 |  | 0.350 | -7.6 | -25.8 |
| `ivo/step_mud_05.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 4.235-4.685 |  | 0.350 | -1.0 | -25.8 |
| `ivo/step_water_01.wav` | `672202__romankolachnik__footsteps_01.wav` | whole |  | 0.350 | -5.9 | -24.0 |
| `ivo/step_water_02.wav` | `672200__romankolachnik__footsteps_03.wav` | whole |  | 0.350 | -3.9 | -24.0 |
| `ivo/step_water_03.wav` | `672199__romankolachnik__footsteps_04.wav` | whole |  | 0.350 | -6.2 | -24.0 |
| `ivo/step_water_04.wav` | `672205__romankolachnik__footsteps_05.wav` | whole |  | 0.350 | -7.8 | -24.0 |
| `ivo/step_water_05.wav` | `672204__romankolachnik__footsteps_06.wav` | whole |  | 0.350 | -7.9 | -24.0 |
| `ivo/step_water_06.wav` | `672203__romankolachnik__footsteps_07.wav` | whole |  | 0.350 | -6.3 | -24.0 |
| `ivo/land_earth_01.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 51.185-51.805 |  | 0.409 | -4.1 | -24.0 |
| `ivo/land_earth_02.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 52.440-53.060 |  | 0.500 | -9.5 | -24.0 |
| `ivo/land_earth_03.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 56.985-57.605 |  | 0.379 | -5.9 | -24.0 |
| `ivo/land_earth_04.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 58.035-58.655 |  | 0.444 | -5.6 | -24.0 |
| `ivo/land_mud_01.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 10.880-11.500 |  | 0.444 | -1.0 | -27.0 |
| `ivo/land_mud_02.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 12.120-12.740 |  | 0.369 | -8.1 | -27.0 |
| `ivo/land_mud_03.wav` | `548384__nox_sound__footsteps_mountain_boots_mud_mono.wav` | 13.100-13.720 |  | 0.389 | -2.1 | -27.0 |
| `ivo/land_hard.wav` | `556042__nox_sound__footsteps_mountain_boots_grass_mono.wav` | 51.185-51.800 | + dropLeather.ogg -3 st, -4 dB | 0.409 | -5.1 | -24.0 |
| `ivo/jump.wav` | `cloth3.ogg` | whole |  | 0.400 | -3.2 | -24.0 |
| `ivo/climb_grab.wav` | `764900__joshua_van_zyl__vegemisc-ext.wav` | 2.120-2.420 | low-pass 5 kHz | 0.299 | -11.1 | -24.0 |
| `ivo/climb_step_01.wav` | `764900__joshua_van_zyl__vegemisc-ext.wav` | 2.420-2.680 | low-pass 5 kHz | 0.259 | -8.6 | -24.0 |
| `ivo/climb_step_02.wav` | `764900__joshua_van_zyl__vegemisc-ext.wav` | 2.680-2.950 | low-pass 5 kHz | 0.244 | -9.1 | -24.0 |
| `ivo/swing_01.wav` | `485266__joao_janz__knife-swing-1_4.wav` | whole |  | 0.170 | -2.7 | -25.5 |
| `ivo/swing_02.wav` | `485265__joao_janz__knife-swing-1_5.wav` | whole |  | 0.150 | -1.0 | -25.5 |
| `ivo/swing_03.wav` | `485276__joao_janz__wooden-stick-swing-1_3.wav` | whole |  | 0.180 | -5.5 | -25.5 |
| `ivo/swing_04.wav` | `485278__joao_janz__wooden-stick-swing-1_5.wav` | whole |  | 0.160 | -3.2 | -25.5 |
| `ivo/hurt.wav` | `547209__mrfossy__voice_adultmale_paingrunts_09.wav` | whole |  | 0.264 | -7.7 | -24.0 |
| `ivo/hurt_low.wav` | `547209__mrfossy__voice_adultmale_paingrunts_09.wav` | whole | -3 st | 0.314 | -8.0 | -24.0 |
| `ivo/death.wav` | `235702__speedygonzo__bodyfall_wood-surface.wav` | 1.700-2.800 |  | 0.589 | -1.0 | -26.5 |
| `ivo/rest.wav` | `454378__kyles__wood-creak-low-sit-down-on-loose-park-bench-and-get-up.flac` | 0.700-1.750 |  | 1.000 | -6.5 | -24.0 |
| `combat/struck_01.wav` | `382642__bbrocer__bag-of-flour-dropped-on-counter-top.wav` | 0.235-0.600 |  | 0.250 | -2.9 | -24.0 |
| `combat/struck_02.wav` | `382642__bbrocer__bag-of-flour-dropped-on-counter-top.wav` | 1.770-2.100 |  | 0.250 | -6.8 | -24.0 |
| `combat/struck_03.wav` | `382642__bbrocer__bag-of-flour-dropped-on-counter-top.wav` | 3.490-3.900 |  | 0.250 | -3.7 | -24.0 |
| `combat/creature_death.wav` | `382642__bbrocer__bag-of-flour-dropped-on-counter-top.wav` | 5.290-6.200 |  | 0.414 | -4.0 | -24.0 |
| `combat/guardian_struck.wav` | `dropLeather.ogg` | whole | -3 st | 0.339 | -5.9 | -24.0 |
| `world/door_open.wav` | `814857__morenaluz__oldwoodendooropenand.wav` | 3.850-5.500 |  | 1.000 | -15.7 | -24.0 |
| `world/door_close.wav` | `814857__morenaluz__oldwoodendooropenand.wav` | 8.950-10.000 |  | 0.604 | -4.7 | -24.0 |
| `world/door_open_alt.wav` | `doorOpen_1.ogg` | whole |  | 0.878 | -5.9 | -24.0 |
| `world/door_close_alt.wav` | `doorClose_4.ogg` | whole |  | 0.494 | -5.7 | -24.0 |
| `world/door_knock.wav` | `bookPlace1.ogg` | whole | two raps 0.2 s apart, the second -2 dB | 0.404 | -5.6 | -24.0 |
| `world/pickup.wav` | `659909__panpiper5__kalimba.wav` | whole |  | 1.000 | -14.0 | -24.0 |
| `world/letter.wav` | `698199__aurelon__opening-and-closing-a-letter.mp3` | 1.650-2.750 |  | 1.000 | -4.6 | -24.0 |
| `world/songbook.wav` | `bookOpen.ogg` | whole |  | 0.145 | -1.0 | -27.0 |
| `world/seeds.wav` | `531829__reactorfactory__seed-in-envelope-shake.m4a` | 0.030-1.300 |  | 1.000 | -8.6 | -24.0 |
| `world/splash_small_01.wav` | `390391__n-razm__small_splashes.wav` | 2.500-3.300 |  | 0.768 | -4.9 | -24.0 |
| `world/splash_small_02.wav` | `390391__n-razm__small_splashes.wav` | 8.220-9.200 |  | 0.763 | -4.2 | -24.0 |
| `world/splash_small_03.wav` | `390391__n-razm__small_splashes.wav` | 15.470-16.400 |  | 0.848 | -6.0 | -24.0 |
| `world/splash_large.wav` | `280220__yurkobb__jump-into-water-02.flac` | 0.200-1.500 |  | 1.000 | -7.9 | -24.0 |
| `world/gust.wav` | `726319__zipcreates__wind-8.wav` | 4.000-7.000 | swell 1.6 s, decay 0.8 s | 2.998 | -12.9 | -24.0 |
| `menu/move.wav` | `click_001.ogg` | whole |  | 0.020 | -1.0 | -29.2 |
| `menu/confirm.wav` | `select_002.ogg` | whole |  | 0.040 | -1.0 | -26.0 |
| `menu/back.wav` | `back_002.ogg` | whole |  | 0.060 | -1.0 | -25.5 |
| `menu/open.wav` | `bookOpen.ogg` | whole |  | 0.145 | -1.0 | -27.0 |
| `menu/close.wav` | `bookClose.ogg` | whole |  | 0.195 | -1.2 | -24.0 |
| `menu/page.wav` | `484968__spacejoe__quiet-page-turn-8.wav` | whole |  | 0.384 | -1.0 | -26.5 |
| `menu/notice.wav` | `464302__eyesonlegs__paperslide.wav` | 0.050-1.600 |  | 1.000 | -13.3 | -24.0 |
