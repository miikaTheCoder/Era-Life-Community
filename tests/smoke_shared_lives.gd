extends "smoke_desktop_modes.gd"

# Real Household entry and UI input; the isolated fixture supplies two known
# existing contacts so the ensemble story is repeatable without random casting.
func _age_and_save() -> void:
	var state: GameState = current_scene.get("gs")
	current_scene.call("_ensure_pending_situation_engines")
	if not _check(await _wait_for(func(): return state.player.realm_id >= 0), "Household realm did not finish loading"):
		return
	for member in [{"first":"Casey","last":"River","age":35,"role":"friend"}, {"first":"Robin","last":"Ledger","age":55,"role":"mentor"}]:
		var person := Person.new()
		person.id = state.next_id
		state.next_id += 1
		person.first_name = member.first
		person.last_name = member.last
		person.age = member.age
		person.bank_balance = 10000
		person.affection[state.player.id] = 60
		state.player.affection[person.id] = 60
		state.npcs.append(person)
		if member.role == "friend":
			state.player.friends.append(person.id)
		else:
			state.player.coworkers.append(person.id)
	state._rebuild_npc_index()
	state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
	if int(state.bank_engine.get_owner_summary_for_actor(state.player).get("bank_balance", 0)) < 1200:
		state.bank_engine.credit_bank(state.bank_engine.owner_key_from_actor(state.player), 10000)
	var runtime = state.scenario_runtime_contract_engine
	var stories: LifeStoryEngine = runtime._ensure_life_story_engine()
	stories.catalog = stories.catalog.filter(func(row): return str(row.id) == "family_business")
	runtime.life_story_service_signature = ""
	if not _check(await _wait_for(func():
		runtime.service_life_stories()
		return state.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player.id), {}).get("stories", {}).has("family_business")
	, 30), "Shared Lives did not appear for an eligible adult"):
		return
	var record: Dictionary = state.scenario_state.life_stories.actors[str(state.player.id)].stories.family_business
	var source_id: String = stories._contract_id(record)
	state.pending_situations_engine.build_pending_list_payload(state.player.id)
	if not _check(await _wait_for(func():
		var pending_view = current_scene.get("popup_viewer")
		if pending_view == null:
			return false
		return pending_view.active_contracts.values().any(func(row): return str(row.get("source_contract_id", row.get("id", ""))) == source_id)
	, 30), "The story projection never reached the pending viewer"):
		return
	await create_timer(0.5).timeout
	current_scene.call("_on_pending_situations_button_pressed")
	await create_timer(1).timeout
	var viewer: PopupViewer = current_scene.get("popup_viewer")
	if not _check(viewer != null and viewer.is_visible_in_tree(), "Pending situations did not open"):
		return
	var view_id := ""
	for id in viewer.active_contracts:
		if str(viewer.active_contracts[id].get("source_contract_id", id)) == source_id:
			view_id = str(id)
	if not _check(view_id != "", "Shared Lives was absent from the pending viewer"):
		return
	current_scene.call("_on_popup_viewer_contract_selected", view_id)
	await create_timer(1).timeout
	_check(viewer.body_label.get_parsed_text().contains(str(record.ensemble.cofounder.name)) and viewer.body_label.get_parsed_text().contains(str(record.ensemble.mentor.name)), "The ensemble was not visible in the chapter")
	await _capture("shared-lives-offer")
	var fund: Button = null
	for button in viewer.options_box.get_children():
		if button is Button and button.text.begins_with("Put up the opening capital"):
			fund = button
	if not _check(fund != null and fund.text.contains("1200"), "The real investment and its cost were absent"):
		return
	_check(current_scene.get_viewport_rect().encloses(fund.get_global_rect()), "Business funding choice is outside the screen")
	var old_balance: int = int(state.player.bank_balance)
	if not await _click(fund):
		return
	if not _check(await _wait_for(func(): return record.has("venture_id")), "Visible business choice did not create the company"):
		return
	var venture: Dictionary = state.scenario_state.family_businesses.ventures[str(record.venture_id)]
	_check(int(state.player.bank_balance) == old_balance - 1200 and stories.businesses().balance(venture) == 1200, "Funding did not move exactly $1200")
	_check(record.history.size() == 1, "Funding was committed more than once")
	await _capture("shared-lives-founded")
	var popup: Control = current_scene.get("action_result_popup_card")
	if popup != null and popup.is_visible_in_tree():
		await _click_at(popup.get_global_rect().get_center())
	await create_timer(0.5).timeout
	if viewer.is_visible_in_tree():
		viewer.call("_on_close_pressed")
	await create_timer(0.5).timeout
	current_scene.call("_show_assets_panel")
	if not _check(await _wait_for(func():
		var panel = current_scene.get("assets_panel")
		return panel != null and panel.is_visible_in_tree() and panel.securities_label.text.contains(str(venture.name)) and panel.wealth_label.text.contains("Controlled Assets: 1")
	, 30), "Assets did not show the new business stake"):
		return
	await _capture("shared-lives-assets")
	current_scene.call("_hide_assets_panel")
	await create_timer(1).timeout
	print("SHARED LIVES GRAPHICAL: choice PASS; actor=", state.player.id, "; business=", venture.name)
	await super._age_and_save()
	var path: String = current_scene.get_meta("world_lineage_save_path", "")
	if not _check(FileAccess.file_exists(path), "Shared Lives test save missing"):
		return
	var payload: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path))
	_check(payload.scenario_state.get("family_businesses", {}).get("ventures", {}).has(str(record.venture_id)), "Save dropped business ownership")
	_check(payload.bank_engine_state.accounts.has(str(venture.account_id)), "Save dropped the company bank account")
	_check(int(payload.bank_engine_state.accounts[str(venture.account_id)].balance) == stories.businesses().balance(venture), "Save changed the company's money")
	print("SHARED LIVES GRAPHICAL: save PASS; reserves=", stories.businesses().balance(venture))
