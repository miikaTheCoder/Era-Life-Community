extends Node
## Presentation adapter for the reconstructed scene and its dynamic contract panels.
## Controls keep their signals, values, visibility authority, and gameplay ownership.
const Design = preload("res://ui/EraTheme.gd")
const Shell = preload("res://ui/EraShell.gd")
const MobileShell = preload("res://ui/EraMobileShell.gd")
const MobilePanels = preload("res://ui/EraMobilePanels.gd")
var host: Control
var design_theme: Theme
var pending: Dictionary = {}
var applying := false
var shell: Node

func _ready() -> void:
	host = get_parent() as Control
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000
	design_theme = Design.create()
	host.theme = design_theme
	RenderingServer.set_default_clear_color(Design.CANVAS)
	get_tree().node_added.connect(_observe)
	_observe_tree(host)
	shell = MobileShell.new() if MobileSupport.is_enabled() else Shell.new()
	shell.name = "EraShell"
	host.add_child.call_deferred(shell)
	if MobileSupport.is_enabled():
		var panels := MobilePanels.new()
		panels.name = "EraMobilePanels"
		host.add_child.call_deferred(panels)

func _observe_tree(node: Node) -> void:
	_observe(node)
	for child in node.get_children():
		_observe_tree(child)

func _observe(node: Node) -> void:
	if node is Window and host.is_ancestor_of(node):
		node.theme = design_theme
		return
	if not node is Control or not host.is_ancestor_of(node) and node != host:
		return
	var id := node.get_instance_id()
	if not node.has_meta("era_theme_observed"):
		node.set_meta("era_theme_observed", true)
		node.theme_changed.connect(_queue.bind(id))
		node.visibility_changed.connect(_queue.bind(id))
		if node is ProgressBar:
			node.value_changed.connect(func(_value: float): _queue(id))
	_queue(id)

func _queue(id: int) -> void:
	if not applying:
		pending[id] = true

func _process(_delta: float) -> void:
	var work := pending.keys()
	pending.clear()
	applying = true
	for id in work:
		var control := instance_from_id(id) as Control
		if is_instance_valid(control) and not control.is_queued_for_deletion():
			_style(control)
	applying = false

func style_tool_button(button: Button, text: String) -> void:
	var id := button.get_instance_id()
	var changed: bool = button.get_meta("era_tool_label", "") != text
	var font_size := 15 if MobileSupport.is_enabled() else 13
	button.set_meta("era_tool_label", text)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Flush a legacy theme replacement before the shell assigns its rectangle.
	# Waiting for the next adapter frame lets the old padding/font enlarge it.
	if changed or pending.has(id) or button.get_theme_font_size("font_size") != font_size:
		var was_applying := applying
		applying = true
		_style(button)
		applying = was_applying
		pending.erase(id)
	button.text = text

func _style(control: Control) -> void:
	if control.has_meta("era_owned"):
		return
	control.begin_bulk_theme_override()
	# Legacy panels install their own fonts and animated neon overrides after ready.
	# Normalize only presentation; never rebuild rows or change simulation contracts.
	if control.theme != null and control != host:
		control.theme = design_theme
	if control is Label or control is BaseButton or control is LineEdit:
		var text_color := Design.TEXT
		if control is BaseButton:
			text_color = Design.BUTTON_TEXT
		if control is Label:
			var original := control.get_theme_color("font_color")
			if original == Design.DANGER or (original.r > 0.7 and original.g < 0.4 and original.b < 0.5):
				text_color = Design.DANGER
			elif original == Design.AMBER or (original.r > 0.7 and original.g > 0.55 and original.b < 0.35):
				text_color = Design.AMBER
		control.add_theme_font_override("font", Design.BOLD if control is BaseButton else Design.BODY)
		var font_size := clampi(control.get_theme_font_size("font_size"), 13, 28)
		if control.has_meta("era_tool_label"):
			font_size = 15 if MobileSupport.is_enabled() else 13
		if control.get_meta("era_mobile_nav", false):
			font_size = 12
		control.add_theme_font_size_override("font_size", font_size)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			control.add_theme_color_override(key, text_color)
		control.add_theme_color_override("font_disabled_color", Design.MUTED)
	if control is Label or control is RichTextLabel or control is BaseButton:
		for key in ["font_shadow_color", "font_outline_color"]:
			control.add_theme_color_override(key, Color.TRANSPARENT)
		for key in ["outline_size", "shadow_outline_size", "shadow_offset_x", "shadow_offset_y"]:
			control.add_theme_constant_override(key, 0)
	if control is RichTextLabel:
		control.add_theme_font_override("normal_font", Design.BODY)
		control.add_theme_font_override("bold_font", Design.BOLD)
		control.add_theme_color_override("default_color", Design.TEXT)
		control.add_theme_font_size_override("normal_font_size", 15 if MobileSupport.is_enabled() else 16)
		control.add_theme_font_size_override("bold_font_size", 15 if MobileSupport.is_enabled() else 16)
		control.add_theme_constant_override("line_separation", 7)
	if control is Button:
		_style_button(control)
		if control is OptionButton:
			control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, 120)
	elif control is Panel or control is PanelContainer:
		_style_panel(control)
	elif control is LineEdit or control is TextEdit:
		for key in ["normal", "read_only", "focus"]:
			control.add_theme_stylebox_override(key, design_theme.get_stylebox(key, control.get_class()))
	elif control is ScrollBar:
		for key in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			control.add_theme_stylebox_override(key, design_theme.get_stylebox(key, control.get_class()))
	elif control is Slider:
		for key in ["slider", "grabber_area", "grabber_area_highlight"]:
			control.add_theme_stylebox_override(key, design_theme.get_stylebox(key, control.get_class()))
	elif control is ProgressBar:
		_style_progress(control)
	if control is ScrollContainer:
		control.follow_focus = true
	if control is Label and control.name == "FlavorLabel":
		control.add_theme_color_override("font_color", Design.MUTED)
		control.add_theme_font_size_override("font_size", 13)
	if control is Label and control.get_parent().has_meta("stat_title"):
		control.add_theme_color_override("font_color", Design.MUTED if control.name == "FlavorLabel" else Design.TEXT)
		control.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		control.add_theme_font_size_override("font_size", 14)
		control.scale = Vector2.ONE
	if control == host.get("startup_intro_title_label"):
		control.add_theme_font_override("font", Design.DISPLAY)
		control.add_theme_font_size_override("font_size", 42 if MobileSupport.is_enabled() else 80)
		control.add_theme_color_override("font_color", Design.ACCENT)
		control.material = null
	if control is Label and control.name == "ValueLabel":
		control.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control.offset_right = -6
		control.add_theme_font_size_override("font_size", 13)
	if control is Label and control.name == "GodModePrewarmButtonLabel":
		control.add_theme_color_override("font_color", Design.MUTED if control.get_parent().disabled else Design.CANVAS)
	if control is ColorRect:
		var key := str(control.name).to_lower()
		if "background" in key or "dim" in key:
			control.color = Color(Design.CANVAS, control.color.a)
		if "sheen" in key or "glow" in key or "lightsweep" in key:
			control.self_modulate.a = 0.0
	control.end_bulk_theme_override()

