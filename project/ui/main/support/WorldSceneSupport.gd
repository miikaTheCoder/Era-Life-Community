extends RefCounted
class_name WorldSceneSupport
## World support for the main scene. State, when needed, is passed explicitly.


static func _other_country_elemental_needs_definite_article(place_name: String) -> bool:
	var clean_name: String = str(place_name).strip_edges()
	if clean_name == "":
		return false
	var lower_name: String = clean_name.to_lower()
	if lower_name.begins_with("the "):
		return false
	if lower_name == "fire nation":
		return true
	if lower_name == "earth kingdom":
		return true
	if lower_name == "air nomads":
		return true
	if lower_name.find("air temple") >= 0:
		return true
	if lower_name.find("water tribe") >= 0:
		return true
	return false


static func _build_other_country_elemental_palette(element: String) -> Dictionary:
	match element:
		"fire":
			return {
				"display_name": "Fire",
				"aura_bg": Color(0.28, 0.08, 0.05, 0.18),
				"aura_border": Color(1.0, 0.52, 0.22, 0.78),
				"aura_shadow": Color(0.98, 0.44, 0.18, 0.34),
				"card_bg": Color(0.19, 0.09, 0.06, 0.98),
				"card_border": Color(1.0, 0.58, 0.22, 0.84),
				"card_shadow": Color(0.96, 0.42, 0.14, 0.24),
				"header_bg": Color(0.28, 0.12, 0.08, 0.98),
				"header_border": Color(1.0, 0.64, 0.26, 0.88),
				"header_shadow": Color(0.96, 0.42, 0.14, 0.24),
				"button_bg": Color(0.22, 0.1, 0.07, 0.96),
				"button_border": Color(1.0, 0.58, 0.24, 0.84),
				"button_shadow": Color(0.94, 0.38, 0.14, 0.22),
				"hover_bg": Color(0.36, 0.15, 0.1, 1.0),
				"hover_border": Color(1.0, 0.76, 0.38, 1.0),
				"hover_shadow": Color(0.98, 0.5, 0.18, 0.3),
				"header_font": Color(1.0, 0.94, 0.88, 0.99),
				"summary_font": Color(1.0, 0.92, 0.86, 0.92),
				"pulse_a": Color(1.06, 1.02, 1.0, 1.0),
				"pulse_b": Color(1.14, 1.06, 1.02, 1.0)
			}
		"water":
			return {
				"display_name": "Water",
				"aura_bg": Color(0.06, 0.14, 0.22, 0.2),
				"aura_border": Color(0.54, 0.86, 1.0, 0.74),
				"aura_shadow": Color(0.28, 0.64, 1.0, 0.32),
				"card_bg": Color(0.08, 0.14, 0.21, 0.98),
				"card_border": Color(0.58, 0.88, 1.0, 0.82),
				"card_shadow": Color(0.24, 0.54, 0.92, 0.22),
				"header_bg": Color(0.1, 0.18, 0.28, 0.98),
				"header_border": Color(0.7, 0.92, 1.0, 0.88),
				"header_shadow": Color(0.26, 0.56, 0.96, 0.22),
				"button_bg": Color(0.1, 0.17, 0.26, 0.96),
				"button_border": Color(0.58, 0.86, 1.0, 0.82),
				"button_shadow": Color(0.22, 0.5, 0.9, 0.2),
				"hover_bg": Color(0.14, 0.24, 0.36, 1.0),
				"hover_border": Color(0.84, 0.96, 1.0, 1.0),
				"hover_shadow": Color(0.34, 0.66, 1.0, 0.32),
				"header_font": Color(0.94, 0.98, 1.0, 0.99),
				"summary_font": Color(0.9, 0.96, 1.0, 0.92),
				"pulse_a": Color(1.0, 1.04, 1.1, 1.0),
				"pulse_b": Color(1.04, 1.1, 1.18, 1.0)
			}
		"earth":
			return {
				"display_name": "Earth",
				"aura_bg": Color(0.1, 0.16, 0.08, 0.2),
				"aura_border": Color(0.78, 0.92, 0.46, 0.72),
				"aura_shadow": Color(0.5, 0.76, 0.22, 0.3),
				"card_bg": Color(0.1, 0.15, 0.08, 0.98),
				"card_border": Color(0.8, 0.92, 0.52, 0.82),
				"card_shadow": Color(0.44, 0.68, 0.2, 0.22),
				"header_bg": Color(0.15, 0.2, 0.1, 0.98),
				"header_border": Color(0.88, 0.96, 0.64, 0.88),
				"header_shadow": Color(0.48, 0.72, 0.22, 0.22),
				"button_bg": Color(0.13, 0.18, 0.1, 0.96),
				"button_border": Color(0.78, 0.92, 0.5, 0.82),
				"button_shadow": Color(0.4, 0.62, 0.18, 0.2),
				"hover_bg": Color(0.2, 0.26, 0.12, 1.0),
				"hover_border": Color(0.96, 1.0, 0.76, 1.0),
				"hover_shadow": Color(0.52, 0.76, 0.24, 0.3),
				"header_font": Color(0.98, 0.98, 0.9, 0.99),
				"summary_font": Color(0.92, 0.96, 0.86, 0.92),
				"pulse_a": Color(1.02, 1.06, 1.0, 1.0),
				"pulse_b": Color(1.08, 1.12, 1.04, 1.0)
			}
		"air":
			return {
				"display_name": "Air",
				"aura_bg": Color(0.2, 0.16, 0.08, 0.18),
				"aura_border": Color(0.96, 0.9, 0.58, 0.74),
				"aura_shadow": Color(0.92, 0.84, 0.44, 0.3),
				"card_bg": Color(0.18, 0.14, 0.08, 0.98),
				"card_border": Color(0.98, 0.92, 0.66, 0.82),
				"card_shadow": Color(0.88, 0.8, 0.4, 0.22),
				"header_bg": Color(0.24, 0.19, 0.1, 0.98),
				"header_border": Color(1.0, 0.96, 0.76, 0.88),
				"header_shadow": Color(0.92, 0.84, 0.42, 0.22),
				"button_bg": Color(0.22, 0.17, 0.1, 0.96),
				"button_border": Color(0.98, 0.92, 0.64, 0.82),
				"button_shadow": Color(0.84, 0.76, 0.38, 0.2),
				"hover_bg": Color(0.3, 0.24, 0.12, 1.0),
				"hover_border": Color(1.0, 0.98, 0.84, 1.0),
				"hover_shadow": Color(0.94, 0.86, 0.46, 0.3),
				"header_font": Color(1.0, 0.98, 0.9, 0.99),
				"summary_font": Color(0.98, 0.96, 0.86, 0.92),
				"pulse_a": Color(1.04, 1.04, 1.0, 1.0),
				"pulse_b": Color(1.1, 1.1, 1.04, 1.0)
			}

	return {}


static func _apply_other_country_browser_button_palette(button: Button, palette: Dictionary) -> void:
	if button == null:
		return

	var normal_style:= StyleBoxFlat.new()
	normal_style.bg_color = palette.get("button_bg", Color(0.14, 0.16, 0.24, 0.92))
	normal_style.border_color = palette.get("button_border", Color(0.6, 0.7, 0.9, 0.34))
	normal_style.shadow_color = palette.get("button_shadow", Color(0.45, 0.58, 0.9, 0.16))
	normal_style.shadow_size = int(palette.get("button_shadow_size", 8))
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.shadow_offset = Vector2.ZERO
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style:= normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = palette.get("hover_bg", normal_style.bg_color.lightened(0.08))
	hover_style.border_color = palette.get("hover_border", normal_style.border_color.lightened(0.12))
	hover_style.shadow_color = palette.get("hover_shadow", normal_style.shadow_color.lightened(0.1))
	hover_style.shadow_size = int(palette.get("hover_shadow_size", normal_style.shadow_size + 6))
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

	button.add_theme_color_override("font_color", palette.get("header_font", Color(0.94, 0.97, 1.0, 0.98)))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))


