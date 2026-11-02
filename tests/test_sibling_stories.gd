extends "test_living_households.gd"

const SIBLINGS := "sibling_fairness"
const SIBLING_MEMORY := "sibling_fairness_legacy"
var sibling_responses_checked := 0

func _sibling_fixture() -> GameState:
	var state := _household_fixture()
	var sibling := state.get_npc_by_id(103, false)
	var partner := state.get_npc_by_id(104, false)
	sibling.partner = null
	sibling.parents = [102]
	state.get_npc_by_id(102, false).children = [101, 103]
	state.player.partner = partner
	partner.partner = state.player
	return state

func _finish_care(state: GameState) -> Dictionary:
	state.scenario_runtime_contract_engine.life_story_engine = LifeStoryEngine.new(state)
	var care := _start_care(state)
	for option in ["share", "listen", "together", "ask", "renew"]:
		if _pending(state, CARE).is_empty():
			_advance_to_due(state, CARE)
		_check(_resolve(state, CARE, option).get("success", false), "Preceding care choice failed")
	return care

func _start_siblings(state: GameState) -> Dictionary:
	var care := _finish_care(state)
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	_only(state, SIBLINGS)
	state.year += 2
	state.scenario_runtime_contract_engine.service_life_stories()
	var record := _record_for(state, SIBLINGS)
	_check(not record.is_empty(), "Sibling arc did not start after the care story")
	_check(record.get("origin", "") == CARE and record.get("origin_legacy", "") == care.legacy, "Sibling arc forgot the earlier care outcome")
	return record

func _sibling_node(state: GameState, record: Dictionary, node: String) -> void:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	record.node = node
	record.status = "waiting"
	record.due_year = int(state.year)
	if node == "loss":
		record.lost_person = "Robin Story"
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _memory_life(state: GameState, full_catalog := false) -> void:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	state.player = state.get_npc_by_id(106, false)
	state.player_id = 106
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	if not full_catalog:
		_only(state, SIBLING_MEMORY)
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _run() -> void:
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty(), "Sibling content failed validation: " + str(engine.content_errors))
	_check(engine.catalog.size() == 14, "The expanded catalog lost existing stories")
	_test_sibling_responses(engine)
	_test_sibling_routes()
	_test_sibling_cast()
	_test_sibling_refusal()
	_test_sibling_money()
	_test_sibling_restore()
	_test_sibling_memory()
	print("SIBLING STORIES TESTS: ", "FAIL" if failed else "PASS", "; responses=", sibling_responses_checked)
	quit(1 if failed else 0)

func _test_sibling_responses(engine: LifeStoryEngine) -> void:
	for definition in engine.catalog:
		if str(definition.get("series", "")) != "Family Crossroads":
			continue
		for node_id in definition.nodes:
			for choice in definition.nodes[node_id].choices:
				var state := _sibling_fixture()
				var record := _start_siblings(state)
				if str(definition.id) == SIBLING_MEMORY:
					record.status = "finished"
					record.legacy = "shared_responsibility"
					_memory_life(state)
					record = _record_for(state, SIBLING_MEMORY)
				_sibling_node(state, record, str(node_id))
				var pending := _pending(state, str(definition.id))
				_check(not pending.is_empty(), "Sibling response was unreachable: " + str(node_id))
				if pending.is_empty():
					continue
				for token in ["{relative}", "{supporter}", "{person}", "{lost_person}"]:
					_check(not str(pending.overview).contains(token), "Unrendered sibling cast token: " + token)
				_check(_resolve(state, str(definition.id), str(choice.id)).get("success", false), "Sibling response failed: " + str(node_id) + "/" + str(choice.id))
				_check(not state.scenario_runtime_contract_engine.resolve_popup_contract(str(pending.id), str(choice.id), {"viewer_actor_id":state.player_id}).get("success", true), "Sibling choice committed twice")
				sibling_responses_checked += 1
	_check(sibling_responses_checked == 30, "Not every sibling response was exercised")
	var malformed := {"schema":"eralife.life_stories", "version":1, "stories":[engine._definition(SIBLINGS).duplicate(true)]}
	malformed.stories[0].nodes.comparison.choices[0].relationships[0].to = "stranger"
	_check(not LifeStoryEngine.validate_catalog(malformed).is_empty(), "Unknown sibling relationship role was accepted")

