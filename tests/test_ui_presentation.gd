extends SceneTree
## Regression: late contract styling cannot erase focus or change gameplay controls.
const Design = preload("res://ui/EraTheme.gd")
const Interface = preload("res://ui/EraInterface.gd")
const Shell = preload("res://ui/EraShell.gd")
const TOOL_KEYS := ["boxing", "belongings", "food_lifestyle", "restaurant_lifestyle", "rick_weapon_shop", "bending", "crown", "superpower", "power", "wizard"]
var failed := false

class RowStreamPanel extends InstitutionHubPanelBase:
	func _render_row_into(container: VBoxContainer, row: Dictionary) -> void:
		var label := Label.new()
		label.text = str(row.get("title", ""))
		container.add_child(label)

class Host extends Control:
	var gs = null
	var current_panel := "life"
	var startup_intro_title_label: Label
	var choose_adventure_entry_overlay: Control
	var choose_adventure_entry_shell: Container
	var output_label: RichTextLabel
	var ui_nav_buttons: Dictionary = {}
	var player_stats_overlay: Control
	var boxing_hud_button: Button
	var belongings_hud_button: Button
	var food_lifestyle_hud_button: Button
	var restaurant_lifestyle_hud_button: Button
	var rick_weapon_shop_hud_button: Button
	var bending_hud_button: Button
	var crown_hud_button: Button
	var superpower_hud_button: Button
	var power_hud_button: Button
	var wizard_hud_button: Button
	var crime_hud_button: Button
	var bending_hud_button_border_overlay: Control

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("UI PRESENTATION: " + message)

func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func _check_tool_rects(buttons: Array[Button], dimensions: Vector2i) -> void:
	for index in buttons.size():
		var button := buttons[index]
		var rect := button.get_global_rect()
		_check(rect.size.is_equal_approx(Vector2(112, 46)), "Shortcut changed size at " + str(dimensions) + ": " + buttons[index].text + " " + str(rect))
		_check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= dimensions.x and rect.end.y <= dimensions.y, "Shortcut escaped viewport at " + str(dimensions))
		var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		var padding_width := button.get_theme_stylebox("normal").get_minimum_size().x
		_check(text_width + padding_width <= rect.size.x, "Shortcut label is clipped at " + str(dimensions) + ": " + button.text + " needs " + str(text_width + padding_width) + "px")
		for other_index in range(index):
			var other_rect := buttons[other_index].get_global_rect()
			_check(not rect.intersects(other_rect), "Shortcuts overlap at " + str(dimensions))
			if rect.position.x < other_rect.end.x and other_rect.position.x < rect.end.x:
				_check(is_equal_approx(rect.end.x, other_rect.end.x), "Shortcut column has staggered right edges at " + str(dimensions))

