class_name GuardianMoveGraph
extends RefCounted
## Every move a guardian can throw: its roots, their links (transitively) and the Finale's revealed moves, deduped.


static func moves(stats: GuardianStats) -> Array[GuardianAttack]:
	var found: Array[GuardianAttack] = []
	var roots: Array[GuardianAttack] = stats.attacks.duplicate()
	if stats.finale != null:
		roots.append_array(stats.finale.revealed_attacks)
	for root: GuardianAttack in roots:
		_visit(root, found)
	return found

## The moves `attack` may chain into, itself included for a link with no attack.
static func links_of(attack: GuardianAttack) -> Array[GuardianAttack]:
	var links: Array[GuardianAttack] = []
	for follow_up: GuardianFollowUp in attack.follow_ups:
		if follow_up == null:
			continue
		links.append(follow_up.attack if follow_up.attack != null else attack)
	return links

## The longest string from `attack`, in moves, the first included; more than MAX_LINKS once it exceeds the cap or
## loops through other moves. A repeat of the same move is left to `max_links`.
static func longest_string(attack: GuardianAttack, depth: int = 1) -> int:
	if depth > GuardianRepertoire.MAX_LINKS:
		return depth
	var longest := depth
	for link: GuardianAttack in links_of(attack):
		if link == attack:
			continue
		longest = maxi(longest, longest_string(link, depth + 1))
	return longest

static func _visit(attack: GuardianAttack, found: Array[GuardianAttack]) -> void:
	if attack == null or found.has(attack):
		return
	found.append(attack)
	for link: GuardianAttack in links_of(attack):
		_visit(link, found)
