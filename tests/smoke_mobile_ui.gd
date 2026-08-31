extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _save(name: String) -> void:
	if "--smoke-no-screenshots" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OS.get_environment("ERA_PREVIEW_DIR").path_join(name + ".png"))
	if result != OK:
		push_error("Could not save mobile screenshot")
		quit(1)

func _tap(point: Vector2) -> void:
	var screen_point := root.get_final_transform() * point
	print("MOBILE TAP: viewport=", point, "; event=", screen_point, "; window=", root.size)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = screen_point
	press.pressed = true
	Input.parse_input_event(press)
	await create_timer(0.1).timeout
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = screen_point
	release.pressed = false
	Input.parse_input_event(release)
	await create_timer(0.2).timeout

func _swipe(point: Vector2, movement: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.position = root.get_final_transform() * point
	press.pressed = true
	Input.parse_input_event(press)
	await create_timer(0.05).timeout
	for step in range(1, 13):
		var drag := InputEventScreenDrag.new()
		drag.position = root.get_final_transform() * (point + movement * step / 12.0)
		drag.relative = root.get_final_transform().basis_xform(movement / 12.0)
		Input.parse_input_event(drag)
		await create_timer(0.02).timeout
	var release := InputEventScreenTouch.new()
	release.position = root.get_final_transform() * (point + movement)
	Input.parse_input_event(release)
	await create_timer(0.8).timeout

func _run() -> void:
	if not MobileSupport.is_enabled():
		push_error("Run this test with -- --mobile-preview")
		quit(1)
		return
	if OS.get_environment("ERA_PREVIEW_DIR").is_empty() and "--smoke-no-screenshots" not in OS.get_cmdline_user_args():
		push_error("Set ERA_PREVIEW_DIR to an existing screenshot output directory")
		quit(1)
		return
	root.unresizable = true
	root.min_size = Vector2i(960, 540)
	root.max_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	await process_frame
	if "--smoke-loader" in OS.get_cmdline_user_args():
		change_scene_to_file("res://scenes/mobile_boot.tscn")
		await process_frame
		await _save("mobile-loading")
		var deadline := Time.get_ticks_msec() + 120000
		while Time.get_ticks_msec() < deadline and (current_scene == null or not current_scene.has_method("_skip_startup_intro_to_title_card")):
			await create_timer(0.2).timeout
		if current_scene == null or not current_scene.has_method("_skip_startup_intro_to_title_card"):
			push_error("Mobile loading screen did not hand off to the game")
			quit(1)
			return
	else:
		change_scene_to_file("res://scenes/main.scn")
	await create_timer(3).timeout
	current_scene.call("_skip_startup_intro_to_title_card")
	await create_timer(3).timeout
	await _save("mobile-title")
	print("MOBILE VIEWPORT ", root.get_visible_rect(), " SCALE ", root.content_scale_size)
	var account_button: Button = current_scene.get("startup_intro_overlay").get_node("MobileAccountActions/Createaccount")
	await _tap(account_button.get_global_rect().get_center())
	var account_open: bool = current_scene.get("title_card_account_popup") != null and current_scene.get("title_card_account_popup").visible
	print("MOBILE ACCOUNT TAP: ", account_open)
	if not account_open:
		push_error("Touch failed to open the account form")
		quit(1)
		return
	await create_timer(1).timeout
	await _save("mobile-account")
	MobileSupport.handle_back(current_scene)
	await _tap(Vector2(480, 280))
	await create_timer(3).timeout
	await _save("mobile-modes")
	var entry_button: Button = current_scene.call("_choose_ereality_entry_button")
	print("MOBILE ENTRY BUTTON ", entry_button.get_global_rect(), "; disabled=", entry_button.disabled)
	entry_button.pressed.connect(func(): print("MOBILE ENTRY PRESSED"))
	await _tap(entry_button.get_global_rect().get_center())
	await create_timer(4).timeout
	await _save("mobile-creator")
	var viewer = current_scene.get("god_mode_viewer")
	if viewer == null:
		push_error("The character creator was not created")
		quit(1)
		return
	if viewer != null:
		print("MOBILE FORM BOUNDS ", viewer.panel.get_global_rect(), " ROOT MIN ", viewer.root.get_combined_minimum_size(), "; visible=", viewer.is_visible_in_tree())
		if not viewer.is_visible_in_tree():
			push_error("Touch did not open the character creator")
			quit(1)
			return
		for widget in [viewer.first_name_edit, viewer.gender_picker, viewer.health_slider]:
			viewer.scroll.ensure_control_visible(widget)
			await create_timer(0.5).timeout
			var before: int = viewer.scroll.scroll_vertical
			var slider_value: float = viewer.health_slider.value
			await _swipe(widget.get_global_rect().get_center(), Vector2(0, -160))
			if viewer.scroll.scroll_vertical < before + 60 or viewer.gender_picker.get_popup().visible or viewer.health_slider.value != slider_value:
				push_error("Swipe over %s failed or activated its control" % widget.get_class())
				quit(1)
				return
		print("MOBILE FORM SWIPES: PASS")
		await _save("mobile-creator-scrolled")
	if "--smoke-prewarm" in OS.get_cmdline_user_args() and viewer != null:
		viewer.scroll.ensure_control_visible(viewer.prewarm_button)
		await create_timer(0.5).timeout
		await _tap(viewer.prewarm_button.get_global_rect().get_center())
		var deadline := Time.get_ticks_msec() + 90000
		while Time.get_ticks_msec() < deadline and not bool(viewer.engine.current_state().get("viewer_ready_button_enabled", false)):
			await create_timer(1).timeout
		var ready: bool = bool(viewer.engine.current_state().get("viewer_ready_button_enabled", false))
		print("MOBILE PREWARM: ", viewer.engine.current_state().get("lifecycle", "unknown"), "; ready=", ready)
		if not ready:
			push_error("World generation did not become ready within 90 seconds")
			quit(1)
			return
		viewer.scroll.ensure_control_visible(viewer.prewarm_button)
		await create_timer(1).timeout
		await _save("mobile-prewarm")
		await _tap(viewer.prewarm_button.get_global_rect().get_center())
		await create_timer(10).timeout
		var entered: bool = current_scene.get("gs").player != null and not viewer.is_visible_in_tree()
		print("MOBILE LIFE: entered=", entered)
		await _save("mobile-life")
		if not entered:
			push_error("Touch did not enter the generated life")
			quit(1)
			return
		# A read-only HUD lookup must not expose mutable nested resident contracts.
		var previous_deck: Variant = current_scene.get_meta("resident_main_tab_surface_contracts", {})
		var previous_lens: Variant = current_scene.get_meta("controlled_actor_incarceration_lens_contract", {})
		var fixture := {"relationships": {"incarceration_lens": {"actor_id": current_scene.get("gs").player.id, "active": true, "nested": {"marker": true}}}}
		current_scene.set_meta("resident_main_tab_surface_contracts", fixture)
		current_scene.set_meta("controlled_actor_incarceration_lens_contract", {})
		var lens: Dictionary = current_scene.call("_controlled_actor_incarceration_lens_contract")
		var lookup_ok: bool = bool(lens.get("active", false))
		if lens.has("nested"):
			lens.nested.marker = false
		lookup_ok = lookup_ok and fixture.relationships.incarceration_lens.nested.marker
		current_scene.set_meta("resident_main_tab_surface_contracts", previous_deck)
		current_scene.set_meta("controlled_actor_incarceration_lens_contract", previous_lens)
		if not lookup_ok:
			push_error("HUD lens lookup changed or aliased its resident contract")
			quit(1)
			return
		var stat_fixture: Dictionary = current_scene.call("_make_player_stat_row", "Health", 100)
		var stat_label: Label = stat_fixture.label
		var stat_bar: ProgressBar = stat_fixture.bar
		current_scene.call("_apply_player_stat_surface_content", stat_label, stat_bar, "Health", 80, 100, {})
		var initial_key: int = stat_bar.get_meta("mobile_stat_content_key", -1)
		current_scene.call("_apply_player_stat_surface_content", stat_label, stat_bar, "Health", 15, 100, {})
		var values_update: bool = stat_bar.value == 15 and stat_bar.get_meta("mobile_stat_content_key") != initial_key
		current_scene.call("_apply_player_stat_surface_content", stat_label, stat_bar, "Health", 15, 100, {"subject_dead": true})
		values_update = values_update and stat_bar.value == 0 and "Dead" in stat_label.text
		current_scene.call("_apply_player_stat_surface_content", stat_label, stat_bar, "Health", 150, 200, {})
		values_update = values_update and stat_bar.value == 150 and stat_bar.max_value == 200
		stat_fixture.row.free()
		if not values_update:
			push_error("Mobile stat cache failed to refresh changed values, context, or range")
			quit(1)
			return
		print("MOBILE HUD REGRESSIONS: PASS")
		var diary: RichTextLabel = current_scene.get("output_label")
		var stats: Control = current_scene.get("player_stats_overlay")
		var nav: Control = current_scene.get_node("UIContainer/MobileNavigation")
		var viewport: Rect2 = current_scene.get_viewport_rect()
		if not viewport.encloses(diary.get_global_rect()) or diary.get_global_rect().intersects(stats.get_global_rect()) or nav.get_global_rect().intersects(diary.get_global_rect()):
			push_error("Mobile gameplay navigation, stats, or diary overlap or overflow")
			quit(1)
			return
		var world_button: Button = current_scene.get("ui_nav_buttons")["world"]
		await _tap(world_button.get_global_rect().get_center())
		await create_timer(3).timeout
		await _save("mobile-world")
		if str(current_scene.get("current_panel")) != "world":
			push_error("Touch did not open the World tab")
			quit(1)
			return
	print("MOBILE UI SMOKE: PASS")
	quit()
