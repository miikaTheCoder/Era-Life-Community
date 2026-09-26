extends RefCounted
class_name CreationSceneSupport
## Creation support for the main scene. State, when needed, is passed explicitly.


static func _feature_overrides_for_mode(mode_text: String) -> Dictionary:
	match mode_text.to_lower():
		"realistic":
			return {
				"bending": false,
				"superpowers": false,
				"vampires": false,
				"artifacts": false,
				"supernatural_school": false,
				"supernatural_events": false
			}

		"enhanced":
			return {
				"bending": true,
				"superpowers": false,
				"vampires": false,
				"artifacts": false,
				"supernatural_school": true,
				"supernatural_events": true
			}

		_:
			return {
				"bending": true,
				"superpowers": true,
				"vampires": true,
				"artifacts": true,
				"supernatural_school": true,
				"supernatural_events": true
			}


static func _feature_override_keys() -> Array:
	return [
		"bending",
		"superpowers",
		"vampires",
		"artifacts",
		"dragonballs",
		"many_realms",
		"supernatural_school",
		"supernatural_events"
	]


static func _feature_override_label(feature_name: String) -> String:
	match feature_name:
		"bending":
			return "Bending"
		"superpowers":
			return "Super Powers"
		"vampires":
			return "Vampires"
		"artifacts":
			return "Artifacts"
		"dragonballs":
			return "Dragon Balls"
		"many_realms":
			return "Many Realms"
		"supernatural_school":
			return "Supernatural School"
		"supernatural_events":
			return "Supernatural Events"
		_:
			return feature_name.capitalize()


static func _build_god_mode_field_box_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	style.shadow_color = shadow_color
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 2)
	return style


static func _god_mode_scrollbar_idle_fade_delay_ms() -> int:
	return 120


static func _god_mode_panel_shaded_color(source: Color, rgb_scale: float, alpha: float = -1.0) -> Color:
	var out_alpha:= source.a if alpha < 0.0 else alpha
	return Color(
		clamp(source.r * rgb_scale, 0.0, 1.0),
		clamp(source.g * rgb_scale, 0.0, 1.0),
		clamp(source.b * rgb_scale, 0.0, 1.0),
		clamp(out_alpha, 0.0, 1.0)
	)


static func _god_mode_month_name(month_value: int) -> String:
	var month_names:= [
		"January",
		"February",
		"March",
		"April",
		"May",
		"June",
		"July",
		"August",
		"September",
		"October",
		"November",
		"December"
	]
	var clamped_value:= int(clamp(month_value, 1, 12))
	return month_names [clamped_value - 1]


static func _is_god_mode_leap_year(year_value: int) -> bool:
	var normalized_year:= year_value
	if normalized_year < 0:
		normalized_year += 1
	if normalized_year % 400 == 0:
		return true
	if normalized_year % 100 == 0:
		return false
	return normalized_year % 4 == 0


static func _selected_god_mode_option_value(button: OptionButton, fallback: int = 0) -> int:
	if button == null or button.item_count == 0:
		return fallback
	var idx:= button.get_selected_id()
	if idx < 0:
		idx = 0
	var metadata = button.get_item_metadata(idx)
	if typeof(metadata) == TYPE_INT or typeof(metadata) == TYPE_FLOAT:
		return int(metadata)
	var text:= button.get_item_text(idx)
	if text.is_valid_int():
		return int(text)
	return fallback


static func _style_god_mode_check_box(check_box: CheckBox) -> void:
	if check_box == null:
		return

	check_box.custom_minimum_size = Vector2(28, 28)
	check_box.scale = Vector2(1.08, 1.08)
	check_box.self_modulate = Color(1.0, 0.96, 1.0, 1.0)


static func _god_mode_elemental_country_visual_profile(country_text: String) -> Dictionary:
	var clean_country: String = str(country_text).strip_edges()
	var canonical: String = clean_country

	if clean_country in ["Northern Water Tribe", "Southern Water Tribe", "Water Tribe"]:
		canonical = "Water Tribe"
	elif clean_country in ["Northern Air Temple", "Southern Air Temple", "Eastern Air Temple", "Western Air Temple", "Air Nomads"]:
		canonical = "Air Nomads"

	match canonical:
		"Fire Nation":
			return {
				"nation": "Fire Nation",
				"core": Color(1.0, 0.3, 0.12, 1.0),
				"glow": Color(1.0, 0.62, 0.24, 0.86),
				"soft": Color(0.42, 0.08, 0.03, 0.92)
			}
		"Earth Kingdom":
			return {
				"nation": "Earth Kingdom",
				"core": Color(0.46, 0.86, 0.32, 1.0),
				"glow": Color(0.86, 1.0, 0.46, 0.82),
				"soft": Color(0.12, 0.3, 0.1, 0.92)
			}
		"Water Tribe":
			return {
				"nation": "Water Tribe",
				"core": Color(0.34, 0.72, 1.0, 1.0),
				"glow": Color(0.68, 0.92, 1.0, 0.86),
				"soft": Color(0.06, 0.16, 0.38, 0.92)
			}
		"Air Nomads":
			return {
				"nation": "Air Nomads",
				"core": Color(0.96, 0.92, 0.78, 1.0),
				"glow": Color(1.0, 0.98, 0.88, 0.86),
				"soft": Color(0.24, 0.22, 0.18, 0.82)
			}
		_:
			return {}


static func _build_god_mode_section_divider_style(line_color: Color, thickness: int = 2) -> StyleBoxLine:
	var style:= StyleBoxLine.new()
	style.color = line_color
	style.thickness = thickness
	style.grow_begin = 4.0
	style.grow_end = 4.0
	return style


static func _style_god_mode_value_label(value_label: Label) -> void:
	if value_label == null:
		return
	value_label.text = "0"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(54, 0)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8, 1.0))
	value_label.add_theme_font_size_override("font_size", 16)


static func _god_mode_back_to_main_menu_circle_button_size() -> int:
	return 54


static func _build_god_mode_circle_button_style(bg_color: Color, border_color: Color, shadow_color: Color, border_width: int = 2, shadow_size: int = 12) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color

	var circle_radius: int = 256
	style.corner_radius_top_left = circle_radius
	style.corner_radius_top_right = circle_radius
	style.corner_radius_bottom_right = circle_radius
	style.corner_radius_bottom_left = circle_radius

	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2.ZERO
	return style


