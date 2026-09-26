extends RefCounted
class_name EducationSceneSupport
## Education support for the main scene. State, when needed, is passed explicitly.


static func _school_hub_join_strings(values: Array, separator: String = ", ") -> String:
	var out: String = ""
	for i in range(values.size()):
		if i > 0:
			out += separator
		out += str(values [i])
	return out


static func _school_hub_parse_child_id_csv(raw_text: String) -> Array:
	var out: Array = []
	var parts: PackedStringArray = str(raw_text).split(",", false)
	for raw_part in parts:
		var child_id: int = int(str(raw_part).strip_edges())
		if child_id > 0 and not out.has(child_id):
			out.append(child_id)
	return out


static func _school_hub_friendliness_color(value: int) -> Color:
	var clean_value: int = clamp(int(value), 0, 100)
	var red:= Color(0.96, 0.16, 0.18, 1.0)
	var yellow:= Color(0.96, 0.84, 0.22, 1.0)
	var orange:= Color(0.98, 0.48, 0.16, 1.0)
	var green:= Color(0.18, 0.92, 0.38, 1.0)

	if clean_value >= 85:
		return green
	if clean_value >= 75:
		return orange.lerp(green, inverse_lerp(75.0, 85.0, float(clean_value)))
	if clean_value >= 50:
		return yellow.lerp(orange, inverse_lerp(50.0, 74.0, float(clean_value)))

	return red.lerp(yellow, inverse_lerp(0.0, 49.0, float(clean_value)))


static func _school_hub_friendliness_meta_key(title_text: String) -> String:
	var clean_title: String = str(title_text).strip_edges().to_lower()
	if clean_title == "":
		clean_title = "meal_space"
	clean_title = clean_title.replace(" ", "_").replace("/", "_").replace(":", "_")
	return "school_hub_friendliness_display_%s" % clean_title


static func _school_hub_apply_popularity_bar_visual(bar: ProgressBar) -> void:
	if bar == null:
		return

	var cyan:= Color(0.12, 0.9, 1.0, 1.0)

	var fill_style:= StyleBoxFlat.new()
	fill_style.bg_color = cyan
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8

	var background_style:= StyleBoxFlat.new()
	background_style.bg_color = Color(cyan.r, cyan.g, cyan.b, 0.13)
	background_style.border_color = Color(cyan.r, cyan.g, cyan.b, 0.28)
	background_style.border_width_left = 1
	background_style.border_width_top = 1
	background_style.border_width_right = 1
	background_style.border_width_bottom = 1
	background_style.corner_radius_top_left = 8
	background_style.corner_radius_top_right = 8
	background_style.corner_radius_bottom_left = 8
	background_style.corner_radius_bottom_right = 8

	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", background_style)


static func _school_hub_class_zone_key(class_zone: Dictionary) -> String:
	var zone_id: String = str(class_zone.get("zone_id", "")).strip_edges()
	if zone_id == "":
		zone_id = str(class_zone.get("name", "class")).strip_edges().to_lower().replace(" ", "_")
	if zone_id == "":
		zone_id = "class"
	return zone_id


static func _school_hub_add_mini_surface_bar(parent: Control, title_text: String, value: int, _danger: bool, _surface_context: Dictionary = {}) -> void:
	if parent == null:
		return

	var label:= Label.new()
	label.text = "%s: %d%%" % [title_text, clamp(value, 0, 100)]
	label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.96))
	label.add_theme_font_size_override("font_size", 11)
	parent.add_child(label)

	var bar:= ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = clamp(value, 0, 100)
	bar.custom_minimum_size = Vector2(0, 14)
	bar.show_percentage = false
	parent.add_child(bar)


static func _school_hub_people_label(count: int) -> String:
	if count == 1:
		return "1 person"
	return "%d people" % max(0, count)


static func _school_hub_add_population_contract_row(rows: Array, seen: Dictionary, row: Dictionary, role: String) -> void:
	var npc_id: int = int(row.get("person_id", -1))
	if npc_id <= 0 or seen.has(npc_id):
		return

	seen [npc_id] = true
	rows.append({
		"person_id": npc_id,
		"full_name": str(row.get("full_name", "Student")),
		"age": int(row.get("age", 0)),
		"role": role,
		"popularity": int(row.get("popularity", 0))
	})


static func _school_hub_popularity_for_person(npc: Person) -> int:
	if npc == null:
		return 0

	var score: float = 0.0
	score += float(npc.fame) * 0.3
	score += float(npc.respect) * 0.26
	score += float(npc.looks) * 0.16
	score += float(npc.smarts) * 0.12
	score += float(npc.satisfaction) * 0.08
	score += float(npc.mental_health) * 0.08
	return clamp(int(round(score)), 0, 100)


