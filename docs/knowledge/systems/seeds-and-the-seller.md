---
id: systems/seeds-and-the-seller
type: system
title: "Season seeds and the seller: caches hold one seed each, seeds held are derived, the trade is a dialogue beat, a bought map draws faint"
status: active
tags: [life-04, seeds, cache, reward-slots, pickups, seller, shop, dialogue, beat, map, rumour, notices, notebook, title, staging, save, save-fact, i18n]
related: [architecture/season-seeds-and-the-seller, systems/found-pieces, systems/pickups, systems/map, systems/dialogue, systems/story, systems/notices, systems/notebook, systems/life-benches-death, systems/rooms, systems/props]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - resources/world/seeds/seed_offer.gd
  - resources/world/seeds/seed_stock.gd
  - resources/world/seeds/seed_stock.tres
  - resources/world/seeds/seed_purse.gd
  - resources/world/seeds/rumours.gd
  - resources/world/found/found_piece.gd
  - resources/save_facts/save_fact.gd
  - resources/save_facts/took_a_cache.tres
  - resources/save_facts/village_replanted.tres
  - globals/player_data.gd
  - globals/save_system.gd
  - scenes/world/interactables/up_reach/up_reach.gd
  - scenes/world/interactables/cache_pickup/cache_pickup.gd
  - scenes/world/interactables/cache_pickup/cache_pickup.tscn
  - scenes/world/interactables/reward_slot/reward_slot.gd
  - scenes/characters/components/pickup_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/story/seed_shop_beat.gd
  - scenes/world/story/seed_shop_beat.tscn
  - scenes/ui/seed_shop/seed_shop_panel.gd
  - scenes/ui/seed_shop/seed_shop_panel.tscn
  - resources/dialogue/village/seller.tres
  - scenes/ui/map/map_room_info.gd
  - scenes/ui/map/map_extras.gd
  - scenes/ui/map/map_canvas.gd
  - scenes/ui/map/map_screen.gd
  - scenes/ui/notice/notice_watcher.gd
  - scenes/ui/notice/notice_queue.gd
  - scenes/ui/notebook/notebook.gd
  - scenes/ui/title/slot_card.gd
  - tools/art/draw_seed_art.py
---

# Season seeds and the seller

**Never break:** Seeds held are derived (`SeedPurse.held` = caches taken minus prices paid), never stored. Caches taken, offers bought and rumours are live data: a bench commits them, a death forgets them together. A bought map or a rumour is drawn from purchases, never written to `map_seen`. The shop is a dialogue beat: no `WorldFreeze` writer, no input reader, no router screen. Nothing bought teaches a song or a skill, adds life or opens a way (`room_kit_test.test_no_way_is_gated_on_seeds`).

## Summary

LIFE-04, design 02 "Sementes de estação e o vendedor" ("Season seeds, the seller (Recommended)", user, 2026-10-28). The 12 CACHE reward slots each hold one season seed. Ivo takes it with Up; the village seller trades seeds for a regional map, a rumour of a found piece, or replanting the village's gardens. Plan and options: `architecture/season-seeds-and-the-seller`.

## User decisions (2026-10-28)

0. Who the seller is: "A woman, fix the text (Recommended)" (user, 2026-10-29): the approved portrait and sprite are a woman, so pt_BR says "Vendedora" and every doc says she; the option labels quoted below were written before this and keep their words.
1. The seller: "He stays to trade (Recommended)": only her apples line ends at 0.6; the stall and the seed trade remain all game.
2. Death: "Everything, purchases too (Recommended)": caches, seeds and purchases since the last bench rewind together.
3. Where the count shows: "Shop + notebook entry somewhere and load save screen (with the palying time)": the shop header, a notebook entry, and the save slot card beside the play time. The SEED toast on a gain stays as the find's feedback (orchestrator call; it shows no count).
4. The rest: "Accept all (Recommended)": prices map 1, rumour 1, replant 3; six regional maps, a repeatable rumour, one replanting; rumours in design 07 order, songbooks first; a bought map in the same ink at 0.35, no fill; four garden beds, one by the stall, procedural art; one husk sprite; the seller first mentions seeds once Ivo holds one; texts drafted for one approval round.

## Data (`resources/world/seeds/`)