static func _god_mode_palette_for_mode(mode_text: String, is_custom: bool = false) -> Dictionary:
	var palette:= {}

	match mode_text:
		"realistic":
			palette = {
				"panel_base": Color(0.08, 0.12, 0.16, 0.96),
				"panel_hover": Color(0.11, 0.16, 0.21, 0.98),
				"border": Color(0.62, 0.9, 0.82, 0.34),
				"border_hover": Color(0.84, 1.0, 0.94, 0.56),
				"shadow": Color(0.08, 0.18, 0.16, 0.2),
				"shadow_hover": Color(0.1, 0.26, 0.22, 0.3),
				"panel_modulate_idle": Color(0.98, 1.0, 0.99, 1.0),
				"panel_modulate_hover": Color(1.0, 1.0, 1.0, 1.0),
				"dim": Color(0.03, 0.06, 0.08, 0.94),
				"title": Color(0.95, 1.0, 0.97, 1.0),
				"subtitle": Color(0.88, 0.98, 0.93, 0.98),
				"body": Color(0.92, 0.98, 0.95, 0.88),
				"status": Color(0.82, 1.0, 0.9, 1.0),
				"preview": Color(0.94, 1.0, 0.96, 1.0),
				"accent": Color(0.56, 0.92, 0.78, 1.0),
				"accent_soft": Color(0.2, 0.33, 0.28, 0.96)
			}
		"enhanced":
			palette = {
				"panel_base": Color(0.17, 0.1, 0.27, 0.95),
				"panel_hover": Color(0.2, 0.12, 0.3, 0.97),
				"border": Color(0.82, 0.75, 0.98, 0.34),
				"border_hover": Color(0.92, 0.86, 1.0, 0.55),
				"shadow": Color(0.26, 0.12, 0.48, 0.22),
				"shadow_hover": Color(0.42, 0.22, 0.7, 0.3),
				"panel_modulate_idle": Color(0.98, 0.98, 1.0, 1.0),
				"panel_modulate_hover": Color(1.0, 1.0, 1.0, 1.0),
				"dim": Color(0.08, 0.02, 0.13, 0.94),
				"title": Color(1.0, 0.97, 0.9, 1.0),
				"subtitle": Color(0.98, 0.93, 1.0, 0.98),
				"body": Color(0.98, 0.95, 1.0, 0.86),
				"status": Color(0.86, 0.95, 1.0, 1.0),
				"preview": Color(1.0, 0.98, 0.9, 1.0),
				"accent": Color(0.86, 0.54, 1.0, 1.0),
				"accent_soft": Color(0.32, 0.16, 0.5, 0.98)
			}
		_:
			palette = {
				"panel_base": Color(0.25, 0.07, 0.17, 0.96),
				"panel_hover": Color(0.31, 0.09, 0.2, 0.98),
				"border": Color(1.0, 0.48, 0.72, 0.38),
				"border_hover": Color(1.0, 0.74, 0.86, 0.62),
				"shadow": Color(0.44, 0.1, 0.28, 0.24),
				"shadow_hover": Color(0.62, 0.16, 0.38, 0.34),
				"panel_modulate_idle": Color(1.0, 0.98, 0.99, 1.0),
				"panel_modulate_hover": Color(1.0, 1.0, 1.0, 1.0),
				"dim": Color(0.1, 0.01, 0.06, 0.95),
				"title": Color(1.0, 0.96, 0.92, 1.0),
				"subtitle": Color(1.0, 0.88, 0.93, 0.98),
				"body": Color(1.0, 0.93, 0.96, 0.88),
				"status": Color(1.0, 0.82, 0.92, 1.0),
				"preview": Color(1.0, 0.96, 0.92, 1.0),
				"accent": Color(1.0, 0.46, 0.76, 1.0),
				"accent_soft": Color(0.44, 0.14, 0.28, 0.98)
			}

	if is_custom:
		palette ["border"] = Color(1.0, 0.88, 0.6, 0.42)
		palette ["border_hover"] = Color(1.0, 0.95, 0.78, 0.68)
		palette ["status"] = Color(1.0, 0.92, 0.66, 1.0)
		palette ["accent"] = Color(1.0, 0.84, 0.48, 1.0)
		palette ["accent_soft"] = Color(0.36, 0.24, 0.1, 0.96)

	return palette


static func _is_god_mode_presentation_control(control: Control) -> bool:
	return control is Button or control is OptionButton or control is LineEdit or control is SpinBox or control is CheckBox


static func _god_mode_presenter_state_for(control: Control) -> String:
	if control == null:
		return "idle"
	var hovered:= bool(control.get_meta("god_mode_presenter_hovered", false))
	if control.has_focus():
		return "focus"
	if hovered:
		return "hover"
	return "idle"


static func _god_mode_subtitle_glitch_color_cycle() -> Array:
	return [
		Color(0.24, 0.86, 1.0, 1.0),
		Color(1.0, 0.78, 0.34, 1.0),
		Color(0.92, 0.44, 1.0, 1.0),
		Color(0.48, 1.0, 0.72, 1.0),
		Color(1.0, 0.34, 0.48, 1.0),
		Color(0.82, 0.7, 0.46, 1.0)
	]


static func _build_reality_mode_state_button_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	style.shadow_color = shadow_color
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 5)
	return style


static func _make_stat_slider(max_value: float) -> HSlider:
	var slider:= HSlider.new()
	slider.min_value = 0
	slider.max_value = max_value
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 28)
	slider.focus_mode = Control.FOCUS_CLICK
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return slider


static func _sync_single_stat_value_label(slider: HSlider, value_label: Label) -> void:
	if slider == null or value_label == null:
		return
	value_label.text = str(int(round(slider.value)))


static func _build_god_mode_slider_track_style(fill_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_right = 9
	style.corner_radius_bottom_left = 9
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = shadow_color
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 1)
	return style


