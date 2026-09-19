extends RefCounted
class_name PopulationSceneSupport
## Population support for the main scene. State, when needed, is passed explicitly.


static func _crown_population_element_color(element: String, fallback: Color = Color(1.0, 0.84, 0.36, 1.0)) -> Color:
	match str(element).strip_edges().to_lower():
		"fire":
			return Color(1.0, 0.28, 0.12, 1.0)
		"water":
			return Color(0.2, 0.62, 1.0, 1.0)
		"earth":
			return Color(0.55, 0.82, 0.36, 1.0)
		"air":
			return Color(0.86, 0.92, 1.0, 1.0)
		_:
			return fallback


static func _crown_population_button_style(bg: Color, border: Color, hover: bool = false, disabled: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 2 if hover else 1
	style.border_width_top = 2 if hover else 1
	style.border_width_right = 2 if hover else 1
	style.border_width_bottom = 2 if hover else 1
	style.border_color = border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 8
	style.content_margin_top = 5
	style.content_margin_right = 8
	style.content_margin_bottom = 5

	if disabled:
		style.bg_color = style.bg_color.darkened(0.25)
		style.border_color = Color(1.0, 0.92, 0.5, 0.66)

	return style


static func _style_crown_population_scrollbar(scroll: ScrollContainer, accent: Color) -> void:
	if scroll == null:
		return

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true

	var vbar:= scroll.get_v_scroll_bar()
	if vbar == null:
		return

	vbar.custom_minimum_size = Vector2(12, 0)

	var track:= StyleBoxFlat.new()
	track.bg_color = Color(accent.r * 0.045, accent.g * 0.04, accent.b * 0.052, 0.7)
	track.border_width_left = 1
	track.border_width_right = 1
	track.border_color = Color(accent.r, accent.g, accent.b, 0.22)
	track.corner_radius_top_left = 8
	track.corner_radius_top_right = 8
	track.corner_radius_bottom_left = 8
	track.corner_radius_bottom_right = 8

	var grabber:= StyleBoxFlat.new()
	grabber.bg_color = Color(accent.r, accent.g, accent.b, 0.62)
	grabber.border_width_left = 1
	grabber.border_width_top = 1
	grabber.border_width_right = 1
	grabber.border_width_bottom = 1
	grabber.border_color = Color(1.0, 0.92, 0.72, 0.74)
	grabber.corner_radius_top_left = 8
	grabber.corner_radius_top_right = 8
	grabber.corner_radius_bottom_left = 8
	grabber.corner_radius_bottom_right = 8

	var grabber_hover:= grabber.duplicate() as StyleBoxFlat
	grabber_hover.bg_color = Color(1.0, 0.91, 0.7, 0.88)
	grabber_hover.border_color = Color(1.0, 0.96, 0.82, 1.0)

	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hover)


static func _crown_population_bloodline_key(target: Person) -> String:
	if target == null:
		return "unknown"

	var dynasty_text: String = str(target.dynasty_origin).strip_edges()
	if dynasty_text != "":
		return dynasty_text

	var last_name_text: String = str(target.last_name).strip_edges()
	if last_name_text != "":
		return last_name_text

	return "entity_%d" % int(target.id)


static func _crown_population_observable_node_display_name(node: Dictionary) -> String:
	var direct_name: String = str(node.get("name", node.get("display_name", ""))).strip_edges()
	if direct_name != "":
		return direct_name

	var first_name: String = str(node.get("first_name", "")).strip_edges()
	var last_name: String = str(node.get("last_name", "")).strip_edges()
	var full_name: String = "%s %s" % [first_name, last_name]
	full_name = full_name.strip_edges()

	if full_name != "":
		return full_name

	var person_id: int = int(node.get("id", node.get("person_id", -1)))
	if person_id > 0:
		return "Observable Person %d" % person_id

	return "Observable Person"


static func _crown_population_observable_node_role_label(
	node: Dictionary,
	section_kind: String
) -> String:
	var role_text: String = ""

	for raw_value in [
		node.get(
			"job",
			""
		),
		node.get(
			"civic_title",
			""
		),
		node.get(
			"role_label",
			""
		),
		node.get(
			"royal_title",
			""
		)
	]:
		var candidate: String = str(
			raw_value
		).strip_edges()

		if candidate != "":
			role_text = candidate
			break

	if role_text == "":
		var contract_raw: Variant = node.get(
			"civic_office_contract",
			{}
		)

		if typeof(contract_raw) == TYPE_DICTIONARY:
			var contract: Dictionary = (
				contract_raw as Dictionary
			)

			role_text = str(
				contract.get(
					"role_label",
					contract.get(
						"office",
						""
					)
				)
			).strip_edges()

	if role_text == "":
		match str(
			section_kind
		).strip_edges().to_lower():
			"sovereign":
				role_text = "Sovereign"

			"royal_court":
				role_text = "Royal Court"

			"noble_court":
				role_text = "Noble Court"

			"executive", \
"federal_executive", \
"federal_cabinet":
				role_text = "Executive Official"

			"legislative", \
"federal_legislative", \
"federal_senate":
				role_text = "Legislator"

			"judicial", \
"federal_judicial", \
"federal_supreme_court":
				role_text = "Judicial Official"

			"military_command":
				role_text = "Military Command"

			"masters":
				role_text = "Master"

			"citizen":
				role_text = "Citizen"

			_:
				role_text = "Population Node"

	var city: String = str(
		node.get(
			"home_city",
			node.get(
				"birth_city",
				""
			)
		)
	).strip_edges()

	if city != "":
		return "%s • %s" % [
			role_text,
			city
		]

	return role_text


static func _crown_population_entity_id_for_person(target: Person) -> String:
	if target == null:
		return ""
	return "human:%d" % int(target.id)


static func _collect_crown_population_graph_nodes_from_surface(root: Node, out: Dictionary) -> void:
	if root == null:
		return

	if root is PanelContainer and root.has_meta("crown_population_graph_node_contract"):
		var node_raw: Variant = root.get_meta("crown_population_graph_node_contract", {})
		if typeof(node_raw) == TYPE_DICTIONARY:
			var node_contract: Dictionary = node_raw
			var entity_id: String = str(node_contract.get("entity_id", "")).strip_edges()
			if entity_id != "":
				node_contract ["card"] = root
				out [entity_id] = node_contract

	for child in root.get_children():
		PopulationSceneSupport._collect_crown_population_graph_nodes_from_surface(child, out)


static func _register_crown_population_graph_node_tween(graph_node: Node, tween: Tween) -> void:
	if graph_node == null or not is_instance_valid(graph_node):
		return

	if tween == null or not tween.is_valid():
		return

	var tweens_raw: Variant = graph_node.get_meta("crown_population_graph_tweens", [])
	var tweens: Array = tweens_raw if typeof(tweens_raw) == TYPE_ARRAY else []

	tweens.append(tween)
	graph_node.set_meta("crown_population_graph_tweens", tweens)


static func _kill_crown_population_graph_node_tweens(graph_node: Node) -> void:
	if graph_node == null or not is_instance_valid(graph_node):
		return

	var tweens_raw: Variant = graph_node.get_meta("crown_population_graph_tweens", [])
	if typeof(tweens_raw) != TYPE_ARRAY:
		return

	var tweens: Array = tweens_raw
	for raw_tween in tweens:
		if raw_tween is Tween:
			var tween: Tween = raw_tween
			if tween.is_valid():
				tween.kill()

	graph_node.set_meta("crown_population_graph_tweens", [])


static func _crown_population_graph_edge_lod_score(raw_edge: Variant) -> float:
	if typeof(raw_edge) != TYPE_DICTIONARY:
		return 0.0

	var edge: Dictionary = raw_edge
	var line_kind: String = str(edge.get("line_kind", "relationship")).strip_edges().to_lower()
	var bond: float = float(clampi(int(edge.get("bond", 50)), 0, 100))
	var weight: float = float(edge.get("weight", 1.0))
	var importance_weight: float = float(edge.get("importance_weight", -1.0))

	if importance_weight < 0.0:
		var tags: Array = edge.get("tags", []) if typeof(edge.get("tags", [])) == TYPE_ARRAY else []
		var label: String = str(edge.get("relationship_label", edge.get("label", ""))).strip_edges().to_lower()

		match line_kind:
			"succession_heir":
				importance_weight = 1.0
			"family":
				if tags.has("parent") or tags.has("child") or label in ["parent", "child", "mother", "father", "son", "daughter"]:
					importance_weight = 0.97
				else:
					importance_weight = 0.88
			"romance":
				importance_weight = 0.92
			"conflict":
				importance_weight = 0.84
			"political":
				importance_weight = 0.76
			"house":
				importance_weight = 0.7
			"economic":
				importance_weight = 0.58
			"social":
				importance_weight = 0.46
			"civic":
				importance_weight = 0.34
			_:
				importance_weight = 0.22

	var kind_bonus: float = 0.0
	match line_kind:
		"succession_heir":
			kind_bonus = 68.0
		"family":
			kind_bonus = 48.0
		"romance":
			kind_bonus = 44.0
		"conflict":
			kind_bonus = 42.0
		"political":
			kind_bonus = 34.0
		"house":
			kind_bonus = 28.0
		"economic":
			kind_bonus = 22.0
		"social":
			kind_bonus = 16.0
		"civic":
			kind_bonus = 10.0
		_:
			kind_bonus = 0.0

	return bond + kind_bonus + (weight * 8.0) + (importance_weight * 45.0)


