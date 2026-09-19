extends RefCounted
class_name MobileSupport

const LOGICAL_WIDTH := 420.0
const REFERENCE_HEIGHT := 840.0

## Platform adaptations only; simulation and save ownership stay with the game.
## --mobile-preview exercises the same layout on a desktop development machine.
static func is_enabled() -> bool:
	return OS.has_feature("android") or "--mobile-preview" in OS.get_cmdline_user_args()


static func logical_viewport_size(physical_size: Vector2) -> Vector2:
	var physical := Vector2(maxf(1.0, physical_size.x), maxf(1.0, physical_size.y))
	return Vector2(LOGICAL_WIDTH, LOGICAL_WIDTH * physical.y / physical.x)


static func configure_viewport(scene: Control) -> void:
	if not is_enabled() or not is_instance_valid(scene):
		return
	var window := scene.get_window()
	if window == null:
		return
	var logical := logical_viewport_size(Vector2(window.size))
	var target := Vector2i(roundi(logical.x), maxi(1, roundi(logical.y)))
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.content_scale_factor = 1.0
	if window.content_scale_size != target:
		window.content_scale_size = target
		_reveal_focused_control.call_deferred(scene)
	var resized := configure_viewport.bind(scene)
	if not scene.resized.is_connected(resized):
		scene.resized.connect(resized)


static func _reveal_focused_control(scene: Control) -> void:
	if not is_instance_valid(scene) or not scene.is_inside_tree():
		return
	# Keyboard resizing changes the form after focus was first acquired.
	var tree := scene.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(scene):
		return
	var focus := scene.get_viewport().gui_get_focus_owner()
	if focus == null:
		return
	var parent := focus.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(focus)
		parent = parent.get_parent()


static func project_safe_area(logical_size: Vector2, physical_size: Vector2, physical_safe_area: Rect2) -> Rect2:
	var full := Rect2(Vector2.ZERO, logical_size)
	if physical_size.x <= 0 or physical_size.y <= 0 or not physical_safe_area.has_area():
		return full
	var clipped := physical_safe_area.intersection(Rect2(Vector2.ZERO, physical_size))
	if not clipped.has_area():
		return full
	var scale := logical_size / physical_size
	return Rect2(clipped.position * scale, clipped.size * scale)


static func safe_viewport_rect(scene: Control) -> Rect2:
	var logical_size := scene.get_viewport_rect().size
	if not OS.has_feature("android"):
		return Rect2(Vector2.ZERO, logical_size)
	var window := scene.get_window()
	var physical_safe := Rect2(DisplayServer.get_display_safe_area())
	physical_safe.position -= Vector2(window.position)
	return project_safe_area(logical_size, Vector2(window.size), physical_safe)


static func configure(scene: Control) -> void:
	if not is_enabled():
		return
	configure_viewport(scene)
	scene.get_tree().quit_on_go_back = false
	Input.emulate_mouse_from_touch = true
	Engine.max_fps = 60
	if scene.get_node_or_null("MobileScrollGestures") == null:
		var gestures := preload("res://platform/mobile/MobileScrollGestures.gd").new()
		gestures.name = "MobileScrollGestures"
		scene.add_child(gestures)


static func handle_back(scene: Control) -> void:
	# Close the keyboard before navigating away from an edited field.
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) and DisplayServer.virtual_keyboard_get_height() > 0:
		DisplayServer.virtual_keyboard_hide()
		var focus := scene.get_viewport().gui_get_focus_owner()
		if focus != null:
			focus.release_focus()
		return

	# Embedded menus/dialogs are Windows, not Controls.
	for window in scene.get_viewport().get_embedded_subwindows():
		if window.visible:
			window.hide()
			return
	var account := scene.get("title_card_account_popup") as Control
	if is_instance_valid(account) and account.is_visible_in_tree():
		scene.call("_close_title_card_account_panel")
		return

	var intro := scene.get("startup_intro_overlay") as Control
	if is_instance_valid(intro) and intro.is_visible_in_tree():
		if not bool(scene.get("startup_intro_accepting_input")):
			scene.call("_skip_startup_intro_to_title_card")
			return

	var shell := scene.get_node_or_null("EraShell")
	if shell != null and shell.has_method("handle_mobile_back") and bool(shell.call("handle_mobile_back")):
		return

	# Route through existing close signals so each panel performs its own cleanup.
	var panels: Array[Control] = []
	_collect_closable_panels(scene, panels)
	var topmost: Control = null
	var top_z := -100000
	for panel in panels:
		var draw_z := _effective_z(panel)
		if draw_z >= top_z:
			topmost = panel
			top_z = draw_z
	if topmost != null:
		topmost.emit_signal("close_requested")
		return

	var dialog := scene.get_node_or_null("MobileExitConfirmation") as ConfirmationDialog
	if dialog == null:
		dialog = ConfirmationDialog.new()
		dialog.name = "MobileExitConfirmation"
		dialog.title = "Exit Era Life?"
		dialog.dialog_text = "Unsaved progress will be lost.\nUse the game's Save action before exiting."
		dialog.get_ok_button().text = "Exit"
		dialog.get_cancel_button().text = "Keep playing"
		dialog.confirmed.connect(scene.get_tree().quit)
		scene.add_child(dialog)
		dialog.get_ok_button().custom_minimum_size.y = 52
		dialog.get_cancel_button().custom_minimum_size.y = 52
	var safe := safe_viewport_rect(scene)
	var dialog_size := Vector2(minf(380.0, safe.size.x - 32.0), 200.0)
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size.x = maxf(1.0, dialog_size.x - 32.0)
	dialog.popup(Rect2i(Vector2i(safe.position + (safe.size - dialog_size) * 0.5), Vector2i(dialog_size)))


