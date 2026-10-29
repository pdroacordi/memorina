---
id: playtests/2026-10-28-life04-seeds-and-seller
type: playtest
title: LIFE-04 seeds and the seller - the cache, toast, shop, map, notebook, slot card and the seller at 0.6 all work in en and pt_BR; the shop panel is drawn under Ivo and the greyhush, and the square's garden bed hides under the bench
status: active
build: 623582e plus LIFE-04 uncommitted. Import 19:40:18. No file under scenes, resources, assets, globals, i18n or the runner changed after it (checked at 19:53), so every run saw the same code.
area_tested: "threshold_ravine_cave cache (en, pt_BR); the seller in village_lane_west: first talk, shop (buy map_frozen_lake and a rumour, focus, wrap, disabled rows, Leave) in en and pt_BR; the map after buying; the four garden beds bare and replanted; the notebook's seeds entry; the title's slot cards (en, pt_BR); the seller at 0.6 with and without a seed, and before 0.6 without one"
tags: [life-04, seeds, cache, seller, shop, map, rumour, gardens, notebook, title, i18n, playtest]
related: [systems/seeds-and-the-seller, architecture/season-seeds-and-the-seller, bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite, bugs/the-square-garden-bed-stands-under-the-bench, playtests/2026-10-28-story06-found-pieces, playtests/2026-10-16-ui13-villager-portraits, playtests/2026-10-02-title-and-slots]
created: 2026-10-28
updated: 2026-10-28
ratings: { fun: 3, fluidity: 3, aesthetics: 2 }
screenshots:
  - screenshots/2026-10-28-life04-seeds-and-seller/cache_husk_prompt_toast_zoom.png
  - screenshots/2026-10-28-life04-seeds-and-seller/notebook_seeds_en.png
  - screenshots/2026-10-28-life04-seeds-and-seller/shop_open_en_ivo_over_panel.png
  - screenshots/2026-10-28-life04-seeds-and-seller/shop_bought_map_en.png
  - screenshots/2026-10-28-life04-seeds-and-seller/shop_bought_rumour_en.png
  - screenshots/2026-10-28-life04-seeds-and-seller/shop_bought_rumour_pt_br.png
  - screenshots/2026-10-28-life04-seeds-and-seller/shop_left_closing_line_en.png
  - screenshots/2026-10-28-life04-seeds-and-seller/map_faint_lake_and_rumour_mark.png
  - screenshots/2026-10-28-life04-seeds-and-seller/garden_beds_bare_vs_replanted_zoom.png
  - screenshots/2026-10-28-life04-seeds-and-seller/seller_at_0_6_trades.png
  - screenshots/2026-10-28-life04-seeds-and-seller/seller_at_0_6_no_seed_no_prompt.png
  - screenshots/2026-10-28-life04-seeds-and-seller/title_slots_seeds_en_pt_br.png
---

# LIFE-04: season seeds and the seller

## Summary

All six flows in the contract (`systems/seeds-and-the-seller`) work in the running game, and every text fits in en and pt_BR. Two visual defects:
- The shop panel is drawn under the world composites. Ivo and the grass draw over its rows, and the greyhush re-shades its paper. This confirms the reviewer's `bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite` in play; evidence was added there.
- The village square's garden bed stands under the save bench, so replanting barely shows there (new: `bugs/the-square-garden-bed-stands-under-the-bench`).

## What was tested

