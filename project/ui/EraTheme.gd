extends RefCounted
## Shared, permanent dark presentation. No simulation state belongs here.

const CANVAS := Color("101214")
const PANEL := Color("191d20")
const RAISED := Color("242b30")
const LINE := Color("38454d")
const TEXT := Color("edf5fa")
const MUTED := Color("a8bac5")
const ACCENT := Color("66dbff")
const BUTTON := Color("102c39")
const BUTTON_EDGE := Color("368baa")
const BUTTON_TEXT := Color("bceeff")
const FOCUS := Color("d4f5ff")
const METRIC := Color("285a70")
const AMBER := Color("ddbd83")
const DANGER := Color("e99e96")
const BODY = preload("res://ui/fonts/LiberationSans-Regular.ttf")
const BOLD = preload("res://ui/fonts/LiberationSans-Bold.ttf")
const DISPLAY = preload("res://ui/fonts/LiberationSerif-Regular.ttf")

static func box(fill: Color, border: Color = LINE, radius: int = 6, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func button(state: String, primary := false, selected := false) -> StyleBoxFlat:
	var fill := BUTTON
	var border := BUTTON_EDGE
	var glow_strength := 0.12
	var glow_size := 5
	if primary:
		fill = ACCENT
		border = ACCENT
		glow_strength = 0.24
		glow_size = 10
	elif selected:
		fill = Color("174558")
		border = ACCENT
		glow_strength = 0.22
		glow_size = 8
	match state:
		"hover", "hover_pressed":
			fill = Color("a5edff") if primary else Color("1c4b60")
			border = ACCENT
			glow_strength = 0.36
			glow_size = 12
		"pressed":
			fill = Color("38b9e6") if primary else Color("0d3547")
			border = ACCENT
			glow_strength = 0.18
			glow_size = 4
		"disabled":
			fill = PANEL
			border = LINE
			glow_strength = 0.0
			glow_size = 0
		"focus":
			var focus := box(Color.TRANSPARENT, FOCUS)
			focus.set_border_width_all(2)
			focus.draw_center = false
			focus.set_expand_margin_all(2)
			return focus
	var style := box(fill, border)
	style.shadow_color = Color(ACCENT, glow_strength)
	style.shadow_size = glow_size
	if selected:
		style.border_width_bottom = 3
	return style

static func create() -> Theme:
	var result := Theme.new()
	result.default_font = BODY
	result.default_font_size = 16
	for type in ["Button", "OptionButton", "MenuButton", "CheckButton", "CheckBox"]:
		result.set_font("font", type, BOLD)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			result.set_stylebox(state, type, button(state))
		for role in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			result.set_color(role, type, BUTTON_TEXT)
		result.set_color("font_disabled_color", type, MUTED)
		result.set_color("font_outline_color", type, Color.TRANSPARENT)
		result.set_constant("outline_size", type, 0)
	for type in ["Panel", "PanelContainer", "PopupPanel", "PopupMenu", "AcceptDialog", "Window", "TooltipPanel"]:
		result.set_stylebox("panel", type, box(PANEL))
	for type in ["LineEdit", "TextEdit", "CodeEdit", "ItemList", "Tree"]:
		result.set_stylebox("normal", type, box(CANVAS))
		result.set_stylebox("read_only", type, box(PANEL))
		result.set_stylebox("focus", type, button("focus"))
		result.set_color("font_color", type, TEXT)
		result.set_color("font_placeholder_color", type, MUTED)
		result.set_color("caret_color", type, ACCENT)
		result.set_color("selection_color", type, Color("164659"))
	for type in ["Label", "RichTextLabel", "TooltipLabel", "PopupMenu", "TabBar", "TabContainer"]:
		result.set_color("font_color", type, TEXT)
		result.set_color("default_color", type, TEXT)
		result.set_color("font_shadow_color", type, Color.TRANSPARENT)
		result.set_color("font_outline_color", type, Color.TRANSPARENT)
		result.set_constant("outline_size", type, 0)
		result.set_constant("shadow_outline_size", type, 0)
	result.set_font("bold_font", "RichTextLabel", BOLD)
	result.set_constant("line_separation", "RichTextLabel", 8)
	result.set_stylebox("panel", "TabContainer", box(PANEL))
	for type in ["TabBar", "TabContainer"]:
		result.set_stylebox("tab_selected", type, button("normal", false, true))
		result.set_stylebox("tab_unselected", type, button("normal"))
		result.set_stylebox("tab_hovered", type, button("hover"))
	result.set_stylebox("hover", "PopupMenu", button("hover"))
	result.set_stylebox("background", "ProgressBar", box(RAISED, RAISED, 3, 0))
	result.set_stylebox("fill", "ProgressBar", box(ACCENT, ACCENT, 3, 0))
	for type in ["VScrollBar", "HScrollBar"]:
		result.set_stylebox("scroll", type, box(CANVAS, CANVAS, 3, 3))
		result.set_stylebox("grabber", type, box(LINE, LINE, 3, 3))
		result.set_stylebox("grabber_highlight", type, box(MUTED, MUTED, 3, 3))
		result.set_stylebox("grabber_pressed", type, box(ACCENT, ACCENT, 3, 3))
	for type in ["HSlider", "VSlider"]:
		result.set_stylebox("slider", type, box(RAISED, LINE, 3, 3))
		result.set_stylebox("grabber_area", type, box(ACCENT, ACCENT, 3, 3))
		result.set_stylebox("grabber_area_highlight", type, box(ACCENT, ACCENT, 3, 3))
	for type in ["VBoxContainer", "HBoxContainer"]:
		result.set_constant("separation", type, 10)
	return result
