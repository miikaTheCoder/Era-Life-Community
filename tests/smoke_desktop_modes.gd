extends SceneTree

# Run with Godot 4.4.1, an isolated XDG_DATA_HOME and a graphical display.
# ERA_MODE selects narrative-family, narrative-continue, household, god, or restore.
# ERA_PREVIEW_DIR optionally records screenshots. No existing saves are used.
# ERA_PORTRAIT=1 exercises the portrait shell with -- --mobile-preview.
var mode := OS.get_environment("ERA_MODE")
var portrait := OS.get_environment("ERA_PORTRAIT") == "1"
var portrait_drawers_checked := false
var failed := false
var origin_mode := ""
var years_per_run := 1
var years_completed := 0
var checkpoints_restored := 0
var choices_made := 0
var last_hydration_diagnostic_ms := -10000
const PERSISTED_PLAYER_FIELDS := ["job", "income", "job_performance", "job_experience", "unemployed_years", "school_mode", "school_name", "school_status", "education_level", "health", "mental_health", "smarts", "friends", "children", "marital_status"]
const RUNTIME_SHORTCUT_LABELS := {
	"belongings": "Belongings", "food_lifestyle": "Food", "restaurant_lifestyle": "Dining",
	"bending": "Bending", "crown": "Realm", "boxing": "Boxing", "superpower": "Superpowers",
	"power": "Powers", "wizard": "Magic", "rick_weapon_shop": "Weapons",
}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	if not ok:
		failed = true
		push_error("DESKTOP MODES: " + message)
	return ok

func _wait_for(predicate: Callable, seconds := 30.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await create_timer(0.1).timeout
	return predicate.call()

func _capture(label: String) -> void:
	if portrait and label == "life":
		if not await _check_portrait_life():
			return
	var directory := OS.get_environment("ERA_PREVIEW_DIR")
	if not directory.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(mode + "-" + label + ".png"))
		if not portrait and OS.get_environment("ERA_UI_GALLERY") == "1" and label in ["menu", "life"]:
			await _capture_ui_sizes(label, directory)
	if portrait and label == "life" and not portrait_drawers_checked:
		portrait_drawers_checked = true
		await _check_portrait_drawers()

func _portrait_shell() -> Node:
	return current_scene.get_node_or_null("EraShell")

func _check_portrait_life() -> bool:
	if not _check(await _wait_for(func(): return _portrait_shell() != null and is_instance_valid(_portrait_shell().get("dock")), 10), "Portrait gameplay shell did not mount"):
		return false
	await create_timer(0.5).timeout
	var shell := _portrait_shell()
	var diary := current_scene.get("output_label") as Control
	var safe := MobileSupport.safe_viewport_rect(current_scene)
	var controls: Array[Control] = [shell.get("header"), diary, shell.get("metrics"), shell.get("dock")]
	for index in controls.size():
		var control := controls[index]
		if not _check(is_instance_valid(control) and control.is_visible_in_tree(), "Portrait shell is missing a visible gameplay region"):
			return false
		var rect := control.get_global_rect()
		_check(safe.grow(1).encloses(rect), "Portrait gameplay region leaves the safe viewport: " + str(control.name) + " " + str(rect))
		for other_index in range(index):
			_check(not rect.intersects(controls[other_index].get_global_rect()), "Portrait gameplay regions overlap: " + str(control.name))
	_check(diary.size.x >= 350 and diary.size.y >= 160, "Portrait journal is too small to read")
	var age := current_scene.get("ui_nav_buttons").get("age_up") as Button
	_check(is_instance_valid(age) and age.is_visible_in_tree() and age.size.y >= 48 and safe.grow(1).encloses(age.get_global_rect()), "Portrait Age action must remain a reachable touch target")
	var assets := shell.get("assets_button") as Button
	_check(is_instance_valid(assets) and assets.is_visible_in_tree() and assets.size.y >= 48, "Portrait Assets action is missing from the dock")
	print("PORTRAIT UI: viewport=", current_scene.get_viewport_rect().size, " safe=", safe, " diary=", diary.get_global_rect(), " dock=", shell.get("dock").get_global_rect())
	return not failed

func _portrait_back() -> void:
	# Use the same notification Android sends; the scene owns dismissal routing.
	current_scene.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(0.5).timeout

func _check_portrait_drawers() -> void:
	var shell := _portrait_shell()
	if not await _click(current_scene.find_child("EraMobileCharacter", true, false)):
		return
	var stats := current_scene.get("player_stats_overlay") as Control
	_check(shell.get("drawer").is_visible_in_tree() and stats.is_visible_in_tree(), "Character tap did not reveal the existing stats")
	_check(MobileSupport.safe_viewport_rect(current_scene).grow(1).encloses(shell.get("drawer").get_global_rect()), "Character drawer leaves the safe viewport")
	await _capture("character")
	await _portrait_back()
	_check(not shell.get("drawer").visible, "Android Back did not close the Character drawer")
	if not await _click(current_scene.find_child("EraMobileMenu", true, false)):
		return
	_check(shell.get("drawer").is_visible_in_tree(), "Menu tap did not open Explore")
	var world := current_scene.get("ui_nav_buttons").get("world") as Button
	_check(is_instance_valid(world) and world.is_visible_in_tree(), "Explore did not expose the original World action")
	await _capture("explore")
	await _portrait_back()
	_check(not shell.get("drawer").visible, "Android Back did not close Explore")

func _portrait_active_surface(tab: String) -> Control:
	var fields: Dictionary = {
		"activities": ["activities_hub_panel", "activities_action_panel", "standard_tab_popup"],
		"relationships": ["institution_hub_overlay", "relationship_hub_panel", "standard_tab_popup"],
		"career": ["career_hub_panel", "standard_tab_popup"],
		"school": ["institution_hub_overlay", "school_hub_panel", "standard_tab_popup"],
		"assets": ["belongings_hud_panel"],
	}
	for field in fields.get(tab, []):
		var surface := current_scene.get(field) as Control
		if is_instance_valid(surface) and surface.is_visible_in_tree():
			return surface
	return null

