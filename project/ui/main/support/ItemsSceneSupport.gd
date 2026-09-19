extends RefCounted
class_name ItemsSceneSupport
## Items support for the main scene. State, when needed, is passed explicitly.


static func _artifact_shop_rarity_color(
	rarity: String
) -> Color:
	match rarity.strip_edges().to_lower():
		"common":
			return Color(
				0.64,
				0.66,
				0.72,
				1.0
			)

		"uncommon":
			return Color(
				0.36,
				0.9,
				0.48,
				1.0
			)

		"rare":
			return Color(
				0.28,
				0.62,
				1.0,
				1.0
			)

		"epic":
			return Color(
				0.68,
				0.36,
				1.0,
				1.0
			)

		"legendary":
			return Color(
				1.0,
				0.72,
				0.18,
				1.0
			)

		"mythic":
			return Color(
				1.0,
				0.34,
				0.7,
				1.0
			)

		"cosmic":
			return Color(
				0.3,
				0.92,
				1.0,
				1.0
			)

		"divine":
			return Color(
				1.0,
				0.92,
				0.58,
				1.0
			)

	return Color(
		0.82,
		0.84,
		0.92,
		1.0
	)


static func _rick_weapon_shop_population_count_text(value: int) -> String:
	var clean_value: int = max(0, int(value))
	if clean_value == 1:
		return "1 person"
	return "%d people" % clean_value


static func _rick_weapon_shop_tracker_title(tracker_key: String) -> String:
	match tracker_key:
		"walking_by":
			return "People Walking By"
		"walking_in":
			return "People Walking In"
		"walking_out":
			return "People Walking Out"
		"browsing":
			return "People Browsing"
		"checking_out":
			return "Person Checking Out"
		"inside_all":
			return "People In The Store"
		_:
			return "Live People"


static func _rick_weapon_shop_weapon_danger_scope(weapon: Dictionary) -> String:
	var weapon_type: String = str(weapon.get("type", "weapon")).strip_edges().to_lower()
	var legal: bool = bool(weapon.get("legal", true))
	var license_required: bool = bool(weapon.get("license_required", false))

	if not legal:
		return "Restricted / reputation-warping / guard-attracting"

	match weapon_type:
		"gun":
			return "High lethality, loud consequences" if license_required else "High lethality, fast escalation"
		"energy":
			return "Reality-bending tech danger"
		"blade":
			return "Close-range danger, personal consequences"
		"ranged":
			return "Distance danger, confidence trap"
		_:
			return "Unknown object danger, which is Rick's least favorite kind"


static func _rick_weapon_shop_weapon_disaster_line(weapon: Dictionary) -> String:
	var weapon_type: String = str(weapon.get("type", "weapon")).strip_edges().to_lower()
	match weapon_type:
		"blade":
			return "I saw one of those turn a wedding into a family tree with missing branches."
		"ranged":
			return "I saw somebody miss the target and hit their grandma once."
		"gun":
			return "I saw one make a loud man quiet and a quiet room happy."
		"energy":
			return "I saw one turn a locked door into weather. Nobody enjoyed the breeze."
		_:
			return "I saw one go wrong once. The object apologized before the person did."


static func _rick_weapon_shop_live_flow_count(rng: RandomNumberGenerator, chance: float = 0.65, max_group: int = 5) -> int:
	var clean_chance: float = clamp(chance, 0.0, 1.0)
	var clean_max: int = int(clamp(max_group, 1, 5))
	if rng.randf() > clean_chance:
		return 0

	var roll: float = rng.randf()
	if clean_max >= 5 and roll >= 0.96:
		return 5
	if clean_max >= 4 and roll >= 0.9:
		return 4
	if clean_max >= 3 and roll >= 0.78:
		return 3
	if clean_max >= 2 and roll >= 0.54:
		return 2
	return 1


static func _rick_weapon_shop_random_jitter_ms(min_ms: int, max_ms: int) -> int:
	var rng:= RandomNumberGenerator.new()
	rng.randomize()
	return int(rng.randi_range(min_ms, max_ms))


static func _rick_weapon_shop_random_checkout_line() -> String:
	var rng:= RandomNumberGenerator.new()
	rng.randomize()
	var lines: Array = [
		"Customer: \"Thanks, Rick.\"\nRick: \"Try not to make the local guards learn your name.\"",
		"Customer: \"Do you do refunds?\"\nRick: \"Only in timelines nobody likes.\"",
		"Customer: \"Bye, Rick.\"\nRick: \"Walk slowly. Fast people explain themselves to doctors.\"",
		"Customer: \"Is this safe?\"\nRick: \"That question gets cheaper before the purchase.\""
	]
	return str(lines [int(rng.randi_range(0, lines.size() - 1))])


