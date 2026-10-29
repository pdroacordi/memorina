# Creatures board (draft for CORE-13 and CORE-04)

Draft, 2026-10-29. Not a design decision: nothing here is approved. It asks the user to pick before any art or code. Sources: design 02 §1, §2, §6, §7.1, §7.2.1, §8 (A isca); 03 §2, §3.2, §5; 04 §2-§3; `systems/guardians`, `systems/greyhush`, `systems/songs-and-the-memorina`, `architecture/half-songs`, `tools/art/prompts/style.md`.

## Decided (user, 2026-10-29)

- Enemies: "The six picks (Recommended)": Threshold boar (replaces the brute at threshold_bridge), Frost Edge crab, Frozen Lake icicle bat, Spring Woods spider, Wind Orchards hornet, Summer Caldera scorpion plus its tougher bait variant for "A isca"; no enemies in the village.
- Teachers: "Same, but a thrush for Chuva": Redoma a glass-shelled snail (fishing village stilts), Chuva a thrush (spring woods), Vendaval a kestrel (orchard_windy_gap), Solstício a lizard (caldera_open_crater).
- Learning: "He plays it back (Recommended)": the creature performs its three notes as moves in each note's direction, repeats slowly when Ivo is near, Ivo echoes them; a wrong note costs nothing; the half sheet holds through the duet.
- After: "Stays and repeats (Recommended)": it stays and sings the phrase again whenever the Memorina is drawn near.

## Ground truth this board builds on

| Fact | Consequence for creatures |
|---|---|
| The only enemy today is the Brute Shadow, one placement: `threshold_bridge` cell 31,4 (`save_id` `threshold_bridge_brute`), legend `B`. Its sheets are 192 px frames, not our 2x art. | CORE-13 replaces one placement and one legend entry; the brute scene, its stats and its sheets retire after. |
| Kit on first visit: Threshold and Frost Edge = sword combo, air slash, pogo, jump (roll and double jump not yet). Lake and Woods either order, still base kit; roll comes from the Frost Guardian, double jump from the Bloom Guardian. Orchards: double jump or Enraizar assured. Caldera: Redoma or wall climb, usually most of the kit. | Each region's creature must be fair with the kit the player can have on arrival; later abilities only make it easier. |
| No parry exists in code or on the roadmap, though 02 §1-§2 call it central. | Attacks below are given a clear wind-up so a parry can be added later; none needs it now. |
| Creatures respawn at a bench or a death (02 Derrota); enemies never give seeds (LIFE-04). | Fights are obstacles, not farming. |
| Redoma bars matter, not creatures (02 §7.1). Sombra's shadow is seen by creatures as Ivo; `EnemySight.visible_presence()` already returns it. | Every species must take its target from `visible_presence()`. `caldera_bait` (A isca) needs a territorial creature, harder than the region's standard. |
| The edge glitch ("pixels deserting the silhouette", 03 §3.2) is not built: corrupted sprites today only pass through `greyhush_creatures.gdshader`. `GreyhushShield` (colour around a body) exists and already names "a creature-teacher". | One shared corruption material is part of CORE-13. Teaching creatures carry a shield and no glitch: colour reads as friend, grey and fraying reads as foe. |
| The four first halves (`Enums.Note`: UP 0, DOWN 1, LEFT 2, RIGHT 3): Redoma L R L; Chuva R R R; Vendaval R R L; Solstício R D U. | A teacher shows each note as a movement in that screen direction, voiced at that note's Memorina pitch. |
| `MemorinaHud` half sheet: `LESSON_SHEET_HOLD` 1.4 s + 0.6 s fade; the SONG-14 playtest found ~2 s too short. | A teacher repeats its phrase and holds the sheet longer (below). |

## Part 1: corrupted creatures (CORE-13)

Glitch column: how the shared corruption material reads on that body. Shared rules for all: pixels desert from the outline on `greyhush_time`, more as the creature is hit; death is a full desertion and spawn its reverse, so neither needs a drawn clip.

