extends RefCounted
class_name WebSupport

## Browser presentation uses CSS pixels, independently of native Portrait.
static func is_enabled() -> bool:
	return OS.has_feature("web") or "--web-preview" in OS.get_cmdline_user_args()


static func density_context() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var dimensions: Variant = JSON.parse_string(str(JavaScriptBridge.eval(
		"JSON.stringify([window.innerWidth, window.innerHeight])", true)))
	if not dimensions is Array or dimensions.size() != 2:
		return {}
	return {
		"web_css_viewport_width": maxf(1.0, float(dimensions[0])),
		"web_css_viewport_height": maxf(1.0, float(dimensions[1])),
	}


static func is_narrow(control: Control) -> bool:
	return is_enabled() and control.get_viewport_rect().size.x < 960.0


static func augment_density_context(context: Dictionary) -> Dictionary:
	context.merge(density_context())
	return context


static func configure(scene: Control) -> void:
	if not is_enabled() or scene.get_node_or_null("MobileScrollGestures") != null or scene.get_node_or_null("WebScrollGestures") != null:
		return
	# Reuse gesture arbitration so swiping across fields does not activate them.
	Input.emulate_mouse_from_touch = true
	var gestures := preload("res://platform/mobile/MobileScrollGestures.gd").new()
	gestures.name = "WebScrollGestures"
	scene.add_child(gestures)