static func _rick_weapon_shop_section_panel(bg_color: Color, border_color: Color) -> PanelContainer:
	var panel:= PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style:= StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(1.0, 0.38, 0.1, 0.14)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)

	var margin:= MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	panel.set_meta("margin", margin)

	return panel


static func _rick_weapon_shop_clean_location_value(raw_value: Variant) -> String:
	if raw_value == null:
		return ""
	var text: String = str(raw_value).strip_edges()
	var lowered: String = text.to_lower()
	if text == "" or lowered in ["<null>", "null", "none", "nil", "n/a", "unknown"]:
		return ""
	return text


static func _rick_weapon_shop_local_culture_tag(country: String) -> String:
	var normalized: String = str(country).strip_edges().to_lower()
	var exact_map: Dictionary = {
		"china": "Chinese",
		"ancient china": "Chinese",
		"greece": "Greek",
		"ancient greece": "Greek",
		"mali": "from Mali",
		"mali empire": "from Mali",
		"assyria": "Assyrian",
		"assyrian empire": "Assyrian",
		"mexico": "Mexican",
		"canada": "Canadian",
		"united states": "American",
		"america": "American",
		"usa": "American"
	}

	if exact_map.has(normalized):
		return str(exact_map.get(normalized))
	if normalized.find("air temple") >= 0:
		return "a monk"
	if normalized.find("fire nation") >= 0:
		return "Fire Nation"
	if normalized.find("earth kingdom") >= 0:
		return "Earth Kingdom"
	if normalized.find("southern water") >= 0:
		return "Southern Water Nation"
	if normalized.find("northern water") >= 0:
		return "Northern Water Nation"
	if normalized.find("water tribe") >= 0:
		return "Water Tribe"
	if normalized.find("china") >= 0:
		return "Chinese"
	if normalized.find("mali") >= 0:
		return "from Mali"
	if normalized.find("assyr") >= 0:
		return "Assyrian"
	if normalized.find("mexico") >= 0:
		return "Mexican"
	if normalized.find("canada") >= 0:
		return "Canadian"
	if normalized.find("america") >= 0 or normalized.find("united states") >= 0:
		return "American"

	var clean_country: String = str(country).strip_edges()
	if clean_country == "":
		return "local"
	return "from %s" % clean_country


static func _artifact_item_color(item: Dictionary) -> Color:
	var color_key: String = str(item.get("color", "")).strip_edges().to_lower()
	var item_name: String = str(item.get("name", "")).strip_edges().to_lower()
	var dragon_star: int = int(item.get("star", 0))

	if dragon_star <= 0 and item_name.findn("-star dragon ball") != -1:
		var star_chunks: PackedStringArray = item_name.split("-star dragon ball")
		if star_chunks.size() > 0:
			dragon_star = int(star_chunks [0])

	if color_key == "":
		if item_name.findn("red bonnet") != -1:
			color_key = "red"
		elif item_name.findn("dragon ball") != -1:
			color_key = "orange"
		elif item_name.findn("gauntlet") != -1:
			color_key = "gold"

	match color_key:
		"red":
			return Color(1.0, 0.26, 0.24, 1.0)
		"blue":
			return Color(0.28, 0.72, 1.0, 1.0)
		"green", "emerald":
			return Color(0.24, 1.0, 0.54, 1.0)
		"yellow":
			return Color(1.0, 0.91, 0.26, 1.0)
		"orange":
			if item_name.findn("dragon ball") != -1 or dragon_star > 0:
				var star_heat: float = clamp(float(max(dragon_star, 1) - 1) / 6.0, 0.0, 1.0)
				return Color(1.0, 0.62, 0.22, 1.0).lerp(Color(1.0, 0.82, 0.3, 1.0), 0.18 + star_heat * 0.34)
			return Color(1.0, 0.62, 0.22, 1.0)
		"violet", "purple":
			return Color(0.72, 0.48, 1.0, 1.0)
		"gold":
			return Color(1.0, 0.84, 0.36, 1.0)
		"silver":
			return Color(0.84, 0.9, 1.0, 1.0)
		"white":
			return Color(0.96, 0.98, 1.0, 1.0)
		"crimson":
			return Color(1.0, 0.3, 0.42, 1.0)
		_:
			return Color(1.0, 0.82, 0.36, 1.0)


