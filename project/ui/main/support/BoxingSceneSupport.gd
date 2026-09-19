extends RefCounted
class_name BoxingSceneSupport
## Boxing support for the main scene. State, when needed, is passed explicitly.


static func _boxing_hub_rankings_division_carousel_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.07, 0.72)
	style.border_color = Color(1.0, 0.68, 0.34, 0.74)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = visual_contract.get("shadow_accent", Color(1.0, 0.32, 0.08, 0.2))
	style.shadow_size = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


static func _boxing_entry_weight_classes() -> Array:
	return [
		"Flyweight",
		"Bantamweight",
		"Featherweight",
		"Lightweight",
		"Welterweight",
		"Middleweight",
		"Light Heavyweight",
		"Heavyweight"
	]


static func _boxing_entry_gender_division_for_actor(actor: Person) -> String:
	if actor == null:
		return "Male"

	var gender_text: String = str(actor.gender if "gender" in actor else "").strip_edges().to_lower()
	if gender_text in ["female", "woman", "girl", "f"]:
		return "Female"

	return "Male"


static func _boxing_entry_popup_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.038, 0.026, 0.97)
	style.border_color = Color(1.0, 0.67, 0.32, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.shadow_color = Color(1.0, 0.44, 0.12, 0.34)
	style.shadow_size = 18
	style.content_margin_left = 24
	style.content_margin_top = 22
	style.content_margin_right = 24
	style.content_margin_bottom = 22
	return style


static func _boxing_entry_button_style(accent: Color = Color(1.0, 0.58, 0.22, 1.0)) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.2, accent.g * 0.16, accent.b * 0.1, 0.92)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.86)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(accent.r, accent.g * 0.7, accent.b * 0.45, 0.2)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


static func _boxing_title_body_from_label(title_label: String) -> String:
	var clean_label: String = str(title_label).strip_edges().to_upper()

	if clean_label.find("WBC") >= 0:
		return "WBC"
	if clean_label.find("WBA") >= 0:
		return "WBA"
	if clean_label.find("IBF") >= 0:
		return "IBF"
	if clean_label.find("WBO") >= 0:
		return "WBO"
	if clean_label.find("RING") >= 0 or clean_label.find("LINEAL") >= 0:
		return "RING"

	return ""


static func _boxing_belt_visual_contract_for_body(body: String) -> Dictionary:
	var clean_body: String = str(body).strip_edges().to_upper()

	match clean_body:
		"WBC":
			return {
				"body": "WBC",
				"short": "WBC",
				"emoji": "🟢",
				"aura_tag": "green_glory",
				"bg": Color(0.015, 0.13, 0.06, 0.96),
				"core": Color(0.18, 1.0, 0.42, 1.0),
				"border": Color(0.25, 1.0, 0.52, 0.96),
				"glow_primary": Color(0.13, 1.0, 0.42, 0.62),
				"glow_secondary": Color(0.54, 1.0, 0.72, 0.28),
				"text": Color(0.86, 1.0, 0.9, 1.0)
			}
		"WBA":
			return {
				"body": "WBA",
				"short": "WBA",
				"emoji": "🔴",
				"aura_tag": "maroon_bloodline",
				"bg": Color(0.145, 0.018, 0.04, 0.96),
				"core": Color(0.76, 0.06, 0.16, 1.0),
				"border": Color(0.98, 0.22, 0.3, 0.92),
				"glow_primary": Color(0.98, 0.09, 0.18, 0.52),
				"glow_secondary": Color(0.52, 0.02, 0.08, 0.38),
				"text": Color(1.0, 0.88, 0.9, 1.0)
			}
		"IBF":
			return {
				"body": "IBF",
				"short": "IBF",
				"emoji": "🟡",
				"aura_tag": "gold_standard",
				"bg": Color(0.19, 0.125, 0.02, 0.96),
				"core": Color(1.0, 0.82, 0.24, 1.0),
				"border": Color(1.0, 0.9, 0.42, 0.94),
				"glow_primary": Color(1.0, 0.78, 0.22, 0.56),
				"glow_secondary": Color(1.0, 0.96, 0.56, 0.28),
				"text": Color(1.0, 0.96, 0.76, 1.0)
			}
		"WBO":
			return {
				"body": "WBO",
				"short": "WBO",
				"emoji": "⚫",
				"aura_tag": "black_gold_red_crown",
				"bg": Color(0.01, 0.01, 0.014, 0.98),
				"core": Color(0.02, 0.018, 0.018, 1.0),
				"border": Color(1.0, 0.76, 0.2, 0.92),
				"glow_primary": Color(1.0, 0.72, 0.16, 0.5),
				"glow_secondary": Color(1.0, 0.1, 0.08, 0.45),
				"text": Color(1.0, 0.89, 0.58, 1.0)
			}
		"RING":
			return {
				"body": "RING",
				"short": "Ring",
				"emoji": "💍",
				"aura_tag": "lineal_silver",
				"bg": Color(0.06, 0.07, 0.09, 0.96),
				"core": Color(0.79, 0.88, 1.0, 1.0),
				"border": Color(0.86, 0.93, 1.0, 0.88),
				"glow_primary": Color(0.58, 0.74, 1.0, 0.42),
				"glow_secondary": Color(1.0, 1.0, 1.0, 0.18),
				"text": Color(0.92, 0.96, 1.0, 1.0)
			}
		_:
			return {
				"body": clean_body,
				"short": clean_body,
				"emoji": "🏆",
				"aura_tag": "generic_title",
				"bg": Color(0.105, 0.075, 0.025, 0.94),
				"core": Color(1.0, 0.76, 0.24, 1.0),
				"border": Color(1.0, 0.86, 0.4, 0.84),
				"glow_primary": Color(1.0, 0.76, 0.24, 0.34),
				"glow_secondary": Color(1.0, 0.94, 0.62, 0.18),
				"text": Color(1.0, 0.94, 0.76, 1.0)
			}


