extends RefCounted
class_name AppearanceSceneSupport
## Appearance support for the main scene. State, when needed, is passed explicitly.


static func _contract_row_layout_group_id(row: Variant) -> String:
	if typeof(row) != TYPE_DICTIONARY:
		return ""

	var row_dict: Dictionary = row
	return str(row_dict.get("layout_group", "")).strip_edges()


static func _contract_make_stylebox(bg: Color, border: Color, border_width: int = 1, radius: int = 16) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


static func _contract_surface_visual_theme(surface: Dictionary, surface_id: String) -> Dictionary:
	var runtime_state: Dictionary = surface.get("runtime_state", {}) if typeof(surface.get("runtime_state", {})) == TYPE_DICTIONARY else {}
	var store_id: String = str(runtime_state.get("store_id", "")).strip_edges()
	var visual: Dictionary = {
		"bg": Color(0.03, 0.036, 0.044, 0.975),
		"border": Color(0.62, 0.78, 0.82, 0.44),
		"title": Color(0.9, 0.96, 0.96, 1.0)
	}
	if surface_id == "restaurant_contract_hub":
		visual ["bg"] = Color(0.085, 0.052, 0.036, 0.985)
		visual ["border"] = Color(0.92, 0.62, 0.34, 0.56)
		visual ["title"] = Color(0.98, 0.92, 0.82, 1.0)
		return visual
	if surface_id == "food_contract_hub":
		match store_id:
			"basket_lane_market":
				visual ["bg"] = Color(0.088, 0.034, 0.048, 0.988)
				visual ["border"] = Color(1.0, 0.5, 0.43, 0.64)
				visual ["title"] = Color(1.0, 0.88, 0.84, 1.0)
			"goldleaf_grocers":
				visual ["bg"] = Color(0.05, 0.044, 0.032, 0.988)
				visual ["border"] = Color(0.92, 0.78, 0.48, 0.62)
				visual ["title"] = Color(0.98, 0.91, 0.7, 1.0)
			"nutripod_exchange":
				visual ["bg"] = Color(0.03, 0.048, 0.058, 0.985)
				visual ["border"] = Color(0.5, 0.86, 0.92, 0.56)
				visual ["title"] = Color(0.78, 0.96, 0.98, 1.0)
			_:
				visual ["bg"] = Color(0.034, 0.046, 0.038, 0.982)
				visual ["border"] = Color(0.58, 0.74, 0.58, 0.46)
				visual ["title"] = Color(0.86, 0.96, 0.84, 1.0)
	return visual


static func _contract_brighten_color(color: Color, amount: float = 0.04) -> Color:
	return Color(
		clamp(color.r + amount, 0.0, 1.0),
		clamp(color.g + amount, 0.0, 1.0),
		clamp(color.b + amount, 0.0, 1.0),
		color.a
	)


static func _contract_darken_color(color: Color, amount: float = 0.04) -> Color:
	return Color(
		clamp(color.r - amount, 0.0, 1.0),
		clamp(color.g - amount, 0.0, 1.0),
		clamp(color.b - amount, 0.0, 1.0),
		color.a
	)


static func _append_stone_colored_text_to_rich_label(
	target_label: RichTextLabel,
	text: String,
	append_newline: bool = true
) -> void:
	if target_label == null:
		return
	var stone_colors: Dictionary = {
		"Mind Stone": Color(1.0, 0.92, 0.22, 1.0),
		"Space Stone": Color(0.3, 0.58, 1.0, 1.0),
		"Reality Stone": Color(1.0, 0.26, 0.34, 1.0),
		"Power Stone": Color(0.7, 0.4, 1.0, 1.0),
		"Time Stone": Color(0.24, 0.92, 0.46, 1.0),
		"Soul Stone": Color(1.0, 0.58, 0.16, 1.0)
	}
	var ordered_names: Array = [
		"Reality Stone",
		"Space Stone",
		"Mind Stone",
		"Power Stone",
		"Time Stone",
		"Soul Stone"
	]
	var cursor: int = 0
	while cursor < text.length():
		var nearest_name: String = ""
		var nearest_index: int = -1
		for stone_name_value in ordered_names:
			var stone_name: String = str(stone_name_value)
			var idx: int = text.find(stone_name, cursor)
			if idx == -1:
				continue
			if nearest_index == -1 or idx < nearest_index:
				nearest_index = idx
				nearest_name = stone_name
		if nearest_index == -1:
			var tail_text: String = text.substr(cursor)
			if tail_text != "":
				target_label.append_text(tail_text)
			if append_newline:
				target_label.append_text("\n")
			return
		if nearest_index > cursor:
			target_label.append_text(text.substr(cursor, nearest_index - cursor))
		target_label.push_color(stone_colors.get(nearest_name, Color(1.0, 1.0, 1.0, 1.0)))
		target_label.push_bold()
		target_label.append_text(nearest_name)
		target_label.pop()
		target_label.pop()
		cursor = nearest_index + nearest_name.length()
	if append_newline:
		target_label.append_text("\n")


