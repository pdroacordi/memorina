# Guardian fights: faster, harder, more animated (proposal board)

Request (user, 2026-11-18): "Vamos fazer agora os itens do roadmap que ainda faltam relacionados aos guardiões. além disso, quero ir além: fazer mais padrões de ataque, mais animações (no momento a luta é meio travada) para todos os guardiões. Todos devem ficar com uma luta mais frenética, mais difícil, mais estilo hollow knight"

Status: approved (user, 2026-11-18): "Approve as proposed (Recommended)"; stages "Yes, each answer escalates (Recommended)"; art "Code first, art per guardian (Recommended)"; life "Keep 3 notes, damage 1 (Recommended)". Roadmap GRD-12 to GRD-18.

## Why the fights feel stuck today

- Three single moves per guardian; after each, 1.4-2.8 s of cooldown spent pacing.
- The telegraph is the guardian standing still with a colour pulse (0.35-0.9 s), not a wind-up pose.
- No strings of hits, no projectiles or ground hazards, no dash or reposition, no aerial move except two leaps.
- The pressure phase is the same from the first hit to the last cure step; only a failed answer speeds it up (design 02 §3).
- The resolver has 3 attack clip slots, so a fourth move has nowhere to play.

## Shared changes (one engine item, before any guardian)

1. **Wind-up, strike, recover.** Each move has a wind-up clip (the telegraph is read from the pose, the pulse stays as an accent), the strike, and a short recovery: the opening to punish. Cooldowns drop to 0.3-0.9 s; the recovery is the breathing room.
2. **Strings.** A move can chain into a follow-up with no cooldown (`follow_ups`, chance per link): lash, lash back, antler thrust.
3. **Stages.** Each good answer moves the guardian to its next stage: more moves, shorter cooldowns, longer strings (the Hollow Knight phase 2). A failed answer still adds aggression as today (design 02 §3, unchanged).
4. **Spawned attacks.** Projectiles and ground hazards as scenes: a travelling spike line, falling icicles, thrown blades, embers. They run on the scaled clock and hit Ivo's hurtbox like any hitbox; they pause with the world.
5. **Reposition moves.** A backstep, a dash across the arena, a leap to the far side, a dive from above.
6. **More clip slots.** Attack slots open to 8, plus wind-up and recover clips per move.

## Per guardian (season patterns, design 02 §3)

New moves in **bold**. "Stage" is the cure step the move joins at (0 = from the start).

### Bloom Guardian (spring, the tree-stag: light, fast, changes sides)
| Move | Stage | What it does | How to dodge |
|---|---|---|---|
| Lash | 0 | as today, now a string of 3: lash, back-lash, **antler thrust** | back off after the second, or pogo |
| Burst | 0 | as today (carries the double-jump recall) | the recall |
| Pounce | 0 | as today; from stage 1 it pounces twice | walk or roll under the first |
| **Thorn row** | 0 | stamps; thorns burst from the floor in a line running at Ivo | jump it |
| **Seed lob** | 1 | lobs 3 pods in arcs; each bursts into a thorn patch for 1 s | stand between them |
| **Antler dash** | 1 | backstep, then a low dash through the whole arena | jump over |

### Frost Guardian (winter, the ice golem: heavy, hits hard, controls the floor)
| Move | Stage | What it does | How to dodge |
|---|---|---|---|
| Swipe | 0 | as today, now swipe, swipe, slam (a string) | out after the second swipe |
| Charge | 0 | as today (carries the roll recall); from stage 1 it turns at the wall and charges back | roll / jump |
| Slam | 0 | as today, now sends an **ice wave** along the floor both ways | jump the wave |
| **Icicle fall** | 1 | strikes the ceiling; icicles fall where Ivo stands, a glint first | keep moving |
| **Body drop** | 2 | heavy leap onto Ivo's spot, shockwave on landing | move out of the shadow |
| Walk | - | GRD-11: walk redrawn or retimed | |

### Leaf Guardian (autumn, the bone scarecrow: erratic, from the air, wind)
| Move | Stage | What it does | How to dodge |
|---|---|---|---|
| Sweep | 0 | as today, now sweep, sweep, **overhead claw** | |
| Hop | 0 | as today | |
| Gust | 0 | as today (carries the wall-climb recall) | the recall |
| **Leaf blades** | 0 | throws 2-3 spinning leaves that fly out and return | duck the way out, jump the way back |
| **Dive** | 1 | leaps high, hangs, dives diagonally at Ivo | move out, punish the landing |
| **Scatter** | 2 | bursts into leaves and reforms behind Ivo, then sweeps | turn and jump |

### Sun Guardian (summer, the stone lion: charges, fire, heat)
| Move | Stage | What it does | How to dodge |
|---|---|---|---|
| Claw | 0 | as today, now claw, claw, **bite lunge** | |
| Charge | 0 | as today; from stage 1 it bounces off the wall and comes back | |
| Roar | 0 | as today | |
| **Ember spit** | 0 | spits 3 embers in arcs; each burns the floor for 1.5 s | stand between |
| **Sun shafts** | 1 | rears; columns of light burn the floor in sequence, lit first | read the order |
| **Pounce slam** | 1 | leaps at Ivo's spot, lands with a burst of embers | |

### The mentor (the final battle)
Design 02 §5.1 says his pressure starts "só o padrão de Inverno, lento e pesado". Proposal: keep the first part heavy, but with strings and the Frost kit's floor control (ice wave, icicles), so it is the hardest winter. After the revelation (spring joins) he takes the Bloom kit's thorn row and pounce too; in stage 2 all at once: the game's hardest pressure.

## Art

About 4-5 new strips per guardian (new moves, wind-ups, recoveries) plus projectile and hazard sprites: about 25 strips and 10 effect sprites, about 70 PixelLab calls in all. A contract in `tools/art/prompts/` first, your approval of each guardian's sheet before it is wired. Until then each new move plays placeholder frames cut from the existing strips, so the code can be built and played first.

## Difficulty

Ivo has 3 life notes and every hit takes 1. With faster fights that leaves little room; the board keeps damage at 1 and makes every move readable (wind-up pose, a glint or a shadow before anything from above) with a clear punish window after it.
