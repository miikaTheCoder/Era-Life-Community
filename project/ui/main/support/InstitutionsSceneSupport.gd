extends RefCounted
class_name InstitutionsSceneSupport
## Institutions support for the main scene. State, when needed, is passed explicitly.


static func _institution_hub_visual_control_for_row_data(row_data: Dictionary) -> Control:
	if row_data.has("card_surface"):
		return row_data.get("card_surface", null)
	if row_data.has("bar"):
		return row_data.get("bar", null)
	if row_data.has("label"):
		return row_data.get("label", null)
	return null


static func _resolve_institution_hub_stat_surface(title: String, value: int, max_value: int, surface_context: Dictionary) -> Dictionary:
	var safe_max: int = max(1, max_value)
	var safe_value: int = clamp(value, 0, safe_max)
	var ratio: float = clamp(float(safe_value) / float(safe_max), 0.0, 1.0)
	var descriptor: String = ""
	var flavor: String = ""

	match title:
		"Career Standing":
			if not bool(surface_context.get("career_active", false)):
				descriptor = "Unemployed"
				flavor = "You do not currently have a job, so your career standing is at zero."
			elif ratio >= 0.85:
				descriptor = "Established"
				flavor = "Your work footing feels secure, respected, and difficult to shake."
			elif ratio >= 0.65:
				descriptor = "Advancing"
				flavor = "Your career is moving with real traction and visible upward pull."
			elif ratio >= 0.45:
				descriptor = "Holding"
				flavor = "Your work position is stable enough, even if it is not dominating the room."
			elif ratio >= 0.25:
				descriptor = "Fragile"
				flavor = "Your career footing exists, but it does not feel fully protected."
			else:
				descriptor = "Precarious"
				flavor = "Your work life feels one bad turn from slipping sideways."
		"Career Pressure":
			if not bool(surface_context.get("career_active", false)):
				descriptor = "Clear"
				flavor = "You are not carrying workplace pressure right now."
			elif ratio >= 0.85:
				descriptor = "Crushing"
				flavor = "Work pressure is sitting on your chest and asking too much from too many directions."
			elif ratio >= 0.65:
				descriptor = "Strained"
				flavor = "Your work stress is real, persistent, and hard to completely shake."
			elif ratio >= 0.45:
				descriptor = "Busy"
				flavor = "There is pressure on the lane, but it still feels manageable."
			elif ratio >= 0.25:
				descriptor = "Managed"
				flavor = "You are carrying the demands of work without feeling swallowed by them."
			else:
				descriptor = "Clear"
				flavor = "Your career lane feels breathable right now."
		"School Standing":
			if not bool(surface_context.get("school_active", false)):
				descriptor = "Inactive"
				flavor = "You are outside formal school right now, so academic standing is not actively being pressed."
			elif ratio >= 0.85:
				descriptor = "Excelling"
				flavor = "Your academic position feels strong, visible, and hard to argue with."
			elif ratio >= 0.65:
				descriptor = "Strong"
				flavor = "You are holding solid footing in school with room to keep climbing."
			elif ratio >= 0.45:
				descriptor = "Steady"
				flavor = "Your school position is intact, even if it is not at the very top."
			elif ratio >= 0.25:
				descriptor = "Slipping"
				flavor = "Your academic footing is still there, but it feels easier to lose than before."
			else:
				descriptor = "At Risk"
				flavor = "Your school standing feels fragile and exposed."
		"School Pressure":
			if not bool(surface_context.get("school_active", false)):
				descriptor = "Clear"
				flavor = "With no active school lane, academic pressure is not the force shaping your day."
			elif ratio >= 0.85:
				descriptor = "Swamped"
				flavor = "School pressure is loud enough that it can crowd everything else in your head."
			elif ratio >= 0.65:
				descriptor = "Pressed"
				flavor = "The weight of school is building and refusing to stay in the background."
			elif ratio >= 0.45:
				descriptor = "Busy"
				flavor = "School is demanding, but the load still feels carryable."
			elif ratio >= 0.25:
				descriptor = "Manageable"
				flavor = "You are feeling the academic load without being buried by it."
			else:
				descriptor = "Light"
				flavor = "School pressure feels low and breathable right now."
		"Relationship Climate":
			if ratio >= 0.85:
				descriptor = "Connected"
				flavor = "Your relationship world feels warm, supported, and emotionally alive."
			elif ratio >= 0.65:
				descriptor = "Warm"
				flavor = "There is meaningful connection around you, even if it is not perfect on every side."
			elif ratio >= 0.45:
				descriptor = "Open"
				flavor = "Your social and family climate feels livable, even with some distance in the air."
			elif ratio >= 0.25:
				descriptor = "Strained"
				flavor = "Connection exists, but the emotional weather around you does not feel fully relaxed."
			else:
				descriptor = "Isolated"
				flavor = "Your relationship climate feels thin, quiet, and short on real support."
		_:
			descriptor = "%d" % safe_value
			flavor = ""

	return {
		"descriptor": descriptor,
		"flavor": flavor,
		"bar_text": "%d" % safe_value,
		"title_text": ""
	}