static func _build_god_mode_slider_streak_style(fill_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = shadow_color
	style.shadow_size = 14
	style.shadow_offset = Vector2.ZERO
	return style


static func _get_god_mode_slider_palette(slider: HSlider) -> Dictionary:
	var stat_key:= ""
	if slider != null and slider.has_meta("god_mode_stat_key"):
		stat_key = str(slider.get_meta("god_mode_stat_key")).to_lower()

	match stat_key:
		"happiness":
			return {
				"core": Color(1.0, 0.82, 0.3, 1.0),
				"soft": Color(0.7, 0.46, 0.12, 0.98),
				"glow": Color(1.0, 0.76, 0.22, 0.24),
				"label": Color(1.0, 0.96, 0.82, 1.0)
			}
		"health":
			return {
				"core": Color(0.98, 0.34, 0.3, 1.0),
				"soft": Color(0.54, 0.14, 0.16, 0.98),
				"glow": Color(0.98, 0.34, 0.3, 0.24),
				"label": Color(1.0, 0.9, 0.88, 1.0)
			}
		"smarts":
			return {
				"core": Color(0.28, 0.72, 1.0, 1.0),
				"soft": Color(0.1, 0.28, 0.56, 0.98),
				"glow": Color(0.28, 0.72, 1.0, 0.24),
				"label": Color(0.9, 0.97, 1.0, 1.0)
			}
		"looks":
			return {
				"core": Color(1.0, 0.46, 0.78, 1.0),
				"soft": Color(0.58, 0.18, 0.42, 0.98),
				"glow": Color(1.0, 0.46, 0.78, 0.24),
				"label": Color(1.0, 0.92, 0.97, 1.0)
			}
		"mental_health":
			return {
				"core": Color(0.4, 0.92, 0.62, 1.0),
				"soft": Color(0.14, 0.4, 0.24, 0.98),
				"glow": Color(0.4, 0.92, 0.62, 0.24),
				"label": Color(0.92, 1.0, 0.94, 1.0)
			}
		"fertility":
			return {
				"core": Color(0.78, 0.48, 1.0, 1.0),
				"soft": Color(0.38, 0.18, 0.58, 0.98),
				"glow": Color(0.78, 0.48, 1.0, 0.24),
				"label": Color(0.96, 0.92, 1.0, 1.0)
			}
		"approval":
			return {
				"core": Color(1.0, 0.86, 0.58, 1.0),
				"soft": Color(0.46, 0.34, 0.18, 0.98),
				"glow": Color(1.0, 0.92, 0.7, 0.3),
				"label": Color(1.0, 0.96, 0.84, 1.0)
			}
		_:
			return {
				"core": Color(0.86, 0.54, 1.0, 1.0),
				"soft": Color(0.32, 0.16, 0.5, 0.98),
				"glow": Color(0.62, 0.28, 0.9, 0.24),
				"label": Color(1.0, 0.96, 0.8, 1.0)
			}


static func _clear_god_mode_slider_emotion_profile(slider: HSlider) -> void:
	if slider == null:
		return
	slider.set_meta("god_mode_emotion_profile", {})
	slider.set_meta("god_mode_last_value", float(slider.value))


static func _select_option_by_text(button: OptionButton, text: String) -> void:
	if button == null:
		return

	for i in range(button.item_count):
		if button.get_item_text(i).to_lower() == text.to_lower():
			button.select(i)
			return

	if button.item_count > 0:
		button.select(0)


static func _set_option_button_blank(button: OptionButton) -> void:
	if button == null:
		return

	button.clear()
	button.add_item("")
	button.select(0)


static func _parse_birth_year_text(raw_text: String) -> Dictionary:
	var text:= raw_text.strip_edges()

	if text == "" or text == "-" or text == "+":
		return { "valid": false}

	if not text.is_valid_int():
		return { "valid": false}

	return {
		"valid": true,
		"year": int(text)
	}


static func _option_button_has_text(button: OptionButton, wanted: String) -> bool:
	if button == null:
		return false
	for i in range(button.item_count):
		if button.get_item_text(i) == wanted:
			return true
	return false


static func _normalize_social_class_picker_value(value: String) -> String:
	var text:= str(value).strip_edges()
	if text in ["Royal", "Royal Court", "Imperial Court", "Pharaonic Court"]:
		return "Royal"
	if text in ["Noble", "Noble House", "Imperial Nobility", "Pharaonic Nobility"]:
		return "Noble"
	return text


static func _god_mode_reality_candidate_entry_kind(settings: Dictionary) -> String:
	var entry_kind: String = str(settings.get("_god_mode_entry_kind", settings.get("god_mode_entry_kind", "custom"))).strip_edges().to_lower()
	if entry_kind == "":
		entry_kind = "custom"
	return entry_kind


static func _god_mode_seed_contract_from_candidate(
	candidate: Dictionary
) -> Dictionary:
	var world_seed: int = int(
		candidate.get(
			"world_seed",
			-1
		)
	)

	return {
		"schema": "eralife.seed_contract",
		"version": 2,
		"seed": world_seed,
		"source": "god_mode_prebirth_reality_candidate",
		"candidate_id": str(
			candidate.get(
				"candidate_id",
				""
			)
		),
		"transaction_id": str(
			candidate.get(
				"transaction_id",
				""
			)
		),
		"transaction_sequence": int(
			candidate.get(
				"transaction_sequence",
				0
			)
		),
		"fresh_seed_commit": bool(
			candidate.get(
				"fresh_seed_commit",
				false
			)
		),
		"single_target_reality": true
	}


static func _god_mode_zero_frame_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.018, 0.06, 0.985)
	style.border_color = Color(0.3, 0.92, 1.0, 0.72)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


static func _household_creator_resolve_world_seed_from_settings(settings: Dictionary) -> int:
	var world_seed: int = int(settings.get("world_seed", -1))
	if world_seed > 0:
		return world_seed

	var seed_contract_raw: Variant = settings.get("seed_contract", {})
	if typeof(seed_contract_raw) == TYPE_DICTIONARY:
		world_seed = int((seed_contract_raw as Dictionary).get("seed", -1))
		if world_seed > 0:
			return world_seed

	var candidate_raw: Variant = settings.get("_prebirth_reality_candidate", {})
	if typeof(candidate_raw) == TYPE_DICTIONARY:
		world_seed = int((candidate_raw as Dictionary).get("world_seed", -1))
		if world_seed > 0:
			return world_seed

	return -1


static func _household_creator_unfinished_draft_button_text(draft: Dictionary) -> String:
	var overview_raw: Variant = draft.get("overview", {})
	var overview: Dictionary = overview_raw if typeof(overview_raw) == TYPE_DICTIONARY else {}

	var household_name: String = str(overview.get("household_name", "Unfinished Household")).strip_edges()
	if household_name == "":
		household_name = "Unfinished Household"

	var era_text: String = str(overview.get("era", "Modern")).strip_edges()
	var year_text: String = str(overview.get("year", "2000")).strip_edges()
	var country_text: String = str(overview.get("country", "")).strip_edges()
	var city_text: String = str(overview.get("city", "")).strip_edges()
	var member_count: int = int(overview.get("member_count", 0))
	var world_seed: int = int(overview.get("world_seed", -1))

	var location_text: String = city_text
	if country_text != "":
		location_text = "%s, %s" % [city_text, country_text] if city_text != "" else country_text

	if location_text == "":
		location_text = "No location"

	return "%s\n%s %s • %s • %d member%s • seed %d" % [
		household_name,
		era_text,
		year_text,
		location_text,
		member_count,
		"" if member_count == 1 else "s",
		world_seed
	]


static func _household_creator_unfinished_drafts_storage_path() -> String:
	return "user://eralife_unfinished_household_creation_contracts.json"


static func _household_creator_normalize_unfinished_drafts(raw_drafts: Array) -> Array:
	var drafts_by_id: Dictionary = {}
	var order: Array = []

	for raw_draft in raw_drafts:
		if typeof(raw_draft) != TYPE_DICTIONARY:
			continue

		var draft: Dictionary = (raw_draft as Dictionary).duplicate(true)
		var draft_id: String = str(draft.get("draft_id", "")).strip_edges()
		if draft_id == "":
			continue

		draft ["draft_id"] = draft_id

		if not draft.has("schema"):
			draft ["schema"] = "eralife.unfinished_household_creation_contract"

		if not draft.has("version"):
			draft ["version"] = 1

		if not order.has(draft_id):
			order.append(draft_id)

		drafts_by_id [draft_id] = draft

	var out: Array = []
	for raw_id in order:
		var clean_id: String = str(raw_id).strip_edges()
		if clean_id == "" or not drafts_by_id.has(clean_id):
			continue
		out.append((drafts_by_id [clean_id] as Dictionary).duplicate(true))

	return out


