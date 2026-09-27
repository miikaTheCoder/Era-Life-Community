extends SceneTree

class CrimeFixture extends RefCounted:
	func get_actor_profile(_actor) -> Dictionary:
		return {"successful_jobs": 2, "organization_id": "crew"}
	func get_organizations_for_actor(_actor) -> Array:
		return [{"id": "crew", "members": {"105": {}}}]

var failed := false
var paths_checked := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _fixture(age: int = 20) -> GameState:
	var state := GameState.new()
	state.year = 2000
	state.era = {"name": "Modern Era"}
	for id in range(101, 106):
		var person := Person.new()
		person.id = id
		person.first_name = {101: "Alex", 102: "Robin", 103: "Casey", 104: "Jordan", 105: "Morgan"}[id]
		person.last_name = "Story"
		person.age = {101: age, 102: 60, 103: age, 104: 45, 105: 30}[id]
		person.bank_balance = 10000
		person.job = "Carpenter" if person.age >= 18 else ""
		person.affection = {101: 50, 102: 50, 103: 50, 104: 50, 105: 50}
		state.npcs.append(person)
	state.player = state.npcs[0]
	state.player_id = 101
	state.player.parents = [102]
	state.npcs[1].children = [101]
	state.player.friends = [103]
	state.player.coworkers = [104]
	state._rebuild_npc_index()
	state.resident_runtime_bootstrap_complete = true
	state.relationship_engine = RelationshipEngine.new(state)
	state.memory_engine = MemoryEngine.new(state)
	state.life_diary_contract_engine = LifeDiaryContractEngine.new(state)
	state.bank_engine = BankEngine.new(state)
	state.crime_world_engine = CrimeFixture.new()
	state.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(state)
	state.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(state)
	state.pending_situations_engine = PendingSituationsEngine.new(state)
	return state

func _only(state: GameState, story_id: String) -> LifeStoryEngine:
	var engine: LifeStoryEngine = state.scenario_runtime_contract_engine._ensure_life_story_engine()
	engine.catalog = engine.catalog.filter(func(row): return str(row.id) == story_id)
	if story_id == "family_legacy":
		state.scenario_state.life_stories = {"version": 1, "actors": {"102": {"stories": {
			"family_loan": {"story_id": "family_loan", "cast_id": 103, "legacy": "broken_word"}
		}}}}
	return engine

func _instance(state: GameState, story_id: String) -> Dictionary:
	return state.scenario_state.get("life_stories", {}).get("actors", {}).get("101", {}).get("stories", {}).get(story_id, {})

func _pending(state: GameState, story_id: String) -> Dictionary:
	for contract in state.scenario_runtime_contract_engine.active_popup_contracts.values():
		if str(contract.get("request", "")) == "life_story" and str(contract.source_result.story_id) == story_id:
			return contract
	return {}

func _choose(state: GameState, story_id: String, option: String) -> Dictionary:
	var contract := _pending(state, story_id)
	_check(not contract.is_empty(), "Missing chapter for " + story_id + ":" + option)
	if contract.is_empty():
		return {}
	return state.pending_situations_engine.resolve_pending_contract(str(contract.id), option, {"viewer_actor_id": 101})

func _advance_to_due(state: GameState, story_id: String) -> void:
	var record := _instance(state, story_id)
	var years: int = maxi(1, int(record.due_year) - int(state.year))
	state.year += years
	for person in state.npcs:
		person.age += years
	state.scenario_runtime_contract_engine.service_life_stories()

func _paths(definition: Dictionary, node_id: String, prefix: Array = []) -> Array:
	var result: Array = []
	for choice in definition.nodes[node_id].choices:
		var path := prefix.duplicate()
		path.append(str(choice.id))
		if str(choice.get("next", "")) == "":
			result.append(path)
		else:
			result.append_array(_paths(definition, str(choice.next), path))
	return result

