extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1080, 2412)
	var boot = load("res://scenes/mobile_boot.tscn").instantiate()
	boot.auto_load_game = false
	root.add_child(boot)
	current_scene = boot
	await process_frame
	check(not ResourceLoader.has_cached("res://scenes/MainScene.gd"), "The entry menu must not load MainScene")
	check(not ResourceLoader.has_cached("res://core/state/GameState.gd"), "The entry menu must not load GameState")
	for dimensions in [Vector2i(1080, 2412), Vector2i(420, 740), Vector2i(720, 1600)]:
		root.size = dimensions
		MobileSupport.configure_viewport(boot)
		for frame in range(6):
			await process_frame
		var viewport: Rect2 = boot.get_viewport_rect()
		var content: Rect2 = boot.loading_content.get_global_rect()
		check(viewport.encloses(content) and absf(content.get_center().y - viewport.get_center().y) <= 2, "Entry menu must remain centered and within the phone viewport")
		for button in boot.action_buttons:
			check(button.size.y >= 48 and viewport.encloses(button.get_global_rect()), "All early menu actions must be reachable touch targets")
	for index in 3:
		boot.action_buttons[index].pressed.emit()
		check(boot.pending_entry == ["new_life", "title", "intro"][index], "Choice must queue its original route while resources load")
		check(boot.cancel_button.visible, "Queued entry must be cancellable")
		boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		check(boot.pending_entry.is_empty() and not boot.action_buttons[index].disabled, "Android Back must cancel the pending choice")
	check(not ResourceLoader.has_cached("res://core/state/GameState.gd"), "Choosing/cancelling before loading must not create gameplay state")
	boot._show_error("Test failure")
	check(boot.action_buttons[0].disabled and boot.pending_entry.is_empty(), "A failed load must not allow an invalid handoff")
	print("MOBILE BOOT TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
