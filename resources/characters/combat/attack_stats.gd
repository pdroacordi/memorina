class_name AttackStats
extends Resource
## One combo sequence as an ordered list of phases. Adding a phase to a combo
## is appending an AttackPhaseData entry here plus authoring one more state in
## the AnimationTree - AttackComponent itself never changes. A single-phase
## array (e.g. a jump or fall attack) needs no special-casing: it simply has
## nowhere to chain to.

@export var phases: Array[AttackPhaseData] = []