static func _era_surface_theme_data(theme_key: String, surface_kind: String = "main") -> Dictionary:
	if surface_kind == "player_stats":
		match theme_key:
			"ancient":
				return {
					"bg": Color(0.48, 0.38, 0.28, 0.97),
					"hover_bg": Color(0.54, 0.42, 0.31, 0.99),
					"border": Color(1.0, 0.9, 0.7, 0.28),
					"hover_border": Color(1.0, 0.95, 0.78, 0.42),
					"glow": Color(1.0, 0.88, 0.6, 0.12),
					"hover_glow": Color(1.0, 0.92, 0.7, 0.18),
					"glow_size": 12,
					"hover_glow_size": 18,
					"radius": 18,
					"margin": 8
				}
			"medieval":
				return {
					"bg": Color(0.2, 0.23, 0.28, 0.97),
					"hover_bg": Color(0.24, 0.28, 0.33, 0.99),
					"border": Color(0.92, 0.96, 1.0, 0.3),
					"hover_border": Color(0.98, 0.99, 1.0, 0.42),
					"glow": Color(0.92, 0.96, 1.0, 0.1),
					"hover_glow": Color(0.98, 0.99, 1.0, 0.16),
					"glow_size": 10,
					"hover_glow_size": 16,
					"radius": 18,
					"margin": 8
				}
			"future":
				return {
					"bg": Color(0.12, 0.2, 0.26, 0.98),
					"hover_bg": Color(0.16, 0.25, 0.31, 1.0),
					"border": Color(0.76, 0.94, 1.0, 0.3),
					"hover_border": Color(0.88, 0.98, 1.0, 0.44),
					"glow": Color(0.66, 0.98, 1.0, 0.12),
					"hover_glow": Color(0.86, 1.0, 1.0, 0.18),
					"glow_size": 12,
					"hover_glow_size": 18,
					"radius": 18,
					"margin": 8
				}
			_:
				return {
					"bg": Color(0.18, 0.3, 0.78, 0.96),
					"hover_bg": Color(0.24, 0.38, 0.9, 0.98),
					"border": Color(0.94, 0.98, 1.0, 0.3),
					"hover_border": Color(1.0, 1.0, 1.0, 0.46),
					"glow": Color(1.0, 1.0, 1.0, 0.14),
					"hover_glow": Color(1.0, 1.0, 1.0, 0.22),
					"glow_size": 20,
					"hover_glow_size": 28,
					"radius": 18,
					"margin": 8
				}

	match theme_key:
		"ancient":
			return {
				"bg": Color(0.34, 0.28, 0.22, 0.9),
				"hover_bg": Color(0.4, 0.32, 0.24, 0.94),
				"border": Color(0.96, 0.82, 0.58, 0.12),
				"hover_border": Color(1.0, 0.88, 0.64, 0.2),
				"glow": Color(1.0, 0.8, 0.48, 0.03),
				"hover_glow": Color(1.0, 0.82, 0.52, 0.06),
				"glow_size": 4,
				"hover_glow_size": 7,
				"radius": 14,
				"margin": 10
			}
		"medieval":
			return {
				"bg": Color(0.12, 0.14, 0.17, 0.9),
				"hover_bg": Color(0.16, 0.18, 0.22, 0.94),
				"border": Color(0.9, 0.94, 0.99, 0.16),
				"hover_border": Color(0.96, 0.98, 1.0, 0.24),
				"glow": Color(0.88, 0.94, 1.0, 0.02),
				"hover_glow": Color(0.94, 0.98, 1.0, 0.04),
				"glow_size": 4,
				"hover_glow_size": 6,
				"radius": 14,
				"margin": 10
			}
		"future":
			return {
				"bg": Color(0.08, 0.13, 0.18, 0.92),
				"hover_bg": Color(0.1, 0.16, 0.22, 0.96),
				"border": Color(0.62, 0.86, 0.96, 0.14),
				"hover_border": Color(0.74, 0.92, 1.0, 0.22),
				"glow": Color(0.36, 0.96, 1.0, 0.04),
				"hover_glow": Color(0.54, 0.98, 1.0, 0.08),
				"glow_size": 5,
				"hover_glow_size": 9,
				"radius": 14,
				"margin": 10
			}
		_:
			return {
				"bg": Color(0.05, 0.09, 0.18, 0.84),
				"hover_bg": Color(0.08, 0.15, 0.3, 0.9),
				"border": Color(1.0, 1.0, 1.0, 0.14),
				"hover_border": Color(1.0, 1.0, 1.0, 0.26),
				"glow": Color(1.0, 1.0, 1.0, 0.08),
				"hover_glow": Color(1.0, 1.0, 1.0, 0.18),
				"glow_size": 8,
				"hover_glow_size": 14,
				"radius": 14,
				"margin": 10
			}


