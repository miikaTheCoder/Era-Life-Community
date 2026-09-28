extends SceneTree

var failed := false

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var kernel := GameStateContractEngine.new()
	# Resident worlds ingest small feature packs before the full kernel. A
	# pack that adds no yearly phases must not replace the age-up fallback.
	var storage_pack := {"state_id": "test_storage", "save_slices": [{"id": "test_state", "save_key": "test_state", "engine_id": "school_engine"}]}
	var loaded: Dictionary = kernel.load_contract_from_dictionary(storage_pack)
	_check(loaded.get("success", false), "Storage-only contract did not load")
	_check(kernel.runtime_phase_registry.is_empty(), "A storage-only pack injected unimplemented yearly phases")
	var schedule: Dictionary = kernel.get_runtime_phase_scheduler_context({"runtime_kind": "age_up"})
	for phase in ["core_state_resolution", "player_phase_contract", "choice_and_opportunity_surfacing", "narrative_and_presentation"]:
		_check(schedule.phase_order.has(phase), "Resident scheduler lost required gameplay phase: " + phase)
	var finalization: Array = schedule.phase_contracts.get("narrative_and_presentation", {}).get("runtime_tasks", [])
	_check(finalization.any(func(task): return task.get("task_id") == "finalize_life_year_contract"), "Fallback schedule omitted yearly stat finalization")

	# Explicit schedules and extension tasks remain authored data. A later
	# storage-only pack must leave their order, budgets and tasks untouched.
	var phases: Array = kernel._build_default_age_up_runtime_phases()
	phases.append({"id": "test_extension", "order": 65, "budget_ms": 3, "metadata": {"runtime_kind": "age_up"}})
	loaded = kernel.load_contract_from_dictionary({"state_id": "test_schedule", "runtime_phases": phases})
	_check(loaded.get("success", false), "Explicit yearly schedule did not load")
	var before: Dictionary = kernel.get_runtime_phase_scheduler_context({"runtime_kind": "age_up"})
	storage_pack.state_id = "test_more_storage"
	kernel.load_contract_from_dictionary(storage_pack)
	var after: Dictionary = kernel.get_runtime_phase_scheduler_context({"runtime_kind": "age_up"})
	_check(after.phase_order == before.phase_order, "Storage pack changed the explicit phase order")
	_check(after.phase_contracts == before.phase_contracts, "Storage pack changed explicit phase tasks or budgets")
	_check(after.phase_order.has("test_extension"), "Custom runtime phase was discarded")

	# A new transaction must not resume the previous year's partially drained
	# age walker and commit its stale target age.
	var state := GameState.create_resident_chassis_shell()
	state.player = Person.new()
	state.player.id = 71
	state.player_id = 71
	state.player.age = 30
	state.year = 2000
	state.scenario_state["age_up_time_contract"] = {
		"source_year": 2000, "target_year": 2001,
		"source_age": 30, "target_age": 31,
	}
	var runtime := AgeUpRuntimeEngine.new(state)
	runtime.runtime_phase_walkers["year_and_era_mutation"] = {
		"micro_lane_cursor": 2,
		"contract_target_year": 2000,
		"contract_target_age": 30,
	}
	runtime._step_year_and_era_mutation_walker()
	var walker: Dictionary = runtime.runtime_phase_walkers.get("year_and_era_mutation", {})
	_check(
		int(walker.get("micro_lane_cursor", -1)) == 1
		and int(walker.get("contract_target_year", -1)) == 2001
		and int(walker.get("contract_target_age", -1)) == 31,
		"A new year resumed the stale age transaction"
	)
	# Crime eligibility must be enforced at the action owner as well as the UI.
	state.player.age = 7
	var crime := CrimeEngine.new(state)
	var blocked: Dictionary = crime.commit_crime("Rob a Store", "Unarmed")
	_check(
		blocked.get("result") == "fail"
		and str(blocked.get("popup_text", "")).contains("Requires age 8"),
		"A direct crime action bypassed the childhood age restriction"
	)
	print("YEAR SCHEDULER TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
