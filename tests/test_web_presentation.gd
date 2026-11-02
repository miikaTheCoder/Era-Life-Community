extends SceneTree
## Regression: high-DPI browser layouts remain readable and forms scroll vertically.
const Shell = preload("res://ui/EraShell.gd")
const Interface = preload("res://ui/EraInterface.gd")
var failed := false

class Host extends Control:
	var gs = null
	var startup_intro_title_label: Label
	var choose_adventure_entry_overlay: Control
	var choose_adventure_entry_shell: Container

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func _settle() -> void:
	for frame in range(4):
		await process_frame

func _capture(viewer: Control, dimensions: Vector2i) -> void:
	var directory := OS.get_environment("ERA_PREVIEW_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	viewer.hide()
	await _settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join("web-menu-%dx%d.png" % [dimensions.x, dimensions.y]))
	viewer.show()
	await _settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join("web-creator-%dx%d.png" % [dimensions.x, dimensions.y]))

func _run() -> void:
	_check(WebSupport.is_enabled(), "Run with -- --web-preview")
	# Equal CSS sizes must have equal layouts regardless of the backing buffer.
	for css in [Vector2(360, 640), Vector2(393, 700), Vector2(844, 390), Vector2(1440, 900)]:
		for dpr in [1.0, 2.75, 3.0]:
			var contract := UIContractEngine.resolve_presentation_density_bootstrap_contract({
				"physical_viewport_width": css.x * dpr,
				"physical_viewport_height": css.y * dpr,
				"web_css_viewport_width": css.x,
				"web_css_viewport_height": css.y,
				"desktop_presentation": true,
			})
			var logical: Dictionary = contract.logical_viewport
			_check(is_equal_approx(float(logical.width), css.x) and is_equal_approx(float(logical.height), css.y),
				"Browser DPR changed logical layout at %s / %s" % [css, dpr])
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	# A tiling compositor may override the requested native window dimensions.
	# Keep the layout's aspect ratio intact when capturing graphical evidence.
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var adapter := Interface.new()
	host.add_child(adapter)
	host.choose_adventure_entry_overlay = Control.new()
	host.add_child(host.choose_adventure_entry_overlay)
	host.choose_adventure_entry_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Shell.mount_menu(host)
	for role in ["narrative_alive", "household_alive", "god_mode_alive"]:
		host.choose_adventure_entry_shell.add_child(Shell.create_entry_card({"id": role, "button_role": role, "button_text": "Begin"}))
	var viewer := GodModeViewer.new()
	host.add_child(viewer)
	viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewer._build()
	for dimensions in [Vector2i(360, 640), Vector2i(420, 900), Vector2i(844, 390), Vector2i(1440, 900)]:
		if DisplayServer.get_name() != "headless":
			root.size = dimensions
		root.content_scale_size = dimensions
		await _settle()
		Shell.layout_menu(host)
		viewer._layout_web_form()
		await _settle()
		var narrow: bool = dimensions.x < 960
		_check(host.choose_adventure_entry_shell.columns == (1 if narrow else 3), "Browser menu kept desktop columns")
		for card in host.choose_adventure_entry_shell.get_children():
			_check(card.get_global_rect().end.x <= dimensions.x + 1, "Browser card overflowed the viewport")
		_check(viewer.panel.get_global_rect().end.x <= dimensions.x + 1, "Creator panel overflowed the viewport")
		_check(viewer.first_name_edit.get_global_rect().end.x <= dimensions.x + 1, "Creator field overflowed the viewport")
		_check(viewer.first_name_edit.get_parent().vertical == narrow, "Creator label and field did not reflow")
		if narrow:
			_check(viewer.first_name_edit.size.y >= 48 and viewer.first_name_edit.get_theme_font_size("font_size") >= 16,
				"Browser text field is too small")
			_check(viewer.scroll.get_v_scroll_bar().max_value > viewer.scroll.get_v_scroll_bar().page, "Long creator form is not scrollable")
			_check(viewer.prewarm_button.get_global_rect().end.y <= dimensions.y + 1, "Prepare world is below the viewport")
		await _capture(viewer, dimensions)
	# Resizing must keep the entered settings and control identities.
	viewer.first_name_edit.text = "Web Test"
	root.content_scale_size = Vector2i(360, 640)
	await _settle()
	_check(viewer.first_name_edit.text == "Web Test", "Reflow erased an entered name")
	host.queue_free()
	await process_frame
	print("WEB PRESENTATION TEST: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