static func _safe_modal_z_index(raw_value: int, fallback_value: int = 950) -> int:
	var min_z: int = -2048
	var max_z: int = 2048
	var desired_z: int = max(int(raw_value), int(fallback_value))
	return int(clamp(desired_z, min_z, max_z))


static func _runtime_stylebox_flat_from_meta(meta_target: Object, meta_key: String, border_width: int = 2, corner_radius: int = 16) -> StyleBoxFlat:
	if meta_target == null:
		return null

	var raw_style: Variant = null
	if meta_target.has_meta(meta_key):
		raw_style = meta_target.get_meta(meta_key)

	if raw_style is StyleBoxFlat:
		return raw_style as StyleBoxFlat

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	meta_target.set_meta(meta_key, style)
	return style


static func _make_era_border_rect(initial_color: Color) -> ColorRect:
	var rect:= ColorRect.new()
	rect.color = initial_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _position_particle_along_frame(
	rect: ColorRect,
	distance: float,
	w: float,
	h: float,
	inset: float,
	particle_size: float
) -> void:
	var perimeter: float = max(1.0, (w * 2.0) + (h * 2.0))
	var d: float = fposmod(distance, perimeter)

	rect.size = Vector2(particle_size, particle_size)

	if d <= w:
		rect.position = Vector2(d - particle_size * 0.5, inset)
	elif d <= w + h:
		d -= w
		rect.position = Vector2(w - inset - particle_size, d - particle_size * 0.5)
	elif d <= w + h + w:
		d -= (w + h)
		rect.position = Vector2((w - d) - particle_size * 0.5, h - inset - particle_size)
	else:
		d -= (w + h + w)
		rect.position = Vector2(inset, (h - d) - particle_size * 0.5)


static func _era_border_theme_data(theme_key: String) -> Dictionary:
	match theme_key:
		"medieval":
			return {
				"core": Color(0.3, 0.35, 0.42, 0.98),
				"glow": Color(0.86, 0.92, 1.0, 0.03),
				"thickness": 5.0,
				"glow_thickness": 5.0,
				"pulse": 0.008,
				"shadow_alpha": 0.36,
				"corner_alpha": 0.05,
				"inner_inset": 5.0,
				"pulse_speed": 0.75,
				"corner_scale": 0.82,
				"highlight": Color(0.96, 0.99, 1.0, 0.26),
				"overlay": Color(0.84, 0.9, 0.98, 0.04),
				"hot_corner": Color(0.98, 1.0, 1.0, 0.08),
				"top_mult": 1.0,
				"right_mult": 1.0,
				"bottom_mult": 1.06,
				"left_mult": 1.0,
				"highlight_thickness": 1.8,
				"overlay_width_ratio": 0.1,
				"overlay_speed": 0.22
			}
		"modern":
			return {
				"core": Color(0.94, 0.95, 0.97, 0.94),
				"glow": Color(0.94, 0.97, 1.0, 0.02),
				"thickness": 3.0,
				"glow_thickness": 3.0,
				"pulse": 0.004,
				"shadow_alpha": 0.07,
				"corner_alpha": 0.012,
				"inner_inset": 3.0,
				"pulse_speed": 0.45,
				"corner_scale": 0.58,
				"highlight": Color(1.0, 1.0, 1.0, 0.14),
				"overlay": Color(1.0, 1.0, 1.0, 0.025),
				"hot_corner": Color(1.0, 1.0, 1.0, 0.03),
				"top_mult": 1.0,
				"right_mult": 1.0,
				"bottom_mult": 1.0,
				"left_mult": 1.0,
				"highlight_thickness": 1.0,
				"overlay_width_ratio": 0.08,
				"overlay_speed": 0.12
			}
		"future":
			return {
				"core": Color(0.24, 0.9, 1.0, 0.98),
				"glow": Color(0.5, 0.98, 1.0, 0.1),
				"thickness": 7.0,
				"glow_thickness": 12.0,
				"pulse": 0.1,
				"shadow_alpha": 0.08,
				"corner_alpha": 0.18,
				"inner_inset": 4.0,
				"pulse_speed": 1.55,
				"corner_scale": 1.18,
				"highlight": Color(0.9, 1.0, 1.0, 0.5),
				"overlay": Color(0.7, 0.96, 1.0, 0.08),
				"hot_corner": Color(0.76, 1.0, 1.0, 0.2),
				"top_mult": 1.0,
				"right_mult": 1.0,
				"bottom_mult": 1.0,
				"left_mult": 1.0,
				"highlight_thickness": 2.0,
				"overlay_width_ratio": 0.16,
				"overlay_speed": 1.1
			}
		_:
			return {
				"core": Color(0.62, 0.5, 0.33, 0.98),
				"glow": Color(0.96, 0.75, 0.4, 0.05),
				"thickness": 5.0,
				"glow_thickness": 7.0,
				"pulse": 0.04,
				"shadow_alpha": 0.3,
				"corner_alpha": 0.14,
				"inner_inset": 5.0,
				"pulse_speed": 1.0,
				"corner_scale": 1.04,
				"highlight": Color(0.98, 0.86, 0.6, 0.18),
				"overlay": Color(0.94, 0.78, 0.52, 0.07),
				"hot_corner": Color(1.0, 0.84, 0.56, 0.18),
				"top_mult": 0.84,
				"right_mult": 0.96,
				"bottom_mult": 1.12,
				"left_mult": 0.9,
				"highlight_thickness": 1.4,
				"overlay_width_ratio": 0.1,
				"overlay_speed": 0.24
			}