static func _boxing_blend_color_list(colors: Array, fallback: Color) -> Color:
	if colors.is_empty():
		return fallback

	var r: float = 0.0
	var g: float = 0.0
	var b: float = 0.0
	var a: float = 0.0

	for raw_color in colors:
		if typeof(raw_color) != TYPE_COLOR:
			continue

		var color: Color = raw_color
		r += color.r
		g += color.g
		b += color.b
		a += color.a

	var count: float = float(max(1, colors.size()))
	return Color(r / count, g / count, b / count, clamp(a / count, 0.0, 1.0))


static func _boxing_belt_chip_style(visual: Dictionary, secondary_layer: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.content_margin_left = 7
	style.content_margin_top = 3
	style.content_margin_right = 7
	style.content_margin_bottom = 3
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	style.bg_color = visual.get("bg", Color(0.105, 0.075, 0.025, 0.94))
	style.border_color = visual.get("border", Color(1.0, 0.86, 0.4, 0.84))
	style.shadow_color = visual.get("glow_secondary", visual.get("glow_primary", Color(1.0, 0.76, 0.24, 0.22))) if secondary_layer else visual.get("glow_primary", Color(1.0, 0.76, 0.24, 0.28))
	style.shadow_size = 8 if secondary_layer else 5

	return style


static func _boxing_hub_fame_fill_color(fame_value: float, is_champion: bool, rank_heat: float) -> Color:
	var clean_fame: float = clamp(fame_value, 0.0, 100.0)

	if clean_fame < 30.0:
		return Color(1.0, 0.16, 0.12, 0.92)

	if is_champion or clean_fame >= 70.0:
		return Color(1.0, 0.86, 0.22, 0.96)

	return Color(1.0, 0.68 + rank_heat * 0.12, 0.24, 0.88)


static func _boxing_hub_athleticism_panel_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(base.r, base.g, base.b, 0.46)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func _boxing_hub_athleticism_bar_background_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(panel.r, panel.g, panel.b, 0.7)
	sb.border_color = Color(1.0, 1.0, 1.0, 0.1)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	return sb


static func _boxing_hub_athleticism_bar_fill_style(visual_contract: Dictionary, value: int) -> StyleBoxFlat:
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))
	var clean_value: int = clamp(value, 0, 100)

	var fill_color: Color = Color(accent.r, accent.g, accent.b, 0.82)
	if clean_value >= 80:
		fill_color = Color(hot.r, hot.g, hot.b, 0.92)
	elif clean_value <= 35:
		fill_color = Color(1.0, 0.22, 0.12, 0.82)

	var sb:= StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = Color(1.0, 1.0, 1.0, 0.18)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.28)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2.ZERO
	return sb


static func _boxing_hub_athleticism_value_color(value: int, visual_contract: Dictionary) -> Color:
	var clean_value: int = clamp(value, 0, 100)

	if clean_value >= 80:
		return visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	if clean_value <= 35:
		return Color(1.0, 0.22, 0.12, 1.0)

	return visual_contract.get("body_text", Color(0.96, 0.97, 1.0, 0.94))


static func _boxing_hub_growth_box_gap() -> float:
	return 2.0


static func _boxing_hub_growth_skill_label_width() -> float:
	return 250.0


static func _boxing_hub_growth_cost_column_width() -> float:
	return 82.0


static func _boxing_hub_growth_header_label(text: String, min_width: float, visual_contract: Dictionary, expand: bool = false) -> Label:
	var label:= Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", visual_contract.get("title", Color(1.0, 0.9, 0.66, 1.0)))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		label.custom_minimum_size = Vector2(min_width, 24)

	if text == "XP COST":
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	elif expand:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	return label


static func _boxing_hub_apply_growth_invisible_scroll(scroll: ScrollContainer) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbar:= scroll.get_v_scroll_bar()
	if vbar == null:
		return

	vbar.step = 1.0
	vbar.custom_minimum_size = Vector2(0, 0)
	vbar.modulate = Color(1.0, 1.0, 1.0, 0.0)
	vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var transparent:= StyleBoxFlat.new()
	transparent.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	transparent.border_color = Color(0.0, 0.0, 0.0, 0.0)
	transparent.set_border_width_all(0)
	transparent.shadow_size = 0

	vbar.add_theme_stylebox_override("scroll", transparent)
	vbar.add_theme_stylebox_override("scroll_focus", transparent)
	vbar.add_theme_stylebox_override("grabber", transparent)
	vbar.add_theme_stylebox_override("grabber_highlight", transparent)
	vbar.add_theme_stylebox_override("grabber_pressed", transparent)


static func _boxing_hub_growth_cost_text_for_row(skill_row: Dictionary) -> String:
	var current_level: int = int(skill_row.get("current_level", 0))
	var max_level: int = int(skill_row.get("max_level", 20))
	var next_cost: int = int(skill_row.get("next_cost", 0))
	var xp: int = int(skill_row.get("xp", 0))
	var remaining_total_slots: int = int(skill_row.get("remaining_total_slots", 0))

	if current_level >= max_level:
		return "MAX"

	if remaining_total_slots <= 0:
		return "CAP"

	if xp < next_cost:
		return "%d" % next_cost

	return "%d" % next_cost


