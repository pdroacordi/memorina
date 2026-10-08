---
id: glossary
type: system
title: Glossary: design term to code identifier, and retired terms
status: active
tags: [glossary, i18n, naming]
related: []
created: 2026-10-02
updated: 2026-10-06
source_files: []
---

# Glossary

The design docs are written in Portuguese; code identifiers are English. Extend this table whenever a design concept gets implemented.

| Design doc (pt) | Code |
|---|---|
| cinzesquecimento / the Greyhush | `greyhush` |
| campo de memória | `MemoryField` |
| pulso de cor | `ColorPulse` |
| sacar / guardar (o instrumento) | `draw` / `sheathe` |
| Congelar | `Enums.Song.FREEZE` |
| Redoma | `Enums.Song.BELL_JAR` |
| Sombra | `Enums.Song.SHADOW` |
| Solstício | `Enums.Song.SOLSTICE` |
| Soltar | `Enums.Song.RELEASE` |
| Vendaval | `Enums.Song.GALE` |
| Enraizar | `Enums.Song.ROOT` |
| Chuva | `Enums.Song.RAIN` |
| o que a canção faz por si (campo, casca, sombra) | `Song.pulse_effect` (`PulseEffect`) |
| atalho permanente da primeira resolução | `SaveSystem.resolve_shortcut` |
| terra / pedra (material do chão) | `Enums.Ground.EARTH` / `STONE`, `RoomMapNode.ground_at()` |
| mapa de sala em texto | `.room`, `RoomMap`, `RoomMapNode`, `room_legend.tres` |
| Inverno / Verão / Outono / Primavera | `Enums.Season.WINTER` / `SUMMER` / `AUTUMN` / `SPRING` |
| estação nativa (de uma região) | `Region.season` / `MemoryField.season` |
| título da canção (Hino do Gelo…) | `Song.title_key` (`SONG_TITLE_*`) |
| resposta do instrumento / trecho | `SongPerformance`, `Song.excerpt` |
| congelar o mundo (durante a resposta) | `WorldFreeze` |
| guardião / fase de pressão / janela de lucidez | `Guardian` / `GuardianFight.Phase.PRESSURE` / `GuardianFight.Phase.LUCIDITY` |
| chamado (call-and-response) / resposta | `GuardianCall`, `MemorinaComponent.call_song` / `call_answered` |
| QTE de emergência / habilidade recuperada | `AbilityRecallComponent`, `AbilityRecallStats` / `SaveSystem.unlock_skill` |
| restaurar o guardião | `SaveSystem.restore_guardian`, `Region.current_baseline()` |
| tempo desacelera | `WorldFreeze.slow()` |
| recaída (o guardião volta à loucura) | `GuardianFight.Phase.RELAPSE` |
| poço de esquecimento (numa região) | `RegionMemory` + `MemorySource` negativo |
| memória da região | `Region.current_baseline()` / `RegionMemory.current()` |
| arena (onde a luta acontece) | `Arena` (`scenes/world/rooms/arena.gd`) |
| clima regional (escala com a memória) | `RegionWeather`, `MemoryField.palette`, `region_tint` |
| cor nasce ao redor da cabeça (QTE) | `RecallAura` |
| água gerada | `WaterBody` (`WaterProfile`, `WaterLook`) |
| ondulações / crista | `WaterSurfaceField` (a splash is displacement) |
| eixo do reflexo | `WaterBody.mirror_axis_offset` |
| submerso (corpo na água) | `WaterVeil` |
| lago em primeiro plano (água na frente do chão) | `water_lake.tscn`, `water_lake.gdshader` |
| poça / água entre terras (corte lateral) | `water_pool.tscn`, `water_surface.gdshader` |
| pintar água (autoria) | `WaterLayer`, `WaterBasins` |
| perigo (cair na água) | `HazardZone`, `Hurtbox.receive_hazard` |
| último chão firme (retorno) | `SafeGroundTracker`, `Player.respawn()` |
| frente de gelo / endurecer antes de parecer sólido | `IceFront` / `IceProfile.harden_at` < `solid_at` |
| degelo pela origem / pelas bordas | `IceProfile.ThawOrigin.FROM_ORIGIN` / `FROM_EDGES` |
| correnteza | not built (`WaterVolume.disturbances()` is the hook) |
| o mesmo canal físico (vento, correnteza, Vendaval) | `Airflow`, `AirflowSource`, `AirflowBody`, `Character.carry()` |
| corrente de vento natural / rajada / calmaria | `WindZone`, `WindProfile` |
| Vendaval (rajada para onde o herói olha, o olho parado) | `GaleField`, `GaleWind`, `GaleShape` |
| rajadas / respingos (sprites curtos de uma canção) | `SpriteBursts`, `SpriteStrip` |
| abrigo (do vento) | `AirflowShelter`, `Player.memorina_shelter` |
| peso / placa de pressão / porta / elevador | `Weight`, `WeightSensor`, `PressurePlate`, `Mechanism` (`trigger_path`) |
| gangorra | `Seesaw` (`length`, `pivot_at`), `SeesawBalance` |
| contrapeso errado trava o elevador | `Mechanism.lock_path` |
| Sombra (a sombra queimada) | `CastShadow`, `Character.silhouette()`, `burned_shadow.gdshader` |
| vista pelas criaturas como o herói | `EnemySight.PRESENCE`, `EnemySight.visible_presence()` |
| Soltar / o cinza guarda o estado antigo | `Releasable`, `ReleaseState` (`hold` / `let_go`) |
| casulo pendurado / cortina de folhas / ponte levadiça | `HangingLoad`, `LeafCover`, `Drawbridge` |
| a canção tocada não corre durante outra resposta | `PulseEmitter.holds_in_pause` |
| Chuva / bacia seca que enche | `RainFall`, `RainBasin` (room map `r`), `WaterBody.set_level` |
| nível da água (autoral) | `WaterBody.level_range()` (the painted reach, `r`) and `WaterBody.rest_level()` (the painted water under it) |
| o que boia (tronco caído) | `Floater` (room map `O`) |
| Enraizar / raízes ligam terra a terra | `RootGrower`, `RootSpanFinder` (BRIDGE / SHAFT / PILLAR), `RootStrands`, `RootSpanView` |
| ponte de raízes / poço de terra / pilar | `RootSpanFinder.Kind.BRIDGE` / `SHAFT` / `PILLAR` |
| escalar (as raízes) | `ClimbComponent`, `Climbable` (grip WALL / POLE), `Player.MotionState.CLIMB` |
| terra molhada (Chuva → Enraizar) | `RootGrower.wet_bridge_cells`, a RAIN pulse at both faces |
| Redoma / casca de geada / nada entra, tudo pode sair | `FrostShell` (physics layer 4 "Shell"), collision exceptions until clear |
| abrigo da Redoma | `DiscShelter` |
| a água fica de fora | `WaterBody.hold_out` / `release` / `is_held_out` |
| Solstício / o dia mais longo | `SolsticeAura`, `ColorPulse.stretch`, `PulseTimeline.stretch` |
| o corredor longo | `trials_solstice`, `solstice_trial_test.gd` |
| banco / ponto de restauração / sentar | `Bench` (room map `R`), `Seat`, `SitComponent`, `SaveSystem.rest_at` |
| a morte volta ao último banco | `SaveLedger` (`commit` / `rewind` / `record_death`), `Game._reload_world` |
| marca de morte (símbolo do cinzesquecimento) | `PlayerData.deaths`, `DeathMarkClusters`, `RegionMemory.mark_deaths` / `erase_marks` |
| vida (notas que perdem a cor) | `LifeHud`, `LifeNote`, `Player.health_changed` |
| pausa / menu de pausa | `PauseMenu`, `Screens`, `ScreenRouter.Kind.PAUSE` (`systems/screens`) |
| mapa (tecla M / LB) | `MapScreen`, `MapCanvas`, `ScreenRouter.Kind.MAP` (`systems/map`) |
| caderno de campo (tecla E / Select) | `Notebook`, `ScreenRouter.Kind.NOTEBOOK` (`systems/notebook`) |
| seções: Lore (diário do personagem) / Canções / Itens / Guardiões | `NotebookEntry.Section.LORE` (titled Memórias / Memories) / `SONGS` / `ITEMS` / `GUARDIANS` |
| registro do caderno (entrada) | `NotebookEntry`, `NotebookCatalog`, `NotebookIndex.present()` |
| guardião conhecido / estado de corrupção | `PlayerData.met_guardians` (`SaveSystem.meet_guardian`) / `restored_guardians` |
| entrada não lida / lida | `NotebookIndex.unread()` / `PlayerData.notebook_read` (`SaveSystem.mark_notebook_read`) |
| aviso de entrada nova (a pena no HUD) | `NotebookWatcher.announced` → `NotebookToast` |
| parte da sala vista (célula do mapa) | `MapGrid` (64 px cells), `PlayerData.map_seen`, revealed by `MapRevealer` |
| contorno do mapa (área vista, contornada) | `MapOutline` (`fill_runs`, `edges`, `notches`, `ink`) |
| Ivo bloqueado (mapa aberto, o mundo segue) | `Screens.BLOCKING`, `Player.block_input` / `unblock_input`, `PlayerInput.blocked` |
| parar tudo atrás do menu (menu hold) | `WorldFreeze.hold()` / `release()` / `is_held()` (scale 0); a performance uses `freeze()` / `thaw()` (scale 1) |

