extends SceneTree

class Screen extends Control:
	var startup_intro_overlay: Control = null
	var startup_intro_accepting_input := true
	var startup_intro_prompt_label: Label
	var title_card_account_popup: Control
	func _title_card_continue_available() -> bool:
		return true
	func _open_title_card_account_panel(mode: String) -> void:
		set_meta("account_mode", mode)
	func _continue_title_card_current_life() -> void:
		pass
	func _disconnect_title_card_eralife_account() -> void:
		pass

class MobileShell extends Node:
	var drawer_open := true
	var layouts := 0
	func handle_mobile_back() -> bool:
		if not drawer_open:
			return false
		drawer_open = false
		return true
	func layout_mobile() -> void:
		layouts += 1

class ClosablePanel extends Control:
	signal close_requested

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	_check(MobileSupport.is_enabled(), "Run this test with -- --mobile-preview")
	for physical in [Vector2(1080, 2400), Vector2(720, 1280), Vector2(1200, 2000), Vector2(1440, 3120), Vector2(360, 640)]:
		var result := UIContractEngine.resolve_presentation_density_bootstrap_contract({
			"physical_viewport_width": physical.x,
			"physical_viewport_height": physical.y,
			"mobile_presentation": true,
			"desktop_presentation": false,
		})
		var logical: Dictionary = result["logical_viewport"]
		_check(is_equal_approx(float(logical.width), 420.0),
			"Portrait layout must keep readable 420px logical width at %s" % physical)
		_check(is_equal_approx(float(logical.width) / float(logical.height), physical.x / physical.y),
			"Mobile layout distorts the aspect ratio at %s" % physical)
		_check(is_equal_approx(float(logical.width) * float(result.ui_scale), physical.x),
			"Mobile scale does not fit the physical screen at %s" % physical)
		_check(MobileSupport.logical_viewport_size(physical).is_equal_approx(Vector2(logical.width, logical.height)), "Loading and gameplay density must agree")
		var composition := UIContractEngine.resolve_presentation_composition_bootstrap_contract({
			"logical_viewport_width": logical.width,
			"logical_viewport_height": logical.height,
			"mobile_presentation": true,
		})
		_check(composition.choose_adventure_entry.card_count == 1,
			"Phone mode selection must use one column")
		_check(composition.choose_adventure_entry.shell_width < logical.width,
			"Phone mode selection must leave room for margins and scrollbar")

		_check(composition.root_shell.left_rail_reserve == 0.0, "Portrait diary must not reserve the desktop stats rail")
		_check(composition.root_shell.nav_button_height >= 48.0, "Portrait navigation needs touch-sized targets")

	var safe := MobileSupport.project_safe_area(Vector2(420, 840), Vector2(1080, 2160), Rect2(24, 80, 1032, 2000))
	_check(safe.position.is_equal_approx(Vector2(24, 80) * (420.0 / 1080.0)), "Display notch inset was not mapped to logical coordinates")
	_check(safe.end.is_equal_approx(Vector2(1056, 2080) * (420.0 / 1080.0)), "Bottom gesture inset was not mapped to logical coordinates")
	_check(MobileSupport.project_safe_area(Vector2(420, 840), Vector2(1080, 2160), Rect2()) == Rect2(0, 0, 420, 840), "Missing display safe area must retain the usable viewport")
	_check(MobileSupport.project_safe_area(Vector2(420, 840), Vector2(1080, 2160), Rect2(-100, -100, 2000, 3000)) == Rect2(0, 0, 420, 840), "Display safe area must be clipped to window bounds")
	_check(ProjectSettings.get_setting("display/window/handheld/orientation.android") == DisplayServer.SCREEN_PORTRAIT, "Android must launch in portrait")
	_check(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_PORTRAIT, "Android exporter must write a portrait manifest from the base handheld setting")
	_check(ProjectSettings.get_setting("application/boot_splash/image.android") == "res://branding/MobileBootSplash.png", "Android must display its branded splash before scripts initialize")
	_check(ResourceLoader.exists("res://branding/MobileBootSplash.png"), "Startup splash resource is missing")
	_check(ProjectSettings.get_setting("application/boot_splash/image") == "res://branding/MobileBootSplash.png", "Exporter needs the base splash path to include its raw PNG")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/mobile_boot.tscn", "Export default must enter the lightweight loader")
	var exports := ConfigFile.new()
	_check(exports.load("res://export_presets.cfg") == OK, "Android export settings must be readable")
	for preset in ["preset.2.options", "preset.3.options"]:
		_check(exports.get_value(preset, "package/unique_name") == "org.eralife.community.portrait", "Portrait install must not replace the existing mobile app")
		_check(exports.get_value(preset, "package/name") == "EraLife Portrait", "Portrait install needs its own launcher label")

	var desktop := UIContractEngine.resolve_presentation_density_bootstrap_contract({
		"physical_viewport_width": 1920.0,
		"physical_viewport_height": 1080.0,
		"desktop_presentation": true,
	})
	_check(is_equal_approx(float(desktop.logical_viewport.width), 1920.0), "Desktop should retain readable native density")
	_check(is_equal_approx(float(desktop.logical_viewport.height), 1080.0), "Desktop should retain readable native density")

	var shop_button := Button.new()
	root.add_child(shop_button)
	ItemsSceneSupport._style_rick_weapon_shop_button(shop_button, 0.0)
	var theme_changes: Array[int] = [0]
	shop_button.theme_changed.connect(func(): theme_changes[0] += 1)
	for pulse in [0.25, 0.5, 0.75, 1.0]:
		ItemsSceneSupport._style_rick_weapon_shop_button(shop_button, pulse)
	_check(theme_changes[0] == 0, "Mobile shop animation must not reapply its theme every frame")
	_check(not shop_button.text.is_empty(), "Mobile shop styling removed the button label")
	shop_button.queue_free()

	# Delaying invisible decoration must retain the target data and later show it.
	var crime := CrimePanel.new()
	var target_card := PanelContainer.new()
	root.add_child(target_card)
	var target_row := {"target_id": 7, "target_selection_action": {"enabled": true}}
	crime.call("_register_crime_target_card_presentation", target_card, target_row)
	_check(not target_card.has_meta("crime_target_reticle_overlay"), "Browse cards should not build hidden reticles")
	_check(target_card.get_meta("crime_target_row_contract", {}).get("target_id", -1) == 7, "Lazy crime decoration lost its target data")
	crime.section_contract_cache["targets"] = {"interaction_contract": {"stage": "choose_crime_target"}}
	crime.call("_refresh_crime_target_reticle", target_card, target_row, false)
	var reticle: Control = target_card.get_meta("crime_target_reticle_overlay", null)
	_check(is_instance_valid(reticle) and reticle.visible, "Entering targeting must create the reticle")
	crime.section_contract_cache.clear()
	crime.call("_refresh_crime_target_reticle", target_card, target_row, false)
	_check(is_instance_valid(reticle) and not reticle.visible, "Returning to browsing must hide the reticle")
	target_card.free()
	crime.free()

	root.size = Vector2i(420, 840)
	var screen := Screen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MobileSupport.configure(screen)
	await process_frame
	_check(root.content_scale_size == Vector2i(420, 840), "Mobile boot must use the portrait density before loading the game")
	root.size = Vector2i(1080, 2400)
	await process_frame
	await process_frame
	_check(root.content_scale_size == Vector2i(420, 933), "Portrait density must follow a changed physical aspect ratio")
	root.size = Vector2i(420, 840)
	await process_frame
	await process_frame
	_check(not quit_on_go_back, "Android Back must not quit without confirmation")
	screen.startup_intro_overlay = Control.new()
	screen.add_child(screen.startup_intro_overlay)
	screen.startup_intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.set_meta("startup_intro_title_card_visible_surface", true)
	MobileSupport.add_title_actions(screen)
	await process_frame
	await process_frame
	var actions := screen.startup_intro_overlay.get_node("MobileAccountActions") as GridContainer
	_check(actions.columns == 2, "Portrait title actions must reflow into two columns")
	for action in actions.get_children():
		if action.visible:
			_check(action.get_global_rect().position.x >= 0 and action.get_global_rect().end.x <= 420, "Title action extends beyond portrait viewport")
			_check(action.size.y >= 48, "Title account action needs a touch-sized target")
	(actions.get_node("Createaccount") as Button).pressed.emit()
	_check(screen.get_meta("account_mode", "") == "signup", "Reflowed account action lost its existing callback")
	var touch := InputEventScreenTouch.new()
	touch.position = actions.get_global_rect().get_center()
	touch.pressed = true
	_check(MobileSupport.event_targets_title_actions(screen, touch),
		"Title account touches must bypass the game's tap-anywhere handler")
	touch.position = Vector2(20, 200)
	_check(not MobileSupport.event_targets_title_actions(screen, touch),
		"Tapping outside account actions must still enter the game")
	screen.startup_intro_overlay.hide()
	var edit := LineEdit.new()
	screen.add_child(edit)
	MobileSupport.adapt_form(edit)
	_check(edit.custom_minimum_size.y >= 56, "Mobile form inputs need touch-sized targets")
	var shell := MobileShell.new()
	shell.name = "EraShell"
	screen.add_child(shell)
	MobileSupport.layout_life(screen)
	_check(shell.layouts == 1, "Legacy mobile entry must delegate layout to the portrait shell")
	MobileSupport.handle_back(screen)
	_check(not shell.drawer_open and screen.get_node_or_null("MobileExitConfirmation") == null, "Back must close the portrait drawer before asking to quit")
	var closed: Array[String] = []
	var front := ClosablePanel.new()
	front.z_index = 200
	screen.add_child(front)
	front.close_requested.connect(func(): closed.append("front"); front.hide())
	var behind := ClosablePanel.new()
	behind.z_index = 10
	screen.add_child(behind)
	behind.close_requested.connect(func(): closed.append("behind"); behind.hide())
	MobileSupport.handle_back(screen)
	_check(closed == ["front"], "Back must close the front panel, even when another was added later")
	MobileSupport.handle_back(screen)
	_check(closed == ["front", "behind"], "Back must skip the already hidden panel")
	MobileSupport.handle_back(screen)
	var dialog := screen.get_node_or_null("MobileExitConfirmation") as ConfirmationDialog
	_check(dialog != null and dialog.visible, "Back at the root must ask before exiting")
	_check(dialog.size.x <= 420, "Exit confirmation must fit portrait width")
	MobileSupport.handle_back(screen)
	_check(not dialog.visible, "A second Back must cancel the exit dialog")
	screen.queue_free()
	await process_frame
	print("MOBILE TESTS: ", "PASS" if failures.is_empty() else "FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)