func _test_tool_stability(host: Host, adapter: Node) -> void:
	var buttons: Array[Button] = []
	var invoked := [false]
	for key in TOOL_KEYS:
		var button := Button.new()
		button.name = key + "_shortcut"
		button.text = "🔫"
		button.set_meta("action_id", key + "_action")
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		host.set(key + "_hud_button", button)
		host.add_child(button)
		buttons.append(button)
	host.belongings_hud_button.pressed.connect(func(): invoked[0] = true)
	host.wizard_hud_button.disabled = true
	host.bending_hud_button_border_overlay = Control.new()
	host.bending_hud_button.add_child(host.bending_hud_button_border_overlay)
	await _settle()
	var shell: Node = adapter.shell
	var legacy := StyleBoxFlat.new()
	legacy.bg_color = Color.MAGENTA
	legacy.set_content_margin_all(12)
	for dimensions in [Vector2i(768, 1024), Vector2i(1280, 800), Vector2i(1920, 1080), Vector2i(768, 480)]:
		root.content_scale_size = dimensions
		await _settle()
		shell._layout_tools()
		await _settle()
		_check_tool_rects(buttons, dimensions)
		var settled_rects: Array[Rect2] = []
		for button in buttons:
			settled_rects.append(button.get_global_rect())
		for frame in range(8):
			# Runtime HUD refreshes still publish icon styles, including font size 28.
			# The new label must not expand at that old font size or retain shifted edges.
			for index in buttons.size():
				var button := buttons[index]
				button.text = "🔫"
				button.add_theme_font_size_override("font_size", 28)
				button.add_theme_stylebox_override("normal", legacy)
				button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				button.grow_vertical = Control.GROW_DIRECTION_BEGIN
				if frame % 3 == 0:
					Shell.layout_tool_button(button, index, Vector2(dimensions))
			host.bending_hud_button_border_overlay.visible = true
			shell._layout_tools()
			await _settle()
			_check_tool_rects(buttons, dimensions)
			for index in buttons.size():
				var button := buttons[index]
				_check(button.get_global_rect().is_equal_approx(settled_rects[index]), "Shortcut moved after legacy refresh: " + TOOL_KEYS[index])
				_check(button.text == button.get_meta("era_tool_label", ""), "Legacy icon replaced shortcut label")
				_check(button.get_meta("action_id") == TOOL_KEYS[index] + "_action", "Shortcut action identity changed")
			_check(host.wizard_hud_button.disabled, "Shortcut styling enabled an unavailable action")
			_check(not host.bending_hud_button_border_overlay.visible, "Legacy animated Bending border reappeared")
	host.bending_hud_button.visible = false
	host.bending_hud_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell._layout_tools()
	await _settle()
	_check(not host.bending_hud_button.visible, "Shortcut layout revived a hidden feature")
	_check(host.bending_hud_button.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Shortcut layout changed input ownership")
	host.belongings_hud_button.grab_focus()
	_check(root.gui_get_focus_owner() == host.belongings_hud_button, "Shortcut is not keyboard reachable")
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	accept = InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = false
	Input.parse_input_event(accept)
	await _settle()
	_check(invoked[0], "Shortcut keyboard activation lost the original action signal")
	for button in buttons:
		button.queue_free()
	await process_frame

func _test_detached_row_stream() -> void:
	var panel := RowStreamPanel.new()
	var container := VBoxContainer.new()
	var rows: Array = []
	for index in range(13):
		rows.append({"title": "Row %d" % index})
	# Section surfaces are built before being attached to their panel. Large
	# sections must yield without calling get_tree() on that detached container.
	panel._render_contract_rows_into(container, {"rows": rows})
	_check(container.get_child_count() > 0 and container.get_child_count() < rows.size(), "Detached rows did not begin with a bounded visible batch")
	for frame in range(5):
		await process_frame
	_check(container.get_child_count() == rows.size(), "Detached section lost its remaining rows")
	for index in range(container.get_child_count()):
		_check(container.get_child(index).text == "Row %d" % index, "Streamed rows changed order")
	for child in container.get_children():
		child.free()
	panel._render_contract_rows_into(container, {"rows": rows})
	for child in container.get_children():
		child.free()
	panel._render_contract_rows_into(container, {"rows": [{"title": "Replacement"}]})
	await _settle()
	_check(container.get_child_count() == 1 and container.get_child(0).text == "Replacement", "An obsolete row stream overwrote the replacement section")
	container.free()
	panel.free()

func _run() -> void:
	await _test_detached_row_stream()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var adapter := Interface.new()
	adapter.name = "EraInterface"
	host.add_child(adapter)
	var button := Button.new()
	button.text = "Resolve situation"
	button.disabled = true
	button.set_meta("action_id", "resolve_test_situation")
	var invoked := [false]
	button.pressed.connect(func(): invoked[0] = true)
	host.add_child(button)
	var legacy := StyleBoxFlat.new()
	legacy.bg_color = Color.MAGENTA
	legacy.shadow_size = 30
	button.add_theme_stylebox_override("normal", legacy)
	await _settle()
	_check(button.disabled, "Styling enabled a gameplay-disabled action")
	_check(button.get_meta("action_id") == "resolve_test_situation", "Action identity changed")
	_check(legacy.bg_color == Color.MAGENTA and legacy.shadow_size == 30, "Shared legacy resources were mutated")
	_check(button.get_theme_stylebox("normal").bg_color == Design.BUTTON, "Late style override escaped the dark theme")
	_check(button.get_theme_stylebox("focus").border_width_left == 2, "Keyboard focus ring is missing")
	button.disabled = false
	button.grab_focus()
	_check(root.gui_get_focus_owner() == button, "Action is not keyboard reachable")
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	accept = InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = false
	Input.parse_input_event(accept)
	await _settle()
	_check(invoked[0], "Keyboard activation lost the original action signal")
	button.set_meta("era_selected", true)
	button.add_theme_stylebox_override("normal", legacy)
	await _settle()
	_check(button.get_theme_stylebox("normal").border_width_bottom == 3, "Secondary tab selection is not visible")
	var dialog := AcceptDialog.new()
	host.add_child(dialog)
	_check(dialog.theme == adapter.design_theme, "Embedded window did not receive the theme")
	var health := ProgressBar.new()
	health.set_meta("stat_title", "Health")
	health.value = 10
	host.add_child(health)
	var fill := PanelContainer.new()
	fill.name = "StatFillLens"
	health.add_child(fill)
	await _settle()
	var danger_color: Color = fill.get_theme_stylebox("panel").bg_color
	health.value = 80
	await _settle()
	_check(fill.get_theme_stylebox("panel").bg_color != danger_color, "Health warning did not clear after recovery")
	await _test_tool_stability(host, adapter)
	host.choose_adventure_entry_overlay = Control.new()
	host.add_child(host.choose_adventure_entry_overlay)
	host.choose_adventure_entry_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Shell.mount_menu(host)
	for role in ["narrative_alive", "household_alive", "god_mode_alive"]:
		host.choose_adventure_entry_shell.add_child(Shell.create_entry_card({"id": role, "button_role": role, "button_text": "Begin"}))
	for dimensions in [Vector2i(1440, 900), Vector2i(1920, 1080), Vector2i(768, 1024), Vector2i(480, 800)]:
		root.content_scale_size = dimensions
		await _settle()
		Shell.layout_menu(host)
		await _settle()
		var grid := host.choose_adventure_entry_shell as GridContainer
		_check(grid.columns == (1 if dimensions.x < 960 else 3), "Menu did not recompose at " + str(dimensions))
		for card in grid.get_children():
			_check(card.get_global_rect().end.x <= dimensions.x + 1, "Menu card overflow at " + str(dimensions))
			var entry: Button = card.get_meta("entry_button")
			_check(entry.get_global_rect().size.y >= 44, "Entry target is too small")
		var directory := OS.get_environment("ERA_PREVIEW_DIR")
		if not directory.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("menu-%d.png" % dimensions.x))
	host.queue_free()
	await process_frame
	print("UI PRESENTATION: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