static func _boxing_hub_growth_cost_color_for_row(skill_row: Dictionary, visual_contract: Dictionary) -> Color:
	var current_level: int = int(skill_row.get("current_level", 0))
	var max_level: int = int(skill_row.get("max_level", 20))
	var next_cost: int = int(skill_row.get("next_cost", 0))
	var xp: int = int(skill_row.get("xp", 0))
	var remaining_total_slots: int = int(skill_row.get("remaining_total_slots", 0))

	if current_level >= max_level:
		return Color(0.3, 1.0, 0.46, 1.0)

	if remaining_total_slots <= 0:
		return visual_contract.get("muted_text", Color(0.86, 0.9, 0.98, 0.8))

	if xp < next_cost:
		return visual_contract.get("muted_text", Color(0.86, 0.9, 0.98, 0.8))

	return visual_contract.get("title", Color(1.0, 0.9, 0.66, 1.0))


static func _boxing_hub_growth_board_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(base.r, base.g, base.b, 0.46)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.56)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func _boxing_hub_growth_row_style(visual_contract: Dictionary, alternate: bool = false) -> StyleBoxFlat:
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var alpha: float = 0.38 if alternate else 0.28

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(panel.r, panel.g, panel.b, alpha)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.1)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


static func _boxing_hub_growth_level_box_style(visual_contract: Dictionary, state: String) -> StyleBoxFlat:
	var clean_state: String = str(state).strip_edges().to_lower()
	var hover: bool = clean_state.ends_with("_hover")
	var pressed: bool = clean_state.ends_with("_pressed")
	clean_state = clean_state.replace("_hover", "").replace("_pressed", "")

	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	var bg: Color = Color(0.2, 0.23, 0.23, 0.58)
	var border: Color = Color(0.58, 0.64, 0.62, 0.62)
	var shadow: Color = Color(0.0, 0.0, 0.0, 0.14)
	var border_width: int = 1

	match clean_state:
		"filled":
			bg = Color(0.0, 0.84, 0.2, 0.98)
			border = Color(0.42, 1.0, 0.52, 0.92)
			shadow = Color(0.0, 1.0, 0.24, 0.22)
		"available":
			bg = Color(0.12, 0.18, 0.13, 0.62)
			border = Color(accent.r, accent.g, accent.b, 0.7)
			shadow = Color(accent.r, accent.g, accent.b, 0.14)
		"locked":
			bg = Color(0.18, 0.2, 0.2, 0.48)
			border = Color(0.58, 0.64, 0.62, 0.54)
			shadow = Color(0.0, 0.0, 0.0, 0.16)
		"blocked_flash":
			bg = Color(0.42, 0.08, 0.055, 0.78)
			border = Color(1.0, 0.12, 0.08, 1.0)
			shadow = Color(1.0, 0.06, 0.02, 0.42)
			border_width = 2

	if hover:
		if clean_state == "filled":
			bg = Color(0.08, 1.0, 0.3, 1.0)
			border = Color(0.72, 1.0, 0.76, 1.0)
			shadow = Color(0.0, 1.0, 0.3, 0.3)
		elif clean_state == "available":
			bg = Color(accent.r, accent.g, accent.b, 0.3)
			border = Color(hot.r, hot.g, hot.b, 0.96)
			shadow = Color(hot.r, hot.g, hot.b, 0.26)
		elif clean_state == "locked":
			bg = Color(0.22, 0.24, 0.24, 0.58)
			border = Color(0.74, 0.78, 0.76, 0.78)
			shadow = Color(0.0, 0.0, 0.0, 0.2)
		border_width = 2

	if pressed:
		if clean_state == "available":
			bg = Color(hot.r, hot.g, hot.b, 0.4)
			border = Color(1.0, 1.0, 0.92, 1.0)
			shadow = Color(hot.r, hot.g, hot.b, 0.3)
		elif clean_state == "locked":
			bg = Color(0.24, 0.25, 0.25, 0.64)
			border = Color(0.82, 0.86, 0.84, 0.84)
		border_width = 2

	var sb:= StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.shadow_color = shadow
	sb.shadow_size = 5
	sb.shadow_offset = Vector2.ZERO
	sb.content_margin_left = 0
	sb.content_margin_top = 0
	sb.content_margin_right = 0
	sb.content_margin_bottom = 0
	return sb


static func _boxing_hub_popup_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = base
	sb.border_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.set_border_width_all(0)
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	return sb


static func _boxing_hub_legacy_ladder_card_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(base.r, base.g, base.b, 0.42)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.44)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func _boxing_hub_shell_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = base.lerp(panel, 0.55)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.68)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 28
	sb.corner_radius_top_right = 28
	sb.corner_radius_bottom_left = 28
	sb.corner_radius_bottom_right = 28
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.76)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 8)
	sb.content_margin_left = 10
	sb.content_margin_top = 10
	sb.content_margin_right = 10
	sb.content_margin_bottom = 10
	return sb


static func _boxing_hub_tab_button_style(visual_contract: Dictionary, state: String = "normal") -> StyleBoxFlat:
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	var bg: Color = Color(panel.r, panel.g, panel.b, 0.62)
	var border: Color = Color(accent.r, accent.g, accent.b, 0.22)
	var shadow: Color = Color(accent.r, accent.g, accent.b, 0.08)
	var border_width: int = 1

	match state:
		"hover":
			bg = Color(accent.r, accent.g, accent.b, 0.2)
			border = Color(accent.r, accent.g, accent.b, 0.66)
			shadow = Color(accent.r, accent.g, accent.b, 0.3)
			border_width = 2
		"selected":
			bg = Color(accent.r, accent.g, accent.b, 0.28)
			border = Color(hot.r, hot.g, hot.b, 0.88)
			shadow = Color(accent.r, accent.g, accent.b, 0.34)
			border_width = 2
		"selected_hover":
			bg = Color(accent.r, accent.g, accent.b, 0.38)
			border = Color(hot.r, hot.g, hot.b, 1.0)
			shadow = Color(hot.r, hot.g, hot.b, 0.42)
			border_width = 2
		"pressed":
			bg = Color(hot.r, hot.g, hot.b, 0.24)
			border = Color(hot.r, hot.g, hot.b, 1.0)
			shadow = Color(hot.r, hot.g, hot.b, 0.26)
			border_width = 2

	var sb:= StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.shadow_color = shadow
	sb.shadow_size = 12
	sb.shadow_offset = Vector2.ZERO
	sb.content_margin_left = 10
	sb.content_margin_top = 6
	sb.content_margin_right = 10
	sb.content_margin_bottom = 6
	return sb