static func _crown_population_graph_card_rect_in_layer(card: Control, layer: Control) -> Rect2:
	if card == null or layer == null:
		return Rect2()

	if not is_instance_valid(card) or not is_instance_valid(layer):
		return Rect2()

	if not card.is_visible_in_tree():
		return Rect2()

	var layer_rect: Rect2 = layer.get_global_rect()
	var card_rect: Rect2 = card.get_global_rect()
	card_rect.position = card_rect.position - layer_rect.position

	return card_rect


static func _crown_population_graph_edge_width(edge: Dictionary) -> float:
	var bond: int = clampi(int(edge.get("bond", 50)), 0, 100)
	var contract_weight: float = float(edge.get("weight", 2.0))
	var importance_weight: float = float(edge.get("importance_weight", 0.22))
	var line_kind: String = str(edge.get("line_kind", "relationship")).strip_edges().to_lower()

	var width: float = 1.15 + (float(bond) / 28.0) + (contract_weight * 0.2) + (importance_weight * 0.85)

	match line_kind:
		"succession_heir":
			width += 1.2
		"family":
			width += 0.82
		"romance":
			width += 0.58
		"conflict":
			width += 0.75
		"political":
			width += 0.45
		"house":
			width += 0.35
		"economic":
			width += 0.25
		"civic":
			width -= 0.2
		_:
			pass

	return clampf(width, 1.35, 7.25)


static func _crown_population_graph_docked_target_rect_for_layer(
	layer: Control,
	target_rect: Rect2,
	edge_index: int,
	total_edges: int
) -> Rect2:
	if layer == null:
		return target_rect

	var layer_size: Vector2 = layer.size
	var margin: float = 18.0
	var dock_size: Vector2 = Vector2(10.0, 10.0)
	var target_center: Vector2 = target_rect.get_center()

	var center: Vector2 = Vector2(
		clampf(target_center.x, margin, maxf(margin, layer_size.x - margin)),
		clampf(target_center.y, margin, maxf(margin, layer_size.y - margin))
	)

	var left_overflow: float = maxf(0.0, - target_center.x)
	var right_overflow: float = maxf(0.0, target_center.x - layer_size.x)
	var top_overflow: float = maxf(0.0, - target_center.y)
	var bottom_overflow: float = maxf(0.0, target_center.y - layer_size.y)

	var strongest_axis: String = "right"
	var strongest_value: float = right_overflow

	if left_overflow > strongest_value:
		strongest_axis = "left"
		strongest_value = left_overflow
	if top_overflow > strongest_value:
		strongest_axis = "top"
		strongest_value = top_overflow
	if bottom_overflow > strongest_value:
		strongest_axis = "bottom"
		strongest_value = bottom_overflow

	var safe_total: int = max(1, total_edges)
	var lane_ratio: float = float(edge_index + 1) / float(safe_total + 1)
	var lane_sway: float = sin(float(edge_index) * 1.61803398875) * (32.0 if safe_total >= 10 else 18.0)

	match strongest_axis:
		"left":
			center.x = margin
			center.y = clampf((layer_size.y * lane_ratio) + lane_sway, margin, layer_size.y - margin)
		"right":
			center.x = layer_size.x - margin
			center.y = clampf((layer_size.y * lane_ratio) + lane_sway, margin, layer_size.y - margin)
		"top":
			center.y = margin
			center.x = clampf((layer_size.x * lane_ratio) + lane_sway, margin, layer_size.x - margin)
		"bottom":
			center.y = layer_size.y - margin
			center.x = clampf((layer_size.x * lane_ratio) + lane_sway, margin, layer_size.x - margin)

	return Rect2(center - (dock_size * 0.5), dock_size)


static func _crown_population_graph_virtual_target_rect_for_edge(
	layer: Control,
	source_rect: Rect2,
	edge: Dictionary,
	edge_index: int,
	total_edges: int
) -> Rect2:
	if layer == null:
		return Rect2()

	var layer_size: Vector2 = layer.size
	if layer_size.x <= 0.0 or layer_size.y <= 0.0:
		return Rect2()

	var margin: float = 18.0
	var dock_size: Vector2 = Vector2(10.0, 10.0)
	var source_center: Vector2 = source_rect.get_center()
	var safe_total: int = max(1, total_edges)
	var lane_ratio: float = float(edge_index + 1) / float(safe_total + 1)
	var target_entity_id: String = str(edge.get("target_entity_id", "")).strip_edges()
	var line_kind: String = str(edge.get("line_kind", "relationship")).strip_edges().to_lower()
	var stable_hash: int = abs(int(("%s:%s:%d" % [target_entity_id, line_kind, edge_index]).hash()))
	var hash_ratio: float = float(stable_hash % 1000) / 1000.0
	var sway: float = (hash_ratio - 0.5) * 46.0
	var side: int = stable_hash % 4
	var center: Vector2 = Vector2.ZERO

	match side:
		0:
			center.x = margin
			center.y = clampf((layer_size.y * lane_ratio) + sway, margin, layer_size.y - margin)
		1:
			center.x = layer_size.x - margin
			center.y = clampf((layer_size.y * lane_ratio) + sway, margin, layer_size.y - margin)
		2:
			center.y = margin
			center.x = clampf((layer_size.x * lane_ratio) + sway, margin, layer_size.x - margin)
		_:
			center.y = layer_size.y - margin
			center.x = clampf((layer_size.x * lane_ratio) + sway, margin, layer_size.x - margin)

	if absf(source_center.x - center.x) < 24.0 and absf(source_center.y - center.y) < 24.0:
		center.x = clampf(layer_size.x - center.x, margin, layer_size.x - margin)
		center.y = clampf(layer_size.y - center.y, margin, layer_size.y - margin)

	return Rect2(center - (dock_size * 0.5), dock_size)


static func _crown_population_graph_anchor_route(source_rect: Rect2, target_rect: Rect2) -> Dictionary:
	var source_center: Vector2 = source_rect.get_center()
	var target_center: Vector2 = target_rect.get_center()
	var delta: Vector2 = target_center - source_center

	if absf(delta.x) >= absf(delta.y):
		if delta.x >= 0.0:
			return {
				"source": source_rect.position + Vector2(source_rect.size.x, source_rect.size.y * 0.5),
				"target": target_rect.position + Vector2(0.0, target_rect.size.y * 0.5),
				"axis": "horizontal"
			}

		return {
			"source": source_rect.position + Vector2(0.0, source_rect.size.y * 0.5),
			"target": target_rect.position + Vector2(target_rect.size.x, target_rect.size.y * 0.5),
			"axis": "horizontal"
		}

	if delta.y >= 0.0:
		return {
			"source": source_rect.position + Vector2(source_rect.size.x * 0.5, source_rect.size.y),
			"target": target_rect.position + Vector2(target_rect.size.x * 0.5, 0.0),
			"axis": "vertical"
		}

	return {
		"source": source_rect.position + Vector2(source_rect.size.x * 0.5, 0.0),
		"target": target_rect.position + Vector2(target_rect.size.x * 0.5, target_rect.size.y),
		"axis": "vertical"
	}


static func _crown_population_graph_edge_color(line_kind: String, accent: Color, intensity: float = 0.78) -> Color:
	var alpha: float = clampf(intensity, 0.36, 1.0)

	match line_kind:
		"succession_heir":
			return Color(1.0, 0.72, 0.1, alpha)
		"romance":
			return Color(1.0, 0.12, 0.68, alpha)
		"family":
			return Color(0.22, 0.58, 1.0, alpha)
		"house":
			return Color(0.76, 0.38, 1.0, alpha)
		"political":
			return Color(1.0, 0.78, 0.18, alpha)
		"economic":
			return Color(0.24, 0.98, 0.52, alpha)
		"conflict":
			return Color(1.0, 0.16, 0.1, alpha)
		"civic":
			return Color(0.78, 0.66, 0.46, alpha)
		"social":
			return Color(0.4, 0.82, 1.0, alpha)
		_:
			return Color(accent.r, accent.g, accent.b, alpha)


static func _crown_population_city_bucket_key_for_person(target: Person, realm_id: int, realm_name: String, section_kind: String, element: String = "", split_by_city: bool = false) -> String:
	if target == null:
		return "unknown"

	var home_city: String = str(target.home_city).strip_edges()
	var birth_city: String = str(target.birth_city).strip_edges()
	var city_key: String = home_city if home_city != "" else birth_city

	if city_key == "":
		city_key = "Unplaced"

	var normalized_city: String = city_key.strip_edges().to_lower()
	var normalized_realm: String = str(realm_name).strip_edges().to_lower()
	var element_key: String = str(element).strip_edges().to_lower()

	if split_by_city:
		return "split:%s:%s:%s" % [
			normalized_realm if normalized_realm != "" else str(realm_id),
			normalized_city,
			section_kind
		]

	if element_key in ["air", "fire", "water"]:
		return "nation:%s:%s:%s" % [
			element_key,
			normalized_city,
			section_kind
		]

	return "nation:%s:%s:%s" % [
		normalized_realm if normalized_realm != "" else str(realm_id),
		normalized_city,
		section_kind
	]


static func _other_country_population_entry_should_hide(entry: Dictionary, realm: Dictionary = {}) -> bool:
	var entry_id: String = str(entry.get("entry_id", "")).strip_edges().to_lower()
	var entry_name: String = str(entry.get("name", "")).strip_edges().to_lower()
	var visual_theme: String = str(realm.get("browser_visual_theme", realm.get("overview_visual_theme", ""))).strip_edges().to_lower()

	if entry_id == "era_kingdom" or entry_name == "era kingdom" or visual_theme == "era_kingdom":
		return true

	if entry_id == "terabithia" or entry_name == "terabithia" or visual_theme == "terabithia":
		return true

	return false


