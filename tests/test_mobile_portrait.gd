extends SceneTree
const Interface = preload("res://ui/EraInterface.gd")
var failures: Array[String] = []
class Host extends Control:
	var gs: GameState
	var ui_nav_buttons: Dictionary = {}
	var output_label: RichTextLabel
	var player_stats_overlay: Control
	var current_panel := "life"
	var startup_intro_title_label: Label
	var belongings_hud_button: Button
	var bending_hud_button: Button
	var food_lifestyle_hud_button: Button
	var restaurant_lifestyle_hud_button: Button
	var rick_weapon_shop_hud_button: Button
	var crown_hud_button: Button
	var boxing_hud_button: Button
	var superpower_hud_button: Button
	var power_hud_button: Button
	var wizard_hud_button: Button
	var bending_hud_button_border_overlay: Control
	func _format_standard_tab_money(value: int) -> String:
		return "$%d" % value

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for i in range(5):
		await process_frame

func _tap(control: Control) -> void:
	var pos := root.get_final_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = pos
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _settle()

func _run() -> void:
	_check(MobileSupport.is_enabled(), "Portrait regression requires --mobile-preview")
	root.size = Vector2i(420, 900)
	var host := Host.new()
	host.gs = GameState.new()
	host.gs.player = Person.new()
	host.gs.player.first_name = "Avery"
	host.gs.player.last_name = "River"
	host.gs.player.age = 17
	host.gs.year = 2000
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MobileSupport.configure(host)
	var page := VBoxContainer.new()
	page.name = "UIContainer"
	host.add_child(page)
	var calls: Array[String] = []
	for key in ["life", "world", "school", "career", "relationships", "activities", "mods", "age_up"]:
		var button := Button.new()
		button.text = key.capitalize()
		button.set_meta("ui_nav_key", key)
		button.pressed.connect(func(): calls.append(key))
		host.ui_nav_buttons[key] = button
		page.add_child(button)
	host.output_label = RichTextLabel.new()
	host.output_label.text = "2000\n\nI started a new life.\n".repeat(30)
	page.add_child(host.output_label)
	host.player_stats_overlay = PanelContainer.new()
	host.add_child(host.player_stats_overlay)
	host.player_stats_overlay.custom_minimum_size = Vector2(280, 700)
	host.player_stats_overlay.z_as_relative = false
	host.player_stats_overlay.z_index = 30
	for key in ["belongings", "bending", "rick_weapon_shop"]:
		var button := Button.new()
		button.text = key
		button.pressed.connect(func(): calls.append(key))
		host.set(key + "_hud_button", button)
		host.add_child(button)
	host.bending_hud_button_border_overlay = Control.new()
	host.bending_hud_button.add_child(host.bending_hud_button_border_overlay)
	var adapter := Interface.new()
	adapter.name = "EraInterface"
	host.add_child(adapter)
	await _settle()
	var shell := host.get_node("EraShell")
	for physical in [Vector2i(360, 740), Vector2i(420, 900), Vector2i(1080, 2412)]:
		root.size = physical
		MobileSupport.configure_viewport(host)
		await _settle()
		var viewport := host.get_viewport_rect()
		for control in [shell.header, shell.dock, shell.metrics, host.output_label]:
			_check(viewport.encloses(control.get_global_rect()), "Portrait region escaped viewport: " + str(control.name) + " " + str(control.get_global_rect()))
		_check(host.output_label.size.y >= 220, "Portrait journal became too short")
		_check(not host.output_label.get_global_rect().intersects(shell.dock.get_global_rect()), "Dock overlaps journal")
		for slot in shell.dock_slots:
			for button in slot.get_children():
				_check(button.get_global_rect().size.y >= 44, "Dock target too small")
		_check(not host.bending_hud_button.is_visible_in_tree(), "Floating shortcut escaped the menu")
		_check(not host.bending_hud_button_border_overlay.visible, "Legacy bending border returned")
		await _tap(host.ui_nav_buttons.age_up)
		_check(calls.has("age_up"), "Touch lost the existing Age Up action")
		calls.clear()
		await _tap(shell.assets_button)
		_check(calls == ["belongings"], "Assets touch lost its original action")
		shell.open_drawer("explore")
		await _settle()
		_check(host.ui_nav_buttons.world.is_visible_in_tree(), "World/Save menu inaccessible")
		_check(host.bending_hud_button.is_visible_in_tree(), "Available power missing from menu")
		_check(viewport.encloses(shell.drawer.get_global_rect()), "Menu escaped safe area")
		_check(shell.handle_mobile_back() and not shell.drawer.visible, "Back did not close menu")
		shell.open_drawer("character")
		await _settle()
		_check(host.player_stats_overlay.is_visible_in_tree(), "Character stats did not open")
		_check(host.player_stats_overlay.z_as_relative and host.player_stats_overlay.z_index == 0, "Legacy absolute layering hides stats behind their drawer")
		shell.close_drawer()
		host.belongings_hud_button.disabled = true
		await _settle()
		_check(shell.assets_button.disabled, "Assets proxy enabled a disabled gameplay action")
		host.belongings_hud_button.disabled = false
		host.bending_hud_button.visible = false
		await _settle()
		shell.open_drawer("explore")
		_check(not host.bending_hud_button.is_visible_in_tree(), "Menu revived an unavailable power")
		shell.close_drawer()
		host.bending_hud_button.visible = true
	host.gs.player.age = 18
	await _settle()
	_check(host.ui_nav_buttons.career.is_visible_in_tree(), "Adult career navigation did not replace school")
	_check(not host.ui_nav_buttons.school.is_visible_in_tree(), "School remained in adult dock")
	host.queue_free()
	await process_frame
	print("MOBILE PORTRAIT TESTS: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