static func _household_creator_section_card(title_text: String) -> PanelContainer:
	var card:= PanelContainer.new()
	card.name = "HouseholdCreatorSection_%s" % title_text.replace(" ", "_")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.035, 0.02, 0.84)
	style.border_color = Color(1.0, 0.18, 0.04, 0.38)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	card.add_theme_stylebox_override("panel", style)

	var margin:= MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var body:= VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)

	var title:= Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.72, 1.0))
	body.add_child(title)

	card.set_meta("body", body)
	return card


static func _household_creator_style_choice_button(button: Button, selected: bool, accent: Color) -> void:
	if button == null or not is_instance_valid(button):
		return

	var normal:= StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.045, 0.028, 0.86) if selected else Color(0.14, 0.026, 0.018, 0.82)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.84 if selected else 0.34)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.shadow_color = Color(accent.r, accent.g, accent.b, 0.34 if selected else 0.1)
	normal.shadow_size = 24 if selected else 10

	var hover:= normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.28, 0.06, 0.035, 0.94)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.95)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.46)
	hover.shadow_size = 32

	var pressed:= normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.32, 0.07, 0.04, 0.98)
	pressed.shadow_size = 12
	pressed.content_margin_top = 3

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.72, 1.0))
	button.queue_redraw()


static func _household_creator_add_labeled_control(parent: Control, label_text: String, control: Control) -> void:
	var label:= Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.62, 0.84))
	parent.add_child(label)
	parent.add_child(control)

	if control != null and is_instance_valid(control):
		control.set_meta("household_creator_label", label)


static func _household_creator_array_has_text(values: Array, needle: String) -> bool:
	var clean_needle: String = str(needle).strip_edges().to_lower()
	if clean_needle == "":
		return false

	for raw_value in values:
		if str(raw_value).strip_edges().to_lower() == clean_needle:
			return true

	return false


static func _household_creator_dedupe_sorted_strings(values: Array) -> Array:
	var out: Array = []
	var seen:= {}

	for raw_value in values:
		var value: String = str(raw_value).strip_edges()
		if value == "":
			continue

		var key: String = value.to_lower()
		if seen.has(key):
			continue

		seen [key] = true
		out.append(value)

	out.sort()
	return out


static func _household_creator_selection_chip(title_text: String) -> PanelContainer:
	var chip:= PanelContainer.new()
	chip.name = "HouseholdCreatorSelectionChip_%s" % title_text.replace(" ", "_")
	chip.custom_minimum_size = Vector2(180, 64)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.018, 0.012, 0.92)
	style.border_color = Color(1.0, 0.24, 0.08, 0.54)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(1.0, 0.18, 0.05, 0.18)
	style.shadow_size = 10
	chip.add_theme_stylebox_override("panel", style)

	var margin:= MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	chip.add_child(margin)

	var box:= VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var title:= Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.48, 0.88))
	box.add_child(title)

	var value:= Label.new()
	value.text = "—"
	value.clip_text = true
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", Color(1.0, 0.88, 0.74, 1.0))
	box.add_child(value)

	chip.set_meta("value_label", value)
	return chip


static func _household_creator_life_stage_options() -> Array:
	return ["Baby", "Child", "Teen", "Adult", "Elder"]


static func _household_creator_set_labeled_control_visible(control: Control, visible_value: bool) -> void:
	if control == null or not is_instance_valid(control):
		return

	control.visible = visible_value

	var raw_label: Variant = control.get_meta("household_creator_label", null)
	if raw_label != null and raw_label is Control and is_instance_valid(raw_label):
		(raw_label as Control).visible = visible_value


static func _household_creator_member_key_from_anchor_label(label_text: String) -> String:
	var text: String = str(label_text)
	var start: int = text.rfind("[")
	var end: int = text.rfind("]")
	if start >= 0 and end > start:
		return text.substr(start + 1, end - start - 1).strip_edges()
	return ""


static func _household_creator_pretty_stat(stat_key: String) -> String:
	match stat_key:
		"mental_health":
			return "Mental"
		_:
			return stat_key.capitalize()


static func _household_creator_starting_money_for_class(class_text: String) -> int:
	var normalized: String = str(class_text).strip_edges().to_lower()
	match normalized:
		"royal":
			return 250000
		"noble":
			return 120000
		"wealthy":
			return 75000
		"middle class":
			return 10000
		"working class":
			return 3000
		"poor":
			return 250
		_:
			return 5000


static func _household_prewarm_signature_material(contract: Dictionary) -> String:
	var safe_contract: Dictionary = contract.duplicate(true)



	safe_contract.erase("start_person_key")

	var members_raw: Variant = safe_contract.get("members", [])
	if typeof(members_raw) == TYPE_ARRAY:
		var members: Array = []
		for raw_member in members_raw:
			if typeof(raw_member) != TYPE_DICTIONARY:
				continue
			var member: Dictionary = (raw_member as Dictionary).duplicate(true)
			member.erase("is_start_actor")
			members.append(member)
		safe_contract ["members"] = members

	return JSON.stringify(safe_contract)


static func _retire_god_mode_visual_authority_node(node: CanvasItem, reason: String) -> void:
	if node == null or not is_instance_valid(node):
		return

	node.visible = false
	node.z_as_relative = false
	node.z_index = -4096
	node.modulate = Color(node.modulate.r, node.modulate.g, node.modulate.b, 0.0)
	node.set_meta("god_mode_visual_authority_retired", true)
	node.set_meta("god_mode_visual_authority_retired_reason", reason)
	node.set_meta("god_mode_visual_authority_retired_at_ms", int(Time.get_ticks_msec()))

	var control:= node as Control
	if control != null:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.scale = Vector2.ONE


static func _retire_god_mode_visual_node_for_playable_life(node: CanvasItem, reason: String) -> void:
	if node == null or not is_instance_valid(node):
		return

	node.visible = false
	node.z_as_relative = false
	node.z_index = -4096
	node.modulate = Color(node.modulate.r, node.modulate.g, node.modulate.b, 0.0)
	node.set_meta("god_mode_visual_authority_retired", true)
	node.set_meta("god_mode_visual_authority_retired_reason", reason)
	node.set_meta("god_mode_visual_authority_retired_at_ms", int(Time.get_ticks_msec()))

	var control:= node as Control
	if control != null:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.scale = Vector2.ONE


