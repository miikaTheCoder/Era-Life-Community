extends SceneTree

class PublishInvalidator:
	extends RefCounted

	var state: GameState
	var engine: CrimeContractEngine
	var fired := false

	func invalidate(payload: Dictionary) -> void:
		if fired or not bool(payload.get("complete", false)):
			return
		fired = true
		state.year += 1
		engine._on_crime_target_realtime_tick({
			"event_name": str(ActionEventTypes.YEAR_PASSED)
		})

var failed := false


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _person(person_id: int) -> Person:
	var person := Person.new()
	person.id = person_id
	person.first_name = "Resident"
	person.last_name = str(person_id)
	person.age = 30
	person.alive = true
	person.home_city = "New Arcadia"
	person.home_country = "Testland"
	return person


func _run() -> void:
	var state := GameState.new()
	state.scenario_state = {}
	state.year = 2000
	state.player = _person(1)
	state.player_id = state.player.id
	state.npcs = [state.player]
	for index in range(750):
		state.npcs.append(_person(index + 2))
	state._rebuild_npc_index()
	state.relationship_engine = RelationshipEngine.new(state)
	state.event_bus = EventBus.new(state)

	var engine := CrimeContractEngine.new(state)
	engine.queue_crime_target_cache_refresh(state.player, "large_world_regression")

	var initial_state: Dictionary = engine.crime_target_refresh_state_by_actor.get("1", {})
	_check(
		initial_state.get("candidate_ids", []).size() == 751,
		"Crime target refresh did not freeze the large-world candidate snapshot"
	)

	# Reproduce the annual mutation storm that previously reset cursor zero on every
	# quantum and therefore never published a complete target projection.
	var first_complete_quantum := -1
	for quantum in range(2000):
		if quantum < 80:
			state.year += 1
			engine._on_crime_target_realtime_tick({
				"event_name": str(ActionEventTypes.YEAR_PASSED)
			})
		engine._service_crime_target_refresh_queue()
		var resident: Dictionary = engine.resident_crime_target_contract(1)
		if bool(resident.get("complete", false)):
			first_complete_quantum = quantum
			break

	_check(
		first_complete_quantum >= 0,
		"A 750-NPC crime target scan did not complete while its source was changing"
	)
	_check(
		first_complete_quantum < 1000,
		"The frozen crime target scan exceeded its bounded convergence budget"
	)
	_check(
		engine.crime_target_refresh_keys.has("1"),
		"Dirty annual events were not coalesced into one follow-up target scan"
	)

	var followup_complete := false
	for quantum in range(2000):
		engine._service_crime_target_refresh_queue()
		if not engine.crime_target_refresh_keys.has("1"):
			followup_complete = true
			break

	_check(followup_complete, "The coalesced target refresh did not become idle")
	_check(
		str(engine.crime_target_source_signature_by_actor.get(1, ""))
		== engine._crime_target_source_signature(state.player),
		"The coalesced target refresh did not commit the latest source signature"
	)

	# A projection subscriber may synchronously change its own source while the
	# completion snapshot is being published. That invalidation must survive the
	# completed generation's cleanup.
	var invalidator := PublishInvalidator.new()
	invalidator.state = state
	invalidator.engine = engine
	state.event_bus.subscribe(
		"crime.target.resident_projection.published",
		invalidator,
		"invalidate",
		{
			"allow_defer": false,
			"force_immediate": true,
			"subscription_id": "crime_target_publish_invalidation_regression"
		}
	)
	# Resident projection events are change notifications, so first make this
	# generation differ from the already-committed snapshot. The subscriber then
	# performs a second synchronous mutation while that changed snapshot publishes.
	state.year += 1
	engine.queue_crime_target_cache_refresh(state.player, "publish_race_regression")
	for quantum in range(2000):
		engine._service_crime_target_refresh_queue()
		if invalidator.fired:
			break
	_check(invalidator.fired, "Complete target publication did not reach its subscriber")
	_check(
		engine.crime_target_refresh_keys.has("1"),
		"A synchronous publication invalidation was lost during generation cleanup"
	)
	for quantum in range(2000):
		engine._service_crime_target_refresh_queue()
		if not engine.crime_target_refresh_keys.has("1"):
			break
	_check(
		not engine.crime_target_refresh_keys.has("1"),
		"The post-publication follow-up scan did not converge"
	)

	# A target refresh is derived UI work and must not compete with an active age-up.
	engine.queue_crime_target_cache_refresh(state.player, "yearly_priority_regression")
	state.scenario_state ["loading_runtime"] = {
		"active": true,
		"session_stage": "running",
		"completion_state": "running"
	}
	var paused_state: Dictionary = engine.crime_target_refresh_state_by_actor.get("1", {})
	var paused_cursor := int(paused_state.get("cursor", -1))
	engine._drive_crime_target_refresh_process_frame()
	paused_state = engine.crime_target_refresh_state_by_actor.get("1", {})
	_check(
		int(paused_state.get("cursor", -2)) == paused_cursor,
		"Crime target projection consumed work during authoritative yearly processing"
	)

	state.scenario_state ["loading_runtime"] = {
		"active": false,
		"session_stage": "complete",
		"completion_state": "complete"
	}
	engine._drive_crime_target_refresh_process_frame()
	var resumed_state: Dictionary = engine.crime_target_refresh_state_by_actor.get("1", {})
	_check(
		resumed_state.is_empty() or int(resumed_state.get("cursor", 0)) > paused_cursor,
		"Crime target projection did not resume after yearly processing completed"
	)

	print("CRIME TARGET REFRESH TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