func _test_sibling_routes() -> void:
	var routes := [
		["listen", "ask_parent", "copies", "renew"],
		["deflect", "acknowledge", "show_up", "copies", "renew"],
		["deflect", "step_back", "respect"],
		["deflect", "blame"],
		["listen", "ask_parent", "claim", "private"]]
	var outcomes: Array = []
	for route in routes:
		var state := _sibling_fixture()
		# Ordinary admission of the full catalog also completes the first care arc.
		_await_chapter(state, SIBLINGS)
		var record := _record_for(state, SIBLINGS)
		_check(str(_pending(state, SIBLINGS).overview).contains("The Time We Owe"), "Sibling context showed an internal story ID instead of the preceding title")
		var first_year: int = state.year
		var prior_care := JSON.stringify(_record_for(state, CARE))
		_check(not state.scenario_state.has("family_businesses") or FamilyBusinessEngine.new(state).ventures_for(101).is_empty(), "Sibling arc requires a company")
		for option in route:
			_await_chapter(state, SIBLINGS)
			_check(_resolve(state, SIBLINGS, str(option)).get("success", false), "Full sibling route failed: " + str(option))
		_check(record.status == "finished" and record.history.size() == route.size(), "Sibling route did not finish exactly once")
		_check(state.year > first_year, "Sibling conflict did not span years")
		_check(JSON.stringify(_record_for(state, CARE)) == prior_care, "Sibling story rewrote the care history")
		_check(not state.life_diary_contract_engine.diary_entries_for_actor(101).is_empty(), "Sibling decisions missed the diary")
		outcomes.append(record.legacy)
		print("SIBLING ROUTE: ", route, " year=", first_year, "..", state.year, " outcome=", record.legacy)
	_check(outcomes == ["shared_responsibility", "trust_repaired", "respectful_distance", "unresolved_resentment", "private"], "Distinct sibling routes lost their inherited outcomes")

func _test_sibling_cast() -> void:
	var fresh := _sibling_fixture()
	_only(fresh, SIBLINGS)
	fresh.scenario_runtime_contract_engine.service_life_stories()
	_check(_record_for(fresh, SIBLINGS).is_empty(), "Sibling continuation started without its preceding care story")
	var state := _sibling_fixture()
	var record := _start_siblings(state)
	_check(int(record.cast_id) == 103 and int(record.ensemble.relative.id) == 102, "Sibling cast did not use the same parent and an existing sibling")
	_check(int(_record_for(state, CARE).cast_id) == 104, "Fixture did not distinguish partner from sibling")
	var sibling := state.get_npc_by_id(103, false)
	state.npcs.erase(sibling)
	state._rebuild_npc_index()
	var before := JSON.stringify(record)
	_check(not _resolve(state, SIBLINGS, "contribute").get("success", true), "Unavailable sibling accepted money")
	state.year = int(record.deadline_year) + 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(JSON.stringify(record) == before and int(record.cast_id) == 103, "Missing sibling was replaced or the deadline changed history")
	state.npcs.append(sibling)
	state._rebuild_npc_index()
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(record.history.size() == 1 and record.history[0].choice == "listen" and record.history[0].automatic, "Returned sibling did not resume the free deadline response")
	for excluded in ["no_sibling", "minor", "deceased", "old_save", "different_parent", "unfinished"]:
		var unsupported := _sibling_fixture()
		var care := _finish_care(unsupported)
		match excluded:
			"no_sibling": unsupported.get_npc_by_id(102, false).children = [101]
			"minor": unsupported.get_npc_by_id(103, false).age = 17
			"deceased": unsupported.get_npc_by_id(103, false).alive = false
			"old_save": care.erase("ensemble")
			"different_parent": unsupported.player.parents = [104]
			"unfinished": care.status = "waiting"
		unsupported.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
		_only(unsupported, SIBLINGS)
		unsupported.year += 2
		unsupported.scenario_runtime_contract_engine.service_life_stories()
		_check(_record_for(unsupported, SIBLINGS).is_empty(), "Invalid sibling cast admitted: " + excluded)
	for id in [102, 103]:
		var bereaved := _sibling_fixture()
		var interrupted := _start_siblings(bereaved)
		bereaved.get_npc_by_id(id, false).alive = false
		bereaved.year += 1
		bereaved.scenario_runtime_contract_engine.service_life_stories()
		_check(interrupted.node == "loss" and interrupted.lost_person == ("Robin Story" if id == 102 else "Casey Story"), "Death did not name the lost participant")
		_check(_resolve(bereaved, SIBLINGS, "remember").get("success", false), "Bereavement did not have a viable free response")

