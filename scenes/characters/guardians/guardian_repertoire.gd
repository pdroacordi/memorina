class_name GuardianRepertoire
extends RefCounted
## Which moves a guardian may throw at its cure stage, and which link follows a strike; pure, used by GuardianAI.

## Moves in one string, the first included, whatever a stage asks.
const MAX_LINKS := 4


## The moves that have joined the set by `stage`, in their authored order.
static func available(attacks: Array[GuardianAttack], stage: int) -> Array[GuardianAttack]:
	var joined: Array[GuardianAttack] = []
	for attack: GuardianAttack in attacks:
		if attack.from_stage <= stage:
			joined.append(attack)
	return joined

## The link after `move`'s strike, or null to end the string; `links_done` counts its moves so far, the first included.
## `in_range(attack)` and `roll()` (0..1) are asked only for an eligible link, and `roll` only for an uncertain chance.
## `recall_owned`: the player owns the recall's skill, so a recall move that left the cadence may chain.
static func next_link(move: GuardianAttack, stage: int, chain_scale: float, links_done: int, max_links: int,
		in_range: Callable, at_wall: bool, recall_requested: bool, roll: Callable,
		recall_owned: bool = false) -> GuardianAttack:
	if move == null or recall_requested or links_done >= mini(max_links, MAX_LINKS):
		return null
	# A recall move chains only once it no longer teaches: while it does, its end resets the recall cadence.
	if move.recall != null and not (recall_owned and move.leaves_cadence_when_owned()):
		return null
	for follow_up: GuardianFollowUp in move.follow_ups:
		if follow_up == null or follow_up.from_stage > stage:
			continue
		var link := follow_up.attack if follow_up.attack != null else move
		if link.from_stage > stage or link.recall != null:
			continue
		if follow_up.needs_wall and not at_wall:
			continue
		if not in_range.call(link):
			continue
		var chance := clampf(follow_up.chance * chain_scale, 0.0, 1.0)
		if chance <= 0.0:
			continue
		if chance >= 1.0 or float(roll.call()) < chance:
			return link
	return null
