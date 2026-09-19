extends SceneTree
## Independent startup harness: never preload MainScene or GameState here.
var entry := "new_life"
var failed := false
var deadline := 0
var max_frame_gap_ms := 0
var last_frame_ms := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--startup-entry="):
			entry = arg.get_slice("=", 1)
	call_deferred("_run")

func _process(_delta: float) -> bool:
	var now := Time.get_ticks_msec()
	if last_frame_ms > 0:
		max_frame_gap_ms = maxi(max_frame_gap_ms, now - last_frame_ms)
	last_frame_ms = now
	if deadline > 0 and now > deadline:
		push_error("Startup profile timed out")
		quit(1)
	return false

func _capture(label: String) -> void:
	var directory := OS.get_environment("ERA_PREVIEW_DIR")
	if not directory.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(label + ".png"))

func _tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = point
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	release.pressed = false
	root.push_input(release, true)
	await process_frame

func _run() -> void:
	if entry not in ["new_life", "title", "intro"]:
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 120000
	root.size = Vector2i(420, 900)
	root.unresizable = true
	root.title = "EraLife startup profile"
	change_scene_to_file("res://scenes/mobile_boot.tscn")
	while current_scene == null:
		await process_frame
	var boot = current_scene
	for frame in range(6):
		await process_frame
	await _capture("early-menu")
	if DisplayServer.get_name() == "headless":
		boot._start_loading()
	# Queue and cancel a real action while the heavy scene loads.
	await _tap(boot.action_buttons[0])
	if boot.pending_entry != "new_life":
		push_error("The early menu did not accept input while loading")
		quit(1)
		return
	boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	if not boot.pending_entry.is_empty():
		push_error("Android Back did not cancel the pending entry")
		quit(1)
		return
	if entry == "title":
		while boot.packed_game == null:
			await process_frame
	await _tap(boot.action_buttons[["new_life", "title", "intro"].find(entry)])
	await _capture("queued-entry")
	while current_scene == boot:
		await process_frame
	var game := current_scene
	if entry == "new_life":
		while not bool(game.get_meta("choose_ereality_entry_button_hot", false)):
			await process_frame
		if game.get("choose_adventure_entry_overlay") == null or not game.get("choose_adventure_entry_overlay").is_visible_in_tree():
			push_error("New life route did not open the existing mode menu")
			quit(1)
			return
	else:
		if entry == "intro":
			await create_timer(2).timeout
			await _capture("intro")
			game.call("_skip_startup_intro_to_title_card")
		while not bool(game.get("startup_intro_accepting_input")):
			await process_frame
		if game.get("startup_intro_overlay") == null or not game.get("startup_intro_overlay").is_visible_in_tree():
			push_error("Title route did not open the existing account/continue screen")
			quit(1)
			return
	await create_timer(0.5).timeout
	await _capture("destination")
	StartupTiming.mark("profile_complete", {"entry": entry, "max_frame_gap_ms": max_frame_gap_ms, "nodes": get_node_count()})
	# Release the scene while the tree and script runtime are still alive.
	current_scene = null
	game.queue_free()
	for frame in range(5):
		await process_frame
	print("STARTUP PROFILE: PASS ", entry)
	quit()
