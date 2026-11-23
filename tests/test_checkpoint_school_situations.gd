extends SceneTree

var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _school_and_situations_fixture() -> GameState:
	var state := GameState.create_resident_chassis_shell()
	state.era = {"name": "Modern Era"}
	state.year = 2035
	var student := Person.new()
	student.id = 7
	student.first_name = "Noel"
	student.age = 4
	student.parents = [8]
	state.player = student
	state.player_id = student.id
	var parent := Person.new()
	parent.id = 8
	parent.age = 27
	state.npcs = [student, parent]
	state._rebuild_npc_index()
	state.school_engine = SchoolEngine.new(state)
	state.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(state)
	state.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(state)
	state.contract_view_layer_contract_engine = ContractViewLayerContractEngine.new(state)
	state.pending_situations_engine = PendingSituationsEngine.new(state)
	return state


func _resume(state: GameState, payload: Dictionary) -> void:
	state.resident_runtime_bootstrap_complete = true
	var runtime := GameStateHydrationRuntime.new(state)
	var report := runtime.begin_resident_checkpoint_spatial_hydration(payload, {"household": payload.npcs})
	_check(report.get("success", false), "Resident hydration rejected the checkpoint")


func _initialize() -> void:
	var source := _school_and_situations_fixture()
	var school: SchoolEngine = source.school_engine
	var roster_key := "Modern Era|college_major|University"
	var enrollment := {"mode": "college_major", "school_name": "University", "status": "active",
		"major": "Chemistry", "years_attended": 2}
	school.enrollment = {8: enrollment, 99: enrollment.duplicate(true)}
	school.school_academic_records = {"8": {"credits": 13}, "99": {"credits": 12}}
	school.school_rosters = {roster_key: [8, 99]}
	school.school_teachers = {roster_key: [7, 99]}
	var seed_key := "age_window:7:toddler_finance_argument"
	var pending = source.pending_situations_engine
	pending.birth_starter_seeded_actor_ids = {seed_key: true, "age_window:99:toddler_finance_argument": true}
	var id := "age_window_finance_argument_7_2033"
	var now := int(Time.get_ticks_msec())
	source.scenario_runtime_contract_engine.active_popup_contracts[id] = {
		"id": id, "target_id": 7, "created_at_ms": now - 5000, "escalation_stage": 0,
		"next_escalation_ms": now + 10000}
	pending.npc_decision_ledger[id] = {"8": now - 4000, "8:stage": "0"}
	source.contract_view_layer_contract_engine.decision_contracts["parent_choice"] = {
		"source_contract_id": id, "actor_id": 8, "perspective": "guardian", "option_id": "listen",
		"updated_at_ms": now - 4000}
	var serializer := GameStateSerializationRuntime.new(source)
	var payload := BinarySaveEngine.decode(BinarySaveEngine.encode(serializer._build_interactive_checkpoint_payload()))
	_check(payload.age_window_state.receipts.size() == 1, "Checkpoint included unrelated actors' seed receipts")
	var restored := _school_and_situations_fixture()
	restored.scenario_state["checkpoint_age_windows_pending"] = true
	_check(restored.pending_situations_engine.seed_age_window_contracts_for_actor(restored.player).get("skipped", false)
		and restored.scenario_runtime_contract_engine.active_popup_contracts.is_empty(),
		"The first frame admitted a new argument before the saved receipts arrived")
	_resume(restored, payload)
	school = restored.school_engine
	_check(school.enrollment.size() == 1 and school.enrollment.get(8) == payload.school_enrollment["8"] and int(school.enrollment[8].years_attended) == 2,
		"Checkpoint lost the complete enrollment or selected outsiders")
	_check(school.school_academic_records.size() == 1 and int(school.school_academic_records.get("8", {}).get("credits", -1)) == 13, "Checkpoint lost the student's transcript")
	_check(school.school_rosters.get(roster_key) == [8] and school.school_teachers.get(roster_key) == [7],
		"Student or teacher membership changed in the checkpoint")
	var resumed = restored.pending_situations_engine
	var contract: Dictionary = restored.scenario_runtime_contract_engine.active_popup_contracts.get(id, {})
	_check(contract.get("target_id") == 7, "The existing pending argument disappeared on Continue")
	var view = restored.contract_view_layer_contract_engine
	_check(view._latest_parent_decision_for_source(id, 7).get("option_id") == "listen",
		"The parent's earlier choice disappeared from the pending argument")
	_check(not resumed._npc_decision_is_due(id, 8, contract, int(Time.get_ticks_msec()) + 60000),
		"Continue permitted a parent to act twice at the same stage")
	_check(resumed.seed_age_window_contracts_for_actor(restored.player).get("already_seeded", false),
		"Continue reissued a previously admitted age-window contract")
	var untouched := _school_and_situations_fixture()
	source.scenario_runtime_contract_engine.active_popup_contracts.clear()
	pending.birth_starter_seeded_actor_ids.clear()
	payload.age_window_state = pending.checkpoint_age_windows([7, 8])
	_resume(untouched, payload)
	var issued: Dictionary = untouched.pending_situations_engine.seed_age_window_contracts_for_actor(untouched.player)
	_check(issued.get("success", false) and not issued.get("already_seeded", false)
		and not untouched.scenario_runtime_contract_engine.active_popup_contracts.is_empty(),
		"A newly eligible window was suppressed after Continue")

	payload.erase("age_window_state")
	payload.erase("school_enrollment")
	for row in payload.npcs:
		if int(row.id) == 8:
			row.merge({"school_mode": "era_school", "school_status": "active", "school_name": "College: Psychology",
				"education_level": "young_adult"}, true)
	var legacy := _school_and_situations_fixture()
	_resume(legacy, payload)
	_check(legacy.pending_situations_engine.birth_starter_seeded_actor_ids == {seed_key: true},
		"Legacy Continue replayed the controlled actor's window or suppressed another actor's")
	_check(legacy.school_engine.enrollment.get(8, {}).get("program") == "young_adult"
		and legacy.school_engine.school_rosters.get("Modern Era|era_school|College: Psychology") == [8],
		"Legacy Continue lost the persisted student's program or roster")
	print("CHECKPOINT SCHOOL AND SITUATION TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
