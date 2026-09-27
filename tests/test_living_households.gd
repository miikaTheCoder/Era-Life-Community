extends "test_shared_lives_readiness.gd"

const CARE := "household_balance"
const LEGACY := "household_care_legacy"
var responses_checked := 0

func _household_fixture() -> GameState:
	var state := _ready_fixture()
	state.get_npc_by_id(102, false).age = 60
	state.get_npc_by_id(103, false).age = 35
	state.player.partner = state.get_npc_by_id(103, false)
	state.player.partner.partner = state.player
	return state

func _start_care(state: GameState) -> Dictionary:
	_only(state, CARE)
	state.scenario_runtime_contract_engine.service_life_stories()
	var record := _record_for(state, CARE)
	_check(not record.is_empty(), "Care arc did not start for a qualifying household")
	return record

func _care_node(state: GameState, record: Dictionary, id: String) -> void:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	record.node = id
	record.status = "waiting"
	record.due_year = int(state.year)
	if id == "loss":
		record.lost_person = "Robin Story"
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _legacy_life(state: GameState, full_catalog := false) -> void:
	state.player = state.get_npc_by_id(106, false)
	state.player_id = 106
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	if not full_catalog:
		_only(state, LEGACY)
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _run() -> void:
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty(), "Living Households catalog failed validation: " + str(engine.content_errors))
	_check(engine.catalog.size() == 10, "Existing stories were lost")
	_test_responses(engine)
	_test_complete_routes()
	_test_cast_and_loss()
	_test_payments_and_save()
	_test_money_boundaries()
	_test_legacy()
	var malformed := {"schema":"eralife.life_stories", "version":1, "stories":[engine._definition(CARE).duplicate(true)]}
	malformed.stories[0].nodes.request.choices[0].relationships[0].to = "invented_person"
	_check(not LifeStoryEngine.validate_catalog(malformed).is_empty(), "Unknown household relationship role was accepted")
	print("LIVING HOUSEHOLDS TESTS: ", "FAIL" if failed else "PASS", "; authored responses=", responses_checked)
	quit(1 if failed else 0)

func _test_responses(engine: LifeStoryEngine) -> void:
	for definition in engine.catalog:
		if str(definition.get("series", "")) != "Living Households":
			continue
		for node_id in definition.nodes:
			for choice in definition.nodes[node_id].choices:
				var state := _household_fixture()
				var record := _start_care(state)
				if str(definition.id) == LEGACY:
					record.status = "finished"
					record.legacy = "care_shared"
					_legacy_life(state)
					record = _record_for(state, LEGACY)
				_care_node(state, record, str(node_id))
				var pending := _pending(state, str(definition.id))
				_check(not pending.is_empty(), "Missing household chapter " + str(node_id))
				if pending.is_empty():
					continue
				_check(not str(pending.overview).contains("{supporter}") and not str(pending.overview).contains("{relative}"), "Household cast token was not rendered")
				_check(_resolve(state, str(definition.id), str(choice.id)).get("success", false), "Response failed: " + str(node_id) + "/" + str(choice.id))
				_check(not state.scenario_runtime_contract_engine.resolve_popup_contract(str(pending.id), str(choice.id), {"viewer_actor_id":state.player_id}).get("success", true), "Household response committed twice")
				responses_checked += 1
	_check(responses_checked == 30, "Not every household response was exercised")