func _test_sibling_refusal() -> void:
	var state := _sibling_fixture()
	var record := _start_siblings(state)
	state.player.affection[103] = 15
	_resolve(state, SIBLINGS, "listen")
	_advance_to_due(state, SIBLINGS)
	_resolve(state, SIBLINGS, "ask_parent")
	_check(record.node == "fracture", "Sibling accepted a new plan despite low trust")
	_advance_to_due(state, SIBLINGS)
	_check(str(_pending(state, SIBLINGS).overview).contains("refuses") and str(_pending(state, SIBLINGS).overview).contains("Previously"), "Sibling refusal or previous choice was hidden")
	_resolve(state, SIBLINGS, "acknowledge")
	_advance_to_due(state, SIBLINGS)
	_resolve(state, SIBLINGS, "buy_break")
	_check(record.node == "distance", "Payment bought forgiveness despite low trust")

func _test_sibling_money() -> void:
	var state := _sibling_fixture()
	var record := _start_siblings(state)
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
	state.bank_engine.set_account_status(account.account_id, "frozen")
	var before := JSON.stringify(record)
	var trust: int = state.player.affection[103]
	_check(not _resolve(state, SIBLINGS, "contribute").get("success", true), "Frozen sibling payment succeeded")
	_check(JSON.stringify(record) == before and state.player.affection[103] == trust, "Rejected sibling payment committed story or relationship effects")
	state.bank_engine.set_account_status(account.account_id, "open")
	_check(_resolve(state, SIBLINGS, "contribute").get("success", false), "Sibling payment could not be retried")
	_check(state.player.bank_balance == 9750 and state.get_npc_by_id(103, false).bank_balance == 10250, "Sibling contribution did not transfer real personal funds")
	for era in ["Ancient Era", "Future Era"]:
		var priced := _sibling_fixture()
		priced.era.name = era
		var priced_record := _start_siblings(priced)
		var cost := 50 if era == "Ancient Era" else 375
		_check(str(_pending(priced, SIBLINGS).response_options).contains(str(cost)), "Sibling price is not visible")
		priced.era.name = "Modern Era"
		_check(_resolve(priced, SIBLINGS, "contribute").get("success", false), "Era-priced sibling payment failed")
		_check(priced.player.bank_balance == 10000 - cost and priced_record.scale == (0.2 if era == "Ancient Era" else 1.5), "An era change repriced the saved promise")
	var poor := _sibling_fixture()
	var poor_record := _start_siblings(poor)
	poor.bank_engine.ensure_bank_account_for_actor(poor.player, {"import_legacy_balance":true})
	poor.bank_engine.spend(poor.bank_engine.owner_key_from_actor(poor.player), 10000)
	before = JSON.stringify(poor_record)
	_check(not _resolve(poor, SIBLINGS, "contribute").get("success", true) and JSON.stringify(poor_record) == before, "Unaffordable sibling choice advanced the story")
	_check(_resolve(poor, SIBLINGS, "listen").get("success", false), "No free sibling response remained")
	var owner := _sibling_fixture()
	var business_record := _found(owner)
	var company := _business(owner, business_record)
	owner.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	owner.year += 2
	_start_siblings(owner)
	var reserves := FamilyBusinessEngine.new(owner).balance(company)
	_check(str(_pending(owner, SIBLINGS).overview).contains("company has its own reserves"), "Sibling owner context is missing")
	_check(_resolve(owner, SIBLINGS, "contribute").get("success", false), "Business owner cannot make a personal sibling payment")
	_check(FamilyBusinessEngine.new(owner).balance(company) == reserves, "Sibling support spent company reserves")