static func _build_other_country_elemental_descriptor(element: String) -> Dictionary:
	match element:
		"fire":
			return {
				"display_name": "Fire",
				"intro": "This realm reads like a furnace with a flag—disciplined, dynastic, and always one decree away from ignition.",
				"nature": "Volcanic monarchy, imperial memory, and disciplined combustion.",
				"stat_a": "Heat",
				"stat_b": "Discipline",
				"stat_c": "Imperial Will",
				"stat_d": "Volcanic Pressure",
				"current_title": "EMBER CURRENT",
				"sites_title": "FLAME SEATS",
				"pressure_title": "DYNASTIC PRESSURE",
				"pressure_lines": [
					"The realm values strength, command, and the visible projection of sovereign force.",
					"Its beauty is inseparable from danger: ceremony, steel, ships, heat, and ambition all move together.",
					"Even at rest, the realm feels like it is storing ignition for later."
				]
			}
		"water":
			return {
				"display_name": "Water",
				"intro": "This realm moves like memory held under ice—adaptive, ancestral, and far more dangerous than its stillness first suggests.",
				"nature": "Tidal resilience, ancestral adaptation, and cold luminous sovereignty.",
				"stat_a": "Flow",
				"stat_b": "Adaptation",
				"stat_c": "Tribal Resolve",
				"stat_d": "Ice Pressure",
				"current_title": "TIDAL CURRENT",
				"sites_title": "ICE SEATS",
				"pressure_title": "ANCESTRAL PRESSURE",
				"pressure_lines": [
					"The realm survives by motion, memory, and collective discipline under brutal conditions.",
					"What looks soft from a distance is often the result of extreme resilience up close.",
					"Ice, tide, kinship, and endurance are all part of the same state language here."
				]
			}
		"earth":
			return {
				"display_name": "Earth",
				"intro": "This realm feels tectonic—massive, patient, and too old to rush itself for anyone.",
				"nature": "Continental sovereignty, dynastic stone, and enduring structural power.",
				"stat_a": "Fortitude",
				"stat_b": "Stability",
				"stat_c": "Dynastic Weight",
				"stat_d": "Seismic Pressure",
				"current_title": "TECTONIC CURRENT",
				"sites_title": "STONE SEATS",
				"pressure_title": "CONTINENTAL PRESSURE",
				"pressure_lines": [
					"The realm projects power through durability, scale, and the ability to outlast sudden disruption.",
					"Its authority is less theatrical than fire and less fluid than water, but it can feel immovable when fully aligned.",
					"Stone, law, land, and continuity all reinforce one another here."
				]
			}
		"air":
			return {
				"display_name": "Air",
				"intro": "This realm does not sit heavily in the world. It hovers over it—lucid, elevated, and spiritually charged.",
				"nature": "Sky-bound monastic sovereignty, mobility, clarity, and spiritual lift.",
				"stat_a": "Lift",
				"stat_b": "Harmony",
				"stat_c": "Clarity",
				"stat_d": "Spiritual Pressure",
				"current_title": "SKY CURRENT",
				"sites_title": "HIGH PLACES",
				"pressure_title": "SPIRITUAL PRESSURE",
				"pressure_lines": [
					"The realm expresses power through detachment, mobility, spiritual discipline, and high vantage.",
					"It feels less like a machine of domination and more like a sacred current moving above denser states.",
					"When strained, its pressure shows up as imbalance between serenity and worldly intrusion."
				]
			}

	return {
		"display_name": "Elemental",
		"intro": "This realm is visibly element-aligned and should never render like an ordinary country card.",
		"nature": "Elemental sovereignty.",
		"stat_a": "Alignment",
		"stat_b": "Current",
		"stat_c": "Will",
		"stat_d": "Pressure",
		"current_title": "ELEMENTAL CURRENT",
		"sites_title": "KEY SITES",
		"pressure_title": "STATE PRESSURE",
		"pressure_lines": [
			"The realm carries a visible elemental signature."
		]
	}


static func _append_other_country_contract_special_realms(_out: Array, _seen: Dictionary) -> void:












	return


static func _fallback_country_shell_names_for_era(era_key: String) -> Array:
	var clean_era: String = str(era_key).strip_edges().to_lower()

	if clean_era.find("ancient") >= 0:
		return [
			"Roman Empire",
			"Egypt",
			"Greece",
			"Persia",
			"Carthage",
			"Han China",
			"India",
			"Gaul",
			"Britannia",
			"Germania",
			"Judea",
			"Numidia"
		]

	if clean_era.find("medieval") >= 0:
		return [
			"England",
			"France",
			"Holy Roman Empire",
			"Byzantine Empire",
			"Spain",
			"Portugal",
			"Venice",
			"Japan",
			"China",
			"Mali Empire",
			"Egypt",
			"Mongol Empire"
		]

	if clean_era.find("industrial") >= 0:
		return [
			"United Kingdom",
			"France",
			"Germany",
			"Italy",
			"Russia",
			"United States",
			"Japan",
			"China",
			"India",
			"Brazil",
			"Mexico",
			"Egypt"
		]

	if clean_era.find("future") >= 0:
		return [
			"United States",
			"Neo Canada",
			"European Union",
			"Pan-African Union",
			"Brazilian Federation",
			"Solar Japan",
			"New Korea",
			"Orbital China",
			"Austral Union",
			"Frontier Realm"
		]

	return [
		"United States",
		"Canada",
		"Mexico",
		"Brazil",
		"United Kingdom",
		"France",
		"Germany",
		"Italy",
		"Spain",
		"Nigeria",
		"Egypt",
		"South Africa",
		"India",
		"China",
		"Japan",
		"South Korea",
		"Australia",
		"New Zealand"
	]


static func _other_country_identity_key(value: String) -> String:
	var cleaned: String = str(value).strip_edges().to_lower()
	for ch in [" ", "_", "-", "•", ".", ",", "'", "\"", ":", ";", "/", "\\", "(", ")"]:
		cleaned = cleaned.replace(ch, "")
	return cleaned


static func _other_country_browser_section_title(
	section: String
) -> String:
	match str(
		section
	).strip_edges().to_lower():
		"interrealm_authority":
			return "INTERREALM AUTHORITY"

		"space_realms":
			return "SPACE REALMS"

		"imaginative_realms":
			return "IMAGINATIVE REALMS"

		"elemental_realms":
			return "ELEMENTAL REALMS"

		"standard_realms", "ordinary_realms":
			return "ORDINARY REALMS"

		_:
			return str(
				section
			).replace(
				"_",
				" "
			).to_upper()


static func _other_country_browser_section_priority(
	section: String
) -> int:
	match str(
		section
	).strip_edges().to_lower():
		"interrealm_authority":
			return 0

		"space_realms":
			return 1

		"imaginative_realms":
			return 2

		"elemental_realms":
			return 3

		"standard_realms", "ordinary_realms":
			return 4

		_:
			return 5


static func _elemental_realm_ruler_surface_label(native_element: String) -> String:
	match str(native_element).strip_edges().to_lower():
		"fire":
			return "Fire Lord"
		"water":
			return "Chief"
		"earth":
			return "Earth King"
		"air":
			return "Air Monk"
		_:
			return "Elemental Regent"


