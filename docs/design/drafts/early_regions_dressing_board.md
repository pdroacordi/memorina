# Dressing the three early regions: Threshold Road, Frost Edge, Spring Woods (proposal board)

Request (user, 2026-11-22): "/feature-loop The next five features that are essential for the game to not seen incomplete." Roadmap WORLD-12, WORLD-13, WORLD-14, confirmed by the user as part of the run.

Status: approved (user, 2026-11-22): scope "Every room (Recommended)"; people "None, two crow stills (Recommended)"; the wheat "Hold the fields still (Recommended)"; the rest (a new winter scarecrow, WORLD-40 and WORLD-41 folded into WORLD-14, the fringes left to WORLD-48, three Codex concepts approved before any prop sheet) "Yes, all of them (Recommended)". The three concepts (`tools/art/sources/regions/dressing_<region>_concept_codex.png`) "Approve, fix in sheets (Recommended)" (user, 2026-11-22): the sheets hold the wheat in one gust, half-bury the figurehead as a bow carving, open the lighthouse doorway, drop the cabin window and soften the blossom. The prop sheets (77 props) "Fix the weak ones, then place (Recommended)" (user, 2026-11-23): cart_tipped, the figurehead's head, cargo_net, log_stack, saw_horse, oil_cans, churn, pot and mushrooms redrawn at exact size; the flagpole's red specks and the gull nest's recoloured feathers cleaned; the blossom tree's winter band bare. The movers, after the review found the wheat built as a still (user, 2026-11-23): "Sway loops, keep the hold (Recommended)": the wheat, the scarecrow's sleeve, the pennant and the torn sail get their sway loops through `AmbientMotion`; `FieldsStillMemory` stays, accepting weaker gusts over the fields (about 33 px/s at peak instead of 66). After the playtest (`playtests/2026-11-23-world12-14-early-regions-dressing`), the art calls "Fix them now" (user, 2026-11-23): the figurehead as a half-buried bow carving, the cargo net less bright, more flowers on the bloom_hollow vines, the farmhouse onions in contrast, the ravine rubble as earth, the root caves dressed further, a larger blossom heap over the soft landing.