static func _boxing_hub_action_button_style(visual_contract: Dictionary, state: String = "normal") -> StyleBoxFlat:
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	var bg: Color = Color(panel.r, panel.g, panel.b, 0.72)
	var border: Color = Color(accent.r, accent.g, accent.b, 0.34)
	var shadow: Color = Color(0.0, 0.0, 0.0, 0.32)
	var border_width: int = 1

	match state:
		"hover":
			bg = Color(accent.r, accent.g, accent.b, 0.22)
			border = Color(hot.r, hot.g, hot.b, 0.9)
			shadow = Color(accent.r, accent.g, accent.b, 0.34)
			border_width = 2
		"pressed":
			bg = Color(hot.r, hot.g, hot.b, 0.26)
			border = Color(hot.r, hot.g, hot.b, 1.0)
			shadow = Color(hot.r, hot.g, hot.b, 0.28)
			border_width = 2

	var sb:= StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = shadow
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 12
	sb.content_margin_top = 8
	sb.content_margin_right = 12
	sb.content_margin_bottom = 8
	return sb


static func _boxing_hub_close_button_style(visual_contract: Dictionary, state: String = "normal") -> StyleBoxFlat:
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	var bg: Color = Color(0.05, 0.035, 0.025, 0.72)
	var border: Color = Color(accent.r, accent.g, accent.b, 0.78)
	var shadow: Color = Color(accent.r, accent.g, accent.b, 0.36)

	match state:
		"hover":
			bg = Color(accent.r, accent.g, accent.b, 0.26)
			border = Color(hot.r, hot.g, hot.b, 1.0)
			shadow = Color(hot.r, hot.g, hot.b, 0.56)
		"pressed":
			bg = Color(hot.r, hot.g, hot.b, 0.34)
			border = Color(1.0, 1.0, 1.0, 0.92)
			shadow = Color(hot.r, hot.g, hot.b, 0.36)

	var sb:= StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.shadow_color = shadow
	sb.shadow_size = 16
	sb.shadow_offset = Vector2.ZERO
	sb.content_margin_left = 8
	sb.content_margin_top = 8
	sb.content_margin_right = 8
	sb.content_margin_bottom = 8
	return sb


static func _boxing_hub_micro_card_style(visual_contract: Dictionary) -> StyleBoxFlat:
	var panel: Color = visual_contract.get("panel", Color(0.055, 0.044, 0.036, 0.97))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = Color(panel.r, panel.g, panel.b, 0.72)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.28)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func _boxing_hub_style_scrollbar(scrollbar: VScrollBar, visual_contract: Dictionary) -> void:
	if scrollbar == null:
		return

	var base: Color = visual_contract.get("base", Color(0.03, 0.026, 0.022, 0.99))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.56, 0.2, 1.0))
	var hot: Color = visual_contract.get("hot", Color(1.0, 0.82, 0.38, 1.0))

	var track:= StyleBoxFlat.new()
	track.bg_color = Color(base.r, base.g, base.b, 0.08)
	track.border_color = Color(accent.r, accent.g, accent.b, 0.1)
	track.set_border_width_all(1)
	track.corner_radius_top_left = 999
	track.corner_radius_top_right = 999
	track.corner_radius_bottom_left = 999
	track.corner_radius_bottom_right = 999

	var grabber:= StyleBoxFlat.new()
	grabber.bg_color = Color(accent.r, accent.g, accent.b, 0.62)
	grabber.border_color = Color(hot.r, hot.g, hot.b, 0.72)
	grabber.set_border_width_all(1)
	grabber.corner_radius_top_left = 999
	grabber.corner_radius_top_right = 999
	grabber.corner_radius_bottom_left = 999
	grabber.corner_radius_bottom_right = 999
	grabber.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	grabber.shadow_size = 10

	var grabber_hover:= grabber.duplicate() as StyleBoxFlat
	grabber_hover.bg_color = Color(hot.r, hot.g, hot.b, 0.86)
	grabber_hover.border_color = Color(1.0, 1.0, 1.0, 0.72)
	grabber_hover.shadow_color = Color(hot.r, hot.g, hot.b, 0.46)
	grabber_hover.shadow_size = 14

	var grabber_pressed:= grabber.duplicate() as StyleBoxFlat
	grabber_pressed.bg_color = Color(hot.r, hot.g, hot.b, 1.0)
	grabber_pressed.border_color = Color(1.0, 1.0, 1.0, 0.88)
	grabber_pressed.shadow_color = Color(hot.r, hot.g, hot.b, 0.38)
	grabber_pressed.shadow_size = 16

	scrollbar.add_theme_stylebox_override("scroll", track)
	scrollbar.add_theme_stylebox_override("scroll_focus", track)
	scrollbar.add_theme_stylebox_override("grabber", grabber)
	scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_pressed)


static func _boxing_belt_visual_contract_for_title_label(title_label: String) -> Dictionary:
	var body: String = BoxingSceneSupport._boxing_title_body_from_label(title_label)
	var visual: Dictionary = BoxingSceneSupport._boxing_belt_visual_contract_for_body(body)
	visual ["title_label"] = str(title_label).strip_edges()
	return visual