static func _god_mode_life_prewarm_thread_worker(
	_candidate_settings: Dictionary,
	_reason: String,
	signature: String,
	_contract: Dictionary,
	_candidate: Dictionary,
	_seed_contract: Dictionary,
	_world_seed: int,
	_surface_rows: Array
) -> Dictionary:


	return {
		"success": false,
		"mode": (
			"threaded_game_state_construction_retired"
		),
		"reason": (
			"GameState construction now belongs to "
			+ "persistent main-thread residency microstages."
		),
		"signature": signature,
		"worker_thread_used": false,
		"ui_is_renderer_only": true
	}


static func _household_member_contract_for_key(contract: Dictionary, local_key: String) -> Dictionary:
	var members_raw: Variant = contract.get("members", [])
	var members: Array = members_raw if typeof(members_raw) == TYPE_ARRAY else []
	for raw_member in members:
		if typeof(raw_member) != TYPE_DICTIONARY:
			continue
		var member: Dictionary = raw_member as Dictionary
		if str(member.get("local_key", "")).strip_edges() == local_key:
			return member.duplicate(true)
	return {}


static func _god_mode_prewarm_should_tail_defer_heavy_surface_caches(prewarm_gs: GameState, settings: Dictionary = {}) -> bool:
	if prewarm_gs == null:
		return true

	if typeof(prewarm_gs.scenario_state) == TYPE_DICTIONARY:
		if bool(prewarm_gs.scenario_state.get("royalty_heavy_bootstrap_forbidden_during_prewarm", false)):
			return true
		if bool(prewarm_gs.scenario_state.get("royal_first_frame_shell_truth_only", false)):
			return true
		if bool(prewarm_gs.scenario_state.get("birth_shell_fast_first_paint", false)):
			return true

	var role_key: String = str(settings.get("royal_role", settings.get("social_role", ""))).strip_edges().to_lower()
	if role_key.find("prince") >= 0:
		return true
	if role_key.find("princess") >= 0:
		return true
	if role_key.find("king") >= 0:
		return true
	if role_key.find("queen") >= 0:
		return true
	if role_key.find("emperor") >= 0:
		return true
	if role_key.find("empress") >= 0:
		return true

	return false


static func _birth_entry_surge_headline(birth_boot_context: Dictionary = {}) -> String:
	var era_name: String = str(birth_boot_context.get("era_name", "")).strip_edges()
	if era_name == "":
		era_name = "EraLife"
	return "%s Reality Surge" % era_name


static func _god_mode_birth_normalized_social_class(settings: Dictionary) -> String:
	var raw_class: String = str(settings.get("social_class", settings.get("social_class_label", ""))).strip_edges()

	if raw_class in ["Royal", "Royal Court", "Imperial Court", "Pharaonic Court"]:
		return "Royal"

	if raw_class in ["Noble", "Noble House", "Imperial Nobility", "Pharaonic Nobility"]:
		return "Noble"

	if raw_class == "Upperclass":
		return "Upper Class"

	return raw_class


static func _god_mode_birth_safe_actor_number(actor: Person, property_name: String, fallback: float = 0.0) -> float:
	if actor == null:
		return fallback

	var clean_property: String = str(property_name).strip_edges()
	if clean_property == "":
		return fallback

	for raw_property in actor.get_property_list():
		if typeof(raw_property) != TYPE_DICTIONARY:
			continue

		var row: Dictionary = raw_property as Dictionary
		if str(row.get("name", "")).strip_edges() == clean_property:
			return float(actor.get(clean_property))

	return fallback


static func _canonical_reality_mode_key(mode_text: String) -> String:
	var clean_mode: String = str(mode_text).strip_edges().to_lower()

	if clean_mode == "":
		return "chaos"

	if clean_mode == "fantasy":
		return "chaos"

	if clean_mode in ["realistic", "enhanced", "chaos"]:
		return clean_mode

	return "chaos"


static func _canonical_feature_override_key(raw_key: Variant) -> String:
	var clean_key: String = str(raw_key).strip_edges().to_lower()
	clean_key = clean_key.replace("-", "_")
	clean_key = clean_key.replace(" ", "_")

	match clean_key:
		"bending":
			return "bending"
		"super_power", "super_powers", "superpower", "superpowers":
			return "superpowers"
		"vampire", "vampires":
			return "vampires"
		"artifact", "artifacts":
			return "artifacts"
		"dragon_ball", "dragon_balls", "dragonball", "dragonballs":
			return "dragonballs"
		"many_realm", "many_realms":
			return "many_realms"
		"supernatural_school":
			return "supernatural_school"
		"supernatural_event", "supernatural_events":
			return "supernatural_events"
		_:
			return ""


static func _custom_household_job_diary_line(_person: Person) -> String:
	return ""


static func _custom_household_relation_label_from_actor(actor_key: String, other_key: String, members_by_key: Dictionary) -> String:
	if actor_key == "" or other_key == "":
		return "household member"

	var other_member: Dictionary = members_by_key.get(other_key, {}) if typeof(members_by_key.get(other_key, {})) == TYPE_DICTIONARY else {}
	var other_anchor_key: String = str(other_member.get("relationship_anchor_key", "")).strip_edges()
	var other_relation_to_anchor: String = str(other_member.get("relationship_to_anchor", other_member.get("relationship_to_start", "household member"))).strip_edges().to_lower()

	if other_anchor_key == actor_key:
		return other_relation_to_anchor if other_relation_to_anchor != "" and other_relation_to_anchor != "none" else "household member"

	var actor_member: Dictionary = members_by_key.get(actor_key, {}) if typeof(members_by_key.get(actor_key, {})) == TYPE_DICTIONARY else {}
	var actor_anchor_key: String = str(actor_member.get("relationship_anchor_key", "")).strip_edges()
	var actor_relation_to_anchor: String = str(actor_member.get("relationship_to_anchor", actor_member.get("relationship_to_start", "household member"))).strip_edges().to_lower()

	if actor_anchor_key == other_key:
		match actor_relation_to_anchor:
			"mother":
				return "child"
			"father":
				return "child"
			"parent":
				return "child"
			"child", "son", "daughter":
				return "parent"
			"husband":
				return "wife"
			"wife":
				return "husband"
			"spouse":
				return "spouse"
			"brother", "sister", "sibling":
				return "sibling"
			"roommate":
				return "roommate"
			"friend":
				return "friend"
			"ex":
				return "ex"
			_:
				return "household member"

	return "household member"


static func _custom_household_is_birth_leak_diary_line(text: String) -> bool:
	var lower_text: String = str(text).strip_edges().to_lower()
	if lower_text == "":
		return true

	return lower_text.begins_with("i was born ") \
