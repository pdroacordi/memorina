class_name DoorLinks
extends RefCounted
## Checks that every door link joins exactly two doors in two rooms of one region, each naming the other's room.


## One message per broken pair; empty when every link is whole.
static func problems(records: Array[Record]) -> PackedStringArray:
	var by_link: Dictionary[StringName, Array] = {}
	for record: Record in records:
		if not by_link.has(record.link):
			by_link[record.link] = []
		by_link[record.link].append(record)
	var found := PackedStringArray()
	for link: StringName in by_link:
		var pair: Array = by_link[link]
		if pair.size() != 2:
			found.append("link %s is used by %d doors, not 2: %s" % [link, pair.size(), _sources(pair)])
			continue
		var a: Record = pair[0]
		var b: Record = pair[1]
		if a.room == b.room:
			found.append("link %s joins room %s to itself: %s" % [link, a.room, _sources(pair)])
			continue
		if a.region != b.region:
			found.append("link %s crosses regions %s and %s: %s" % [link, a.region, b.region, _sources(pair)])
		if a.to_room != b.room:
			found.append("%s: link %s leads to %s, but its partner is in %s" % [a.source, link, a.to_room, b.room])
		if b.to_room != a.room:
			found.append("%s: link %s leads to %s, but its partner is in %s" % [b.source, link, b.to_room, a.room])
	return found

static func _sources(pair: Array) -> String:
	var names := PackedStringArray()
	for record: Record in pair:
		names.append(record.source)
	return ", ".join(names)


## One door as a room file declares it.
class Record:
	var room: StringName
	var region: StringName
	var link: StringName
	var to_room: StringName
	## Where it was declared, for the message.
	var source: String

	func _init(in_room: StringName, in_region: StringName, in_link: StringName, in_to_room: StringName, in_source: String) -> void:
		room = in_room
		region = in_region
		link = in_link
		to_room = in_to_room
		source = in_source