static func _boxing_belt_visual_contracts_for_title_labels(title_labels: Array) -> Array:
	var visuals: Array = []
	var seen: Dictionary = {}

	for raw_label in title_labels:
		var label: String = str(raw_label).strip_edges()
		if label == "":
			continue

		var body: String = BoxingSceneSupport._boxing_title_body_from_label(label)
		if body == "":
			body = label.to_upper()

		if seen.has(body):
			continue

		var visual: Dictionary = BoxingSceneSupport._boxing_belt_visual_contract_for_body(body)
		visual ["title_label"] = label
		visuals.append(visual)
		seen [body] = true

	return visuals


static func _boxing_champion_belt_aura_contract(title_labels: Array, is_champion: bool, fame_value: int = 0) -> Dictionary:
	var visuals: Array = BoxingSceneSupport._boxing_belt_visual_contracts_for_title_labels(title_labels)
	var has_wbc: bool = false
	var has_wba: bool = false
	var has_ibf: bool = false
	var has_wbo: bool = false
	var primary_glows: Array = []
	var secondary_glows: Array = []
	var borders: Array = []
	var backgrounds: Array = []
	var tags: Array = []

	for raw_visual in visuals:
		if typeof(raw_visual) != TYPE_DICTIONARY:
			continue

		var visual: Dictionary = raw_visual
		var body: String = str(visual.get("body", "")).strip_edges().to_upper()

		match body:
			"WBC":
				has_wbc = true
			"WBA":
				has_wba = true
			"IBF":
				has_ibf = true
			"WBO":
				has_wbo = true

		if typeof(visual.get("glow_primary", null)) == TYPE_COLOR:
			primary_glows.append(visual.get("glow_primary"))
		if typeof(visual.get("glow_secondary", null)) == TYPE_COLOR:
			secondary_glows.append(visual.get("glow_secondary"))
		if typeof(visual.get("border", null)) == TYPE_COLOR:
			borders.append(visual.get("border"))
		if typeof(visual.get("bg", null)) == TYPE_COLOR:
			backgrounds.append(visual.get("bg"))

		var tag: String = str(visual.get("aura_tag", "")).strip_edges()
		if tag != "" and tag not in tags:
			tags.append(tag)

	var belt_count: int = visuals.size()
	var undisputed: bool = has_wbc and has_wba and has_ibf and has_wbo
	var hybrid_red_green: bool = has_wbc and has_wba
	var dark_gold_dominance: bool = has_wbo and has_ibf

	var fallback_bg: Color = Color(0.06, 0.046, 0.03, 0.96)
	var fallback_border: Color = Color(1.0, 0.86, 0.48, 0.94)
	var fallback_primary: Color = Color(1.0, 0.86, 0.58, 0.48)
	var fallback_secondary: Color = Color(1.0, 0.94, 0.74, 0.22)

	var bg: Color = BoxingSceneSupport._boxing_blend_color_list(backgrounds, fallback_bg)
	var border: Color = BoxingSceneSupport._boxing_blend_color_list(borders, fallback_border)
	var primary: Color = BoxingSceneSupport._boxing_blend_color_list(primary_glows, fallback_primary)
	var secondary: Color = BoxingSceneSupport._boxing_blend_color_list(secondary_glows, fallback_secondary)
	var title_text: Color = Color(1.0, 0.92, 0.62, 1.0)
	var aura_label: String = "Champion Aura"
	var pulse_speed: float = 0.74

	if undisputed:
		bg = Color(0.025, 0.018, 0.012, 0.98)
		border = Color(1.0, 0.92, 0.34, 1.0)
		primary = Color(0.32, 1.0, 0.43, 0.72)
		secondary = Color(1.0, 0.12, 0.1, 0.62)
		title_text = Color(1.0, 0.96, 0.7, 1.0)
		aura_label = "UNDISPUTED GOD ENERGY"
		pulse_speed = 1.12
	elif hybrid_red_green:
		bg = Color(0.07, 0.055, 0.038, 0.97)
		border = Color(0.82, 0.62, 0.26, 0.96)
		primary = Color(0.16, 1.0, 0.42, 0.62)
		secondary = Color(1.0, 0.08, 0.16, 0.5)
		title_text = Color(0.96, 1.0, 0.82, 1.0)
		aura_label = "Hybrid Champion Aura"
	elif dark_gold_dominance:
		bg = Color(0.014, 0.012, 0.012, 0.98)
		border = Color(1.0, 0.78, 0.22, 0.96)
		primary = Color(1.0, 0.76, 0.16, 0.58)
		secondary = Color(1.0, 0.08, 0.06, 0.44)
		title_text = Color(1.0, 0.9, 0.56, 1.0)
		aura_label = "Dark Gold Dominance"
	elif has_wbc:
		aura_label = "WBC Green Glow"
		title_text = Color(0.85, 1.0, 0.88, 1.0)
	elif has_wba:
		aura_label = "WBA Maroon Glow"
		title_text = Color(1.0, 0.86, 0.88, 1.0)
	elif has_wbo:
		aura_label = "WBO Black Gold Glow"
		title_text = Color(1.0, 0.89, 0.54, 1.0)
	elif has_ibf:
		aura_label = "IBF Gold Glow"
		title_text = Color(1.0, 0.94, 0.72, 1.0)

	var fame_boost: float = clamp(float(fame_value) / 260.0, 0.0, 0.38)
	var intensity: float = clamp(0.24 + float(belt_count) * 0.16 + fame_boost, 0.0, 1.0)

	return {
		"enabled": is_champion and belt_count > 0,
		"belt_count": belt_count,
		"is_undisputed": undisputed,
		"hybrid_red_green": hybrid_red_green,
		"dark_gold_dominance": dark_gold_dominance,
		"visuals": visuals,
		"tags": tags,
		"label": aura_label,
		"bg": bg,
		"border": border,
		"glow_primary": primary,
		"glow_secondary": secondary,
		"title_text": title_text,
		"intensity": intensity,
		"pulse_speed": pulse_speed,
		"shadow_size": 14 + int(float(belt_count) * 5.0) + (10 if undisputed else 0)
	}