or lower_text.begins_with("i was conceived ") \
or lower_text.begins_with("before i was born") \
or lower_text.begins_with("before you had a name") \
or lower_text.begins_with("my soul was chosen ") \
or lower_text.begins_with("i was blessed to be born with ") \
or lower_text.begins_with("i was reincarnated as ") \
or lower_text.find(" was born with ") != -1 \
or lower_text.find(" birth class") != -1 \
or lower_text.find(" birth contract") != -1 \
or lower_text.find(" being born into ") != -1 \
or lower_text.find("you are being born") != -1 \
or lower_text.find("i was born touched by") != -1 \
or lower_text.begins_with("my birthday is ") \
or lower_text.begins_with("my father is ") \
or lower_text.begins_with("my mother is ") \
or lower_text.find("grandfather is ") != -1 \
or lower_text.find("grandmother is ") != -1 \
or lower_text.find("great-grandfather is ") != -1 \
or lower_text.find("great-grandmother is ") != -1


static func _format_birth_place_text(city: String, state: String, country: String) -> String:
	var clean_city: String = str(city).strip_edges()
	var clean_state: String = str(state).strip_edges()
	var clean_country: String = str(country).strip_edges()

	if clean_country.to_lower() in ["usa", "united states", "united states of america"]:
		clean_country = "USA"

	if clean_state != "":
		return "%s, %s, %s" % [clean_city, clean_state, clean_country]

	return "%s, %s" % [clean_city, clean_country]


static func _spawn_ready_primary_birth_actor_id(gs: GameState) -> int:
	if gs == null or gs.player == null:
		return -1
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return int(gs.player.id)

	var primary_id: int = int(gs.scenario_state.get("spawn_ready_primary_birth_actor_id", -1))
	if primary_id <= 0:
		primary_id = int(gs.scenario_state.get("birth_shell_player_id", -1))
	if primary_id <= 0:
		primary_id = int(gs.player.id)
		gs.scenario_state ["spawn_ready_primary_birth_actor_id"] = primary_id

	return primary_id