static func _standard_tab_make_vormir_panel_style(kind: String = "info") -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()

	match kind:
		"stat":
			style.bg_color = Color(0.018, 0.01, 0.03, 0.985)
			style.border_color = Color(0.78, 0.3, 1.0, 0.86)
			style.shadow_color = Color(0.42, 0.08, 0.88, 0.42)
			style.shadow_size = 24
		"section":
			style.bg_color = Color(0.03, 0.012, 0.05, 0.96)
			style.border_color = Color(1.0, 0.48, 0.16, 0.72)
			style.shadow_color = Color(0.76, 0.18, 1.0, 0.38)
			style.shadow_size = 26
		"button":
			style.bg_color = Color(0.035, 0.014, 0.062, 0.98)
			style.border_color = Color(1.0, 0.52, 0.18, 0.88)
			style.shadow_color = Color(0.72, 0.18, 1.0, 0.44)
			style.shadow_size = 24
		"button_hover":
			style.bg_color = Color(0.07, 0.028, 0.11, 1.0)
			style.border_color = Color(1.0, 0.68, 0.28, 1.0)
			style.shadow_color = Color(0.92, 0.3, 1.0, 0.62)
			style.shadow_size = 32
		_:
			style.bg_color = Color(0.012, 0.008, 0.024, 0.988)
			style.border_color = Color(0.72, 0.28, 1.0, 0.9)
			style.shadow_color = Color(0.42, 0.08, 0.88, 0.46)
			style.shadow_size = 28

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_offset = Vector2.ZERO

	return style


static func _standard_tab_apply_vormir_label_style(label: Label, strong: bool = false) -> void:
	if label == null:
		return

	label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.78, 0.99) if strong else Color(0.93, 0.86, 1.0, 0.96))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.36, 0.08, 0.34) if strong else Color(0.7, 0.18, 1.0, 0.3))
	label.add_theme_constant_override("shadow_outline_size", 4 if strong else 2)


static func _standard_tab_apply_vormir_bar_style(bar: ProgressBar) -> void:
	if bar == null:
		return

	var bg:= StyleBoxFlat.new()
	bg.bg_color = Color(0.018, 0.01, 0.03, 0.96)
	bg.border_color = Color(0.44, 0.12, 0.72, 0.62)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 10
	bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_left = 10
	bg.corner_radius_bottom_right = 10

	var fill:= StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.48, 0.16, 0.92)
	fill.border_color = Color(1.0, 0.76, 0.3, 0.68)
	fill.border_width_left = 1
	fill.border_width_top = 1
	fill.border_width_right = 1
	fill.border_width_bottom = 1
	fill.corner_radius_top_left = 10
	fill.corner_radius_top_right = 10
	fill.corner_radius_bottom_left = 10
	fill.corner_radius_bottom_right = 10
	fill.shadow_color = Color(1.0, 0.42, 0.1, 0.34)
	fill.shadow_size = 10
	fill.shadow_offset = Vector2.ZERO

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


static func _build_theme_color_override_cache_key(
	override_name: String,
	color: Color,
	quantization_steps: int = 64
) -> String:
	var quant_steps: int = max(1, quantization_steps)
	var r_bucket: int = int(round(clamp(color.r, 0.0, 1.0) * quant_steps))
	var g_bucket: int = int(round(clamp(color.g, 0.0, 1.0) * quant_steps))
	var b_bucket: int = int(round(clamp(color.b, 0.0, 1.0) * quant_steps))
	var a_bucket: int = int(round(clamp(color.a, 0.0, 1.0) * quant_steps))
	return "%s|%d|%d|%d|%d" % [
		override_name,
		r_bucket,
		g_bucket,
		b_bucket,
		a_bucket
	]


static func _build_control_scale_cache_key(
	scale_value: Vector2,
	quantization_steps: int = 384
) -> String:
	var quant_steps: int = max(1, quantization_steps)
	var x_bucket: int = int(round(scale_value.x * quant_steps))
	var y_bucket: int = int(round(scale_value.y * quant_steps))
	return "%d|%d" % [x_bucket, y_bucket]