static func _school_hub_has_active_contract_for_player(gs: GameState) -> bool:
	if gs == null or gs.player == null or gs.school_engine == null:
		return false

	var p: Person = gs.player
	var school_name: String = str(p.school_name).strip_edges()
	var school_mode: String = str(p.school_mode).strip_edges()
	var school_status: String = str(p.school_status).strip_edges().to_lower()

	if school_name != "" and school_name != "None" and school_mode != "" and school_mode != "None" and school_status == "active":
		return true

	var snapshot: Dictionary = gs.school_engine.get_school_ecosystem_snapshot(p)
	var active_contract: Dictionary = ValueSceneSupport._safe_dictionary(snapshot.get("active_contract", {}))
	return not active_contract.is_empty()


static func _school_hub_get_enrollable_children_for_parent(gs: GameState,
	parent: Person) -> Array:
	if parent == null or gs == null or gs.school_engine == null:
		return []
	if not gs.school_engine.has_method("get_enrollable_children_for_parent"):
		return []
	return gs.school_engine.get_enrollable_children_for_parent(parent)


static func _school_hub_get_children_for_parent(gs: GameState,
	parent: Person) -> Array:
	if parent == null or gs == null or gs.school_engine == null:
		return []
	if gs.school_engine.has_method("get_children_for_parent"):
		return gs.school_engine.get_children_for_parent(parent)
	return EducationSceneSupport._school_hub_get_enrollable_children_for_parent(gs, parent)


static func _school_hub_child_id_csv(ids: Array) -> String:
	var parts: Array = []
	for raw_id in ids:
		var child_id: int = int(raw_id)
		if child_id > 0 and not parts.has(str(child_id)):
			parts.append(str(child_id))
	return EducationSceneSupport._school_hub_join_strings(parts, ",")


static func _school_hub_group_child_school_options(gs: GameState,
	children: Array) -> Array:
	var grouped: Dictionary = {}
	var order: Array = []

	if gs == null or gs.school_engine == null:
		return []

	for raw_child in children:
		var child: Person = raw_child
		if child == null:
			continue

		var child_options: Array = gs.school_engine.get_school_options_for(child)
		for raw_option in child_options:
			var option: Dictionary = ValueSceneSupport._safe_dictionary(raw_option)
			var contract: Dictionary = ValueSceneSupport._safe_dictionary(option.get("contract", {}))
			var school_name: String = str(option.get("name", "")).strip_edges()
			var school_type: String = str(option.get("type", "")).strip_edges()
			if school_name == "" or school_type == "":
				continue

			var group_key: String = "%s::%s" % [school_type, school_name]
			if not grouped.has(group_key):
				grouped [group_key] = {
					"type": school_type,
					"name": school_name,
					"contract": contract.duplicate(true),
					"child_ids": [],
					"child_names": []
				}
				order.append(group_key)

			var row: Dictionary = ValueSceneSupport._safe_dictionary(grouped.get(group_key, {}))
			var child_ids: Array = ValueSceneSupport._safe_array(row.get("child_ids", []))
			var child_names: Array = ValueSceneSupport._safe_array(row.get("child_names", []))

			if not child_ids.has(int(child.id)):
				child_ids.append(int(child.id))
				child_names.append("%s age %d" % [child.first_name, int(child.age)])

			row ["child_ids"] = child_ids
			row ["child_names"] = child_names
			grouped [group_key] = row

	var out: Array = []
	for raw_key in order:
		var key: String = str(raw_key)
		if grouped.has(key):
			out.append(ValueSceneSupport._safe_dictionary(grouped.get(key, {})))

	return out


static func _school_hub_friendliness_text_color(value: int) -> Color:
	var base: Color = EducationSceneSupport._school_hub_friendliness_color(value)
	return Color(base.r, base.g, base.b, 0.98)


static func _school_hub_apply_friendliness_bar_visual(bar: ProgressBar, value: int) -> void:
	if bar == null:
		return

	var clean_value: int = clamp(int(value), 0, 100)
	var fill_color: Color = EducationSceneSupport._school_hub_friendliness_color(clean_value)

	var fill_style:= StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_left = 8
	fill_style.corner_radius_bottom_right = 8

	var background_style:= StyleBoxFlat.new()
	background_style.bg_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.13)
	background_style.border_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.28)
	background_style.border_width_left = 1
	background_style.border_width_top = 1
	background_style.border_width_right = 1
	background_style.border_width_bottom = 1
	background_style.corner_radius_top_left = 8
	background_style.corner_radius_top_right = 8
	background_style.corner_radius_bottom_left = 8
	background_style.corner_radius_bottom_right = 8

	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_stylebox_override("background", background_style)


