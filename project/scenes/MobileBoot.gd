extends Control

## Keep Android responsive while the reconstructed game's large script loads.
## No game state is created here; MainScene keeps ownership of initialization.
const GAME_SCENE := "res://scenes/main.scn"
const Design = preload("res://ui/EraTheme.gd")

var status_label: Label
var progress_bar: ProgressBar
var started_at_ms := 0
var loading_center: CenterContainer
var loading_content: VBoxContainer

func _ready() -> void:
	print("MOBILE_BOOT: loading screen ready at ", Time.get_ticks_msec())
	set_process(false)
	MobileSupport.configure_viewport(self)
	theme = Design.create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Design.CANVAS
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	loading_center = CenterContainer.new()
	add_child(loading_center)
	loading_content = VBoxContainer.new()
	loading_content.add_theme_constant_override("separation", 20)
	loading_center.add_child(loading_content)
	var title := Label.new()
	title.text = "ERA / LIFE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Design.DISPLAY)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Design.ACCENT)
	loading_content.add_child(title)
	status_label = Label.new()
	status_label.text = "Preparing your game…"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	loading_content.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 8
	progress_bar.show_percentage = false
	loading_content.add_child(progress_bar)
	var hint := Label.new()
	hint.text = "Your world is getting ready. The first launch can take about a minute."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Design.MUTED)
	loading_content.add_child(hint)
	resized.connect(_layout_loading)
	_layout_loading()
	started_at_ms = Time.get_ticks_msec()
	# Allow container layout, font uploads, and the Android swap chain to settle
	# before background resource loading can occupy the renderer.
	for frame in range(3):
		await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.2).timeout
	print("MOBILE_BOOT: first loading frame drawn at ", Time.get_ticks_msec(), " viewport=", get_viewport_rect(), " content=", loading_content.get_global_rect())
	var error := ResourceLoader.load_threaded_request(GAME_SCENE, "PackedScene", false)
	if error != OK:
		status_label.text = "Could not start loading (%s). Please restart the app." % error_string(error)
		return
	set_process(true)

func _layout_loading() -> void:
	if loading_center == null:
		return
	# Anchors follow the viewport while Android settles its initial surface size.
	# Absolute container geometry can retain the earlier physical-height layout.
	loading_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_center.offset_left = 24
	loading_center.offset_top = 24
	loading_center.offset_right = -24
	loading_center.offset_bottom = -24
	loading_content.custom_minimum_size.x = maxf(1.0, get_viewport_rect().size.x - 48)



func _process(_delta: float) -> void:
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	if not progress.is_empty():
		progress_bar.value = float(progress[0]) * 100.0
	status_label.text = "Preparing your game… %d seconds" % ((Time.get_ticks_msec() - started_at_ms) / 1000)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		var packed := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
		if packed == null:
			status_label.text = "The game scene could not be loaded. Please restart the app."
			return
		status_label.text = "Opening Era Life…"
		progress_bar.value = 100
		await RenderingServer.frame_post_draw
		print("MOBILE_BOOT: opening game at ", Time.get_ticks_msec())
		var error := get_tree().change_scene_to_packed(packed)
		if error != OK:
			status_label.text = "Could not open the game (%s)." % error_string(error)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		set_process(false)
		status_label.text = "The game could not be loaded. Please restart the app."