static func _other_country_merge_realm_truth_into_surface_realm(surface_realm: Dictionary, truth_realm: Dictionary) -> Dictionary:
	var out: Dictionary = surface_realm.duplicate(true)

	for key in [
		"id",
		"realm_id",
		"name",
		"country",
		"government_style",
		"government_model",
		"government_type",
		"ruler_id",
		"ruler_npc_id",
		"leader_id",
		"ruler_name",
		"leader_name",
		"leader_title",
		"surface_ruler_office",
		"president_person_id",
		"first_partner_person_id",
		"federal_republic_population_contract",
		"federal_executive_person_ids",
		"federal_cabinet_person_ids",
		"federal_senate_person_ids",
		"federal_supreme_court_person_ids",
		"federal_governor_person_ids",
		"federal_citizen_person_ids"
	]:
		if truth_realm.has(key):
			out [key] = truth_realm.get(key)

	if not out.has("population") and truth_realm.has("population"):
		out ["population"] = truth_realm.get("population")
	if not out.has("treasury") and truth_realm.has("treasury"):
		out ["treasury"] = truth_realm.get("treasury")
	if not out.has("military_units") and truth_realm.has("military_units"):
		out ["military_units"] = truth_realm.get("military_units")
	if not out.has("military_stockpile") and truth_realm.has("military_stockpile"):
		out ["military_stockpile"] = truth_realm.get("military_stockpile")

	out ["surface_governance_merged_from_realm_truth"] = true
	out ["ui_is_renderer_only"] = true
	return out


static func _other_country_text_already_has_title(raw_text: String, title_text: String) -> bool:
	var clean_raw: String = str(raw_text).strip_edges().to_lower()
	var clean_title: String = str(title_text).strip_edges().to_lower()
	if clean_raw == "" or clean_title == "":
		return true

	if clean_raw.begins_with(clean_title):
		return true

	return false


static func _other_country_person_plain_name(person: Person) -> String:
	if person == null:
		return "Unknown"

	var first_name: String = str(person.first_name).strip_edges()
	var last_name: String = str(person.last_name).strip_edges()
	var full_name: String = ("%s %s" % [first_name, last_name]).strip_edges()

	if full_name == "":
		full_name = str(person.name).strip_edges()

	if full_name == "":
		full_name = "Unknown"

	return full_name


static func _other_country_ruler_text_is_generic_office(lower_text: String, realm: Dictionary = {}) -> bool:
	var text_value: String = str(lower_text).strip_edges().to_lower()
	if text_value == "":
		return false

	var realm_name: String = str(realm.get("name", "")).strip_edges().to_lower()
	var place_names: Array = []
	if realm_name != "":
		place_names.append(realm_name)
		if realm_name.begins_with("the "):
			place_names.append(realm_name.substr(4).strip_edges())
		else:
			place_names.append("the %s" % realm_name)

	var capital_text: String = str(realm.get("capital", realm.get("capital_city", ""))).strip_edges().to_lower()
	if capital_text != "":
		place_names.append(capital_text)

	var office_prefixes: Array = [
		"president",
		"chancellor",
		"supreme leader",
		"general secretary",
		"council voice",
		"head of state",
		"ruler",
		"king",
		"queen",
		"emperor",
		"empress",
		"fire lord",
		"earth king",
		"earth queen",
		"chief",
		"air monk",
		"monk",
		"pharaoh",
		"pharoah",
		"archon",
		"basileus",
		"shahanshah",
		"suffet",
		"maharaja",
		"chieftain",
		"consul",
		"tyrant",
		"sultan",
		"mansa",
		"khan",
		"doge",
		"shogun",
		"council head",
		"warlord"
	]

	for raw_prefix in office_prefixes:
		var prefix: String = str(raw_prefix).strip_edges().to_lower()
		if prefix == "":
			continue

		if text_value == prefix:
			return true

		for raw_place in place_names:
			var place: String = str(raw_place).strip_edges().to_lower()
			if place == "":
				continue
			if text_value == "%s of %s" % [prefix, place]:
				return true

		if text_value.begins_with("%s of " % prefix):
			return true

	return false


static func _other_country_clean_person_title_for_display(raw_title: String, plain_name: String = "") -> String:
	var title_text: String = str(raw_title).strip_edges()
	if title_text == "":
		return ""

	var lower_title: String = title_text.to_lower()
	var lower_name: String = str(plain_name).strip_edges().to_lower()

	if lower_name != "" and lower_title.find(lower_name) >= 0:
		return ""

	var rejected_office_tokens: Array = [
		"president of ",
		"chancellor of ",
		"supreme leader of ",
		"general secretary of ",
		"council voice of ",
		"head of state of ",
		"ruler of "
	]

	for raw_token in rejected_office_tokens:
		if lower_title.begins_with(str(raw_token)):
			return ""

	return title_text


static func _other_country_surface_ruler_explicit_city_pool(lower_realm: String, lower_country: String, lower_element: String) -> Array:
	var key_text: String = "%s %s %s" % [lower_realm, lower_country, lower_element]

	if lower_element == "fire" or key_text.find("fire nation") >= 0:
		return ["Capital City", "Caldera City", "Ember Island", "Fire Fountain City", "Shu Jing"]

	if lower_element == "earth" or key_text.find("earth kingdom") >= 0:
		return ["Ba Sing Se", "Omashu", "Gaoling", "Chin Village", "Kyoshi Island"]

	if lower_element == "water" or key_text.find("water tribe") >= 0 or key_text.find("water nation") >= 0:
		return ["Agna Qel'a", "Wolf Cove", "Harbor City", "Foggy Swamp", "Southern Water Village"]

	if lower_element == "air" or key_text.find("air temple") >= 0 or key_text.find("air nomads") >= 0:
		return ["Eastern Air Temple", "Western Air Temple", "Northern Air Temple", "Southern Air Temple"]

	if key_text.find("ancient egypt") >= 0 or key_text.find("egypt") >= 0:
		return ["Thebes", "Memphis", "Alexandria", "Avaris", "Heliopolis"]

	if key_text.find("mesopotamia") >= 0:
		return ["Babylon", "Ur", "Nineveh", "Akkad", "Lagash"]

	if key_text.find("assyria") >= 0:
		return ["Nineveh", "Ashur", "Nimrud", "Arbela"]

	if key_text.find("greece") >= 0:
		return ["Athens", "Sparta", "Corinth", "Thebes"]

	if key_text.find("rome") >= 0 or key_text.find("roman") >= 0:
		return ["Rome", "Pompeii", "Ravenna", "Mediolanum"]

	if key_text.find("china") >= 0:
		return ["Xi'an", "Luoyang", "Chang'an", "Nanjing"]

	if key_text.find("persia") >= 0:
		return ["Persepolis", "Susa", "Ecbatana", "Pasargadae"]

	if key_text.find("mali") >= 0:
		return ["Timbuktu", "Niani", "Gao", "Jenne"]

	if key_text.find("england") >= 0:
		return ["London", "York", "Winchester", "Canterbury"]

	if key_text.find("frankia") >= 0 or key_text.find("france") >= 0:
		return ["Paris", "Tours", "Orléans", "Reims"]

	if key_text.find("byzantine") >= 0:
		return ["Constantinople", "Nicaea", "Thessalonica", "Antioch"]

	if key_text.find("japan") >= 0:
		return ["Kyoto", "Nara", "Kamakura", "Edo"]

	if key_text.find("arabia") >= 0 or key_text.find("caliphate") >= 0:
		return ["Mecca", "Medina", "Damascus", "Baghdad"]

	return []


static func _other_country_ancient_ruler_title_for_name(lower_name: String, government_style: String = "") -> String:
	var clean_name: String = str(lower_name).strip_edges().to_lower()
	var clean_government: String = str(government_style).strip_edges()

	if clean_name.find("greece") >= 0:
		return "Archon"
	if clean_name.find("athens") >= 0:
		return "Archon"
	if clean_name.find("sparta") >= 0:
		return "Basileus"
	if clean_name.find("roman") >= 0:
		return "Emperor"
	if clean_name.find("egypt") >= 0:
		return "Pharaoh"
	if clean_name.find("persia") >= 0:
		return "Shahanshah"
	if clean_name.find("carthage") >= 0:
		return "Suffet"
	if clean_name.find("han china") >= 0 or clean_name == "china":
		return "Emperor"
	if clean_name.find("india") >= 0:
		return "Maharaja"
	if clean_name.find("judea") >= 0:
		return "King"
	if clean_name.find("numidia") >= 0:
		return "King"
	if clean_name.find("gaul") >= 0 or clean_name.find("germania") >= 0 or clean_name.find("britannia") >= 0:
		return "Chieftain"

	match clean_government:
		"Monarchy":
			return "King"
		"Empire":
			return "Emperor"
		"Kingdom":
			return "King"
		"Republic":
			return "Consul"
		"Democracy":
			return "Archon"
		"Dictatorship":
			return "Tyrant"
		_:
			return "Ruler"


