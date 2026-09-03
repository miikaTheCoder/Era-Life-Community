extends SceneTree

class CountingAgeUpRuntime extends AgeUpRuntimeEngine:
	var direct_packet_collection_calls: int = 0

	func _collect_direct_delta_packets() -> Array:
		direct_packet_collection_calls += 1
		return super._collect_direct_delta_packets()

class RelationshipProjectionSpy:
	extends RefCounted

	var update_calls: int = 0

	func update_relationship(_player, _target) -> int:
		update_calls += 1
		return 50

class RelationshipTargetTrap:
	extends RefCounted

	var collection_calls: int = 0

	func _collect_player_relationship_targets() -> Array:
		collection_calls += 1
		return [Person.new()]

class TypedWorldFeedSpy:
	extends RefCounted

	var build_calls: int = 0

	func build_runtime_mailbox_entries_from_typed_packets(_packets: Array) -> Array:
		build_calls += 1
		return [
			{
				"type": "world_feed_entry",
				"entry": {
					"text": "typed-feed-a",
					"event_name": "typed_test_a"
				}
			},
			{
				"type": "world_feed_entry",
				"entry": {
					"text": "typed-feed-b",
					"event_name": "typed_test_b"
				}
			}
		]

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
	var relationship_spy := RelationshipProjectionSpy.new()
	var relationship_target_trap := RelationshipTargetTrap.new()
	state.relationship_engine = relationship_spy
	state.life_engine = relationship_target_trap
	runtime.runtime_phase_walkers["player_phase_contract"] = {
		"micro_lane_cursor": 7,
		"events": [],
		"opps": []
	}
	var relationship_step: Dictionary = runtime._step_player_phase_contract_walker()
	var relationship_walker: Dictionary = runtime.runtime_phase_walkers.get("player_phase_contract", {})
	_check(
		int(relationship_walker.get("micro_lane_cursor", -1)) == 9,
		"Player phase did not bypass the discarded relationship projection"
	)
	_check(
		relationship_target_trap.collection_calls == 0 and relationship_spy.update_calls == 0,
		"Player phase still scanned relationship targets for a discarded score"
	)
	_check(
		str(relationship_step.get("current_micro_lane", "")) == "relationship_projection_skipped",
		"Player phase did not report its bounded relationship transition"
	)
	# Checkpoint compatibility: a save made while the old lane was active must
	# advance without replaying the no-op target loop.
	runtime.runtime_phase_walkers["player_phase_contract"] = {
		"micro_lane_cursor": 8,
		"relationship_targets": [Person.new()],
		"relationship_cursor": 0,
		"events": [],
		"opps": []
	}
	runtime._step_player_phase_contract_walker()
	relationship_walker = runtime.runtime_phase_walkers.get("player_phase_contract", {})
	_check(
		int(relationship_walker.get("micro_lane_cursor", -1)) == 9 and relationship_spy.update_calls == 0,
		"An older checkpoint replayed the discarded relationship projection"
	)

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

	# Presentation must finish against the source snapshot taken on its first
	# slice even when background producers continue appending authoritative rows.
	var bounded_state := GameState.new()
	bounded_state.player = Person.new()
	bounded_state.player.id = 72
	bounded_state.player_id = 72
	bounded_state.npcs = [bounded_state.player]
	bounded_state.year = 2010
	bounded_state.world_feed = [
		{"text": "captured-feed-a", "event_name": "captured_test_a"},
		{"text": "captured-feed-b", "event_name": "captured_test_b"}
	]
	bounded_state.pending_death_messages = ["captured-death"]
	bounded_state.pending_inheritance_messages = ["captured-inheritance"]
	bounded_state.pending_year_resolution_popups = [
		{"popup_title": "Captured", "popup_text": "captured-popup"}
	]
	var typed_world_feed_spy := TypedWorldFeedSpy.new()
	bounded_state.world_feed_engine = typed_world_feed_spy
	var bounded_runtime := CountingAgeUpRuntime.new(bounded_state)
	bounded_runtime.active_year_context = {
		"year": bounded_state.year,
		"quality_tier": AgeUpRuntimeEngine.QUALITY_BALANCED,
		"narrative_phase_budget": 1,
		"world_feed_cursor": 0,
		"death_cursor": 0,
		"inheritance_cursor": 0,
		"popup_cursor": 0
	}
	var presentation_complete: bool = false
	for frame in range(24):
		bounded_runtime._run_narrative_and_presentation()
		bounded_state.world_feed.append({
			"text": "late-feed-%d" % frame,
			"event_name": "late_test_%d" % frame
		})
		bounded_state.pending_death_messages.append("late-death-%d" % frame)
		bounded_state.pending_inheritance_messages.append("late-inheritance-%d" % frame)
		bounded_state.pending_year_resolution_popups.append({
			"popup_title": "Late",
			"popup_text": "late-popup-%d" % frame
		})
		presentation_complete = bounded_runtime._narrative_and_presentation_complete()
		if presentation_complete:
			break
	_check(presentation_complete, "Live-growing presentation sources prevented bounded completion")
	_check(
		bounded_runtime.direct_packet_collection_calls == 1,
		"Narrative slices repeatedly normalized the full direct-delta mailbox"
	)
	_check(
		typed_world_feed_spy.build_calls == 1,
		"Narrative slices repeatedly rebuilt typed world-feed rows"
	)
	var bounded_progress: Dictionary = bounded_runtime.active_year_context.get("narrative_progress", {})
	_check(
		int(bounded_progress.get("world_feed_high_water", -1)) == 2
		and int(bounded_runtime.active_year_context.get("world_feed_cursor", -1)) == 2,
		"Narrative source high-water mark changed after background appends"
	)
	_check(
		bounded_state.world_feed.size() > 2
		and bounded_state.pending_death_messages.size() > 1
		and bounded_state.pending_inheritance_messages.size() > 1
		and bounded_state.pending_year_resolution_popups.size() > 1,
		"Bounded draining removed rows from authoritative source arrays"
	)
	var bounded_mailboxes_text: String = JSON.stringify(bounded_runtime.active_mailboxes)
	_check(
		bounded_mailboxes_text.contains("captured-feed-a")
		and bounded_mailboxes_text.contains("captured-feed-b")
		and bounded_mailboxes_text.contains("captured-death")
		and bounded_mailboxes_text.contains("captured-inheritance")
		and bounded_mailboxes_text.contains("captured-popup"),
		"Narrative snapshot lost rows that existed at its high-water mark"
	)
	print("YEAR DIARY TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
