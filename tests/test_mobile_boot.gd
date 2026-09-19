extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1080, 2412)
	change_scene_to_file("res://scenes/mobile_boot.tscn")
	await process_frame
	for dimensions in [Vector2i(1080, 2412), Vector2i(420, 740), Vector2i(720, 1600)]:
		root.size = dimensions
		MobileSupport.configure_viewport(current_scene)
		for frame in range(6):
			await process_frame
		var viewport: Rect2 = current_scene.get_viewport_rect()
		var content: Rect2 = current_scene.loading_content.get_global_rect()
		if not viewport.encloses(content) or absf(content.get_center().y - viewport.get_center().y) > 2:
			failures += 1
			push_error("Loading content must stay centered in the resized phone viewport: %s vs %s" % [content, viewport])
	print("MOBILE BOOT TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