Timelines in `tools/playtest/scripts/` (the runner's fresh save, a private `APPDATA` per run):
- `life04_cache_en.json`, `life04_cache_pt_BR.json`: start at (6580, 630) in `threshold_ravine_cave`, walk left 0.3 s to x 6526.9 (the husk is at 6512), Up, a burst of shots through the toast, then E for the notebook.
- `life04_shop_en.json`, `life04_shop_pt_BR.json`: `caches` = 2 seeds, start at (-740, 280), 20 px left of the seller (col 17, x -720). Up, two lines, the panel; Down x3 to Frozen Lake, buy; Down x2 to the rumour, buy; Down and Up at 0 seeds; Leave; the closing line; M and X x3 on the map. `life04_discover.json` was the probe run for the same talk.
- `life04_gardens_replanted.json` (`bought: [replant_village]`) and `life04_gardens_bare.json`: teleports to each bed's room, diffed frame by frame.
- `life04_late_trade.json` (`restored_guardians: [0, 1]`, seeds, `seller_seeds_first` heard), `life04_late_noseed.json` (0.6, no seed), `life04_late_apples.json` (no seed, below 0.6).
- The title: a `-s` SceneTree driver (scratchpad, not committed) wrote two debug slots with `ResourceSaver`: 12 caches, Orchard Terraces bench; and 3 caches with `map_frozen_lake` bought, Town Square bench. It booted `boot.tscn` with `--title`, pressed Enter on the focused Continue and captured the slot screen.

## Findings

1. **The cache works and the husk reads, though it is small** (`cache_husk_prompt_toast_zoom.png`). In the grey cave the husk (7x9 art px at 2x) shows a dark left half against a light right half. It stands above the floor's tufts. The Up prompt shows at 15 px and not at 68 px. Up takes it at once. The husk is gone the next frame, and the SEED toast ("Season seed" / "Semente de estação", husk icon) slides in within 0.12 s, holds and is out by 3.4 s. The HUD quill shows beside it. The husk is the size of Ivo's boot, so a player who is not looking for it can miss it in a dark corner. That is a judgement from stills.
2. **First talk**: "That's a season seed. Haven't seen one in years." / "Nobody plants anything now. ..." (2 rows), then the panel opens on Z, with focus on the first row. pt_BR fits the box the same way.
3. **The panel**: header "Seeds: 2" with the husk; six map rows ("Map: Threshold Road" ... "Map: Summer Caldera"), "A rumour", "Replant the village" and "Leave". Price and an 8x8 husk are right-aligned. At 2 seeds, Replant (3) is drawn faded and is skipped by focus: Down from "A rumour" lands on Leave.
   - Up from the first row wraps to Leave, and Down from Leave wraps to the first row (focus log).
   - Buying Frozen Lake drops its row and shows "Seeds: 1" and the said line "An old map. The roads were there, once." Focus moves to the row now in that place, Wind Orchards (`shop_bought_map_en.png`).
   - The rumour shows "Something left behind. Bloom Woods, they said." (`shop_bought_rumour_en.png`). At 0 seeds every row is faded and focus sits on Leave; Down and Up both stay on Leave.
   - Leave closes the panel, and the talk resumes on "Find more, bring them here." (`shop_left_closing_line_en.png`). The next Z ends the talk, and the Up prompt comes back.
   - pt_BR fits: "Sementes: 2", "Mapa: Caldeira de Verão", "Um boato", "Replantar a vila", "Sair"; the rumour line is "Algo deixado pra trás. Bosque Florido, disseram." (`shop_bought_rumour_pt_br.png`).
   - The rumour line wraps to 2 rows in both languages, and its second row ends 3 art px above the frame. A longer region name would push a third row onto the frame. `seed_shop_text_fit_test` is the guard for that.
4. **Bug, confirmed in play: the panel is drawn under the world composites** (`shop_open_en_ivo_over_panel.png`). In every shop frame Ivo's sprite covers "A rumour" and "Replant the village", and the street's grass blades draw over the panel as green dots. The panel's paper comes out (177, 153, 137) where `bg_box_wood.png` (and the dialogue box) are (208, 156, 142). It changes to (175, 159, 151) at 0.6: the panel takes the world's memory shading. This is the medium-severity reviewer bug, now seen; measurements added to `bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite`.
5. **The map** (`map_faint_lake_and_rumour_mark.png`, two zoom-outs with X): Frozen Lake's surface rooms are thin outlines at the faint ink, with no fill. Lane west, the room explored in this run, is a filled box with a bright outline. The two are easy to tell apart. A 5x5 diamond marks the rumour about 3,700 world px west of the village, in the woods (`woods_root_caves_alcove`'s region). `seen=` stayed at 60 cells, lane west's only, after both buys, so nothing was written to `map_seen`. At the default zoom (4 px per cell) neither the lake nor the mark is on screen when the map opens at the village. The player has to zoom out or pan to find what they bought.
6. **Gardens** (`garden_beds_bare_vs_replanted_zoom.png`; columns lane west, square, mill, gate east; bare above, replanted below): with `replant_village` bought, lane west, mill and gate east show the planted bed (green crowns, yellow buds) where the bare one was. Lane west's bed stands in front of the bakery counter. From the stall with Ivo at the seller it is just past the left edge of the frame; it comes into frame when Ivo stands between the two. **Bug: the square's bed is under the save bench** (bed x 356..404, bench x 384..416). Only a 1-2 px green line shows under the seat: `bugs/the-square-garden-bed-stands-under-the-bench`.
7. **Notebook** (`notebook_seeds_en.png`): E after the take opens on Memories > "Season seeds", unread, with "1 in my pocket" over "Hard little husks, ...". pt_BR shows "1 no bolso". The entry is marked read when the book closes.
8. **Title slot cards** (`title_slots_seeds_en_pt_br.png`): each used card shows the count and the husk icon on the bench row, under the play time: 12 for the full slot, and 2 for 3 taken minus the 1-seed map. "Terraços do Pomar" and a two-digit count fit side by side in pt_BR. Reached with a `-s` driver: the runner itself is memory-only.
9. **The seller at 0.6** (`seller_at_0_6_trades.png`): with two guardians restored she still stands at the stall. Up gives "Seeds? Let's see." and the panel, so the trade works. With no seed at 0.6 no Up prompt shows and Up does nothing (`seller_at_0_6_no_seed_no_prompt.png`), as the contract says. Below 0.6 with no seed, the apples line plays: "Apples. West orchards. Last ones, till someone goes out there."
10. **Text vs art: the seller is a woman.** The portrait and sprite (approved in UI-13, `playtests/2026-10-16-ui13-villager-portraits`) show a woman. The plate reads "Vendedor" (masculine, pre-existing), and the new notebook text reads "O vendedor de maçãs troca por elas" in pt_BR. The contract and design 05 call the seller "he". English hides this; Portuguese does not. It needs a decision on who the seller is, so it is reported, not filed.
11. **Not confirmed**: `life04_late_apples` ended in a segmentation fault at exit, after its last shot, with a talk open (the timeline's final Up had started the apples line again). It happened once in 11 runner runs; the other 10, some of which also ended with a talk or the panel open, exited cleanly. Not filed.

## Ratings rationale

- **Fun 3** (low confidence, inferred): the loop (find a husk, trade, see a map or a mark appear, watch the village plant) is complete and legible. Whether one seed per secret feels worth the detour, and whether a rumour diamond pulls the player toward the woods, needs a human session.
- **Fluidity 3** (inferred from timing and focus logs, not felt): the panel opens on the cue with no blank frame between the talk and the shop, focus is predictable, and wrap and disabled rows behave. The toast is quick (in by 0.12 s). Input latency and how the talk-shop-talk handoff feels cannot be judged from stills.
- **Aesthetics 2**: the panel and the slot card are clean and fit in both languages, and the planted beds read well where they stand in the open. But in every shop frame Ivo stands on top of the panel and the panel is tinted grey, and the square's bed is hidden. Both are layout faults the player would see on the first trade.

## What screenshots cannot show

Input latency on the shop's buttons, whether the panel's appearance feels abrupt, the replanted beds' 1.5 s fade (only the end states were captured), audio (none is wired for a buy), and how noticeable the husk is in motion while running past it.
