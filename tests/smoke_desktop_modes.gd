extends SceneTree

# Run with Godot 4.4.1, an isolated XDG_DATA_HOME and a graphical display.
# ERA_MODE selects narrative-family, narrative-continue, household, god, or restore.
# ERA_PREVIEW_DIR optionally records screenshots. No existing saves are used.
var mode := OS.get_environment("ERA_MODE")
var failed := false

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
	var directory := OS.get_environment("ERA_PREVIEW_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(mode + "-" + label + ".png"))

func _click_at(point: Vector2) -> void:
	var position := root.get_final_transform() * point
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

func _run() -> void:
	if mode.is_empty():
		mode = "narrative-family"
	if not _check(not OS.get_environment("XDG_DATA_HOME").is_empty(), "Use scripts/test-desktop-modes.sh to isolate test saves"):
		quit(1)
		return
	root.size = Vector2i(1440, 900)
	root.unresizable = true
	root.min_size = Vector2i(1440, 900)
	root.max_size = Vector2i(1440, 900)
	change_scene_to_file("res://scenes/main.scn")
	await create_timer(3).timeout
	current_scene.call("_skip_startup_intro_to_title_card")
	await create_timer(2).timeout
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
	if not await _click(viewer.prewarm_button):
		return
	if not _check(await _wait_for(func(): return viewer.engine.current_state().get("viewer_ready_button_enabled", false), 100), "God Mode did not become ready"):
		return
	if not await _click(viewer.prewarm_button):
		return
	_check(await _wait_for(func(): return not viewer.is_visible_in_tree() and current_scene.call("_playable_life_shell_has_visible_sovereignty")), "God Mode did not enter gameplay")
	await _capture("life")

func _household() -> void:
	if not _check(await _wait_for(func(): return is_instance_valid(current_scene.get("household_creator_overlay")) and current_scene.get("household_creator_overlay").visible), "Household did not open on first click"):
		return
	if not await _click(current_scene.find_child("HouseholdCreatorBigCreateButton", true, false)):
		return
	await _click(current_scene.get("household_creator_reality_buttons").get("realistic"))
	await _capture("world-setup")
	if not await _click(current_scene.get("household_creator_prewarm_button")):
		return
	if not _check(await _wait_for(func(): return current_scene.get("household_creator_world_prewarmed")), "Household world seed was not created"):
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
	var list: VBoxContainer = current_scene.get("household_creator_start_selection_list")
	if not _check(is_instance_valid(list) and list.get_child_count() == 3, "Household start selection missing"):
		return
	await _capture("select-member")
	if not await _click(list.get_child(1)):
		return
	if not _check(await _wait_for(func(): return not current_scene.get_meta("prepared_mode_entry_pending", false) and current_scene.call("_playable_life_shell_has_visible_sovereignty"), 125), "Household did not enter a life"):
		return
	var state: GameState = current_scene.get("gs")
	_check(state.player.first_name == "Bea" and state.player.age == 8, "Selected household member was not used")
	_check(state.player.smarts == 88 and state.player.job == "Student", "Selected member's stats or school identity were lost")
	_check(state.scenario_state.get("custom_household_member_index", {}).size() == 3, "World did not keep all authored household members")
	var mother: Person = null
	for actor in state.npcs:
		if actor.first_name == "Ada" and actor.last_name == "Desktop":
			mother = actor
	_check(mother != null, "Created parent missing")
	if mother != null:
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
	var old_age := state.player.age
	var old_year: int = state.year
	var previous_entries: Array = state.scenario_state.get("life_diary_state_by_npc", {}).get(str(state.player_id), {}).get("entries", [])
	var age_button: Button = null
	for button in current_scene.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text.to_upper().strip_edges() == "AGE UP":
			age_button = button
			break
	if not await _click(age_button):
		return
	if not _check(await _wait_for(func(): return state.year > old_year and state.player.age > old_age, 60), "Age Up did not advance the simulation"):
		return
	await create_timer(4).timeout
	_check(state.player.age == old_age + 1 and state.year == old_year + 1, "Age Up advanced more than one year")
	await _capture("aged")
	if not await _click(current_scene.get("ui_nav_buttons").get("world")):
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
	var expected := {"path": path, "mode": mode, "id": state.player_id, "first_name": state.player.first_name, "last_name": state.player.last_name, "age": state.player.age, "year": state.year, "money": state.player.bank_balance, "parents": state.player.parents, "diary": diary, "world_feed": payload.get("world_feed", []), "household": state.scenario_state.get("custom_household_member_index", {}), "story": state.scenario_state.get("choose_adventure", {})}
	var file := FileAccess.open("user://desktop-expected.json", FileAccess.WRITE)
	var saved_actor: Dictionary = payload.npcs.filter(func(row): return int(row.id) == state.player_id)[0]
	expected["affection"] = saved_actor.get("affection", {})
	file.store_string(JSON.stringify(expected))
	print("DESKTOP SAVED: ", path, " age=", state.player.age, " year=", state.year, " diary=", diary.get("entries", []).size(), " feed=", state.world_feed.size())

func _restore() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://desktop-expected.json"))
	if not _check(not expected.is_empty(), "No saved test expectation in this isolated profile"):
		return
	if not _check(await _wait_for(func(): return current_scene.call("_title_card_continue_available"), 60), "Saved life is not available from the title screen"):
		return
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_C
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	if not _check(await _wait_for(func(): return current_scene.call("_playable_life_shell_has_visible_sovereignty"), 125), "Continue did not restore gameplay"):
		return
	# The first playable frame precedes background checkpoint hydration.
	if not _check(await _wait_for(_hydration_complete, 90), "Checkpoint hydration did not finish"):
		return
	var state: GameState = current_scene.get("gs")
	for field in ["id", "first_name", "last_name", "age"]:
		_check(state.player.get(field) == expected[field], "Reload changed player " + field)
	_check(state.year == expected.year, "Reload changed year")
	_check(state.scenario_state.get("choose_adventure", {}) == expected.get("story", {}), "Reload lost narrative history")
	_check(state.player.bank_balance == expected.money, "Reload changed money")
	for actor_key in expected.get("affection", {}):
		_check(state.player.affection.get(int(actor_key)) == expected.affection[actor_key], "Reload lost a relationship score")
	_check(JSON.stringify(state.player.parents) == JSON.stringify(expected.parents), "Reload changed parents")
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
	if not failed:
		await _age_and_save()

func _hydration_complete() -> bool:
	var host: GameState = current_scene.get("reality_residency_host_game_state")
	if host == null or host.reality_residency_manager == null:
		return false
	var signature: String = current_scene.get("reality_residency_attached_signature")
	var record: Dictionary = host.reality_residency_manager.resident_records.get(signature, {})
	return not record.is_empty() and not record.get("checkpoint_payload_apply_pending", true) and record.get("resident_chassis_tail_complete", false)
