extends SceneTree

# A busy UI projection must not prevent the checkpoint supplying its data
# from making progress. Model a projection worker that keeps returning pending.
class BusyProjectionManager extends RealityResidencyManager:
	var payload_slices := 0
	var projection_slices := 0

	func _service_checkpoint_interactive_projection_lane(_signature: String, _record: Dictionary, _runtime: GameState, _allow_step: bool, _budget: int) -> Dictionary:
		projection_slices += 1
		return {"success": true, "serviced": true, "projection_terminal": false}

	func _service_ready_checkpoint_payload_tail(_signature: String, _record: Dictionary, _runtime: GameState) -> bool:
		payload_slices += 1
		return false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := BusyProjectionManager.new()
	var runtime := GameState.new()
	var record := {
		"runtime_ref": runtime, "lens_attached": true,
		"resident_chassis_tail_complete": true,
		"checkpoint_payload_apply_pending": true,
	}
	manager.resident_records["restore"] = record
	for tick in range(4):
		manager._service_ready_checkpoint_tail("restore", record, 1, 1)
	var passed := manager.payload_slices == 4 and manager.projection_slices >= 4
	if not passed:
		push_error("Busy projection starved checkpoint hydration: %d payload slices" % manager.payload_slices)
	print("CHECKPOINT PROGRESS TESTS: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