static func _other_country_population_realm_name_from_entry(entry: Dictionary, realm: Dictionary = {}) -> String:
	var realm_name: String = str(realm.get("name", realm.get("country", ""))).strip_edges()
	if realm_name != "":
		return realm_name

	realm_name = str(entry.get("name", "")).strip_edges()
	if realm_name != "":
		return realm_name

	return "Country / Realm"


static func _crown_population_wall_should_hide_for_realm(_realm_id: int, realm_name: String, realm: Dictionary = {}) -> bool:
	var name_key: String = str(realm_name).strip_edges().to_lower()
	var visual_theme: String = str(realm.get("browser_visual_theme", realm.get("overview_visual_theme", ""))).strip_edges().to_lower()
	var entry_id: String = str(realm.get("entry_id", realm.get("id", ""))).strip_edges().to_lower()

	if name_key == "era kingdom" or entry_id == "era_kingdom" or visual_theme == "era_kingdom":
		return true

	if name_key == "terabithia" or entry_id == "terabithia" or visual_theme == "terabithia":
		return true

	return false


static func _population_lens_incremental_entity_key(
	raw_row: Variant
) -> String:
	if raw_row is Person:
		return "person:%d" % int(
			(raw_row as Person).id
		)

	if typeof(raw_row) == TYPE_DICTIONARY:
		var row: Dictionary = (
			raw_row as Dictionary
		)

		for raw_key in [
			"entity_id",
			"node_id",
			"person_id",
			"actor_id",
			"id",
			"contract_id"
		]:
			var key: String = str(
				raw_key
			)
			var candidate: String = str(
				row.get(
					key,
					""
				)
			).strip_edges()

			if candidate != "":
				return "%s:%s" % [
					key,
					candidate
				]

	return "row_hash:%s" % str(
		hash(
			raw_row
		)
	)


static func _population_lens_incremental_section_accent(
	accent_key: String,
	realm_accent: Color
) -> Color:
	match str(
		accent_key
	).strip_edges().to_lower():
		"royal":
			return Color(
				1.0,
				0.78,
				0.24,
				1.0
			)

		"noble":
			return Color(
				0.78,
				0.56,
				1.0,
				1.0
			)

		"executive", "federal_executive":
			return Color(
				0.34,
				0.56,
				1.0,
				1.0
			)

		"federal_cabinet":
			return Color(
				0.42,
				0.66,
				1.0,
				1.0
			)

		"legislative", "federal_legislative":
			return Color(
				0.38,
				0.54,
				0.98,
				1.0
			)

		"judicial", "federal_judicial":
			return Color(
				0.7,
				0.56,
				1.0,
				1.0
			)

		"federal_governor":
			return Color(
				0.48,
				0.82,
				0.62,
				1.0
			)

		"military":
			return Color(
				0.86,
				0.48,
				0.34,
				1.0
			)

		"elemental":
			return realm_accent

		"social_upper":
			return Color(
				1.0,
				0.76,
				0.28,
				1.0
			)

		"social_middle":
			return Color(
				0.34,
				0.72,
				1.0,
				1.0
			)

		"social_skilled":
			return Color(
				0.34,
				0.88,
				0.68,
				1.0
			)

		"social_working":
			return Color(
				0.82,
				0.6,
				0.34,
				1.0
			)

		"social_lower":
			return Color(
				0.62,
				0.64,
				0.72,
				1.0
			)

		_:
			return realm_accent


static func _crown_population_full_target_bucket_color(title_text: String, fallback: Color) -> Color:
	var key: String = str(title_text).strip_edges().to_lower()

	if key.find("profile") >= 0:
		return Color(0.56, 0.76, 1.0, 1.0)
	if key.find("court") >= 0:
		return Color(0.82, 0.58, 1.0, 1.0)
	if key.find("dynasty") >= 0 or key.find("family") >= 0:
		return Color(1.0, 0.72, 0.38, 1.0)
	if key.find("force") >= 0 or key.find("state") >= 0:
		return Color(1.0, 0.34, 0.24, 1.0)

	return fallback


static func _crown_population_full_target_bucket_style(accent: Color, hovered: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.08, accent.g * 0.062, accent.b * 0.085, 0.95)
	style.border_width_left = 2 if hovered else 1
	style.border_width_top = 2 if hovered else 1
	style.border_width_right = 2 if hovered else 1
	style.border_width_bottom = 2 if hovered else 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.82 if hovered else 0.42)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.28 if hovered else 0.12)
	style.shadow_size = 10 if hovered else 4
	style.shadow_offset = Vector2.ZERO
	return style


static func _crown_population_noble_title_from_text(text: String) -> String:
	var lowered: String = str(text).strip_edges().to_lower()
	if lowered == "":
		return ""

	if lowered.find("high noble") >= 0 \
or lowered.find("high nobility") >= 0 \
or lowered.find("upper nobility") >= 0 \
or lowered.find("aristocrat") >= 0 \
or lowered.find("aristocracy") >= 0 \
or lowered.find("nobility") >= 0:
		return "High Noble"

	if lowered.find("marchioness") >= 0:
		return "Marchioness"

	if lowered.find("marquess") >= 0 \
or lowered.find("marquis") >= 0 \
or lowered.find("marquise") >= 0 \
or lowered.find("marquee") >= 0 \
or lowered.find("marcher lord") >= 0:
		return "Marquess"

	if lowered.find("archduchess") >= 0:
		return "Archduchess"

	if lowered.find("archduke") >= 0:
		return "Archduke"

	if lowered.find("duchess") >= 0:
		return "Duchess"

	if lowered.find("duke") >= 0 \
or lowered.find("ducal") >= 0 \
or lowered.find("duchy") >= 0:
		return "Duke"

	if lowered.find("countess") >= 0:
		return "Countess"

	if lowered.find("count ") >= 0 or lowered == "count":
		return "Count"

	if lowered.find("baroness") >= 0:
		return "Baroness"

	if lowered.find("baron") >= 0:
		return "Baron"

	if lowered.find("viscountess") >= 0:
		return "Viscountess"

	if lowered.find("viscount") >= 0:
		return "Viscount"

	if lowered.find("lady") >= 0:
		return "Lady"

	if lowered.find("lord") >= 0:
		return "Lord"

	if lowered == "noble":
		return "High Noble"

	return ""


static func _crown_population_title_tier_from_text(title_text: String) -> String:
	var lowered: String = str(title_text).strip_edges().to_lower()
	if lowered == "":
		return ""

	if lowered.find("king") >= 0 \
or lowered.find("queen") >= 0 \
or lowered.find("emperor") >= 0 \
or lowered.find("empress") >= 0 \
or lowered.find("pharaoh") >= 0 \
or lowered.find("sovereign") >= 0 \
or lowered.find("chief") >= 0 \
or lowered.find("fire lord") >= 0 \
or lowered.find("fire queen") >= 0 \
or lowered.find("earth king") >= 0 \
or lowered.find("earth queen") >= 0 \
or lowered.find("air regent") >= 0:
		return "ruler"

	if lowered.find("crown prince") >= 0 or lowered.find("crown princess") >= 0:
		return "heir"

	if lowered.find("prince") >= 0 or lowered.find("princess") >= 0:
		return "royal_child"

	if lowered.find("archduke") >= 0 or lowered.find("archduchess") >= 0:
		return "ducal"

	if lowered.find("duke") >= 0 \
or lowered.find("duchess") >= 0 \
or lowered.find("ducal") >= 0 \
or lowered.find("duchy") >= 0:
		return "ducal"

	if lowered.find("marquess") >= 0 \
or lowered.find("marchioness") >= 0 \
or lowered.find("marquis") >= 0 \
or lowered.find("marquise") >= 0 \
or lowered.find("marquee") >= 0 \
or lowered.find("marcher lord") >= 0:
		return "marcher"

	if lowered.find("high noble") >= 0 \
or lowered.find("nobility") >= 0 \
or lowered.find("aristocrat") >= 0 \
or lowered.find("aristocracy") >= 0:
		return "lord"

	if lowered.find("countess") >= 0 \
or lowered.find("count ") >= 0 \
or lowered == "count" \
or lowered.find("baroness") >= 0 \
or lowered.find("baron") >= 0 \
or lowered.find("viscountess") >= 0 \
or lowered.find("viscount") >= 0:
		return "lord"

	if lowered.find("lord") >= 0 or lowered.find("lady") >= 0:
		return "lord"

	return ""


static func _crown_population_push_unique_person(out: Array, seen: Dictionary, target: Person) -> void:
	if target == null or not target.alive:
		return

	var target_id: int = int(target.id)
	if target_id <= 0 or seen.has(target_id):
		return

	out.append(target)
	seen [target_id] = true


static func _crown_population_citizen_strata_title(key: String) -> String:
	match str(key):
		"bottom_class":
			return "BOTTOM CLASS"
		"lower_middle_class":
			return "LOWER-MIDDLE CLASS"
		"middle_class":
			return "MIDDLE CLASS"
		"upper_middle_class":
			return "UPPER-MIDDLE CLASS"
		"elite":
			return "ELITES"
		"peasant":
			return "PEASANTS"
		"merchant":
			return "MERCHANTS"
		_:
			return "COMMONERS"


static func _crown_population_citizen_strata_subtitle(key: String) -> String:
	match str(key):
		"bottom_class":
			return "Bottom-class citizens with the least economic security. Their jobs and stats still render per card."
		"lower_middle_class":
			return "Working and lower-middle citizens. They are regular citizens, not federal officials."
		"middle_class":
			return "Stable middle-class citizens, professionals, workers, and household builders."
		"upper_middle_class":
			return "Upper-middle citizens, business owners, high earners, and high-status professionals."
		"elite":
			return "The one percent: rich, famous, or extremely wealthy civilians. They are powerful citizens, not federal officers."
		"peasant":
			return "Lowborn workers, farmers, servants, laborers, and rural citizens."
		"merchant":
			return "Trade, craft, shop, and wealth-building citizens."
		_:
			return "Regular citizens outside the noble court. Their individual jobs still render on each card."