static func _other_country_medieval_ruler_title_for_name(lower_name: String, government_style: String = "") -> String:
	var clean_name: String = str(lower_name).strip_edges().to_lower()
	var clean_government: String = str(government_style).strip_edges()

	if clean_name.find("byzantine") >= 0:
		return "Emperor"
	if clean_name.find("holy roman") >= 0:
		return "Emperor"
	if clean_name.find("mali") >= 0:
		return "Mansa"
	if clean_name.find("mongol") >= 0:
		return "Khan"
	if clean_name.find("venice") >= 0:
		return "Doge"
	if clean_name.find("japan") >= 0:
		return "Shogun"
	if clean_name.find("china") >= 0:
		return "Emperor"
	if clean_name.find("england") >= 0 or clean_name.find("france") >= 0 or clean_name.find("spain") >= 0 or clean_name.find("portugal") >= 0:
		return "King"
	if clean_name.find("egypt") >= 0:
		return "Sultan"

	match clean_government:
		"Monarchy":
			return "King"
		"Empire":
			return "Emperor"
		"Kingdom":
			return "King"
		"Republic":
			return "Doge"
		"Democracy":
			return "Council Head"
		"Dictatorship":
			return "Warlord"
		_:
			return "Ruler"


static func _resolve_realm_stat_surface(_title: String, value: int, max_value: int, surface_context: Dictionary) -> Dictionary:
	var safe_max: int = max(1, max_value)
	var safe_value: int = clamp(value, 0, safe_max)
	var ratio: float = clamp(float(safe_value) / float(safe_max), 0.0, 1.0)

	var stat_family: String = str(surface_context.get("realm_stat_family", "generic")).strip_edges()
	var is_imaginative_realm: bool = bool(surface_context.get("is_imaginative_realm", false))
	var is_elemental_realm: bool = bool(surface_context.get("is_elemental_realm", false))
	var is_era_kingdom: bool = bool(surface_context.get("is_era_kingdom", false))
	var native_element: String = str(surface_context.get("native_element", "")).strip_edges().to_lower()
	var access_state: String = str(surface_context.get("access_state", "")).strip_edges().to_lower()

	var descriptor: String = ""
	var flavor: String = ""

	match stat_family:
		"wonder":
			if ratio >= 0.9:
				descriptor = "Mythic"
				flavor = "The realm feels overflowing with living wonder."
			elif ratio >= 0.72:
				descriptor = "Charged"
				flavor = "Imagination is moving strongly through the realm."
			elif ratio >= 0.5:
				descriptor = "Awake"
				flavor = "The realm still answers belief, even if not at full brilliance."
			elif ratio >= 0.3:
				descriptor = "Fading"
				flavor = "Wonder is still present, but the realm is not glowing at full strength."
			else:
				descriptor = "Thin"
				flavor = "The realm feels dimmer, weaker, and harder to fully believe."

		"resonance":
			if ratio >= 0.9:
				descriptor = "Harmonized"
				flavor = "The realm is listening and responding with almost no internal resistance."
			elif ratio >= 0.72:
				descriptor = "Tuned"
				flavor = "Its internal rhythm feels aligned and steady."
			elif ratio >= 0.5:
				descriptor = "Steady"
				flavor = "The realm is holding together without obvious distortion."
			elif ratio >= 0.3:
				descriptor = "Uneven"
				flavor = "Something in the realm feels slightly out of tune."
			else:
				descriptor = "Discordant"
				flavor = "The realm feels unstable, strained, and hard to settle."

		"protection":
			if ratio >= 0.9:
				descriptor = "Fortified"
				flavor = "Its protectors feel numerous, alert, and difficult to break through."
			elif ratio >= 0.72:
				descriptor = "Guarded"
				flavor = "The threshold is being watched with real strength."
			elif ratio >= 0.5:
				descriptor = "Covered"
				flavor = "The realm is protected, though not beyond challenge."
			elif ratio >= 0.3:
				descriptor = "Thinly Guarded"
				flavor = "Protection is present, but the defensive edge feels lighter than it should."
			else:
				descriptor = "Exposed"
				flavor = "The threshold feels easier to breach than the realm would want."

		"veil_strength":
			if access_state == "view_only":
				if ratio >= 0.85:
					descriptor = "Sealed"
					flavor = "The veil is holding hard, and true entry still feels distant."
				elif ratio >= 0.6:
					descriptor = "Veiled"
					flavor = "The realm can be seen, but the crossing still resists full access."
				else:
					descriptor = "Porous"
					flavor = "The veil is still there, but it does not feel perfectly secure."
			else:
				if ratio >= 0.85:
					descriptor = "Hidden"
					flavor = "The realm still keeps much of itself obscured."
				elif ratio >= 0.6:
					descriptor = "Thinned"
					flavor = "Ordinary rules are weakening around the edges."
				elif ratio >= 0.35:
					descriptor = "Opened"
					flavor = "The boundary is parting more easily than before."
				else:
					descriptor = "Exposed"
					flavor = "The veil feels weak enough that crossing pressure can be felt directly."

		"prosperity":
			if ratio >= 0.9:
				descriptor = "Flourishing"
				flavor = "The realm feels wealthy, supplied, and confidently expanding."
			elif ratio >= 0.72:
				descriptor = "Healthy"
				flavor = "Its resources and general condition feel comfortably strong."
			elif ratio >= 0.5:
				descriptor = "Stable"
				flavor = "The realm is functioning well enough, even if not lavishly."
			elif ratio >= 0.3:
				descriptor = "Strained"
				flavor = "The realm can still function, but it does not feel economically comfortable."
			else:
				descriptor = "Starving"
				flavor = "The realm feels deprived, underfed, and at risk of visible decline."

		"stability":
			if ratio >= 0.9:
				descriptor = "Anchored"
				flavor = "The realm feels deeply settled and difficult to shake."
			elif ratio >= 0.72:
				descriptor = "Secure"
				flavor = "Its internal order feels dependable and intact."
			elif ratio >= 0.5:
				descriptor = "Holding"
				flavor = "The realm is standing, though not without stress."
			elif ratio >= 0.3:
				descriptor = "Shaken"
				flavor = "The realm feels vulnerable to disruption."
			else:
				descriptor = "Fractured"
				flavor = "Its internal order feels close to giving way."

		"loyalty":
			if ratio >= 0.9:
				descriptor = "Devoted"
				flavor = "Its people feel deeply committed to the realm’s current order."
			elif ratio >= 0.72:
				descriptor = "Backed"
				flavor = "Support feels real and broadly intact."
			elif ratio >= 0.5:
				descriptor = "Compliant"
				flavor = "The realm still has obedience, even if not passionate loyalty."
			elif ratio >= 0.3:
				descriptor = "Restless"
				flavor = "Its people are following, but they do not feel fully settled."
			else:
				descriptor = "Disloyal"
				flavor = "The realm feels emotionally and politically ready to pull away."

		"pressure":
			if ratio >= 0.9:
				descriptor = "Boiling"
				flavor = "Pressure inside the realm feels near open rupture."
			elif ratio >= 0.72:
				descriptor = "Volatile"
				flavor = "The realm feels one bad moment away from visible escalation."
			elif ratio >= 0.5:
				descriptor = "Tense"
				flavor = "Pressure is present and noticeable, even if not yet explosive."
			elif ratio >= 0.3:
				descriptor = "Watchful"
				flavor = "The realm is carrying pressure, but it still feels containable."
			else:
				descriptor = "Clear"
				flavor = "There is pressure in the background, but not enough to define the realm."

		_:
			if is_imaginative_realm:
				descriptor = "Otherworldly" if ratio >= 0.65 else "Unsteady"
				flavor = "This realm does not behave like an ordinary state surface."
			elif is_elemental_realm:
				match native_element:
					"fire":
						descriptor = "Blazing" if ratio >= 0.75 else "Smoldering"
						flavor = "The realm feels defined by heat, force, and disciplined intensity."
					"water":
						descriptor = "Flowing" if ratio >= 0.75 else "Shifting"
						flavor = "The realm feels adaptive, fluid, and emotionally responsive."
					"earth":
						descriptor = "Rooted" if ratio >= 0.75 else "Heavy"
						flavor = "The realm feels grounded, enduring, and difficult to move."
					"air":
						descriptor = "Lifted" if ratio >= 0.75 else "Drifting"
						flavor = "The realm feels light, spiritual, and hard to pin down."
					_:
						descriptor = "Elemental"
						flavor = "The realm is carrying a clear elemental identity."
			elif is_era_kingdom:
				descriptor = "Sovereign" if ratio >= 0.7 else "Imperiled"
				flavor = "The hidden sovereign structure feels powerful, but not invulnerable."
			else:
				descriptor = "%d" % safe_value
				flavor = ""

	return {
		"descriptor": descriptor,
		"flavor": flavor,
		"bar_text": "%d" % safe_value,
		"title_text": ""
	}