func _test_complete_routes() -> void:
	for route in [["share","listen","together","ask","renew"], ["limited","promise","accept_limits","clear"], ["share","listen","together","take_over","return_voice"]]:
		var state := _household_fixture()
		# Full catalog and ordinary pacing, including competing eligible stories.
		_await_chapter(state, CARE)
		var record := _record_for(state, CARE)
		var first_year: int = state.year
		_check(not state.scenario_state.has("family_businesses") or FamilyBusinessEngine.new(state).ventures_for(101).is_empty(), "No-business route unexpectedly requires a company")
		for option in route:
			_await_chapter(state, CARE)
			_check(_resolve(state, CARE, str(option)).get("success", false), "Complete household route failed: " + str(option))
		_check(record.status == "finished" and record.history.size() == route.size(), "Household route did not finish exactly once")
		_check(state.year - first_year >= 4, "Household story did not span years")
		_check(record.legacy in ["care_shared","care_with_boundaries","care_repaired"], "Household outcome was not remembered")
		_check(not state.life_diary_contract_engine.diary_entries_for_actor(101).is_empty(), "Household choices missed the diary")
		print("HOUSEHOLD ROUTE: ", route, " start=", first_year, " end=", state.year, " legacy=", record.legacy)
	var low_trust := _household_fixture()
	low_trust.player.affection[103] = 20
	var low_record := _start_care(low_trust)
	_resolve(low_trust, CARE, "share")
	_advance_to_due(low_trust, CARE)
	_resolve(low_trust, CARE, "listen")
	_check(low_record.node == "refusal", "Supporter's refusal ignored the actual relationship")
	_advance_to_due(low_trust, CARE)
	_check(str(_pending(low_trust, CARE).overview).contains("refuses the rota") and str(_pending(low_trust, CARE).overview).contains("Previously"), "Disagreement or earlier choice was hidden")

func _test_cast_and_loss() -> void:
	var state := _household_fixture()
	state.player.partner = null
	state.get_npc_by_id(102, false).children.append(103)
	var record := _start_care(state)
	_check(int(record.ensemble.relative.id) == 102 and int(record.ensemble.supporter.id) == 103, "Adult sibling fallback did not use existing family")
	var old_count := state.npcs.size()
	var missing := state.get_npc_by_id(103, false)
	state.npcs.erase(missing)
	state._rebuild_npc_index()
	_check(not _resolve(state, CARE, "fund").get("success", true), "Unavailable supporter accepted a payment")
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(record.status == "pending" and int(record.cast_id) == 103 and state.npcs.size() == old_count - 1, "Missing supporter was invented or replaced")
	state.npcs.append(missing)
	state._rebuild_npc_index()
	missing.alive = false
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(record.node == "loss" and record.lost_person == "Casey Story", "Death did not surface the named bereavement chapter")
	_check(_resolve(state, CARE, "remember").get("success", false), "Bereavement had no free viable response")
	var unsupported := _household_fixture()
	unsupported.player.partner = null
	_start_care_without_cast(unsupported)
	var deadline := _household_fixture()
	var expired := _start_care(deadline)
	deadline.year = int(expired.deadline_year) + 1
	deadline.scenario_runtime_contract_engine.service_life_stories()
	_check(expired.history.size() == 1 and expired.history[0].choice == "limited" and expired.history[0].automatic, "Deadline did not select the free boundary response")
	_check(deadline.player.bank_balance == 10000, "Deadline spent money without a choice")

func _start_care_without_cast(state: GameState) -> void:
	_only(state, CARE)
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(_record_for(state, CARE).is_empty(), "Care arc invented a partner or sibling")

