extends SceneTree

func _initialize() -> void:
	call_deferred("_validate")

func _validate() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: Godot --headless --path project --script scripts/validate-story-pack.gd -- /absolute/path/pack.json")
		quit(2)
		return
	var engine := LifeStoryEngine.new()
	# Validate against built-ins without rejecting a copy already installed locally.
	var reserved: Array = engine.catalog.filter(func(row): return not str(row.id).contains(".")).map(func(row): return str(row.id))
	var report := ModLoader.read_story_pack(args[0], reserved)
	for error in report.errors:
		printerr(str(error))
	if report.errors.is_empty():
		print("STORY PACK: PASS; stories=", report.stories.size())
	quit(0 if report.errors.is_empty() else 1)