static func _build_control_rotation_cache_key(
	rotation_value: float,
	quantization_steps: int = 8192
) -> String:
	var quant_steps: int = max(1, quantization_steps)
	return str(int(round(rotation_value * quant_steps)))


static func _build_control_position_cache_key(
	position_value: Vector2,
	quantization_steps: int = 4
) -> String:
	var quant_steps: int = max(1, quantization_steps)
	var x_bucket: int = int(round(position_value.x * quant_steps))
	var y_bucket: int = int(round(position_value.y * quant_steps))
	return "%d|%d" % [x_bucket, y_bucket]


static func _build_canvas_item_modulate_cache_key(
	color: Color,
	quantization_steps: int = 128
) -> String:
	var quant_steps: int = max(1, quantization_steps)
	var r_bucket: int = int(round(clamp(color.r, 0.0, 1.0) *
	quant_steps))
	var g_bucket: int = int(round(clamp(color.g, 0.0, 1.0) *
	quant_steps))
	var b_bucket: int = int(round(clamp(color.b, 0.0, 1.0) *
	quant_steps))
	var a_bucket: int = int(round(clamp(color.a, 0.0, 1.0) *
	quant_steps))
	return "%d|%d|%d|%d" % [
		r_bucket,
		g_bucket,
		b_bucket,
		a_bucket
	]


static func _contract_tab_visual_theme(surface_id: String, _tab_id: String, active: bool, surface: Dictionary = {}) -> Dictionary:
	var surface_visual: Dictionary = AppearanceSceneSupport._contract_surface_visual_theme(surface, surface_id)
	var runtime_state: Dictionary = surface.get("runtime_state", {}) if typeof(surface.get("runtime_state", {})) == TYPE_DICTIONARY else {}
	var store_id: String = str(runtime_state.get("store_id", "")).strip_edges()
	var border: Color = Color(0.42, 0.56, 0.64, 0.3)
	var font: Color = Color(0.9, 1.0, 1.0, 1.0)
	var bg: Color = Color(0.03, 0.045, 0.065, 0.82)
	if surface_visual.has("border"):
		border = surface_visual.get("border")
	if surface_visual.has("title"):
		font = surface_visual.get("title")
	if surface_id == "restaurant_contract_hub":
		bg = Color(0.175, 0.085, 0.035, 0.94) if active else Color(0.07, 0.038, 0.024, 0.84)
		border = Color(1.0, 0.66, 0.24, 0.78) if active else Color(1.0, 0.46, 0.18, 0.34)
		font = Color(1.0, 0.94, 0.84, 1.0)
	elif surface_id == "food_contract_hub":
		if store_id == "basket_lane_market":
			bg = Color(0.158, 0.058, 0.076, 0.96) if active else Color(0.076, 0.032, 0.046, 0.86)
			border = Color(1.0, 0.56, 0.46, 0.82) if active else Color(0.86, 0.36, 0.38, 0.42)
			font = Color(1.0, 0.9, 0.88, 1.0)
		else:
			bg = Color(0.092, 0.075, 0.04, 0.94) if active else Color(0.035, 0.052, 0.04, 0.84)
			border = Color(1.0, 0.76, 0.24, 0.78) if active else Color(0.55, 0.72, 0.48, 0.38)
			font = Color(1.0, 0.92, 0.62, 1.0)
	return {
		"bg": bg,
		"border": border,
		"font": font
	}