static func _school_hub_student_friendliness_for_row(gs: GameState,
	row: Dictionary) -> int:
	var clean_row: Dictionary = ValueSceneSupport._safe_dictionary(row)
	if clean_row.is_empty():
		return 50

	if clean_row.has("friendliness"):
		return clamp(int(clean_row.get("friendliness", 50)), 0, 100)

	if clean_row.has("friendliness_value"):
		return clamp(int(clean_row.get("friendliness_value", 50)), 0, 100)

	if clean_row.has("social_warmth"):
		return clamp(int(clean_row.get("social_warmth", 50)), 0, 100)

	var person_id: int = int(clean_row.get("person_id", -1))
	if gs != null and person_id > 0:
		var npc: Person = gs.get_or_reactivate_npc_by_id(person_id)
		if npc != null:
			var score: float = 50.0
			score += (float(npc.satisfaction) - 50.0) * 0.24
			score += (float(npc.mental_health) - 50.0) * 0.2
			score += (float(npc.respect) - 50.0) * 0.22
			score += (float(npc.happiness) - 50.0) * 0.18 if "happiness" in npc else 0.0
			score += (float(npc.health) - 50.0) * 0.08
			score += (float(npc.smarts) - 50.0) * 0.04
			return clamp(int(round(score)), 0, 100)

	var popularity: int = clamp(int(clean_row.get("popularity", 50)), 0, 100)
	return clamp(int(round(45.0 + (float(popularity) * 0.18))), 0, 100)


static func _school_hub_add_student_friendliness_bar(gs: GameState,
	box: VBoxContainer, row: Dictionary) -> void:
	if box == null:
		return

	var friendliness: int = EducationSceneSupport._school_hub_student_friendliness_for_row(gs, row)

	var friendliness_label:= Label.new()
	friendliness_label.text = "Friendliness %d%%" % friendliness
	friendliness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	friendliness_label.add_theme_font_size_override("font_size", 11)
	friendliness_label.add_theme_color_override("font_color", EducationSceneSupport._school_hub_friendliness_text_color(friendliness))
	box.add_child(friendliness_label)

	var friendliness_bar:= ProgressBar.new()
	friendliness_bar.min_value = 0
	friendliness_bar.max_value = 100
	friendliness_bar.value = friendliness
	friendliness_bar.custom_minimum_size = Vector2(0, 12)
	friendliness_bar.show_percentage = false
	friendliness_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	EducationSceneSupport._school_hub_apply_friendliness_bar_visual(friendliness_bar, friendliness)
	box.add_child(friendliness_bar)


static func _school_hub_meal_tab_label(gs: GameState) -> String:
	if gs == null or gs.player == null or gs.school_engine == null:
		return "Meal"

	var snapshot: Dictionary = gs.school_engine.get_school_ecosystem_snapshot(gs.player)
	var active_contract: Dictionary = ValueSceneSupport._safe_dictionary(snapshot.get("active_contract", {}))
	var meal_zone: Dictionary = ValueSceneSupport._safe_dictionary(snapshot.get("meal_zone", {}))
	var label_text: String = str(meal_zone.get("name", active_contract.get("meal_surface_label", "Meal"))).strip_edges()

	if label_text == "":
		return "Meal"

	return label_text


static func _school_hub_visible_classmate_count(classmates: Array, class_zones: Array, player: Person) -> int:
	var seen: Dictionary = {}

	for raw_classmate in classmates:
		var npc: Person = raw_classmate
		if npc == null:
			continue
		if player != null and int(npc.id) == int(player.id):
			continue
		seen [int(npc.id)] = true

	for raw_zone in class_zones:
		var class_zone: Dictionary = ValueSceneSupport._safe_dictionary(raw_zone)
		var students: Array = ValueSceneSupport._safe_array(class_zone.get("students", []))
		for raw_student in students:
			var row: Dictionary = ValueSceneSupport._safe_dictionary(raw_student)
			var student_id: int = int(row.get("person_id", -1))
			if student_id <= 0:
				continue
			if player != null and student_id == int(player.id):
				continue
			seen [student_id] = true

	return seen.size()


static func _school_hub_remaining_class_roster_rows(gs: GameState,
	class_zone: Dictionary) -> Array:
	var rows: Array = []
	var students: Array = ValueSceneSupport._safe_array(class_zone.get("students", []))
	if students.is_empty():
		return rows

	var preview_limit: int = int(class_zone.get("student_preview_limit", 10))
	preview_limit = int(clamp(preview_limit, 0, students.size()))

	for i in range(preview_limit, students.size()):
		var student_row: Dictionary = ValueSceneSupport._safe_dictionary(students [i])
		if student_row.is_empty():
			continue

		var person_id: int = int(student_row.get("person_id", -1))
		var popularity: int = int(student_row.get("popularity", 0))

		if popularity <= 0 and gs != null and person_id > 0:
			var npc: Person = gs.get_or_reactivate_npc_by_id(person_id)
			if npc != null:
				popularity = EducationSceneSupport._school_hub_popularity_for_person(npc)

		rows.append({
			"person_id": person_id,
			"full_name": str(student_row.get("full_name", "Student")),
			"age": int(student_row.get("age", 0)),
			"role": "Student • %s" % str(class_zone.get("name", "Class")),
			"popularity": popularity
		})

	return rows