static func _boxing_hub_fighter_card_style(_visual_contract: Dictionary, row: Dictionary) -> StyleBoxFlat:
	var is_champion: bool = bool(row.get("is_champion", false))
	var belt_count: int = max(0, int(row.get("belt_count", 0)))
	var fame_value: int = clamp(int(row.get("fame", 0)), 0, 100)
	var rank: int = int(row.get("rank", 99))
	var rank_heat: float = clamp(float(row.get("rank_heat", 0.0)), 0.0, 1.0)
	if rank > 0 and rank <= 5:
		rank_heat = max(rank_heat, clamp(float(6 - rank) / 5.0, 0.0, 1.0))

	var title_labels: Array = row.get("title_labels", []) if typeof(row.get("title_labels", [])) == TYPE_ARRAY else []
	var belt_aura: Dictionary = row.get("belt_aura", {}) if typeof(row.get("belt_aura", {})) == TYPE_DICTIONARY else {}
	if belt_aura.is_empty():
		belt_aura = BoxingSceneSupport._boxing_champion_belt_aura_contract(title_labels, is_champion, fame_value)

	var cream_glow: float = clamp(0.14 + float(belt_count) * 0.18 + float(fame_value) / 280.0 + rank_heat * 0.12, 0.0, 1.0)
	var style:= StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	if is_champion:
		var intensity: float = clamp(float(belt_aura.get("intensity", cream_glow)), 0.0, 1.0)
		style.bg_color = belt_aura.get("bg", Color(0.24 + cream_glow * 0.18, 0.15 + cream_glow * 0.12, 0.055, 0.96))
		style.border_color = belt_aura.get("border", Color(1.0, 0.86, 0.48, 0.94))
		style.shadow_color = belt_aura.get("glow_primary", Color(1.0, 0.86, 0.58, 0.26 + cream_glow * 0.28))
		style.shadow_size = int(belt_aura.get("shadow_size", 14 + int(belt_count * 5)))

		if bool(belt_aura.get("is_undisputed", false)):
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.shadow_size += int(8.0 * intensity)
	elif rank > 0 and rank <= 5:
		style.bg_color = Color(0.06 + rank_heat * 0.03, 0.07 + rank_heat * 0.035, 0.09 + rank_heat * 0.03, 0.92)
		style.border_color = Color(0.92, 0.82, 0.58, 0.42 + rank_heat * 0.22)
		style.shadow_color = Color(1.0, 0.88, 0.62, 0.16 + rank_heat * 0.14)
		style.shadow_size = 8 + int(rank_heat * 5.0)
	else:
		style.bg_color = Color(0.03, 0.04, 0.06, 0.9)
		style.border_color = Color(0.52, 0.62, 0.78, 0.34)
		style.shadow_color = Color(0.1, 0.14, 0.22, 0.16)
		style.shadow_size = 6

	return style


static func _boxing_hub_champion_title_caption_from_labels(title_labels: Array, division_text: String = "") -> String:
	var body_names: Array = []
	var weight_class: String = str(division_text).strip_edges()

	if weight_class.begins_with("Male "):
		weight_class = weight_class.substr(5).strip_edges()
	elif weight_class.begins_with("Female "):
		weight_class = weight_class.substr(7).strip_edges()

	for raw_label in title_labels:
		var title_label: String = str(raw_label).strip_edges()
		if title_label == "":
			continue

		var body: String = BoxingSceneSupport._boxing_title_body_from_label(title_label)
		if body == "":
			continue

		var display_body: String = "Ring" if body == "RING" else body
		if display_body not in body_names:
			body_names.append(display_body)

		var clean_weight: String = title_label
		if body == "RING":
			clean_weight = clean_weight.replace("Ring Magazine Lineal", "")
			clean_weight = clean_weight.replace("Ring Magazine", "")
			clean_weight = clean_weight.replace("Lineal", "")
		else:
			clean_weight = clean_weight.replace(body, "")

		clean_weight = clean_weight.replace("Champion", "")
		clean_weight = clean_weight.replace("Champ", "")
		clean_weight = clean_weight.replace("Title", "")
		clean_weight = clean_weight.strip_edges()

		if clean_weight != "":
			weight_class = clean_weight

	if weight_class == "":
		return "Champion"

	if body_names.is_empty():
		return "%s Champion" % weight_class

	var suffix: String = "Champ" if body_names.size() == 1 else "Champion"
	return "%s %s %s" % [
		", ".join(body_names),
		weight_class,
		suffix
	]