static func _crown_population_citizen_strata_accent_color(key: String, fallback: Color) -> Color:
	match str(key):
		"bottom_class":
			return Color(fallback.r * 0.58, fallback.g * 0.58, fallback.b * 0.58, 1.0)
		"lower_middle_class":
			return Color(fallback.r * 0.74, fallback.g * 0.78, fallback.b * 0.82, 1.0)
		"middle_class":
			return Color(fallback.r * 0.92, fallback.g * 0.92, fallback.b * 0.92, 1.0)
		"upper_middle_class":
			return Color(0.78, 0.86, 1.0, 1.0)
		"elite":
			return Color(1.0, 0.88, 0.48, 1.0)
		"peasant":
			return Color(0.72, 0.62, 0.44, 1.0)
		"merchant":
			return Color(0.5, 0.86, 0.68, 1.0)
		_:
			return Color(fallback.r, fallback.g, fallback.b, 1.0)


static func _build_crown_population_removal_label(target: Person) -> String:
	if target == null:
		return "Execute"
	if bool(target.is_ruler):
		return "Assassinate"
	if bool(target.is_royal):
		return "Assassinate"
	if int(target.succession_rank) > 0:
		return "Assassinate"
	if str(target.royal_title).strip_edges() != "":
		return "Assassinate"

	var office_job: String = str(target.job).strip_edges().to_lower()
	if office_job in [
		"president",
		"prime minister",
		"governor",
		"mayor",
		"senator",
		"judge",
		"minister",
		"court official",
		"general"
	]:
		return "Assassinate"

	return "Execute"


static func _crown_population_promotion_ceiling_seed(gs: GameState) -> String:
	if gs == null or gs.player == null:
		return ""

	var p: Person = gs.player
	if bool(p.is_ruler):
		return "Heir Line"

	var clean_title:= str(p.royal_title).strip_edges().to_lower()
	if int(p.succession_rank) == 1 or clean_title.find("heir") != -1 or clean_title.find("crown") != -1:
		return "Royal Child"

	if bool(p.is_royal) or str(p.royal_title).strip_edges() != "":
		return "Lesser Royal"

	return ""


static func _build_crown_population_promotion_options(gs: GameState,
	target: Person) -> Array:
	var out: Array = []
	if target == null:
		return out

	var ceiling_seed:= PopulationSceneSupport._crown_population_promotion_ceiling_seed(gs)
	if ceiling_seed == "":
		return out

	var option_rows: Array = []
	if gs != null and gs.royalty_engine != null and gs.royalty_engine.has_method("get_spawnable_royal_rank_options"):
		option_rows = gs.royalty_engine.get_spawnable_royal_rank_options(
			GovernmentSceneSupport._crown_realm_name(gs, int(target.realm_id)),
			""
		)

	if option_rows.is_empty():
		option_rows = [
			{ "seed": "Royal Child", "label": "Prince / Princess"},
			{ "seed": "Heir Line", "label": "Crown Prince / Crown Princess"},
			{ "seed": "Lesser Royal", "label": "Duke / Duchess"}
		]

	for raw_row in option_rows:
		if typeof(raw_row) != TYPE_DICTIONARY:
			continue

		var row: Dictionary = raw_row
		var seed_text:= str(row.get("seed", "")).strip_edges()
		if seed_text == "":
			continue

		if ceiling_seed == "Lesser Royal" and seed_text != "Lesser Royal":
			continue
		if ceiling_seed == "Royal Child" and seed_text == "Heir Line":
			continue

		out.append(row)

	return out


static func _apply_crown_population_promotion(gs: GameState,
	target: Person, rank_seed: String) -> String:
	if target == null or gs == null or gs.player == null:
		return ""

	var normalized_seed:= str(rank_seed).strip_edges()
	if gs.royalty_engine != null and gs.royalty_engine.has_method("_normalize_royal_rank_seed"):
		normalized_seed = str(gs.royalty_engine.call("_normalize_royal_rank_seed", normalized_seed)).strip_edges()
	if normalized_seed == "":
		normalized_seed = "Lesser Royal"

	target.is_ruler = false
	target.is_royal = true
	target.deposed = false
	target.exiled = false
	target.realm_id = int(gs.player.realm_id)
	target.palace_owned = false

	match normalized_seed:
		"Heir Line":
			target.social_class = "Royal"
			target.succession_rank = 1
			target.royal_title = str(gs.royalty_engine.call("_resolve_rank_title", target, "heir"))
		"Royal Child":
			target.social_class = "Royal"
			target.succession_rank = max(3, int(target.succession_rank))
			target.royal_title = str(gs.royalty_engine.call("_resolve_rank_title", target, "royal_child"))
		_:
			target.social_class = "Noble"
			target.succession_rank = max(8, int(target.succession_rank))
			target.royal_title = str(gs.royalty_engine.call("_resolve_rank_title", target, "lesser_royal"))
			normalized_seed = "Lesser Royal"

	if gs.royalty_engine != null and gs.royalty_engine.has_method("_set_royal_rank_seed_trait"):
		gs.royalty_engine.call("_set_royal_rank_seed_trait", target, normalized_seed)
	if gs.royalty_engine != null and gs.royalty_engine.has_method("_sync_royal_job_identity"):
		gs.royalty_engine.call("_sync_royal_job_identity", target)
	if gs.royalty_engine != null and gs.royalty_engine.has_method("_apply_royal_fame_floor"):
		gs.royalty_engine.call("_apply_royal_fame_floor", target)

	target.approval = min(100, int(target.approval) + 12)
	return normalized_seed


static func _crown_population_realm_element(gs: GameState,
	realm_id: int, realm_name: String = "") -> String:
	var clean_name: String = str(realm_name).strip_edges()
	if clean_name == "":
		clean_name = GovernmentSceneSupport._crown_realm_name(gs, realm_id)

	if gs != null and gs.realm_engine != null and gs.realm_engine.has_method("_realm_element_for_name"):
		return str(gs.realm_engine._realm_element_for_name(clean_name)).strip_edges().to_lower()

	return ""


static func _is_crown_population_element_master(gs: GameState,
	target: Person, realm_id: int, element: String) -> bool:
	if target == null or not target.alive:
		return false

	var clean_element: String = str(element).strip_edges().to_lower()
	if clean_element == "":
		return false

	var bending_type: String = str(target.bending_type).strip_edges().to_lower()
	var bending_nation: String = str(target.bending_nation).strip_edges().to_lower()
	var realm_name: String = GovernmentSceneSupport._crown_realm_name(gs, realm_id).strip_edges()
	var realm_key: String = realm_name.to_lower()

	var is_elemental_bender: bool = bending_type == clean_element or bending_type == "avatar"
	if not is_elemental_bender:
		return false

	var mastery_value: int = 0
	if typeof(target.bending_mastery) == TYPE_DICTIONARY:
		mastery_value = int(target.bending_mastery.get(clean_element, 0))

	var has_master_signal: bool = mastery_value >= 70
	has_master_signal = has_master_signal or str(target.job).strip_edges().to_lower().find("bending") >= 0
	has_master_signal = has_master_signal or "Bending Master" in target.traits

	if not has_master_signal:
		return false

	if int(target.realm_id) == realm_id:
		return true

	if bending_nation != "":
		if bending_nation == realm_key:
			return true
		if bending_nation.find(clean_element) >= 0:
			return true
		if realm_key.find(bending_nation) >= 0:
			return true

	if realm_key.find(clean_element) >= 0:
		return true

	if PopulationSceneSupport._crown_population_person_matches_realm(gs, target, realm_id, realm_name):
		return true

	return false


static func _crown_population_modern_citizen_role_label(gs: GameState,
	target: Person, realm_id: int, realm_name: String = "") -> String:
	if target == null:
		return "Citizen"

	if not PopulationSceneSupport._crown_population_uses_modern_class_lens(gs, realm_id, realm_name):
		return ""

	var social_key: String = str(target.social_class).strip_edges().to_lower()
	var job_text: String = str(target.job).strip_edges()

	if social_key in ["elite", "ultra elite", "ruling elite", "old money", "billionaire", "one percent", "1%", "rich"]:
		return "Upper-Class Citizen"

	if social_key in ["upper middle class", "upper-middle class", "upper class", "upperclass", "wealthy"]:
		return "Upper-Middle Citizen"

	if social_key in ["middle class", "middle-class", "professional"]:
		return "Middle-Class Citizen"

	if social_key in ["lower middle class", "lower-middle class", "working class", "working-class", "commoner", "merchant", "trader", "worker"]:
		if job_text != "":
			return GovernmentSceneSupport._crown_title_case(job_text)
		return "Working-Class Citizen"

	if social_key in ["poor", "lower class", "low class", "bottom class", "bottom-class", "struggling"]:
		return "Bottom-Class Citizen"

	if job_text != "":
		return GovernmentSceneSupport._crown_title_case(job_text)

	return "Citizen"


static func _crown_population_is_throne_holder(gs: GameState,
	target: Person, realm_id: int) -> bool:
	if target == null:
		return false

	if bool(target.is_ruler):
		return true

	if gs != null and gs.realm_engine != null and gs.realm_engine.realms.has(realm_id):
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
		var ruler_id: int = int(realm.get("ruler_id", -1))
		if ruler_id > 0 and int(target.id) == ruler_id:
			return true

	return false


