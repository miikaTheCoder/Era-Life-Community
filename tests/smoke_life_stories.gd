extends "smoke_desktop_modes.gd"

# Reuse real Household entry, mouse/touch routing, aging, and checkpoint save.
# This isolated fixture adds a friend so the childhood story is reproducible.
func _age_and_save() -> void:
	var state: GameState = current_scene.get("gs")
	current_scene.call("_ensure_pending_situation_engines")
	var friend := Person.new()
	friend.id = state.next_id
	state.next_id += 1
	friend.first_name = "Casey"
	friend.last_name = "River"
	friend.age = state.player.age
	friend.friends = [state.player.id]
	state.player.friends.append(friend.id)
	state.npcs.append(friend)
	state._rebuild_npc_index()
	var runtime = state.scenario_runtime_contract_engine
	runtime.life_story_service_signature = ""
	if not _check(await _wait_for(func():
		runtime.service_life_stories()
		return state.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player.id), {}).get("stories", {}).has("childhood_pact")
	, 30), "Childhood story did not surface in ordinary Household play"):
		return
	var record: Dictionary = state.scenario_state.life_stories.actors[str(state.player.id)].stories.childhood_pact
	var source_id: String = runtime.life_story_engine._contract_id(record)
	state.pending_situations_engine.build_pending_list_payload(state.player.id)
	await create_timer(1).timeout
	current_scene.call("_on_pending_situations_button_pressed")
	await create_timer(1).timeout
	var viewer: PopupViewer = current_scene.get("popup_viewer")
	if not _check(viewer != null and viewer.is_visible_in_tree(), "Pending situations did not open"):
		return
	var view_id := ""
	for id in viewer.active_contracts:
		var row: Dictionary = viewer.active_contracts[id]
		if str(row.get("source_contract_id", row.get("id", ""))) == source_id:
			view_id = str(id)
	if not _check(view_id != "", "New story was absent from the resident pending list"):
		return
	current_scene.call("_on_popup_viewer_contract_selected", view_id)
	await create_timer(1).timeout
	await _capture("life-story-choice")
	_check(viewer.body_label.get_parsed_text().contains("Casey River"), "Story view lost its named cast")
	_check(viewer.body_label.get_parsed_text().contains("respond through year %d" % int(record.deadline_year)), "Story view omitted its deadline")
	var choice: Button = null
	for control in viewer.options_box.get_children():
		if control is Button and control.text == "Walk home together":
			choice = control
	if not _check(choice != null, "Authored response was replaced by generic perspective options"):
		return
	var viewport: Rect2 = current_scene.get_viewport_rect()
	_check(viewport.encloses(choice.get_global_rect()), "Story choice extends beyond the viewport")
	if viewport.size.x < 600 and viewport.size.y >= 800:
		_check(viewer.body_label.size.y >= 200, "Portrait story text is squeezed above unused choice space")
	if not await _click(choice):
		return
	if not _check(await _wait_for(func(): return str(record.status) == "waiting", 20), "Visible story response did not commit"):
		return
	_check(record.history.size() == 1 and record.history[0].choice == "stand_beside", "Story input committed more than once")
	var diary_text := str(state.life_diary_contract_engine.diary_entries_for_actor(state.player.id))
	_check(diary_text.count("I stood beside Casey River") == 1, "Story resolution was missing or duplicated in the diary")
	await _capture("life-story-result")
	var popup: Control = current_scene.get("action_result_popup_card")
	if popup != null and popup.is_visible_in_tree():
		await _click_at(popup.get_global_rect().get_center())
	await create_timer(1).timeout
	# Closing a result restores the pending viewer; close that restored surface
	# before trying Age Up behind it.
	if viewer.is_visible_in_tree():
		viewer.call("_on_close_pressed")
	await create_timer(1).timeout
	print("LIFE STORIES GRAPHICAL: choice PASS; actor=", state.player.id, "; due_year=", record.due_year)
	await super._age_and_save()
	_check(str(record.status) == "waiting", "One age-up prematurely advanced a six-year follow-up")
	var saved_path: String = current_scene.get_meta("world_lineage_save_path", "")
	if saved_path != "" and FileAccess.file_exists(saved_path):
		var payload: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(saved_path))
		var saved_story: Dictionary = payload.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player.id), {}).get("stories", {}).get("childhood_pact", {})
		_check(saved_story.get("status", "") == "waiting" and int(saved_story.get("cast_id", -1)) == friend.id, "Graphical Save dropped the ongoing story or its cast")
		_check(payload.npcs.any(func(row): return int(row.id) == friend.id), "Graphical Save omitted the recurring friend")
	if MobileSupport.is_enabled():
		current_scene.call("_open_saved_life_picker", "load")
		await create_timer(0.5).timeout
		var picker: Control = current_scene.get("saved_life_picker_popup")
		_check(viewport.encloses(picker.get_global_rect()), "Phone save picker extends beyond the viewport")
		var cancel: Control = current_scene.get("saved_life_picker_cancel_button")
		_check(viewport.encloses(cancel.get_global_rect()), "Phone save picker Back button is unreachable")
		current_scene.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await create_timer(0.5).timeout
		_check(not picker.visible, "Android Back did not close the top save picker")