| espaço de salvamento (slot) | `SaveSlots` (`save_N.tres` / `save_debug_N.tres`), `SaveSystem.begin_slot`, `read_slots` |
| abertura do jogo (escolhe título ou jogo) | `Boot` (`scenes/boot/boot.tscn`), `BootPolicy` |
| tela de título | `Title` (`scenes/ui/title/`) |
| tela dos espaços de salvamento | `SlotScreen` (`Purpose.LOAD` / `Purpose.NEW`), `SlotCard` |
| escurecer ao voltar ao título | `Screens` `Blackout` (a real-time `Fade`) |
| tempo de jogo | `PlayerData.play_time` (wall-clock seconds, menus included) |
| último jogo salvo / o mais antigo | `PlayerData.saved_at`, `SaveSlots.latest` / `SaveSlots.oldest` |
| Novo jogo / Continuar / Sair do jogo | `TITLE_NEW_GAME` / `TITLE_CONTINUE` / `TITLE_QUIT_GAME` |
| Apagar / Substituir / Vazio | `TITLE_ERASE` + `CONFIRM_ERASE` / `CONFIRM_OVERWRITE` / `TITLE_EMPTY_SLOT` |
| Voltar ao título | `PAUSE_QUIT_TO_TITLE`, `CONFIRM_QUIT_TO_TITLE`, `Game.quit_to_title` |
| nome da região / do banco (no título) | `Region.name_key` (`REGION_*`), `SaveSlots.bench_name_key` (`BENCH_` + bench id in capitals) |
| teletransportar (banco, retorno) | `Character.teleport` |