static func _crown_population_loyalty_value(gs: GameState,
	target: Person, realm_id: int, section_kind: String) -> int:
	if target == null:
		return 0

	if PopulationSceneSupport._crown_population_is_throne_holder(gs, target, realm_id):
		return -1

	var realm_loyalty: int = 50
	if gs != null and gs.realm_engine != null and gs.realm_engine.realms.has(realm_id):
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
		realm_loyalty = clampi(int(realm.get("loyalty", 50)), 0, 100)

	var approval_value: int = clampi(int(target.approval), 0, 100)
	var respect_value: int = clampi(int(target.respect), 0, 100)
	var fame_value: int = clampi(int(target.fame), 0, 100)

	if section_kind == "official" or bool(target.is_royal) or int(target.succession_rank) > 0:
		return clampi(int(round((float(approval_value) * 0.62) + (float(respect_value) * 0.28) + (float(realm_loyalty) * 0.1))), 0, 100)

	return clampi(int(round((float(realm_loyalty) * 0.68) + (float(respect_value) * 0.22) + (float(fame_value) * 0.1))), 0, 100)


static func _apply_crown_population_name_button_style(button: Button, _target: Person, _section_kind: String, _accent: Color, role_accent: Color) -> void:
	if button == null:
		return

	var base_bg: Color = Color(role_accent.r * 0.11, role_accent.g * 0.1, role_accent.b * 0.12, 0.94)
	var normal_border: Color = Color(role_accent.r, role_accent.g, role_accent.b, 0.46)
	var hover_border: Color = Color(1.0, 0.91, 0.72, 1.0)

	button.add_theme_stylebox_override("normal", PopulationSceneSupport._crown_population_button_style(base_bg, normal_border, false, false))
	button.add_theme_stylebox_override("hover", PopulationSceneSupport._crown_population_button_style(base_bg.lerp(Color(1.0, 0.91, 0.72, 0.96), 0.16), hover_border, true, false))
	button.add_theme_stylebox_override("pressed", PopulationSceneSupport._crown_population_button_style(base_bg.lerp(Color(1.0, 0.78, 0.34, 0.98), 0.2), Color(1.0, 0.78, 0.34, 1.0), true, false))
	button.add_theme_stylebox_override("disabled", PopulationSceneSupport._crown_population_button_style(base_bg, normal_border, false, true))
	button.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.52, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(1.0, 0.92, 0.5, 0.86))


static func _crown_population_bloodline_color(target: Person, fallback: Color) -> Color:
	var key: String = PopulationSceneSupport._crown_population_bloodline_key(target)
	var bloodline_hash: int = abs(int(hash(key)))

	var r_bucket: int = bloodline_hash % 47
	var g_bucket: int = floori(float(bloodline_hash) / 47.0) % 47
	var b_bucket: int = floori(float(bloodline_hash) / 2209.0) % 47

	var r: float = 0.32 + float(r_bucket) / 100.0
	var g: float = 0.32 + float(g_bucket) / 100.0
	var b: float = 0.32 + float(b_bucket) / 100.0

	return Color(
		clamp(r, 0.24, 0.92),
		clamp(g, 0.24, 0.92),
		clamp(b, 0.24, 0.92),
		1.0
	).lerp(fallback, 0.3)


static func _crown_population_realm_ruler_for(gs: GameState,
	realm_id: int) -> Person:
	if gs == null or realm_id <= 0:
		return null

	if gs.realm_engine != null and gs.realm_engine.realms.has(realm_id):
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
		var ruler_id: int = int(realm.get("ruler_id", -1))
		if ruler_id > 0:
			return GovernmentSceneSupport._find_active_crown_person_by_id(gs, ruler_id)

	return null


static func _crown_population_influence_value(gs: GameState,
	target: Person, realm_id: int, section_kind: String, element: String = "") -> int:
	if target == null:
		return 0

	var influence: float = 0.0

	match section_kind:
		"official":
			influence += 34.0
		"noble":
			influence += 26.0
		"master":
			influence += 22.0
		_:
			influence += 8.0

	if PopulationSceneSupport._crown_population_is_throne_holder(gs, target, realm_id):
		influence += 40.0
	if bool(target.is_royal):
		influence += 16.0
	if int(target.succession_rank) > 0:
		influence += maxf(0.0, 22.0 - float(target.succession_rank))

	influence += float(target.fame) * 0.18
	influence += float(target.respect) * 0.22
	influence += float(target.approval) * 0.12

	if int(target.bank_balance) >= 1000000:
		influence += 8.0
	if int(target.bank_balance) >= 10000000:
		influence += 10.0

	var clean_element: String = str(element).strip_edges().to_lower()
	if clean_element != "" and PopulationSceneSupport._is_crown_population_element_master(gs, target, realm_id, clean_element):
		influence += 14.0

	return clampi(int(round(influence)), 0, 100)


static func _crown_population_current_action_text(target: Person) -> String:
	if target == null:
		return "No readable action context."

	var bits: Array = []

	var context_text: String = str(target.current_context).strip_edges()
	if context_text != "" and context_text != "free":
		bits.append("Context: %s" % context_text.replace("_", " ").capitalize())

	var job_text: String = str(target.job).strip_edges()
	if job_text != "":
		bits.append("Work: %s" % GovernmentSceneSupport._crown_title_case(job_text))

	var school_status: String = str(target.school_status).strip_edges()
	if school_status != "":
		bits.append("School: %s" % school_status)

	var marital_status: String = str(target.marital_status).strip_edges()
	if marital_status != "":
		bits.append("House: %s" % marital_status)

	if bits.is_empty():
		return "Current action: living inside the active realm simulation."

	return " • ".join(bits)


static func _crown_population_collect_visible_graph_entity_ids(groups: Array) -> Dictionary:
	var out: Dictionary = {}

	for raw_group in groups:
		if typeof(raw_group) != TYPE_ARRAY:
			continue

		var group: Array = raw_group
		for raw_person in group:
			var person: Person = raw_person
			if person == null or not person.alive:
				continue

			var entity_id: String = PopulationSceneSupport._crown_population_entity_id_for_person(person)
			if entity_id != "":
				out [entity_id] = true

	return out


static func _crown_population_graph_card_visible_in_layer(card: Control, layer: Control) -> bool:
	if card == null or layer == null:
		return false

	if not is_instance_valid(card) or not is_instance_valid(layer):
		return false

	var view_rect:= Rect2(Vector2.ZERO, layer.size).grow(8.0)
	var card_rect: Rect2 = PopulationSceneSupport._crown_population_graph_card_rect_in_layer(card, layer)

	if card_rect.size == Vector2.ZERO:
		return false

	return view_rect.intersects(card_rect)


static func _crown_population_wall_cache_key(gs: GameState,
	realm_id: int) -> String:
	return "realm_population_wall:category_v12_sovereign_scope_async_shards:%d:%d" % [
		realm_id,
		int(gs.year) if gs != null else 0
	]


static func _crown_population_should_city_split_realm(gs: GameState,
	realm_id: int, realm_name: String, element: String = "") -> bool:
	var name_key: String = str(realm_name).strip_edges().to_lower()
	var element_key: String = str(element).strip_edges().to_lower()

	if element_key == "earth":
		return true

	if name_key.find("earth kingdom") >= 0:
		return true

	var resolved_name: String = GovernmentSceneSupport._crown_realm_name(gs, realm_id).strip_edges().to_lower()
	if resolved_name.find("earth kingdom") >= 0:
		return true

	return false


static func _crown_population_representative_nation_sample(gs: GameState,
	people: Array, max_count: int, realm_id: int, realm_name: String, section_kind: String, element: String = "") -> Array:
	var clean_max: int = maxi(0, max_count)
	if clean_max <= 0:
		return []

	if people.size() <= clean_max:
		return people

	var buckets: Dictionary = {}
	var bucket_order: Array = []
	var split_by_city: bool = PopulationSceneSupport._crown_population_should_city_split_realm(gs, realm_id, realm_name, element)

	for raw_person in people:
		var person: Person = raw_person
		if person == null or not person.alive:
			continue

		var bucket_key: String = PopulationSceneSupport._crown_population_city_bucket_key_for_person(
			person,
			realm_id,
			realm_name,
			section_kind,
			element,
			split_by_city
		)

		if not buckets.has(bucket_key):
			buckets [bucket_key] = []
			bucket_order.append(bucket_key)

		var bucket: Array = buckets.get(bucket_key, [])
		bucket.append(person)
		buckets [bucket_key] = bucket

	var out: Array = []
	var cursor_by_bucket: Dictionary = {}

	for raw_bucket_key in bucket_order:
		cursor_by_bucket [str(raw_bucket_key)] = 0

	var made_progress: bool = true
	while out.size() < clean_max and made_progress:
		made_progress = false

		for raw_bucket_key in bucket_order:
			if out.size() >= clean_max:
				break

			var bucket_key: String = str(raw_bucket_key)
			var bucket: Array = buckets.get(bucket_key, []) if typeof(buckets.get(bucket_key, [])) == TYPE_ARRAY else []
			var cursor: int = int(cursor_by_bucket.get(bucket_key, 0))

			if cursor >= bucket.size():
				continue

			var person: Person = bucket [cursor]
			cursor_by_bucket [bucket_key] = cursor + 1

			if person == null or not person.alive:
				continue

			out.append(person)
			made_progress = true

	return out


static func _crown_population_view_contract_signature(gs: GameState,
	view_contract: Dictionary) -> String:
	if view_contract.is_empty():
		return "empty"

	return "%d:%d:%d:%d:%d:%d" % [
		int(view_contract.get("realm_id", -1)),
		int(view_contract.get("built_for_year", gs.year if gs != null else 0)),
		(view_contract.get("officials", []) as Array).size() if typeof(view_contract.get("officials", [])) == TYPE_ARRAY else 0,
		(view_contract.get("nobles", []) as Array).size() if typeof(view_contract.get("nobles", [])) == TYPE_ARRAY else 0,
		(view_contract.get("masters", []) as Array).size() if typeof(view_contract.get("masters", [])) == TYPE_ARRAY else 0,
		(view_contract.get("citizens", []) as Array).size() if typeof(view_contract.get("citizens", [])) == TYPE_ARRAY else 0
	]