static func _institution_hub_inner_panel_style(kind: String) -> StyleBoxFlat:
	var clean_kind: String = str(kind).strip_edges().to_lower()
	var accent: Color = Color(0.42, 0.62, 1.0, 0.88)
	var top_color: Color = Color(0.03, 0.045, 0.085, 0.98)
	var base_color: Color = Color(0.015, 0.02, 0.04, 0.98)

	match clean_kind:
		"school":
			accent = Color(0.46, 0.72, 1.0, 0.92)
			top_color = Color(0.03, 0.07, 0.13, 0.98)
			base_color = Color(0.012, 0.024, 0.06, 0.98)
		"relationships":
			accent = Color(1.0, 0.48, 0.72, 0.9)
			top_color = Color(0.078, 0.03, 0.072, 0.98)
			base_color = Color(0.034, 0.014, 0.04, 0.98)
		"career":
			accent = Color(0.52, 0.92, 0.72, 0.88)
			top_color = Color(0.025, 0.08, 0.055, 0.98)
			base_color = Color(0.012, 0.036, 0.026, 0.98)

	var style:= StyleBoxFlat.new()
	style.bg_color = base_color.lerp(top_color, 0.36)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.62)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style


static func _style_institution_hub_action_button(btn: Button, kind: String) -> void:
	if btn == null:
		return

	var clean_kind: String = str(kind).strip_edges().to_lower()
	var accent: Color = Color(0.42, 0.62, 1.0, 0.88)
	var fill: Color = Color(0.045, 0.06, 0.105, 0.96)

	match clean_kind:
		"school":
			accent = Color(0.46, 0.72, 1.0, 0.92)
			fill = Color(0.04, 0.085, 0.155, 0.96)
		"relationships":
			accent = Color(1.0, 0.48, 0.72, 0.9)
			fill = Color(0.1, 0.04, 0.085, 0.96)
		"career":
			accent = Color(0.52, 0.92, 0.72, 0.88)
			fill = Color(0.04, 0.105, 0.07, 0.96)

	var normal:= StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.62)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 2)

	var hover:= normal.duplicate()
	hover.bg_color = fill.lerp(accent, 0.22)
	hover.border_color = accent

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 14)


static func _institution_hub_sections_for(gs: GameState,
	kind: String) -> Array:
	match kind:
		"career":
			return [
				{ "key": "overview", "label": "Overview"},
				{ "key": "actions", "label": "Actions"},
				{ "key": "jobs", "label": "Jobs"},
				{ "key": "workplace", "label": "Workplace"}
			]
		"school":
			if not EducationSceneSupport._school_hub_has_active_contract_for_player(gs):
				return []
			return [
				{ "key": "overview", "label": "Overview"},
				{ "key": "classes", "label": "Classes"},
				{ "key": "meal", "label": EducationSceneSupport._school_hub_meal_tab_label(gs)},
				{ "key": "teachers", "label": "Teachers"},
				{ "key": "social", "label": "Social"},
				{ "key": "actions", "label": "Actions"}
			]
		"relationships":
			return [
				{ "key": "family", "label": "Family"},
				{ "key": "ancestors", "label": "Ancestors"},
				{ "key": "household", "label": "MY HOUSEHOLD"},
				{ "key": "partner", "label": "Partner"},
				{ "key": "pets", "label": "PETS"},
				{ "key": "descendants", "label": "Descendants"},
				{ "key": "dead", "label": "Dead"},
				{ "key": "social", "label": "Social"},
				{ "key": "exes", "label": "Exes"}
			]
		_:
			return [
				{ "key": "overview", "label": "Overview"}
			]


static func _institution_hub_section_is_allowed(gs: GameState,
	kind: String, section: String) -> bool:
	var clean_section: String = str(section).strip_edges()
	if clean_section == "":
		return false

	var defs: Array = InstitutionsSceneSupport._institution_hub_sections_for(gs, str(kind).strip_edges().to_lower())
	for raw_def in defs:
		var def: Dictionary = raw_def
		if str(def.get("key", "")).strip_edges() == clean_section:
			return true

	return false


static func _build_institution_hub_stat_surface_context(gs: GameState,
	kind: String, person: Person) -> Dictionary:
	var clean_kind: String = str(kind).strip_edges().to_lower()
	var has_partner: bool = gs != null and gs.get_valid_partner(person, true, true) != null
	var school_active: bool = str(person.school_name).strip_edges() != ""
	var career_active: bool = str(person.job).strip_edges() != ""
	var workplace_active: bool = str(person.current_workplace_id).strip_edges() != ""
	return {
		"surface_family": "institution_hub",
		"institution_kind": clean_kind,
		"career_active": career_active,
		"school_active": school_active,
		"relationship_partnered": has_partner,
		"workplace_active": workplace_active
	}
