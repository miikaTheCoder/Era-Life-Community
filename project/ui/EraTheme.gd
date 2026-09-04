extends RefCounted
## Shared, permanent dark presentation. No simulation state belongs here.

const CANVAS := Color("101211")
const PANEL := Color("191c1a")
const RAISED := Color("242925")
const LINE := Color("3c443e")
const TEXT := Color("eeeee7")
const MUTED := Color("acb5ac")
const ACCENT := Color("b2c9a2")
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
	var fill := RAISED
	var border := LINE
	if primary:
		fill = ACCENT
		border = ACCENT
	elif selected:
		fill = Color("2e3b30")
		border = ACCENT
	match state:
		"hover", "hover_pressed":
			fill = Color("c6d9b8") if primary else Color("333c34")
			border = ACCENT
		"pressed":
			fill = Color("9ab38a") if primary else Color("3a493c")
			border = ACCENT
		"disabled":
			fill = PANEL
			border = LINE
		"focus":
			var focus := box(Color.TRANSPARENT, AMBER)
			focus.set_border_width_all(2)
			focus.draw_center = false
			return focus
	var style := box(fill, border)
	if selected:
		style.border_width_bottom = 3
	return style

static func create() -> Theme:
	var result := Theme.new()
	result.default_font = BODY
	result.default_font_size = 16
	for type in ["Button", "OptionButton", "MenuButton", "CheckButton", "CheckBox"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			result.set_stylebox(state, type, button(state))
		for role in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			result.set_color(role, type, TEXT)
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
		result.set_color("selection_color", type, Color("415440"))
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