static func _elemental_nation_for_bending_type(bending_type_text: String) -> String:
	match str(bending_type_text).strip_edges().to_lower():
		"air":
			return "Air Nomads"
		"water":
			return "Water Tribe"
		"earth":
			return "Earth Kingdom"
		"fire":
			return "Fire Nation"
		_:
			return ""


static func _is_elemental_nation_name(nation_name: String) -> bool:
	match str(nation_name).strip_edges():
		"Fire Nation", "Earth Kingdom", "Water Tribe", "Northern Water Tribe", "Southern Water Tribe", "Air Nomads", "Northern Air Temple", "Southern Air Temple", "Eastern Air Temple", "Western Air Temple":
			return true
		_:
			return false


static func _other_country_elemental_definite_name(place_name: String, uppercase: bool = false) -> String:
	var clean_name: String = str(place_name).strip_edges()
	if clean_name == "":
		return ""
	var lower_name: String = clean_name.to_lower()
	var out: String = clean_name
	if WorldSceneSupport._other_country_elemental_needs_definite_article(clean_name):
		out = "the %s" % clean_name
	elif lower_name.begins_with("the "):
		out = clean_name
	if uppercase:
		return out.to_upper()
	return out


static func _other_country_elemental_surface_origin_name(realm: Dictionary, entry: Dictionary = {}) -> String:
	if typeof(realm) != TYPE_DICTIONARY:
		return ""
	var candidates: Array = [
		str(realm.get("name", "")).strip_edges(),
		str(realm.get("country", "")).strip_edges(),
		str(entry.get("name", "")).strip_edges()
	]
	for raw_candidate in candidates:
		var candidate: String = str(raw_candidate).strip_edges()
		if candidate == "":
			continue
		if WorldSceneSupport._other_country_elemental_needs_definite_article(candidate):
			return candidate
	return ""


static func _other_country_browser_feature_enabled(gs: GameState,
	feature_key: String) -> bool:
	if gs == null:
		return false

	if gs.has_method("is_feature_enabled"):
		return bool(gs.is_feature_enabled(feature_key))

	if typeof(gs.custom_settings) == TYPE_DICTIONARY:
		var overrides_raw: Variant = gs.custom_settings.get("feature_overrides", {})
		var overrides: Dictionary = overrides_raw if typeof(overrides_raw) == TYPE_DICTIONARY else {}
		if overrides.has(feature_key):
			return bool(overrides.get(feature_key, false))

	return true


static func _other_country_browser_allows_elemental_surfaces(gs: GameState) -> bool:
	if CreationSceneSupport._other_country_browser_reality_mode_key(gs) == "realistic":
		return false
	return WorldSceneSupport._other_country_browser_feature_enabled(gs, "bending")


static func _other_country_browser_allows_many_realms_surfaces(gs: GameState) -> bool:
	if CreationSceneSupport._other_country_browser_reality_mode_key(gs) == "realistic":
		return false
	return WorldSceneSupport._other_country_browser_feature_enabled(gs, "many_realms")


static func _other_country_player_presence(gs: GameState,
	entry: Dictionary, realm: Dictionary) -> Dictionary:
	var out:= {
		"lives_here": false,
		"rules_here": false,
		"is_current_place": false,
		"label": ""
	}

	if gs == null or gs.player == null:
		return out

	var p: Person = gs.player
	var entry_name: String = str(entry.get("name", realm.get("name", ""))).strip_edges()
	var entry_kind: String = str(entry.get("entry_kind", "")).strip_edges().to_lower()

	var home_country: String = str(p.home_country).strip_edges()
	if home_country == "":
		home_country = str(p.birth_country).strip_edges()

	var player_home_key: String = WorldSceneSupport._other_country_identity_key(home_country)
	var entry_name_key: String = WorldSceneSupport._other_country_identity_key(entry_name)
	var realm_name_key: String = WorldSceneSupport._other_country_identity_key(str(realm.get("name", entry_name)))
	var realm_country_key: String = WorldSceneSupport._other_country_identity_key(str(realm.get("country", entry_name)))

	var lives_here: bool = false
	if home_country != "":
		lives_here = player_home_key == entry_name_key \
or player_home_key == realm_name_key \
or player_home_key == realm_country_key

	var resolved_realm_id: int = PopulationSceneSupport._resolve_existing_realm_id_for_other_country_population_entry(gs, entry)
	var entry_is_real_realm: bool = entry_kind == "realm" or entry_kind == "hidden_realm"
	var entry_is_country_shell: bool = entry_kind == "country"

	if not lives_here and entry_is_real_realm and resolved_realm_id > 0 and int(p.realm_id) == resolved_realm_id:
		lives_here = true

	if not lives_here and not entry_is_country_shell:
		var entry_realm_id: int = int(entry.get("realm_id", realm.get("realm_id", realm.get("id", 0))))
		if entry_realm_id > 0 and int(p.realm_id) == entry_realm_id:
			lives_here = true

	var us_realm_id: int = -1
	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		us_realm_id = int(gs.scenario_state.get("presidential_parent_contract_us_realm_id", -1))

	if not lives_here and WorldSceneSupport._other_country_surface_is_united_states(gs, entry, realm):
		if us_realm_id > 0 and int(p.realm_id) == us_realm_id:
			lives_here = true
		elif player_home_key in ["usa", "us", "unitedstates", "unitedstatesofamerica", "america"]:
			lives_here = true

	var rules_here: bool = false
	var raw_ruler = realm.get("ruler_id", realm.get("leader_id", realm.get("president_person_id", 0)))

	if int(raw_ruler) > 0 and int(raw_ruler) == int(p.id):
		rules_here = true

	if not rules_here and bool(p.is_ruler):
		if lives_here:
			rules_here = true
		elif entry_is_real_realm and resolved_realm_id > 0 and int(p.realm_id) == resolved_realm_id:
			rules_here = true

	out ["lives_here"] = lives_here
	out ["rules_here"] = rules_here
	out ["is_current_place"] = lives_here or rules_here
	out ["label"] = "YOU LIVE HERE" if bool(out ["is_current_place"]) else ""

	return out