func _check_portrait_surface(surface: Control, label: String) -> void:
	var safe := MobileSupport.safe_viewport_rect(current_scene)
	_check(safe.grow(1).encloses(surface.get_global_rect()), "Portrait " + label + " panel exceeds the safe viewport")
	var reachable_buttons := 0
	for raw in surface.find_children("*", "Button", true, false):
		var button := raw as Button
		if not button.is_visible_in_tree():
			continue
		var rect := button.get_global_rect()
		_check(rect.size.x <= safe.size.x + 1, "Portrait " + label + " action retains desktop width: " + button.text)
		if safe.intersects(rect) and not button.disabled:
			reachable_buttons += 1
			_check(rect.size.y >= 44, "Portrait " + label + " action is too small to tap: " + button.text)
	_check(reachable_buttons > 0, "Portrait " + label + " panel has no reachable actions")

func _inspect_portrait_gameplay() -> void:
	var state: GameState = current_scene.get("gs")
	var occupation := "school" if state.player.age < 18 else "career"
	for tab in [occupation, "relationships", "activities"]:
		if not await _click(_navigation_button(tab)):
			return
		if not _check(await _wait_for(func(): return _portrait_active_surface(tab) != null, 15), "Portrait navigation did not open " + tab):
			return
		await create_timer(0.5).timeout
		var surface := _portrait_active_surface(tab)
		_check_portrait_surface(surface, tab)
		await _capture("inspect-" + tab)
		await _portrait_back()
		_check(not surface.is_visible_in_tree(), "Android Back did not close " + tab)
		_check(current_scene.get("current_panel") == "life", "Portrait panel Back did not return to the journal")
		var journal := current_scene.get("output_label") as RichTextLabel
		_check(journal != null and journal.is_visible_in_tree() and journal.size.y >= 220, "Back from " + tab + " did not restore the visible journal layout")
		await _capture("back-from-" + tab)
		if failed:
			return
	var shell := _portrait_shell()
	var assets := shell.get("assets_button") as Button
	if is_instance_valid(assets) and not assets.disabled:
		if not await _click(assets):
			return
		if not _check(await _wait_for(func(): return _portrait_active_surface("assets") != null, 10), "Assets proxy did not open the original inventory"):
			return
		var inventory := _portrait_active_surface("assets")
		_check_portrait_surface(inventory, "assets")
		await _capture("inspect-assets")
		await _portrait_back()
		_check(not inventory.is_visible_in_tree(), "Android Back did not close Assets")
	else:
		print("PORTRAIT ASSETS: unavailable for the current actor")
	await _check_portrait_life()


func _capture_ui_sizes(label: String, directory: String) -> void:
	var old_scale_size := root.content_scale_size
	var old_aspect := root.content_scale_aspect
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	for dimensions in [Vector2i(768, 1024), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.content_scale_size = dimensions
		await create_timer(0.5).timeout
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		root.content_scale_size = dimensions
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("%s-%s-%d.png" % [mode, label, dimensions.x]))
		if label == "life":
			var age_up: Button = current_scene.get("ui_nav_buttons").get("age_up")
			var diary: RichTextLabel = current_scene.get("output_label")
			print("DESKTOP UI SIZE: requested=", dimensions, " viewport=", current_scene.get_viewport_rect().size, " age_up=", age_up.get_global_rect(), " diary=", diary.get_global_rect())
			_check(age_up != null and age_up.get_global_rect().end.x <= dimensions.x + 1 and age_up.get_global_rect().end.y <= dimensions.y + 1, "Age Up leaves the viewport at " + str(dimensions))
			_check(diary.size.x >= 280 and diary.size.y >= 200, "Diary became unusably small at " + str(dimensions))
			await _check_runtime_shortcuts(dimensions, diary, age_up)
			if dimensions.x < 1000:
				var shell: Node = current_scene.get_node("EraShell")
				await _click(shell.stats_toggle)
				_check(current_scene.get("player_stats_overlay").is_visible_in_tree(), "Character drawer did not open")
				await _click(shell.stats_toggle)
				_check(not current_scene.get("player_stats_overlay").is_visible_in_tree(), "Character drawer did not close")
	root.content_scale_size = old_scale_size
	root.content_scale_aspect = old_aspect
	current_scene.set("ui_presentation_density_applied_signature", "")
	current_scene.call("_repair_playable_life_shell_after_viewport_resize", "ui_gallery_restore")
	await create_timer(0.5).timeout