static func _render_boxing_hub_fighter_card(parent: Control, row: Dictionary, visual_contract: Dictionary) -> void:
	if parent == null:
		return

	var is_champion: bool = bool(row.get("is_champion", false))
	var rank: int = int(row.get("rank", 99))
	var rank_heat: float = clamp(float(row.get("rank_heat", 0.0)), 0.0, 1.0)
	if rank > 0 and rank <= 5:
		rank_heat = max(rank_heat, clamp(float(6 - rank) / 5.0, 0.0, 1.0))

	var target_fame: float = clamp(float(row.get("fame", 0)), 0.0, 100.0)
	var title_labels: Array = row.get("title_labels", []) if typeof(row.get("title_labels", [])) == TYPE_ARRAY else []
	var belt_aura: Dictionary = row.get("belt_aura", {}) if typeof(row.get("belt_aura", {})) == TYPE_DICTIONARY else {}
	if belt_aura.is_empty():
		belt_aura = BoxingSceneSupport._boxing_champion_belt_aura_contract(title_labels, is_champion, int(target_fame))

	var belt_visuals: Array = row.get("belt_visuals", []) if typeof(row.get("belt_visuals", [])) == TYPE_ARRAY else []
	if belt_visuals.is_empty() and not title_labels.is_empty():
		belt_visuals = BoxingSceneSupport._boxing_belt_visual_contracts_for_title_labels(title_labels)

	var champion_title_caption: String = str(row.get("champion_title_caption", row.get("champion_aura_label", ""))).strip_edges()
	if champion_title_caption == "" and is_champion:
		champion_title_caption = BoxingSceneSupport._boxing_hub_champion_title_caption_from_labels(title_labels, str(row.get("division", "")))

	var card:= PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 176 if is_champion and not title_labels.is_empty() else 152)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", BoxingSceneSupport._boxing_hub_fighter_card_style(visual_contract, row))
	parent.add_child(card)

	var margin:= MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title:= Label.new()
	title.text = "%s%s" % [
		"🏆 " if is_champion else "",
		str(row.get("title", row.get("name", "Unknown Fighter")))
	]
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", belt_aura.get("title_text", Color(1.0, 0.92, 0.62, 1.0)) if is_champion else Color(0.93, 0.94, 0.98, 0.96))
	title.add_theme_color_override("font_shadow_color", belt_aura.get("glow_secondary", Color(0.0, 0.0, 0.0, 0.72)) if is_champion else Color(0.0, 0.0, 0.0, 0.54))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(title)

	if is_champion and champion_title_caption != "":
		var aura_label:= Label.new()
		aura_label.text = champion_title_caption
		aura_label.clip_text = true
		aura_label.add_theme_font_size_override("font_size", 10)
		aura_label.add_theme_color_override("font_color", belt_aura.get("title_text", Color(1.0, 0.9, 0.58, 0.92)))
		aura_label.add_theme_color_override("font_shadow_color", belt_aura.get("glow_primary", Color(0.0, 0.0, 0.0, 0.66)))
		aura_label.add_theme_constant_override("shadow_offset_x", 1)
		aura_label.add_theme_constant_override("shadow_offset_y", 1)
		box.add_child(aura_label)

	var record:= Label.new()
	record.text = "%s • %s" % [
		str(row.get("division", "")),
		str(row.get("record_text", "0-0-0"))
	]
	record.clip_text = true
	record.add_theme_font_size_override("font_size", 11)
	record.add_theme_color_override("font_color", visual_contract.get("body_text", Color(0.92, 0.95, 1.0, 0.9)))
	box.add_child(record)

	if not title_labels.is_empty():
		var belt_icons: Array = []
		for raw_visual in belt_visuals:
			if typeof(raw_visual) != TYPE_DICTIONARY:
				continue

			var belt_visual: Dictionary = raw_visual
			var belt_icon: String = str(belt_visual.get("emoji", "")).strip_edges()
			if belt_icon != "":
				belt_icons.append(belt_icon)

		var belts_header:= Label.new()
		belts_header.text = "Titles: %s" % " ".join(belt_icons) if not belt_icons.is_empty() else "Titles:"
		belts_header.add_theme_font_size_override("font_size", 10)
		belts_header.add_theme_color_override("font_color", belt_aura.get("title_text", Color(1.0, 0.84, 0.46, 0.96)) if is_champion else Color(1.0, 0.84, 0.46, 0.96))
		box.add_child(belts_header)

		var belts_wrap:= HFlowContainer.new()
		belts_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		belts_wrap.add_theme_constant_override("h_separation", 5)
		belts_wrap.add_theme_constant_override("v_separation", 4)
		box.add_child(belts_wrap)

		for raw_title_label in title_labels:
			var title_label: String = str(raw_title_label).strip_edges()
			if title_label == "":
				continue

			var visual: Dictionary = BoxingSceneSupport._boxing_belt_visual_contract_for_title_label(title_label)

			var chip_outer:= PanelContainer.new()
			chip_outer.add_theme_stylebox_override("panel", BoxingSceneSupport._boxing_belt_chip_style(visual, true))
			belts_wrap.add_child(chip_outer)

			var chip:= PanelContainer.new()
			chip.add_theme_stylebox_override("panel", BoxingSceneSupport._boxing_belt_chip_style(visual, false))
			chip_outer.add_child(chip)

			var chip_margin:= MarginContainer.new()
			chip_margin.add_theme_constant_override("margin_left", 5)
			chip_margin.add_theme_constant_override("margin_top", 2)
			chip_margin.add_theme_constant_override("margin_right", 5)
			chip_margin.add_theme_constant_override("margin_bottom", 2)
			chip.add_child(chip_margin)

			var chip_label:= Label.new()
			chip_label.text = "%s %s" % [
				str(visual.get("emoji", "🏆")),
				title_label
			]
			chip_label.clip_text = true
			chip_label.add_theme_font_size_override("font_size", 10)
			chip_label.add_theme_color_override("font_color", visual.get("text", Color(1.0, 0.94, 0.76, 1.0)))
			chip_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
			chip_label.add_theme_constant_override("shadow_offset_x", 1)
			chip_label.add_theme_constant_override("shadow_offset_y", 1)
			chip_margin.add_child(chip_label)

	var last_fight:= Label.new()
	last_fight.text = "Last: %s" % str(row.get("last_fight", "No recent fight."))
	last_fight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_fight.add_theme_font_size_override("font_size", 11)
	last_fight.add_theme_color_override("font_color", visual_contract.get("muted_text", Color(0.8, 0.86, 1.0, 0.8)))
	box.add_child(last_fight)

	var fame_label:= Label.new()
	fame_label.text = "Fame"
	fame_label.add_theme_font_size_override("font_size", 10)
	fame_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36, 0.94) if target_fame >= 30.0 else Color(1.0, 0.34, 0.3, 0.94))
	box.add_child(fame_label)

	var fame_wrap:= Control.new()
	fame_wrap.custom_minimum_size = Vector2(0, 15)
	fame_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(fame_wrap)

	var fame_bar:= ProgressBar.new()
	fame_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fame_bar.min_value = 0.0
	fame_bar.max_value = 100.0
	fame_bar.value = 0.0
	fame_bar.show_percentage = false
	fame_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fame_wrap.add_child(fame_bar)

	var back_style:= StyleBoxFlat.new()
	back_style.bg_color = Color(0.045, 0.04, 0.035, 0.96)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8

	var fill_style:= StyleBoxFlat.new()
	fill_style.bg_color = BoxingSceneSupport._boxing_hub_fame_fill_color(target_fame, is_champion, rank_heat)
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8

	fame_bar.add_theme_stylebox_override("background", back_style)
	fame_bar.add_theme_stylebox_override("fill", fill_style)

	var fame_number:= Label.new()
	fame_number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fame_number.text = "%d/100" % int(round(target_fame))
	fame_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fame_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fame_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fame_number.add_theme_font_size_override("font_size", 9)
	fame_number.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	fame_number.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	fame_number.add_theme_constant_override("shadow_offset_x", 1)
	fame_number.add_theme_constant_override("shadow_offset_y", 1)
	fame_wrap.add_child(fame_number)

	var tween:= fame_bar.create_tween()
	tween.tween_property(fame_bar, "value", target_fame, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if target_fame >= 75.0 or bool(belt_aura.get("is_undisputed", false)):
		var pulse:= fame_wrap.create_tween()
		pulse.set_loops()

		var pulse_color: Color = Color(1.0, 0.92, 0.58, 1.0) if target_fame >= 30.0 else Color(1.0, 0.34, 0.3, 1.0)
		var pulse_speed: float = float(belt_aura.get("pulse_speed", 0.48)) if is_champion else 0.48
		pulse_speed = clamp(pulse_speed, 0.34, 1.24)

		pulse.tween_property(fame_wrap, "modulate", pulse_color, pulse_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(fame_wrap, "modulate", Color(1.0, 1.0, 1.0, 1.0), pulse_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func _boxing_hub_panel_style(gs: GameState) -> StyleBoxFlat:
	var visual_contract: Dictionary = BoxingSceneSupport._boxing_hub_visual_contract(gs)
	var base: Color = visual_contract.get("panel", Color(0.045, 0.052, 0.075, 0.96))
	var accent: Color = visual_contract.get("accent", Color(1.0, 0.52, 0.2, 0.72))

	var sb:= StyleBoxFlat.new()
	sb.bg_color = base
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.54)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	sb.shadow_size = 22
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 14
	sb.content_margin_top = 14
	sb.content_margin_right = 14
	sb.content_margin_bottom = 14
	return sb


static func _boxing_hub_visual_contract(gs: GameState) -> Dictionary:
	var era_name: String = "Modern Era"
	if gs != null and gs.era != null:
		era_name = str(gs.era.name)

	var base: Color = Color(0.022, 0.024, 0.03, 0.99)
	var panel: Color = Color(0.04, 0.048, 0.062, 0.97)
	var accent: Color = Color(1.0, 0.56, 0.2, 1.0)
	var hot: Color = Color(1.0, 0.82, 0.38, 1.0)
	var title: Color = Color(1.0, 0.9, 0.66, 1.0)
	var body_text: Color = Color(0.96, 0.97, 1.0, 0.94)
	var muted_text: Color = Color(0.86, 0.9, 0.98, 0.8)

	match era_name:
		"Future Era":
			base = Color(0.004, 0.018, 0.03, 0.99)
			panel = Color(0.012, 0.04, 0.062, 0.97)
			accent = Color(0.36, 0.94, 1.0, 1.0)
			hot = Color(0.72, 1.0, 0.94, 1.0)
			title = Color(0.78, 1.0, 0.96, 1.0)
			body_text = Color(0.9, 0.98, 1.0, 0.94)
			muted_text = Color(0.74, 0.92, 1.0, 0.8)
		"Modern Era":
			base = Color(0.03, 0.026, 0.022, 0.99)
			panel = Color(0.055, 0.044, 0.036, 0.97)
			accent = Color(1.0, 0.56, 0.2, 1.0)
			hot = Color(1.0, 0.82, 0.38, 1.0)
			title = Color(1.0, 0.9, 0.66, 1.0)
			body_text = Color(0.98, 0.96, 0.92, 0.94)
			muted_text = Color(0.96, 0.88, 0.78, 0.8)
		_:
			base = Color(0.026, 0.024, 0.03, 0.99)
			panel = Color(0.044, 0.042, 0.054, 0.97)
			accent = Color(1.0, 0.58, 0.24, 1.0)
			hot = Color(1.0, 0.8, 0.38, 1.0)

	return {
		"era": era_name,
		"base": base,
		"panel": panel,
		"accent": accent,
		"hot": hot,
		"title": title,
		"body_text": body_text,
		"muted_text": muted_text,
		"shadow_accent": Color(accent.r, accent.g, accent.b, 0.48)
	}


static func _activities_begin_boxing_should_render(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	var actor: Person = gs.player
	if not bool(actor.alive):
		return false

	var profile: Dictionary = ValueSceneSupport._safe_dictionary(actor.boxing_profile)

	var already_started: bool = (
		bool(profile.get("is_boxer", false))
		or bool(profile.get("boxing_hub_unlocked", false))
		or bool(profile.get("boxing_career_started_by_player", false))
		or bool(profile.get("turned_pro", false))
		or bool(ValueSceneSupport._safe_dictionary(profile.get("amateur_circuit", {})).get("is_amateur", false))
	)

	if already_started:
		return false

	if bool(profile.get("retired", false)):
		return false

	return true