func _run() -> void:
	var catalog := LifeStoryEngine.new()
	_check(catalog.content_errors.is_empty(), "Invalid authored story content: " + str(catalog.content_errors))
	catalog.catalog = catalog.catalog.filter(func(row): return str(row.get("series", "Life Stories")) == "Life Stories")
	_check(catalog.catalog.size() == 6, "Expected all six launch stories")
	var malformed: Dictionary = {"schema": "eralife.life_stories", "version": 1, "stories": catalog.catalog.duplicate(true)}
	malformed.stories[0].nodes.gate.choices[0].next = "missing"
	_check(not LifeStoryEngine.validate_catalog(malformed).is_empty(), "Dangling chapter was accepted")
	malformed = {"schema": "eralife.life_stories", "version": 1, "stories": catalog.catalog.duplicate(true)}
	malformed.stories[0].nodes.gate.choices[2].transfer = -100
	_check(not LifeStoryEngine.validate_catalog(malformed).is_empty(), "A paid automatic choice was accepted")
	# Exercise every authored route through the real pending and runtime owners,
	# real banking/relationships, and saved year-based follow-up admission.
	for definition in catalog.catalog:
		for path in _paths(definition, str(definition.start)):
			var state := _fixture(10 if str(definition.id) == "childhood_pact" else 20)
			_only(state, str(definition.id))
			state.scenario_runtime_contract_engine.service_life_stories()
			for option_id in path:
				var result := _choose(state, str(definition.id), str(option_id))
				_check(bool(result.get("success", false)), "%s %s failed: %s" % [str(definition.id), str(option_id), str(result)])
				var record := _instance(state, str(definition.id))
				if str(record.get("status", "")) == "waiting":
					_check(_pending(state, str(definition.id)).is_empty(), "Follow-up appeared in the same year")
					_advance_to_due(state, str(definition.id))
			var record := _instance(state, str(definition.id))
			_check(str(record.get("status", "")) == "finished", "An authored route never finished")
			_check(record.get("history", []).size() == path.size(), "Choice history duplicated or lost a chapter")
			_check(not state.life_diary_contract_engine.diary_entries_for_actor(101).is_empty(), "Choice bypassed diary authority")
			paths_checked += 1
	_test_money_and_rejections()
	_test_checkpoint()
	_test_deadlines_and_cast()
	_test_pacing_and_legacy()
	print("LIFE STORIES TESTS: ", "FAIL" if failed else "PASS", "; complete routes=", paths_checked)
	quit(1 if failed else 0)

func _test_money_and_rejections() -> void:
	var state := _fixture()
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	var contract := _pending(state, "family_loan")
	var before := JSON.stringify(_instance(state, "family_loan"))
	var runtime = state.scenario_runtime_contract_engine
	var wrong: Dictionary = runtime.resolve_popup_contract(contract.id, "accept", {"viewer_actor_id": 102})
	var invalid: Dictionary = runtime.resolve_popup_contract(contract.id, "invented_choice", {"viewer_actor_id": 101})
	_check(not wrong.success and not invalid.success, "Wrong actor or invented choice was accepted")
	_check(before == JSON.stringify(_instance(state, "family_loan")), "Rejected choice changed story state")
	var result: Dictionary = state.pending_situations_engine.resolve_pending_contract("pending_item:" + str(contract.id), "accept", {"viewer_actor_id": 101})
	_check(result.get("success", false), "Pending-view identity did not resolve the story")
	_check(state.player.bank_balance == 10600 and state.npcs[1].bank_balance == 9400, "Loan did not transfer real money between its cast")
	var replay: Dictionary = runtime.resolve_popup_contract(contract.id, "accept", {"viewer_actor_id": 101})
	_check(not replay.success and state.player.bank_balance == 10600, "Repeated click paid the loan twice")
	_advance_to_due(state, "family_loan")
	var spend: Dictionary = state.bank_engine.request_actor_bank_action(state.player, {"action": "spend", "amount": 10600})
	_check(spend.get("success", false), "Fixture could not spend its authoritative money")
	var affection_before: int = state.player.affection[102]
	result = _choose(state, "family_loan", "repay")
	_check(not result.get("success", false), "Unaffordable repayment succeeded")
	_check(str(_instance(state, "family_loan").status) == "pending" and state.player.bank_balance == 0, "Failed payment advanced story or recreated money")
	_check(state.player.affection[102] == affection_before, "Failed payment changed relationship")
	result = _choose(state, "family_loan", "extension")
	_check(result.get("success", false), "A free alternative failed after an unaffordable choice")
	# Era pricing is fixed when the story starts, even after a later era change.
	state = _fixture()
	state.era.name = "Medieval Era"
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	_choose(state, "family_loan", "accept")
	_check(state.player.bank_balance == 10180, "Medieval loan did not use era pricing")
	state.era.name = "Future Era"
	_advance_to_due(state, "family_loan")
	_choose(state, "family_loan", "repay")
	_check(state.player.bank_balance == 10000, "Era shift changed an existing repayment amount")

