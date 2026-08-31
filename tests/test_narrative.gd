extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := GameState.new()
	var adventure := ChooseAdventureEngine.new(state)
	var catalog := adventure.start_adventure()
	var entries: Array = catalog.get("opps", [])
	print("NARRATIVE TEST: catalog stories=", entries.size())
	var completed := 0
	var failed := 0
	for entry in entries:
		var story_id: String = str(entry.get("choice_id", "")).trim_prefix("adventure:")
		for route in ["family", "continue"]:
			state = GameState.new()
			adventure = ChooseAdventureEngine.new(state)
			adventure.start_adventure()
			var result := adventure.start_adventure(story_id)
			var choices_taken := 0
			while choices_taken < 25 and not result.get("birth_now", false):
				var choices: Array = result.get("opps", [])
				if choices.is_empty():
					break
				var selected: String = str(choices[0].get("choice_id", ""))
				for choice in choices:
					if choice.get("choice_id", "") == "choose_birth_path:" + route:
						selected = choice.choice_id
						break
				result = adventure.choose(selected)
				choices_taken += 1
			var expected_mode := "lineage_birth" if route == "family" else "continue_as_anchor"
			var success: bool = result.get("birth_now", false) and result.get("birth_mode", "") == expected_mode and not result.get("lineage_birth_contract", {}).is_empty()
			if success:
				completed += 1
			else:
				failed += 1
			print("NARRATIVE TEST: story=", story_id, " route=", route, " choices=", choices_taken, " result=", result.get("type", ""), " pass=", success)
	# Reusing the library must not carry the previous story's completion threshold.
	var restarted := adventure.start_adventure("runaway_heir")
	if restarted.get("saturation", -1) != 0 or restarted.get("cycle", -1) != 0:
		push_error("Starting another story retained previous progress")
		failed += 1
	var after_choice := adventure.choose("heir_lie_to_captain")
	if after_choice.get("birth_ready", false) or float(after_choice.get("saturation", 0)) <= 0:
		push_error("Fresh story must accumulate its own choices before birth")
		failed += 1
	print("NARRATIVE TESTS: ", "PASS" if failed == 0 else "FAIL", "; completed paths=", completed)
	quit(0 if failed == 0 and completed > 0 else 1)
