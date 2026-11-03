class_name MusicRequests
extends RefCounted
## The open music requests; the highest layer plays, the newest wins a tie (architecture/music-system).

var _open: Array[MusicRequest] = []
var _serial: int = 0


func add(request: MusicRequest) -> MusicRequest:
	_serial += 1
	request.serial = _serial
	_open.append(request)
	return request

func remove(request: MusicRequest) -> void:
	_open.erase(request)

## Drops the requests whose owner left the tree; returns whether any dropped.
func prune() -> bool:
	var before := _open.size()
	_open = _open.filter(func(r: MusicRequest) -> bool: return r.is_alive())
	return _open.size() != before

## The request that plays, or null.
func top() -> MusicRequest:
	var best: MusicRequest = null
	for request: MusicRequest in _open:
		if best == null or request.layer > best.layer or (request.layer == best.layer and request.serial > best.serial):
			best = request
	return best

func has(request: MusicRequest) -> bool:
	return _open.has(request)

func size() -> int:
	return _open.size()