- `SeedOffer`: `id`, `kind` (MAP, RUMOUR, REPLANT; append only), `price` (seeds, 1 or more), `region_key` (MAP: a `Region.name_key`; the row shows `tr()` of it).
- `SeedStock` (`seed_stock.tres`, `DEFAULT_PATH`): offers in shop order, `get_offer`, `rumour()`, `validate()` (unique ids, price >= 1, exactly one RUMOUR and one REPLANT, MAP offers with a unique region). Shipped: `map_threshold`, `map_frost_edge`, `map_spring_woods`, `map_frozen_lake`, `map_wind_orchards`, `map_summer_caldera` (1 each; no village map), `rumour` (1, repeatable), `replant_village` (3). 12 seeds against 6 + 3 + up to 17.
- `SeedPurse` (static, pure): `taken`, `spent` (offer prices plus rumour price per rumour, at today's prices), `held` (clamped at 0), `bought`, `on_sale` (MAP and REPLANT until bought, RUMOUR while `Rumours.next` is not null), `can_buy`, `bought_map_regions`.
- `Rumours` (static, pure): `next(found, data)` is the first piece in `found_catalog.tres` order that `FoundPickup.lies` and is not rumoured; `marked` is the rumoured pieces that still lie.
- `FoundPiece.room`: the room id whose `.room` holds the slot, so a rumour finds its region without loading contents (`room_files_test.test_every_found_piece_names_its_room`).

## Save

- `PlayerData.caches_taken`, `offers_bought` (MAP and REPLANT ids), `rumours` (slot ids): live arrays; an old save loads them empty; no `migrate` or `SaveLedger` change.
- `SaveSystem.has_cache`, `take_cache`, `buy_offer`, `add_rumour`: writers only, each emitting `progress_changed` once per change. Affordability is the shop's check through `SeedPurse`.
- `SaveFact.Kind.CACHES_TAKEN_AT_LEAST` (12; `index` the count) and `OFFER_BOUGHT` (13; `id` the offer). Facts: `took_a_cache.tres` (1 cache), `village_replanted.tres`. `ReachKit` packs neither.

## The cache (`CachePickup`)

- `RewardSlot._fill()` adds a `CachePickup` with the slot id to every CACHE slot; no catalog, every cache holds one seed. A filled slot draws no debug marker.
- An Area2D like the other pickups: `Seat.LAYER`, a 2x2-cell reach, the husk (`assets/sprites/world/pickups/seed.png`, 14x18) standing on the floor line. `lies(slot_id, data)` is `not caches_taken.has(slot_id)`, read on ready and on `progress_changed`. `take()` calls `SaveSystem.take_cache` and emits `taken`.
- **`UpReach`** (`scenes/world/interactables/up_reach/`): the shared reach every pickup composes (`ItemPickup`, `FoundPickup`, `CachePickup`). `setup(cells, art_top, art_x)` sizes the root's shape and stands the `look_up` prompt over the higher of the reach and the art; `refresh(shown)` shows the prompt only while Ivo is in reach, not in a story and `Player.reaches` the root; `player()` is Ivo in reach. `Talkable` keeps its own reach.
- Ivo: `PickupComponent.reachable_cache()`; `Player._try_cache` runs after `_try_found` and before `_try_board`, the letter path (one `UP_BUFFER`, `_free_for_up`, refused in a story, a refused press is spent).

## The seller and the trade

- `seller.tres` (priority order): `seller_seeds_first` (once, when `took_a_cache`: two lines, the cue-only line `seller_shop`, a closing line); `seller_trade` (when `took_a_cache`: a line, the cue, a closing line); `seller_apples` (unless 0.6, unchanged). Before his first seed Ivo hears only the apples line; at 0.6 without a seed she has no line.
- She stays all game: the lane-west Talkable has no `presence`, and `inhabitants/seller.tscn` and `props/village/market_stall_apples.tscn` have no `RegionPresence` (`village_voices_test.test_the_seller_stays_to_trade_all_game`).
- **`SeedShopBeat`** (`scenes/world/story/seed_shop_beat.tscn`, cue `seller_shop`, hold STILL) under `Beats/SeedShop` in `village_lane_west_contents.tscn`. `start()` opens the panel with `SeedPurse.on_sale` and `held`. On `chosen` it re-checks `can_buy`: MAP and REPLANT call `buy_offer`, RUMOUR calls `add_rumour(Rumours.next(...).slot_id)` and names the region of the piece's room (read from the `Room` group) in the said line; then it refreshes the panel. On `left` it closes the panel and calls `finish()`; the talk resumes on its closing line. `stock` and `found` are plain vars holding preloads, so tests swap them.
- **`SeedShopPanel`** (`scenes/ui/seed_shop/`, under the beat's `Layer` CanvasLayer at layer 2, over the world's layer 1 (its greyhush pass and composites would shade a layer-1 panel) and under `ScreenLayer` at 3; INHERIT; `bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite`): a view that never reads the save. A 320x180 `Art` at scale 2 with `menu_theme.tres`; the wood box (`bg_box_wood.png`, the dialogue box's) at 64..256 x 6..176; a header (seed icon, `SHOP_SEEDS_HELD`); one `InkButton` row per offer (text left, price and an 8x8 seed icon right; a row the player cannot afford is disabled with `focus_mode` NONE); Leave last; a said line under the rows. Focus links wrap at both ends and skip disabled rows; the first focusable row takes focus on open; `close()` releases focus; `NOTIFICATION_UNPAUSED` takes it back. Buttons and GUI focus are the only input, as in the dialogue box.

## The map

- `MapRoomInfo` (room id, scene key, region key, bounds, interior) is built by `MapScreen` from the `Room` group; a room outside a Region has an empty region key.
- `MapExtras` (pure): `known_rooms(infos, regions)` (surface rooms of bought regions), `rumour_points(infos, pieces)` (per piece, the centre of its region's surface rooms moved into the nearest of them, a cell from its edges), `steps(points)` (marks sharing a place spread by `MapCanvas.MARK_STEP`, 7 pack px).
- `MapCanvas.build(patches, known, marks, mark_steps)`: known rooms are full-grid patches drawn first as ink at 0.35 (`FAINT_INK`, no fill), then the seen patches, then the marks (5x5 pack px ink diamonds). `seen_rect()` merges all three, so the centre clamp reaches a bought region or a mark. Known patches are cached per room key and bounds.

## Where the count shows

- The shop header (`SHOP_SEEDS_HELD`).
- The notebook's LORE entry `lore_seeds` (requirement `CACHES_TAKEN_AT_LEAST` index 1): `NotebookEntry.detail_counts_seeds` makes `Notebook` format `tr(detail_key) % SeedPurse.held(...)` (`NOTEBOOK_LORE_SEEDS_HELD`).
- The title's save slot card: the count and an 8x8 seed icon on the bench row, right of the bench name, under the play time (`SlotCard`, `SeedPurse.held` of the slot's save; numbers only, no new key).
- No HUD counter. `Notice.Kind.SEED` (appended): `NoticeWatcher` diffs `caches_taken.size()` (seeded silently at `_ready`) and queues one SEED notice per seed gained, text `NOTICE_SEED`, icon `seed_icon` (`item_icon_seed.png`); a fall in the count (a rewind) drops the seed notices waiting. Same queue, hold and toast as items.

## Replanting

`Gardens` (`FactStaging`) under `Props` in the four street rooms (lane west x 290, in view of the stall; square x 380; mill x 700; gate east x 1000; floor y 288): `[{when: village_replanted, show: Replanted, fade_seconds: 1.5}, {show: Bare}]`. Children hold `props/village/garden_bed_planted.tscn` (3 season bands, `prop_seasonal_material.tres`) and `garden_bed_bare.tscn` (one band). No ambient motion.

## Art

`tools/art/draw_seed_art.py` (procedural, PIL; contracts `tools/art/prompts/pickup_seed.md`, `item_icon_seed.md`, `village_garden_bed_bare.md`, `village_garden_bed_planted.md`): the husk upright with a dark side against a lit side so it reads in the grey; the icon (16x16); the beds (24 art px wide at 2x; the planted bed's autumn and winter bands from `season_bands.py`). Credited in `CREDITS.md`.

## Debug and playtests

Timelines take `"caches"`, `"bought"` and `"rumours"` (strings), after `"found"` (`tools/playtest/README.md`). The runner's notice log prints `seed` for a SEED notice.

## Known limits

- A price edit after release moves old saves' balances (clamped at 0).
- The `$` legend text in `room_legend.tres` still calls CACHE "undecided" (the file had someone else's uncommitted change); update it and regenerate `docs/maps/README.md` once it is free.
- Not playtested yet: the husk's readability in the grey, the panel's layout at 2x and the said lines' wording.

## Tests

- `seed_purse_test`, `rumours_test`, `seed_stock_test`; `save_fact_test` (`test_caches_taken_at_least`, `test_offer_bought`); `save_system_seeds_test`; `player_data_test` (round trip, old save).
- `cache_pickup_test`, `reward_slot_test.test_a_cache_holds_one_seed`, `player_cache_test`; `player_pickup_test`, `found_pickup_test`, `player_found_test` unchanged on `UpReach`.
- `room_files_test.test_every_found_piece_names_its_room`, `room_kit_test.test_no_way_is_gated_on_seeds`.
- `map_extras_test`; `map_screen_test` (a bought region draws faint, `map_seen` unchanged, the clamp reaches it; a mark shows while its piece lies).
- `notice_queue_test`, `notice_watcher_test` (one SEED notice with its icon, a rebuilt world tells nothing, it waits for a talk), `notice_text_fit_test` (NOTICE_SEED).
- `seed_shop_beat_test`, `seed_shop_panel_test`, `seed_shop_text_fit_test`; `story_beats_test` (the new cue has one beat).
- `notebook_seeds_test`, `notebook_text_fit_test` (two-digit count); `slot_screen_test.test_a_used_slot_shows_the_seeds_held_beside_the_play_time`.
- `village_voices_test.test_the_seller_stays_to_trade_all_game`; `dialogue_text_fit_test` covers the seller's lines.