func _check_runtime_shortcuts(dimensions: Vector2i, diary: Control, age_up: Control) -> void:
	# Observe the real buttons through normal legacy refresh ticks. Available
	# shortcuts can change as engines finish bootstrapping, so compare positions
	# only while a button keeps its stack index; never create gameplay fixtures.
	var previous: Dictionary = {}
	var observed: Dictionary = {}
	var samples := 0
	var deadline := Time.get_ticks_msec() + 1000
	while samples < 2 or Time.get_ticks_msec() < deadline:
		await RenderingServer.frame_post_draw
		samples += 1
		var snapshot: Dictionary = {}
		var columns: Dictionary = {}
		var occupied: Dictionary = {}
		var sample_ok := true
		var overlay := current_scene.get("bending_hud_button_border_overlay") as Control
		if is_instance_valid(overlay):
			sample_ok = _check(not overlay.visible, "Legacy Bending border returned at " + str(dimensions)) and sample_ok
		for key in RUNTIME_SHORTCUT_LABELS:
			var button := current_scene.get(key + "_hud_button") as Button
			if not is_instance_valid(button) or not button.is_visible_in_tree():
				continue
			var rect := button.get_global_rect()
			var stack_index := int(button.get_meta("runtime_floating_hud_stack_index", -1))
			var column := int(button.get_meta("runtime_floating_hud_stack_column", -1))
			var context := "%s at %s (frame %d, stack %d): %s" % [key, dimensions, samples, stack_index, rect]
			observed[key] = true
			sample_ok = _check(button.text == RUNTIME_SHORTCUT_LABELS[key], "Shortcut label changed: " + context) and sample_ok
			var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			var horizontal_padding := button.get_theme_stylebox("normal").get_minimum_size().x
			sample_ok = _check(rect.size.x + 1 >= text_width + horizontal_padding, "Shortcut label is clipped: " + context) and sample_ok
			sample_ok = _check(stack_index >= 0 and column >= 0, "Shortcut has no stack slot: " + context) and sample_ok
			sample_ok = _check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= dimensions.x + 1 and rect.end.y <= dimensions.y + 1, "Shortcut leaves the viewport: " + context) and sample_ok
			sample_ok = _check(not rect.intersects(diary.get_global_rect()), "Shortcut overlaps the diary: " + context) and sample_ok
			sample_ok = _check(not rect.intersects(age_up.get_global_rect()), "Shortcut overlaps Age Up: " + context) and sample_ok
			if columns.has(column):
				var column_rect: Rect2 = columns[column]
				sample_ok = _check(absf(rect.position.x - column_rect.position.x) <= 1 and absf(rect.end.x - column_rect.end.x) <= 1, "Shortcut column is misaligned: " + context) and sample_ok
			else:
				columns[column] = rect
			for other_key in occupied:
				sample_ok = _check(not rect.intersects(occupied[other_key]), "Shortcuts overlap (%s): %s" % [other_key, context]) and sample_ok
			occupied[key] = rect
			if previous.has(key):
				var before: Dictionary = previous[key]
				if before["instance_id"] == button.get_instance_id() and before["stack_index"] == stack_index:
					var previous_rect: Rect2 = before["rect"]
					sample_ok = _check(rect.is_equal_approx(previous_rect), "Shortcut moved between rendered frames: " + context + "; previous=" + str(previous_rect)) and sample_ok
			snapshot[key] = {"instance_id": button.get_instance_id(), "stack_index": stack_index, "rect": rect}
		previous = snapshot
		if not sample_ok:
			return
	_check(not observed.is_empty(), "No visible runtime shortcuts were checked at " + str(dimensions))
	print("DESKTOP UI SHORTCUTS: viewport=", dimensions, " rendered_frames=", samples, " observed=", observed.keys())

func _click_at(point: Vector2) -> void:
	var position := root.get_final_transform() * point
	if portrait:
		for pressed in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.position = position
			touch.pressed = pressed
			Input.parse_input_event(touch)
			await create_timer(0.12).timeout
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = position
		Input.parse_input_event(motion)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			Input.parse_input_event(event)
			await create_timer(0.12).timeout
	await create_timer(0.25).timeout

func _click(control: Control) -> bool:
	if not _check(is_instance_valid(control) and control.is_visible_in_tree(), "Missing or hidden control"):
		return false
	if control is BaseButton and not _check(not control.disabled, "Disabled control: " + control.name):
		return false
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
		parent = parent.get_parent()
	await create_timer(0.2).timeout
	print("DESKTOP CLICK: ", control.name, " rect=", control.get_global_rect())
	await _click_at(control.get_global_rect().get_center())
	return true

func _entry_button(role: String) -> Button:
	for button in current_scene.find_children("*", "Button", true, false):
		if button.get_meta("entry_role", "") == role:
			return button
	return null

func _navigation_button(tab: String) -> Button:
	if portrait:
		var key := "age_up" if tab in ["age up", "age_up"] else tab
		var button := current_scene.get("ui_nav_buttons").get(key) as Button
		if is_instance_valid(button) and not button.is_visible_in_tree():
			var shell := _portrait_shell()
			if shell != null:
				shell.call("open_drawer", "explore")
		return button
	# Age transitions can rebuild the navigation. Use the current visible
	# control rather than a cached reference to an earlier layout.
	for control in current_scene.find_children("*", "Button", true, false):
		if control.is_visible_in_tree() and control.text.strip_edges().to_lower() == tab:
			return control
	return null