func _test_payments_and_save() -> void:
	var state := _household_fixture()
	var record := _start_care(state)
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
	state.bank_engine.set_account_status(account.account_id, "frozen")
	var before := JSON.stringify(record)
	_check(not _resolve(state, CARE, "fund").get("success", true), "Frozen care payment succeeded")
	_check(JSON.stringify(record) == before and state.player.bank_balance == 10000, "Rejected payment committed a consequence")
	state.bank_engine.set_account_status(account.account_id, "open")
	_check(_resolve(state, CARE, "fund").get("success", false), "Care payment could not be retried")
	_check(state.player.bank_balance == 9700 and state.get_npc_by_id(103, false).bank_balance == 10300, "Care payment did not move real money to the supporter")
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	for id in [101,102,103]:
		_check(payload.npcs.any(func(row): return int(row.id) == id), "Compact save omitted household cast")
	var restored := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	RealityResidencyManager.new(restored)._materialize_checkpoint_resume_shell(restored, {"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "household-checkpoint", {})
	restored.era = {"name":payload.era_name}
	restored.bank_engine = BankEngine.new(restored)
	var hydration := GameStateHydrationRuntime.new(restored)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]}, {"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	for step in range(20000):
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	_check(not hydration.is_background_hydration_active(), "Household binary hydration did not complete")
	_check(JSON.stringify(_record_for(restored, CARE)) == JSON.stringify(payload.scenario_state.life_stories.actors["101"].stories[CARE]), "Restore changed the care plan or cast")
	_check(restored.player.bank_balance == 9700 and restored.get_npc_by_id(103, false).bank_balance == 10300, "Restore changed personal care balances")
	restored.resident_runtime_bootstrap_complete = true
	restored.relationship_engine = RelationshipEngine.new(restored)
	restored.memory_engine = MemoryEngine.new(restored)
	restored.life_diary_contract_engine = LifeDiaryContractEngine.new(restored)
	restored.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(restored)
	restored.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(restored)
	restored.pending_situations_engine = PendingSituationsEngine.new(restored)
	_only(restored, CARE)
	_advance_to_due(restored, CARE)
	_check(_resolve(restored, CARE, "listen").get("success", false), "Saved care plan could not continue")
	_check(_record_for(restored, CARE).history.size() == 2, "Restored care history duplicated or dropped a decision")

func _test_legacy() -> void:
	for status in ["waiting", "finished"]:
		var excluded := _household_fixture()
		var source := _start_care(excluded)
		source.status = status
		source.legacy = "care_shared" if status == "waiting" else "private"
		_legacy_life(excluded)
		_check(_record_for(excluded, LEGACY).is_empty(), "An unfinished or private care plan became an inherited memory")
	var state := _household_fixture()
	var record := _start_care(state)
	for option in ["share","listen","together","ask","renew"]:
		if _pending(state, CARE).is_empty():
			_advance_to_due(state, CARE)
		_resolve(state, CARE, option)
	var before := JSON.stringify(record)
	state.get_npc_by_id(103, false).alive = false
	_legacy_life(state, true)
	_await_chapter(state, LEGACY)
	var inherited := _record_for(state, LEGACY)
	_check(inherited.get("origin", "") == CARE and inherited.get("origin_legacy", "") == "care_shared", "Descendant did not encounter the actual household legacy")
	_check(_resolve(state, LEGACY, "read").get("success", false), "Deceased supporter prevented a remembered legacy")
	_await_chapter(state, LEGACY)
	_check(_resolve(state, LEGACY, "adapt").get("success", false), "Descendant could not finish the family-history chapter")
	_check(inherited.get("status", "") == "finished" and JSON.stringify(record) == before, "Descendant rewrote the parent's saved choices")

func _test_money_boundaries() -> void:
	for era in ["Ancient Era", "Future Era"]:
		var state := _household_fixture()
		state.era.name = era
		_start_care(state)
		var cost := 60 if era == "Ancient Era" else 450
		_check(str(_pending(state, CARE).response_options).contains(str(cost)), "Care payment hid its era-scaled cost")
		_check(_resolve(state, CARE, "fund").get("success", false) and state.player.bank_balance == 10000 - cost, "Era-scaled care payment is incorrect")
	var poor := _household_fixture()
	poor.player.bank_balance = 0
	var poor_record := _start_care(poor)
	var before := JSON.stringify(poor_record)
	_check(not _resolve(poor, CARE, "fund").get("success", true) and JSON.stringify(poor_record) == before, "Unaffordable help committed a consequence")
	_check(_resolve(poor, CARE, "limited").get("success", false), "No free response remained after an unaffordable payment")
	var owner := _household_fixture()
	var business_record := _found(owner)
	var company := _business(owner, business_record)
	owner.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	_only(owner, CARE)
	owner.year += 2
	owner.scenario_runtime_contract_engine.service_life_stories()
	var reserve := FamilyBusinessEngine.new(owner).balance(company)
	_check(str(_pending(owner, CARE).overview).contains("company has its own reserves"), "Owned business context is missing")
	_check(_resolve(owner, CARE, "fund").get("success", false), "Owner could not arrange personal care")
	_check(FamilyBusinessEngine.new(owner).balance(company) == reserve, "Personal care spent company reserves")