static func _spawn_ready_birth_intro_allowed_for_current_actor(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false
	return int(gs.player.id) == CreationSceneSupport._spawn_ready_primary_birth_actor_id(gs)


static func _other_country_browser_reality_mode_key(gs: GameState) -> String:
	if gs == null:
		return "unknown"

	var mode_key: String = str(gs.reality_mode).strip_edges().to_lower()
	if typeof(gs.custom_settings) == TYPE_DICTIONARY:
		mode_key = str(gs.custom_settings.get("reality_mode", mode_key)).strip_edges().to_lower()

	if mode_key == "":
		mode_key = "chaos"

	return mode_key


static func _other_country_surface_birth_locations_for_era(gs: GameState,
	era_key: String = "") -> Array:
	var out: Array = []
	var clean_era: String = str(era_key).strip_edges()

	if gs == null:
		return out

	var source_candidates: Array = []
	if "era_manager" in gs and gs.era_manager != null:
		source_candidates.append(gs.era_manager)
	if "era_engine" in gs and gs.era_engine != null:
		source_candidates.append(gs.era_engine)
	if "era" in gs and gs.era != null:
		source_candidates.append(gs.era)

	for source in source_candidates:
		var source_locations: Array = CreationSceneSupport._other_country_surface_birth_locations_from_source(source, clean_era)
		for raw_location in source_locations:
			if typeof(raw_location) != TYPE_DICTIONARY:
				continue
			var location: Dictionary = raw_location as Dictionary
			if not out.has(location):
				out.append(location)

	return out


static func _other_country_surface_birth_locations_from_source(source: Variant, era_key: String = "") -> Array:
	if source == null:
		return []

	if typeof(source) == TYPE_DICTIONARY:
		var source_dict: Dictionary = source as Dictionary
		var direct_locations: Array = ValueSceneSupport._safe_array(source_dict.get("birth_locations", []))
		if not direct_locations.is_empty():
			return direct_locations

		var keyed_locations: Array = ValueSceneSupport._safe_array(source_dict.get("locations", []))
		if not keyed_locations.is_empty():
			return keyed_locations

		var eras: Dictionary = ValueSceneSupport._safe_dictionary(source_dict.get("eras", {}))
		var clean_era: String = str(era_key).strip_edges()
		if clean_era != "" and eras.has(clean_era):
			var era_payload: Variant = eras.get(clean_era)
			if typeof(era_payload) == TYPE_DICTIONARY:
				return ValueSceneSupport._safe_array((era_payload as Dictionary).get("birth_locations", []))
			if typeof(era_payload) == TYPE_ARRAY:
				return era_payload as Array

		return []

	if typeof(source) != TYPE_OBJECT:
		return []

	if era_key != "" and source.has_method("get_birth_locations_for_era"):
		var era_locations: Variant = source.get_birth_locations_for_era(era_key)
		if typeof(era_locations) == TYPE_ARRAY:
			return era_locations as Array

	if source.has_method("get_birth_locations"):
		var locations: Variant = source.get_birth_locations()
		if typeof(locations) == TYPE_ARRAY:
			return locations as Array

	return []


static func _resolve_birth_relative_pair(gs: GameState,
	ids: Array) -> Array:
	var first: Person = null
	var second: Person = null
	var extras: Array = []

	for raw_id in ids:
		var rel: Person = gs.get_or_reactivate_npc_by_id(int(raw_id))
		if rel == null:
			continue

		if rel.gender == "Male" and first == null:
			first = rel
		elif rel.gender == "Female" and second == null:
			second = rel
		else:
			extras.append(rel)

	if first == null and extras.size() > 0:
		first = extras [0]

	if second == null:
		for extra in extras:
			if extra != first:
				second = extra
				break

	return [first, second]


static func _merged_feature_overrides_from_settings(gs: GameState) -> Dictionary:
	var saved_mode:= str(gs.custom_settings.get("reality_mode", "chaos")).to_lower()
	var merged:= CreationSceneSupport._feature_overrides_for_mode(saved_mode)

	var saved_overrides = gs.custom_settings.get("feature_overrides", {})
	if typeof(saved_overrides) == TYPE_DICTIONARY:
		for key in CreationSceneSupport._feature_override_keys():
			if saved_overrides.has(key):
				merged [key] = bool(saved_overrides [key])

	return merged


static func _god_mode_back_to_main_menu_circle_shell_size() -> int:
	return CreationSceneSupport._god_mode_back_to_main_menu_circle_button_size() + 22


static func _reality_mode_allows_elemental_birth_locations(mode_text: String) -> bool:
	var clean_mode: String = str(mode_text).strip_edges().to_lower()
	if clean_mode == "":
		clean_mode = "chaos"

	if clean_mode == "realistic":
		return false

	var overrides: Dictionary = CreationSceneSupport._feature_overrides_for_mode(clean_mode)
	return bool(overrides.get("bending", true))


static func _filter_birth_countries_for_reality_mode(countries: Array, mode_text: String) -> Array:
	if CreationSceneSupport._reality_mode_allows_elemental_birth_locations(mode_text):
		return countries.duplicate(true)

	var filtered: Array = []
	for raw_country in countries:
		var country_text: String = str(raw_country).strip_edges()
		if country_text == "":
			continue
		if WorldSceneSupport._is_elemental_nation_name(country_text):
			continue
		filtered.append(country_text)

	return filtered


static func _friendly_reality_mode_label(mode_text: String) -> String:
	match CreationSceneSupport._canonical_reality_mode_key(mode_text):
		"realistic":
			return "Realistic"
		"enhanced":
			return "Enhanced"
		"chaos":
			return "Chaos"
		_:
			return "Chaos"


static func _household_creator_load_unfinished_drafts_from_disk() -> Array:
	var path: String = CreationSceneSupport._household_creator_unfinished_drafts_storage_path()
	if not FileAccess.file_exists(path):
		return []

	var file:= FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open unfinished household draft storage: %s" % path)
		return []

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	var raw_drafts: Array = []

	if typeof(parsed) == TYPE_ARRAY:
		raw_drafts = parsed as Array
	elif typeof(parsed) == TYPE_DICTIONARY:
		var payload: Dictionary = parsed as Dictionary
		var drafts_raw: Variant = payload.get("drafts", payload.get("unfinished_household_creation_contracts", []))
		if typeof(drafts_raw) == TYPE_ARRAY:
			raw_drafts = drafts_raw as Array

	return CreationSceneSupport._household_creator_normalize_unfinished_drafts(raw_drafts)


static func _household_creator_save_unfinished_drafts_to_disk(drafts: Array) -> void:
	var normalized_drafts: Array = CreationSceneSupport._household_creator_normalize_unfinished_drafts(drafts)
	var payload: Dictionary = {
		"schema": "eralife.unfinished_household_creation_contract_storage",
		"version": 1,
		"storage_key": "unfinished_household_creation_contracts",
		"drafts": normalized_drafts.duplicate(true),
		"saved_at_ms": int(Time.get_ticks_msec()),
		"saved_at_unix": int(Time.get_unix_time_from_system())
	}

	var path: String = CreationSceneSupport._household_creator_unfinished_drafts_storage_path()
	var file:= FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write unfinished household draft storage: %s" % path)
		return

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


static func _household_creator_unfinished_drafts(gs: GameState) -> Array:
	var disk_drafts: Array = CreationSceneSupport._household_creator_load_unfinished_drafts_from_disk()
	var session_drafts: Array = []

	if gs != null:
		if typeof(gs.scenario_state) != TYPE_DICTIONARY:
			gs.scenario_state = {}

		var raw: Variant = gs.scenario_state.get("unfinished_household_creation_contracts", [])
		if typeof(raw) == TYPE_ARRAY:
			session_drafts = raw as Array
		else:
			gs.scenario_state ["unfinished_household_creation_contracts"] = []

	var merged: Array = []
	merged.append_array(disk_drafts)
	merged.append_array(session_drafts)

	var normalized: Array = CreationSceneSupport._household_creator_normalize_unfinished_drafts(merged)

	if gs != null:
		gs.scenario_state ["unfinished_household_creation_contracts"] = normalized.duplicate(true)

	if disk_drafts.is_empty() and not session_drafts.is_empty() and not normalized.is_empty():
		CreationSceneSupport._household_creator_save_unfinished_drafts_to_disk(normalized)

	return normalized.duplicate(true)


static func _household_creator_store_unfinished_draft(gs: GameState,
	draft: Dictionary) -> void:
	var draft_id: String = str(draft.get("draft_id", "")).strip_edges()
	if draft_id == "":
		return

	var drafts: Array = CreationSceneSupport._household_creator_unfinished_drafts(gs)
	var replaced: bool = false

	for i in range(drafts.size()):
		if typeof(drafts [i]) != TYPE_DICTIONARY:
			continue

		if str((drafts [i] as Dictionary).get("draft_id", "")).strip_edges() == draft_id:
			drafts [i] = draft.duplicate(true)
			replaced = true
			break

	if not replaced:
		drafts.append(draft.duplicate(true))

	drafts = CreationSceneSupport._household_creator_normalize_unfinished_drafts(drafts)

	if gs != null:
		if typeof(gs.scenario_state) != TYPE_DICTIONARY:
			gs.scenario_state = {}
		gs.scenario_state ["unfinished_household_creation_contracts"] = drafts.duplicate(true)

	CreationSceneSupport._household_creator_save_unfinished_drafts_to_disk(drafts)


static func _household_creator_remove_unfinished_draft(gs: GameState,
	draft_id: String) -> void:
	var clean_id: String = str(draft_id).strip_edges()
	if clean_id == "":
		return

	var drafts: Array = CreationSceneSupport._household_creator_unfinished_drafts(gs)
	var kept: Array = []

	for raw_draft in drafts:
		if typeof(raw_draft) != TYPE_DICTIONARY:
			continue

		var draft: Dictionary = raw_draft as Dictionary
		if str(draft.get("draft_id", "")).strip_edges() == clean_id:
			continue

		kept.append(draft.duplicate(true))

	kept = CreationSceneSupport._household_creator_normalize_unfinished_drafts(kept)

	if gs != null:
		if typeof(gs.scenario_state) != TYPE_DICTIONARY:
			gs.scenario_state = {}
		gs.scenario_state ["unfinished_household_creation_contracts"] = kept.duplicate(true)

	CreationSceneSupport._household_creator_save_unfinished_drafts_to_disk(kept)


static func _ensure_family_creation_contract_engine(gs: GameState) -> void:
	if gs == null:
		return
	if gs.family_creation_contract_engine == null:
		gs.family_creation_contract_engine = FamilyCreationContractEngine.new(gs)


static func _household_creator_house_type_options_for(gs: GameState,
	default_class: String, era_key: String) -> Array:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)

	if gs != null and gs.family_creation_contract_engine != null:
		return gs.family_creation_contract_engine.house_type_options_for(era_key, default_class)

	return ["Family home", "Apartment", "Townhouse"]


static func _household_creator_validate_world_contract(gs: GameState,
	world_contract: Dictionary) -> Dictionary:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null:
		return gs.family_creation_contract_engine.validate_world_contract(world_contract)

	for key in ["era", "year", "reality_mode", "default_social_class", "house_type", "country", "city"]:
		if str(world_contract.get(key, "")).strip_edges() == "":
			return {
				"success": false,
				"reason": "Select %s first." % key
			}

	return {
		"success": true,
		"reason": "World contract valid."
	}


static func _household_creator_life_stage_for_age(gs: GameState,
	age_value: int) -> String:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null:
		return gs.family_creation_contract_engine.life_stage_for_age(age_value)

	if age_value <= 1:
		return "Baby"
	if age_value <= 12:
		return "Child"
	if age_value <= 17:
		return "Teen"
	if age_value <= 64:
		return "Adult"
	return "Elder"