The tiles, backdrops and palettes of the three regions are already approved (`tools/art/references/regions/board_threshold.png`, `board_frost_edge.png`, `board_spring_woods.png`, WORLD-30). Today each region has only its fronts (the farmhouse, the lighthouse base, the wreck hull, the woodcutter's hut; WORLD-24, WORLD-35), the farmhouse's STORY-02 meal, the wreck hold's seven borrowed village crates and barrels, the bridge's snow drift, the root wall (WORLD-42) and the lighthouse lamp and mentor staging (STORY-34). Thirteen of the 21 rooms have no `Props` node. This board adds what WORLD-11 gave the village and WORLD-15..17 gave the guardian regions: the props, what moves on the memory clock, the people, and the foreground. Concepts (Codex, our own art, no characters) follow approval: `tools/art/sources/regions/dressing_<region>_concept_codex.png`.

## How it is built (WORLD-15..17's pipeline)

1. The user approves this board, then the three concepts.
2. Codex draws one prop sheet per region on magenta, cut by `tools/art/cut_props.py --figure=none` to sizes in `tools/art/region_prop_sizes.json` measured against Ivo's 29 art px, palette-snapped. Nature props get three season bands (`prop_seasonal_material.tres`; "get three", user, 2026-11-22: winter-drawn props banded by `season_bands.py --winter`, spring-drawn ones from spring); built props one. The woodcutter's hut gets its own interior sheet, like the fisher hut and the orchard inn.
3. What moves is a short loop through `AmbientMotion` (stops below memory 0.2; movers above it run at the region's pace, "as you recommend", user, 2026-11-22). PixelLab `animate-with-text-v3` or `sway_between_posts.py` for cloth and ferns, drawn frames for petals. The user approves each sheet before it is placed.
4. Props are `Sprite2D` scenes under each room's `Props` (z -10); they never collide and never cover a gameplay cell, a jump line, a fight floor, a reward slot or a secret's hint. Nothing drawn invites a jump onto it (no rungs, ropes or ledges that are not cells). `prop_grounding_test` and `region_prop_placement_test` extend to `threshold`, `frost_edge` and `spring_woods`.
5. Reused from earlier regions where the look fits: `frozen_lake` (snow drift, snowy rock, dead shrub, frozen reeds, cairn, rope coil, barrel, crate, icicles, hanging roots, frost moss), `wind_orchards` (fence, fallen fence, signpost, nest, vines, ivy), `village` (woodpile, chopping block, chimney smoke). Reuse keeps each region's palette only if the colours sit in it; a prop that does not is redrawn on the region sheet.

Regions run one at a time, each its own commit: Threshold, then Frost Edge, then Spring Woods.

## WORLD-12 Threshold Road (winter, memory 0.3, before any song)

The road out of the village is the player's first lesson in the greyhush (01 §9.2): a farm that stopped at its meal and its harvest. Short, atmospheric, nothing that reads as usable.

**Sheet (built, one band):** the wayshrine (a small stone roadside shrine with a pitched roof, a carved figure and burnt-out candle stubs; the room is named for it and has none today), broken fence runs (snapped rails), an abandoned cart tipped on a broken wheel (design 04 §6), a scythe left standing in the wheat, sheaves bound and unbound, a road milestone, broken bridge parapet stubs, fallen bridge masonry.
**Sheet (nature, three bands):** grey wheat in tall stands (spring green, autumn gold, winter frost-grey and uncut: the harvest never came), a lone bare field tree, the scarecrow (question 4), dry thistles; reused: snowy rocks, dead shrub, snow drifts.
**Moves:** the wheat (4 frames, a sway; question 3) and the scarecrow's rag sleeve (4).
**People:** none (the farm is abandoned). Animals: two crows on the scarecrow and a fence, stills (question 2).
**Foreground:** tall wheat at threshold_fields' bottom edge (design 04 §6), in the WORLD-48 pass (question 6).

| Room | Dressing |
|---|---|
| threshold_fields | Wheat stands along the floor (cols 1-13, 20-28, 47-58), thinned under the farmhouse front (cols 35-46) and its shed roof; the scarecrow on the knoll top (cols 15-18, standing on row 7) with a crow; broken fence runs west of the knoll and east of the house; the tipped cart and a sheaf by the dip (cols 24-28, the dip cols 29-31 left bare); the bare tree on the east rise (cols 50-55); the scythe in the west wheat. |
| threshold_farmhouse | Keeps STORY-02's table, chair, stool, broom, basket, bucket, shelf and window; adds from the farmhouse sheet: a pot on the cold hearth (cols 17-18), onions and herbs from the beam, a coat and hat on a peg by the door (col 3), a churn. The sword's reach (x 240-368) and the table top stay clear. |
| threshold_bridge | Keeps the snow drift over the SoftLanding. Parapet stubs at the decks' outer ends (cols 10-11, 28-29, behind row 5), fallen masonry on the ravine floor (cols 14-17, row 11); the crack (12,10) and the draft (13,10) of the secret stay the only marks on the west wall. The milestone at the west road (cols 1-2), clear of the turn-back talk's reach. Snowy rocks and a dead shrub on the east block, away from the boar (31,4). |
| threshold_icefall_foot | Icicles on the shaft walls (cols 0 and 3) in `frozen_lake` art like the shaft above; the shaft and the open rows 9-11 stay bare. |
| threshold_ravine_cave | Roots hanging from the tunnel mouth (cols 9-13, rows 0-1), earth rubble on the mound (cols 8-15, row 5), a worn sack beside the cache hollow (cols 2-7), never on the `$` cell (3,7). |
| threshold_wayshrine | The shrine on the plateau west of the bench (cols 6-8, on row 7), snow drifts at the plateau's foot, a fence stub by the east back wall; the bench (10,6) stays clear. |

## WORLD-13 Frost Edge and the lighthouse (winter, memory 0.05)

**The Frost Guardian is not here** (design 04 §2: "O Guardião de Gelo não é o mentor"; it guards the Frozen Lake since STORY-03). The lighthouse is the mentor's: no ice-arena props, claw marks or Frost Guardian traces anywhere in this region; lighthouse_top is the final arena (GRD-06) and keeps its lamp and mentor staging. At memory 0.05 nothing moves outside a pulse, and Ivo has no Memorina until the lantern: every mover here is seen frozen mid-gesture on the way up.

**Sheet (built, one band):** the Gull's figurehead (a carved gull, half buried; `frost_wreck_letter` is "Log of the Gull"), a snapped mast with its spar and a torn sail, an anchor, buoys, a mooring bollard, the keeper's things (oil cans, a coal bin, a storm lantern on a nail, a folded blanket), a fog bell on a post, a flagpole with a torn pennant, a low iron railing; for the wreck hold: a hammock, a ship's lantern on a beam, a cargo net, a sea chest.
**Sheet (nature, three bands):** frozen kelp on rocks, beach-grass tufts, ice crust and frozen spray on the breaker, gull nests with old feathers; reused: snowy rocks, frost moss, icicles, snow drifts.
**Moves:** the pennant and the torn sail (6 frames each, held mid-flap at 0.05; they move only inside a pulse).
**People:** none. The mentor's staging in lighthouse_top is unchanged.
**Foreground:** icicles at the bench cave's mouth and rocks at frost_shore's bottom edge (design 04 §6 "estalactites, rochas"), in the WORLD-48 pass.

| Room | Dressing |
|---|---|
| frost_shore | Keeps the wreck hull (x 285-909). The figurehead and a buoy on the rock spur (cols 3-7), kelp and ice crust on its faces; rope coil and a barrel washed up at the west end (cols 0-2); the anchor at the breaker's foot (col 28); frozen spray on the breaker's curl (cols 33-37, under row 6, never on its top). Nothing in the dead lake (rows 10-11). No prop near the crabs (cols 10, 26) that reads as a creature. |
| frost_wreck_hold | Keeps the seven borrowed props, adds the hammock, ship's lantern, cargo net and sea chest so the hold reads as a ship, not a cellar; the bow and the letter's slot (17,3) stay clear, as do the loose planks' jump lines. |
| frost_cliffs | The keeper's shelter in the bench cave: the storm lantern on a nail, a blanket and a crate (cols 1-5, row 44), the bench (6,44) clear. Snow drifts in the slope's step corners, frost on the chimney walls, gull nests on the wall faces between treads, a cairn at the top exit (row 8, cols 33-38). The secret niche's crack (col 12, rows 38-39) stays the only mark on that face. No ropes or rungs. |
| lighthouse_base | Keeps the front. The fog bell beside the rock block (cols 4-5), oil cans and the coal bin by the door (cols 16-18 and 23-25, off the door at col 20), the flagpole with the pennant west of the front, the railing at the lookout's open east end (col 39, rows 5-8); the lookout slot (37,5) stays clear. |
| lighthouse_interior | Nothing in the shaft: the helix stair's view (`HelixView`, z -15) would be drawn over by any prop (z -10). On the two galleries only, and only where `HelixView` draws nothing (measured in the build): the keeper's empty cot end and a logbook stand on the middle gallery (row 25); if the view fills the gallery, none. |
| lighthouse_top | Keeps the lamp, its chain and the mentor. Only at the west wall, behind the fight's edge: oil cans and the keeper's chair (cols 1-3, row 20), low contrast. The floor, the air, the hatch pocket (cols 35-38) and the grey wall stay bare. |

## WORLD-14 Spring Woods (spring, memory 0.4)

**Sheet (built, one band):** a log stack, a saw horse, a hand cart of logs, a birdhouse on a post, a wooden signpost (reuse the orchard one if its palette holds), the woodcutter's chopping block with its axe (reuse the village one).
**Sheet (nature, three bands):** giant trunk bases with buttress roots (behind the ledges), shelf fungus, mushroom clusters, ferns, flowering bushes, a blossom tree, mossy stumps and rocks, a fallen log (unlike the pond's puzzle log in shape and colour), hanging moss, cracked mud and dead reeds for the dry pond, a moss-and-blossom heap (WORLD-41, question 5).
**Interior sheet (one band):** the woodcutter's hut: hearth with a kettle, bed with furs, table, an axe rack, snowshoes and a fur coat (the songbook is "a winter hand's", 07), a shelf of jars.
**Moves:** ferns and hanging moss (4 frames each, a sway), blossom petals drifting past at backdrop depth (6), the hut's chimney smoke if someone lives there (8, the village loop; question 2).
**People:** none proposed; question 2.
**Foreground:** branches and ferns at the open rooms' edges (design 04 §6), in the WORLD-48 pass.
**Folded in (question 5):** WORLD-40 (the hollow tree's knots drawn as wood or shelf fungus of the trunk) and WORLD-41 (a spring heap and SoftLanding where the drop from orchard_terraces lands in woods_canopy).

| Room | Dressing |
|---|---|
| woods_edge | Keeps the hut front. The chopping block, log stack and saw horse by the hut (cols 6-10); ferns and flowers along the floor; a blossom tree east of the bench (cols 33-37). The thrush's perch on the woodpile (25,6) and the bench (30,8) stay clear. The woods_crown tree's trunk rising behind the hut out of the top edge (cols 15-18), so the crown above has a tree under it (question 1). |
| woods_hut | Interior from its sheet: the hearth, bed, table, axe rack, snowshoes and coat. The loft ledge (row 5), the stair ledge (row 7) and the songbook's slot (10,4) stay clear. |
| woods_deep | Giant trunk bases between the branch ledges (behind, never under a ledge's end), shelf fungus on the trunks, mushrooms and ferns on the root mound (cols 12-41, rows 27-32), roots around the pit. No webs near the spiders (46,12; 52,16): a web would read as a hazard. The root wall (32,32) stays the only root tangle at the hole. |
| woods_canopy | Leaf and blossom clusters behind the branch ledges, the orchard nest at the nest slot (2,8) so the cache's place reads as a nest; the opening up to the orchards (cols 4-11) and the launch branch stay clear. WORLD-41's heap where the drop lands. |
| woods_root_caves | Hanging roots and mushrooms on the earth faces only: no root on shaft D's stone (cols 39-41) or any stone face, since Lógico 1 teaches that stone never roots. The alcove slot (3,16) clear. |
| woods_pond | Cracked mud on the dry basin's floor, dead reeds on its rim, a stranded lily pad or two; no log or plank in or by the basin, so the puzzle log stays the only thing that floats. The alcove slot (11,5) clear. |
| bloom_hollow | Only the edges: flowering vines on the west block's face (cols 0-2, rows 0-4) and the east wall, blossom shrubs in the two corners above the floor's ends. Nothing on the floor line between the walls (the thorn rows and seed patches must read alone), nothing over the west doorway (rows 5-8) or in the air the pounce and the lucidity leap cross. |
| woods_hollow_tree | WORLD-40's knots; shelf fungus and resin streaks on the heartwood wall between knots, a nest in the side hollow beside the cache (cols 10-13, row 22); the flashback ribbon's marks and the hollow's air (cols 4-9) stay clear. |
| woods_crown | Leaf and blossom clusters around the branch (cols 10-15, row 9) and the trunk top; the cache (12,8) and the hole (cols 11-14) clear. |

## Questions for the user

1. **Scope.** Every room as listed (the arena, the lighthouse rooms and the puzzle rooms lightly, the woods_crown trunk behind the hut included), or only the main rooms first (threshold_fields, the wayshrine, frost_shore, lighthouse_base, woods_edge, woods_deep)? Recommended: every room as listed, as WORLD-15..17 did.
2. **People and animals.** Recommended: no people in any of the three (the farm is abandoned, the keeper is gone, the woodcutter's hut is empty and cold, no chimney smoke); two crow stills in the fields. Or: a woodcutter in his hut with smoke from the chimney, an idle loop with no talk like the fisherman.
3. **The wheat** (design 04 §3.2: "Trigo cinza parado no meio do balanço"). At the threshold's 0.3 the wheat would sway slowly (the 2026-11-22 rule). Recommended: a hand-placed `MemorySource` over threshold_fields holding the fields under 0.2, as `WellSquallMemory` does for the lake well, so the wheat stands frozen mid-sway until a pulse (the region's other rooms keep 0.3). Or: let it sway slowly at 0.3 like the lake's movers.
4. **The scarecrow** (design 04 §3.2). Recommended: a new winter scarecrow for the knoll, in rags with a crow on its arm, drawn on the threshold sheet. Or: reuse the orchard's plain straw scarecrow.
5. **Fold in WORLD-40 and WORLD-41** into WORLD-14 (the hollow tree's knots as wood of the trunk; a spring heap and a SoftLanding where the terraces drop lands in woods_canopy, a one-cell `.room` change)? Recommended: yes, both.
6. **Foreground.** Recommended: these three regions' fringes (the fields' tall wheat, the cliffs' icicles and the shore's rocks, the woods' branches and ferns) join WORLD-48, so all six regions' foreground is built in one ForegroundPass pass; props only here. Or: each item builds its own region's fringes now.
7. **The concepts.** After the board, three Codex concepts (one per region) are drawn and shown for approval before any prop sheet. Approve that order, or go straight to the sheets?
