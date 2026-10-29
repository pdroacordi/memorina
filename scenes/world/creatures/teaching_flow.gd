class_name TeachingFlow extends RefCounted

## A teaching creature's states and clock; the creature only relays (systems/teaching-creatures).

## The teacher sings: `interval` seconds per note after `lead_in` seconds; `duet` adds Ivo's voice.
signal sing_requested(interval: float, lead_in: float, duet: bool)
signal sing_stopped
## The balloon opens with its glyphs hidden; `lit_as_sung` lights each as it is revealed.
signal balloon_shown(lit_as_sung: bool)
signal revealed(index: int)
## All glyphs show; the first `count` are lit.
signal lit(count: int)
signal shaken
## The balloon closes after `linger` seconds.
signal balloon_closed(linger: float)
## The half should be saved now; answer with learned().
signal learn_requested
signal flourished

enum State { AWAY, SINGING, LISTENING, DUET, FLOURISH, TAUGHT_QUIET, TAUGHT_SINGING }

## Seconds before the duet, so Ivo's last echoed note rings out.
const DUET_LEAD_IN := 0.5

var _lesson: CreatureLesson
var _state := State.TAUGHT_QUIET
var _near: bool = false
var _teachable: bool = false
var _busy: bool = false
## Echo notes Ivo has played right.
var _count: int = 0
## A mistake was heard; the next phrase waits for echo_reset().
var _awaiting_reset: bool = false
## Seconds left on the current wait (repeat in LISTENING, linger in FLOURISH).
var _wait: float = 0.0


func _init(lesson: CreatureLesson) -> void:
	_lesson = lesson

func state() -> State:
	return _state

func set_near(near: bool) -> void:
	_near = near
	if not near:
		_go_silent()

func set_busy(busy: bool) -> void:
	_busy = busy
	if busy:
		_go_silent()

func set_teachable(teachable: bool) -> void:
	if teachable == _teachable:
		return
	_teachable = teachable
	match _state:
		State.DUET, State.FLOURISH:
			# The half being learned decides; learned() and the linger end these.
			return
		State.SINGING, State.LISTENING, State.TAUGHT_SINGING:
			_close()
	_state = State.AWAY if teachable else State.TAUGHT_QUIET

## Ivo drew the Memorina; once taught, a draw near it brings the phrase back.
func drawn() -> void:
	if _state != State.TAUGHT_QUIET or not _near or _busy:
		return
	_state = State.TAUGHT_SINGING
	balloon_shown.emit(true)
	sing_requested.emit(_lesson.note_interval, _lesson.lead_in, false)

## The teacher's own voice sounded note `index` of the phrase.
func note_sung(index: int) -> void:
	if _state in [State.SINGING, State.TAUGHT_SINGING]:
		revealed.emit(index)

func phrase_sung() -> void:
	match _state:
		State.SINGING:
			_state = State.LISTENING
			_wait = _lesson.repeat_after
		State.TAUGHT_SINGING:
			_state = State.TAUGHT_QUIET
			balloon_closed.emit(_lesson.after_linger)
		State.DUET:
			balloon_closed.emit(0.0)
			learn_requested.emit()

## Ivo played the next note of the phrase.
func note_echoed() -> void:
	if _state == State.SINGING:
		sing_stopped.emit()
		_state = State.LISTENING
	elif _state != State.LISTENING:
		return
	_awaiting_reset = false
	_count += 1
	lit.emit(_count)

func echo_failed() -> void:
	if _state == State.SINGING:
		sing_stopped.emit()
		_state = State.LISTENING
	elif _state != State.LISTENING:
		return
	_count = 0
	_awaiting_reset = true
	shaken.emit()
	lit.emit(0)

## The instrument was sheathed mid-echo: its progress is gone, so the balloon unlights and the repeat clock restarts.
func echo_cleared() -> void:
	if _state != State.LISTENING or _count == 0:
		return
	_count = 0
	_wait = _lesson.repeat_after
	lit.emit(0)

## The mistake was heard out: sing again, slower.
func echo_reset() -> void:
	if _state != State.LISTENING or not _awaiting_reset:
		return
	_awaiting_reset = false
	_sing(_lesson.retry_interval, 0.0)

## The phrase was echoed whole; `completes` says the half makes the song whole.
func echoed(completes: bool) -> void:
	if _state != State.LISTENING and _state != State.SINGING:
		return
	sing_stopped.emit()
	lit.emit(SongHalves.HALF_LENGTH)
	if completes:
		_state = State.DUET
		sing_requested.emit(_lesson.note_interval, DUET_LEAD_IN, true)
		return
	_state = State.FLOURISH
	learn_requested.emit()

## The answer to learn_requested: whether the half was saved.
func learned(ok: bool) -> void:
	if _state != State.FLOURISH and _state != State.DUET:
		return
	if not ok:
		_state = State.AWAY
		_count = 0
		if _near and not _busy and _teachable:
			_sing(_lesson.note_interval, 0.0)
		else:
			balloon_closed.emit(0.0)
		return
	if _state == State.DUET:
		_settle()
		return
	flourished.emit()
	balloon_closed.emit(_lesson.flourish_linger)
	_wait = _lesson.flourish_linger

func tick(delta: float) -> void:
	match _state:
		State.AWAY:
			if _teachable and _near and not _busy:
				_sing(_lesson.note_interval, _lesson.lead_in)
		State.LISTENING:
			if _count > 0 or _awaiting_reset:
				return
			_wait -= delta
			if _wait <= 0.0:
				_sing(_lesson.note_interval, 0.0)
		State.FLOURISH:
			_wait -= delta
			if _wait <= 0.0:
				_settle()

func _sing(interval: float, lead_in: float) -> void:
	_state = State.SINGING
	_count = 0
	_awaiting_reset = false
	balloon_shown.emit(false)
	sing_requested.emit(interval, lead_in, false)

## Out of reach or busy: the phrase stops and the balloon closes; a duet interrupted teaches nothing.
func _go_silent() -> void:
	match _state:
		State.SINGING, State.LISTENING, State.DUET:
			_close()
			_state = State.AWAY if _teachable else State.TAUGHT_QUIET
		State.TAUGHT_SINGING:
			_close()
			_state = State.TAUGHT_QUIET

func _close() -> void:
	_count = 0
	_awaiting_reset = false
	sing_stopped.emit()
	balloon_closed.emit(0.0)

func _settle() -> void:
	_count = 0
	_state = State.AWAY if _teachable else State.TAUGHT_QUIET
