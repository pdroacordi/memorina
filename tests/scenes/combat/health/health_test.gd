class_name HealthTest extends GdUnitTestSuite

## Health.reset() must emit the heal event used by the life HUD.

var _health: Health

func before_test() -> void:
	_health = auto_free(Health.new())
	_health.max_hp = 3
	add_child(_health)

func test_reset_announces_the_heal() -> void:
	_health.take_damage(2)
	var heals: Array = []
	_health.healed.connect(func(amount: int, current: int) -> void: heals.append([amount, current]))
	_health.reset()
	assert_int(_health.current_hp).is_equal(3)
	assert_array(heals).is_equal([[2, 3]])

func test_reset_at_full_is_silent() -> void:
	var heals: Array = []
	_health.healed.connect(func(amount: int, current: int) -> void: heals.append([amount, current]))
	_health.reset()
	assert_array(heals).is_empty()

func test_death_is_announced_once() -> void:
	var deaths: Array = []
	_health.died.connect(func() -> void: deaths.append(true))
	_health.take_damage(3)
	_health.take_damage(1)
	assert_int(deaths.size()).is_equal(1)
