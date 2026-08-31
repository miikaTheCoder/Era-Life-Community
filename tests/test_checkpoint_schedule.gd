extends SceneTree

class RecordingManager extends RealityResidencyManager:
	var serviced: Array[String] = []

	# Drive rendering ticks explicitly so this scheduling test also runs headless.
	func _arm_service_pump_for_next_renderer_frame() -> void:
		pass

	func _service_rehydration_record(signature: String, record: Dictionary) -> void:
		serviced.append(signature)
		record["state"] = "rehydration_pending" if serviced.size() == 1 else "failed"
		resident_records[signature] = record
		if record["state"] == "failed":
			_remove_service_key("resident:%s" % signature)

var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := RecordingManager.new()
	manager.attached_signature = "playing"
	var playing := {
		"signature": "playing", "state": "ready", "lens_attached": true,
		"projection_surface_packets_complete": true,
	}
	manager.resident_records["playing"] = playing.duplicate(true)
	manager.active_service_keys = ["resident:playing"]
	manager._ensure_service_pump()
	_check(not manager.service_pump_armed, "A completed life should leave the scheduler dormant")

	var path := "user://checkpoint-scheduling-test.bin"
	var fixture := FileAccess.open(path, FileAccess.WRITE)
	fixture.store_8(0)
	fixture.close()
	manager.reserve_checkpoint_reality("restore", {"checkpoint_path": path})
	_check(manager.service_pump_armed, "Loading another life must wake the dormant scheduler")
	manager._service_pump_frame()
	_check(manager.serviced == ["restore"], "The first frame must service the requested restore")
	_check(manager.service_pump_armed, "An incomplete restore must schedule another frame")
	manager._service_pump_frame()
	_check(manager.serviced == ["restore", "restore"], "The next frame must continue the restore")
	_check(manager.resident_records["playing"] == playing, "Loading must not alter or service the active life")
	_check(manager.attached_signature == "playing", "Loading must not detach the active life before commit")
	_check(not manager.service_pump_armed, "A failed restore must stop scheduling work")
	DirAccess.remove_absolute(path)
	await process_frame
	print("CHECKPOINT SCHEDULING TESTS: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
