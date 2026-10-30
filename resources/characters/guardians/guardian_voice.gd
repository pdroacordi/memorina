class_name GuardianVoice
extends Resource
## A guardian's words: its speaker, a bark per lucid window and its talks after restoration (systems/guardians, "Talks").

@export var speaker: Speaker
## One text key per cure step, said as the leap lands; size = `GuardianStats.cycles_to_restore`.
@export var lucid_barks: Array[String] = []
## Said instead after a failed answer.
@export var retry_bark: String = ""
## Must be in the DialogueCatalog; its first dialogue is gated on GUARDIAN_RESTORED.
@export var talks: DialogueSet


## The key said as the window after `cycle` good answers opens.
func bark_for(cycle: int, after_failure: bool) -> String:
	if after_failure and not retry_bark.is_empty():
		return retry_bark
	if lucid_barks.is_empty():
		return ""
	return lucid_barks[clampi(cycle, 0, lucid_barks.size() - 1)]