### Estrada do Limiar (`threshold`), winter 0.3. First enemy; replaces the brute.

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Javali (boar)** | Low, wide, tusks, bristled ridge; ~30x18 art px | Wanders the frozen field; on sight, paws the ground (0.6 s tell) and charges in a straight line; stops dazed against a wall or after a fixed run | Forages the grey wheat; frozen stubble flicks up from its feet (stopped in grey, moves near Ivo) | Jump over the charge and hit its back; pogo on the dazed boar; the combo lands during its daze | Ridge bristles fray first, like frost lifting off |
| B. Corvo (crow) | Small, black, from the scarecrow field; ~14x10 | Perches, then dives at Ivo along an arc and climbs back to a perch | Scarecrow and stopped wheat | Air slash at the bottom of the dive; step under the arc | Feathers peel off in single pixels |
| C. Cão do sítio (the farm's dog) | Medium dog; ~24x16 | Brute AI almost as is: wander, chase, crouch, lunge bite | The farm's forgotten dog (01 §3 "o nome do cachorro") | Combo after the lunge; pogo | Outline flickers like a fading memory |

**Recommended: A, the boar.** A charge teaches "read the tell, jump, punish" in one obstacle, it stays on the ground for a base-kit first fight, and it does not ask the player to kill a pet. C is the cheapest AI but carries a heavy lore image for a common mob.

### Borda Gelada (`frost_edge`), winter 0.05. The deepest grey; base kit (opening journey).

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Caranguejo (crab)** | Wide, low shell with barnacled ice, two claws; ~20x12 | Sidesteps toward Ivo; claw snap forward (0.4 s tell); shell front blocks sword hits | Shore ice and the wreck | Pogo on the shell (it takes only hits from above or behind); jump over the snap | Heaviest fraying of the set: the shell edge breaks up in large steps (0.05 memory) |
| B. Gaivota (gull) | Long wings; ~24x10 gliding | Circles the cliff shaft, dives across a ledge to knock Ivo off | `frost_cliffs` vertical climb | Air slash; wait on the ledge for the pass | Wingtips scatter |
| C. Ratos do naufrágio (wreck rats) | Tiny, 3-4 at once; ~10x6 | Scurry low in the hold, bite and retreat | `frost_wreck_hold` | Down slash and pogo; low swings | Pixels shed into a trail |

**Recommended: A, the crab.** It makes the pogo the answer to something (the first fight teaches the attack; the second teaches the down-strike), and it suits both the shore and the wreck.

### Lago Gelado (`frozen_lake`), winter 0.3. Base kit on arrival; roll after the guardian.

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Morcego-pingente (icicle bat)** | Hangs folded like an icicle (~10x18); opens to ~24x12 | Hangs still among real icicles in `lake_ice_caves`; drops and swoops when Ivo passes under; returns to the ceiling | Ice caves, hanging ice | Bait the drop, step back, air slash or pogo as it swoops; double jump on a revisit | Hanging: the "icicle" tip drips pixels, the tell that it is not ice |
| B. Lúcio (pike) | Long fish; ~28x8 | Leaps from open water in an arc across a crossing, then sinks | Lake water (hazards detect the body) | Time the crossing; slash at the arc's top | Scales flake mid-leap |
| C. Arminho (stoat, winter coat) | Slim, white; ~18x8 | Fast darting bites, retreats out of reach | Snow along the fishing village | Chop as it closes; roll through once owned | White coat frays to grey |

**Recommended: A, the icicle bat.** It is the set's first ceiling ambush, and it uses the cave's own material for camouflage. B is beautiful but tied to water crossings, which the Congelar puzzles already own.

### Bosque Florido (`spring_woods`), spring 0.4. Base kit on arrival; double jump after the guardian.

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Aranha (spider)** | Round body, eight legs; ~16x14; silk thread drawn as a line | Drops on its thread from the canopy or a root cave ceiling, bobs at Ivo's height, bites when close; climbs back up | Canopy and root caves; spring "liga", silk binds | Hit it at the bottom of the bob; pogo on it to climb higher (a rewarded double jump later) | The thread itself frays, a dotted line |
| B. Besouro-rinoceronte (rhino beetle) | Armoured, horned; ~20x14 | Walks, then tosses upward with its horn | Moss earth, fallen trunks | Pogo off its back (a bounce that reaches ledges) | Shell edge shimmers |
| C. Javali-de-musgo | Boar variant | As the Threshold boar | — | — | — |

**Recommended: A, the spider.** It is vertical where the others are horizontal, and it fits both woods levels. C is listed only as the minimum-scope reuse.

### Pomar dos Ventos (`wind_orchards`), autumn 0.25. Double jump or Enraizar assured; wall climb after the guardian.

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Vespa (hornet)** | Small striped flyer; ~14x12 | Hovers, locks on (0.5 s buzz tell), dashes in a straight line; the wind (`systems/air`) carries it, bending its path | Rotting autumn fruit, nests in the trees; wind currents | Sidestep or jump the dash, slash during its recovery; read the current to predict the bend | Wings blur into scattered pixels |
| B. Pega (magpie) | ~18x10 | Rides currents, swoops, steals nothing (kept simple) | Wind | Air slash | Feathers peel |
| C. Lebre (hare) | ~18x12 | Long wind-assisted leaps that land on Ivo | Terraces, wind | Move out from under the landing shadow, punish the landing | Ears fray |

**Recommended: A, the hornet.** It is the only enemy that makes the region's wind matter, and its dash has a clean tell.

### Caldeira de Verão (`summer_caldera`), summer 0.15. Most of the kit; Sombra learned here.

| Option | Silhouette | Behaviour / attack | Material, season | Counter-play | Glitch |
|---|---|---|---|---|---|
| **A. Escorpião (scorpion)** | Low body, tail arched overhead; ~28x14 (20 tall with tail) | Territorial: holds a patch of basalt, turns to face anything in it; tail strike overhead (0.7 s tell) sticks in the ground for 0.8 s | Hot basalt and temple sand; summer "fica", it stays put | Roll through the strike, punish the stuck tail; pogo is refused by the raised tail (it swats upward) | The tail tip flickers and frays: the tell is in the fraying |
| B. Cigarra (cicada nymph) | ~12x10 | Bursts out of the ash under Ivo, then burrows again | Ash scree | Keep moving; slash when it surfaces | Shell cracks into pixels |
| C. Tatu-basalto (armadillo) | ~20x14, rolls into a ball | Rolls down slopes at Ivo | Basalt shelves of the Sun stair | Jump over; hit it while it uncurls | Ball outline breaks |

**Recommended: A, the scorpion.** Territorial is exactly what `caldera_bait` (A isca) asks for: the bait's guard is the same scene with tougher stats, and the Sombra shadow pulls it off its patch.

### Vila (`home_village`), 0.8

**Recommended: no enemies.** The hub is the safe place; the village is "not for exploring" (04 §3.1, the grate decision).

## Part 2: teaching creatures (CORE-04)

Shared behaviour, recommended for all four:
1. **Ambient first.** The creature lives in its spot and performs its three notes on its own every few seconds, in shielded colour inside the grey. Each note is a movement in the note's screen direction, voiced at the Memorina's pitch for that note in the animal's own timbre. No HUD.
2. **Trigger.** Ivo, owning the Memorina, comes within ~4 cells. The creature turns to face the camera's plane and performs again, slower (the guardian call's 0.55 s note interval), then waits.
3. **Echo.** Ivo draws the Memorina and plays the three notes back. A wrong note is the ordinary mistake, at no cost; the creature waits ~2 s and performs again. A right echo calls `Player.learn_song_half(song, Enums.SongHalf.FIRST)`.
4. **Hold.** The half sheet stays up while the creature sings the phrase once more with Ivo (a duet, ~4 s), then fades. This is the fix for the ~2 s playtest finding.
5. **Repeat forever.** Whenever Ivo later draws the Memorina near it, it sings the phrase again: a living memory aid beside the notebook.
6. It has no hurtbox. A sword swing startles it (one flinch clip), and it resumes after a few seconds. It never blocks a path.

