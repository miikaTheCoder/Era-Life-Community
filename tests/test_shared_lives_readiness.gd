extends "test_shared_lives.gd"

# Full catalog, ordinary admission and authored timing. This intentionally does
# not use _only(), _found(), _chapter(), or the filtered child-switch helper.
func _ready_fixture() -> GameState:
	var state := _business_fixture()
	state.player.age = 35
	state.get_npc_by_id(106, false).age = 18
	state.get_npc_by_id(107, false).age = 0
	return state

func _record_for(state: GameState, id: String) -> Dictionary:
	return state.scenario_state.get("life_stories", {}).get("actors", {}).get(str(state.player_id), {}).get("stories", {}).get(id, {})

func _resolve(state: GameState, id: String, choice: String) -> Dictionary:
	var pending := _pending(state, id)
	if pending.is_empty():
		_check(false, "Readiness route has no pending chapter: " + id)
		return {}
	return state.pending_situations_engine.resolve_pending_contract(str(pending.id), choice, {"viewer_actor_id": state.player_id})

func _service(state: GameState, focus: String) -> void:
	var runtime = state.scenario_runtime_contract_engine
	runtime.service_life_stories()
	for contract in runtime.active_popup_contracts.values().duplicate():
		if str(contract.get("request", "")) != "life_story":
			continue
		var id := str(contract.source_result.story_id)
		if id == focus:
			continue
		var definition: Dictionary = runtime.life_story_engine._definition(id)
		var node: Dictionary = definition.nodes[str(contract.source_result.node_id)]
		_check(_resolve(state, id, str(node.default)).get("success", false), "Competing story default failed: " + id)

func _year(state: GameState, focus: String) -> void:
	state.year += 1
	for person in state.npcs:
		person.age += 1
	_service(state, focus)

func _await_chapter(state: GameState, id: String) -> Dictionary:
	for step in range(40):
		_service(state, id)
		var pending := _pending(state, id)
		if not pending.is_empty():
			_check(str(pending.overview).contains("respond through year"), "Missing readable calendar deadline")
			_check(not str(pending.overview).contains("{cofounder}"), "Unresolved cast token")
			return pending
		_year(state, id)
	_check(false, "Story was not discoverable with the full catalog: " + id)
	return {}

func _run() -> void:
	var state := _ready_fixture()
	_await_chapter(state, "family_business")
	_check(state.scenario_runtime_contract_engine.life_story_engine.catalog.size() >= 8, "Readiness filtered the catalog")
	_check(state.year > 2000, "Fixture did not exercise competition from earlier stories")
	var offer := _pending(state, "family_business")
	_check(str(offer.response_options).contains("1200") and str(offer.response_options).contains("your bank"), "Investment price or payer is hidden")
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance": true})
	var account_id := str(account.get("account_id", ""))
	_check(account_id != "", "Personal account was not available")
	state.bank_engine.set_account_status(account_id, "frozen")
	var stories_before := JSON.stringify(state.scenario_state.life_stories)
	var money_before: int = state.player.bank_balance
	_check(not _resolve(state, "family_business", "found").get("success", true), "Frozen payment unexpectedly succeeded")
	_check(JSON.stringify(state.scenario_state.life_stories) == stories_before and state.player.bank_balance == money_before,
		"Failed investment advanced the chapter or changed money")
	_check(FamilyBusinessEngine.new(state).ventures_for(state.player_id).is_empty(), "Failed investment created a company")
	state.bank_engine.set_account_status(account_id, "open")
	_check(_resolve(state, "family_business", "found").get("success", false), "Affordable investment failed after rejection")
	var record := _record_for(state, "family_business")
	if not record.has("venture_id"):
		quit(1)
		return
	var venture: Dictionary = state.scenario_state.family_businesses.ventures[record.venture_id]
	var founder_year: int = state.year
	for choice in ["shared", "smaller", "rotate", "reduce", "open", "stay", "scale_back", "steady", "handover"]:
		_await_chapter(state, "family_business")
		_check(_resolve(state, "family_business", choice).get("success", false), "Founder route failed at " + choice)
	_check(record.status == "finished" and state.year - founder_year == 12, "Founder route did not follow its authored calendar")
	_check(int(venture.manager_id) == 106 and int(venture.stakes.get("106", 0)) == 60, "Handover lost the heir's ownership")
	var cast_before := JSON.stringify(venture.cast)
	var company_id := str(venture.id)
	state.player = state.get_npc_by_id(106, false)
	state.player_id = 106
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	for choice in ["read", "keep", "steward"]:
		_await_chapter(state, "family_business_heir")
		_check(_resolve(state, "family_business_heir", choice).get("success", false), "Inherited route failed at " + choice)
	_check(_record_for(state, "family_business_heir").status == "finished", "Inherited continuation did not finish")
	_check(str(venture.id) == company_id and JSON.stringify(venture.cast) == cast_before, "Heir received a replacement company or cast")
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	var saved: Dictionary = payload.scenario_state.family_businesses.ventures[company_id]
	_check(saved.stakes == JSON.parse_string(JSON.stringify(venture.stakes)) and saved.legacy == "a_living_family_business", "Saved inherited consequences are wrong")
	_check(int(payload.bank_engine_state.accounts[venture.account_id].balance) == FamilyBusinessEngine.new(state).balance(venture), "Save changed inherited company reserves")
	_check(not state.life_diary_contract_engine.diary_entries_for_actor(106).is_empty(), "Heir's decisions were absent from the diary")
	print("SHARED LIVES READINESS: founder start=", founder_year, " heir finished=", state.year, " company=", company_id, " reserves=", FamilyBusinessEngine.new(state).balance(venture))
	var declined := _ready_fixture()
	_await_chapter(declined, "family_business")
	_check(not _resolve(declined, "family_business", "not_a_choice").get("success", true), "Unavailable response was accepted")
	_check(_resolve(declined, "family_business", "decline").get("success", false), "Declining was not playable")
	_check(FamilyBusinessEngine.new(declined).ventures_for(declined.player_id).is_empty(), "Declining created a company")
	for step in range(4):
		_year(declined, "family_business")
	_check(_pending(declined, "family_business").is_empty() and _record_for(declined, "family_business").status == "finished", "Declined offer reappeared")
	print("SHARED LIVES READINESS TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
