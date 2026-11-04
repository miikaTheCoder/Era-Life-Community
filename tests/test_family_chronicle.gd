extends "test_ui_presentation.gd"

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.gui_embed_subwindows = true
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ui := VBoxContainer.new()
	ui.name = "UIContainer"
	host.add_child(ui)
	host.output_label = RichTextLabel.new()
	ui.add_child(host.output_label)
	host.gs = GameState.new()
	host.gs.player = Person.new()
	host.gs.player.id = 101
	host.gs.player_id = 101
	host.gs.player.first_name = "Alex"
	host.gs.player.last_name = "Story"
	host.gs.player.age = 42
	host.gs.year = 2026
	host.gs.scenario_state.life_stories = {"version":1, "actors":{"101":{"stories":{}}}}
	var adapter := Interface.new()
	adapter.name = "EraInterface"
	host.add_child(adapter)
	await _settle()
	var shell: Node = adapter.shell
	_check(is_instance_valid(shell.chronicle_button) and shell.chronicle_button.is_visible_in_tree(), "Chronicle journal entry missing")
	shell.chronicle_button.pressed.emit()
	await _settle()
	var panel: AcceptDialog = shell.chronicle_panel
	_check(panel.visible and panel.body.get_parsed_text().contains("no story memories yet"), "Chronicle empty state missing")
	panel.hide()
	var history: Array = []
	for index in range(40):
		history.append({"year":2000 + index, "text":"I listened to Sam's plans before describing my own hopes. We made room for separate directions and a conversation we could both return to."})
	host.gs.scenario_state.life_stories.actors["101"].stories.child_ambitions = {
		"story_title":"A Future of Their Own", "cast_name":"Sam Story", "status":"finished",
		"legacy":"supported_direction", "finished_year":2040, "outcome":"Room for their own future", "history":history}
	for dimensions in [Vector2i(1440, 900), Vector2i(420, 900), Vector2i(360, 640)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _settle()
		shell.chronicle_button.pressed.emit()
		await _settle()
		_check(panel.visible, "Chronicle closed during refresh")
		_check(panel.size.x <= dimensions.x and panel.size.y <= dimensions.y, "Chronicle escaped viewport at " + str(dimensions))
		_check(panel.body.get_parsed_text().contains("Sam Story"), "Chronicle omitted saved participant")
		_check(panel.body.get_content_height() > panel.body.size.y, "Long chronicle has no scrollable content")
		panel.body.get_v_scroll_bar().value = panel.body.get_v_scroll_bar().max_value
		await _settle()
		_check(panel.body.get_v_scroll_bar().value > 0, "Chronicle cannot scroll to older memories")
		panel.body.scroll_to_line(0)
		if OS.has_environment("ERA_PREVIEW_DIR") and DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(OS.get_environment("ERA_PREVIEW_DIR"))
			root.get_texture().get_image().save_png(OS.get_environment("ERA_PREVIEW_DIR").path_join("chronicle-%dx%d.png" % [dimensions.x, dimensions.y]))
		panel.get_ok_button().pressed.emit()
		await _settle()
		_check(not panel.visible, "Return to life failed")
	# Hydration and a same-year response must refresh the recap without a new year.
	shell.recap_check_at = 0
	await _settle()
	_check(shell.recap.text.contains("2040"), "Recap stayed stale after saved history arrived")
	_check(shell.recap.size.y >= 48, "Wrapped recap collapsed below readable height")
	host.gs.player.id = 106
	host.gs.player.first_name = "Sam"
	host.gs.player.parents = [101]
	shell.recap_check_at = 0
	await _settle()
	_check(shell.recap.text.contains("left:"), "Generation change did not show inherited recap")
	var literal := {"person":"[url=https://invalid.example]Alex[/url]", "entries":[], "truncated":false}
	panel.present(literal, Vector2(420, 900))
	_check(panel.body.get_parsed_text().contains("[url="), "Authored text was interpreted as BBCode")
	panel.hide()
	host.free()
	await _settle()
	print("FAMILY CHRONICLE TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