### Redoma (BELL_JAR), Lago Gelado. First half L R L.

| Option | Animal | How it performs L R L | Where, trigger | After the half |
|---|---|---|---|---|
| **A. Caracol-redoma (glass-shelled snail)** | Pond snail with a clear, frosted shell, the bell jar image itself; ~12x10 art px | Drip from the stilt roof falls; the snail rocks its shell left, right, left, a glass chime on each, and withdraws: the shell frosts over, the drip runs off it. Then it slides back out ("nothing enters, everything may leave") | Under the stilts of `lake_fishing_village`, on the way to the guardian; triggered on approach | Stays; its shell stays frosted and it chimes the phrase whenever the Memorina is drawn near |
| B. Cágado (pond turtle) under an ice hole | ~16x10 | Looks out left, right, left, then pulls into its shell as snow falls on it | `lake_shore`, at an ice hole | Stays; same repeat |

**Recommended: A.** The animal is the song's image (a glass dome that keeps the weather out, and lets its keeper out again).

### Chuva (RAIN), Bosque Florido. First half R R R.

| Option | Animal | How it performs R R R | Where, trigger | After the half |
|---|---|---|---|---|
| **A. Rã (frog) in the dry basin** | Small green frog; ~12x10 | Three hops to the right across the cracked basin floor, three croaks on one pitch, then it looks up at a sky that does not rain | `woods_pond`, in "A bacia seca" itself; triggered on approach | Stays in the basin; once Chuva is whole, playing it fills the basin and the frog swims: the reward is seen |
| B. Sabiá (thrush), the user's own example | ~12x10 | Three hops right along a branch, three equal chirps; raindrops stopped on the leaves shake loose near it | `woods_edge`, on the woodcutter's hut roof (by the bench) | Flies off west, toward the lake where the songbook lies (a hint) |