static func add_title_actions(scene: Control) -> void:
	if not is_enabled():
		return
	if not bool(scene.get_meta("startup_intro_title_card_visible_surface", false)):
		return
	var overlay := scene.get("startup_intro_overlay") as Control
	if overlay == null:
		return
	var actions := overlay.get_node_or_null("MobileAccountActions") as GridContainer
	if actions == null:
		actions = GridContainer.new()
		actions.columns = 2
		actions.name = "MobileAccountActions"
		overlay.add_child(actions)
		actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		actions.add_theme_constant_override("h_separation", 8)
		actions.add_theme_constant_override("v_separation", 8)
		for label in ["Create account", "Log in", "Continue", "Disconnect"]:
			var button := Button.new()
			button.name = label.replace(" ", "")
			button.text = label
			button.custom_minimum_size = Vector2(0, 48)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 16)
			match label:
				"Create account": button.pressed.connect(Callable(scene, "_open_title_card_account_panel").bind("signup"))
				"Log in": button.pressed.connect(Callable(scene, "_open_title_card_account_panel").bind("login"))
				"Continue": button.pressed.connect(Callable(scene, "_continue_title_card_current_life"))
				"Disconnect": button.pressed.connect(Callable(scene, "_disconnect_title_card_eralife_account"))
			actions.add_child(button)
	var safe := safe_viewport_rect(scene)
	actions.position = safe.position + Vector2(16, 16)
	actions.size = Vector2(maxf(1.0, safe.size.x - 32.0), 0)
	(actions.get_node("Continue") as Button).disabled = not bool(scene.call("_title_card_continue_available"))
	(actions.get_node("Disconnect") as Button).visible = not bool(scene.get_meta("title_card_player_is_guest", true))
	var prompt := scene.get("startup_intro_prompt_label") as Label
	if prompt != null:
		prompt.text = prompt.text.replace("Press A to create an ErAccount. Press L to log in.", "Account options are above.").replace("Press anywhere", "Tap anywhere").replace("Press C", "Tap Continue").replace("Press F", "Tap Disconnect")


static func adapt_form(node: Node) -> void:
	if not is_enabled():
		return
	if node is BaseButton or node is LineEdit or node is SpinBox:
		node.custom_minimum_size.y = maxf(node.custom_minimum_size.y, 56)
		node.add_theme_font_size_override("font_size", maxi(node.get_theme_font_size("font_size"), 20))
	if node is OptionButton:
		node.get_popup().add_theme_constant_override("v_separation", 18)
		node.get_popup().add_theme_font_size_override("font_size", 20)
	if node is ScrollContainer:
		node.follow_focus = true
	for child in node.get_children():
		adapt_form(child)


static func layout_life(scene: Control) -> void:
	# The portrait shell owns navigation containers, the diary, and progression.
	# It mounts deferred, so entry can legitimately precede its first layout.
	var shell := scene.get_node_or_null("EraShell")
	if shell != null and shell.has_method("layout_mobile"):
		shell.call("layout_mobile")


static func event_targets_title_actions(scene: Control, event: InputEvent) -> bool:
	if not is_enabled():
		return false
	var overlay := scene.get("startup_intro_overlay") as Control
	if not is_instance_valid(overlay):
		return false
	var actions := overlay.get_node_or_null("MobileAccountActions") as Control
	if actions == null or not actions.is_visible_in_tree():
		return false
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		return actions.get_global_rect().has_point(event.position)
	return false


static func _collect_closable_panels(node: Node, panels: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control:
			if not child.is_visible_in_tree():
				continue
			if child.has_signal("close_requested") and not child.get_signal_connection_list("close_requested").is_empty():
				panels.append(child)
		_collect_closable_panels(child, panels)


static func _effective_z(control: Control) -> int:
	var total := control.z_index
	var item: CanvasItem = control
	while item.z_as_relative and not item.is_set_as_top_level():
		item = item.get_parent() as CanvasItem
		if item == null:
			break
		total += item.z_index
	return total
