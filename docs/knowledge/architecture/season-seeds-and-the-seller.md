---
id: architecture/season-seeds-and-the-seller
type: architecture
title: Season seeds and the seller (LIFE-04) - caches fill with a CachePickup, seeds held are derived (caches taken minus prices bought), the trade is a dialogue beat with its own panel, a bought map draws faint beside map_seen and never writes it
status: built
tags: [life-04, seeds, cache, reward-slots, pickups, seller, shop, dialogue, beat, map, rumour, notices, staging, save, save-fact, i18n, plan]
related: [architecture/found-pieces, architecture/reward-slots-reserve-their-place-in-the-room-text, architecture/dialogue-is-data-and-choices-are-save-facts, architecture/the-opening-is-staged-by-save-facts, architecture/map-reveal-seen-cells-per-room, architecture/notebook-entries-are-derived-from-the-save, architecture/the-life-loop-rewinds-by-reloading, systems/map, systems/found-pieces, systems/pickups, systems/dialogue, systems/story, systems/notices, systems/life-benches-death, systems/screens, systems/rooms, systems/world, gotchas/a-control-is-culled-by-its-own-rect, gotchas/a-killed-tween-never-emits-finished, gotchas/a-static-func-returning-its-own-enum-fails-once-another-script-types-it, gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/world/interactables/reward_slot/reward_slot.gd
  - scenes/world/interactables/found_pickup/found_pickup.gd
  - scenes/world/interactables/item_pickup/item_pickup.gd
  - scenes/characters/components/pickup_component.gd
  - scenes/characters/ivo/player.gd
  - resources/save_facts/save_fact.gd
  - globals/player_data.gd
  - globals/save_system.gd
  - resources/dialogue/village/seller.tres
  - scenes/world/rooms/home_village/contents/village_lane_west.room
  - scenes/ui/map/map_screen.gd
  - scenes/ui/map/map_canvas.gd
  - scenes/ui/notice/notice_queue.gd
  - scenes/ui/notice/notice_watcher.gd
  - resources/world/found/found_piece.gd
---

# Season seeds and the seller (LIFE-04)

**Status: built** (2026-10-28; contract: `systems/seeds-and-the-seller`). Design: `docs/design/02_mecanicas.md`, "Sementes de estação e o vendedor" ("Season seeds, the seller (Recommended)", user, 2026-10-28). Roadmap LIFE-04 (needs STORY-06, built).

## Context

- The 12 CACHE reward slots (`$`, `RewardSlot.Kind.CACHE`) are placed and reached by some kit (`room_kit_test`). Regions: frost_edge 2 (`lighthouse_base_lookout`, `frost_cliffs_niche`), threshold 1, frozen_lake 1, spring_woods 4, wind_orchards 3, summer_caldera 1.
- STORY-06 set the pattern: `RewardSlot._fill()` adds a pickup child at `_ready`, presence derived from the save, Up through `Player`'s chain (`architecture/found-pieces`). Its ADR deferred one choice: "extract on a third pickup". The cache is the third.
- Design rules: seeds come only from caches, never from enemies. Unspent seeds are lost on death "like everything else". Nothing bought teaches a song or a skill or adds life. The seller sells three things: regional maps, rumours and replanting the village (visual only).
- **Open tension 1 (map).** Design 02 UI and the user's UI-04 reveal ("only the parts of the room the player saw on screen") say the map is drawn by exploring. `systems/map`: only cells whose centre was on screen are seen. The design proposes a fainter line for a bought map.
- **Open tension 2 (the seller leaves).** Design 05's village voices (approved) and `systems/story` say the seller "leaves at 0.6" with her stall: Talkable `presence` 0.7 in `village_lane_west.room` and `RegionPresence` 0.7 on `inhabitants/seller.tscn`. The village reaches 0.6 at the second restored guardian. Most caches need abilities that guardians teach, so most seeds come after he has gone. Only the user can settle this (question 1).
- `resources/dialogue/village/seller.tres` holds `seller_apples` (unless 0.6). It has uncommitted changes by someone else, and `room_legend.tres` does too.

## Options considered

**Seeds held: a stored count or derived.**
- `PlayerData.seeds: int`, incremented on a take and decremented on a buy. Rejected: the cache's world presence must still be derived from which caches were taken, so the count would be a second record that can drift from it, and from the purchases.
- **Chosen: derived.** `held = caches_taken.size() - sum(price of each offer bought) - rumour price * rumours.size()`, computed by one pure `SeedPurse`. Cost: a price edit after release changes an old save's balance. The display clamps at 0, and `SeedStock.validate` keeps prices at 1 or more.

**What a death rewinds.**
- Purchases survive a death (like `notebook_read`), caches rewind. Rejected: a cache taken after the bench comes back while the seed it paid for stays spent, so the balance goes negative. Making it hold would mean caches survive too, which breaks "lost on death".
- **Chosen: all three arrays are live data.** A bench commits them and a death forgets them. Nothing changes in `SaveLedger`, and the state after a death is exactly the bench's: caches taken since are back in the world, purchases since are unbought. This reads design 02's "como todo o resto" literally (question 2).

**The cache pickup.**
- A third copy of the reach, prompt and body-tracking lines (`ItemPickup`, `FoundPickup`). Rejected: the STORY-06 ADR set the third pickup as the time to extract.
- One generic slot pickup with a reward strategy Resource (`FoundPiece` and a seed cache behind one interface). Rejected: it rewrites `FoundPickup` and its suites one day after they shipped, and a songbook's lesson path is specific to books anyway.
- A `Pickup` base class. Rejected: inheritance on a non-engine base (CLAUDE.md, and as already rejected in `architecture/found-pieces`).
- **Chosen:** a new `CachePickup` Area2D beside the other two. The shared lines move into an `UpReach` component node that all three pickups compose. `Talkable` keeps its own reach, which is centred on the speaker, asymmetric and auto-starts.

**How the trade is offered.**
- Dialogue choices with grants. Rejected: a question takes at most 3 choices and the stock is up to 8 rows plus Leave. `grants` only sets an ITEM. Paying would need a new kind of write in the director, and "can afford" is a count, not a fact.
- A router screen (`ScreenRouter.Kind.SHOP`). Rejected: `systems/dialogue` forbids a talk from adding a router screen, and the router opens screens only on presses.
- **Chosen: a dialogue beat that owns its panel.** The seller's talk reaches a cue-only line (`seller_shop`). `SeedShopBeat` (a `DialogueBeat`, hold STILL, like `StagedBeat` and `GuitarBeat`) opens its own `SeedShopPanel` under a CanvasLayer inside the beat's scene. Buttons and GUI focus do the input, as in the dialogue box. Leave finishes the beat, and the talk resumes on its closing line. So it adds no `WorldFreeze` writer, no input reader and no router screen. The talk's block, the map refusal, the notice hold and the pause opening over it all come for free.
- The panel inside the beat, chosen over a panel in `game.tscn` reached through new director relays (the `PhraseSheet` precedent). Relays would put shop signals on the generic `DialogueDirector` (SRP).

**A bought map.**
- Write the region's cells into `map_seen`. Rejected: it breaks the never-break rule ("only cells whose centre was on screen are seen"). The cells could not be told apart from explored ones, which would undo the user's UI-04 reveal.
- Draw the rooms' real shape from their `.room` files. Rejected: contents load lazily, and a "contorno das salas" is the room's rectangle.
- **Chosen:** a derived layer. `MapScreen` draws each surface room of a bought region as one full-grid `MapCanvas.Patch` with `faint = true`: the same `MapOutline` ink geometry at a lower alpha and no fill, under the explored patches. `map_seen`, `MapRevealer` and `MapGrid` are untouched.

**A rumour's target.**
- The player picks a region. Rejected: it needs a second menu level, and the design says a rumour marks "a região de uma carta ou de um caderno". It points at a piece, not at a region the player chooses.
- The piece nearest the seller, or in the least explored region. Rejected: not data, and hard to test.
- **Chosen:** the first piece in `found_catalog.tres` order (design 07's order: the four songbooks, then threads A-D) that still lies and is not already rumoured. The purchase records that slot id. The mark shows while the piece still lies (`FoundPickup.lies`), so it is derived and goes once the piece is taken.

**Replanting.**
- Several purchases (one per street). Rejected for now: more offers and more stagings for one visual reward (question 9).
- **Chosen:** one purchase, `replant_village`. A `Gardens` `FactStaging` in each village street room shows `Replanted` on a new fact (OFFER_BOUGHT `replant_village`), else `Bare`.

## Decision

### Data (`resources/world/seeds/`)

- `SeedOffer` (Resource): `id: StringName`, `kind: Kind { MAP, RUMOUR, REPLANT }` (append only), `price: int` (seeds), `region_key: String` (MAP only: a `Region.name_key`, e.g. `REGION_FROZEN_LAKE`; the region's name in the row is `tr(region_key)`, so there is one row key per kind).
- `SeedStock` (Resource): `offers: Array[SeedOffer]` in shop order, `const DEFAULT_PATH`, `get_offer(id)`, `rumour() -> SeedOffer`, `validate() -> PackedStringArray`: unique non-empty ids, price >= 1, exactly one RUMOUR and one REPLANT, MAP offers with a non-empty and unique `region_key`.
- `seed_stock.tres`: `map_threshold`, `map_frost_edge`, `map_spring_woods`, `map_frozen_lake`, `map_wind_orchards`, `map_summer_caldera` (no village map: the village is seen at once and its interiors are not drawn), `rumour`, `replant_village`. Default prices: map 1, rumour 1, replant 3 (question 3). There are 12 seeds against 6 + 3 + up to 17, so choices matter.
- `SeedPurse` (RefCounted, static, pure), in `seed_purse.gd`:
  - `taken(data) -> int`;
  - `spent(data, stock) -> int`;
  - `held(data, stock) -> int`, clamped at 0;
  - `bought(offer, data) -> bool`;
  - `on_sale(stock, found, data) -> Array[SeedOffer]`: MAP and REPLANT while not bought, RUMOUR while `Rumours.next` is not null;
  - `can_buy(offer, stock, found, data) -> bool`: on sale and `held >= price`;
  - `bought_map_regions(stock, data) -> PackedStringArray`.
- `Rumours` (RefCounted, static, pure), in `rumours.gd`: `next(found, data) -> FoundPiece` and `marked(found, data) -> Array[FoundPiece]` (rumoured and still `FoundPickup.lies`).
- `FoundPiece.room: StringName` (new): the room id whose `.room` holds the slot (`village_bell_tower`, `frost_wreck_hold`...), set for all 17 pieces. A rumour needs the region of a slot that may sit in unloaded contents. `room_files_test` pins it against the maps.

### Save

- `PlayerData` gains three live arrays, with no `migrate` change (an old save loads them empty) and no `SaveLedger` change:
  - `caches_taken: Array[StringName]` (slot ids);
  - `offers_bought: Array[StringName]` (MAP and REPLANT offer ids);
  - `rumours: Array[StringName]` (slot ids of the pieces rumoured).
- `SaveSystem`: `has_cache(slot_id)`, `take_cache(slot_id)`, `buy_offer(offer_id)`, `add_rumour(slot_id)`. Each asserts a non-empty id and emits `progress_changed` only on a change, like `mark_found`. They are writers only. Affordability is the shop's check through `SeedPurse`, so `SaveSystem` never reads a catalog.
- `SaveFact.Kind` appends two kinds (12 and 13); `SaveFact.check` reads them:
  - `CACHES_TAKEN_AT_LEAST`: `index` is the count, as for `GUARDIANS_RESTORED_AT_LEAST`;
  - `OFFER_BOUGHT`: `id` is the offer id.
- `ReachKit` packs neither kind. No way is gated on them, and a test pins that no barrier names them.
- New fact files:
  - `resources/save_facts/took_a_cache.tres` (CACHES_TAKEN_AT_LEAST 1);
  - `resources/save_facts/village_replanted.tres` (OFFER_BOUGHT `replant_village`).

### The cache in the world

- `RewardSlot._fill()`: for `Kind.CACHE`, add a `CachePickup` with `slot_id`. There is no catalog because every cache holds one seed. COLLECTIBLE handling is unchanged. A filled slot draws no marker.
- `UpReach` (`scenes/world/interactables/up_reach/up_reach.gd`, a Node composed by a pickup root):
  - `reach_cells: Vector2` and `top: float` (px, the art top);
  - at `_ready` it sizes its parent's `CollisionShape2D`, places its `KeyGlyph` prompt and connects the parent Area2D's `body_entered` / `body_exited`;
  - `player() -> Player`;
  - `refresh(shown: bool)` sets the prompt to `shown and player != null and not in story and player.reaches(parent)`.
  - `ItemPickup`, `FoundPickup` and `CachePickup` compose it. Their `_physics_process` becomes one `refresh` call (a book adds `not wants_to_move()`). `PickupComponent` is unchanged in kind: the areas are still the pickup roots.
- `CachePickup` (`scenes/world/interactables/cache_pickup/`):
  - layers as `ItemPickup`; a 2x2-cell reach; the seed husk standing on the floor line;
  - `static lies(slot_id, data) -> bool` (`not caches_taken.has(slot_id)`), read on ready and on `progress_changed`;
  - `is_available()`; `take()` calls `SaveSystem.take_cache` and emits `taken(slot_id)`.
- `PickupComponent.reachable_cache() -> CachePickup`.
- `Player._try_cache(on_floor)` runs after `_try_found` and before `_try_board`. It is the letter path: one `UP_BUFFER`, `_free_for_up`, refused in a story, a refused press is spent, `_drop_buffers()` then `take()`.

### The seller and the trade

- **Dialogue** (`seller.tres`; see the file note below). Priority order:
  - `seller_seeds_first`: once, when `took_a_cache`; two lines, then the cue line `seller_shop`, then one closing line;
  - `seller_trade`: when `took_a_cache`; one line, the cue, one closing line;
  - `seller_apples`: unchanged.
  - Before his first seed Ivo hears only the apples line (question 11).
- **`SeedShopBeat`** (`scenes/world/story/seed_shop_beat.tscn`, `extends DialogueBeat`, cue `seller_shop`, hold STILL) under a new `Beats` Node2D in `village_lane_west_contents.tscn`. It is the controller:
  - `start()` calls `panel.open(SeedPurse.on_sale(...), SeedPurse.held(...))`;
  - on `panel.chosen(offer_id)` it re-checks `can_buy`. MAP or REPLANT calls `buy_offer`. RUMOUR calls `add_rumour(Rumours.next(...).slot_id)` and passes that piece's region name to the panel's said line. Then it refreshes the panel;
  - on `panel.left` it closes the panel and calls `finish()`.
  - Plain vars `stock` and `found` hold preloads (`SeedStock.DEFAULT_PATH`, `FoundCatalog.DEFAULT_PATH`) so tests can swap them.
  - If the beat leaves the tree mid-shop, the director already drops the talk (`gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first`).
- **`SeedShopPanel`** (`scenes/ui/seed_shop/seed_shop_panel.tscn`, instanced under the beat's `Layer` CanvasLayer at layer 1, INHERIT) is a view that never reads the save:
  - one 320x180 `Art` root at scale 2, `menu_theme.tres`;
  - panel `BGbox_05A` centred (starting size 192x140; settle in the build, as the dialogue box did);
  - a header row: seed icon and `SHOP_SEEDS_HELD` (`%d`);
  - one `InkButton` row per offer: text left, price and seed icon right. A row the player cannot afford is disabled with `focus_mode` NONE;
  - a Leave row last;
  - one said-line Label (`SHOP_SAID_*`) shown after a purchase.
  - Focus as in `DialogueBox`: explicit neighbours, wrapping at both ends; the first enabled row is focused on open, else Leave. `close()` releases focus, and `NOTIFICATION_UNPAUSED` grabs it back.
  - It is drawn under the HUD and the `Fade` (same layer, earlier in the tree), and under `ScreenLayer`. No tween is needed; any that is added is bound to the panel (pausable, scaled).
- **Question 1 decides the 0.6 case.**
  - Default (a), she stays: drop `"presence": 0.7` from `village_lane_west.room` (line 41, plus its line-3 comment) and `RegionPresence` from `inhabitants/seller.tscn`; check `MarketStallApples` for a 0.7 presence too. `seller_apples` keeps its `unless` 0.6, so at 0.6 he has no apples line and only trades.
  - Otherwise these files stay as they are.

**`seller.tres` (someone else's uncommitted change).** No new file can avoid the edit. The `t` names this set by path in the `.room`, a dialogue lives in exactly one set, and moving `seller_apples` to a new set would delete or empty this file. So the build edits it after that change is committed or confirmed. Exactly what changes:
- one `ext_resource` for `took_a_cache.tres`;
- six line sub-resources: `DLG_SELLER_SEEDS_01`, `_02`, a cue-only line `cue = &"seller_shop"` with no text and no speaker, `_03`, `DLG_SELLER_TRADE_01`, the cue again, `_02`;
- two `Dialogue` sub-resources (`seller_seeds_first` with `once = true`; `seller_trade`), both with `when = [took_a_cache]`;
- `dialogues = [seeds_first, trade, apples]`.
- The `seller_apples` sub-resources stay byte-identical.

### The map

- `MapExtras` (RefCounted, pure; `scenes/ui/map/map_extras.gd`). It takes a list of `MapRoomInfo` records (`room_id`, `region_key`, `bounds`, `interior`; its own file and `class_name`, `gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script`):
  - `known_rooms(infos, regions) -> Array[Rect2]`: surface rooms of bought regions;
  - `rumour_points(infos, pieces) -> PackedVector2Array`: per piece, the centre of its region's surface-room union, snapped into the nearest of those rooms so it never floats in the void. Several marks in one region step 7 pack px apart along x.
- `MapScreen.open()` builds the infos from the `Room` group, as `_seen_patches` does, then:
  - known rooms become faint full-grid Patches, cached per room key;
  - the rumour points come from `Rumours.marked`.
  - `MapCanvas.build(patches, known, marks)` draws known patches (`FAINT_INK`, the same cream at 0.35, no fill), then seen patches, then marks (a 5x5 pack px ink diamond, `MARK`). `seen_rect()` merges all three, so the centre clamp reaches a bought region or a mark.
- Revised never-break for `systems/map`: "A bought map or a rumour is drawn from purchases, never written to `map_seen`."

### Notices and the count

- No permanent HUD counter. The design keeps the HUD to the life notes.
- `Notice.Kind` appends SEED, and `NoticeQueue.add_seed()` queues one per seed gained.
  - `NoticeWatcher` diffs `caches_taken.size()`, seeded silently at `_ready`, and sends `shown("NOTICE_SEED", seed_icon)`. `seed_icon` is a new export.
  - Same queue, same hold (`NoticeHold`), same toast.
- The held count shows only in the shop header (question 7). No notebook entry: the Items section stays one entry per `PlayerItem`.

### Replanting

- `Gardens` `FactStaging` under `Props` in the four street rooms: lane west by the stall, square, mill and gate east (question 9).
  - Stages: `[{when: village_replanted, show: Replanted, fade_seconds: 1.5}, {show: Bare}]`.
  - Children are `Sprite2D` beds with season bands. `Replanted` may breathe through `AmbientMotion` (the daughter-strip precedent); the staging stays the only writer of visibility.
  - The lane-west bed sits in view of the stall, so the purchase is seen growing as the shop closes.
  - `prop_grounding_test` holds the beds to the street.

### Art (contracts first, `systems/art-pipeline`)

- `tools/art/prompts/pickup_seed.md`, `item_icon_seed.md`, `village_garden_bed_bare.md`, `village_garden_bed_planted.md`.
- A procedural `tools/art/draw_seed_art.py` (PIL, like `draw_found_pickups.py`) writes:
  - `assets/sprites/world/pickups/seed.png` (about 10x12 art px at 2x, a hard ridged husk upright with strong value contrast: the found-pieces lesson that flat art blends into the grey);
  - `assets/sprites/hud/icons/seed.png` (16x16, the notice and the shop);
  - `assets/sprites/world/props/village/garden_bed_{bare,planted}.png` (season bands).
- Credit everything in `CREDITS.md`.

### i18n (en and pt_BR, `i18n/translations.csv`; no literal in scripts or scenes)

- `NOTICE_SEED` ("Season seed" / "Semente de estação").
- `SHOP_SEEDS_HELD` (`%d`).
- `SHOP_MAP` (`%s` = `tr(region_key)`), `SHOP_RUMOUR`, `SHOP_REPLANT`, `SHOP_LEAVE`.
- `SHOP_SAID_MAP`, `SHOP_SAID_RUMOUR` (`%s` = region name), `SHOP_SAID_REPLANT`.
- `DLG_SELLER_SEEDS_01..03`, `DLG_SELLER_TRADE_01..02`.
- No prose is approved yet: the orchestrator drafts it and the user approves it in one round (question 8), as design 07 was for STORY-06.
- `seed_shop_text_fit_test` measures every row with each region's name, the header at 2 digits and each said line in both languages. `dialogue_text_fit_test` and `notice_text_fit_test` cover the rest by iteration.

### Playtest runner

- Timeline fields, after `found`, strings per `gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them`:
  - `"caches": [slot_ids]` → `take_cache`;
  - `"bought": [offer_ids]` → `buy_offer`;
  - `"rumours": [slot_ids]` → `add_rumour`.
- Timeline `tools/playtest/scripts/life04_seeds.json`:
  - take `threshold_ravine_cache` (base kit, the first secret) and see the toast;
  - at the seller (lane west col 17) with `caches` seeded, buy `map_frozen_lake` and a rumour, then Leave;
  - open the map: faint lake rooms, a mark on the woods (`woods_root_caves_alcove`, the first songbook);
  - a second leg with `bought: [replant_village]` walks the street.

### Reachability

No kit change. Caches are already audited slots, the seller stands in the village, and nothing bought opens a way. Add `room_kit_test.test_no_way_is_gated_on_seeds`: no barrier, door or grate names CACHES_TAKEN_AT_LEAST or OFFER_BOUGHT.

## Build order

1. Save and facts: the three arrays, the `SaveSystem` API, the two `SaveFact` kinds and fact files, the runner fields. Tests.
2. Pure rules: `SeedOffer`, `SeedStock` + `.tres`, `SeedPurse`, `Rumours`, `FoundPiece.room` on the 17 pieces. Tests.
3. Art script and contracts (placeholders first), `CREDITS.md`.
4. `UpReach` extracted. `ItemPickup` and `FoundPickup` move onto it with their suites green, unchanged.
5. `CachePickup`, `RewardSlot._fill` for CACHE, `PickupComponent.reachable_cache`, `Player._try_cache`. Leave the `$` legend text until `room_legend.tres` is free; then regenerate `docs/maps/README.md`.
6. Notices: SEED kind and icon.
7. Map: `MapRoomInfo`, `MapExtras`, the faint patches and marks in `MapCanvas`/`MapScreen`.
8. Shop: `SeedShopPanel`, `SeedShopBeat`, the `Beats` node in lane west, the `seller.tres` edit (after the other change lands), and the 0.6 change per question 1. Text keys and the fit test.
9. Gardens: stagings in the four street rooms.
10. Docs:
    - new `systems/seeds-and-the-seller` and its CLAUDE.md row (never break: seeds held are derived from caches taken and purchases, never stored; caches, purchases and rumours are live data; a bought map or rumour never writes `map_seen`; the shop is a beat, with no `WorldFreeze` writer, input reader or router screen);
    - update `systems/map`, `pickups`, `found-pieces`, `rooms`, `dialogue`, `story` (village voices row), `notices`, `life-benches-death`;
    - glossary: semente de estação → seed / `SeedPurse`; esconderijo → `CachePickup`; vendedor → seller; rumor → rumour; replantio → `replant_village`;
    - design 05's seller row (per question 1); the roadmap row; this entry's As built.
11. `verify-gates`, smoke, then playtest.

## Tests (gdUnit4)

- `tests/resources/world/seeds/seed_purse_test.gd`: held = taken - spent with repeated rumours; clamped at 0; refuses an offer the player cannot afford, a map already bought, a rumour with none left; `on_sale` order and hiding; `bought_map_regions`.
- `rumours_test.gd`:
  - `next` follows catalog order and skips pieces already rumoured, letters taken and books `can_teach` refuses;
  - null when none is left;
  - `marked` drops a taken piece.
- `seed_stock_test.gd`:
  - the shipped stock validates;
  - one MAP per world region scene but the village, and its `region_key` equals that scene's `name_key` (the six region `.tscn`s, trials excluded);
  - bad stocks report.
- `save_fact_test`: `test_caches_taken_at_least`, `test_offer_bought`.
- `tests/globals/save_system_seeds_test.gd`: each writer emits once and a repeat is silent; a death forgets all three. `player_data_test`: an old save loads them empty; round trip.
- `cache_pickup_test.gd`: lies until taken; shown again after a rewind; `take` records and emits; prompt and `reaches` agree across the edge.
- `reward_slot_test`: a CACHE gets one `CachePickup` and no marker. COLLECTIBLE is unchanged.
- `player_cache_test.gd`:
  - Up takes a seed once;
  - a door, a talk, an item and a found piece each win over it;
  - airborne, in a story or mid-roll is refused and the press is spent.
- `player_pickup_test`, `found_pickup_test`, `player_found_test`: unchanged and green after `UpReach`.
- `room_files_test.test_every_found_piece_names_its_room`.
- `room_kit_test.test_no_way_is_gated_on_seeds`.
- `map_extras_test.gd`: known rooms only for bought regions' surface rooms; a rumour point lies inside a region room; several marks step apart.
- `map_screen_test`:
  - a bought region draws faint and `map_seen` is unchanged;
  - the clamp reaches it;
  - a mark shows while its piece lies and goes once it is taken.
- `notice_queue_test` / `notice_watcher_test`: a cache raises one SEED notice with the icon; a rebuilt world is seeded silently; the notice waits for a talk.
- `seed_shop_beat_test.gd`:
  - start opens the panel with the stock on sale and the count held;
  - a buy writes the save and refreshes the panel;
  - an offer the player cannot afford is refused;
  - a rumour records `Rumours.next`;
  - Leave finishes the beat.
- `seed_shop_panel_test.gd`: rows taken from the offers; a row the player cannot afford is unfocusable; focus wraps; `close` releases focus; Z through `Input.parse_input_event` on a row emits `chosen`.
- `seed_shop_text_fit_test.gd`.
- `village_voices_test` updated for question 1.
- `story_beats_test` covers the new cue. `dialogue_catalog_test`, `prop_grounding_test`.

## Consequences

- The cache's content and the stock are data, and prices are a `.tres` edit. A price edit moves old saves' balances (clamped at 0).
- A bench makes a purchase permanent; a death before a bench unbuys it and puts its caches back.
- `UpReach` is the one place for Up-pickup reach and prompt. A fourth pickup composes it.
- The map now shows two kinds of knowledge, explored and told, in two strengths. "Seen" still means only the camera.
- `FoundPiece.room` duplicates a fact the maps hold, so moving a found piece is now a two-field edit, pinned by `room_files_test`.
- If question 1 keeps the seller leaving at 0.6, the trade closes after the second guardian and most seeds become worthless. The plan does not choose that silently.

## As built (2026-10-28)

Built as decided, with the user decisions below. Where the build differs from the Decision:

- **The seller stays** (decision 1): the lane-west talk lost its `presence` 0.7, `inhabitants/seller.tscn` and `props/village/market_stall_apples.tscn` lost their `RegionPresence`; `seller_apples` keeps its `unless` 0.6.
- **The count shows in three places** (decision 3), not the shop alone: the shop header; a LORE notebook entry `lore_seeds` (requirement `CACHES_TAKEN_AT_LEAST` 1) whose detail line takes the count through a new `NotebookEntry.detail_counts_seeds` flag read by `Notebook`; the title's `SlotCard`, which shows the count and an 8x8 seed icon on the bench row under the play time (numbers only, no text key).
- **`UpReach.setup(cells, art_top, art_x)`** is called by the pickup root in its own `_ready`, not run in the component's `_ready`: a child's `_ready` runs before its parent's, and `ItemPickup` only knows its art's top there. `ItemPickup` and `FoundPickup` moved onto it with their suites unchanged.
- **`RewardSlot.content()`** returns the `Area2D` it holds (a `FoundPickup` or a `CachePickup`).
- **The seed art:** the husk is 7x9 art px at 2x (14x18), taller than the grass; the icon sits beside the other item icons at `assets/sprites/hud/items/item_icon_seed.png`, not `hud/icons/seed.png`.
- **The panel** uses the dialogue box's wood box (`bg_box_wood.png`) at 192x170 pack px; rows are 12 px with an 8x8 seed icon by each price; a disabled row's ink is an override (`DISABLED_INK`), since `menu_theme.tres` has no InkButton disabled colour and was not touched.
- **The rumour's said line** names the region of the piece's room, found in the `Room` group (every region is in the world); a missing room pushes an error and leaves the name empty.
- **`MapExtras.known_rooms`** returns the `MapRoomInfo`s (the screen caches each room's full-grid patch by its scene key and bounds), and `MapExtras.steps` gives each mark its offset in `MapCanvas.MARK_STEP`s.
- **Notices:** `Notice.is_intent()` replaced the queue's `not is_item()` tests; `NoticeQueue.drop_seeds()` drops waiting seed notices when the count falls (a rewind).
- **The `Gardens` beds** have no ambient motion; the staging is the only writer of their visibility. Positions: lane west x 290 (the stall in the same view), square x 380, mill x 700, gate east x 1000.
- **The cue** is also set on the `SeedShop` instance in the lane-west contents, because `story_beats_test` reads cues from the contents' scene state, not from instanced sub-scenes.
- **Not done:** the `$` legend text in `room_legend.tres` (someone else's uncommitted change) and the `docs/maps/README.md` regeneration that follows it; the roadmap row (the orchestrator's); the playtest.

## User decisions (2026-10-28)

0. Who the seller is: "A woman, fix the text (Recommended)" (user, 2026-10-29), as the approved art shows; quoted labels keep their words.
1. The seller: "He stays to trade (Recommended)": only her apples line ends at 0.6; the stall and the seed trade remain all game.
2. Death: "Everything, purchases too (Recommended)": caches, seeds and purchases since the last bench rewind together.
3. Where the count shows: "Shop + notebook entry somewhere and load save screen (with the palying time)": the shop header, a notebook entry, and the save slot card beside the play time. The SEED toast on a gain stays as the find's feedback (orchestrator call; it shows no count).
4. The rest: "Accept all (Recommended)": prices map 1, rumour 1, replant 3; six regional maps, a repeatable rumour, one replanting; rumours in design 07 order, songbooks first; a bought map in the same ink at 0.35, no fill; four garden beds, one by the stall, procedural art; one husk sprite; the seller first mentions seeds once Ivo holds one; texts drafted for one approval round.

## Questions only the user can answer (recommended default first)

1. **The seller leaves the village at 0.6** (design 05, approved), but most seeds come later.
   - (a) **He stays for the trade (Recommended)**: his apples line ends at 0.6, the stall and the trade remain.
   - (b) He leaves at 0.6 and is found again in the orchards' inn (his line points west).
   - (c) The trade closes at 0.6.
2. **Death:** "Everything since the bench rewinds, purchases too (Recommended)", or purchases survive (which needs caches to survive too).
3. **Prices:** map 1, rumour 1, replant 3 (Recommended), out of 12 seeds.
4. **Stock:** six regional maps (no village), a rumour repeatable until every piece is found, one replanting (Recommended).
5. **Rumour order:** design 07's order, songbooks first (Recommended); or nearest unexplored.
6. **A bought map's look:** the room rectangles in the same ink at 0.35, no fill (Recommended); or a dotted line.
7. **Where the count shows:** a "Season seed" toast on each gain and the count in the shop only (Recommended); or also in the pause menu or a notebook Items entry.
8. **Texts:** the orchestrator drafts the seller's lines and shop strings in en and pt_BR for one approval round (Recommended).
9. **Gardens:** one bed per street room, four, with the lane-west one by the stall (Recommended); or only by the stall. Procedural art from a contract (Recommended), or Codex.
10. **Seed art:** one hard husk for all 12 (Recommended), or tinted by the region's season.
11. **When the seller first mentions seeds:** at the first seed Ivo holds (Recommended), or from the start, to point players at the caches.
