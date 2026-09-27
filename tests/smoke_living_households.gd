extends "smoke_desktop_modes.gd"

const CARE := "household_balance"

# The isolated Household fixture supplies existing family relationships. Story
# admission, competing stories, calendar progression and choice commits are real.
func _age_and_save() -> void:
	var state: GameState = current_scene.get("gs")
	current_scene.call("_ensure_pending_situation_engines")
	if mode != "restore":
		if not _check(await _wait_for(func(): return state.player.realm_id >= 0), "Household realm did not finish loading"):
			return
		var supporter: Person
		for person in state.npcs:
			if person.first_name == "Cora" and person.last_name == "Desktop":
				supporter = person
		if not _check(supporter != null, "Created adult household member is missing"):
			return
		state.player.partner = supporter
		supporter.partner = state.player
		state.player.affection[supporter.id] = 60
		supporter.affection[state.player.id] = 60
		var parent := Person.new()
		parent.id = state.next_id
		state.next_id += 1
		parent.first_name = "Robin"
		parent.last_name = "Desktop"
		parent.age = 60
		parent.children = [state.player_id]
		parent.realm_id = state.player.realm_id
		parent.affection[state.player_id] = 60
		state.player.parents.append(parent.id)
		state.player.affection[parent.id] = 60
		state.npcs.append(parent)
		state._rebuild_npc_index()
		state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
		if state.player.bank_balance < 1000:
			state.bank_engine.credit_bank(state.bank_engine.owner_key_from_actor(state.player), 1000)
		state.scenario_runtime_contract_engine.life_story_service_signature = ""
	var stories: LifeStoryEngine = state.scenario_runtime_contract_engine._ensure_life_story_engine()
	_check(stories.catalog.size() == 10, "Household discovery must retain the full catalog")
	var previous_entries: Array = state.life_diary_contract_engine.diary_entries_for_actor(state.player_id).duplicate(true)
	await _settle_pending(state)
	for offset in range(years_per_run):
		if failed or not await _advance_one_year():
			return
		await _settle_pending(state)
	await _capture("household-aged")
	await _save(previous_entries)
	var record: Dictionary = _care_record(state)
	print("LIVING HOUSEHOLDS GRAPHICAL: save PASS; age=", state.player.age, "; history=", record.get("history", []).size())

func _care_record(state: GameState) -> Dictionary:
	return state.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player_id), {}).get("stories", {}).get(CARE, {})

func _settle_pending(state: GameState) -> void:
	var runtime = state.scenario_runtime_contract_engine
	runtime.service_life_stories()
	print("LIVING HOUSEHOLDS DISCOVERY: year=", state.year, "; stories=", state.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player_id), {}).get("stories", {}).keys())
	for contract in runtime.active_popup_contracts.values().duplicate():
		if str(contract.get("request", "")) != "life_story":
			continue
		var id := str(contract.source_result.story_id)
		var node_id := str(contract.source_result.node_id)
		var definition: Dictionary = runtime.life_story_engine._definition(id)
		var node: Dictionary = definition.nodes[node_id]
		if id == CARE:
			var choice := "fund" if node_id == "request" else str(node.default)
			await _visible_choice(state, contract, choice)
		else:
			var result: Dictionary = state.pending_situations_engine.resolve_pending_contract(str(contract.id), str(node.default), {"viewer_actor_id":state.player_id})
			_check(result.get("success", false), "Competing story default failed: " + id)