static func _other_country_surface_is_united_states(gs: GameState,
	entry: Dictionary, realm: Dictionary) -> bool:
	var keys: Array = [
		str(entry.get("name", "")),
		str(entry.get("label", "")),
		str(entry.get("entry_id", "")),
		str(realm.get("name", "")),
		str(realm.get("country", "")),
		str(realm.get("realm_contract_resolved_from_country", ""))
	]

	for raw_value in keys:
		var key: String = WorldSceneSupport._other_country_identity_key(str(raw_value))
		if key in ["usa", "us", "unitedstates", "unitedstatesofamerica", "america"]:
			return true
		if key.find("unitedstates") >= 0:
			return true

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var us_realm_id: int = int(gs.scenario_state.get("presidential_parent_contract_us_realm_id", -1))
		var realm_id: int = int(realm.get("realm_id", realm.get("id", -1)))
		if us_realm_id > 0 and realm_id == us_realm_id:
			return true

	return false


static func _append_other_country_browser_entry_unique(out: Array, seen: Dictionary, entry: Dictionary) -> void:
	if typeof(entry) != TYPE_DICTIONARY or entry.is_empty():
		return

	var entry_kind: String = str(entry.get("entry_kind", "realm")).strip_edges().to_lower()
	var entry_id: String = str(entry.get("entry_id", "")).strip_edges()
	var entry_name: String = str(entry.get("name", "")).strip_edges()
	var realm_raw: Variant = entry.get("realm", {})
	var realm: Dictionary = realm_raw if typeof(realm_raw) == TYPE_DICTIONARY else {}
	var realm_name: String = str(realm.get("name", entry_name)).strip_edges()
	var realm_id: int = int(entry.get("realm_id", realm.get("realm_id", realm.get("id", 0))))

	if entry_id == "":
		entry_id = WorldSceneSupport._other_country_identity_key(entry_name)

	var aliases: Array = WorldSceneSupport._other_country_browser_entry_identity_aliases(entry_kind, entry_id, entry_name, realm_name, realm_id)

	for alias_key in aliases:
		if seen.has(alias_key):
			return

	for alias_key in aliases:
		seen [alias_key] = true

	out.append(entry)


static func _other_country_browser_entry_identity_aliases(entry_kind: String, entry_id: String, entry_name: String, realm_name: String, realm_id: int = 0) -> Array:
	var aliases: Array = []

	var clean_kind: String = str(entry_kind).strip_edges().to_lower()
	if clean_kind == "":
		clean_kind = "realm"

	var clean_entry_id: String = WorldSceneSupport._other_country_identity_key(entry_id)
	var clean_entry_name: String = WorldSceneSupport._other_country_identity_key(entry_name)
	var clean_realm_name: String = WorldSceneSupport._other_country_identity_key(realm_name)

	if clean_entry_id != "":
		aliases.append("%s:id:%s" % [clean_kind, clean_entry_id])
		aliases.append("any:id:%s" % clean_entry_id)

	if clean_entry_name != "":
		aliases.append("%s:name:%s" % [clean_kind, clean_entry_name])
		aliases.append("any:name:%s" % clean_entry_name)

	if clean_realm_name != "":
		aliases.append("%s:realm_name:%s" % [clean_kind, clean_realm_name])
		aliases.append("any:realm_name:%s" % clean_realm_name)

	if realm_id > 0:
		aliases.append("realm_id:%d" % realm_id)

	var joined: String = "%s %s %s" % [entry_id, entry_name, realm_name]
	var lowered: String = joined.strip_edges().to_lower()

	if lowered.find("terabithia") >= 0:
		aliases.append("special:terabithia")

	if lowered.find("vormir") >= 0:
		aliases.append("special:vormir")

	if lowered.find("nidavellir") >= 0:
		aliases.append("special:nidavellir")

	if lowered.find("era kingdom") >= 0 or lowered.find("erakingdom") >= 0:
		aliases.append("special:era_kingdom")

	var elemental_exact_key: String = clean_entry_name if clean_entry_name != "" else clean_realm_name
	if elemental_exact_key != "":
		if lowered.find("earth kingdom") >= 0:
			aliases.append("elemental_surface:earth:%s" % elemental_exact_key)
		elif lowered.find("fire nation") >= 0:
			aliases.append("elemental_surface:fire:%s" % elemental_exact_key)
		elif lowered.find("water tribe") >= 0:
			aliases.append("elemental_surface:water:%s" % elemental_exact_key)
		elif lowered.find("air temple") >= 0 or lowered.find("air nomads") >= 0:
			aliases.append("elemental_surface:air:%s" % elemental_exact_key)

	if aliases.is_empty():
		aliases.append("%s:fallback:%s" % [clean_kind, WorldSceneSupport._other_country_identity_key("%s:%s:%d" % [entry_id, entry_name, realm_id])])

	return aliases


static func _other_country_apply_presidential_parent_leader_truth_to_surface(gs: GameState,
	surface_realm: Dictionary) -> Dictionary:
	if gs == null or typeof(surface_realm) != TYPE_DICTIONARY:
		return surface_realm
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return surface_realm

	var out: Dictionary = surface_realm.duplicate(true)
	var us_realm_id: int = int(gs.scenario_state.get("presidential_parent_contract_us_realm_id", -1))
	var president_id: int = int(gs.scenario_state.get("presidential_parent_contract_president_id", -1))

	var country_key: String = WorldSceneSupport._other_country_identity_key(str(out.get("country", out.get("name", ""))))
	var name_key: String = WorldSceneSupport._other_country_identity_key(str(out.get("name", "")))
	var realm_id: int = int(out.get("realm_id", out.get("id", -1)))

	var is_us_surface: bool = realm_id == us_realm_id \
or country_key in ["usa", "us", "unitedstates", "unitedstatesofamerica", "america"] \
or name_key in ["usa", "us", "unitedstates", "unitedstatesofamerica", "america"]

	if not is_us_surface:
		return out

	if president_id <= 0:
		president_id = int(out.get("president_person_id", out.get("leader_id", out.get("ruler_id", -1))))

	if president_id <= 0 and gs.player != null:
		var player_country_key: String = WorldSceneSupport._other_country_identity_key(str(gs.player.home_country))
		var player_job_key: String = str(gs.player.job).strip_edges().to_lower()
		var player_civic_title_key: String = str(gs.player.civic_title).strip_edges().to_lower()

		if player_country_key in ["usa", "us", "unitedstates", "unitedstatesofamerica", "america"]:
			if player_job_key.find("president") >= 0 or player_civic_title_key.find("president") >= 0 or bool(gs.player.is_ruler):
				president_id = int(gs.player.id)

	if president_id <= 0:
		return out

	var president = null
	if gs.has_method("get_npc_by_id"):
		president = gs.get_npc_by_id(president_id)
	if president == null and gs.has_method("get_or_reactivate_npc_by_id"):
		president = gs.get_or_reactivate_npc_by_id(president_id)

	var president_name: String = "President"
	if president != null:
		president_name = "%s %s" % [str(president.first_name), str(president.last_name)]
		president_name = president_name.strip_edges()

	out ["id"] = us_realm_id
	out ["realm_id"] = us_realm_id
	out ["name"] = "United States"
	out ["country"] = "United States"
	out ["government_style"] = "Republic"
	out ["government_model"] = "federal_presidential_republic"
	out ["federal_republic_population_contract"] = true
	out ["ruler_id"] = president_id
	out ["ruler_npc_id"] = president_id
	out ["leader_id"] = president_id
	out ["president_person_id"] = president_id
	out ["ruler_name"] = president_name
	out ["leader_name"] = president_name
	out ["leader_title"] = "President of the United States"
	out ["surface_ruler_office"] = "President of the United States"
	out ["presidential_parent_contract_leader_truth"] = true
	out ["ui_is_renderer_only"] = true

	return out