func _test_checkpoint() -> void:
	var state := _fixture(10)
	_only(state, "childhood_pact")
	state.scenario_runtime_contract_engine.service_life_stories()
	_choose(state, "childhood_pact", "stand_beside")
	var serializer := GameStateSerializationRuntime.new(state)
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(serializer._build_interactive_checkpoint_payload()))
	var expected: Dictionary = JSON.parse_string(JSON.stringify(state.scenario_state.life_stories))
	_check(payload.scenario_state.get("life_stories", {}) == expected, "Checkpoint dropped waiting story state")
	_check(payload.npcs.any(func(row): return int(row.id) == 103), "Checkpoint lost a recurring friend outside the family graph")
	var restored := GameState.new()
	var residency := RealityResidencyManager.new(restored)
	var player_snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	var report: Dictionary = residency._materialize_checkpoint_resume_shell(restored, {
		"actor_id": 101, "actor_snapshot": player_snapshot, "year": int(payload.year)
	}, "life-story-checkpoint", {})
	_check(report.get("success", false), "Story checkpoint could not restore the player")
	restored.era = {"name": payload.era_name}
	var hydration := GameStateHydrationRuntime.new(restored)
	var begin: Dictionary = hydration.begin_resident_checkpoint_spatial_hydration(payload,
		{"household": payload.npcs, "city": [], "realm": [], "world": []},
		{"resident_restore": true, "runtime_scene_tree_access_allowed": false, "strict_one_item_per_slice": true})
	_check(begin.get("success", false), "Story checkpoint hydration did not begin")
	var steps := 0
	while hydration.is_background_hydration_active() and steps < 20000:
		hydration.run_background_hydration_slice(50)
		steps += 1
	_check(steps < 20000, "Story checkpoint hydration did not finish")
	_check(restored.scenario_state.get("life_stories", {}) == expected, "Hydration failed to restore story authority")
	if not restored.scenario_state.has("life_stories"):
		return
	restored._rebuild_npc_index()
	restored.resident_runtime_bootstrap_complete = true
	restored.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(restored)
	restored.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(restored)
	restored.pending_situations_engine = PendingSituationsEngine.new(restored)
	restored.memory_engine = MemoryEngine.new(restored)
	restored.life_diary_contract_engine = LifeDiaryContractEngine.new(restored)
	_only(restored, "childhood_pact")
	restored.scenario_runtime_contract_engine.service_life_stories()
	_check(_pending(restored, "childhood_pact").is_empty(), "Restore surfaced the next chapter too early")
	_advance_to_due(restored, "childhood_pact")
	var pending := _pending(restored, "childhood_pact")
	_check(not pending.is_empty() and str(pending.get("overview", "")).contains("Casey Story"), "Restored chapter lost its original cast")
	_check(str(pending.get("overview", "")).contains("stood beside"), "Later chapter did not explain its earlier choice")
	_check(_choose(restored, "childhood_pact", "commit").get("success", false), "Restored follow-up was not playable")
	# Save with an open chapter, omit its disposable runtime projection, and
	# rebuild the same canonical chapter at the same year without restarting it.
	state = _fixture()
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	var old_id: String = _pending(state, "family_loan").id
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.scenario_state.life_stories))
	state.scenario_state = {"life_stories": saved}
	state.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(state)
	state.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(state)
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(_pending(state, "family_loan").get("id", "") == old_id, "Open chapter changed identity after restore")