func _style_button(button: Button) -> void:
	var key := str(button.get_meta("ui_nav_key", ""))
	var primary := bool(button.get_meta("era_primary", false)) or key == "age_up" or str(button.get_meta("entry_role", "")) == "narrative_alive"
	var selected := (not key.is_empty() and key == str(host.get("current_panel"))) or bool(button.get_meta("era_selected", false)) or button.button_pressed
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var old := button.get_theme_stylebox(state)
		var compact := bool(button.get_meta("era_mobile_nav", false))
		var signature := "%s:%s:%s:%s" % [state, primary, selected, compact]
		if old.get_meta("era_button", "") != signature:
			var style := Design.button(state, primary, selected)
			if compact:
				style.content_margin_left = 4
				style.content_margin_right = 4
			style.set_meta("era_button", signature)
			button.add_theme_stylebox_override(state, style)
	if primary:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, Design.CANVAS)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if button.tooltip_text.is_empty():
		var names := {"×": "Close", "X": "Close", "↑": "Scroll up", "↓": "Scroll down"}
		button.tooltip_text = names.get(button.text, "")
	if not key.is_empty():
		button.add_theme_font_size_override("font_size", 12 if button.get_meta("era_mobile_nav", false) else 15)
		button.scale = Vector2.ONE
		button.rotation = 0.0

func _style_panel(control: Control) -> void:
	var old := control.get_theme_stylebox("panel") as StyleBoxFlat
	# Fill lenses are metric bars rather than panel chrome.
	var fill_lens := "fill" in str(control.name).to_lower() and control.get_parent() is ProgressBar
	var color := _metric_color(control.get_parent()) if fill_lens else Design.PANEL
	if old != null and old.get_meta("era_panel", Color.TRANSPARENT) == color:
		return
	var style := old.duplicate() as StyleBoxFlat if old != null else Design.box(Design.PANEL)
	style.bg_color = color
	style.border_color = Design.LINE
	style.shadow_size = 0
	style.shadow_color = Color.TRANSPARENT
	style.set_border_width_all(0 if fill_lens else 1)
	style.set_corner_radius_all(3 if fill_lens else 6)
	style.set_meta("era_panel", color)
	control.add_theme_stylebox_override("panel", style)

func _style_progress(bar: ProgressBar) -> void:
	for key in ["background", "fill"]:
		var old := bar.get_theme_stylebox(key)
		var color := Design.RAISED if key == "background" else _metric_color(bar)
		if old.get_meta("era_progress", Color.TRANSPARENT) == color:
			continue
		var style := Design.box(color, color, 3, 0)
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		style.set_meta("era_progress", color)
		bar.add_theme_stylebox_override(key, style)
	for child in bar.get_children():
		if child is PanelContainer:
			_style_panel(child)

func _metric_color(bar: ProgressBar) -> Color:
	if str(bar.get_meta("stat_title", "")).to_lower() == "health" and bar.value < 30:
		return Color("804b46")
	return Design.METRIC