func _run() -> void:
	if mode.is_empty():
		mode = "narrative-family"
	origin_mode = mode
	var requested_years := OS.get_environment("ERA_YEARS")
	if not requested_years.is_empty():
		years_per_run = clampi(int(requested_years), 0, 30)
	if not _check(not OS.get_environment("XDG_DATA_HOME").is_empty(), "Use scripts/test-desktop-modes.sh to isolate test saves"):
		quit(1)
		return
	if portrait and not _check(MobileSupport.is_enabled(), "ERA_PORTRAIT requires -- --mobile-preview"):
		quit(1)
		return
	var dimensions := Vector2i(420, 900) if portrait else Vector2i(1440, 900)
	root.size = dimensions
	root.unresizable = true
	root.min_size = dimensions
	root.max_size = dimensions
	if portrait and mode != "restore":
		change_scene_to_file("res://scenes/mobile_boot.tscn")
		if not _check(await _wait_for(func(): return current_scene != null and current_scene.has_method("_choose_entry")), "Mobile entry menu did not appear"):
			quit(1)
			return
		await _capture("early-menu")
		var boot := current_scene
		var boot_id := boot.get_instance_id()
		await _click(boot.find_child("Boot_new_life", true, false))
		if not _check(await _wait_for(func(): return current_scene != null and current_scene.get_instance_id() != boot_id and is_instance_valid(current_scene.get("choose_adventure_entry_overlay")), 120), "Mobile New life did not reach mode selection"):
			quit(1)
			return
		await create_timer(2).timeout
	else:
		change_scene_to_file("res://scenes/main.scn")
		await create_timer(3).timeout
		current_scene.call("_skip_startup_intro_to_title_card")
		await create_timer(2).timeout
		await _capture("title")
		if mode == "restore":
			await _restore()
			await _capture("restored")
			print("DESKTOP MODES: restore ", "FAIL" if failed else "PASS")
			quit(1 if failed else 0)
			return
		await _click_at(root.get_visible_rect().get_center())
		await create_timer(2).timeout
	await _capture("menu")
	var role := "household_alive" if mode == "household" else "narrative_alive"
	var button: Button = current_scene.call("_choose_ereality_entry_button") if mode == "god" else _entry_button(role)
	if _check(button != null and not button.pressed.get_connections().is_empty(), "Mode entry has no action: " + role):
		if await _click(button):
			if mode == "household":
				await _household()
			elif mode == "god":
				await _god()
			else:
				await _narrative()
	if not failed:
		var state: GameState = current_scene.get("gs")
		_check(await _wait_for(func(): return state.resident_runtime_bootstrap_complete, 125), "Gameplay engines did not finish initialization")
	if not failed:
		await _age_and_save()
	await _capture("final")
	print("DESKTOP MODES: ", mode, " ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func _narrative() -> void:
	if not _check(await _wait_for(func(): return is_instance_valid(current_scene.get("choose_adventure_scenario_panel")) and current_scene.get("choose_adventure_scenario_panel").visible), "Narrative did not open"):
		return
	var panel: ChooseYourOwnAdventureScenarioPanel = current_scene.get("choose_adventure_scenario_panel")
	await _capture("catalog")
	for step in range(25):
		var result: Dictionary = current_scene.get("gs").choose_adventure_scenario_engine.last_result
		# Catalog publication is stored in state; subsequent results also update last_result.
		if result.is_empty():
			result = current_scene.get("gs").scenario_state.get("choose_adventure", {}).get("last_result", {})
		var options: Array = result.get("opps", [])
		if not _check(not options.is_empty(), "Narrative exposed no choices: " + str(result.get("type"))):
			return
		var index := 0
		if result.get("type") == "choose_adventure_birth_path_selection" and mode == "narrative-continue":
			index = 1
		print("DESKTOP NARRATIVE: ", result.get("type"), " choice=", options[index].get("choice_id"))
		var choices: Array = panel.choices_box.get_children().filter(func(node): return node is Button and not node.is_queued_for_deletion())
		if not _check(index < choices.size(), "Choice button missing") or not await _click(choices[index]):
			return
		if current_scene.get_meta("prepared_mode_entry_pending", false) or not panel.visible:
			break
	if not _check(await _wait_for(func(): return current_scene.get("gs").player != null and not panel.visible and current_scene.call("_playable_life_shell_has_visible_sovereignty"), 125), "Narrative did not enter a life"):
		return
	await create_timer(3).timeout
	var state: GameState = current_scene.get("gs")
	print("DESKTOP LIFE: ", state.player.first_name, " age=", state.player.age, " year=", state.year, " family=", state.player.parents)
	_check(state.player.age == 0 if mode == "narrative-family" else state.player.age >= 16, "Narrative start age incorrect")
	_check(not state.scenario_state.get("choose_adventure", {}).get("pressure_history", []).is_empty(), "Narrative choices were lost at the gameplay handoff")
	_check(state.scenario_state.get("choose_adventure_lineage_birth", true) == (mode == "narrative-family"), "Narrative ending mode was lost")
	if mode == "narrative-family":
		_check(state.lineage_engine != null, "Narrative birth bypassed the lineage authority")
	await _capture("life")

func _god() -> void:
	if not _check(await _wait_for(func(): return is_instance_valid(current_scene.get("god_mode_viewer")) and current_scene.get("god_mode_viewer").is_visible_in_tree()), "God Mode did not open"):
		return
	var viewer = current_scene.get("god_mode_viewer")
	await _capture("creator")
	if not await _click(viewer.prewarm_button):
		return
	if not _check(await _wait_for(func(): return viewer.engine.current_state().get("viewer_ready_button_enabled", false), 100), "God Mode did not become ready"):
		return
	if OS.get_environment("ERA_PORTRAIT") == "1":
		_check(not StartupTiming.stages.has("life_shell_visible"), "Prewarmed life was timed while covered by God Mode")
	if not await _click(viewer.prewarm_button):
		return
	_check(await _wait_for(func(): return not viewer.is_visible_in_tree() and current_scene.call("_playable_life_shell_has_visible_sovereignty")), "God Mode did not enter gameplay")
	if OS.get_environment("ERA_PORTRAIT") == "1":
		_check(await _wait_for(func(): return StartupTiming.stages.has("life_shell_visible")), "Visible life was not timed")
	await _capture("life")

func _household() -> void:
	if not _check(await _wait_for(func(): return is_instance_valid(current_scene.get("household_creator_overlay")) and current_scene.get("household_creator_overlay").visible), "Household did not open on first click"):
		return
	var create: Button = current_scene.find_child("HouseholdCreatorBigCreateButton", true, false)
	await create_timer(0.5).timeout
	if MobileSupport.is_enabled():
		_check(create.size.x >= 280, "Household create button is too narrow to read on a phone")
	if not await _click(create):
		return
	await _click(current_scene.get("household_creator_reality_buttons").get("realistic"))
	await _capture("world-setup")
	if not await _click(current_scene.get("household_creator_prewarm_button")):
		return
	if not _check(await _wait_for(func(): return current_scene.get("household_creator_world_prewarmed")), "Household world seed was not created"):
		return
	if not _check(await _wait_for(func():
		var button = current_scene.get("household_creator_create_member_button")
		return is_instance_valid(button) and button.is_visible_in_tree()
	), "Household member form was not presented after world preparation"):
		return
	for member in [{"name": "Ada", "age": 35}, {"name": "Bea", "age": 8}, {"name": "Cora", "age": 30}]:
		if not await _click(current_scene.get("household_creator_create_member_button")):
			return
		var first: LineEdit = current_scene.get("household_creator_member_first_name_line")
		var last: LineEdit = current_scene.get("household_creator_member_last_name_line")
		first.text = member.name
		first.text_changed.emit(first.text)
		last.text = "Desktop"
		last.text_changed.emit(last.text)
		_select(current_scene.get("household_creator_member_gender_picker"), "Female")
		current_scene.get("household_creator_member_age_spin").value = member.age
		if member.name == "Bea":
			_select(current_scene.get("household_creator_member_relation_picker"), "Daughter")
		elif member.name == "Cora":
			_select(current_scene.get("household_creator_member_relation_picker"), "Roommate")
		await _capture("member-" + member.name)
		if not await _click(current_scene.get("household_creator_member_basic_continue_button")):
			return
		if member.name == "Bea":
			current_scene.get("household_creator_member_stats_sliders")["smarts"].value = 88
		if not await _click(current_scene.get("household_creator_member_save_button")):
			return
	if not _check(current_scene.get("household_creator_created_members").size() == 3, "Household editor lost a member"):
		return
	await _capture("household")
	if not await _click(current_scene.get("household_creator_continue_button")):
		return
	if not _check(await _wait_for(func():
		var selection = current_scene.get("household_creator_start_selection_list")
		return is_instance_valid(selection) and selection.is_visible_in_tree() and selection.get_child_count() == 3
	), "Household start selection missing"):
		return
	var list: VBoxContainer = current_scene.get("household_creator_start_selection_list")
	await _capture("select-member")
	var start_index := int(OS.get_environment("ERA_HOUSEHOLD_START_INDEX")) if OS.has_environment("ERA_HOUSEHOLD_START_INDEX") else 1
	if not await _click(list.get_child(start_index)):
		return
	if not _check(await _wait_for(func(): return not current_scene.get_meta("prepared_mode_entry_pending", false) and current_scene.call("_playable_life_shell_has_visible_sovereignty"), 125), "Household did not enter a life"):
		return
	var state: GameState = current_scene.get("gs")
	var expected_member: Array = [["Ada", 35], ["Bea", 8], ["Cora", 30]][start_index]
	_check(state.player.first_name == expected_member[0] and state.player.age == expected_member[1], "Selected household member was not used")
	if start_index == 1:
		_check(state.player.smarts == 88 and state.player.job == "Student", "Selected member's stats or school identity were lost")
	_check(state.scenario_state.get("custom_household_member_index", {}).size() == 3, "World did not keep all authored household members")
	var mother: Person = null
	for actor in state.npcs:
		if actor.first_name == "Ada" and actor.last_name == "Desktop":
			mother = actor
	_check(mother != null, "Created parent missing")
	if mother != null and start_index == 1:
		_check(state.player.parents.has(mother.id) and mother.children.has(state.player.id), "Household family links are not reciprocal")
	print("DESKTOP LIFE: ", state.player.first_name, " age=", state.player.age, " year=", state.year, " parents=", state.player.parents)
	await _capture("life")

func _select(picker: OptionButton, label: String) -> void:
	for index in range(picker.item_count):
		if picker.get_item_text(index).to_lower() == label.to_lower():
			picker.select(index)
			picker.item_selected.emit(index)
			return
	_check(false, "Missing picker option: " + label)

func _age_and_save() -> void:
	var state: GameState = current_scene.get("gs")
	for parent_id in state.player.parents:
		var parent: Person = state.get_npc_by_id(int(parent_id))
		_check(parent != null and parent.children.has(state.player_id), "Created life has a one-way parent link")
	var previous_entries: Array = state.scenario_state.get("life_diary_state_by_npc", {}).get(str(state.player_id), {}).get("entries", []).duplicate(true)
	for offset in range(years_per_run):
		if not await _advance_one_year():
			return
		print("DESKTOP YEAR: ", JSON.stringify({"mode": origin_mode, "years_completed": years_completed, "age": state.player.age, "year": state.year, "alive": state.player.alive, "health": state.player.health, "money": state.player.bank_balance, "job": state.player.job, "school_status": state.player.school_status, "education_level": state.player.education_level, "friends": state.player.friends.size(), "children": state.player.children.size()}))
	await _capture("aged-%d" % state.player.age)
	if portrait or OS.get_environment("ERA_EXPLORE") == "1":
		await _inspect_gameplay()
	await _save(previous_entries)

func _inspect_gameplay() -> void:
	if portrait:
		await _inspect_portrait_gameplay()
		return
	for tab in ["school", "career", "relationships"]:
		var button: Button = _navigation_button(tab)
		if not await _click(button):
			return
		await create_timer(2).timeout
		await _capture("inspect-" + tab)
		var labels: Array = []
		for control in current_scene.find_children("*", "Button", true, false):
			if control.is_visible_in_tree() and not control.disabled:
				labels.append({"name": control.name, "text": control.text})
		print("DESKTOP PANEL: ", tab, " ", JSON.stringify(labels))
		var panel: Control = current_scene.get({"school": "school_hub_panel", "career": "career_hub_panel", "relationships": "relationship_hub_panel"}[tab])
		_check(panel != null and panel.is_visible_in_tree(), "Navigation did not open the " + tab + " hub")
		# These hubs are modal: return to the life screen before selecting
		# another navigation button behind the overlay.
		for control in current_scene.find_children("*", "Button", true, false):
			if control.is_visible_in_tree() and control.text in ["×", "← RETURN TO LIFE"]:
				await _click(control)
				break
	var pending: Button = current_scene.get("pending_situations_button")
	if pending != null and pending.is_visible_in_tree() and not pending.disabled:
		await _click(pending)
		await create_timer(1).timeout
		var viewer: PopupViewer = current_scene.get("popup_viewer")
		if viewer != null and viewer.is_visible_in_tree():
			print("DESKTOP PENDING: ", JSON.stringify(viewer.last_list_payload))
			await _capture("inspect-pending")
			for control in viewer.find_children("*", "Button", true, false):
				if control.is_visible_in_tree() and control.text == "X":
					await _click(control)
					break
	await _click(_navigation_button("life"))

func _advance_one_year() -> bool:
	var state: GameState = current_scene.get("gs")
	var old_age := state.player.age
	var old_year: int = state.year
	if not _check(state.player.alive, "Life ended before requested duration; inspect the diary rather than starting a different life"):
		return false
	# A completed year can leave its informational result card on top of the
	# navigation. Dismiss it before locating/clicking the next Age Up button so
	# multi-year certification never spends a year click closing stale chrome.
	var stale_result: Control = current_scene.get("action_result_popup")
	var stale_card: Control = current_scene.get("action_result_popup_card")
	if (
		stale_result != null
		and stale_result.is_visible_in_tree()
		and stale_card != null
		and stale_card.is_visible_in_tree()
	):
		await _click_at(stale_card.get_global_rect().get_center())
		await create_timer(0.4).timeout
	var age_button: Button = _navigation_button("age_up") if portrait else null
	if not portrait:
		for button in current_scene.find_children("*", "Button", true, false):
			if button.is_visible_in_tree() and button.text.to_upper().strip_edges() == "AGE UP":
				age_button = button
				break
	if not await _click(age_button):
		return false
	var deadline := Time.get_ticks_msec() + 90000
	var prompt_count := 0
	while state.year <= old_year and Time.get_ticks_msec() < deadline:
		if await _answer_blocking_prompt():
			prompt_count += 1
			if not _check(prompt_count <= 12, "Choices keep returning without allowing the year to advance"):
				return false
			if state.year <= old_year:
				await _click(_navigation_button("age_up") if portrait else age_button)
		await create_timer(0.2).timeout
	if not _check(state.year > old_year and state.player.age > old_age, "Age Up did not advance the simulation"):
		await _capture("age-stalled")
		print("DESKTOP STALL: ", current_scene.get("cached_last_result"))
		return false
	await create_timer(4).timeout
	if not _check(await _wait_for(func(): return not state.scenario_state.get("age_up_tail_runtime_pending", false), 90), "Yearly simulation did not finish after age changed"):
		var stalled_runtime: AgeUpRuntimeEngine = state.life_engine.runtime_engine
		print("DESKTOP YEAR STALL: ", JSON.stringify({"age": state.player.age, "year": state.year, "phase_cursor": stalled_runtime.runtime_slice_phase_cursor, "phase_order": stalled_runtime.runtime_slice_order, "narrative_progress": stalled_runtime.active_year_context.get("narrative_progress"), "last_report": state.scenario_state.get("age_up_tail_runtime_last_autonomous_report", {})}))
		await _capture("year-stalled")
		return false
	var year_report: Dictionary = state.scenario_state.get("age_up_tail_runtime_last_autonomous_report", {})
	print("DESKTOP YEAR RUNTIME: ", JSON.stringify({"mode": year_report.get("mode"), "success": year_report.get("success"), "complete": year_report.get("is_complete")}))
	if state.life_engine != null and state.life_engine.runtime_engine != null:
		var runtime: AgeUpRuntimeEngine = state.life_engine.runtime_engine
		print("DESKTOP YEAR PHASES: ", JSON.stringify({"order": runtime.runtime_slice_order, "timings": runtime.runtime_slice_phase_timings, "school_engine": state.school_engine != null, "career_engine": state.career_engine != null, "health_engine": state.health_engine != null}))
		_check(runtime.runtime_slice_phase_timings.has("player_phase_contract"), "Age changed without running the player health, school and career phase")
	_check(state.player.age == old_age + 1 and state.year == old_year + 1, "Age Up advanced more than one year")
	var entries: Array = state.life_diary_contract_engine.diary_entries_for_actor(state.player_id)
	_check(entries.any(func(row): return row is Array and row.has("Age: %d" % state.player.age)), "Completed year is missing from the authoritative diary")
	years_completed += 1
	return not failed

func _answer_blocking_prompt() -> bool:
	var scenario: ScenarioPanel = current_scene.get("scenario_panel")
	if scenario != null and scenario.is_visible_in_tree():
		for control in scenario.buttons_box.get_children():
			if control is Button and control.is_visible_in_tree() and not control.disabled:
				print("DESKTOP CHOICE: ", scenario.title_label.text, " -> ", control.text)
				choices_made += 1
				await _click(control)
				return true
	var popup: Control = current_scene.get("action_result_popup")
	if popup != null and popup.is_visible_in_tree():
		var choices: VBoxContainer = current_scene.get("action_result_popup_choices")
		for control in choices.get_children():
			if control is Button and control.is_visible_in_tree() and not control.disabled:
				print("DESKTOP CHOICE: ", current_scene.get("action_result_popup_title").text, " -> ", control.text)
				choices_made += 1
				await _click(control)
				return true
		# Informational result cards close on click; choices are handled above.
		await _click_at(current_scene.get("action_result_popup_card").get_global_rect().get_center())
		return true
	return false

func _save(previous_entries: Array) -> void:
	var state: GameState = current_scene.get("gs")
	if not await _click(_navigation_button("world")):
		return
	await create_timer(2).timeout
	var save_button: Button = null
	for button in current_scene.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and "Save Game" in button.text:
			save_button = button
			break
	await _capture("world")
	# Background world events can arrive after the save commits. Only require
	# events that already existed when the user pressed Save to survive reload.
	var saved_world_feed: Array = state.world_feed.duplicate(true)
	if not await _click(save_button):
		return
	if not _check(await _wait_for(func(): return current_scene.has_meta("world_lineage_save_last_report") and not current_scene.get_meta("world_lineage_save_in_progress", false), 60), "Save did not finish"):
		return
	var report: Dictionary = current_scene.get_meta("world_lineage_save_last_report", {})
	_check(report.get("success", false), "Save failed: " + str(report))
	var path: String = current_scene.get_meta("world_lineage_save_path", "")
	_check(FileAccess.file_exists(path), "Save file missing")
	var payload: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path))
	var stored_texts: Array = payload.get("world_feed", []).map(func(row): return str(row.get("text", "")) if row is Dictionary else str(row))
	_check(saved_world_feed.all(func(row): return (str(row.get("text", "")) if row is Dictionary else str(row)) in stored_texts), "Save omitted world events that existed before the click")
	var diary: Dictionary = state.scenario_state.get("life_diary_state_by_npc", {}).get(str(state.player_id), {})
	if state.life_diary_contract_engine != null:
		diary = {"entries": state.life_diary_contract_engine.diary_entries_for_actor(state.player_id)}
	_check(not diary.get("entries", []).is_empty(), "Aged life has no diary to preserve")
	for old_entry in previous_entries:
		_check(old_entry in diary.get("entries", []), "Aging after reload lost an earlier diary year")
	_check(diary.get("entries", []) == payload.scenario_state.get("life_diary_state_by_npc", {}).get(str(state.player_id), {}).get("entries", []), "Save did not capture the current diary")
	var expected := {"path": path, "mode": origin_mode, "years_completed": years_completed, "checkpoints_restored": checkpoints_restored, "id": state.player_id, "first_name": state.player.first_name, "last_name": state.player.last_name, "age": state.player.age, "year": state.year, "money": state.player.bank_balance, "parents": state.player.parents, "diary": diary, "world_feed": payload.get("world_feed", []), "household": state.scenario_state.get("custom_household_member_index", {}), "story": state.scenario_state.get("choose_adventure", {})}
	expected["player_fields"] = {}
	for field in PERSISTED_PLAYER_FIELDS:
		expected.player_fields[field] = state.player.get(field)
	var file := FileAccess.open("user://desktop-expected.json", FileAccess.WRITE)
	var saved_actor: Dictionary = payload.npcs.filter(func(row): return int(row.id) == state.player_id)[0]
	expected["affection"] = saved_actor.get("affection", {})
	expected["choices_made"] = choices_made
	file.store_string(JSON.stringify(expected))
	print("DESKTOP SAVED: ", path, " age=", state.player.age, " year=", state.year, " diary=", diary.get("entries", []).size(), " feed=", state.world_feed.size())