func _test_deadlines_and_cast() -> void:
	var state := _fixture()
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(str(_pending(state, "family_loan").get("overview", "")).contains("respond through year 2002"), "Story must show its stable calendar deadline")
	state.year += 3
	state.player.age += 3
	state.scenario_runtime_contract_engine.service_life_stories()
	var record := _instance(state, "family_loan")
	_check(record.history.size() == 1 and record.history[0].choice == "decline" and record.history[0].automatic, "Ignored chapter did not take its authored free outcome")
	_check(state.player.bank_balance == 10000, "Ignoring a loan accepted money automatically")
	for i in range(4):
		state.scenario_runtime_contract_engine.service_life_stories()
	_check(record.history.size() == 1, "Deadline replayed more than once")
	state = _fixture()
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	var cast = state.npcs[1]
	state.npc_index.erase(102)
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(_instance(state, "family_loan").status == "pending", "Temporarily absent cast was replaced or killed")
	state.npc_index[102] = cast
	cast.alive = false
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(_instance(state, "family_loan").status == "finished" and _pending(state, "family_loan").is_empty(), "A deceased cast member kept issuing choices")
	_check(str(state.player.memories).contains("died before our story"), "An interrupted story vanished without closure")
	state = _fixture(10)
	state.player.friends = []
	_only(state, "childhood_pact")
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(_instance(state, "childhood_pact").is_empty(), "Story invented a friend instead of using a real relationship")

func _test_pacing_and_legacy() -> void:
	var state := _fixture()
	var runtime = state.scenario_runtime_contract_engine
	runtime.service_life_stories()
	_check(state.scenario_state.life_stories.actors["101"].stories.size() == 1, "More than one story started in a year")
	state.year += 1
	runtime.service_life_stories()
	_check(state.scenario_state.life_stories.actors["101"].stories.size() == 1, "Story admission ignored its cooldown")
	state.year += 1
	runtime.service_life_stories()
	_check(state.scenario_state.life_stories.actors["101"].stories.size() == 2, "Second eligible story never started")
	# Full real parental history, followed by a change of controlled generation.
	state = _fixture()
	_only(state, "family_loan")
	state.scenario_runtime_contract_engine.service_life_stories()
	_choose(state, "family_loan", "accept")
	_advance_to_due(state, "family_loan")
	_choose(state, "family_loan", "refuse")
	var child := Person.new()
	child.id = 106
	child.first_name = "Avery"
	child.last_name = "Story"
	child.age = 18
	child.parents = [101]
	state.npcs.append(child)
	state.player.children = [106]
	state.player = child
	state.player_id = 106
	state._rebuild_npc_index()
	runtime = state.scenario_runtime_contract_engine
	runtime.life_story_engine = LifeStoryEngine.new(state)
	runtime.life_story_engine.catalog = runtime.life_story_engine.catalog.filter(func(row): return str(row.id) == "family_legacy")
	runtime.service_life_stories()
	var story: Dictionary = state.scenario_state.life_stories.actors["106"].stories.get("family_legacy", {})
	_check(story.get("cast_id", -1) == 102 and story.get("origin_legacy", "") == "broken_word", "Descendant did not inherit the real parent's story and cast")
	var contract_id: String = runtime.life_story_engine._contract_id(story) if not story.is_empty() else "missing"
	var report: Dictionary = runtime.resolve_popup_contract(contract_id, "listen", {"viewer_actor_id": 106})
	_check(report.get("success", false), "Inherited family chapter was not playable")