func _visible_choice(state: GameState, contract: Dictionary, choice: String) -> void:
	var record := _care_record(state)
	var stories: LifeStoryEngine = state.scenario_runtime_contract_engine.life_story_engine
	var definition: Dictionary = stories._definition(CARE)
	var node: Dictionary = definition.nodes[str(record.node)]
	var label: String = stories._render(stories._choice_label(node, choice), record)
	state.pending_situations_engine.build_pending_list_payload(state.player_id)
	if not _check(await _wait_for(func():
		var view = current_scene.get("popup_viewer")
		return view != null and view.active_contracts.values().any(func(row): return str(row.get("source_contract_id", row.get("id", ""))) == str(contract.id))
	, 30), "Care chapter never reached the pending viewer"):
		return
	var card: Control = current_scene.get("action_result_popup_card")
	if card != null and card.is_visible_in_tree():
		await _click_at(card.get_global_rect().get_center())
	current_scene.call("_on_pending_situations_button_pressed")
	await create_timer(1).timeout
	var viewer: PopupViewer = current_scene.get("popup_viewer")
	var view_id := ""
	for id in viewer.active_contracts:
		if str(viewer.active_contracts[id].get("source_contract_id", id)) == str(contract.id):
			view_id = str(id)
	if not _check(view_id != "", "Care chapter missing from the visible list"):
		return
	current_scene.call("_on_popup_viewer_contract_selected", view_id)
	await create_timer(1).timeout
	_check(viewer.body_label.get_parsed_text().contains(str(record.ensemble.supporter.name)), "Care chapter hid the recurring supporter")
	_check(not viewer.body_label.get_parsed_text().contains("{relative}"), "Care chapter showed an unrendered name")
	await _capture("care-" + str(record.node))
	var button: Button
	for control in viewer.options_box.get_children():
		if control is Button and control.text.begins_with(label):
			button = control
	if not _check(button != null, "Care response is absent: " + label):
		return
	_check(current_scene.get_viewport_rect().encloses(button.get_global_rect()), "Care response is outside the screen")
	var old_count: int = record.history.size()
	var old_balance: int = state.player.bank_balance
	var other: Person = state.get_npc_by_id(int(record.cast_id), false)
	var other_balance: int = other.bank_balance
	if not await _click(button):
		return
	if not _check(await _wait_for(func(): return record.history.size() == old_count + 1), "Visible care response did not commit exactly once"):
		return
	if choice == "fund":
		var cost := stories._amount(300, record)
		_check(state.player.bank_balance == old_balance - cost and other.bank_balance == other_balance + cost, "Visible care payment changed the wrong balance")
	print("LIVING HOUSEHOLDS GRAPHICAL: choice PASS; node=", contract.source_result.node_id, "; choice=", choice, "; history=", record.history.size())
	card = current_scene.get("action_result_popup_card")
	if card != null and card.is_visible_in_tree():
		await _click_at(card.get_global_rect().get_center())
	if viewer.is_visible_in_tree():
		viewer.call("_on_close_pressed")
	await create_timer(0.5).timeout

func _verify_shared_checkpoint(payload: Dictionary, state: GameState) -> void:
	super._verify_shared_checkpoint(payload, state)
	var saved: Dictionary = payload.scenario_state.get("life_stories", {})
	_check(JSON.parse_string(JSON.stringify(state.scenario_state.get("life_stories", {}))) == saved, "Cold Continue changed household story choices, cast or history")
	for account_id in payload.get("bank_engine_state", {}).get("accounts", {}):
		var account: Dictionary = payload.bank_engine_state.accounts[account_id]
		var live: Dictionary = state.bank_engine.accounts.get(account_id, {})
		for field in ["owner_id", "world_id", "currency", "balance", "status"]:
			_check(account.get(field) == live.get(field), "Cold Continue changed a household bank account: " + str(field))
	var record := _care_record(state)
	for member in record.get("ensemble", {}).values():
		_check(state.get_npc_by_id(int(member.id), false) != null, "Cold Continue lost household cast")
	var required := int(OS.get_environment("ERA_REQUIRE_CARE_CHOICES"))
	_check(record.get("history", []).size() >= required, "Household arc was not discovered and continued through ordinary years")
	print("LIVING HOUSEHOLDS RESTORED: history=", record.get("history", []).size(), "; personal=", state.player.bank_balance)
