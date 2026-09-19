extends Control

## Independent mobile menu. No GameState, gameplay classes or scene preloads.
## Choices hand off to existing MainScene routes after background loading.
const GAME_SCENE := "res://scenes/main.scn"
const Design = preload("res://ui/EraTheme.gd")

var status_label: Label
var progress_bar: ProgressBar
var started_at_ms := 0
var loading_center: CenterContainer
var loading_content: VBoxContainer
var action_buttons: Array[Button] = []
var cancel_button: Button
var pending_entry := ""
var packed_game: PackedScene
var load_started := false
var handoff_started := false
var auto_load_game := true

func _ready() -> void:
	set_process(false)
	MobileSupport.configure_viewport(self)
	get_tree().quit_on_go_back = false
	theme = Design.create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Design.CANVAS
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	loading_center = CenterContainer.new()
	add_child(loading_center)
	loading_content = VBoxContainer.new()
	loading_content.add_theme_constant_override("separation", 16)
	loading_center.add_child(loading_content)
	var title := Label.new()
	title.text = "ERA / LIFE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Design.DISPLAY)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Design.ACCENT)
	loading_content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A world of possibilities. A life of your own."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Design.MUTED)
	loading_content.add_child(subtitle)
	_add_action("New life", "new_life", true)
	_add_action("Saved life & account", "title")
	_add_action("Watch intro", "intro")
	status_label = Label.new()
	status_label.text = "Preparing your game…"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Design.MUTED)
	loading_content.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 6
	progress_bar.show_percentage = false
	loading_content.add_child(progress_bar)
	cancel_button = Button.new()
	cancel_button.text = "Back to menu"
	cancel_button.custom_minimum_size.y = 48
	cancel_button.visible = false
	cancel_button.pressed.connect(_cancel_entry)
	loading_content.add_child(cancel_button)
	resized.connect(_layout_loading)
	_layout_loading()
	StartupTiming.mark("boot_menu_ready")
	if auto_load_game:
		_begin_loading_after_paint()

func _add_action(label: String, entry: String, primary := false) -> void:
	var button := Button.new()
	button.text = label
	button.name = "Boot_" + entry
	button.custom_minimum_size.y = 56
	if primary:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, Design.button(state, true))
		for role in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(role, Design.CANVAS)
	button.pressed.connect(_choose_entry.bind(entry))
	loading_content.add_child(button)
	action_buttons.append(button)

func _begin_loading_after_paint() -> void:
	# Paint the interactive menu before competing with script loading.
	for frame in range(3):
		await RenderingServer.frame_post_draw
	StartupTiming.mark("boot_menu_first_frame")
	_start_loading()

func _start_loading() -> void:
	if load_started:
		return
	load_started = true
	started_at_ms = Time.get_ticks_msec()
	StartupTiming.mark("game_resource_request")
	var error := ResourceLoader.load_threaded_request(GAME_SCENE, "PackedScene", false)
	if error != OK:
		_show_error("Could not start loading (%s). Please restart the app." % error_string(error))
		return
	set_process(true)

func _choose_entry(entry: String) -> void:
	if handoff_started or entry not in ["new_life", "title", "intro"]:
		return
	pending_entry = entry
	for button in action_buttons:
		button.disabled = true
	cancel_button.visible = true
	status_label.text = "Finishing preparations…"
	if packed_game != null:
		_open_game()

func _cancel_entry() -> void:
	if handoff_started:
		return
	pending_entry = ""
	cancel_button.visible = false
	for button in action_buttons:
		button.disabled = false
	status_label.text = "Ready when you are." if packed_game != null else "Preparing your game…"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not pending_entry.is_empty():
		_cancel_entry()

func _layout_loading() -> void:
	if loading_center == null:
		return
	loading_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe := MobileSupport.safe_viewport_rect(self)
	var viewport := get_viewport_rect()
	loading_center.offset_left = safe.position.x + 24
	loading_center.offset_top = safe.position.y + 24
	loading_center.offset_right = safe.end.x - viewport.size.x - 24
	loading_center.offset_bottom = safe.end.y - viewport.size.y - 24
	loading_content.custom_minimum_size.x = maxf(1.0, safe.size.x - 48)

func _process(_delta: float) -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	if not progress.is_empty():
		progress_bar.value = float(progress[0]) * 100.0
	var seconds := (Time.get_ticks_msec() - started_at_ms) / 1000
	status_label.text = "%s %d s" % ["Preparing your game…" if pending_entry.is_empty() else "Finishing preparations…", seconds]
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		packed_game = ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
		if packed_game == null:
			_show_error("The game scene could not be loaded. Please restart the app.")
			return
		StartupTiming.mark("game_resource_loaded", {"load_ms": Time.get_ticks_msec() - started_at_ms})
		progress_bar.value = 100
		status_label.text = "Ready when you are."
		if not pending_entry.is_empty():
			_open_game()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_show_error("The game could not be loaded. Please restart the app.")

func _show_error(message: String) -> void:
	set_process(false)
	status_label.text = message
	pending_entry = ""
	cancel_button.visible = false
	for button in action_buttons:
		button.disabled = true

func _open_game() -> void:
	if handoff_started or packed_game == null:
		return
	handoff_started = true
	cancel_button.visible = false
	status_label.text = "Opening EraLife…"
	# Let the status paint before synchronous scene instantiation/_ready.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	else:
		await get_tree().process_frame
	var before := Time.get_ticks_msec()
	var game := packed_game.instantiate()
	if game == null:
		handoff_started = false
		_show_error("Could not open the game. Please restart the app.")
		return
	StartupTiming.mark("game_scene_instantiated", {"instantiate_ms": Time.get_ticks_msec() - before})
	game.set_meta("mobile_boot_entry", pending_entry)
	var tree := get_tree()
	tree.root.add_child(game)
	tree.current_scene = game
	hide()
	queue_free()