func _restore() -> void:
	if not _check(FileAccess.file_exists("user://desktop-expected.json"), "No saved test expectation in this isolated profile"):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://desktop-expected.json"))
	if not _check(parsed is Dictionary, "Test expectation is not valid JSON"):
		return
	var expected: Dictionary = parsed
	if not _check(not expected.is_empty(), "No saved test expectation in this isolated profile"):
		return
	var saved_payload: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(str(expected.path)))
	if not _check(not saved_payload.is_empty(), "Saved checkpoint could not be decoded before Continue"):
		return
	origin_mode = str(expected.mode)
	years_completed = int(expected.get("years_completed", 0))
	checkpoints_restored = int(expected.get("checkpoints_restored", 0)) + 1
	choices_made = int(expected.get("choices_made", 0))
	if not _check(await _wait_for(func(): return current_scene.call("_title_card_continue_available"), 60), "Saved life is not available from the title screen"):
		return
	if portrait:
		var overlay := current_scene.get("startup_intro_overlay") as Control
		if not await _click(overlay.get_node_or_null("MobileAccountActions/Continue")):
			return
	else:
		for pressed in [true, false]:
			var key := InputEventKey.new()
			key.keycode = KEY_C
			key.pressed = pressed
			Input.parse_input_event(key)
			await process_frame
	if not _check(await _wait_for(func(): return current_scene.call("_playable_life_shell_has_visible_sovereignty"), 125), "Continue did not restore gameplay"):
		return
	var first_frame_state: GameState = current_scene.get("gs")
	print("DESKTOP RESUME FIRST FRAME: ", JSON.stringify({"age": first_frame_state.player.age, "year": first_frame_state.year, "affection": first_frame_state.player.affection}))
	# The first playable frame precedes background checkpoint hydration.
	if not _check(await _wait_for(_hydration_complete, 90), "Checkpoint hydration did not finish"):
		return
	var state: GameState = current_scene.get("gs")
	_verify_shared_checkpoint(saved_payload, state)
	for field in ["id", "first_name", "last_name", "age"]:
		_check(state.player.get(field) == expected[field], "Reload changed player " + field)
	_check(state.year == expected.year, "Reload changed year")
	_check(state.scenario_state.get("choose_adventure", {}) == expected.get("story", {}), "Reload lost narrative history")
	_check(state.player.bank_balance == expected.money, "Reload changed money")
	for field in expected.get("player_fields", {}):
		_check(JSON.parse_string(JSON.stringify(state.player.get(field))) == expected.player_fields[field], "Reload changed player " + field + ": expected " + str(expected.player_fields[field]) + ", got " + str(state.player.get(field)))
	for actor_key in expected.get("affection", {}):
		_check(state.player.affection.get(int(actor_key)) == expected.affection[actor_key], "Reload changed relationship score for " + str(actor_key) + ": expected " + str(expected.affection[actor_key]) + ", got " + str(state.player.affection.get(int(actor_key))))
	print("DESKTOP RELATIONSHIPS: ", state.player.affection)
	_check(JSON.parse_string(JSON.stringify(state.player.parents)) == expected.parents, "Reload changed parents")
	for parent_id in state.player.parents:
		var parent: Person = state.get_npc_by_id(int(parent_id))
		_check(parent != null and parent.children.has(state.player_id), "Reload lost reciprocal parent link")
	for key in expected.household:
		var actor: Person = state.get_npc_by_id(int(expected.household[key]))
		_check(actor != null, "Reload dropped household member " + key)
	var diary: Dictionary = state.scenario_state.get("life_diary_state_by_npc", {}).get(str(state.player_id), {})
	var entries: Array = diary.get("entries", [])
	for entry in expected.diary.get("entries", []):
		_check(JSON.stringify(entry) in entries.map(func(row): return JSON.stringify(row)), "Reload lost a diary entry")
	_check(state.world_feed.size() >= expected.world_feed.size(), "Reload lost world history")
	var restored_texts: Array = state.world_feed.map(func(row): return str(row.get("text", "")) if row is Dictionary else str(row))
	_check(expected.world_feed.all(func(row): return (str(row.get("text", "")) if row is Dictionary else str(row)) in restored_texts), "Reload changed saved world events")
	print("DESKTOP RESTORED: ", expected.mode, " age=", state.player.age, " year=", state.year, " diary=", entries.size(), " feed=", state.world_feed.size())
	var output: RichTextLabel = current_scene.get("output_label")
	_check(await _wait_for(func(): return output.get_parsed_text().contains("Age: %d" % state.player.age), 10), "Reload shows an old age in the visible diary")
	await _capture("life")
	if not failed and years_per_run > 0:
		await _age_and_save()
	elif not failed and OS.get_environment("ERA_EXPLORE") == "1":
		await _inspect_gameplay()

