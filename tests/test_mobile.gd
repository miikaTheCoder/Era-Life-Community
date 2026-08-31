extends SceneTree

class Screen extends Control:
	var startup_intro_overlay: Control = null
	var startup_intro_accepting_input := true

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
	for physical in [Vector2(2400, 1080), Vector2(1280, 720), Vector2(800, 480), Vector2(2560, 1600), Vector2(640, 360)]:
		var result := UIContractEngine.resolve_presentation_density_bootstrap_contract({
			"physical_viewport_width": physical.x,
			"physical_viewport_height": physical.y,
			"mobile_presentation": true,
			"desktop_presentation": false,
		})
		var logical: Dictionary = result["logical_viewport"]
		_check(float(logical.width) >= 959.9 and float(logical.height) >= 539.9,
			"Mobile layout crops its reference canvas at %s" % physical)
		_check(is_equal_approx(float(logical.width) / float(logical.height), physical.x / physical.y),
			"Mobile layout distorts the aspect ratio at %s" % physical)
		_check(is_equal_approx(float(logical.width) * float(result.ui_scale), physical.x),
			"Mobile scale does not fit the physical screen at %s" % physical)
		var composition := UIContractEngine.resolve_presentation_composition_bootstrap_contract({
			"logical_viewport_width": logical.width,
			"logical_viewport_height": logical.height,
			"mobile_presentation": true,
		})
		_check(composition.choose_adventure_entry.card_count == 1,
			"Phone mode selection must use one column")
		_check(composition.choose_adventure_entry.shell_width < logical.width,
			"Phone mode selection must leave room for margins and scrollbar")

	var desktop := UIContractEngine.resolve_presentation_density_bootstrap_contract({
		"physical_viewport_width": 1920.0,
		"physical_viewport_height": 1080.0,
		"desktop_presentation": true,
	})
	_check(is_equal_approx(float(desktop.logical_viewport.width), 1440.0), "Desktop width changed")
	_check(is_equal_approx(float(desktop.logical_viewport.height), 810.0), "Desktop height changed")

	var shop_button := Button.new()
	root.add_child(shop_button)
	MainSceneLogic._style_rick_weapon_shop_button(shop_button, 0.0)
	var theme_changes: Array[int] = [0]
	shop_button.theme_changed.connect(func(): theme_changes[0] += 1)
	for pulse in [0.25, 0.5, 0.75, 1.0]:
		MainSceneLogic._style_rick_weapon_shop_button(shop_button, pulse)
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

	var screen := Screen.new()
	root.add_child(screen)
	MobileSupport.configure(screen)
	_check(not quit_on_go_back, "Android Back must not quit without confirmation")
	screen.startup_intro_overlay = Control.new()
	screen.add_child(screen.startup_intro_overlay)
	var actions := Control.new()
	actions.name = "MobileAccountActions"
	actions.position = Vector2(100, 10)
	actions.size = Vector2(300, 60)
	screen.startup_intro_overlay.add_child(actions)
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(120, 30)
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
	MobileSupport.handle_back(screen)
	_check(not dialog.visible, "A second Back must cancel the exit dialog")
	screen.queue_free()
	await process_frame
	print("MOBILE TESTS: ", "PASS" if failures.is_empty() else "FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)