static func _request_population_government_truth_tail_for_realm(gs: GameState,
	realm_id: int, realm_name: String, reason: String = "population_government_truth_tail") -> Dictionary:
	if gs == null or realm_id <= 0:
		return {
			"success": false,
			"reason": "missing_game_state_or_invalid_realm",
			"ui_is_renderer_only": true
		}

	if not "truth_resolution_contract_engine" in gs or gs.truth_resolution_contract_engine == null:
		gs.truth_resolution_contract_engine = TruthResolutionContractEngine.new(gs)

	if gs.truth_resolution_contract_engine == null:
		return {
			"success": false,
			"reason": "missing_truth_resolution_contract_engine",
			"realm_id": realm_id,
			"realm_name": realm_name,
			"ui_is_renderer_only": true
		}

	if not gs.truth_resolution_contract_engine.has_method("resolve_population_and_government_truth_for_realms"):
		return {
			"success": false,
			"reason": "truth_resolution_engine_missing_resolve_method",
			"realm_id": realm_id,
			"realm_name": realm_name,
			"ui_is_renderer_only": true
		}

	return gs.truth_resolution_contract_engine.resolve_population_and_government_truth_for_realms(
		[realm_id],
		{
			"source": reason,
			"realm_id": realm_id,
			"realm_name": realm_name,
			"surface_already_exists": true,
			"truth_may_complete_after_observation": true,
			"skip_runtime_materialization": true,
			"ontology_only_ready_gate": true,
			"background_truth_resolution": true,
			"ready_door_may_not_wait": true,
			"ui_is_renderer_only": true
		}
	)


static func _population_card_contract_tail_realm_name(gs: GameState,
	realm_id: int) -> String:
	if realm_id <= 0:
		return ""

	if gs != null and gs.realm_engine != null and "realms" in gs.realm_engine and typeof(gs.realm_engine.realms) == TYPE_DICTIONARY:
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		if typeof(realm_raw) == TYPE_DICTIONARY:
			var realm: Dictionary = realm_raw
			var realm_name: String = str(realm.get("name", realm.get("country", ""))).strip_edges()
			if realm_name != "":
				return realm_name

	return GovernmentSceneSupport._crown_realm_name(gs, realm_id)


static func _other_country_population_preferred_city(gs: GameState,
	_entry: Dictionary, realm: Dictionary = {}) -> String:
	var preferred_city: String = str(realm.get("capital_city", "")).strip_edges()
	if preferred_city != "":
		return preferred_city

	var subzones_raw: Variant = realm.get("subzones", [])
	if typeof(subzones_raw) == TYPE_ARRAY:
		var subzones: Array = subzones_raw
		if not subzones.is_empty():
			preferred_city = str(subzones [0]).strip_edges()
			if preferred_city != "":
				return preferred_city

	if gs != null and gs.player != null:
		preferred_city = str(gs.player.home_city if str(gs.player.home_city).strip_edges() != "" else gs.player.birth_city).strip_edges()

	return preferred_city


static func _resolve_existing_realm_id_for_other_country_population_entry(gs: GameState,
	entry: Dictionary) -> int:
	if gs == null or gs.realm_engine == null:
		return -1
	if typeof(gs.realm_engine.realms) != TYPE_DICTIONARY:
		return -1

	var realm_raw: Variant = entry.get("realm", {})
	var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}

	var direct_realm_id: int = int(entry.get("realm_id", realm.get("realm_id", realm.get("id", -1))))
	if direct_realm_id > 0 and gs.realm_engine.realms.has(direct_realm_id):
		return direct_realm_id

	var wanted_name: String = PopulationSceneSupport._other_country_population_realm_name_from_entry(entry, realm)
	var wanted_country: String = str(realm.get("country", wanted_name)).strip_edges()
	var wanted_keys: Dictionary = {}

	for raw_name in [wanted_name, wanted_country, str(entry.get("name", ""))]:
		var clean_name: String = str(raw_name).strip_edges()
		if clean_name == "":
			continue
		wanted_keys [WorldSceneSupport._other_country_identity_key(clean_name)] = true

	for raw_realm_id in gs.realm_engine.realms.keys():
		var realm_id: int = int(raw_realm_id)
		var existing_raw: Variant = gs.realm_engine.realms.get(raw_realm_id, gs.realm_engine.realms.get(realm_id, {}))
		if typeof(existing_raw) != TYPE_DICTIONARY:
			continue

		var existing: Dictionary = existing_raw
		var existing_names: Array = [
			str(existing.get("name", "")),
			str(existing.get("country", "")),
			str(existing.get("realm_contract_resolved_from_country", ""))
		]

		for raw_existing_name in existing_names:
			var existing_key: String = WorldSceneSupport._other_country_identity_key(str(raw_existing_name))
			if existing_key != "" and wanted_keys.has(existing_key):
				return realm_id

	return -1


static func _population_lens_prewarm_trace_event(gs: GameState,
	stage: String, payload: Dictionary = {}) -> void:
	if gs == null:
		return

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	var events_raw: Variant = gs.scenario_state.get("population_lens_prewarm_trace", [])
	var events: Array = events_raw if typeof(events_raw) == TYPE_ARRAY else []

	var row: Dictionary = payload.duplicate(true)
	row ["stage"] = str(stage)
	row ["at_ms"] = int(Time.get_ticks_msec())
	row ["year"] = int(gs.year)
	row ["ui_is_renderer_only"] = true
	row ["intent_is_not_action"] = true

	events.append(row)

	if events.size() > 320:
		events = events.slice(events.size() - 320, events.size())

	gs.scenario_state ["population_lens_prewarm_trace"] = events
	gs.scenario_state ["population_lens_prewarm_trace_last_stage"] = str(stage)
	gs.scenario_state ["population_lens_prewarm_trace_last_payload"] = row.duplicate(true)


static func _presidential_parent_federal_population_stream_complete_for_realm(gs: GameState,
	realm_id: int) -> bool:
	if gs == null or realm_id <= 0:
		return true

	var scenario_complete: bool = true
	var scenario_pending: bool = false

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var us_realm_id: int = int(gs.scenario_state.get("presidential_parent_contract_us_realm_id", -1))
		if us_realm_id == realm_id:
			scenario_complete = bool(gs.scenario_state.get("presidential_parent_contract_federal_population_complete", false)) \
or bool(gs.scenario_state.get("presidential_parent_contract_federal_population_stream_complete", false))

			scenario_pending = bool(gs.scenario_state.get("presidential_parent_contract_federal_population_pending_after_player_control", false)) \
or bool(gs.scenario_state.get("presidential_parent_contract_federal_population_stream_running", false)) \
or bool(gs.scenario_state.get("presidential_parent_contract_federal_population_stream_jobs_pending_after_player_control", false))

			if scenario_complete:
				return true

			if scenario_pending:
				return false

	if gs.realm_engine != null and "realms" in gs.realm_engine and typeof(gs.realm_engine.realms) == TYPE_DICTIONARY:
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		if typeof(realm_raw) == TYPE_DICTIONARY:
			var realm: Dictionary = realm_raw
			var managed_federal: bool = bool(realm.get("federal_republic_population_contract", false)) \
or str(realm.get("government_model", "")).strip_edges().to_lower() == "federal_presidential_republic"

			if not managed_federal:
				return true

			if bool(realm.get("federal_republic_population_complete", false)) \
or bool(realm.get("federal_republic_population_stream_complete", false)):
				return true

			if bool(realm.get("federal_republic_population_pending_after_player_control", false)) \
or bool(realm.get("federal_republic_population_streaming", false)) \
or bool(realm.get("federal_republic_population_stream_jobs_pending_after_player_control", false)):
				return false

	return true


