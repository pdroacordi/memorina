class_name DissonanceFxTest extends GdUnitTestSuite

## DissonanceFx shows the veil only while the veil or the revelation is above zero (GRD-06). The globals it writes are
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