**Recommended: A.** It teaches at the puzzle the song will solve, and the repeated note reads clearly as three equal hops. B is the cheaper bird if the user wants their example literally.

### Vendaval (GALE), Pomar dos Ventos. First half R R L.

| Option | Animal | How it performs R R L | Where, trigger | After the half |
|---|---|---|---|---|
| **A. Peneireiro (kestrel)** | Small falcon hovering; ~16x12 | Hangs in the updraft, slips right twice on the gust, then wheels left into the wind, a cry on each | `orchard_windy_gap`, over the natural current; triggered when Ivo stands on the gap's floor | Stays hovering; it slips through the phrase again whenever the Memorina is drawn |
| B. Estorninhos (starling flock) | 12-20 birds, ~6x4 each | The flock sweeps right, right, then folds left: the phrase drawn by a murmuration | `orchard_terraces`, the arrival bench, open sky | The flock leaves south-east, toward the Caldera and the songbook |

**Recommended: A.** One sprite. B is the most beautiful staging on the board but needs flocking code and many sprites on screen.

### Solstício (SOLSTICE), Caldeira de Verão. First half R D U.

| Option | Animal | How it performs R D U | Where, trigger | After the half |
|---|---|---|---|---|
| **A. Lagarto (basking lizard)** | Sun lizard on basalt; ~18x8 | Turns right to the sunbeam, dips (a push-up, real lizard display), rises with its head up; the colour around it holds a little longer than its pulse (the song's own idea) | `caldera_open_crater`, on a sunlit ledge by the bench; triggered on approach | Stays basking; repeats on draw |
| B. Mariposa (moth) at a brazier | ~10x8 | Flies right to the brazier, drops down, rises up into the light | `caldera_temple_gate` | Flies off north-west, toward the orchards and the songbook |

**Recommended: A.** The push-up is a readable down-up, and basking is "the longest day" as behaviour.

## Part 3: scope

### How many enemy types

| Set | Types | Covers |
|---|---|---|
| Minimum | 4: boar (all three winter regions), spider, hornet, scorpion | One per season; winter regions share a creature |
| **Recommended** | **6: boar, crab, icicle bat, spider, hornet, scorpion**, plus the scorpion's bait variant as data only | One per region, each with its own counter (charge, pogo, ambush, vertical, wind dash, territory) |
| Later, if wanted | Second creature per region from the B columns | Variety in the long regions (Orchards, Caldera) |

Density hint: 1-3 per non-puzzle room, none in puzzle rooms unless the puzzle is about them (A isca).

### What replaces the brute

The boar takes the brute's cell in `threshold_bridge` (31,4), with a new `save_id`. The `B` legend entry becomes the boar, or is retired for one character per species. Retire `scenes/characters/enemies/brute_shadow/`, its stats and the pack-era sheets; move `combat_reach_test`'s brute cases to the boar (park inside Ivo's reach: slash 78.5, chop 70.5).

### Structure hints (CLAUDE.md: composition, Resources, controller split)

- **Body:** `Enemy extends Character` stays. One scene per species, `scenes/characters/enemies/<species>/`, composed of Hurtbox, Hitbox, `LocomotionComponent`, `EnemySight`, the AI, an `AnimationDriver` and resolver, and the new corruption material.
- **Moves as data:** generalise `BruteShadowAttackStats` into an `EnemyMove` Resource (telegraph, range, wind-up, active, recovery, cooldown, `lunge_speed`, `leap_impulse`, damage, knockback, clip). Share fields with `GuardianAttack` or extract a common base. An `EnemyStats` Resource holds health, contact damage, sight, `stop_distance` and `moves: Array[EnemyMove]`. The bait scorpion is the same scene with another `EnemyStats`.
- **Intent:** `EnemyAI extends AIController` keeps WANDER/CHASE and gains generic TELEGRAPH/ATTACK/RECOVER driven by the move list (most of `BruteShadowAI` moves down). Movement style is the only per-species code: ground walker (boar, crab, scorpion), flyer (hornet, uses `AirflowBody`), ceiling hanger (bat), thread (spider). Each style is a small `EnemyAI` subclass or a swapped locomotion component, never a branch in one script.
- **Corruption edge:** one shared shader include, art-pixel space, re-rolled on `greyhush_time` (never `TIME` or `FRAGCOORD`), with a `corruption` uniform 0..1 the script raises with damage. Death and spawn are shader dissolves. It works under the creatures `CanvasPass`. Guardians can adopt it later (02 §2 says they share the glitch).
- **Teacher:** a new `TeachingCreature` (not an `Enemy`, not a `StoryActor`) with a `GreyhushShield`, its own resolver and a `CreatureLesson` Resource: song, half (FIRST), note interval, rest between repeats, trigger radius, and one clip per note direction. It reuses the guardian call path (`Player.open_call`), which today takes a whole song: the change is a three-note phrase. Then `Player.learn_song_half`. The duet hold is a teacher-specific hold on the half sheet, not a bigger `LESSON_SHEET_HOLD` for every half (songbooks keep theirs).
- **Audio:** each teacher needs 4 note sounds at the Memorina's pitches in its timbre (16 samples, or one sample pitched 4 ways).

### Art workload (2x density: 1 art px = 2x2 game px; Ivo is ~29 art px tall in 128 px frames)

Pipeline per species (the `inhabitant_cat` route): one Codex still on magenta, PixelLab `animate3` per clip, `cut_inhabitant.py`, a contract in `tools/art/prompts/`, a `CREDITS.md` line. Expect 1-3 review rounds per still (Ivo took several).

| Creature | Body (art px) | Frame (game px) | Clips (frames) | Total frames |
|---|---|---|---|---|
| Boar | 30x18 | 96x64 | idle 4, walk 6, tell 3, charge 4, daze 4, hurt 2 | 23 |
| Crab | 20x12 | 64x48 | idle 4, sidestep 6, tell 2, snap 4, hurt 2 | 18 |
| Icicle bat | 10x18 hanging / 24x12 open | 64x64 | hang 2, drop 3, fly 6, swoop 3, hurt 2 | 16 |
| Spider | 16x14 (+ code-drawn thread) | 48x48 | idle 4, climb 4, bob 4, bite 4, hurt 2 | 18 |
| Hornet | 14x12 | 48x48 | hover 4, tell 3, dash 3, recover 3, hurt 2 | 15 |
| Scorpion | 28x14 (20 tall) | 80x64 | idle 4, walk 6, tell 3, strike 4, stuck 3, hurt 2 | 22 |
| **6 corrupted** | | | no death or spawn clips (shader) | **~112** |
| Glass snail | 12x10 | 32x32 | idle 4, rock L/R 3+3, withdraw 4, emerge 4, flinch 2 | 20 |
| Frog | 12x10 | 48x32 | idle 4, hop 5, croak 3, look up 2, swim 4, flinch 2 | 20 |
| Kestrel | 16x12 | 48x48 | hover 6, slip 3, wheel 4, cry 2, flinch 2 | 17 |
| Lizard | 18x8 | 48x32 | bask 4, turn 3, push-up 4, flinch 2 | 13 |
| **4 teachers** | | | | **~70** |

About 180 frames and 10 stills. The minimum set saves 2 stills and ~34 frames. The B-option flock (starlings) and the frog's swim are the costliest single items.

## Questions for the user

1. **How many enemy types?** Default: **6, one per region, plus the bait scorpion as a stats variant** (minimum 4 if art time is short).
2. **The six corrupted creatures:** boar (Limiar), crab (Borda Gelada), icicle bat (Lago), spider (Bosque), hornet (Pomar), scorpion (Caldeira)? Default: **yes, the recommended set; no enemies in the Vila.**
3. **The four teachers:** glass snail (Redoma), frog in the dry basin (Chuva), kestrel (Vendaval), basking lizard (Solstício)? Default: **yes; the thrush (your bird example) if you want a bird for Chuva.**
4. **How is the half taken?** Default: **by echo** (Ivo plays the three notes back, the call-and-response), not by watching alone. The creature repeats until he does, and the sheet holds through a ~4 s duet.
5. **What does a teacher do after?** Default: **it stays and sings the phrase whenever the Memorina is drawn near it**, rather than leaving toward the songbook's region as a hint.