## Terms no longer used

When a code identifier or design term is renamed or retired, add it here instead of just
deleting the old row above — a stale name showing up in an old comment, commit message, or
someone's memory of the project is exactly what causes an accidental regression back to it.

| Retired term | What replaced it |
|---|---|
| "Lembre-se!" / `RECALL_PROMPT` (the recall banner) | retired 2026-09-21: the recall shows instead of telling (`RecallAura`, `RecallPrompt` key only) |
| `GUARDIAN_CALL_ANSWER` ("Answer on the Memorina") | retired 2026-09-21: the answer moved to Ivo's own sheet with the key blinking; no prose |
| "one sheet at the top for the whole call" (round 4 rule) | replaced 2026-09-21 by LISTEN on the guardian's sheet, ANSWER on Ivo's |
| "LISTEN on the guardian's sheet, ANSWER on Ivo's, each placed beside its owner" | replaced 2026-09-22: the turn still passes, but both sheets take ONE centred slot - the hopping frame was the clutter |
| `AbilityRecallStats.requires_airborne` | retired 2026-09-22: a recall asked for on the ground is a CHAIN (`grounded_steps`, `airborne_finish`) instead of a moment that never comes |
| `Guardian`'s `Corruption` node / `corruption_lift_time` | retired 2026-09-22: the well of forgetting is the REGION's (`RegionMemory`), authored in the region scene so it outlives a room |
| `downtown_contents.tscn`'s ad-hoc `GreyhushPatch` | retired 2026-09-22: became `HomeVillage/Memory/DowntownWell`, so it lifts with the region instead of outliving its restoration |
| `Region.memory_baseline` | moved 2026-09-22 to `RegionMemory.authored` |
| `FreezableWater`'s ColorRect surface bobbing on a `MemoryClock`, frozen exactly while a FREEZE pulse overlapped | replaced 2026-09-22 by `WaterBody` + `IceFront` (grows from the origin, thaws on its own clock) |
| `water_strip.tscn` / `reflection_strip_look.tres` / `strip_profile.tres` (a pool's cross-section drawn in front of the ground) | replaced 2026-09-23 by the lake (`water_lake.tscn`, `lake_look.tres`, no profile) |
| a `WaterBody` scene placed by hand with a typed `size` | replaced 2026-09-23 by painting a `WaterLayer`; the scenes are still what a layer instances |
| `Player.call_window_opened(seconds)` | retired 2026-09-22: the length was only ever feeding a second clock; `call_window_progress(fraction)` reports the fight's own |
| hand-painted room ground (`TileMapLayer` with inline `TileSet` per contents scene), painted `WaterLayer`s and hand-placed enemies in contents scenes | replaced 2026-09-23 by `.room` text maps built by `RoomMapNode` from the one `floor_tileset.tres` (`docs/maps/README.md`) |
| `RadialWind` / `GaleShape.VERTICAL_SHARE` (Vendaval blowing outward from the origin) | replaced 2026-09-30 by `GaleWind`: the gale blows one way, the way Ivo faces (the user's decision) |
| Redoma holding water out column by column (depth 0 per dry column, hazard runs of wet columns) | replaced 2026-09-30 by per-pixel `held_discs` and curved hazard outlines; lakes are never held out |
| `SaveSystem.new_game()` / `save_game()` / `load_game()`; "an unsaved death rewinds" with nothing to rewind to; design 02's "sem perder progresso material" | retired 2026-10-01: `SaveSystem.begin()`, `rest_at()`, `record_death()` over a `SaveLedger`; death rewinds to the last bench (the user's decision) |
| the first song matrix: `BLIZZARD` (Ventania/Nevasca), `CONCENTRATED_SUN` (Sol Concentrado), `SUDDEN_STORM` (Tempestade Repentina), `WEAKEN` (Fragilizar), `STRIP` (Despir), `SPROUT` (Brotar), `HATCH` (Eclodir), and the unslotted Hibernação | replaced 2026-09-23 by the second matrix, each renamed IN ITS SLOT so the save indices hold: `BELL_JAR`, `SHADOW`, `SOLSTICE`, `RELEASE`, `GALE`, `ROOT`, `RAIN` (design 02 §7.1). The soundtrack files were renamed after the new titles; their music predates the new songs |
| `PauseInput` / `PauseMenu.opened` → `WorldFreeze.freeze` (the first pause-menu plan, never built) | replaced 2026-10-02 by one `MenuInput`, the `ScreenRouter` and `Screens.hold_requested` → `WorldFreeze.hold` |
| `MemorinaVoice.note_finished` starting the performance | removed 2026-10-02: a performance starts from `Player._tick_pending_performance` on the pausable clock |
| `user://save.tres` / `save_debug.tres` (one save) | replaced 2026-10-06 by three slots; `SaveSlots.adopt_legacy` moves the old file into slot 1 once |
