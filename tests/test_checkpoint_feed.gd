extends SceneTree

var failed := false

class CostlyGuard extends GameStateHydrationRuntime:
	func _capture_controlled_actor_hydration_snapshot() -> Dictionary:
		var snapshot := super._capture_controlled_actor_hydration_snapshot()
		OS.delay_usec(2000)
		return snapshot

class SlowFeedState extends GameState:
	var calls := 0
	func normalize_world_feed_entry(entry) -> Dictionary:
		calls += 1
		OS.delay_usec(2000)
		return super.normalize_world_feed_entry(entry)

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _runtime(state: GameState) -> GameStateHydrationRuntime:
	var runtime := CostlyGuard.new(state)
	runtime.active_hydration_session = {
		"payload": {"world_feed": state.world_feed},
		"checkpoint_entity_state_stage": 4,
		"checkpoint_world_feed_cursor": 0,
		"strict_one_item_per_slice": true,
	}
	runtime.background_hydration_active = true
	runtime.background_hydration_queue = [{"kind": "checkpoint_entity_state", "phase": "entity_graph"}]
	return runtime

func _run() -> void:
	var state := GameState.new()
	state.player = Person.new()
	state.player.id = 42
	state.player_id = 42
	state.player.affection[43] = 76
	state.npcs = [state.player]
	state._rebuild_npc_index()
	state.year = 2016
	for index in range(257):
		state.world_feed.append({"text": "Saved event %d" % index, "year": 2000 + index % 17, "custom": {"ordinal": index}})
	state.world_feed[1] = "My legacy event"
	state.world_feed[2] = {"text": "Champion", "event_name": "bending_tournament_champion", "tournament_id": "cup_2004", "year": 2016}
	var expected: Array = state.world_feed.map(func(row): return state.normalize_world_feed_entry(row))
	var runtime := _runtime(state)
	var slices := 0
	while int(runtime.active_hydration_session.checkpoint_entity_state_stage) == 4 and slices < 300:
		var before := int(runtime.active_hydration_session.checkpoint_world_feed_cursor)
		var report := runtime.run_background_hydration_slice(1)
		var after := int(runtime.active_hydration_session.checkpoint_world_feed_cursor)
		_check(after - before <= 32, "World feed exceeded bounded batch cap")
		_check(report.serviced_items == 1, "Feed batched across unrelated hydration items")
		_check(state.player.affection[43] == 76 + slices, "Feed hydration lost interleaved relationship changes")
		state.player.affection[43] += 1
		slices += 1
	_check(slices < 100, "World feed still consumes a guarded frame per entry: %d slices" % slices)
	_check(state.world_feed == expected, "Batched normalization changed world history, metadata or order")
	_check(runtime.active_hydration_session.checkpoint_entity_state_stage == 5, "Feed did not advance after exhausting entries")
	var slow := SlowFeedState.new()
	slow.world_feed = ["One", "Two", "Three"]
	var slow_runtime := _runtime(slow)
	slow_runtime.run_background_hydration_slice(1)
	_check(slow.calls == 1 and slow_runtime.active_hydration_session.checkpoint_world_feed_cursor == 1, "Slow normalization ignored its work deadline")
	var empty := GameState.new()
	var empty_runtime := _runtime(empty)
	empty_runtime.run_background_hydration_slice(1)
	_check(empty_runtime.active_hydration_session.checkpoint_entity_state_stage == 5, "Empty history stalled hydration")
	print("CHECKPOINT FEED TESTS: ", "FAIL" if failed else "PASS", "; slices=", slices)
	quit(1 if failed else 0)
