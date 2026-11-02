extends "smoke_living_households.gd"

# Private-display automation through existing Continue and real yearly owners.
# This is not interactive playtesting or device certification. Keep the 90 s gate.
var restore_started_ms := 0
var hydration_started_ms := 0
var previous_stage := ""
var stage_started_ms := 0
var stage_ms: Dictionary = {}

func _restore() -> void:
	restore_started_ms = Time.get_ticks_msec()
	await super._restore()
	print("COLD CONTINUE RESULT: ", JSON.stringify({
		"passed": not failed, "restore_and_play_ms": Time.get_ticks_msec() - restore_started_ms,
		"stages_ms": stage_ms, "years_completed": years_completed,
		"headless": DisplayServer.get_name() == "headless",
	}))

func _hydration_complete() -> bool:
	var now := Time.get_ticks_msec()
	if hydration_started_ms == 0:
		hydration_started_ms = now
		print("COLD CONTINUE FIRST FRAME: ", now - restore_started_ms)
	var complete := super._hydration_complete()
	var state: GameState = current_scene.get("gs")
	var hydration = state.game_state_hydration_runtime
	var stage := "engine_graph"
	if hydration != null:
		var queue: Array = hydration.background_hydration_queue
		stage = str(queue.front()) if not queue.is_empty() else "tail"
		if not queue.is_empty() and queue.front().get("kind", "") == "checkpoint_entity_state":
			stage = "entity_" + str(hydration.active_hydration_session.get("checkpoint_entity_state_stage", -1))
	if stage != previous_stage or complete:
		if not previous_stage.is_empty():
			stage_ms[previous_stage] = int(stage_ms.get(previous_stage, 0)) + now - stage_started_ms
		previous_stage = stage
		stage_started_ms = now
	if complete:
		print("COLD CONTINUE TIMING: ", JSON.stringify({
			"continue_to_complete_ms": now - restore_started_ms,
			"first_frame_to_complete_ms": now - hydration_started_ms, "stages_ms": stage_ms,
		}))
	return complete

func _verify_shared_checkpoint(payload: Dictionary, state: GameState) -> void:
	super._verify_shared_checkpoint(payload, state)
	var expected_feed: Array = []
	for entry in payload.get("world_feed", []):
		expected_feed.append(state.normalize_world_feed_entry(entry))
	_check(state.world_feed == expected_feed, "Cold Continue changed exact normalized world history or its order")
	for key in ["life_stories", "family_businesses", "life_diary_state_by_npc"]:
		_check(JSON.parse_string(JSON.stringify(state.scenario_state.get(key, {}))) == payload.get("scenario_state", {}).get(key, {}), "Cold Continue changed exact " + key)
	for row in payload.get("npcs", []):
		var actor: Person = state.get_npc_by_id(int(row.id), false)
		if not _check(actor != null, "Cold Continue lost saved actor " + str(row.id)):
			continue
		for key in ["first_name", "last_name", "age", "alive"]:
			_check(actor.get(key) == row.get(key), "Cold Continue changed cast identity %s %s" % [row.id, key])
		_check((actor.partner.id if actor.partner != null else -1) == int(row.get("partner_id", -1)), "Cold Continue changed partner for " + str(row.id))
		for key in ["parents", "children", "friends", "affection"]:
			_check(JSON.parse_string(JSON.stringify(actor.get(key))) == row.get(key, {} if key == "affection" else []), "Cold Continue changed actor %s %s" % [row.id, key])
