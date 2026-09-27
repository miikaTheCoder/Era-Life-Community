extends SceneTree

# Exercise the real navigation refresh while an input is held. World generation
# is unrelated to focus ownership, so this scene only installs the relevant UI.
class NavigationScene extends "res://scenes/MainScene.gd":
	var commands := 0
	var navigation_shown := true
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _input(_event) -> void:
		pass
	func _unhandled_input(_event: InputEvent) -> void:
		pass
	func _notification(_what: int) -> void:
		pass
	func _active_reality_presentation_contract() -> Dictionary:
		return {"navigation_visibility":{"age_up":navigation_shown}}
	func _god_mode_ui_locked() -> bool:
		return false
	func _standard_tabs_locked() -> bool:
		return false
	func _ui_nav_button_theme_tokens(_key: String, _state: String, _pulse_strength: float = 0.0, _disabled: bool = false) -> Dictionary:
		return {}
	func _on_button_pressed() -> void:
		commands += 1

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = root.get_final_transform() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	root.size = Vector2i(800, 600)
	root.content_scale_size = Vector2i(800, 600)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var host := NavigationScene.new()
	var container := Control.new()
	container.name = "UIContainer"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var output := RichTextLabel.new()
	output.name = "OutputLabel"
	output.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(output)
	host.add_child(container)
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var adapter = load("res://ui/EraInterface.gd").new()
	adapter.name = "EraInterface"
	host.add_child(adapter)
	var button := Button.new()
	button.text = "AGE UP"
	button.position = Vector2(100, 100)
	button.size = Vector2(200, 64)
	host.add_child(button)
	host._register_ui_nav_button(button)
	await process_frame
	await process_frame
	for attempt in range(2):
		adapter._style_button(button)
		var center := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = root.get_final_transform() * center
		Input.parse_input_event(motion)
		await _mouse(center, true)
		_check(button.button_pressed, "Age Up did not receive mouse down")
		host._apply_ui_nav_button_visuals()
		_check(root.gui_get_focus_owner() == button, "Navigation refresh stole mouse focus")
		_check(button.button_pressed, "Navigation refresh cancelled the held mouse press")
		await _mouse(center, false)
		_check(host.commands == attempt + 1, "A repeated Age Up click did not produce exactly one command")
	adapter._style_button(button)
	button.grab_focus()
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	host._apply_ui_nav_button_visuals()
	_check(root.gui_get_focus_owner() == button and button.button_pressed, "Navigation refresh cancelled keyboard input")
	accept = InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = false
	Input.parse_input_event(accept)
	await process_frame
	_check(host.commands == 3, "Keyboard activation did not produce exactly one command")
	host.navigation_shown = false
	host._apply_ui_nav_button_visuals()
	_check(not button.visible and button.disabled and button.focus_mode == Control.FOCUS_NONE, "Hidden navigation remained interactive")
	host.queue_free()
	await process_frame
	print("NAVIGATION INPUT TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