func _verify_shared_checkpoint(payload: Dictionary, state: GameState) -> void:
	var saved_businesses: Dictionary = payload.get("scenario_state", {}).get("family_businesses", {})
	if saved_businesses.get("ventures", {}).is_empty():
		return
	_check(JSON.parse_string(JSON.stringify(state.scenario_state.get("family_businesses", {}))) == saved_businesses, "Reload changed company ownership, cast, settlement year or history")
	_check(JSON.parse_string(JSON.stringify(state.scenario_state.get("life_stories", {}))) == payload.scenario_state.get("life_stories", {}), "Reload changed story choices, cast or history")
	if not _check(state.bank_engine != null, "Reload did not initialize banking"):
		return
	var saved_accounts: Dictionary = payload.get("bank_engine_state", {}).get("accounts", {})
	for account_id in saved_accounts:
		var live: Dictionary = state.bank_engine.accounts.get(account_id, {})
		for field in ["owner_id", "world_id", "currency", "balance", "status"]:
			_check(live.get(field) == saved_accounts[account_id].get(field), "Reload changed bank account %s field %s" % [account_id, field])
	var businesses := FamilyBusinessEngine.new(state)
	var before: Dictionary = state.scenario_state.get("family_businesses", {}).duplicate(true)
	var balances: Dictionary = {}
	for venture_id in saved_businesses.ventures:
		var saved: Dictionary = saved_businesses.ventures[venture_id]
		var venture: Dictionary = before.get("ventures", {}).get(venture_id, {})
		balances[venture_id] = businesses.balance(venture)
		for cast in saved.get("cast", {}).values():
			var person: Person = state.get_npc_by_id(int(cast.get("id", -1)), false)
			_check(person != null, "Reload dropped a recurring business participant")
	businesses.service_actor(state.player)
	businesses.service_actor(state.player)
	_check(before == state.scenario_state.get("family_businesses", {}), "Repeated same-year business servicing changed settlement history")
	for venture_id in balances:
		_check(businesses.balance(before.ventures[venture_id]) == balances[venture_id], "Reload awarded duplicate company income")
	print("DESKTOP BUSINESS RESTORED: actor=", state.player_id, " personal=", state.player.bank_balance, " reserves=", JSON.stringify(balances))