static func _other_country_person_title_name(person: Person, fallback_title: String) -> String:
	if person == null:
		return "Unknown"

	var full_name: String = WorldSceneSupport._other_country_person_plain_name(person)
	var title_text: String = str(fallback_title).strip_edges()

	if title_text == "":
		title_text = WorldSceneSupport._other_country_clean_person_title_for_display(str(person.royal_title), full_name)

	if title_text.strip_edges().to_lower() == "ruler":
		return full_name

	if title_text == "":
		return full_name

	if WorldSceneSupport._other_country_text_already_has_title(full_name, title_text):
		return full_name

	return "%s %s" % [title_text, full_name]


static func _other_country_extract_person_name_from_ruler_text(raw_text: String, realm: Dictionary = {}) -> String:
	var text_value: String = str(raw_text).strip_edges()
	if text_value == "":
		return ""

	var lower_text: String = text_value.to_lower()

	if WorldSceneSupport._other_country_ruler_text_is_generic_office(lower_text, realm):
		return ""

	var generic_prefixes: Array = [
		"president of ",
		"chancellor of ",
		"supreme leader of ",
		"general secretary of ",
		"council voice of ",
		"ruler of ",
		"head of state of ",
		"king of ",
		"queen of ",
		"emperor of ",
		"empress of ",
		"fire lord of ",
		"earth king of ",
		"earth queen of ",
		"chief of ",
		"air monk of "
	]

	for raw_prefix in generic_prefixes:
		var prefix: String = str(raw_prefix)
		if lower_text.begins_with(prefix):
			var remainder: String = text_value.substr(prefix.length()).strip_edges()
			if remainder != "" and not WorldSceneSupport._other_country_ruler_text_is_generic_office(remainder.to_lower(), realm):
				return remainder
			return ""

	return text_value


static func _other_country_surface_culture_contract(realm_name: String, country_name: String, native_element: String, era_key: String) -> Dictionary:
	var lower_realm: String = str(realm_name).strip_edges().to_lower()
	var lower_country: String = str(country_name).strip_edges().to_lower()
	var lower_element: String = str(native_element).strip_edges().to_lower()
	var lower_era: String = str(era_key).strip_edges().to_lower()
	var key_text: String = "%s %s %s %s" % [lower_era, lower_realm, lower_country, lower_element]

	if lower_element == "fire" or key_text.find("fire nation") >= 0:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "fire_nation",
			"display_name": "Fire Nation Culture",
			"values": ["discipline", "honor", "expansion", "strength"],
			"naming_rules": "first_name + 'of' + military_city",
			"city_pool": ["Capital City", "Caldera City", "Ember Island", "Fire Fountain City", "Shu Jing"],
			"power_structure": "military monarchy",
			"ruler_title": "Fire Lord",
			"name_format": "of_city",
			"prefer_actions": ["expand_influence", "project_strength", "preserve_honor"],
			"avoid_actions": ["appear_weak", "ignore_insult"],
			"behavior_bias": { "loyalty": 8, "rebellion": -4, "militarism": 18, "diplomacy": -5, "stability": 4}
		})

	if lower_element == "earth" or key_text.find("earth kingdom") >= 0:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "earth_kingdom",
			"display_name": "Earth Kingdom Culture",
			"values": ["tradition", "endurance", "territory", "stability"],
			"naming_rules": "first_name + 'of' + ancient_city",
			"city_pool": ["Ba Sing Se", "Omashu", "Gaoling", "Chin Village", "Kyoshi Island"],
			"power_structure": "royal monarchy",
			"ruler_title": "Earth King",
			"name_format": "of_city",
			"prefer_actions": ["preserve_borders", "maintain_order", "defend_customs"],
			"avoid_actions": ["rapid_reform", "reckless_war"],
			"behavior_bias": { "loyalty": 10, "rebellion": -8, "stability": 14, "militarism": 3, "diplomacy": 4}
		})

	if lower_element == "water" or key_text.find("water tribe") >= 0 or key_text.find("water nation") >= 0:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "water_tribes",
			"display_name": "Water Tribe Culture",
			"values": ["community", "adaptation", "healing", "ancestry"],
			"naming_rules": "first_name + 'of' + tribal_home",
			"city_pool": ["Agna Qel'a", "Wolf Cove", "Harbor City", "Foggy Swamp", "Southern Water Village"],
			"power_structure": "tribal chieftaincy",
			"ruler_title": "Chief",
			"name_format": "of_city",
			"prefer_actions": ["protect_community", "heal_divisions", "honor_ancestors"],
			"avoid_actions": ["abandon_people", "break_tradition"],
			"behavior_bias": { "loyalty": 16, "rebellion": -6, "stability": 8, "diplomacy": 10, "militarism": -2}
		})

	if lower_element == "air" or key_text.find("air temple") >= 0 or key_text.find("air nomads") >= 0:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "air_nomads",
			"display_name": "Air Nomad Culture",
			"values": ["freedom", "spirituality", "balance", "nonviolence"],
			"naming_rules": "first_name + 'of' + temple",
			"city_pool": ["Eastern Air Temple", "Western Air Temple", "Northern Air Temple", "Southern Air Temple"],
			"power_structure": "spiritual council",
			"ruler_title": "Air Monk",
			"name_format": "of_city",
			"prefer_actions": ["preserve_balance", "mediate_conflict", "teach_spirituality"],
			"avoid_actions": ["conquest", "cruel_punishment"],
			"behavior_bias": { "loyalty": 12, "rebellion": -10, "stability": 7, "diplomacy": 18, "militarism": -18}
		})

	if key_text.find("ancient egypt") >= 0 or key_text.find("egypt") >= 0:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "ancient_egypt",
			"display_name": "Ancient Egyptian Culture",
			"values": ["order", "afterlife", "divinity", "monumentality"],
			"naming_rules": "first_name + 'of' + sacred_city",
			"city_pool": ["Thebes", "Memphis", "Heliopolis", "Alexandria", "Abydos"],
			"power_structure": "divine monarchy",
			"ruler_title": "Pharaoh",
			"name_format": "of_city",
			"prefer_actions": ["preserve_order", "honor_gods", "build_monuments"],
			"avoid_actions": ["rebellion", "desecration"],
			"behavior_bias": { "loyalty": 20, "rebellion": -15, "stability": 16, "diplomacy": 2, "monuments": 18}
		})

	if lower_era in ["medieval", "medieval era"]:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "medieval_feudal",
			"display_name": "Medieval Feudal Culture",
			"values": ["lineage", "faith", "land", "oaths"],
			"naming_rules": "first_name + 'of' + seat",
			"city_pool": ["York", "Winchester", "Canterbury", "London", "Norwich"],
			"power_structure": "feudal monarchy",
			"ruler_title": "King",
			"name_format": "of_city",
			"prefer_actions": ["form_alliances", "defend_lineage", "wage_claim_wars"],
			"avoid_actions": ["break_oaths", "ignore_vassals"],
			"behavior_bias": { "loyalty": 5, "rebellion": 6, "stability": -2, "diplomacy": 8, "militarism": 10}
		})

	if lower_era in ["ancient", "ancient era"]:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "ancient_dynastic",
			"display_name": "Ancient Dynastic Culture",
			"values": ["lineage", "omens", "conquest", "ritual"],
			"naming_rules": "first_name + 'of' + ancient_city",
			"city_pool": ["Babylon", "Ur", "Nineveh", "Tyre", "Persepolis"],
			"power_structure": "dynastic monarchy",
			"ruler_title": "King",
			"name_format": "of_city",
			"prefer_actions": ["expand_dynasty", "honor_omens", "secure_grain"],
			"avoid_actions": ["dynastic_shame", "weak_succession"],
			"behavior_bias": { "loyalty": 8, "rebellion": -3, "stability": 5, "militarism": 8, "diplomacy": 2}
		})

	if lower_era in ["future", "future era"]:
		return WorldSceneSupport._other_country_make_culture_contract({
			"id": "future_civic_algorithmic",
			"display_name": "Future Civic Culture",
			"values": ["efficiency", "innovation", "surveillance", "mobility"],
			"naming_rules": "first_name + legal_family_name",
			"city_pool": ["Neo Tokyo", "New Shanghai", "Lagos Arcology", "Toronto Spire", "Chicago Grid"],
			"power_structure": "technocratic republic",
			"ruler_title": "President",
			"name_format": "family_name",
			"prefer_actions": ["optimize_systems", "expand_infrastructure", "manage_risk"],
			"avoid_actions": ["systemic_decay", "untracked_instability"],
			"behavior_bias": { "loyalty": 0, "rebellion": 4, "stability": 8, "innovation": 18, "privacy": -10}
		})

	return WorldSceneSupport._other_country_make_culture_contract({
		"id": "modern_civic",
		"display_name": "Modern Civic Culture",
		"values": ["rights", "commerce", "identity", "public_opinion"],
		"naming_rules": "first_name + legal_family_name",
		"city_pool": [],
		"power_structure": "civic state",
		"ruler_title": "",
		"name_format": "family_name",
		"prefer_actions": ["manage_public_opinion", "grow_economy", "protect_rights"],
		"avoid_actions": ["public_scandal", "economic_collapse"],
		"behavior_bias": { "loyalty": 0, "rebellion": 2, "stability": 0, "diplomacy": 4, "commerce": 8}
	})


