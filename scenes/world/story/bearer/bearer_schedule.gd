class_name BearerSchedule
extends RefCounted
## Whether a bearer fragment is due: its guardian restored and its engraving not yet seen
## (architecture/story-04-bearer-fragments, "Seen").

## The SCENE_SEEN id of a guardian's fragment, recorded by its engraving scene.
const ID_FORMAT := "bearer_%s"


static func due(data: PlayerData, fragment: BearerFragment) -> bool:
	if data == null or fragment == null or fragment.engraving == null:
		return false
	return SaveFact.check(SaveFact.Kind.GUARDIAN_RESTORED, fragment.guardian, data) \
			and not data.scenes_seen.has(fragment.engraving.id)

static func id(guardian: Enums.Guardian) -> StringName:
	return StringName(ID_FORMAT % String(Enums.Guardian.keys()[guardian]).to_lower())
