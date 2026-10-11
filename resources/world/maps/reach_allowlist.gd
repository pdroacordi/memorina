class_name ReachAllowlist extends Resource

## The reachability errors room_reach_test accepts; each entry must still match a finding.

const DEFAULT_PATH := "res://resources/world/maps/reach_allowlist.tres"

@export var entries: Array[ReachAllowlistEntry] = []

static func load_default() -> ReachAllowlist:
	return load(DEFAULT_PATH) as ReachAllowlist

func allows(finding: ReachFinding) -> bool:
	for entry: ReachAllowlistEntry in entries:
		if entry.matches(finding):
			return true
	return false
