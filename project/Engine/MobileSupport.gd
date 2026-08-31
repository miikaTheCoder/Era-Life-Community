extends RefCounted
class_name MobileSupport

## Platform adaptations only; simulation and save ownership stay with the game.
## --mobile-preview exercises the same layout on a desktop development machine.
static func is_enabled() -> bool:
	return OS.has_feature("android") or "--mobile-preview" in OS.get_cmdline_user_args()


static func configure(scene: Control) -> void:
	if not is_enabled():
		return
	scene.get_tree().quit_on_go_back = false
	Input.emulate_mouse_from_touch = true
	Engine.max_fps = 60
	if scene.get_node_or_null("MobileScrollGestures") == null:
		var gestures := preload("res://Engine/MobileScrollGestures.gd").new()
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
	dialog.popup_centered(Vector2i(440, 180))


static func add_title_actions(scene: Control) -> void:
	if not is_enabled():
		return
	if not bool(scene.get_meta("startup_intro_title_card_visible_surface", false)):
		return
	var overlay := scene.get("startup_intro_overlay") as Control
	if overlay == null:
		return
	var actions := overlay.get_node_or_null("MobileAccountActions") as HBoxContainer
	if actions == null:
		actions = HBoxContainer.new()
		actions.name = "MobileAccountActions"
		overlay.add_child(actions)
		actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		actions.offset_left = -700
		actions.offset_right = -16
		actions.offset_top = 16
		actions.offset_bottom = 72
		actions.add_theme_constant_override("separation", 12)
		for label in ["Create account", "Log in", "Continue", "Disconnect"]:
			var button := Button.new()
			button.name = label.replace(" ", "")
			button.text = label
			button.custom_minimum_size = Vector2(162, 56)
			button.add_theme_font_size_override("font_size", 20)
			match label:
				"Create account": button.pressed.connect(Callable(scene, "_open_title_card_account_panel").bind("signup"))
				"Log in": button.pressed.connect(Callable(scene, "_open_title_card_account_panel").bind("login"))
				"Continue": button.pressed.connect(Callable(scene, "_continue_title_card_current_life"))
				"Disconnect": button.pressed.connect(Callable(scene, "_disconnect_title_card_eralife_account"))
			actions.add_child(button)
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
	var root := scene.get_node_or_null("UIContainer") as Control
	if root == null:
		return
	# Keep the existing stats and floating-action rails clear of the diary.
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 303
	root.offset_right = -112
	root.offset_top = 18
	root.offset_bottom = -18
	root.custom_minimum_size = Vector2.ZERO
	var navigation := root.get_node_or_null("MobileNavigation") as GridContainer
	if navigation == null:
		navigation = GridContainer.new()
		navigation.name = "MobileNavigation"
		navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_theme_constant_override("h_separation", 6)
		navigation.add_theme_constant_override("v_separation", 6)
		root.add_child(navigation)
		root.move_child(navigation, 0)
	navigation.columns = 4 if scene.get_viewport_rect().size.x >= 1100 else 3
	var buttons: Dictionary = scene.get("ui_nav_buttons")
	for value in buttons.values():
		var button := value as Button
		if button == null:
			continue
		if button.get_parent() != navigation:
			button.reparent(navigation)
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_FILL
		button.add_theme_font_size_override("font_size", 16)
	var diary := scene.get("output_label") as RichTextLabel
	if diary != null:
		diary.custom_minimum_size = Vector2.ZERO
		diary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		diary.fit_content = false
		diary.scroll_active = true


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