static func _contract_row_visual_theme(surface_id: String, _section_id: String, row_dict: Dictionary = {}) -> Dictionary:
	var row_kind: String = str(row_dict.get("kind", "")).strip_edges().to_lower()
	var store_id: String = str(row_dict.get("store_id", "")).strip_edges()
	var restaurant_id: String = str(row_dict.get("restaurant_id", "")).strip_edges()
	var category: String = str(row_dict.get("category", "")).strip_edges().to_lower()
	var tier: String = str(row_dict.get("tier", "")).strip_edges().to_lower()
	var bg: Color = Color(0.04, 0.055, 0.075, 0.88)
	var border: Color = Color(0.46, 0.72, 0.78, 0.28)
	var font: Color = Color(0.94, 1.0, 1.0, 1.0)
	var description_font: Color = Color(0.7, 0.82, 0.86, 0.9)
	var border_width: int = 1
	var radius: int = 16
	var title_size: int = 16
	var pulse_glow: bool = false
	var pulse_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
	var pulse_seconds: float = 0.82
	var orbit_color: Color = Color(0.0, 0.0, 0.0, 0.0)
	var orbit_seconds: float = 2.1

	if surface_id == "food_contract_hub":
		bg = Color(0.035, 0.05, 0.04, 0.92)
		border = Color(0.52, 0.74, 0.54, 0.42)
		font = Color(0.92, 1.0, 0.88, 1.0)
		description_font = Color(0.76, 0.88, 0.78, 0.92)
		match store_id:
			"basket_lane_market":
				bg = Color(0.11, 0.046, 0.06, 0.97)
				border = Color(1.0, 0.56, 0.46, 0.8)
				font = Color(1.0, 0.9, 0.88, 1.0)
				description_font = Color(1.0, 0.82, 0.8, 0.94)
				border_width = 2
			"goldleaf_grocers":
				bg = Color(0.07, 0.05, 0.024, 0.97)
				border = Color(1.0, 0.84, 0.34, 0.86)
				font = Color(1.0, 0.94, 0.72, 1.0)
				description_font = Color(0.98, 0.87, 0.62, 0.95)
				border_width = 2
			"nutripod_exchange":
				bg = Color(0.028, 0.058, 0.078, 0.96)
				border = Color(0.38, 0.95, 1.0, 0.76)
				font = Color(0.76, 1.0, 1.0, 1.0)
				description_font = Color(0.66, 0.9, 0.96, 0.94)
				border_width = 2

		if row_kind == "grocery_store_premium":
			radius = 22
			title_size = 19
		elif row_kind == "grocery_item":
			radius = 14
			title_size = 15
			var grocery_visual: Dictionary = FoodSceneSupport._grocery_item_contract_visual_profile(row_dict)
			if grocery_visual.has("bg"):
				bg = grocery_visual.get("bg")
			if grocery_visual.has("border"):
				border = grocery_visual.get("border")
			if grocery_visual.has("font"):
				font = grocery_visual.get("font")
			if grocery_visual.has("description_font"):
				description_font = grocery_visual.get("description_font")
			if grocery_visual.has("border_width"):
				border_width = int(grocery_visual.get("border_width", border_width))
			if grocery_visual.has("radius"):
				radius = int(grocery_visual.get("radius", radius))
			if grocery_visual.has("title_size"):
				title_size = int(grocery_visual.get("title_size", title_size))
			pulse_glow = bool(grocery_visual.get("pulse_glow", false))
			pulse_tint = grocery_visual.get("pulse_tint", pulse_tint)
			pulse_seconds = float(grocery_visual.get("pulse_seconds", pulse_seconds))
			orbit_color = grocery_visual.get("orbit_color", orbit_color)
			orbit_seconds = float(grocery_visual.get("orbit_seconds", orbit_seconds))
		elif row_kind == "grocery_aisle_carousel":
			radius = 20
			title_size = 24
			if store_id == "basket_lane_market":
				bg = Color(0.148, 0.056, 0.078, 0.97)
				border = Color(1.0, 0.62, 0.5, 0.86)
				font = Color(1.0, 0.92, 0.9, 1.0)
				description_font = Color(1.0, 0.84, 0.82, 0.94)
				border_width = 3
		elif row_kind == "grocery_inside_store_header":
			title_size = 18
			radius = 22
			if store_id == "basket_lane_market":
				bg = Color(0.126, 0.05, 0.066, 0.97)
				border = Color(1.0, 0.58, 0.48, 0.84)
				font = Color(1.0, 0.9, 0.88, 1.0)
				description_font = Color(1.0, 0.82, 0.8, 0.94)
				border_width = 3

	if surface_id == "restaurant_contract_hub":
		bg = Color(0.1, 0.05, 0.026, 0.94)
		border = Color(1.0, 0.56, 0.18, 0.48)
		font = Color(1.0, 0.94, 0.86, 1.0)
		description_font = Color(1.0, 0.8, 0.62, 0.92)
		if ["restaurant_intent", "restaurant_intent_partner", "restaurant_intent_find_date", "restaurant_intent_locked"].has(row_kind):
			bg = Color(0.15, 0.074, 0.032, 0.97)
			border = Color(1.0, 0.67, 0.28, 0.72)
			font = Color(1.0, 0.95, 0.88, 1.0)
			description_font = Color(1.0, 0.82, 0.66, 0.94)
			border_width = 2
			radius = 22
			title_size = 18
		elif row_kind == "restaurant_category":
			bg = Color(0.175, 0.084, 0.034, 0.96)
			border = Color(1.0, 0.72, 0.3, 0.68)
			border_width = 2
			radius = 20
			title_size = 18
		elif ["restaurant", "restaurant_selected"].has(row_kind):
			var key: String = restaurant_id
			if key == "":
				key = str(row_dict.get("label", "restaurant"))
			var palette_index: int = abs(int(hash(key))) % 4
			match palette_index:
				0:
					bg = Color(0.135, 0.048, 0.03, 0.96)
					border = Color(1.0, 0.45, 0.24, 0.7)
				1:
					bg = Color(0.115, 0.072, 0.03, 0.96)
					border = Color(1.0, 0.72, 0.28, 0.7)
				2:
					bg = Color(0.086, 0.045, 0.03, 0.96)
					border = Color(1.0, 0.88, 0.66, 0.64)
				_:
					bg = Color(0.15, 0.06, 0.02, 0.96)
					border = Color(1.0, 0.58, 0.14, 0.72)
			if category == "luxury" or tier.find("luxury") >= 0:
				border = Color(1.0, 0.84, 0.4, 0.86)
				font = Color(1.0, 0.95, 0.76, 1.0)
			elif category == "fast_food":
				border = Color(1.0, 0.38, 0.18, 0.8)
				font = Color(1.0, 0.9, 0.78, 1.0)
			if row_kind == "restaurant_selected":
				border_width = 3
				title_size = 18
			else:
				border_width = 2
				title_size = 17

	return {
		"bg": bg,
		"border": border,
		"font": font,
		"description_font": description_font,
		"border_width": border_width,
		"radius": radius,
		"title_size": title_size,
		"pulse_glow": pulse_glow,
		"pulse_tint": pulse_tint,
		"pulse_seconds": pulse_seconds,
		"orbit_color": orbit_color,
		"orbit_seconds": orbit_seconds
	}