static func _population_lens_incremental_section_specs(
	view_contract: Dictionary,
	realm_accent: Color,
	element: String,
	federal_republic: bool
) -> Array:
	var section_contracts_raw: Variant = (
		view_contract.get(
			"population_section_contracts",
			[]
		)
	)
	var section_contracts: Array = (
		section_contracts_raw as Array
		if typeof(
			section_contracts_raw
		) == TYPE_ARRAY
		else []
	)
	var specs: Array = []

	if not section_contracts.is_empty():
		for raw_section in section_contracts:
			var section: Dictionary = (
				ValueSceneSupport._safe_dictionary(
					raw_section
				)
			)

			if section.is_empty():
				continue

			var rows: Array = ValueSceneSupport._safe_array(
				section.get(
					"rows",
					[]
				)
			)

			if rows.is_empty():
				continue

			var accent: Color = (
				PopulationSceneSupport._population_lens_incremental_section_accent(
					str(
						section.get(
							"accent_key",
							""
						)
					),
					realm_accent
				)
			)

			specs.append({
				"key": str(
					section.get(
						"key",
						"population"
					)
				),
				"title": str(
					section.get(
						"title",
						"POPULATION"
					)
				),
				"subtitle": str(
					section.get(
						"subtitle",
						""
					)
				),
				"rows": rows,
				"accent": accent,
				"glow": float(
					section.get(
						"glow",
						0.16
					)
				),
				"columns": int(
					section.get(
						"columns",
						5
					)
				),
				"section_kind": str(
					section.get(
						"section_kind",
						section.get(
							"key",
							"population"
						)
					)
				),
				"social_class": str(
					section.get(
						"social_class",
						""
					)
				)
			})

		return specs


	if federal_republic:
		return [
			{
				"key": "federal_executive",
				"title": "EXECUTIVE BRANCH",
				"subtitle": "President and First Family.",
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"federal_executive",
						[]
					)
				),
				"accent": Color(
					0.34,
					0.56,
					1.0,
					1.0
				),
				"glow": 0.36,
				"columns": 2
			},
			{
				"key": "federal_cabinet",
				"title": "EXECUTIVE CABINET",
				"subtitle": (
					"Federal executive department leadership."
				),
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"federal_cabinet",
						[]
					)
				),
				"accent": Color(
					0.42,
					0.66,
					1.0,
					1.0
				),
				"glow": 0.24,
				"columns": 5
			},
			{
				"key": "federal_senate",
				"title": (
					"LEGISLATIVE BRANCH • SENATE"
				),
				"subtitle": "Two senators per state.",
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"federal_senate",
						[]
					)
				),
				"accent": Color(
					0.38,
					0.54,
					0.98,
					1.0
				),
				"glow": 0.2,
				"columns": 7
			},
			{
				"key": "federal_supreme_court",
				"title": (
					"JUDICIAL BRANCH • SUPREME COURT"
				),
				"subtitle": "Federal judicial authority.",
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"federal_supreme_court",
						[]
					)
				),
				"accent": Color(
					0.7,
					0.56,
					1.0,
					1.0
				),
				"glow": 0.22,
				"columns": 4
			},
			{
				"key": "federal_governor",
				"title": (
					"STATE EXECUTIVES • GOVERNORS"
				),
				"subtitle": (
					"Governors of the geographical states."
				),
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"federal_governors",
						[]
					)
				),
				"accent": Color(
					0.48,
					0.82,
					0.62,
					1.0
				),
				"glow": 0.18,
				"columns": 7
			},
			{
				"key": "citizen",
				"title": "CITIZENS",
				"subtitle": (
					"Resident civilian population."
				),
				"rows": ValueSceneSupport._safe_array(
					view_contract.get(
						"citizens",
						[]
					)
				),
				"accent": realm_accent,
				"glow": 0.14,
				"columns": 7
			}
		]

	return [
		{
			"key": "official",
			"title": "ROYAL COURT",
			"subtitle": (
				"Ruler, partner, heirs, and sovereignty offices."
			),
			"rows": ValueSceneSupport._safe_array(
				view_contract.get(
					"royals",
					view_contract.get(
						"officials",
						[]
					)
				)
			),
			"accent": Color(
				1.0,
				0.78,
				0.24,
				1.0
			),
			"glow": 0.34,
			"columns": 4
		},
		{
			"key": "noble",
			"title": "NOBLE COURT",
			"subtitle": (
				"High noble houses and territorial authorities."
			),
			"rows": ValueSceneSupport._safe_array(
				view_contract.get(
					"nobles",
					[]
				)
			),
			"accent": Color(
				0.78,
				0.56,
				1.0,
				1.0
			),
			"glow": 0.28,
			"columns": 4
		},
		{
			"key": "master",
			"title": (
				"%s BENDING MASTERS"
				% element.to_upper()
				if element != ""
				else "MASTERS"
			),
			"subtitle": (
				"Realm-aligned masters and high-skill residents."
			),
			"rows": ValueSceneSupport._safe_array(
				view_contract.get(
					"masters",
					[]
				)
			),
			"accent": realm_accent,
			"glow": 0.42,
			"columns": 5
		},
		{
			"key": "citizen",
			"title": "CITIZENS",
			"subtitle": "Resident civilian population.",
			"rows": ValueSceneSupport._safe_array(
				view_contract.get(
					"citizens",
					[]
				)
			),
			"accent": realm_accent,
			"glow": 0.14,
			"columns": 7
		}
	]


static func _resolve_surface_realm_dict(gs: GameState,
	raw_realm_id: Variant) -> Dictionary:
	var out: Dictionary = {}
	if gs == null or gs.realm_engine == null:
		return out

	var realms_raw: Variant = gs.realm_engine.realms
	var realms: Dictionary = realms_raw if typeof(realms_raw) == TYPE_DICTIONARY else {}

	var raw_key: String = str(raw_realm_id).strip_edges()
	var int_key: int = int(raw_realm_id)
	var realm_raw: Variant = {}

	if realms.has(raw_realm_id):
		realm_raw = realms.get(raw_realm_id, {})
	elif raw_key != "" and realms.has(raw_key):
		realm_raw = realms.get(raw_key, {})
	elif realms.has(int_key):
		realm_raw = realms.get(int_key, {})
	else:
		realm_raw = {}

	out = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
	if out.is_empty():
		return out

	if int_key > 0 and gs.realm_engine.has_method("ensure_realm_defaults"):
		var hydrated: Dictionary = gs.realm_engine.ensure_realm_defaults(int_key)
		if not hydrated.is_empty():
			out = hydrated

	return out


static func _crown_population_uses_federal_republic_lens(gs: GameState,
	realm_id: int, realm_name: String = "") -> bool:
	var resolved_name: String = str(realm_name).strip_edges()
	if resolved_name == "":
		resolved_name = GovernmentSceneSupport._crown_realm_name(gs, realm_id)

	var name_key: String = resolved_name.strip_edges().to_lower()
	var compact_name: String = name_key.replace(".", "").replace(" ", "").replace("-", "")

	if compact_name in [
		"usa",
		"us",
		"unitedstates",
		"unitedstatesofamerica",
		"america"
	]:
		return true

	if gs != null and gs.realm_engine != null and "realms" in gs.realm_engine and typeof(gs.realm_engine.realms) == TYPE_DICTIONARY:
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		if typeof(realm_raw) == TYPE_DICTIONARY:
			var realm: Dictionary = realm_raw
			var government_model: String = str(realm.get("government_model", "")).strip_edges().to_lower()
			var government_style: String = str(realm.get("government_style", realm.get("government", ""))).strip_edges().to_lower()

			if bool(realm.get("federal_republic_population_contract", false)):
				return true

			if government_model in [
				"federal_presidential_republic",
				"federal_republic",
				"presidential_republic",
				"constitutional_republic"
			]:
				return true

			if government_style in [
				"federal republic",
				"presidential republic",
				"constitutional republic"
			]:
				return true

	return false


static func _crown_population_noble_title_from_person(target: Person, _realm_id: int = -1) -> String:
	if target == null:
		return ""

	var royal_title_text: String = str(target.royal_title).strip_edges()
	var royal_title_match: String = PopulationSceneSupport._crown_population_noble_title_from_text(royal_title_text)
	if royal_title_match != "":
		return royal_title_match

	var social_class_text: String = str(target.social_class).strip_edges()
	var social_title_match: String = PopulationSceneSupport._crown_population_noble_title_from_text(social_class_text)
	if social_title_match != "":
		return social_title_match

	var job_text: String = str(target.job).strip_edges()
	var job_title_match: String = PopulationSceneSupport._crown_population_noble_title_from_text(job_text)
	if job_title_match != "":
		return job_title_match

	var social_key: String = social_class_text.to_lower()
	var gender_text: String = str(target.gender).strip_edges().to_lower()

	if social_key in [
		"noble",
		"nobility",
		"aristocrat",
		"aristocracy",
		"upper nobility",
		"high nobility"
	]:
		var succession_rank: int = int(target.succession_rank)

		if succession_rank > 0 and succession_rank <= 8:
			return "Duchess" if gender_text == "female" else "Duke"

		if succession_rank > 8 and succession_rank <= 12:
			return "Marchioness" if gender_text == "female" else "Marquess"

		return "Lady" if gender_text == "female" else "Lord"

	return ""


static func _crown_population_is_ruler_partner_card(gs: GameState,
	target: Person, realm_id: int) -> bool:
	if target == null or not target.alive:
		return false

	if PopulationSceneSupport._crown_population_is_throne_holder(gs, target, realm_id):
		return true

	var ruler: Person = PopulationSceneSupport._crown_population_realm_ruler_for(gs, realm_id)
	if ruler == null:
		return false

	if target.partner != null and int(target.partner.id) == int(ruler.id):
		return true

	if ruler.partner != null and int(ruler.partner.id) == int(target.id):
		return true

	return false


static func _crown_population_person_matches_realm(gs: GameState,
	target: Person, realm_id: int, realm_name: String = "") -> bool:
	if target == null or not target.alive:
		return false

	if realm_id > 0 and int(target.realm_id) == realm_id:
		return true

	var resolved_realm_name: String = str(realm_name).strip_edges()
	if resolved_realm_name == "":
		resolved_realm_name = GovernmentSceneSupport._crown_realm_name(gs, realm_id)

	var normalized_realm_name: String = resolved_realm_name.strip_edges().to_lower()
	if normalized_realm_name == "":
		return false

	var aliases: Dictionary = {}
	if gs != null and gs.realm_engine != null and gs.realm_engine.has_method("_normalize_realm_match_aliases"):
		aliases = gs.realm_engine._normalize_realm_match_aliases(resolved_realm_name)

	for raw_value in [
		str(target.home_country),
		str(target.birth_country),
		str(target.bending_nation)
	]:
		var value: String = str(raw_value).strip_edges().to_lower()
		if value == "":
			continue
		if value == normalized_realm_name or aliases.has(value):
			return true

	return false