static func _belonging_item_is_food(item: Dictionary, category: String) -> bool:
	var clean_category: String = str(category).strip_edges().to_lower()
	var item_type: String = str(item.get("type", "")).strip_edges().to_lower()

	if clean_category == "food":
		return true
	if item_type == "food" or item_type == "grocery":
		return true
	if item.has("hunger_restore") or item.has("nutrition"):
		return true
	if str(item.get("source", "")).strip_edges().to_lower().find("grocery") >= 0:
		return true

	return false


static func _belonging_food_item_id(item: Dictionary) -> int:
	return int(item.get("id", item.get("item_id", -1)))


static func _belonging_food_action_button_style(_item: Dictionary, strength: float, hovered: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	var core: Color = Color(1.0, 0.58, 0.28, 1.0)
	style.bg_color = Color(core.r * 0.22, core.g * 0.18, core.b * 0.12, 0.42 + strength * 0.2)
	style.border_color = Color(core.r, core.g, core.b, 0.58 + strength * 0.24)
	style.shadow_color = Color(core.r, core.g * 0.75, core.b * 0.45, 0.22 + strength * 0.18)
	style.shadow_size = 18 if hovered else 10
	style.shadow_offset = Vector2.ZERO
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


static func _rick_weapon_shop_hub_available_shell_safe(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false
	if gs.awaiting_new_life:
		return false
	if gs.weapons_engine == null:
		return false

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var snapshot: Dictionary = ValueSceneSupport._safe_dictionary(gs.scenario_state.get("runtime_hud_visibility_snapshot", {}))
		if snapshot.has("rick_weapon_shop_available"):
			return bool(snapshot.get("rick_weapon_shop_available", false))

	return ItemsSceneSupport._rick_weapon_shop_hub_available(gs)


static func _rick_weapon_shop_hub_available(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false
	if gs.awaiting_new_life:
		return false
	if gs.weapons_engine == null:
		return false
	if gs.weapons_engine.has_method("get_store"):
		return not gs.weapons_engine.get_store().is_empty()
	return true


static func _rick_weapon_shop_should_show_recognition(gs: GameState,
	contract: Dictionary) -> bool:
	if gs == null or gs.player == null:
		return false

	var actor_id: int = int(gs.player.id)
	for raw_entry in ValueSceneSupport._safe_array(contract.get("transaction_log", [])):
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry as Dictionary
		if int(entry.get("actor_id", -1)) == actor_id and bool(entry.get("success", false)):
			return true

	return false


static func _rick_weapon_shop_population_badge_text(label_text: String, value: int, show_value: bool = true) -> String:
	var clean_label: String = str(label_text).strip_edges()
	if not show_value:
		return clean_label

	var lowered: String = clean_label.to_lower()
	var suffix: String = clean_label

	if lowered == "people" or lowered == "person":
		suffix = ""
	elif lowered.begins_with("people "):
		suffix = clean_label.substr(7).strip_edges()
	elif lowered.begins_with("person "):
		suffix = clean_label.substr(7).strip_edges()

	var count_text: String = ItemsSceneSupport._rick_weapon_shop_population_count_text(value)
	if suffix == "":
		return count_text

	return "%s %s" % [count_text, suffix]


static func _rick_weapon_shop_inside_live_text(contract: Dictionary, state: Dictionary) -> String:
	var inside: Dictionary = ValueSceneSupport._safe_dictionary(state.get("inside", {}))
	var lines: Array = []

	var last_live_line: String = str(inside.get("last_live_line", "")).strip_edges()
	if last_live_line != "":
		lines.append(last_live_line)

	var rick_live_text: String = str(inside.get("rick_live_text", "")).strip_edges()
	if rick_live_text != "":
		lines.append(rick_live_text)
	else:
		lines.append(ItemsSceneSupport._rick_weapon_shop_rick_greeting(contract))

	return "\n\n".join(lines)


static func _rick_weapon_shop_rick_greeting(contract: Dictionary) -> String:
	var vendor: Dictionary = ValueSceneSupport._safe_dictionary(contract.get("vendor", {}))
	var vendor_name: String = str(vendor.get("display_name", "Rick"))
	return "%s looks up before the door finishes opening.\nRick: \"Take your time. The wall always tells me what people think they need.\"" % vendor_name


static func _rick_weapon_shop_find_weapon(weapon_name: String, contract: Dictionary) -> Dictionary:
	for raw_weapon in ValueSceneSupport._safe_array(contract.get("inventory", [])):
		if typeof(raw_weapon) != TYPE_DICTIONARY:
			continue
		var weapon: Dictionary = raw_weapon as Dictionary
		var current_name: String = str(weapon.get("name", weapon.get("display_name", ""))).strip_edges()
		if current_name == weapon_name:
			return weapon.duplicate(true)
	return {}


static func _rick_weapon_shop_line_for_selected_weapon(weapon: Dictionary, contract: Dictionary) -> String:
	if weapon.is_empty():
		return "Rick squints at the wall.\nRick: \"Point at the thing, not the idea of the thing.\""

	var weapon_name: String = str(weapon.get("name", weapon.get("display_name", "that"))).strip_edges()
	var handling_line: String = str(weapon.get("rick_line", "")).strip_edges()
	var danger_scope: String = ItemsSceneSupport._rick_weapon_shop_weapon_danger_scope(weapon)
	var overview: String = ItemsSceneSupport._rick_weapon_shop_weapon_overview(weapon, contract)
	var disaster: String = ItemsSceneSupport._rick_weapon_shop_weapon_disaster_line(weapon)

	var live_lines: Array = []
	live_lines.append("Rick follows your eyes to the %s." % weapon_name)
	if handling_line != "":
		live_lines.append(handling_line)
	live_lines.append("Danger scope: %s." % danger_scope)
	live_lines.append(overview)
	live_lines.append("Rick: \"%s\"" % disaster)

	return "\n".join(live_lines)


static func _rick_weapon_shop_weapon_overview(weapon: Dictionary, contract: Dictionary) -> String:
	var commerce: Dictionary = ValueSceneSupport._safe_dictionary(contract.get("commerce", {}))
	var currency: String = str(commerce.get("currency", "coins"))
	return "%s costs %d %s. Legal status: %s. License: %s." % [
		str(weapon.get("name", weapon.get("display_name", "This weapon"))),
		int(weapon.get("cost", 0)),
		currency,
		str(weapon.get("legality_label", "Legal")),
		str(weapon.get("license_label", "No License Required"))
	]


static func _rick_weapon_shop_best_era(gs: GameState) -> String:
	if gs != null and gs.era != null:
		var era_text: String = str(gs.era.name if "name" in gs.era else gs.era).strip_edges()
		if era_text != "":
			return era_text
	return "Modern Era"


static func _rick_weapon_shop_best_country(gs: GameState) -> String:
	if gs != null and gs.player != null:
		for key in ["country", "birth_country", "current_country", "home_country"]:
			var value: String = ItemsSceneSupport._rick_weapon_shop_clean_location_value(gs.player.get(key) if gs.player.has_method("get") else "")
			if value != "":
				return value

	if gs != null and typeof(gs.scenario_state) == TYPE_DICTIONARY:
		for key in ["country", "birth_country", "current_country", "home_country"]:
			var state_country: String = ItemsSceneSupport._rick_weapon_shop_clean_location_value(gs.scenario_state.get(key, ""))
			if state_country != "":
				return state_country

	return "United States"


static func _rick_weapon_shop_best_city(gs: GameState) -> String:
	if gs != null and gs.player != null:
		for key in ["city", "birth_city", "current_city", "home_city"]:
			var value: String = ItemsSceneSupport._rick_weapon_shop_clean_location_value(gs.player.get(key) if gs.player.has_method("get") else "")
			if value != "":
				return value

	if gs != null and typeof(gs.scenario_state) == TYPE_DICTIONARY:
		for key in ["city", "birth_city", "current_city", "home_city"]:
			var state_city: String = ItemsSceneSupport._rick_weapon_shop_clean_location_value(gs.scenario_state.get(key, ""))
			if state_city != "":
				return state_city

	return "Unknown City"


static func _rick_weapon_shop_local_rick_name(country: String) -> String:
	var tag: String = ItemsSceneSupport._rick_weapon_shop_local_culture_tag(country)
	if tag == "":
		return "Rick"
	if tag == "a monk":
		return "Rick but a monk"
	if tag.begins_with("from "):
		return "Rick but %s" % tag
	return "Rick but %s" % tag


static func _style_rick_weapon_shop_button(button: Button, pulse: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.has_meta("era_tool_label"):
		return
	# Reapplying this decorative theme every frame cascades through the HUD.
	# Phones use a steady glow; the button's action and visibility are unchanged.
	if MobileSupport.is_enabled():
		if button.get_meta("mobile_rick_style_applied", false):
			return
		pulse = 0.5

	var btn_style: StyleBoxFlat = AppearanceSceneSupport._runtime_stylebox_flat_from_meta(button, "rick_weapon_shop_button_style", 2, 16)
	if btn_style == null:
		return

	button.begin_bulk_theme_override()
	button.text = "🔫"
	button.tooltip_text = "Open Rick's Universal Weapon Shop"
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	btn_style.bg_color = Color(0.34, 0.18, 0.08, 0.22 + (pulse * 0.12))
	btn_style.border_color = Color(1.0, 0.62, 0.24, 0.55 + (pulse * 0.3))
	button.add_theme_stylebox_override("normal", btn_style)
	button.add_theme_stylebox_override("hover", btn_style)
	button.add_theme_stylebox_override("pressed", btn_style)
	button.end_bulk_theme_override()
	if MobileSupport.is_enabled():
		button.set_meta("mobile_rick_style_applied", true)


static func _belongings_projection_has_asset(gs: GameState,
	actor: Person, category: String, asset_id: int) -> bool:
	if actor == null or gs == null or gs.belongings_engine == null:
		return false
	if asset_id <= 0:
		return false

	var clean_category: String = str(category).strip_edges()
	if clean_category == "":
		return false

	var existing_items: Array = gs.belongings_engine.get_category_items(actor, clean_category)
	for raw_item in existing_items:
		if typeof(raw_item) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw_item as Dictionary
		if int(item.get("id", -1)) == asset_id:
			return true

	return false


static func _player_has_named_artifact(gs: GameState,
	item_name: String) -> bool:
	if gs == null or gs.player == null or gs.belongings_engine == null:
		return false
	return gs.belongings_engine.has_item_named(gs.player, "Artifacts", item_name)


static func _player_has_infinity_gauntlet_artifact(gs: GameState) -> bool:
	return ItemsSceneSupport._player_has_named_artifact(gs, "Infinity Gauntlet")


static func _build_artifact_card_style(item: Dictionary, aura_strength: float) -> StyleBoxFlat:
	var accent: Color = ItemsSceneSupport._artifact_item_color(item)
	var item_name: String = str(item.get("name", "")).strip_edges().to_lower()

	var style:= StyleBoxFlat.new()
	var base_bg: Color = Color(0.08, 0.1, 0.14, 0.94).lerp(Color(accent.r, accent.g, accent.b, 0.16), 0.18)

	if item_name.findn("gauntlet") != -1:
		base_bg = base_bg.lerp(Color(1.0, 0.96, 0.78, base_bg.a), 0.1 * aura_strength)
	elif item_name.findn("red bonnet") != -1:
		base_bg = base_bg.lerp(Color(0.3, 0.09, 0.1, base_bg.a), 0.18 * aura_strength)

	style.bg_color = base_bg
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(accent.r, accent.g, accent.b, 0.38 + aura_strength * 0.34)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.14 + aura_strength * 0.24)
	style.shadow_size = 5 + int(round(aura_strength * 6.0))
	style.shadow_offset = Vector2(0, 0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


static func _build_artifact_button_style(item: Dictionary, aura_strength: float, is_hovered: bool = false) -> StyleBoxFlat:
	var accent: Color = ItemsSceneSupport._artifact_item_color(item)
	var item_name: String = str(item.get("name", "")).strip_edges().to_lower()
	var style:= StyleBoxFlat.new()
	var bg_alpha: float = 0.1 + aura_strength * 0.1 + (0.06 if is_hovered else 0.0)
	var border_alpha: float = 0.5 + aura_strength * 0.3 + (0.1 if is_hovered else 0.0)
	var glow_alpha: float = 0.18 + aura_strength * 0.24 + (0.08 if is_hovered else 0.0)
	var bg_color: Color = Color(accent.r, accent.g, accent.b, bg_alpha)

	if item_name.findn("gauntlet") != -1:
		bg_color = bg_color.lerp(Color(1.0, 0.96, 0.78, bg_color.a), 0.16 * aura_strength)
	elif item_name.findn("red bonnet") != -1:
		bg_color = bg_color.lerp(Color(1.0, 0.3, 0.3, bg_color.a), 0.12 * aura_strength)

	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	style.shadow_color = Color(accent.r, accent.g, accent.b, glow_alpha)
	style.shadow_size = 6 + int(round(aura_strength * 4.0)) + (1 if is_hovered else 0)
	style.shadow_offset = Vector2(0, 0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


static func _resolve_belonging_market_profile(gs: GameState,
	item: Dictionary) -> Dictionary:
	var item_type: String = str(item.get("type", item.get("subtype", ""))).strip_edges()
	var lore: String = str(item.get("lore", "")).strip_edges()

	var base_value: int = int(item.get("base_value", item.get("value", 0)))
	if base_value <= 0 and item.has("worth"):
		base_value = int(item.get("worth", 0))
	if base_value <= 0 and item.has("price"):
		base_value = int(item.get("price", 0))
	if base_value <= 0 and item.has("estimated_value"):
		base_value = int(item.get("estimated_value", 0))

	var annual_appreciation_rate: float = float(item.get("annual_appreciation_rate", 0.0))

	var acquired_year: int = int(item.get("acquired_year", 0))
	if acquired_year == 0 and typeof(item.get("provenance", {})) == TYPE_DICTIONARY:
		var provenance: Dictionary = item.get("provenance", {})
		acquired_year = int(provenance.get("acquired_year", 0))

	if item_type == "DragonBall":
		var star: int = int(item.get("star", 0))
		var dragon_ball_prices: Dictionary = {
			1: 1000000000,
			2: 2500000000,
			3: 5000000000,
			4: 10000000000,
			5: 15000000000,
			6: 25000000000,
			7: 40000000000
		}
		var dragon_ball_lore: Dictionary = {
			1: "Its glow feels ancient even when resting still.",
			2: "Collectors whisper that this one tends to surface near turning points in history.",
			3: "Its internal light bends like a living flame.",
			4: "The most sentimental traders refuse to name their price for this one.",
			5: "Merchants claim the room changes temperature when it is near.",
			6: "Its glow feels too intelligent to be ordinary treasure.",
			7: "The rarest dealers won't even look directly at it for too long."
		}
		if base_value <= 0 and dragon_ball_prices.has(star):
			base_value = int(dragon_ball_prices [star])
		if annual_appreciation_rate <= 0.0 and base_value > 0:
			annual_appreciation_rate = 0.09
		if lore == "" and dragon_ball_lore.has(star):
			lore = str(dragon_ball_lore [star]).strip_edges()

	elif item_type == "Artifact":
		var artifact_market_profile: Dictionary = (
			ValueSceneSupport._safe_dictionary(
				item.get(
					"artifact_market_profile",
					{}
				)
			)
		)

		if not artifact_market_profile.is_empty():
			if base_value <= 0:
				base_value = int(
					artifact_market_profile.get(
						"base_value",
						artifact_market_profile.get(
							"value",
							0
						)
					)
				)

			if annual_appreciation_rate <= 0.0:
				annual_appreciation_rate = float(
					artifact_market_profile.get(
						"annual_appreciation_rate",
						0.0
					)
				)

			if lore == "":
				lore = str(
					artifact_market_profile.get(
						"lore",
						""
					)
				).strip_edges()

			if not artifact_market_profile.has(
				"historical_value"
			):
				artifact_market_profile [
					"historical_value"
				] = int(
					item.get(
						"historical_value",
						0
					)
				)

			if not artifact_market_profile.has(
				"cultural_value"
			):
				artifact_market_profile [
					"cultural_value"
				] = int(
					item.get(
						"cultural_value",
						0
					)
				)

	var years_held: int = 0
	if gs != null and acquired_year > 0:
		years_held = max(0, int(gs.year) - acquired_year)

	var current_value: int = base_value
	if annual_appreciation_rate > 0.0 and years_held > 0:
		current_value = int(round(float(base_value) * pow(1.0 + annual_appreciation_rate, years_held)))

	return {
		"base_value": base_value,
		"current_value": current_value,
		"annual_appreciation_rate": annual_appreciation_rate,
		"years_held": years_held,
		"lore": lore
	}


static func _resolve_belonging_display_lore(gs: GameState,
	item: Dictionary) -> String:
	var lore: String = str(item.get("lore", "")).strip_edges()
	if lore != "":
		return lore

	var market_profile: Dictionary = ItemsSceneSupport._resolve_belonging_market_profile(gs, item)
	return str(market_profile.get("lore", "")).strip_edges()