static func _apply_contract_action_button_visual(button: Button, action: Dictionary, surface_id: String, section_id: String, row_context: Dictionary = {}, compact_contract_section: bool = false) -> void:
	if button == null or not is_instance_valid(button):
		return

	var action_id: String = str(action.get("id", action.get("action_id", ""))).strip_edges()
	var action_style: String = str(action.get("style", "")).strip_edges().to_lower()
	var row_store_id: String = str(row_context.get("store_id", "")).strip_edges()
	var row_visual: Dictionary = AppearanceSceneSupport._contract_row_visual_theme(surface_id, section_id, row_context)
	var bg: Color = Color(0.06, 0.075, 0.085, 0.94)
	var border: Color = Color(0.66, 0.76, 0.78, 0.44)
	var font: Color = Color(0.94, 0.98, 0.98, 1.0)
	var glow: Color = Color(1.0, 1.0, 1.0, 0.32)
	var border_width: int = 1
	var radius: int = 15

	if row_visual.has("border"):
		border = row_visual.get("border")
	if row_visual.has("font"):
		font = row_visual.get("font")

	if surface_id == "food_contract_hub":
		bg = Color(0.045, 0.06, 0.05, 0.94)
		border = Color(0.78, 0.82, 0.74, 0.36)
		font = Color(0.91, 0.96, 0.9, 1.0)
		glow = Color(1.0, 1.0, 1.0, 0.42)

		var era_mart_context: bool = (
			action_id == "grocery_store:basket_lane_market"
			or row_store_id == "basket_lane_market"
			or action_id.begins_with("grocery_aisle:")
			or action_id == "grocery_done_browsing"
			or action_id == "grocery_back:aisles"
			or action_id == "grocery_back:stores"
		)

		if era_mart_context:
			bg = Color(0.138, 0.06, 0.076, 0.97)
			border = Color(1.0, 0.56, 0.46, 0.78)
			font = Color(1.0, 0.92, 0.88, 1.0)
			glow = Color(1.0, 0.72, 0.66, 0.48)
			border_width = 2
			radius = 18

		if action_id == "grocery_store:basket_lane_market":
			bg = Color(0.16, 0.064, 0.082, 0.98)
			border = Color(1.0, 0.6, 0.5, 0.84)
			font = Color(1.0, 0.92, 0.88, 1.0)
			border_width = 2
			radius = 18
		elif action_id == "grocery_store:goldleaf_grocers" or action_id.begins_with("grocery_goldleaf_membership"):
			bg = Color(0.085, 0.066, 0.038, 0.96)
			border = Color(0.94, 0.8, 0.46, 0.76)
			font = Color(0.98, 0.92, 0.72, 1.0)
			border_width = 2
			radius = 18
		elif action_id.begins_with("grocery_aisle:"):
			bg = Color(0.152, 0.064, 0.084, 0.98)
			border = Color(1.0, 0.64, 0.52, 0.86)
			font = Color(1.0, 0.94, 0.92, 1.0)
			glow = Color(1.0, 0.78, 0.72, 0.52)
			border_width = 2
			radius = 20
		elif action_id.begins_with("grocery_add"):
			if row_store_id == "basket_lane_market":
				bg = Color(0.13, 0.06, 0.072, 0.97)
				border = Color(1.0, 0.58, 0.48, 0.82)
				font = Color(1.0, 0.92, 0.9, 1.0)
				glow = Color(1.0, 0.74, 0.68, 0.52)
				border_width = 2
				radius = 16
			else:
				bg = Color(0.06, 0.07, 0.068, 0.95)
				border = Color(0.86, 0.88, 0.82, 0.58)
				font = Color(0.94, 0.96, 0.92, 1.0)
				border_width = 2
		elif action_style == "danger":
			bg = Color(0.095, 0.048, 0.046, 0.95)
			border = Color(0.9, 0.42, 0.36, 0.62)
			font = Color(0.98, 0.88, 0.84, 1.0)

	if surface_id == "restaurant_contract_hub":
		bg = Color(0.125, 0.072, 0.045, 0.95)
		border = Color(0.95, 0.66, 0.34, 0.58)
		font = Color(0.98, 0.92, 0.82, 1.0)
		glow = Color(1.0, 0.93, 0.76, 0.46)
		border_width = 2
		radius = 18
		if action_id.begins_with("restaurant_start") or action_id.begins_with("restaurant_category") or action_id.begins_with("restaurant_select"):
			bg = Color(0.145, 0.082, 0.045, 0.96)
			border = Color(0.98, 0.72, 0.4, 0.72)
			font = Color(0.99, 0.94, 0.86, 1.0)
		elif action_id.begins_with("restaurant_menu"):
			bg = Color(0.155, 0.09, 0.05, 0.96)
			border = Color(0.98, 0.76, 0.45, 0.74)
			font = Color(0.99, 0.95, 0.84, 1.0)
		elif action_style == "danger":
			bg = Color(0.12, 0.052, 0.038, 0.95)
			border = Color(0.92, 0.44, 0.34, 0.66)
			font = Color(0.99, 0.88, 0.82, 1.0)
		elif action_style == "secondary":
			bg = Color(0.09, 0.06, 0.045, 0.94)
			border = Color(0.92, 0.68, 0.45, 0.42)
			font = Color(0.98, 0.9, 0.78, 1.0)

	if compact_contract_section:
		radius = 12

	var normal_style: StyleBoxFlat = AppearanceSceneSupport._contract_make_stylebox(bg, border, border_width, radius)
	var hover_style: StyleBoxFlat = AppearanceSceneSupport._contract_make_stylebox(AppearanceSceneSupport._contract_brighten_color(bg, 0.035), glow, border_width + 1, radius)
	hover_style.shadow_color = glow
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2.ZERO

	var pressed_style: StyleBoxFlat = AppearanceSceneSupport._contract_make_stylebox(AppearanceSceneSupport._contract_darken_color(bg, 0.035), glow, border_width + 1, radius)
	pressed_style.shadow_color = glow
	pressed_style.shadow_size = 3
	pressed_style.shadow_offset = Vector2.ZERO

	var disabled_style: StyleBoxFlat = AppearanceSceneSupport._contract_make_stylebox(Color(bg.r, bg.g, bg.b, 0.45), Color(border.r, border.g, border.b, 0.2), border_width, radius)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", Color(min(font.r + 0.04, 1.0), min(font.g + 0.04, 1.0), min(font.b + 0.04, 1.0), 1.0))
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", Color(font.r, font.g, font.b, 0.45))
	if not compact_contract_section:
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size = Vector2(0, 38)


