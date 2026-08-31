extends SceneTree

class RuntimeShell extends RefCounted:
	var realm_engine = null
class RealmService extends RefCounted:
	var realms := {7: {"name": "Test Realm", "population": 200000, "land": 100}}

func _initialize() -> void:
	var runtime := RuntimeShell.new()
	var market := GlobalMarketEngine.new(runtime)
	var passed := market._realm_local_modifier(7) == 1.0 and market._realm_name(7) == ""
	runtime.realm_engine = RealmService.new()
	passed = passed and market._realm_local_modifier(7) == 1.2 and market._realm_name(7) == "Test Realm"
	passed = passed and market._realm_local_modifier(99) == 1.0 and market._realm_name(99) == ""
	if not passed:
		push_error("Market queries must tolerate a partial checkpoint shell and use realm data once available")
	print("CHECKPOINT MARKET TESTS: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