static func _other_country_make_culture_contract(data: Dictionary) -> Dictionary:
	var id_text: String = str(data.get("id", "generic_culture")).strip_edges().to_lower()
	var display_name: String = str(data.get("display_name", id_text.capitalize())).strip_edges()
	var city_pool: Array = ValueSceneSupport._safe_array(data.get("city_pool", []))
	var ruler_title: String = str(data.get("ruler_title", "")).strip_edges()
	var name_format: String = str(data.get("name_format", "family_name")).strip_edges().to_lower()
	var behavior_bias: Dictionary = ValueSceneSupport._safe_dictionary(data.get("behavior_bias", {}))

	return {
		"schema": "eralife.cultural_reality_contract",
		"version": 1,
		"id": id_text,
		"display_name": display_name,
		"values": ValueSceneSupport._safe_array(data.get("values", [])),
		"naming_rules": str(data.get("naming_rules", "")),
		"city_pool": city_pool,
		"power_structure": str(data.get("power_structure", "civic state")),
		"behavior_bias": behavior_bias,
		"ruler_identity_contract": {
			"must_have_title": ruler_title,
			"name_format": name_format,
			"valid_origin_cities": city_pool
		},
		"behavior_contract": {
			"prefer_actions": ValueSceneSupport._safe_array(data.get("prefer_actions", [])),
			"avoid_actions": ValueSceneSupport._safe_array(data.get("avoid_actions", [])),
			"bias": behavior_bias
		},
		"history_contract": {
			"records_identity_origin": name_format == "of_city",
		},
		"ui_contract": {
			"observer_only": true,
		}
	}


static func _resolve_player_realm_dict(gs: GameState) -> Dictionary:
	if gs == null or gs.player == null or gs.realm_engine == null:
		return {}

	var preferred_city: String = str(gs.player.home_city if str(gs.player.home_city).strip_edges() != "" else gs.player.birth_city).strip_edges()

	var realm_id: int = int(gs.player.realm_id)
	if realm_id > 0 and gs.realm_engine.realms.has(realm_id):
		if gs.realm_engine.has_method("ensure_realm_population_surface_contract"):
			gs.realm_engine.ensure_realm_population_surface_contract(realm_id, preferred_city, {
				"source": "mainscene_player_realm_contract_resolution",
				"ui_is_renderer": true
			})

		var direct_raw: Variant = gs.realm_engine.realms.get(realm_id, {})
		var direct_realm: Dictionary = direct_raw if typeof(direct_raw) == TYPE_DICTIONARY else {}
		if not direct_realm.is_empty():
			return direct_realm

	var candidate_names: Array = []
	for raw_name in [
		str(gs.player.home_country).strip_edges(),
		str(gs.player.birth_country).strip_edges(),
		str(gs.player.bending_nation).strip_edges()
	]:
		var clean_name: String = str(raw_name).strip_edges()
		if clean_name != "" and not candidate_names.has(clean_name):
			candidate_names.append(clean_name)

	for preferred_name in candidate_names:
		var ensured_realm_id: int = -1
		if gs.realm_engine.has_method("ensure_realm_for_country"):
			ensured_realm_id = gs.realm_engine.ensure_realm_for_country(preferred_name, preferred_city)

		if ensured_realm_id <= 0:
			continue

		gs.player.realm_id = ensured_realm_id

		if gs.realm_engine.has_method("ensure_realm_population_surface_contract"):
			gs.realm_engine.ensure_realm_population_surface_contract(ensured_realm_id, preferred_city, {
				"source": "mainscene_player_realm_contract_resolution_from_country",
				"ui_is_renderer": true
			})

		var ensured_raw: Variant = gs.realm_engine.realms.get(ensured_realm_id, {})
		var ensured_realm: Dictionary = ensured_raw if typeof(ensured_raw) == TYPE_DICTIONARY else {}
		if not ensured_realm.is_empty():
			return ensured_realm

	return {}


static func _ensure_truth_resolution_contract_engine(gs: GameState) -> TruthResolutionContractEngine:
	if gs == null:
		return null

	if "truth_resolution_contract_engine" in gs and gs.truth_resolution_contract_engine != null:
		return gs.truth_resolution_contract_engine as TruthResolutionContractEngine

	gs.truth_resolution_contract_engine = TruthResolutionContractEngine.new(gs)
	return gs.truth_resolution_contract_engine as TruthResolutionContractEngine


static func _global_prewarm_ready_gate_realm_ids(gs: GameState) -> Array:
	var out: Array = []
	var seen: Dictionary = {}

	if gs != null and gs.player != null:
		var player_realm_id: int = int(gs.player.realm_id)
		if player_realm_id > 0:
			out.append(player_realm_id)
			seen [player_realm_id] = true

	if gs != null and typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var us_realm_id: int = int(gs.scenario_state.get("presidential_parent_contract_us_realm_id", -1))
		if us_realm_id > 0 and not seen.has(us_realm_id):
			out.append(us_realm_id)
			seen [us_realm_id] = true

	return out


static func _other_country_reconcile_observable_population_surface(gs: GameState,

	panel,
	realm_id: int,
	realm_name: String,
	aliases: Array,
	reason: String
) -> Dictionary:
	if gs == null or panel == null or realm_id <= 0:
		return {
			"success": false,
			"reason": "missing_panel_or_realm",
			"ui_is_renderer_only": true
		}

	var observable_hot: bool = false
	if "world_observability_contract_engine" in gs and gs.world_observability_contract_engine != null:
		if gs.world_observability_contract_engine.has_method("has_observable_population_surface"):
			observable_hot = gs.world_observability_contract_engine.has_observable_population_surface(realm_id)

	if not observable_hot:
		return {
			"success": false,
			"reason": "observable_surface_not_sealed",
			"realm_id": realm_id,
			"realm_name": realm_name,
			"click_path_build_forbidden": true,
			"ui_is_renderer_only": true
		}

	var hot: bool = panel.has_surface_for(realm_id, realm_name)

	if not hot:
		for raw_alias in aliases:
			var alias_name: String = str(raw_alias).strip_edges()
			if alias_name == "":
				continue

			if panel.has_surface_for(realm_id, alias_name):
				realm_name = alias_name
				hot = true
				break

	if hot:
		panel.add_aliases(realm_id, realm_name, aliases)

	return {
		"success": hot,
		"reason": "observable_surface_read_only_hot" if hot else "observable_surface_exists_but_panel_shell_missing",
		"realm_id": realm_id,
		"realm_name": realm_name,
		"panel_hot": hot,
		"observable_hot": observable_hot,
		"read_only": true,
		"click_path_build_forbidden": true,
		"ui_is_renderer_only": true,
		"reason_context": reason
	}
