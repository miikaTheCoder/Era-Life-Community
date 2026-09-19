extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	# Deliberately load by path: static class references in this test would hide
	# regressions by pulling in the implementations before the assertion.
	var state = load("res://core/state/GameState.gd").new()
	var steps: Array = state._resident_runtime_engine_steps()
	check(not ResourceLoader.has_cached("res://systems/bending/BendingEngine.gd"), "Describing residency must not eagerly load bending")
	var engines := 0
	var alias_found := false
	var bank_step: Dictionary = {}
	for step in steps:
		if not step.has("engine_property"):
			continue
		engines += 1
		check(step.runner.is_valid() and not str(step.engine_class_name).is_empty(), "Engine step must preserve its callable and registered class name")
		if step.engine_class_name == &"BoxingRoundLogEngine":
			alias_found = true
		if step.engine_property == &"bank_engine":
			bank_step = step
	check(engines == 232 and alias_found, "Residency order/catalog must retain all 232 engine steps, including file/name aliases")
	check(not bank_step.is_empty(), "Bank residency step missing")
	if not bank_step.is_empty():
		var first: Dictionary = bank_step.runner.call()
		var instance = state.bank_engine
		check(first.get("success", false) and instance != null, "Executing a delayed step must construct the real engine")
		if instance != null:
			check(instance.get_script().get_global_name() == bank_step.engine_class_name, "Constructed engine must match its descriptor")
		var second: Dictionary = bank_step.runner.call()
		check(second.get("mode", "") == "engine_already_resident" and state.bank_engine == instance, "Repeated execution must reuse the existing engine")
	print("STARTUP DEPENDENCY TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