static func _crown_population_uses_modern_class_lens(gs: GameState,
	realm_id: int, realm_name: String = "") -> bool:
	var resolved_name: String = str(realm_name).strip_edges()
	if resolved_name == "":
		resolved_name = GovernmentSceneSupport._crown_realm_name(gs, realm_id)

	var name_key: String = resolved_name.strip_edges().to_lower()
	var compact_name: String = name_key.replace(".", "").replace(" ", "").replace("-", "")

	if compact_name in [
		"usa",
		"us",
		"unitedstates",
		"unitedstatesofamerica",
		"america"
	]:
		return true

	if gs != null and gs.realm_engine != null and gs.realm_engine.realms.has(realm_id):
		var realm_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
		var government_style: String = str(realm.get("government_style", "")).strip_edges().to_lower()

		if government_style in [
			"democracy",
			"republic",
			"federal republic",
			"constitutional republic",
			"presidential republic",
			"parliamentary democracy"
		]:
			return true

	return false


static func _crown_population_citizen_strata_order(gs: GameState,
	realm_id: int, realm_name: String = "") -> Array:
	if PopulationSceneSupport._crown_population_uses_modern_class_lens(gs, realm_id, realm_name):
		return [
			"bottom_class",
			"lower_middle_class",
			"middle_class",
			"upper_middle_class",
			"elite"
		]

	return ["peasant", "commoner", "merchant"]


static func _materialize_crown_population_target_for_realm(gs: GameState,
	realm_id: int, realm_name: String = "", capital_city: String = "") -> Person:
	if gs == null or realm_id <= 0:
		return null

	var resolved_realm_name: String = realm_name.strip_edges()
	var resolved_capital_city: String = capital_city.strip_edges()
	var native_element: String = ""
	var is_avatar_nation: bool = false
	if gs.realm_engine != null and gs.realm_engine.has_method("ensure_realm_defaults"):
		var realm: Dictionary = gs.realm_engine.ensure_realm_defaults(realm_id)
		if not realm.is_empty():
			if resolved_realm_name == "":
				resolved_realm_name = str(realm.get("name", "")).strip_edges()
			if resolved_capital_city == "":
				resolved_capital_city = str(realm.get("capital_city", "")).strip_edges()
			if gs.realm_engine.has_method("_realm_element_for_name"):
				native_element = str(gs.realm_engine._realm_element_for_name(resolved_realm_name)).strip_edges().to_lower()
			is_avatar_nation = native_element in ["air", "earth", "fire", "water"]

	var generated: Person = null
	var materialize_filters: Array = []
	if is_avatar_nation:
		materialize_filters.append({
			"realm_id": realm_id,
			"home_country": resolved_realm_name,
			"birth_country": resolved_realm_name,
			"bending_nation": resolved_realm_name,
			"bending_type": native_element
		})
		materialize_filters.append({
			"realm_id": realm_id,
			"home_country": resolved_realm_name,
			"birth_country": resolved_realm_name,
			"bending_nation": resolved_realm_name
		})
		materialize_filters.append({
			"realm_id": realm_id,
			"home_country": resolved_realm_name
		})
	materialize_filters.append({
		"realm_id": realm_id
	})

	for raw_filters in materialize_filters:
		var filters: Dictionary = raw_filters
		if gs.population_lifecycle_manager == null:
			break
		generated = gs.population_lifecycle_manager.materialize_person_from_shard(filters)
		if generated != null:
			break

	if generated == null and gs.realm_engine != null and gs.realm_engine.has_method("create_bootstrap_realm_resident"):
		var bootstrap_role: String = "worker"
		if is_avatar_nation and randi() % 100 < 35:
			bootstrap_role = "soldier"
		generated = gs.realm_engine.create_bootstrap_realm_resident(realm_id, resolved_capital_city, bootstrap_role)

	if generated == null:
		generated = PopulationSceneSupport._synthesize_crown_population_target_for_realm(gs,
			realm_id,
			resolved_realm_name,
			resolved_capital_city,
			native_element,
			is_avatar_nation
		)

	if generated == null:
		return null

	generated.realm_id = realm_id
	var preferred_settlement_id: String = ""
	if gs.geo_engine != null:
		if gs.geo_engine.has_method("bootstrap_for_current_era"):
			gs.geo_engine.bootstrap_for_current_era()
		var options: Array = gs.geo_engine.realm_to_settlements.get(realm_id, [])
		if not options.is_empty():
			preferred_settlement_id = str(options [0])

	if preferred_settlement_id != "" and gs.geo_engine != null and gs.geo_engine.has_method("bootstrap_person_place"):
		gs.geo_engine.bootstrap_person_place(generated, {
			"settlement_id": preferred_settlement_id
		})

	if resolved_realm_name != "":
		generated.home_country = resolved_realm_name
		if str(generated.birth_country).strip_edges() == "":
			generated.birth_country = resolved_realm_name
	if resolved_capital_city != "":
		if str(generated.home_city).strip_edges() == "":
			generated.home_city = resolved_capital_city
		if str(generated.birth_city).strip_edges() == "":
			generated.birth_city = resolved_capital_city

	if is_avatar_nation:
		if str(generated.bending_nation).strip_edges() == "":
			generated.bending_nation = resolved_realm_name
		var current_bending_type: String = str(generated.bending_type).strip_edges().to_lower()
		if current_bending_type == "" or current_bending_type == "none":
			generated.bending_type = native_element
		if typeof(generated.bending_mastery) != TYPE_DICTIONARY:
			generated.bending_mastery = {}
		var mastery: Dictionary = generated.bending_mastery
		mastery [native_element] = max(1, int(mastery.get(native_element, 0)))
		generated.bending_mastery = mastery

	if gs.realm_engine != null and gs.realm_engine.has_method("_apply_elemental_realm_identity_to_npc"):
		gs.realm_engine._apply_elemental_realm_identity_to_npc(generated, resolved_realm_name)

	return generated


static func _synthesize_crown_population_target_for_realm(gs: GameState,
	realm_id: int, realm_name: String, capital_city: String, native_element: String, is_avatar_nation: bool) -> Person:
	if gs == null or gs.npc_factory == null or realm_id <= 0:
		return null

	var generated: Person = gs.npc_factory.create_random_npc(false)
	if generated == null:
		return null

	gs.apply_reality_rules_to_person(generated)

	generated.realm_id = realm_id
	generated.is_ruler = false
	generated.is_royal = false
	generated.deposed = false
	generated.exiled = false
	generated.palace_owned = false
	generated.royal_title = ""
	generated.succession_rank = 99

	if realm_name.strip_edges() != "":
		generated.home_country = realm_name
		generated.birth_country = realm_name

	if capital_city.strip_edges() != "":
		generated.home_city = capital_city
		generated.birth_city = capital_city

	var era_name: String = str(gs.era.name if gs != null and gs.era != null else "Modern Era")
	var synthetic_role: String = "worker"

	if is_avatar_nation and randi() % 100 < 35:
		synthetic_role = "soldier"

	if synthetic_role == "soldier":
		generated.social_class = "Commoner"
		if era_name == "Ancient Era":
			generated.job = ["Warrior", "Guard", "Spearman", "Archer"].pick_random()
		elif era_name == "Medieval Era":
			generated.job = ["Guard", "Watchman", "Soldier", "Militia"].pick_random()
		else:
			generated.job = ["Soldier", "Guard", "Militia", "Officer"].pick_random()
	else:
		if era_name == "Ancient Era":
			generated.social_class = ["Commoner", "Peasant", "Merchant"].pick_random()
			generated.job = ["Farmer", "Builder", "Artisan", "Trader", "Fisher"].pick_random()
		elif era_name == "Medieval Era":
			generated.social_class = ["Peasant", "Commoner", "Merchant"].pick_random()
			generated.job = ["Farmer", "Blacksmith", "Mason", "Merchant", "Artisan"].pick_random()
		else:
			generated.social_class = ["Commoner", "Commoner", "Merchant"].pick_random()
			generated.job = ["Worker", "Laborer", "Merchant", "Artisan", "Dockhand"].pick_random()

	if era_name == "Ancient Era" and is_avatar_nation:
		var lineage_place: String = capital_city.strip_edges()
		if lineage_place == "":
			lineage_place = realm_name.strip_edges()
		if lineage_place != "":
			generated.last_name = "of %s" % lineage_place

	if is_avatar_nation:
		generated.bending_nation = realm_name
		var current_bending_type: String = str(generated.bending_type).strip_edges().to_lower()
		if current_bending_type == "" or current_bending_type == "none":
			generated.bending_type = native_element
			if typeof(generated.bending_mastery) != TYPE_DICTIONARY:
				generated.bending_mastery = {}
			var mastery: Dictionary = generated.bending_mastery
			mastery [native_element] = max(1, int(mastery.get(native_element, 0)))
			generated.bending_mastery = mastery

	if gs.population_lifecycle_manager != null and gs.population_lifecycle_manager.has_method("inject_live_population_personality"):
		gs.population_lifecycle_manager.inject_live_population_personality(generated, {
			"realm_id": realm_id,
			"home_country": realm_name,
			"source": "crown_fallback_synth"
		})

	if not gs.npcs.has(generated):
		gs.npcs.append(generated)

	if gs.geo_engine != null and gs.geo_engine.has_method("bootstrap_person_place"):
		var preferred_settlement_id: String = ""
		if gs.geo_engine.has_method("bootstrap_for_current_era"):
			gs.geo_engine.bootstrap_for_current_era()
		var options: Array = gs.geo_engine.realm_to_settlements.get(realm_id, [])
		if not options.is_empty():
			preferred_settlement_id = str(options [0])
		if preferred_settlement_id != "":
			gs.geo_engine.bootstrap_person_place(generated, {
				"settlement_id": preferred_settlement_id
			})

	if gs.world_space_engine != null:
		gs.world_space_engine.place_npc(generated)

	if gs.chunk_simulation_engine != null:
		gs.chunk_simulation_engine.assign_npc(generated)

	return generated