static func _append_stone_and_element_colored_text_to_rich_label(
	target_label: RichTextLabel,
	text: String,
	append_newline: bool = true
) -> void:
	if target_label == null:
		return

	var source_text: String = str(text)
	var phrase_variants: Array = [
		"4 Elements",
		"4 elements",
		"4 ELEMENTS"
	]

	var cursor: int = 0
	while cursor < source_text.length():
		var nearest_index: int = -1
		var nearest_phrase: String = ""

		for raw_phrase in phrase_variants:
			var phrase: String = str(raw_phrase)
			var found_index: int = source_text.find(phrase, cursor)
			if found_index == -1:
				continue
			if nearest_index == -1 or found_index < nearest_index:
				nearest_index = found_index
				nearest_phrase = phrase

		if nearest_index == -1:
			AppearanceSceneSupport._append_stone_colored_text_to_rich_label(
				target_label,
				source_text.substr(cursor),
				false
			)
			break

		if nearest_index > cursor:
			AppearanceSceneSupport._append_stone_colored_text_to_rich_label(
				target_label,
				source_text.substr(cursor, nearest_index - cursor),
				false
			)

		SupernaturalSceneSupport._append_avatar_four_elements_phrase(target_label, nearest_phrase)
		cursor = nearest_index + nearest_phrase.length()

	if append_newline:
		target_label.append_text("\n")


static func _era_border_theme_key_from_world(gs: GameState) -> String:
	if gs == null or gs.era == null:
		return "ancient"

	var era_name: String = str(gs.era.name).to_lower()

	if era_name.find("future") != -1:
		return "future"
	if era_name.find("modern") != -1 or era_name.find("industrial") != -1 or era_name.find("contemporary") != -1:
		return "modern"
	if era_name.find("medieval") != -1 or era_name.find("middle") != -1 or era_name.find("feudal") != -1:
		return "medieval"

	return "ancient"
