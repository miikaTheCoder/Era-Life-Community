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
	var parent := Person.new()
	parent.id = 41
	var child := Person.new()
	child.id = 42
	var roommate := Person.new()
	roommate.id = 43
	state.player = child
	state.player_id = child.id
	state.npcs = [parent, child, roommate]
	state._rebuild_npc_index()
	var members := [
		{"local_key": "person_0", "relationship_to_anchor": "none"},
		{"local_key": "person_1", "relationship_anchor_key": "person_0", "relationship_to_anchor": "daughter"},
		{"local_key": "person_2", "relationship_anchor_key": "person_0", "relationship_to_anchor": "roommate"},
	]
	var people := {"person_0": parent, "person_1": child, "person_2": roommate}
	var contract := {"start_person_key": "person_1", "members": members}
	state._wire_custom_household_relationships(child, people, contract)
	child.affection[41] = 76
	parent.affection[42] = 79
	_check(child.parents == [41] and parent.children == [42], "Selected child lost reciprocal parent links")
	_check(parent.friends.has(43) and roommate.friends.has(41), "Roommate link lost")
	_check(not child.parents.has(42) and not parent.children.has(41), "Household created a self relationship")
	state.scenario_state = {
		"custom_household_member_index": {"person_0": 41, "person_1": 42, "person_2": 43},
		"custom_household_spawn_contract": contract,
		"custom_household_start_person_key": "person_1",
		"choose_adventure": {"current_story_id": "runaway_heir", "pressure_history": [{"wealth": 3}]},
		"life_diary_state_by_npc": {"42": {"entries": ["I attended school."]}, "999": {"entries": ["Unrelated NPC history."]}},
	}
	state.world_feed = [{"text": "A remembered world event.", "year": 2001}]
	var serializer := GameStateSerializationRuntime.new(state)
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(serializer._build_interactive_checkpoint_payload()))
	var ids: Array = payload.npcs.map(func(row): return int(row.id))
	var restored_parent: Person = state._deserialize_npc(payload.npcs.filter(func(row): return int(row.id) == 41)[0])
	var restored_child: Person = state._deserialize_npc(payload.npcs.filter(func(row): return int(row.id) == 42)[0])
	_check(restored_parent.children.has(42) and restored_child.parents.has(41), "Decoded family IDs cannot be found by normal gameplay lookups")
	_check(restored_child.affection.get(41) == 76 and restored_parent.affection.get(42) == 79, "Decoded relationship scores cannot be found by actor ID")
	# Continue shows this actor before background spatial hydration. That path
	# skips _deserialize_npc, and the actor is not imported again in the tail.
	var resumed_state := GameState.new()
	var residency := RealityResidencyManager.new(resumed_state)
	var resume_report: Dictionary = residency._materialize_checkpoint_resume_shell(resumed_state, {"actor_id": 42, "actor_snapshot": payload.npcs.filter(func(row): return int(row.id) == 42)[0], "year": 2001}, "checkpoint-test", {})
	_check(resume_report.get("success", false), "Checkpoint resume shell could not materialize")
	_check(resumed_state.player.parents.has(41), "Immediately resumed actor has non-integer parent IDs")
	_check(resumed_state.player.affection.get(41) == 76, "Immediately resumed actor lost its relationship score")
	var resumed_player_ref: Person = resumed_state.player
	var resumed_player_instance_id: int = resumed_player_ref.get_instance_id()
	var tail_hydration := GameStateHydrationRuntime.new(resumed_state)
	resumed_state.game_state_hydration_runtime = tail_hydration
	var tail_begin: Dictionary = tail_hydration.begin_resident_checkpoint_spatial_hydration(
		payload,
		{
			"household": payload.npcs,
			"city": [],
			"realm": [],
			"world": [],
		},
		{
			"source": "test_mode_checkpoint.controlled_actor_tail",
			"resident_restore": true,
			"runtime_scene_tree_access_allowed": false,
			"strict_one_item_per_slice": true,
		}
	)
	_check(tail_begin.get("success", false), "Checkpoint hydration tail could not begin")
	_check(not tail_begin.get("worker_thread_used", true), "Checkpoint hydration tail still advertises live worker mutation")
	var initial_fingerprint: int = int(tail_begin.get("controlled_actor_fingerprint", 0))
	var initial_guard_snapshot: Dictionary = tail_hydration._capture_controlled_actor_hydration_snapshot()
	_check(initial_guard_snapshot.get("state", {}).has("affection"), "Controlled actor fingerprint omitted relationship state")
	var legitimate_change_applied := false
	var legitimate_relationship_score: int = (
		int(resumed_state.player.affection.get(43, 50)) + 7
	) % 101
	var relationship_projection := RelationshipsHubContractEngine.new(resumed_state)
	var tail_steps := 0
	while tail_hydration.is_background_hydration_active() and tail_steps < 20000:
		if tail_steps == 1:
			# A gameplay/UI action between cooperative quanta becomes the next
			# baseline. Hydration must preserve it rather than restoring save-start.
			resumed_state.player.affection[43] = legitimate_relationship_score
			legitimate_change_applied = true
			_check(int(tail_hydration._capture_controlled_actor_hydration_snapshot().get("fingerprint", 0)) != initial_fingerprint, "Controlled actor fingerprint ignored a relationship change")

		var live_parent: Person = resumed_state.get_npc_by_id(41, false)
		if live_parent != null:
			var projected_bond: int = relationship_projection._projection_bond_score_for_pair(
				resumed_state.player,
				live_parent,
				{"projection_bond_cache": {}}
			)
			_check(projected_bond == 76, "Relationship projection observed checkpoint actor drift")

		var tail_slice: Dictionary = tail_hydration.run_background_hydration_slice(50)
		_check(tail_slice.get("success", false), "Checkpoint hydration tail slice failed")
		_check(not tail_slice.get("worker_thread_used", true), "Checkpoint hydration mutated live state on a worker")
		_check(resumed_state.player == resumed_player_ref, "Checkpoint hydration replaced the controlled actor reference")
		_check(resumed_state.player.get_instance_id() == resumed_player_instance_id, "Checkpoint hydration changed the controlled actor instance")
		_check(resumed_state.get_npc_by_id(42, false) == resumed_player_ref, "Checkpoint hydration replaced the controlled actor index entry")
		_check(resumed_state.player.affection.get(41) == 76, "Checkpoint hydration changed the saved relationship score")
		if legitimate_change_applied:
			_check(resumed_state.player.affection.get(43) == legitimate_relationship_score, "Checkpoint hydration erased a legitimate between-quantum relationship change")
		tail_steps += 1

	_check(tail_steps < 20000, "Checkpoint hydration tail did not complete")
	_check(legitimate_change_applied, "Checkpoint hydration completed before the interleaved change could be tested")
	_check(int(tail_hydration.last_hydration_report.get("controlled_actor_last_fingerprint", 0)) != initial_fingerprint, "Controlled actor fingerprint did not advance with a legitimate main-thread change")
	_check(tail_hydration.last_hydration_report.get("controlled_actor_invariant_preserved", false), "Controlled actor invariant was not preserved through tail hydration")
	_check(resumed_state.player.affection.get(41) == 76, "Completed checkpoint tail changed the saved relationship score")
	_check(resumed_state.player.affection.get(43) == legitimate_relationship_score, "Completed checkpoint tail erased the legitimate relationship change")
	_check(ids.has(43), "Checkpoint dropped a household member outside the family graph")
	_check(payload.scenario_state.custom_household_start_person_key == "person_1", "Checkpoint lost selected household member")
	_check(payload.scenario_state.choose_adventure.pressure_history.size() == 1, "Checkpoint lost narrative choices")
	_check(payload.scenario_state.life_diary_state_by_npc["42"].entries == ["I attended school."], "Checkpoint lost player diary")
	_check(not payload.scenario_state.life_diary_state_by_npc.has("999"), "Checkpoint copied unrelated actor history")
	_check(payload.world_feed.size() == 1 and payload.world_feed[0].text == "A remembered world event.", "Checkpoint lost world history")
	# Current age-up events live in the diary authority before a legacy UI
	# bucket is refreshed. They must be saved even when that bucket is absent.
	state.life_diary_contract_engine = LifeDiaryContractEngine.new(state)
	state.life_diary_contract_engine.enqueue_intent({"type": "legacy_entry", "actor_id": 42, "year": 2001, "age": 9, "lines": ["I started a new school year."], "preserve_lines_exactly": true})
	state.scenario_state.erase("life_diary_state_by_npc")
	payload = BinarySaveEngine.decode(BinarySaveEngine.encode(serializer._build_interactive_checkpoint_payload()))
	var authority_rows: Array = payload.scenario_state.life_diary_state_by_npc["42"].entries
	_check(not authority_rows.is_empty() and str(authority_rows).contains("I started a new school year."), "Checkpoint omitted the current diary authority")
	var restored_diary := LifeDiaryContractEngine.new(state)
	state.life_diary_contract_engine = restored_diary
	var hydration := GameStateHydrationRuntime.new(state)
	var phase: Dictionary = {"hydrated": [], "failed": [], "warnings": [], "deferred": []}
	hydration._hydrate_contract_slices_for_phase("system_state", payload, phase, {})
	_check(restored_diary.diary_entries_for_actor(42) == authority_rows, "Diary authority could not restore its saved stream")
	state.year = 2001
	child.age = 9
	var stale_snapshot := {"year": 2000, "age": 8, "life_diary_lines": ["A stale first frame."]}
	var current_snapshot := serializer._checkpoint_presentation_snapshot(stale_snapshot)
	_check(current_snapshot.year == 2001 and current_snapshot.age == 9 and str(current_snapshot.life_diary_lines).contains("I started a new school year."), "Checkpoint presentation retained the original birth frame")
	_check(stale_snapshot.age == 8, "Saving mutated the live presentation snapshot")
	print("MODE CHECKPOINT TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
