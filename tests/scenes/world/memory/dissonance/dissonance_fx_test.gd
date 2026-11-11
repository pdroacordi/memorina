class_name DissonanceFxTest extends GdUnitTestSuite

## DissonanceFx shows the veil and its screen copy only while the veil or the revelation is above zero (GRD-06, TECH-12). The globals it writes are
## not readable outside the editor (RenderingServer.global_shader_parameter_get), so only the veil is checked here.


func test_it_shows_the_veil_only_while_dissonant() -> void:
	var veil := auto_free(ColorRect.new()) as ColorRect
	add_child(veil)
	var fx := auto_free(DissonanceFx.new()) as DissonanceFx
	add_child(fx)
	fx.set(&"_veil", veil)
	fx.set_dissonance(0.4, 0.0)
	assert_bool(veil.visible).is_true()
	fx.set_dissonance(0.0, 0.0)
	assert_bool(veil.visible).is_false()
	fx.set_dissonance(0.0, 0.7)
	assert_bool(veil.visible).is_true()

## The copy reads the whole screen every frame it shows, so it hides with the veil (TECH-12).
func test_it_shows_the_screen_copy_only_with_the_veil() -> void:
	var copy := auto_free(BackBufferCopy.new()) as BackBufferCopy
	add_child(copy)
	var fx := auto_free(DissonanceFx.new()) as DissonanceFx
	add_child(fx)
	fx.set(&"_copy", copy)
	fx.set_dissonance(0.0, 0.0)
	assert_bool(copy.visible).is_false()
	fx.set_dissonance(0.3, 0.0)
	assert_bool(copy.visible).is_true()
	fx.set_dissonance(0.0, 0.0)
	assert_bool(copy.visible).is_false()
	fx.set_dissonance(0.0, 1.0)
	assert_bool(copy.visible).is_true()