static func _household_creator_member_requires_job(gs: GameState,
	age_value: int) -> bool:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null and gs.family_creation_contract_engine.has_method("member_requires_job"):
		return bool(gs.family_creation_contract_engine.member_requires_job(age_value))

	return int(age_value) >= 18


static func _household_creator_life_stage_age_range(gs: GameState,
	stage_text: String) -> Dictionary:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null and gs.family_creation_contract_engine.has_method("life_stage_age_range"):
		return gs.family_creation_contract_engine.life_stage_age_range(stage_text)

	var stage: String = str(stage_text).strip_edges().to_lower()
	match stage:
		"baby":
			return { "min": 0, "max": 1, "default": 0}
		"child":
			return { "min": 2, "max": 12, "default": 8}
		"teen":
			return { "min": 13, "max": 17, "default": 16}
		"elder":
			return { "min": 65, "max": 130, "default": 70}
		_:
			return { "min": 18, "max": 64, "default": 25}


static func _god_mode_birth_actor_display_name(actor: Person, settings: Dictionary = {}) -> String:
	var first_name: String = str(settings.get("first_name", "")).strip_edges()
	var last_name: String = str(settings.get("last_name", "")).strip_edges()

	if first_name == "" and actor != null:
		first_name = str(actor.first_name).strip_edges()

	if last_name == "" and actor != null:
		last_name = str(actor.last_name).strip_edges()

	var full_name: String = ("%s %s" % [first_name, last_name]).strip_edges()
	if full_name == "" or full_name.to_lower() == "unknown":
		full_name = ValueSceneSupport._person_display_name_for_identity_switch(actor)

	if full_name == "" or full_name.to_lower() == "unknown":
		full_name = "Acrello IsBack"

	return full_name


static func _god_mode_birth_surface_lock_active(gs: GameState,
	_reason: String = "god_mode_birth_surface_lock") -> bool:
	if gs == null or gs.player == null:
		return false

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return false

	if not bool(gs.scenario_state.get("god_mode_birth_surface_lock_active", false)):
		return false

	var locked_actor_id: int = int(gs.scenario_state.get("god_mode_birth_surface_lock_actor_id", -1))
	if locked_actor_id > 0 and locked_actor_id != int(gs.player.id):
		gs.scenario_state ["god_mode_birth_surface_lock_active"] = false
		return false

	var until_ms: int = int(gs.scenario_state.get("god_mode_birth_surface_lock_until_ms", 0))
	if until_ms > 0 and int(Time.get_ticks_msec()) > until_ms:
		gs.scenario_state ["god_mode_birth_surface_lock_active"] = false
		return false

	return true


static func _feature_overrides_match_mode(mode_text: String, overrides: Dictionary) -> bool:
	var preset:= CreationSceneSupport._feature_overrides_for_mode(mode_text)

	for key in CreationSceneSupport._feature_override_keys():
		if bool(overrides.get(key, false)) != bool(preset.get(key, false)):
			return false

	return true


static func _normalize_feature_overrides_for_reality_mode(mode_text: String, raw_overrides: Variant) -> Dictionary:
	var clean_mode: String = CreationSceneSupport._canonical_reality_mode_key(mode_text)
	var out: Dictionary = CreationSceneSupport._feature_overrides_for_mode(clean_mode)

	if typeof(raw_overrides) != TYPE_DICTIONARY:
		return out

	var raw: Dictionary = (raw_overrides as Dictionary).duplicate(true)

	for raw_key in raw.keys():
		var canonical_key: String = CreationSceneSupport._canonical_feature_override_key(raw_key)
		if canonical_key == "":
			continue

		out [canonical_key] = bool(raw.get(raw_key, out.get(canonical_key, false)))

	return out


static func _canonicalize_god_mode_reality_settings(settings: Dictionary, reason: String = "god_mode_reality_settings") -> Dictionary:
	var out: Dictionary = settings.duplicate(true)

	var clean_mode: String = CreationSceneSupport._canonical_reality_mode_key(out.get("reality_mode", "chaos"))
	var normalized_overrides: Dictionary = CreationSceneSupport._normalize_feature_overrides_for_reality_mode(
		clean_mode,
		out.get("feature_overrides", {})
	)

	out ["reality_mode"] = clean_mode
	out ["feature_overrides"] = normalized_overrides.duplicate(true)
	out ["reality_mode_label"] = CreationSceneSupport._friendly_reality_mode_label(clean_mode) if CreationSceneSupport._feature_overrides_match_mode(clean_mode, normalized_overrides) else "Custom"
	out ["reality_mode_authority"] = "god_mode_canonical_reality_contract"
	out ["reality_mode_canonicalized_reason"] = reason
	out ["reality_mode_canonicalized_at_ms"] = int(Time.get_ticks_msec())
	out ["fantasy_alias_is_chaos"] = true

	return out


static func _display_reality_mode_label_from_settings(settings: Dictionary) -> String:
	var clean_mode: String = CreationSceneSupport._canonical_reality_mode_key(settings.get("reality_mode", "chaos"))
	var overrides: Dictionary = CreationSceneSupport._normalize_feature_overrides_for_reality_mode(
		clean_mode,
		settings.get("feature_overrides", {})
	)

	if not CreationSceneSupport._feature_overrides_match_mode(clean_mode, overrides):
		return "Custom"

	return CreationSceneSupport._friendly_reality_mode_label(clean_mode)


static func _is_secret_superpower_birth_identity_line(text: String) -> bool:
	var clean_text: String = DiarySceneSupport._compact_diary_text(text)
	if clean_text == "":
		return false

	var lower_text: String = clean_text.to_lower()
	return lower_text.find("what you see is not what you get") != -1 \
or lower_text.find("what i see is not what i get") != -1


static func _custom_household_member_display_job(member: Person) -> String:
	if member == null:
		return "unemployed"

	var job_name: String = str(member.job).strip_edges()
	if job_name == "":
		return "unemployed"
	return "%s %s" % [ValueSceneSupport._article_for_phrase(job_name), job_name]


static func _player_has_secret_superpower_birth_identity(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	var has_power: bool = false
	if gs.power_engine != null and gs.power_engine.has_method("has_superpowers"):
		has_power = gs.power_engine.has_superpowers(gs.player)

	if not has_power:
		return false

	var config: Dictionary = {}
	if typeof(gs.custom_settings) == TYPE_DICTIONARY:
		var config_raw: Variant = gs.custom_settings.get("superpower_configurator", {})
		if typeof(config_raw) == TYPE_DICTIONARY:
			config = (config_raw as Dictionary).duplicate(true)

	var public_identity: String = str(config.get("public_identity", "")).strip_edges().to_lower()
	if public_identity == "secret":
		return true

	if gs.power_engine != null and gs.power_engine.has_method("get_person_power_state"):
		var power_state: Dictionary = gs.power_engine.get_person_power_state(gs.player)
		return not bool(power_state.get("public_power_known", false))

	return false
