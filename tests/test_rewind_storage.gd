extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

# Enter at encoding, leaving production encoding and incremental disk I/O intact.
func _begin(state: GameState, path: String, payload: Dictionary) -> void:
	state.scenario_state["rewind_snapshot_pipeline"] = {
		"active": true, "stage": "save_write_encode_start", "path": path,
		"_chunk_out": payload, "_write_file_chunk_size": 32,
	}

func _finish(state: GameState) -> void:
	for step in range(100000):
		if state.step_rewind_snapshot_pipeline():
			return
	_check(false, "Rewind writer did not finish")

func _write_first_chunk(state: GameState) -> void:
	for step in range(128):
		if state.scenario_state.rewind_snapshot_pipeline.get("stage") == "save_write_flush_chunks":
			state.step_rewind_snapshot_pipeline()
			return
		if state.step_rewind_snapshot_pipeline():
			break
	_check(false, "Rewind writer never reached the first chunk")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var state := GameState.new()
	var original := {"player_id": 42, "year": 2001, "history": "Old life"}
	if args.size() == 2:
		var path: String = args[1]
		if args[0] == "--verify-path":
			var restored := BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path))
			_check(restored.get("year") == 2001 and restored.get("player_id") == 42, "Previous rewind no longer decodes")
		else:
			var payload := original.duplicate(true)
			if args[0] == "--fault-path":
				payload["history"] = Crypto.new().generate_random_bytes(262144).hex_encode()
			_begin(state, path, payload)
			state.scenario_state.rewind_snapshot_pipeline["_write_file_chunk_size"] = 32768
			_finish(state)
			if args[0] == "--fault-path":
				_check(state.rewind_snapshot_paths.is_empty(), "Failed rewind write published a usable snapshot")
				_check(not state.scenario_state.rewind_snapshot_pipeline.get("success", true), "Failed rewind write reported success")
				if not failed:
					print("SAVE FAILURE REPORT: PASS")
			else:
				_check(state.rewind_snapshot_paths == [path], "Initial rewind not published")
		quit(1 if failed else 0)
		return

	state._ensure_rewind_dir()
	var path := "user://rewind_cache/rewind_test.bin"
	_begin(state, path, original)
	_finish(state)
	_check(state.rewind_snapshot_paths == [path], "Initial rewind not published")
	var old_bytes := FileAccess.get_file_as_bytes(path)
	_check(BinarySaveEngine.decode(old_bytes).get("year") == 2001, "Initial rewind cannot decode")
	state.rewind_snapshot_paths.clear()
	_begin(state, path, {"player_id": 42, "year": 2002, "history": "New life"})
	_write_first_chunk(state)
	_check(FileAccess.get_file_as_bytes(path) == old_bytes, "Partial rewind write destroyed the previous snapshot")
	_check(state.rewind_snapshot_paths.is_empty(), "Partial rewind became selectable")
	_finish(state)
	_check(BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path)).get("year") == 2002, "Replacement rewind cannot decode")
	_check(state.rewind_snapshot_paths == [path], "Replacement rewind not published exactly once")
	_check(DirAccess.get_files_at("user://rewind_cache").size() == 1, "Successful rewind left a temporary file")

	var known_paths := state.rewind_snapshot_paths.duplicate()
	_begin(state, "user://missing-parent/rewind.bin", original)
	_finish(state)
	_check(state.rewind_snapshot_paths == known_paths, "Failed open changed the rewind history")
	_check(not state.scenario_state.rewind_snapshot_pipeline.get("success", true), "Failed open not reported")

	var blocked := "user://rewind_cache/blocked.bin"
	DirAccess.make_dir_absolute(blocked)
	_begin(state, blocked, original)
	_finish(state)
	_check(state.rewind_snapshot_paths == known_paths, "Failed rename published a snapshot")
	var recovery: String = state.scenario_state.rewind_snapshot_pipeline.get("recovery_path", "")
	_check(not recovery.is_empty() and FileAccess.file_exists(recovery), "Failed rename lost recovery bytes")
	if not recovery.is_empty() and FileAccess.file_exists(recovery):
		_check(BinarySaveEngine.decode(FileAccess.get_file_as_bytes(recovery)).get("year") == 2001, "Recovery snapshot cannot decode")
		DirAccess.remove_absolute(recovery)
	DirAccess.remove_absolute(blocked)
	# A vanished partial file or empty encoder result must not enter history.
	_begin(state, "user://rewind_cache/missing.bin", original)
	_write_first_chunk(state)
	var temporary: String = state._rewind_temp_path
	_check(not temporary.is_empty(), "Writer did not stage its partial file")
	if not temporary.is_empty():
		DirAccess.remove_absolute(temporary)
	_finish(state)
	_check(state.rewind_snapshot_paths == known_paths, "Missing partial file changed history")
	_check(not state.scenario_state.rewind_snapshot_pipeline.get("success", true), "Missing partial file reported success")
	state.scenario_state["rewind_snapshot_pipeline"] = {
		"active": true, "stage": "save_write_flush_open", "path": path,
		"_write_bytes": PackedByteArray(),
	}
	var previous_bytes := FileAccess.get_file_as_bytes(path)
	_finish(state)
	_check(FileAccess.get_file_as_bytes(path) == previous_bytes, "Empty encoding replaced the old snapshot")
	_check(not state.scenario_state.rewind_snapshot_pipeline.get("success", true), "Empty encoding reported success")

	# Starting another capture and resetting a life must discard unfinished bytes.
	_begin(state, "user://rewind_cache/cancel.bin", original)
	_write_first_chunk(state)
	temporary = state._rewind_temp_path
	state.player = Person.new()
	state.player.id = 42
	state.capture_rewind_snapshot()
	_check(not temporary.is_empty() and not FileAccess.file_exists(temporary), "New capture leaked unfinished bytes")
	_check(state.has_pending_rewind_snapshot_pipeline(), "New capture failed to start")
	_begin(state, "user://rewind_cache/reset.bin", original)
	_write_first_chunk(state)
	temporary = state._rewind_temp_path
	# The world reset clears scenario state before resetting rewind support.
	state.scenario_state.clear()
	state.reset_rewind_support_for_new_life()
	_check(not state.has_pending_rewind_snapshot_pipeline(), "Reset left an active writer")
	_check(not temporary.is_empty() and not FileAccess.file_exists(temporary), "Reset leaked unfinished bytes")

	# A failed replacement at capacity must preserve the oldest playable snapshot.
	for index in range(state.REWIND_LIMIT):
		_begin(state, "user://rewind_cache/retained_%d.bin" % index, original)
		_finish(state)
	known_paths = state.rewind_snapshot_paths.duplicate()
	_begin(state, "user://missing-parent/overflow.bin", original)
	_finish(state)
	_check(state.rewind_snapshot_paths == known_paths, "Failure evicted a valid rewind")
	_check(FileAccess.file_exists(known_paths[0]), "Failure removed oldest rewind bytes")
	var revisited: String = known_paths[0]
	_begin(state, revisited, original)
	_finish(state)
	_check(state.rewind_snapshot_paths.size() == state.REWIND_LIMIT, "Revisiting a year duplicated its history entry")
	_check(state.rewind_snapshot_paths.back() == revisited and FileAccess.file_exists(revisited), "Revisiting a year pruned its replacement")
	known_paths = state.rewind_snapshot_paths.duplicate()
	_begin(state, "user://rewind_cache/newest.bin", original)
	_finish(state)
	_check(state.rewind_snapshot_paths.size() == state.REWIND_LIMIT, "Successful rewind exceeded retention limit")
	_check(not FileAccess.file_exists(known_paths[0]), "Successful rewind did not prune oldest snapshot")
	state.reset_rewind_support_for_new_life()
	if not failed:
		print("REWIND STORAGE TESTS: PASS")
	quit(1 if failed else 0)
