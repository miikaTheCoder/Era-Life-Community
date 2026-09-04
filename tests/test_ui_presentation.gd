extends SceneTree
## Regression: late contract styling cannot erase focus or change gameplay controls.
const Design = preload("res://ui/EraTheme.gd")
const Interface = preload("res://ui/EraInterface.gd")
const Shell = preload("res://ui/EraShell.gd")
var failed := false

class Host extends Control:
	var gs = null
	var current_panel := "life"
	var startup_intro_title_label: Label
	var choose_adventure_entry_overlay: Control
	var choose_adventure_entry_shell: Container
	var output_label: RichTextLabel

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

func _run() -> void:
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
