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
	print("YEAR SCHEDULER TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
