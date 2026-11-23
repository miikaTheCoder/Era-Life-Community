extends "test_story_pack_safety.gd"

# Render the real profile-packet consumers without booting unrelated world UI.
# The safety regression separately exercises these paths in fresh cold processes.
func _run() -> void:
	root.size = Vector2i(1440, 900)
	var data := _sample()
	data.stories[0].nodes.invitation.choices[0].result = "I kept [color=red]literal results[/color] with {person}."
	_install(data)
	var state := _pack_fixture()
	state.get_npc_by_id(103, false).first_name = "[i]Casey[/i]"
	_reload(state)
	_tick(state)
	_check(_resolve(state, PACK_ID, "walk").get("success", false), "Graphical text fixture could not answer its story")
	var design = load("res://ui/EraTheme.gd")
	var frame := PanelContainer.new()
	frame.position = Vector2(180, 90)
	frame.size = Vector2(1080, 720)
	frame.add_theme_stylebox_override("panel", design.box(design.PANEL))
	root.add_child(frame)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.add_theme_font_override("normal_font", design.BODY)
	label.add_theme_font_size_override("normal_font_size", 20)
	label.add_theme_color_override("default_color", design.TEXT)
	frame.add_child(label)
	for restored in [false, true]:
		if restored:
			state = _hydrate(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload(), state.scenario_runtime_contract_engine.export_state())
		var scene = load("res://scenes/MainScene.gd").new()
		scene.gs = state
		scene.output_label = label
		var packet := UniversalSwitchContractEngine.new(state).prepare_profile_pointer_packet(state.player, {"source":"literal_text_graphical"})
		for consumer in ["press-frame", "published-diary"]:
			label.clear()
			if label.has_meta("visible_truth_anchor_signature"):
				label.remove_meta("visible_truth_anchor_signature")
			if consumer == "press-frame":
				scene._apply_playable_life_viewer_packet_press_frame_lens_only(packet, "", "relationship_profile_switch_literal_graphical")
			else:
				_check(scene._install_switched_actor_life_diary_from_published_packet(state.player, packet, "literal_text_graphical", {"actor_id":state.player_id}), "Graphical published diary was not installed")
			_check(label.get_parsed_text().contains("[color=red]literal results[/color]") and label.get_parsed_text().contains("[i]Casey[/i]"), "Graphical switch view interpreted authored text")
			await create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			if OS.has_environment("ERA_PREVIEW_DIR"):
				var folder := OS.get_environment("ERA_PREVIEW_DIR")
				DirAccess.make_dir_recursive_absolute(folder)
				var screenshot := root.get_texture().get_image()
				var bright_pixels := 0
				for y in range(100, 190):
					for x in range(190, 900):
						var pixel := screenshot.get_pixel(x, y)
						if pixel.r > 0.6 and pixel.g > 0.6 and pixel.b > 0.6:
							bright_pixels += 1
				_check(bright_pixels > 100, "Graphical switch capture omitted visible diary text")
				screenshot.save_png(folder.path_join(consumer + ("-hydrated" if restored else "-live") + ".png"))
		scene.free()
	frame.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PACK_FILE))
	print("STORY PACK TEXT GRAPHICAL: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
