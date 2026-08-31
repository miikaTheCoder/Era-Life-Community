extends Control

## Keep Android responsive while the reconstructed game's large script loads.
## No game state is created here; MainScene keeps ownership of initialization.
const GAME_SCENE := "res://scenes/main.scn"

var status_label: Label
var progress_bar: ProgressBar
var started_at_ms := 0

func _ready() -> void:
	set_process(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.025, 0.05, 0.06)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 720
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var title := Label.new()
	title.text = "ERA LIFE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)
	status_label = Label.new()
	status_label.text = "Preparing your game…"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	box.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 24
	progress_bar.show_percentage = false
	box.add_child(progress_bar)
	var hint := Label.new()
	hint.text = "Loading the world scripts can take about a minute.\nPlease keep the app open."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	box.add_child(hint)
	started_at_ms = Time.get_ticks_msec()
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(GAME_SCENE, "PackedScene", false)
	if error != OK:
		status_label.text = "Could not start loading (%s). Please restart the app." % error_string(error)
		return
	set_process(true)

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
		await get_tree().process_frame
		var error := get_tree().change_scene_to_packed(packed)
		if error != OK:
			status_label.text = "Could not open the game (%s)." % error_string(error)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		set_process(false)
		status_label.text = "The game could not be loaded. Please restart the app."
