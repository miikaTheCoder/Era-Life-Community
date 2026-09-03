extends SceneTree

var failed := false

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := GameState.new()
	state.player = Person.new()
	state.player.id = 71
	state.player_id = 71
	state.npcs = [state.player]
	state.life_diary_contract_engine = LifeDiaryContractEngine.new(state)
	var runtime := AgeUpRuntimeEngine.new(state)
	for age in [1, 2]:
		state.year = 2000 + age
		state.player.age = age
		runtime.active_year_context = {"zero_frame_tail": true}
		# The result-commit lane receives no diary-worthy events in quiet years.
		runtime.runtime_phase_walkers["player_phase_contract"] = {"micro_lane_cursor": 11, "events": [], "opps": []}
		runtime._step_player_phase_contract_walker()
		var result: Dictionary = runtime._finalize_runtime_slice_session()
		_check(result.get("is_complete", false), "Quiet year did not finish")
	var entries: Array = state.life_diary_contract_engine.diary_entries_for_actor(71)
	_check(str(entries).contains("Age: 1") and str(entries).contains("Age: 2"), "Quiet years disappeared from the authoritative diary")
	var before: String = JSON.stringify(entries)
	runtime._finalize_runtime_slice_session()
	_check(JSON.stringify(state.life_diary_contract_engine.diary_entries_for_actor(71)) == before, "Finalizing a year twice duplicated its diary entry")
	# Finishing the last phase can consume the frame budget. The next frame
	# must still finalize the year, even though there are no phases left.
	state.scenario_state["loading_runtime"] = {"session_stage": "running", "completion_state": "running"}
	runtime.runtime_slice_active = true
	runtime.runtime_slice_order = ["narrative_and_presentation"]
	runtime.runtime_slice_phase_cursor = 0
	runtime.runtime_contract_scheduler = {"phase_order": runtime.runtime_slice_order}
	runtime.active_year_context = {"zero_frame_tail": true, "year": state.year}
	var step: Dictionary = runtime.run_year_runtime_slice(1, 1)
	_check(runtime.runtime_slice_phase_cursor == 1, "Final presentation phase did not finish")
	_check(not step.get("is_complete", false), "Fixture did not yield after the last phase")
	for frame in range(8):
		step = runtime.run_year_runtime_slice(1, 1)
		if step.get("is_complete", false):
			break
	_check(step.get("is_complete", false) and not runtime.runtime_slice_active, "Year never finalized after yielding on its last phase")
	print("YEAR DIARY TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
