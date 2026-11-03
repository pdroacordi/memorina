extends Node
## Plays the top music request on two crossfading decks; knows no game rules (architecture/music-system).

## A deck at or below this gain is stopped, linear.
const SILENT_GAIN := 0.001
## The live deck, one fading out and one released one-shot ringing to its end.
const DECKS := 3

var _requests := MusicRequests.new()
var _mix := MusicMix.new()
var _decks: Array[Deck] = []
## The deck playing the top request; the other one is fading out or idle.
var _live: Deck
var _hushed: bool = false
var _last_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in DECKS:
		var deck := Deck.new()
		deck.player = AudioStreamPlayer.new()
		deck.player.bus = AudioBuses.MUSIC
		add_child(deck.player)
		deck.player.finished.connect(_on_finished.bind(deck))
		_decks.append(deck)
	_last_usec = Time.get_ticks_usec()

## Asks for `cue` at `layer` for as long as `owner` stays in the tree.
func request(cue: MusicCue, layer: MusicRequest.Layer, owner: Node) -> MusicRequest:
	var made := _requests.add(MusicRequest.new(cue, layer, owner))
	_refresh()
	return made

## Ends a request; a looping cue fades over `fade` real seconds (negative: the cue's own), a one-shot rings out.
func release(request: MusicRequest, fade: float = -1.0) -> void:
	if request == null or not _requests.has(request):
		return
	_requests.remove(request)
	if _live != null and _live.request == request:
		_retire(_live, fade)
		_live = null
	else:
		# Already displaced by a newer request: the fade asked here still applies.
		for deck: Deck in _decks:
			if deck != _live and deck.request == request:
				_retire(deck, fade)
	_refresh()

## Moves a stem of `request` to `level` (0..1) over `seconds` real seconds.
func set_stem(request: MusicRequest, stem: StringName, level: float, seconds: float) -> void:
	if request == null:
		return
	request.levels[stem] = level
	if _live != null and _live.request == request:
		_mix.set_stem(stem, level, seconds)

## Holds the Music bus `db` lower while `id` is open; the deepest duck wins.
func duck(id: StringName, db: float) -> void:
	_mix.duck(id, db)

func unduck(id: StringName) -> void:
	_mix.unduck(id)

## Pauses every deck where it stands (the freeze frame); unhush resumes from the same sample.
func hush() -> void:
	_hushed = true

func unhush() -> void:
	_hushed = false

## Seconds into the playing cue, or 0.
func position() -> float:
	return _live.player.get_playback_position() if _live != null and _live.player.playing else 0.0

## The playing request, or null.
func playing() -> MusicRequest:
	return _live.request if _live != null else null

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real := (now - _last_usec) / 1_000_000.0
	_last_usec = now
	var paused := WorldFreeze.is_held() or _hushed
	for deck: Deck in _decks:
		deck.player.stream_paused = paused
	if paused:
		return
	if _requests.prune():
		if _live != null and not _requests.has(_live.request):
			_retire(_live, -1.0)
			_live = null
		_refresh()
	_mix.step(real)
	for deck: Deck in _decks:
		deck.step(real)
		_apply(deck)

func _refresh() -> void:
	var top := _requests.top()
	if top == null:
		return
	if _live != null:
		if _live.request == top:
			return
		if _live.request.cue == top.cue:
			_live.request = top
			return
		_retire(_live, -1.0)
	_live = _start(top)

func _start(request: MusicRequest) -> Deck:
	var deck := _free_deck()
	deck.request = request
	deck.ringing = false
	_mix.reset(request.cue)
	for stem: StringName in request.levels:
		_mix.set_stem(stem, request.levels[stem], 0.0)
	# A per-play copy, so stem volumes never write the shared resource.
	deck.player.stream = request.cue.stream.duplicate() if request.cue.stream != null else null
	deck.gain = 0.0 if request.cue.fade_in > 0.0 else 1.0
	deck.target = 1.0
	deck.rate = 1.0 / request.cue.fade_in if request.cue.fade_in > 0.0 else INF
	if deck.player.stream != null:
		deck.player.play()
	_apply(deck)
	return deck

func _retire(deck: Deck, fade: float) -> void:
	var cue := deck.request.cue if deck.request != null else null
	if fade < 0.0 and cue != null and not cue.loops:
		deck.ringing = true
		return
	var seconds := fade if fade >= 0.0 else (cue.fade_out if cue != null else 0.0)
	deck.target = 0.0
	deck.rate = 1.0 / seconds if seconds > 0.0 else INF

func _free_deck() -> Deck:
	for deck: Deck in _decks:
		if deck != _live and not deck.player.playing:
			return deck
	# All busy: cut a fading deck before a ringing one-shot.
	for ringing_too: bool in [false, true]:
		for deck: Deck in _decks:
			if deck != _live and deck.ringing == ringing_too:
				deck.player.stop()
				return deck
	return _decks[0]

func _apply(deck: Deck) -> void:
	if not deck.player.playing:
		return
	if deck == _live and deck.player.stream is AudioStreamSynchronized:
		var sync := deck.player.stream as AudioStreamSynchronized
		var stems := deck.request.cue.stems
		for i: int in stems.size():
			sync.set_sync_stream_volume(i, _mix.stem_db(stems[i]))
	var gain_db := MusicMix.SILENT_DB if deck.gain <= SILENT_GAIN else linear_to_db(deck.gain)
	deck.player.volume_db = gain_db + _mix.duck_db()
	if deck.gain <= SILENT_GAIN and deck.target <= 0.0 and not deck.ringing:
		deck.player.stop()
		deck.request = null

func _on_finished(deck: Deck) -> void:
	if deck != _live:
		deck.ringing = false
		deck.request = null
		return
	# A one-shot cue reached its end while still on top: its request is done.
	_requests.remove(deck.request)
	deck.request = null
	_live = null
	_refresh()


class Deck:
	var player: AudioStreamPlayer
	var request: MusicRequest
	## Linear 0..1 deck gain and where it is heading.
	var gain: float = 0.0
	var target: float = 0.0
	## Gain change per real second; INF jumps.
	var rate: float = 0.0
	## A released one-shot left to play to its end.
	var ringing: bool = false

	func step(delta: float) -> void:
		gain = target if is_inf(rate) else move_toward(gain, target, rate * delta)
