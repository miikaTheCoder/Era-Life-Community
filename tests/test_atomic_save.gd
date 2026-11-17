extends SceneTree

var failed := false

# Isolate file publication from world generation. Production encoding, file I/O,
# summaries and failure reports still run through serialize_to_path.
class FixtureSerializer extends GameStateSerializationRuntime:
	var fixture: Dictionary = {"player_name": "Ada", "player_id": 42, "year": 2001}
	var summaries := 0
	var checkpoints := 0

	func serialize_to_payload(_options: Dictionary = {}) -> Dictionary:
		return {"success": true, "payload": fixture.duplicate(true)}

	func _write_summary_cache(_path: String, _summary: Dictionary) -> void:
		summaries += 1

	func _build_cross_device_checkpoint(_path: String, _options: Dictionary) -> void:
		checkpoints += 1

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--seed-path":
		var writer := FixtureSerializer.new()
		var report := writer.serialize_to_path(args[1])
		quit(0 if report.get("success", false) else 1)
		return
	if args.size() == 2 and args[0] == "--verify-path":
		var decoded: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(args[1])) if args[1].ends_with(".bin") else JSON.parse_string(FileAccess.get_file_as_string(args[1]))
		_check(decoded.get("year") == 2001 and decoded.get("player_id") == 42, "Previous save no longer decodes")
		quit(1 if failed else 0)
		return
	if args.size() == 2 and args[0] == "--fault-path":
		var writer := FixtureSerializer.new()
		writer.fixture["history"] = Crypto.new().generate_random_bytes(262144).hex_encode()
		var report := writer.serialize_to_path(args[1])
		_check(not report.get("success", true), "Failed write reported success")
		_check(writer.summaries == 0 and writer.checkpoints == 0, "Failed write published metadata")
		if not failed:
			print("SAVE FAILURE REPORT: PASS")
		quit(1 if failed else 0)
		return

	for extension in ["bin", "json"]:
		var path: String = "user://saved_lives/atomic_test." + extension
		var writer := FixtureSerializer.new()
		var first := writer.serialize_to_path(path)
		_check(first.get("success", false), "First save failed")
		writer.fixture["year"] = 2002
		var second := writer.serialize_to_path(path)
		_check(second.get("success", false) and second.get("wrote_file", false), "Replacement save failed")
		var decoded: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path)) if extension == "bin" else JSON.parse_string(FileAccess.get_file_as_string(path))
		_check(decoded.get("year") == 2002 and decoded.get("player_id") == 42, "Replacement did not preserve payload")
		_check(writer.summaries == 2 and writer.checkpoints == 2, "Successful saves missed metadata publication")
		_check(DirAccess.get_files_at("user://saved_lives").size() == 1, "Successful save left temporary files")
		DirAccess.remove_absolute(path)

	var writer := FixtureSerializer.new()
	var missing := writer.serialize_to_path("user://missing-parent/life.bin")
	_check(not missing.get("success", true), "Missing directory reported success")
	DirAccess.make_dir_absolute("user://saved_lives/blocked.bin")
	var blocked := writer.serialize_to_path("user://saved_lives/blocked.bin")
	_check(not blocked.get("success", true), "Directory destination reported success")
	_check(DirAccess.dir_exists_absolute("user://saved_lives/blocked.bin"), "Failed replacement removed destination")
	var recovery_path: String = blocked.get("recovery_path", "")
	_check(not recovery_path.is_empty() and FileAccess.file_exists(recovery_path), "Failed replacement lost the complete recovery file")
	if not recovery_path.is_empty() and FileAccess.file_exists(recovery_path):
		var recovered := BinarySaveEngine.decode(FileAccess.get_file_as_bytes(recovery_path))
		_check(recovered.get("year") == 2001 and recovered.get("player_id") == 42, "Recovery file is not a complete save")
		DirAccess.remove_absolute(recovery_path)
	_check(writer.summaries == 0 and writer.checkpoints == 0, "Failed saves published metadata")
	_check(not writer.last_serialization_report.get("success", true), "Failure report was not retained")
	DirAccess.remove_absolute("user://saved_lives/blocked.bin")
	if not failed:
		print("ATOMIC SAVE TESTS: PASS")
	quit(1 if failed else 0)