func _hydration_complete() -> bool:
	var host: GameState = current_scene.get("reality_residency_host_game_state")
	if host == null or host.reality_residency_manager == null:
		return false
	var signature: String = current_scene.get("reality_residency_attached_signature")
	var record: Dictionary = host.reality_residency_manager.resident_records.get(signature, {})
	if Time.get_ticks_msec() - last_hydration_diagnostic_ms >= 10000:
		last_hydration_diagnostic_ms = Time.get_ticks_msec()
		var diagnostic := {"signature": signature, "at_ms": last_hydration_diagnostic_ms}
		for key in ["state", "service_attempts", "lens_attached", "resident_chassis_tail_complete", "checkpoint_payload_apply_pending", "checkpoint_payload_tail_failed", "checkpoint_payload_tail_failure_reason", "checkpoint_progressive_hydration_started", "checkpoint_progressive_hydration_current_tier", "checkpoint_engine_graph_main_thread_report", "checkpoint_progressive_hydration_last_slice_report"]:
			diagnostic[key] = record.get(key)
		var state: GameState = current_scene.get("gs")
		diagnostic["actor_id"] = state.player_id
		if state.game_state_hydration_runtime != null:
			var hydration = state.game_state_hydration_runtime
			diagnostic["queue_front"] = hydration.background_hydration_queue.front() if not hydration.background_hydration_queue.is_empty() else {}
			diagnostic["last_slice"] = hydration.last_background_hydration_report
		print("DESKTOP HYDRATION: ", JSON.stringify(diagnostic))
	return not record.is_empty() and not record.get("checkpoint_payload_apply_pending", true) and record.get("resident_chassis_tail_complete", false) and record.get("checkpoint_payload_tail_complete", false) and not record.get("checkpoint_payload_tail_failed", false)