func _test_sibling_restore() -> void:
	var state := _sibling_fixture()
	var record := _start_siblings(state)
	_resolve(state, SIBLINGS, "contribute")
	var expected: Dictionary = JSON.parse_string(JSON.stringify(record))
	var relationships := state.player.affection.duplicate(true)
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	for id in [101, 102, 103]:
		_check(payload.npcs.any(func(row): return int(row.id) == id), "Compact save lost a sibling participant")
	var restored := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	RealityResidencyManager.new(restored)._materialize_checkpoint_resume_shell(restored, {"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "sibling-checkpoint", {})
	restored.era = {"name":payload.era_name}
	restored.bank_engine = BankEngine.new(restored)
	var hydration := GameStateHydrationRuntime.new(restored)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]}, {"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	for step in range(20000):
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	_check(not hydration.is_background_hydration_active(), "Sibling binary hydration did not complete")
	_check(JSON.parse_string(JSON.stringify(_record_for(restored, SIBLINGS))) == expected, "Restore changed sibling cast, origin or decisions")
	_check(restored.player.affection.size() == relationships.size(), "Restore lost a relationship edge")
	for id in relationships:
		_check(float(restored.player.affection.get(id, -1)) == float(relationships[id]), "Restore changed a relationship with actor " + str(id))
	_check(restored.player.bank_balance == 9750 and restored.get_npc_by_id(103, false).bank_balance == 10250, "Restore changed sibling funds")
	restored.resident_runtime_bootstrap_complete = true
	restored.relationship_engine = RelationshipEngine.new(restored)
	restored.memory_engine = MemoryEngine.new(restored)
	restored.life_diary_contract_engine = LifeDiaryContractEngine.new(restored)
	restored.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(restored)
	restored.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(restored)
	restored.pending_situations_engine = PendingSituationsEngine.new(restored)
	_only(restored, SIBLINGS)
	_advance_to_due(restored, SIBLINGS)
	_check(_resolve(restored, SIBLINGS, "ask_parent").get("success", false), "Restored sibling promise could not continue")
	_check(_record_for(restored, SIBLINGS).history.size() == 2 and restored.player.bank_balance == 9750, "Restore duplicated a sibling choice or payment")

func _test_sibling_memory() -> void:
	for legacy in ["shared_responsibility", "unresolved_resentment", "private", "unfinished"]:
		var state := _sibling_fixture()
		var source := _start_siblings(state)
		source.status = "waiting" if legacy == "unfinished" else "finished"
		source.legacy = legacy
		var before := JSON.stringify(source)
		state.get_npc_by_id(103, false).alive = false
		_memory_life(state)
		var inherited := _record_for(state, SIBLING_MEMORY)
		if legacy in ["private", "unfinished"]:
			_check(inherited.is_empty(), "A private or unfinished sibling argument was inherited")
		else:
			_check(inherited.get("origin", "") == SIBLINGS and inherited.get("origin_legacy", "") == legacy, "Child forgot the actual sibling outcome")
			_check(str(_pending(state, SIBLING_MEMORY).overview).contains(legacy.replace("_", " ")), "Child cannot read the inherited outcome")
			_check(_resolve(state, SIBLING_MEMORY, "read").get("success", false), "Remembered deceased sibling prevented continuation")
			_await_chapter(state, SIBLING_MEMORY)
			_check(_resolve(state, SIBLING_MEMORY, "release").get("success", false), "Child could not put down the inherited argument")
			_check(inherited.status == "finished" and inherited.legacy == "argument_released", "Inherited sibling chapter did not finish")
		_check(JSON.stringify(source) == before, "Child rewrote the parent's saved sibling choices")
	var ordinary := _sibling_fixture()
	_await_chapter(ordinary, SIBLINGS)
	for option in ["deflect", "blame"]:
		_await_chapter(ordinary, SIBLINGS)
		_resolve(ordinary, SIBLINGS, option)
	_memory_life(ordinary, true)
	_await_chapter(ordinary, SIBLING_MEMORY)
	_check(str(_pending(ordinary, SIBLING_MEMORY).overview).contains("What We Call Fair"), "Inherited context hid the parent's story title")
	_check(_resolve(ordinary, SIBLING_MEMORY, "question").get("success", false), "Inherited sibling memory was undiscoverable with the full catalog")
	_await_chapter(ordinary, SIBLING_MEMORY)
	_check(_resolve(ordinary, SIBLING_MEMORY, "adapt").get("success", false), "Full-catalog inherited route could not finish")
