extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := Person.new()
	actor.id = 41
	actor.first_name = "Save"
	actor.last_name = "Regression"
	actor.age = 37
	actor.health = 186.0
	actor.bank_balance = 12345
	actor.parents = [11, 12]
	actor.children = [51]
	actor.partner = Person.new()
	actor.partner.id = 42
	actor.traits = ["Kind", "Curious"]
	actor.bending_mastery["water"] = 73
	var serializer := GameStateSerializationRuntime.new()
	var snapshot := serializer._interactive_checkpoint_actor_snapshot(actor)
	var restored: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(snapshot))
	var expected := {
		"id": 41, "first_name": "Save", "last_name": "Regression", "age": 37,
		"health": 186.0, "bank_balance": 12345, "parents": [11, 12],
		"children": [51], "partner_id": 42, "traits": ["Kind", "Curious"],
	}
	var failed := false
	# The binary codec uses JSON internally, so numeric arrays decode as floats.
	expected = JSON.parse_string(JSON.stringify(expected))
	for field in expected:
		if restored.get(field) != expected[field]:
			push_error("Character save lost %s" % field)
			failed = true
	if restored.get("bending_mastery", {}).get("water") != 73:
		push_error("Character save lost nested power data")
		failed = true
	if restored.has("partner") or restored.has("script") or restored.has("resource_path"):
		push_error("Character save included object references or Resource internals")
		failed = true
	print("CHECKPOINT ACTOR TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
