extends RefCounted
class_name RelationshipsSceneSupport
## Relationships support for the main scene. State, when needed, is passed explicitly.


static func _nearby_switch_row_person(row: Dictionary) -> Person:
	if typeof(row) != TYPE_DICTIONARY:
		return null
	var npc_raw: Variant = row.get("npc", null)
	if npc_raw != null and npc_raw is Person:
		return npc_raw as Person
	return null


static func _romance_contract_stat_palette_key(stat_name: String) -> String:
	var clean: String = str(stat_name).strip_edges()

	match clean:
		"Mental Health":
			return "Mental"
		"Affection":
			return "Bond"
		"Distance Pull":
			return "Bond"
		_:
			return clean


static func _relationship_profile_death_cause_for(target: Person) -> String:
	if target == null:
		return "unknown causes"

	var cause_text: String = str(target.cause_of_death).strip_edges()
	if cause_text == "":
		cause_text = "unknown causes"

	return cause_text


static func _relationship_profile_dead_health_flavor(surface_context: Dictionary) -> String:
	var cause_text: String = str(surface_context.get("death_cause", "unknown causes")).strip_edges()
	if cause_text == "":
		cause_text = "unknown causes"

	var year_label: String = str(surface_context.get("death_year_label", "an unknown year")).strip_edges()
	if year_label == "":
		year_label = "an unknown year"

	var perspective: String = str(surface_context.get("narrative_perspective", "first_person")).strip_edges().to_lower()

	if perspective == "first_person":
		return "I died from %s in the year %s." % [cause_text, year_label]

	return "They died from %s in the year %s." % [cause_text, year_label]


static func _relationship_bond_descriptor_for_ratio(ratio: float) -> String:
	var safe_ratio: float = clamp(float(ratio), 0.0, 1.0)

	if safe_ratio >= 0.85:
		return "Devoted"
	elif safe_ratio >= 0.7:
		return "Warm"
	elif safe_ratio >= 0.5:
		return "Open"
	elif safe_ratio >= 0.3:
		return "Guarded"
	elif safe_ratio >= 0.15:
		return "Cold"

	return "Hostile"


static func _relationship_bond_posthumous_descriptor(living_descriptor: String) -> String:
	var clean_descriptor: String = str(living_descriptor).strip_edges()
	if clean_descriptor == "":
		clean_descriptor = "Unknown"

	return "%s, Now Dead" % clean_descriptor


static func _relationship_bond_flavor_for_descriptor(descriptor: String, surface_context: Dictionary, posthumous: bool = false) -> String:
	var clean_descriptor: String = str(descriptor).strip_edges()
	var perspective: String = str(surface_context.get("narrative_perspective", "first_person")).strip_edges().to_lower()
	var surface_family: String = str(surface_context.get("surface_family", "")).strip_edges().to_lower()
	var descriptor_title_mode: String = str(surface_context.get("descriptor_title_mode", "")).strip_edges().to_lower()
	var relationship_card_owned: bool = bool(surface_context.get("relationship_card_labels_are_contract_owned", false)) \
or bool(surface_context.get("relationship_card_contract_engine_owned", false)) \
or surface_family == "institution_hub" \
or descriptor_title_mode == "bond_pov"

	var bond_object_label: String = str(surface_context.get("bond_object_label", "")).strip_edges()

	if bond_object_label == "":
		bond_object_label = "you" if perspective == "third_person" and relationship_card_owned else "them"

	if perspective == "third_person":
		if posthumous:
			match clean_descriptor:
				"Devoted":
					return "They trusted %s deeply and felt safest when they were close to %s." % [bond_object_label, bond_object_label]
				"Warm":
					return "They felt genuinely close to %s and usually read %s as safe, welcome company." % [bond_object_label, bond_object_label]
				"Open":
					return "They were comfortable around %s, even if some emotional distance was still there." % [bond_object_label]
				"Guarded":
					return "They recognized %s, but they were still protecting part of themselves around %s." % [bond_object_label, bond_object_label]
				"Cold":
					return "They did not feel fully settled around %s and kept their trust pulled back." % [bond_object_label]
				"Hostile":
					return "They felt tense around %s and would rather keep distance than closeness." % [bond_object_label]

			return "Their relationship with %s ended with unresolved emotional distance." % bond_object_label

		match clean_descriptor:
			"Devoted":
				return "They trust %s deeply and feel safest when they are close to %s." % [bond_object_label, bond_object_label]
			"Warm":
				return "They feel genuinely close to %s and usually read %s as safe, welcome company." % [bond_object_label, bond_object_label]
			"Open":
				return "They are comfortable around %s, even if some emotional distance is still there." % [bond_object_label]
			"Guarded":
				return "They recognize %s, but they are still protecting part of themselves around %s." % [bond_object_label, bond_object_label]
			"Cold":
				return "They do not feel fully settled around %s and keep their trust pulled back." % [bond_object_label]
			"Hostile":
				return "They feel tense around %s and would rather keep distance than closeness." % [bond_object_label]

		return ""

	if posthumous:
		match clean_descriptor:
			"Devoted":
				return "I trusted them deeply and felt safest when I was close to them."
			"Warm":
				return "I felt genuinely close to them and usually read them as safe, welcome company."
			"Open":
				return "I was comfortable around them, even if some emotional distance was still there."
			"Guarded":
				return "I recognized them, but I was still protecting part of myself around them."
			"Cold":
				return "I did not feel fully settled around them and kept my trust pulled back."
			"Hostile":
				return "I felt tense around them and would rather keep distance than closeness."

		return "My relationship with them ended with unresolved emotional distance."

	match clean_descriptor:
		"Devoted":
			return "I trust them deeply and feel safest when I am close to them."
		"Warm":
			return "I feel genuinely close to them and usually read them as safe, welcome company."
		"Open":
			return "I am comfortable around them, even if some emotional distance is still there."
		"Guarded":
			return "I recognize them, but I am still protecting part of myself around them."
		"Cold":
			return "I do not feel fully settled around them and keep my trust pulled back."
		"Hostile":
			return "I feel tense around them and would rather keep distance than closeness."

	return ""


static func _entity_relationship_popup_panel_style(accent: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.12, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = accent
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_size = 4
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	return style


static func _entity_relationship_progress_background_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.16, 0.18, 0.94)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


static func _entity_relationship_progress_fill_style(fill_color: Color) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = fill_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


static func _entity_relationship_stat_palette(value: int, max_value: int, mode: String = "") -> Dictionary:
	var ratio: float = 0.0
	if max_value > 0:
		ratio = clamp(float(value) / float(max_value), 0.0, 1.0)

	var fill_color: Color = Color(0.7, 0.84, 1.0, 0.96)
	var text_color: Color = Color(1.0, 1.0, 1.0, 0.98)

	match mode:
		"bond":
			if ratio <= 0.35:
				fill_color = Color(1.0, 0.34, 0.34, 0.96)
			elif ratio <= 0.74:
				fill_color = Color(1.0, 0.84, 0.22, 0.96)
			else:
				fill_color = Color(1.0, 0.38, 0.68, 0.96)
		"danger":
			if ratio >= 0.7:
				fill_color = Color(1.0, 0.38, 0.28, 0.98)
			elif ratio >= 0.4:
				fill_color = Color(1.0, 0.72, 0.24, 0.96)
			else:
				fill_color = Color(0.92, 0.94, 0.52, 0.96)
		"health":
			fill_color = Color(0.48, 1.0, 0.76, 0.96)
		"training":
			fill_color = Color(0.76, 1.0, 0.48, 0.96)
		"hunger":
			fill_color = Color(1.0, 0.74, 0.32, 0.96)
		_:
			if ratio <= 0.35:
				fill_color = Color(1.0, 0.34, 0.34, 0.96)
			elif ratio <= 0.74:
				fill_color = Color(1.0, 0.84, 0.22, 0.96)
			else:
				fill_color = Color(1.0, 0.38, 0.68, 0.96)

	return {
		"fill": fill_color,
		"text": text_color
	}


static func _entity_relationship_card_danger_color(danger_value: int) -> Color:
	var safe_danger: int = clampi(danger_value, 0, 10)

	if safe_danger <= 1:
		return Color(0.36, 1.0, 0.42, 1.0)
	if safe_danger <= 3:
		return Color(0.62, 1.0, 0.48, 1.0)
	if safe_danger <= 5:
		return Color(1.0, 0.88, 0.36, 1.0)
	if safe_danger <= 7:
		return Color(1.0, 0.58, 0.28, 1.0)

	return Color(1.0, 0.3, 0.24, 1.0)


static func _entity_relationship_card_dot_row(value: int, max_value: int = 100, dot_count: int = 5) -> String:
	var ratio: float = 0.0
	if max_value > 0:
		ratio = clamp(float(value) / float(max_value), 0.0, 1.0)

	var filled: int = clampi(int(round(ratio * float(dot_count))), 0, dot_count)
	var out: Array = []
	for i in range(dot_count):
		out.append("●" if i < filled else "○")
	return "".join(out)


static func _entity_relationship_trait_icon(trait_text: String) -> String:
	match str(trait_text).strip_edges().to_lower():
		"strong":
			return "✦"
		"sensitive":
			return "❤"
		"trainable":
			return "⬆"
		"protective":
			return "🛡"
		"playful":
			return "★"
		"loyal":
			return "✚"
		"gentle":
			return "❀"
		"alert":
			return "⚑"
		_:
			return "◆"


static func _entity_relationship_delta_flash_color(stat_key: String, delta: int, positive_delta_is_good: bool = true) -> Color:
	var clean_key: String = str(stat_key).strip_edges().to_lower()
	var good_delta: bool = delta > 0 if positive_delta_is_good else delta < 0

	if clean_key == "hunger":
		good_delta = delta < 0

	if good_delta:
		return Color(0.78, 1.0, 0.66, 1.0)

	return Color(1.0, 0.42, 0.46, 1.0)


static func _append_relationship_browser_target(targets: Array, seen: Dictionary, npc: Person, section: String) -> void:
	if npc == null:
		return
	if npc.id <= 0:
		return
	if seen.has(npc.id):
		return

	var final_section:= section
	if not npc.alive:
		final_section = "Dead Relationships"

	seen [npc.id] = true
	targets.append({
		"id": npc.id,
		"section": final_section,
		"npc": npc
	})


static func _add_unique_death_panel_family_id(ids: Array, seen: Dictionary, npc_id: int) -> void:
	if npc_id <= 0:
		return
	if seen.has(npc_id):
		return
	seen [npc_id] = true
	ids.append(npc_id)


static func _other_country_romance_preference_text(preference: String) -> String:
	var clean: String = str(preference).strip_edges().to_lower()
	if clean in ["man", "men", "male", "boyfriend"]:
		return "a man"
	if clean in ["woman", "women", "female", "girlfriend"]:
		return "a woman"
	return "someone"


static func _other_country_romance_target_needs_definite_article(target_name: String) -> bool:
	var clean: String = str(target_name).strip_edges()
	if clean == "":
		return false

	var lower: String = clean.to_lower()
	if lower.begins_with("the "):
		return true

	var exact_targets: Array = [
		"earth kingdom",
		"fire nation",
		"water tribe",
		"water nation",
		"northern water tribe",
		"southern water tribe",
		"northern air temple",
		"southern air temple",
		"eastern air temple",
		"western air temple",
		"maurya empire",
		"kingdom of aksum",
		"kingdom of askum",
		"united states",
		"united kingdom",
		"netherlands",
		"philippines",
		"maldives"
	]

	if lower in exact_targets:
		return true

	var article_markers: Array = [
		" kingdom",
		" empire",
		" nation",
		" republic",
		" dynasty",
		" temple",
		" temples",
		" tribe",
		" tribes",
		" confederation",
		" federation",
		" state",
		" states",
		" realm",
		" caliphate",
		" sultanate",
		" duchy"
	]

	for marker in article_markers:
		if lower.find(str(marker)) >= 0:
			return true

	return false


static func _append_relationship_browser_target_split_dead(
	targets: Array,
	seen: Dictionary,
	npc: Person,
	living_section: String
) -> void:
	if npc == null:
		return
	if seen.has(npc.id):
		return

	var final_section:= living_section
	if not npc.alive:
		final_section = "Dead Relationships"

	seen [npc.id] = true
	targets.append({
		"id": npc.id,
		"npc": npc,
		"section": final_section
	})


static func _relationship_profile_grocery_locked_job(target: Person) -> String:
	if target == null:
		return ""

	if target.has_meta("grocery_identity_locked_job"):
		var locked_job: String = str(target.get_meta("grocery_identity_locked_job")).strip_edges()
		if locked_job != "":
			return locked_job

	return ""


static func _relationship_profile_job_looks_royal(job_text: String) -> bool:
	var lower_job: String = str(job_text).strip_edges().to_lower()
	if lower_job == "":
		return false

	var royal_terms: Array = [
		"king",
		"queen",
		"prince",
		"princess",
		"duke",
		"duchess",
		"emperor",
		"empress",
		"ruler",
		"royal"
	]

	for raw_term in royal_terms:
		if lower_job.find(str(raw_term)) >= 0:
			return true

	return false


static func _relationship_profile_job_is_invalid(job_text: String) -> bool:
	var lower_job: String = str(job_text).strip_edges().to_lower()
	return lower_job == "" or lower_job == "parent" or lower_job == "mother" or lower_job == "father" or lower_job == "guardian"


static func _relationship_profile_target_has_federal_republic_office(target: Person) -> bool:
	if target == null:
		return false

	var office_contract: Dictionary = {}
	var raw_contract: Variant = target.get("civic_office_contract")
	if typeof(raw_contract) == TYPE_DICTIONARY:
		office_contract = (raw_contract as Dictionary).duplicate(true)

	var government_model: String = str(office_contract.get("government_model", "")).strip_edges().to_lower()
	if government_model in [
		"federal_presidential_republic",
		"federal_republic",
		"presidential_republic",
		"constitutional_republic"
	]:
		return true

	var civic_title: String = str(target.get("civic_title")).strip_edges().to_lower()
	var job_key: String = str(target.job).strip_edges().to_lower()

	return civic_title in [
		"president",
		"first lady",
		"first gentleman",
		"vice president"
	] or job_key in [
		"president",
		"president of the united states",
		"first lady",
		"first gentleman",
		"vice president"
	]


static func _relationship_profile_fame_tier_for_value(value: int) -> String:
	if value >= 90:
		return "Legend"
	if value >= 70:
		return "Global"
	if value >= 50:
		return "National"
	if value >= 25:
		return "Local"
	return "None"


static func _relationship_profile_fame_tier_rank(tier: String) -> int:
	match str(tier).strip_edges().to_lower():
		"legend":
			return 4
		"global":
			return 3
		"national":
			return 2
		"local":
			return 1
		_:
			return 0


static func _relationship_profile_effective_property_count(target: Person, raw_property_count: int, effective_social_class: String) -> int:
	if target == null:
		return max(0, raw_property_count)

	if raw_property_count > 0:
		return raw_property_count

	if int(target.age) < 18:
		return 0

	var class_text: String = str(effective_social_class).strip_edges().to_lower()
	if class_text.find("royal") >= 0 or class_text.find("noble") >= 0 or class_text.find("elite") >= 0:
		return 3
	if class_text.find("upper") >= 0:
		return 2

	return 1


static func _relationship_profile_effective_vehicle_count(target: Person, raw_vehicle_count: int, effective_income: int, effective_social_class: String) -> int:
	if target == null:
		return max(0, raw_vehicle_count)

	if raw_vehicle_count > 0:
		return raw_vehicle_count

	if int(target.age) < 18:
		return 0

	var class_text: String = str(effective_social_class).strip_edges().to_lower()
	if class_text.find("royal") >= 0 or class_text.find("noble") >= 0 or class_text.find("elite") >= 0:
		return 2
	if class_text.find("upper") >= 0:
		return 1
	if effective_income >= 65000:
		return 1

	return 0


static func _relationship_profile_home_is_placeholder(city: String, country: String) -> bool:
	var home_text: String = ("%s, %s" % [city, country]).strip_edges().to_lower()
	if home_text == ",":
		return true
	if home_text.find("frontier realm") >= 0:
		return true
	if str(city).strip_edges() == "" or str(country).strip_edges() == "":
		return true
	return false


static func _relationship_profile_should_show_pregnancy_line(target: Person) -> bool:
	if target == null:
		return false

	var gender_text: String = str(target.gender).strip_edges().to_lower()
	var pregnancy_active: bool = int(target.pregnancy_progress) >= 0 or bool(target.pregnancy_known)

	if pregnancy_active:
		return true

	if gender_text == "male" or gender_text == "man" or gender_text == "boy":
		return false

	return true


static func _relationship_profile_hunger_descriptor(hunger_value: float) -> String:
	var value: int = clamp(int(round(hunger_value)), 0, 100)

	if value <= 5:
		return "Critical Starvation"
	if value <= 18:
		return "Starving"
	if value <= 35:
		return "Malnourished"
	if value <= 55:
		return "Hungry"
	if value <= 72:
		return "Peckish"
	if value <= 92:
		return "Satisfied"
	return "Full"


static func _relationship_profile_height_text_from_contract(height_contract: Dictionary) -> String:
	var display: String = str(height_contract.get("display", "")).strip_edges()
	if display != "":
		return display

	var height_in: float = float(height_contract.get("height_in", height_contract.get("height_inches", 0.0)))
	if height_in > 0.0:
		var rounded: int = int(round(height_in))
		var feet: int = int(floor(float(rounded) / 12.0))
		var inches: int = int(rounded % 12)
		return "%d'%d\"" % [feet, inches]

	var display_metric: String = str(height_contract.get("display_metric", "")).strip_edges()
	if display_metric != "":
		return display_metric

	return ""


static func _relationship_profile_weight_text_from_contract(weight_contract: Dictionary) -> String:
	var display: String = str(weight_contract.get("display", "")).strip_edges()
	if display != "":
		return display

	var weight_lbs: float = float(weight_contract.get("weight_lbs", weight_contract.get("walkaround_weight_lbs", 0.0)))
	if weight_lbs > 0.0:
		return "%d lb" % int(round(weight_lbs))

	var display_metric: String = str(weight_contract.get("display_metric", "")).strip_edges()
	if display_metric != "":
		return display_metric

	return ""


static func _relationship_profile_local_direct_number_from_person(target: Person, keys: Array) -> float:
	if target == null:
		return 0.0

	for raw_key in keys:
		var key: String = str(raw_key)
		if key == "":
			continue
		if key in target:
			var raw_value: Variant = target.get(key)
			var number_value: float = float(raw_value)
			if number_value > 0.0:
				return number_value

	return 0.0


static func _relationship_profile_local_body_type_for_actor(target: Person) -> String:
	if target == null:
		return "mesomorph"

	var seed_value: int = abs(hash("relationship_profile_body_type|%d|%s|%s" % [
		int(target.id),
		str(target.gender),
		str(target.first_name)
	])) % 3

	if seed_value == 0:
		return "ectomorph"
	if seed_value == 2:
		return "endomorph"
	return "mesomorph"


static func _relationship_profile_local_body_type_display_name(body_type: String) -> String:
	match str(body_type).strip_edges().to_lower():
		"ectomorph":
			return "Ectomorph"
		"endomorph":
			return "Endomorph"
		_:
			return "Mesomorph"


static func _relationship_profile_local_body_type_traits(body_type: String) -> Dictionary:
	match str(body_type).strip_edges().to_lower():
		"ectomorph":
			return {
				"fat_gain_multiplier": 0.78,
				"muscle_gain_multiplier": 0.88,
				"natural_frame_multiplier": 0.92,
				"metabolism_multiplier": 1.14,
				"weight_drift_to_setpoint": 0.18,
				"description": "Naturally leaner frame, faster metabolism, harder weight gain."
			}
		"endomorph":
			return {
				"fat_gain_multiplier": 1.22,
				"muscle_gain_multiplier": 1.03,
				"natural_frame_multiplier": 1.1,
				"metabolism_multiplier": 0.88,
				"weight_drift_to_setpoint": 0.12,
				"description": "Naturally heavier frame, easier weight gain, slower weight loss."
			}
		_:
			return {
				"fat_gain_multiplier": 1.0,
				"muscle_gain_multiplier": 1.1,
				"natural_frame_multiplier": 1.02,
				"metabolism_multiplier": 1.0,
				"weight_drift_to_setpoint": 0.15,
				"description": "Balanced athletic frame with average weight response."
			}


static func _relationship_profile_local_adult_height_for_actor(target: Person) -> float:
	if target == null:
		return 67.0

	var gender_text: String = str(target.gender).strip_edges().to_lower()
	var base_height: float = 69.0
	if gender_text in ["female", "woman", "girl", "f"]:
		base_height = 64.0

	var rng:= RandomNumberGenerator.new()
	rng.seed = abs(hash("relationship_profile_adult_height|%d|%s|%s" % [
		int(target.id),
		str(target.gender),
		str(target.last_name)
	])) % 2147483647

	return clamp(base_height + rng.randfn(0.0, 2.2), 48.0, 86.0)


static func _relationship_profile_local_height_growth_factor_for_age(age: int) -> float:
	var age_value: float = max(0.0, float(age))
	var maturity_age: float = 18.0

	if age_value <= 0.0:
		return 0.305
	if age_value < 2.0:
		return lerp(0.305, 0.485, age_value / 2.0)
	if age_value < 6.0:
		return lerp(0.485, 0.655, (age_value - 2.0) / 4.0)
	if age_value < 12.0:
		return lerp(0.655, 0.815, (age_value - 6.0) / 6.0)
	if age_value < maturity_age:
		return lerp(0.815, 1.0, (age_value - 12.0) / max(1.0, maturity_age - 12.0))
	if age_value >= 65.0:
		return clamp(1.0 - ((age_value - 65.0) * 0.0012), 0.955, 1.0)

	return 1.0


static func _relationship_profile_local_life_stage_for_age(age: int) -> String:
	if age <= 1:
		return "baby"
	if age <= 5:
		return "child"
	if age <= 12:
		return "preteen"
	if age <= 17:
		return "teen"
	if age <= 25:
		return "young_adult"
	if age <= 59:
		return "adult"
	if age <= 79:
		return "elder"
	return "elderly"


static func _relationship_profile_local_format_height_inches(height_in: float) -> String:
	var rounded: int = int(round(height_in))
	var feet: int = int(floor(float(rounded) / 12.0))
	var inches: int = int(rounded % 12)
	return "%d'%d\"" % [feet, inches]


static func _relationship_profile_local_healthy_weight_for_height(height_in: float, traits: Dictionary, weight_growth_factor: float) -> float:
	var height_m: float = max(0.3, height_in * 0.0254)
	var adult_healthy: float = 22.0 * height_m * height_m * 2.20462
	var frame_multiplier: float = clamp(float(traits.get("natural_frame_multiplier", 1.0)), 0.72, 1.35)
	var growth_factor: float = clamp(weight_growth_factor, 0.1, 1.08)
	return clamp(adult_healthy * frame_multiplier * growth_factor, 5.0, 650.0)


static func _relationship_profile_local_starting_weight_offset(target: Person, body_type: String) -> float:
	if target == null:
		return 0.0

	var rng:= RandomNumberGenerator.new()
	rng.seed = abs(hash("relationship_profile_starting_weight|%d|%s|%s" % [
		int(target.id),
		str(target.age),
		str(body_type)
	])) % 2147483647

	var center: float = 1.5
	match str(body_type).strip_edges().to_lower():
		"ectomorph":
			center = -5.0
		"endomorph":
			center = 7.0
		_:
			center = 1.5

	return rng.randfn(center, 4.0)


static func _relationship_profile_local_weight_category_from_bmi(bmi: float) -> String:
	if bmi < 18.5:
		return "lean"
	if bmi < 25.0:
		return "average"
	if bmi < 30.0:
		return "overweight"
	return "obese"


static func _relationship_profile_unified_child_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.024, 0.058, 0.18)
	style.border_color = Color(1.0, 0.48, 0.72, 0.14)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style


static func _relationship_profile_stats_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.026, 0.07, 0.74)
	style.border_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.shadow_color = Color(1.0, 0.2, 0.64, 0.16)
	style.shadow_size = 14
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func _relationship_profile_move_children(
	source: Node,
	destination: Node
) -> void:
	if source == null or destination == null:
		return

	while source.get_child_count() > 0:
		var child: Node = source.get_child(0)

		source.remove_child(child)
		destination.add_child(child)


static func _relationship_civic_display_title(npc: Person) -> String:
	if npc == null:
		return ""

	var civic_title: String = str(npc.get("civic_title")).strip_edges()
	if civic_title != "":
		return civic_title

	var job_text: String = str(npc.job).strip_edges().to_lower()

	if job_text == "president" or job_text == "president of the united states":
		return "President"

	if job_text == "first lady":
		return "First Lady"

	if job_text == "first gentleman":
		return "First Gentleman"

	return ""


static func _relationship_profile_click_key(kind: String, action_id: String = "", target_id: int = -1) -> String:
	return "%s:%s:%d" % [
		str(kind).strip_edges().to_lower(),
		str(action_id).strip_edges(),
		int(target_id)
	]


static func _relationship_profile_is_primary_click_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event:= event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed

	if event is InputEventScreenTouch:
		var touch_event:= event as InputEventScreenTouch
		return touch_event.pressed

	return false


static func _relationship_profile_switch_room_prewarm_meta_key(target_id: int) -> String:
	return "relationship_profile_switch_room_prewarm_requested_%d" % int(target_id)


static func _relationship_profile_gendered_niece_nephew_label(target: Person) -> String:
	if target == null:
		return "Niece/Nephew"

	var gender: String = str(target.gender).strip_edges().to_lower()
	if gender == "male" or gender == "man" or gender == "boy":
		return "Nephew"
	if gender == "female" or gender == "woman" or gender == "girl":
		return "Niece"

	return "Niece/Nephew"


static func _relationship_profile_gendered_child_label(target: Person) -> String:
	if target == null:
		return "child"

	var gender: String = str(target.gender).strip_edges().to_lower()
	if gender == "male" or gender == "man" or gender == "boy":
		return "son"
	if gender == "female" or gender == "woman" or gender == "girl":
		return "daughter"

	return "child"


static func _relationship_profile_gendered_sibling_label(sibling: Person) -> String:
	if sibling == null:
		return "Sibling"

	var gender: String = str(sibling.gender).strip_edges().to_lower()
	if gender == "male" or gender == "man" or gender == "boy":
		return "Brother"
	if gender == "female" or gender == "woman" or gender == "girl":
		return "Sister"

	return "Sibling"


static func _relationship_hub_climate_chip_style(climate_value: int) -> StyleBoxFlat:
	var safe_value: int = clamp(int(climate_value), 0, 100)
	var ratio: float = clamp(float(safe_value) / 100.0, 0.0, 1.0)

	var cold_accent: Color = Color(0.34, 0.62, 1.0, 0.92)
	var neutral_accent: Color = Color(0.78, 0.64, 0.92, 0.94)
	var warm_accent: Color = Color(1.0, 0.5, 0.74, 0.98)

	var accent: Color = cold_accent.lerp(neutral_accent, clamp(ratio * 2.0, 0.0, 1.0))
	if ratio > 0.5:
		accent = neutral_accent.lerp(warm_accent, clamp((ratio - 0.5) * 2.0, 0.0, 1.0))

	var cold_base: Color = Color(0.018, 0.03, 0.064, 0.98)
	var warm_base: Color = Color(0.105, 0.034, 0.082, 0.98)

	var style:= StyleBoxFlat.new()
	style.bg_color = cold_base.lerp(warm_base, ratio)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.62 + ratio * 0.3)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.12 + ratio * 0.42)
	style.shadow_size = int(round(lerp(5.0, 26.0, ratio)))
	style.shadow_offset = Vector2(0, 4)
	return style


static func _relationship_hub_control_tree_has_rendered_card(root: Node, depth: int = 0) -> bool:
	if root == null:
		return false
	if not is_instance_valid(root):
		return false
	if depth > 8:
		return false

	if root is Control:
		var control: Control = root as Control
		if control.has_meta("relationship_card_npc_id"):
			return true
		if control.has_meta("relationship_card_contract"):
			return true
		if control.has_meta("relationship_card_contract_engine_owned"):
			return true

	for child in root.get_children():
		if child is Node:
			if RelationshipsSceneSupport._relationship_hub_control_tree_has_rendered_card(child as Node, depth + 1):
				return true

	return false


static func _relationship_hub_section_key_from_button_text(label_text: String) -> String:
	var clean: String = str(label_text).strip_edges().to_lower()
	match clean:
		"family":
			return "family"
		"ancestors":
			return "ancestors"
		"my household":
			return "household"
		"partner":
			return "partner"
		"pets", "pet", "animals", "animal", "companions":
			return "pets"
		"descendants":
			return "descendants"
		"dead":
			return "dead"
		"social":
			return "social"
		"exes":
			return "exes"
		_:
			return clean


static func _relationship_hub_section_palette(section_key: String) -> Dictionary:
	var clean: String = str(section_key).strip_edges().to_lower()
	match clean:
		"family":
			return {
				"accent": Color(1.0, 0.5, 0.74, 0.96),
				"active_fill": Color(0.145, 0.05, 0.105, 0.98),
				"inactive_fill": Color(0.06, 0.03, 0.055, 0.94),
				"hover_fill": Color(0.195, 0.065, 0.125, 0.98),
				"font_color": Color(1.0, 0.96, 0.99, 1.0),
				"shadow_color": Color(0.48, 0.08, 0.24, 0.28)
			}
		"ancestors":
			return {
				"accent": Color(0.92, 0.8, 0.46, 0.94),
				"active_fill": Color(0.135, 0.105, 0.04, 0.98),
				"inactive_fill": Color(0.06, 0.05, 0.028, 0.94),
				"hover_fill": Color(0.18, 0.145, 0.055, 0.98),
				"font_color": Color(1.0, 0.97, 0.88, 1.0),
				"shadow_color": Color(0.38, 0.3, 0.1, 0.24)
			}
		"household":
			return {
				"accent": Color(1.0, 0.72, 0.42, 0.94),
				"active_fill": Color(0.17, 0.088, 0.032, 0.98),
				"inactive_fill": Color(0.08, 0.045, 0.02, 0.94),
				"hover_fill": Color(0.215, 0.108, 0.04, 0.98),
				"font_color": Color(1.0, 0.97, 0.92, 1.0),
				"shadow_color": Color(0.46, 0.2, 0.05, 0.24)
			}
		"social":
			return {
				"accent": Color(0.42, 0.88, 1.0, 0.94),
				"active_fill": Color(0.035, 0.112, 0.15, 0.98),
				"inactive_fill": Color(0.02, 0.058, 0.085, 0.94),
				"hover_fill": Color(0.05, 0.145, 0.188, 0.98),
				"font_color": Color(0.95, 0.99, 1.0, 1.0),
				"shadow_color": Color(0.06, 0.28, 0.36, 0.24)
			}
		"dead":
			return {
				"accent": Color(0.62, 0.7, 0.84, 0.9),
				"active_fill": Color(0.06, 0.074, 0.105, 0.98),
				"inactive_fill": Color(0.035, 0.045, 0.065, 0.94),
				"hover_fill": Color(0.085, 0.1, 0.135, 0.98),
				"font_color": Color(0.92, 0.96, 1.0, 1.0),
				"shadow_color": Color(0.1, 0.14, 0.22, 0.2)
			}
		"partner":
			return {
				"accent": Color(1.0, 0.4, 0.6, 0.96),
				"active_fill": Color(0.165, 0.04, 0.085, 0.98),
				"inactive_fill": Color(0.072, 0.02, 0.05, 0.94),
				"hover_fill": Color(0.21, 0.05, 0.098, 0.98),
				"font_color": Color(1.0, 0.96, 0.98, 1.0),
				"shadow_color": Color(0.44, 0.06, 0.18, 0.24)
			}
		"exes":
			return {
				"accent": Color(0.98, 0.42, 0.62, 0.92),
				"active_fill": Color(0.115, 0.045, 0.07, 0.98),
				"inactive_fill": Color(0.055, 0.025, 0.045, 0.94),
				"hover_fill": Color(0.155, 0.05, 0.08, 0.98),
				"font_color": Color(1.0, 0.96, 0.98, 1.0),
				"shadow_color": Color(0.4, 0.08, 0.16, 0.22)
			}
		"descendants":
			return {
				"accent": Color(0.88, 0.6, 1.0, 0.94),
				"active_fill": Color(0.102, 0.052, 0.13, 0.98),
				"inactive_fill": Color(0.052, 0.028, 0.072, 0.94),
				"hover_fill": Color(0.13, 0.062, 0.165, 0.98),
				"font_color": Color(0.98, 0.96, 1.0, 1.0),
				"shadow_color": Color(0.22, 0.08, 0.3, 0.22)
			}
		_:
			return {
				"accent": Color(1.0, 0.48, 0.72, 0.9),
				"active_fill": Color(0.1, 0.04, 0.085, 0.98),
				"inactive_fill": Color(0.05, 0.022, 0.045, 0.94),
				"hover_fill": Color(0.135, 0.05, 0.095, 0.98),
				"font_color": Color(1.0, 1.0, 1.0, 1.0),
				"shadow_color": Color(0.0, 0.0, 0.0, 0.24)
			}


static func _relationship_hub_visual_pulse_bucket(pulse_strength: float, max_bucket: int = 6) -> int:
	var safe_max: int = max(1, int(max_bucket))
	return clamp(int(round(clamp(float(pulse_strength), 0.0, 1.0) * float(safe_max))), 0, safe_max)


static func _add_unique_institution_relationship_id(ids: Array, seen: Dictionary, npc_id: int) -> void:
	if npc_id <= 0:
		return
	if seen.has(npc_id):
		return
	seen [npc_id] = true
	ids.append(npc_id)


static func _relationship_safe_person_id_array(person: Person, property_id: String) -> Array:
	var out: Array = []

	if person == null:
		return out

	var raw_value: Variant = person.get(property_id)
	if typeof(raw_value) != TYPE_ARRAY:
		return out

	for raw_id in raw_value:
		var clean_id: int = int(raw_id)
		if clean_id <= 0:
			continue
		if clean_id in out:
			continue
		out.append(clean_id)

	return out


static func _relationship_people_share_any_parent_id(a_parent_ids: Array, b_parent_ids: Array) -> bool:
	if a_parent_ids.is_empty() or b_parent_ids.is_empty():
		return false

	for raw_parent_id in a_parent_ids:
		if int(raw_parent_id) in b_parent_ids:
			return true

	return false


static func _relationship_hub_family_lane_has_members(ids: Array) -> bool:
	if typeof(ids) != TYPE_ARRAY:
		return false

	for raw_id in ids:
		if int(raw_id) > 0:
			return true

	return false


static func _career_coworker_group_label(gs: GameState,
	coworker: Person) -> String:
	if coworker == null or gs == null or gs.player == null:
		return "Workplace Team"

	var workplace_id: String = str(coworker.current_workplace_id).strip_edges()
	if gs.workplace_engine != null and workplace_id != "":
		var meta_value = gs.workplace_engine.workplace_meta.get(workplace_id, {})
		if typeof(meta_value) == TYPE_DICTIONARY:
			var meta: Dictionary = meta_value
			var department: String = str(meta.get("department", "")).strip_edges()
			if department != "":
				return department

	if coworker.id in gs.player.friends:
		return "Work Friends"

	var relation_score: int = RelationshipsSceneSupport._relationship_score_for_target(gs, coworker)
	if relation_score <= 35:
		return "Workplace Rivals"
	if int(coworker.job_performance) >= 80:
		return "High Performers"
	if int(coworker.job_performance) <= 35:
		return "Needs Support"
	return "Workplace Team"


static func _career_coworker_marker_suffix(gs: GameState,
	coworker: Person) -> String:
	if coworker == null:
		return "Coworker"

	var tags: Array = []
	var role_text: String = str(coworker.job).strip_edges()
	if role_text != "":
		tags.append(role_text)

	if gs != null and gs.player != null:
		if coworker.id in gs.player.friends:
			tags.append("Friend")
		else:
			var relation_score: int = RelationshipsSceneSupport._relationship_score_for_target(gs, coworker)
			if relation_score <= 35:
				tags.append("Rival")
			elif relation_score >= 70:
				tags.append("Trusted")

	if int(coworker.job_performance) >= 80:
		tags.append("High Perf")
	elif int(coworker.job_performance) <= 35:
		tags.append("Low Perf")

	if tags.is_empty():
		return "Coworker"
	return " • ".join(tags)


static func _nearby_switch_is_immediate_household_member(gs: GameState,
	npc: Person) -> bool:
	if gs == null or gs.player == null or npc == null:
		return false

	var player: Person = gs.player
	var npc_id: int = int(npc.id)

	if ValueSceneSupport._safe_array(player.parents).has(npc_id):
		return true
	if ValueSceneSupport._safe_array(player.children).has(npc_id):
		return true
	if player.partner != null and int(player.partner.id) == npc_id:
		return true

	for raw_parent_id in ValueSceneSupport._safe_array(player.parents):
		var parent: Person = gs.get_or_reactivate_npc_by_id(int(raw_parent_id))
		if parent == null:
			continue
		if ValueSceneSupport._safe_array(parent.children).has(npc_id):
			return true

	return false


static func _nearby_switch_is_family_member(gs: GameState,
	npc: Person) -> bool:
	if gs == null or gs.player == null or npc == null:
		return false

	var player: Person = gs.player
	var npc_id: int = int(npc.id)

	if RelationshipsSceneSupport._nearby_switch_is_immediate_household_member(gs, npc):
		return true

	if ValueSceneSupport._safe_array(npc.children).has(int(player.id)):
		return true
	if ValueSceneSupport._safe_array(player.children).has(npc_id):
		return true
	if ValueSceneSupport._safe_array(player.parents).has(npc_id):
		return true
	if ValueSceneSupport._safe_array(npc.parents).has(int(player.id)):
		return true

	for raw_parent_id in ValueSceneSupport._safe_array(player.parents):
		var parent: Person = gs.get_or_reactivate_npc_by_id(int(raw_parent_id))
		if parent == null:
			continue
		if ValueSceneSupport._safe_array(parent.parents).has(npc_id):
			return true
		if ValueSceneSupport._safe_array(parent.children).has(npc_id):
			return true

	for raw_child_id in ValueSceneSupport._safe_array(player.children):
		var child: Person = gs.get_or_reactivate_npc_by_id(int(raw_child_id))
		if child == null:
			continue
		if ValueSceneSupport._safe_array(child.children).has(npc_id):
			return true

	return false


static func _nearby_switch_contract_distance_to_player(gs: GameState,
	npc: Person) -> int:
	if gs == null or gs.player == null or npc == null:
		return 999999

	if RelationshipsSceneSupport._nearby_switch_is_immediate_household_member(gs, npc):
		return 0

	var player_city: String = ValueSceneSupport._person_contract_city(gs.player)
	var npc_city: String = ValueSceneSupport._person_contract_city(npc)
	var player_country: String = ValueSceneSupport._person_contract_country(gs.player)
	var npc_country: String = ValueSceneSupport._person_contract_country(npc)

	if player_city != "" and npc_city != "" and player_city == npc_city:
		return 1 + int(abs(hash("neighbor|%s|%s" % [str(gs.player.id), str(npc.id)])) % 5)

	if player_country != "" and npc_country != "" and player_country == npc_country:
		if gs.has_method("_world_distance_to_player"):
			return max(6, int(gs._world_distance_to_player(npc)))
		return 6 + int(abs(hash("local|%s|%s" % [str(gs.player.id), str(npc.id)])) % 45)

	if gs.has_method("_world_distance_to_player"):
		return int(gs._world_distance_to_player(npc))

	return 999999


static func _ensure_romance_contract_engine_ready(gs: GameState) -> bool:
	if gs == null:
		return false

	if gs.has_method("_ensure_load_game_runtime_dependencies"):
		gs._ensure_load_game_runtime_dependencies()

	if gs.romance_contract_engine == null:
		gs.romance_contract_engine = RomanceContractEngine.new(gs)

	if gs.romance_contract_engine == null:
		return false

	if "gs" in gs.romance_contract_engine:
		gs.romance_contract_engine.gs = gs

	if not gs.romance_contract_engine.has_method("begin_foreign_date_search"):
		return false

	if not gs.romance_contract_engine.has_method("accept_pending_foreign_romance_contract"):
		return false

	return true


static func _relationship_score_for_target(gs: GameState,
	target: Person) -> int:
	if gs == null or gs.player == null or target == null:
		return 0

	if gs.relationship_engine != null and gs.relationship_engine.has_method("ensure_pair_relationship_baseline"):
		return int(gs.relationship_engine.ensure_pair_relationship_baseline(gs.player, target))

	if typeof(gs.player.affection) == TYPE_DICTIONARY:
		return clamp(int(gs.player.affection.get(target.id, 0)), 0, 100)

	return 0


static func _relationship_hub_pet_card_contracts_for_player(gs: GameState) -> Array:
	if gs == null or gs.player == null:
		return []
	if gs.pets_contract_engine == null:
		return []
	return gs.pets_contract_engine.get_pet_cards_for_actor(gs.player, {
		"source": "mainscene.relationship_hub_pets_section"
	})


static func _entity_relationship_trait_color(trait_text: String, entity: Dictionary = {}) -> Color:
	var stats: Dictionary = ValueSceneSupport._safe_dictionary(entity.get("stats", {}))
	var trust_value: int = int(stats.get("trust", 50))
	var training_value: int = int(stats.get("training", 0))

	match str(trait_text).strip_edges().to_lower():
		"strong":
			return Color(1.0, 0.72, 0.42, 1.0)
		"sensitive":
			return Color(1.0, 0.56, 0.7, 1.0) if trust_value > 35 else Color(1.0, 0.38, 0.54, 1.0)
		"trainable":
			return Color(0.76, 1.0, 0.52, 1.0) if training_value >= 50 else Color(0.66, 0.94, 0.54, 1.0)
		"protective":
			return Color(0.8, 0.92, 1.0, 1.0)
		"playful":
			return Color(1.0, 0.92, 0.46, 1.0)
		"loyal":
			return Color(0.78, 1.0, 0.86, 1.0)
		"gentle":
			return Color(0.92, 0.86, 1.0, 1.0)
		"alert":
			return Color(1.0, 0.76, 0.38, 1.0)
		_:
			return Color(0.86, 0.92, 1.0, 1.0)


static func _entity_relationship_profile_commit_delta_for_stat(stat_key: String, state_delta: Dictionary, bond_delta: int = 0) -> int:
	var clean_key: String = str(stat_key).strip_edges().to_lower()
	if clean_key == "bond":
		return bond_delta

	var before_stats: Dictionary = ValueSceneSupport._safe_dictionary(state_delta.get("before", {}))
	var after_stats: Dictionary = ValueSceneSupport._safe_dictionary(state_delta.get("after", {}))
	if before_stats.is_empty() or after_stats.is_empty():
		return 0

	return int(after_stats.get(clean_key, before_stats.get(clean_key, 0))) - int(before_stats.get(clean_key, 0))


static func _household_creator_relationship_gender_lock(gs: GameState,
	raw_relation: String) -> String:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null and gs.family_creation_contract_engine.has_method("relationship_gender_lock"):
		return str(gs.family_creation_contract_engine.relationship_gender_lock(raw_relation)).strip_edges().to_lower()

	var relation: String = RelationshipsSceneSupport._household_normalize_relationship(gs, raw_relation)
	match relation:
		"father", "son", "brother", "husband", "uncle":
			return "male"
		"mother", "daughter", "sister", "wife", "aunt":
			return "female"
		_:
			return ""


static func _household_creator_gender_adjusted_relationship(gs: GameState,
	raw_relation: String, gender_text: String) -> String:
	var relation: String = RelationshipsSceneSupport._household_normalize_relationship(gs, raw_relation)
	var gender: String = str(gender_text).strip_edges().to_lower()

	if gender == "male":
		match relation:
			"mother":
				return "Father"
			"daughter":
				return "Son"
			"sister":
				return "Brother"
			"wife":
				return "Husband"
			"aunt":
				return "Uncle"

	if gender == "female":
		match relation:
			"father":
				return "Mother"
			"son":
				return "Daughter"
			"brother":
				return "Sister"
			"husband":
				return "Wife"
			"uncle":
				return "Aunt"

	return raw_relation


static func _household_creator_relationship_age_range(gs: GameState,
	raw_relation: String, anchor_age: int = -1) -> Dictionary:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null and gs.family_creation_contract_engine.has_method("relationship_age_range"):
		return gs.family_creation_contract_engine.relationship_age_range(raw_relation, anchor_age)

	var relation: String = RelationshipsSceneSupport._household_normalize_relationship(gs, raw_relation)
	match relation:
		"mother", "father":
			if anchor_age >= 0:
				return { "min": int(clamp(anchor_age + 16, 18, 130)), "max": 130}
			return { "min": 18, "max": 130}
		"son", "daughter":
			if anchor_age >= 16:
				return { "min": 0, "max": int(clamp(anchor_age - 16, 0, 130))}
			return { "min": 0, "max": 0}
		"husband", "wife", "ex":
			return { "min": 18, "max": 130}
		"grandparent":
			return { "min": 65, "max": 130}
		_:
			return { "min": 0, "max": 130}


static func _household_creator_default_age_for_relationship(gs: GameState,
	raw_relation: String, anchor_age: int, min_age: int, max_age: int) -> int:
	var relation: String = RelationshipsSceneSupport._household_normalize_relationship(gs, raw_relation)
	match relation:
		"mother", "father":
			return int(clamp(anchor_age + 30, min_age, max_age))
		"son", "daughter":
			return int(clamp(anchor_age - 25, min_age, max_age))
		"husband", "wife", "ex", "brother", "sister", "cousin", "friend", "roommate":
			return int(clamp(anchor_age, min_age, max_age))
		"uncle", "aunt":
			return int(clamp(anchor_age + 20, min_age, max_age))
		"grandparent":
			return int(clamp(max(70, anchor_age + 55), min_age, max_age))
		_:
			return int(clamp(25, min_age, max_age))


static func _household_normalize_relationship(gs: GameState,
	raw_value: String) -> String:
	CreationSceneSupport._ensure_family_creation_contract_engine(gs)
	if gs != null and gs.family_creation_contract_engine != null:
		return gs.family_creation_contract_engine.normalize_relationship(raw_value)

	var value: String = str(raw_value).strip_edges().to_lower()
	if value == "":
		return "none"
	return value


static func _collect_ancestor_generation_ids(gs: GameState,
	person: Person, generation: int) -> Array:
	var out: Array = []
	if person == null:
		return out
	if generation <= 1:
		return out

	var frontier: Array = []
	for pid in person.parents:
		frontier.append(int(pid))

	var depth: int = 1
	var seen: Dictionary = {}

	while depth < generation and frontier.size() > 0:
		var next_frontier: Array = []
		for pid in frontier:
			var facts: Dictionary = gs.get_npc_facts_by_id(int(pid))
			if facts.is_empty():
				continue
			var parent_ids_raw = facts.get("parents", [])
			if typeof(parent_ids_raw) != TYPE_ARRAY:
				continue
			for ancestor_pid in parent_ids_raw:
				next_frontier.append(int(ancestor_pid))
		frontier = next_frontier
		depth += 1

	for pid in frontier:
		var ancestor_id: int = int(pid)
		if ancestor_id <= 0:
			continue
		if seen.has(ancestor_id):
			continue
		seen [ancestor_id] = true
		out.append(ancestor_id)

	return out


static func _collect_descendant_generation_ids(gs: GameState,
	person: Person, generation: int) -> Array:
	var out: Array = []
	if person == null:
		return out
	if generation <= 0:
		return out

	var frontier: Array = []
	var root_facts: Dictionary = gs.get_npc_facts_by_id(int(person.id)) if gs != null and gs.has_method("get_npc_facts_by_id") else {}
	var root_children_raw: Variant = root_facts.get("children", person.children) if not root_facts.is_empty() else person.children
	var root_children: Array = root_children_raw if typeof(root_children_raw) == TYPE_ARRAY else []

	for cid in person.children:
		if int(cid) > 0 and int(cid) not in frontier:
			frontier.append(int(cid))

	for cid in root_children:
		if int(cid) > 0 and int(cid) not in frontier:
			frontier.append(int(cid))

	var depth: int = 1
	var seen: Dictionary = {}

	while depth < generation and frontier.size() > 0:
		var next_frontier: Array = []
		for cid in frontier:
			var facts: Dictionary = gs.get_npc_facts_by_id(int(cid))
			if facts.is_empty():
				continue
			var child_ids_raw = facts.get("children", [])
			if typeof(child_ids_raw) != TYPE_ARRAY:
				continue
			for gcid in child_ids_raw:
				if int(gcid) > 0 and int(gcid) not in next_frontier:
					next_frontier.append(int(gcid))
		frontier = next_frontier
		depth += 1

	for cid in frontier:
		var descendant_id: int = int(cid)
		if descendant_id <= 0:
			continue
		if seen.has(descendant_id):
			continue
		seen [descendant_id] = true
		out.append(descendant_id)

	return out


static func _append_relationship_browser_target_split_dead_by_id(gs: GameState,

	targets: Array,
	seen: Dictionary,
	npc_id: int,
	living_section: String
) -> void:
	if npc_id <= 0:
		return

	var npc: Person = gs.get_npc_by_id(npc_id)
	if npc == null:
		npc = gs.get_or_reactivate_npc_by_id(npc_id)

	if npc == null:
		var facts: Dictionary = gs.get_npc_facts_by_id(npc_id)
		if facts.is_empty():
			return
		var ghost:= Person.new()
		ghost.id = npc_id
		ghost.first_name = str(facts.get("first_name", ""))
		ghost.last_name = str(facts.get("last_name", ""))
		ghost.gender = str(facts.get("gender", ""))
		ghost.age = int(facts.get("age", 0))
		ghost.alive = bool(facts.get("alive", false))
		npc = ghost

	RelationshipsSceneSupport._append_relationship_browser_target_split_dead(targets, seen, npc, living_section)


static func _collect_death_panel_family_member_ids(gs: GameState,
	root: Person) -> Array:
	var ids: Array = []
	var seen: Dictionary = {}
	if root == null or gs == null:
		return ids
	RelationshipsSceneSupport._add_unique_death_panel_family_id(ids, seen, int(root.id))
	var partner: Person = gs.get_valid_partner(root, true, true)
	if partner != null:
		RelationshipsSceneSupport._add_unique_death_panel_family_id(ids, seen, int(partner.id))
	for parent_id_value in root.parents:
		RelationshipsSceneSupport._add_unique_death_panel_family_id(ids, seen, int(parent_id_value))
	for child_id_value in root.children:
		RelationshipsSceneSupport._add_unique_death_panel_family_id(ids, seen, int(child_id_value))
	if not root.parents.is_empty():
		for npc in gs.npcs:
			if npc == null:
				continue
			if int(npc.id) == int(root.id):
				continue
			if npc.parents == root.parents:
				RelationshipsSceneSupport._add_unique_death_panel_family_id(ids, seen, int(npc.id))
	return ids


static func _other_country_romance_initial_diary_line(gs: GameState,
	entry: Dictionary, preference: String) -> String:
	var target_text: String = RelationshipsSceneSupport._other_country_romance_target_sentence_name(entry)
	var preference_text: String = RelationshipsSceneSupport._other_country_romance_preference_text(preference)
	var era_name: String = str(gs.era.name if gs != null and gs.era != null and "name" in gs.era else "").strip_edges()
	var lower_era: String = era_name.to_lower()

	if lower_era.find("ancient") >= 0 or lower_era.find("medieval") >= 0:
		return "I sent a letter to %s hoping to meet %s." % [target_text, preference_text]

	if lower_era.find("future") >= 0:
		return "I sent a future-era romance signal toward %s hoping to meet %s." % [target_text, preference_text]

	return "I made a public statement in %s hoping to meet %s." % [target_text, preference_text]


static func _other_country_romance_target_sentence_name(entry: Dictionary) -> String:
	var clean: String = str(entry.get("name", entry.get("entry_id", "that place"))).strip_edges()
	if clean == "":
		return "that place"

	var lower: String = clean.to_lower()
	if lower.begins_with("the "):
		return "the %s" % clean.substr(4).strip_edges()

	if RelationshipsSceneSupport._other_country_romance_target_needs_definite_article(clean):
		return "the %s" % clean

	return clean


static func _relationship_descendant_section_from_target_facts(gs: GameState,
	target: Person) -> String:
	if gs == null or gs.player == null or target == null:
		return ""

	var observer_id: int = int(gs.player.id)
	var target_id: int = int(target.id)
	if observer_id <= 0 or target_id <= 0 or observer_id == target_id:
		return ""

	var frontier: Array = [target_id]
	var visited: Dictionary = {}

	for depth in range(1, 5):
		var next_frontier: Array = []

		for raw_id in frontier:
			var current_id: int = int(raw_id)
			if current_id <= 0:
				continue
			if visited.has(current_id):
				continue
			visited [current_id] = true

			var facts: Dictionary = gs.get_npc_facts_by_id(current_id) if gs.has_method("get_npc_facts_by_id") else {}
			if facts.is_empty():
				continue

			var parent_ids_raw: Variant = facts.get("parents", [])
			var parent_ids: Array = parent_ids_raw if typeof(parent_ids_raw) == TYPE_ARRAY else []

			for raw_parent_id in parent_ids:
				var parent_id: int = int(raw_parent_id)
				if parent_id == observer_id:
					match depth:
						1:
							return "Children"
						2:
							return "Grandchildren"
						3:
							return "Great-Grandchildren"
						_:
							return "Descendants"

				if parent_id > 0:
					next_frontier.append(parent_id)

		frontier = next_frontier

	return ""


static func _relationship_label_from_bidirectional_lineage_facts(gs: GameState,
	target: Person) -> String:
	if target == null:
		return ""

	var descendant_section: String = RelationshipsSceneSupport._relationship_descendant_section_from_target_facts(gs, target)
	if descendant_section == "":
		return ""

	match descendant_section:
		"Children":
			if str(target.gender) == "Male":
				return "Son"
			if str(target.gender) == "Female":
				return "Daughter"
			return "Child"
		"Grandchildren":
			if str(target.gender) == "Male":
				return "Grandson"
			if str(target.gender) == "Female":
				return "Granddaughter"
			return "Grandchild"
		"Great-Grandchildren":
			if str(target.gender) == "Male":
				return "Great-Grandson"
			if str(target.gender) == "Female":
				return "Great-Granddaughter"
			return "Great-Grandchild"
		_:
			return "Descendant"


static func _relationship_profile_target_is_grocery_locked_non_royal(target: Person) -> bool:
	var locked_job: String = RelationshipsSceneSupport._relationship_profile_grocery_locked_job(target)
	if locked_job == "":
		return false

	var lower_job: String = locked_job.to_lower()
	var royal_terms: Array = [
		"king",
		"queen",
		"prince",
		"princess",
		"duke",
		"duchess",
		"emperor",
		"empress",
		"ruler",
		"royal"
	]

	for raw_term in royal_terms:
		if lower_job.find(str(raw_term)) >= 0:
			return false

	return true


static func _relationship_profile_fallback_job_for(gs: GameState,
	target: Person) -> String:
	if target == null:
		return "Unemployed"

	if int(target.age) < 16:
		return "Student"

	if int(target.age) < 18:
		return "Part-Time Worker"

	if gs != null and gs.career_engine != null and gs.career_engine.has_method("pick_job_for"):
		var picked_job: String = str(gs.career_engine.pick_job_for(target)).strip_edges()
		if picked_job != "" and not RelationshipsSceneSupport._relationship_profile_job_is_invalid(picked_job) and not RelationshipsSceneSupport._relationship_profile_job_looks_royal(picked_job):
			return picked_job

	var fallback_jobs: Array = [
		"Teacher",
		"Nurse",
		"Mechanic",
		"Cashier",
		"Office Worker",
		"Delivery Driver",
		"Engineer",
		"Security Guard",
		"Retail Manager",
		"Construction Worker",
		"Accountant",
		"Chef"
	]

	var seed_value: int = abs(int(hash("%d|profile_fallback_job|%d" % [int(target.id), int(gs.year) if gs != null else 0])))
	return str(fallback_jobs [seed_value % fallback_jobs.size()])


static func _relationship_profile_effective_job_for(gs: GameState,
	target: Person, grocery_locked_non_royal: bool) -> String:
	if target == null:
		return "Unemployed"

	var federal_job: String = RelationshipsSceneSupport._relationship_profile_federal_republic_job_for(target)
	if federal_job != "":
		target.job = federal_job
		target.is_royal = false
		target.royal_title = ""
		target.succession_rank = 99
		return federal_job

	var locked_grocery_job: String = RelationshipsSceneSupport._relationship_profile_grocery_locked_job(target)
	var effective_job: String = str(target.job).strip_edges()

	if locked_grocery_job != "":
		effective_job = locked_grocery_job
	elif gs != null and gs.royalty_engine != null and gs.royalty_engine.has_method("_formal_royal_job_for") and not grocery_locked_non_royal:
		var royal_job: String = str(gs.royalty_engine._formal_royal_job_for(target)).strip_edges()
		if royal_job != "" and not RelationshipsSceneSupport._relationship_profile_target_has_federal_republic_office(target):
			effective_job = royal_job

	if RelationshipsSceneSupport._relationship_profile_job_is_invalid(effective_job):
		effective_job = RelationshipsSceneSupport._relationship_profile_fallback_job_for(gs, target)
		target.job = effective_job

	if grocery_locked_non_royal and RelationshipsSceneSupport._relationship_profile_job_looks_royal(effective_job):
		effective_job = RelationshipsSceneSupport._relationship_profile_fallback_job_for(gs, target)
		target.job = effective_job

	if RelationshipsSceneSupport._relationship_profile_target_has_federal_republic_office(target) and RelationshipsSceneSupport._relationship_profile_job_looks_royal(effective_job):
		effective_job = RelationshipsSceneSupport._relationship_profile_federal_republic_job_for(target)
		target.job = effective_job
		target.is_royal = false
		target.royal_title = ""
		target.succession_rank = 99

	if effective_job == "":
		effective_job = "Unemployed"

	return effective_job


static func _relationship_profile_federal_republic_job_for(target: Person) -> String:
	if target == null:
		return ""

	if not RelationshipsSceneSupport._relationship_profile_target_has_federal_republic_office(target):
		return ""

	var office_contract: Dictionary = {}
	var raw_contract: Variant = target.get("civic_office_contract")
	if typeof(raw_contract) == TYPE_DICTIONARY:
		office_contract = (raw_contract as Dictionary).duplicate(true)

	var office_text: String = str(office_contract.get("office", "")).strip_edges()
	var full_title: String = str(office_contract.get("office_full_title", "")).strip_edges()
	var civic_title: String = str(target.get("civic_title")).strip_edges()
	var job_text: String = str(target.job).strip_edges()
	var job_key: String = job_text.to_lower()

	if office_text == "President" or civic_title == "President" or job_key == "president" or job_key == "president of the united states":
		return "President of the United States"

	if office_text in ["First Lady", "First Gentleman"]:
		return office_text

	if civic_title in ["First Lady", "First Gentleman", "Vice President"]:
		return civic_title

	if full_title != "":
		if full_title.begins_with("The "):
			full_title = full_title.substr(4).strip_edges()
		if full_title == "President of the United States":
			return "President of the United States"
		return full_title

	if job_text != "":
		return job_text

	return ""


static func _relationship_profile_effective_fame_tier_for(gs: GameState,
	target: Person) -> String:
	if target == null:
		return "None"

	var civic_fame_floor: int = RelationshipsSceneSupport._relationship_profile_civic_fame_floor(gs, target)
	var fame_value: int = max(int(target.fame), civic_fame_floor)

	if fame_value > int(target.fame):
		target.fame = fame_value

	var resolved_tier: String = RelationshipsSceneSupport._relationship_profile_fame_tier_for_value(fame_value)

	if str(target.fame_tier).strip_edges() == "" or str(target.fame_tier).strip_edges() == "None" or RelationshipsSceneSupport._relationship_profile_fame_tier_rank(resolved_tier) > RelationshipsSceneSupport._relationship_profile_fame_tier_rank(str(target.fame_tier)):
		target.fame_tier = resolved_tier

	return str(target.fame_tier)


static func _relationship_profile_civic_fame_floor(gs: GameState,
	target: Person) -> int:
	if target == null:
		return 0

	var federal_job: String = RelationshipsSceneSupport._relationship_profile_federal_republic_job_for(target).strip_edges().to_lower()
	if federal_job == "president of the united states":
		return 85

	if federal_job in ["first lady", "first gentleman"]:
		return 55

	if RelationshipsSceneSupport._relationship_profile_target_is_presidential_child(gs, target):
		return 35

	return 0


static func _relationship_profile_target_is_presidential_child(gs: GameState,
	target: Person) -> bool:
	if target == null or gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return false

	var president_id: int = int(gs.scenario_state.get("presidential_parent_contract_president_id", -1))
	var first_partner_id: int = int(gs.scenario_state.get("presidential_parent_contract_first_partner_id", -1))
	var target_id: int = int(target.id)

	if president_id <= 0 and first_partner_id <= 0:
		return false

	if target.parents.has(president_id) or target.parents.has(first_partner_id):
		return true

	var president: Person = gs.get_or_reactivate_npc_by_id(president_id) if president_id > 0 else null
	if president != null and president.children.has(target_id):
		return true

	var first_partner: Person = gs.get_or_reactivate_npc_by_id(first_partner_id) if first_partner_id > 0 else null
	if first_partner != null and first_partner.children.has(target_id):
		return true

	return false


static func _relationship_profile_income_floor_for(target: Person, effective_job: String, effective_social_class: String) -> int:
	if target == null:
		return 0

	if int(target.age) < 16:
		return 0

	var lower_job: String = str(effective_job).strip_edges().to_lower()
	var base_income: float = 32000.0

	if lower_job == "student":
		base_income = 0.0
	elif lower_job.find("part-time") >= 0:
		base_income = 14500.0
	elif lower_job.find("teacher") >= 0:
		base_income = 52000.0
	elif lower_job.find("nurse") >= 0:
		base_income = 76000.0
	elif lower_job.find("soldier") >= 0:
		base_income = 42000.0
	elif lower_job.find("cashier") >= 0:
		base_income = 28500.0
	elif lower_job.find("mechanic") >= 0:
		base_income = 47000.0
	elif lower_job.find("chef") >= 0:
		base_income = 44000.0
	elif lower_job.find("security") >= 0:
		base_income = 34000.0
	elif lower_job.find("streamer") >= 0:
		base_income = 41000.0
	elif lower_job.find("office") >= 0:
		base_income = 43000.0
	elif lower_job.find("artist") >= 0:
		base_income = 39000.0
	elif lower_job.find("delivery") >= 0:
		base_income = 36000.0
	elif lower_job.find("engineer") >= 0 or lower_job.find("software") >= 0:
		base_income = 92000.0
	elif lower_job.find("trainer") >= 0:
		base_income = 48000.0
	elif lower_job.find("entrepreneur") >= 0:
		base_income = 68000.0
	elif lower_job.find("manager") >= 0:
		base_income = 56000.0
	elif lower_job.find("construction") >= 0:
		base_income = 49000.0
	elif lower_job.find("accountant") >= 0:
		base_income = 64000.0
	elif RelationshipsSceneSupport._relationship_profile_job_looks_royal(lower_job):
		base_income = 125000.0

	var class_text: String = str(effective_social_class).strip_edges().to_lower()
	if class_text.find("royal") >= 0 or class_text.find("noble") >= 0 or class_text.find("elite") >= 0:
		base_income *= 1.85
	elif class_text.find("upper") >= 0:
		base_income *= 1.55
	elif class_text.find("middle") >= 0:
		base_income *= 1.12
	elif class_text.find("poor") >= 0 or class_text.find("lower") >= 0:
		base_income *= 0.72

	var seed_value: int = abs(int(hash("%d|%s|income_projection" % [int(target.id), effective_job])))
	var variance: float = 0.88 + (float(seed_value % 31) / 100.0)

	return int(round(base_income * variance))


static func _relationship_profile_effective_income(target: Person, effective_job: String, effective_social_class: String) -> int:
	if target == null:
		return 0

	var actual_income: int = int(round(float(target.income)))
	if actual_income > 0:
		return actual_income

	var seeded_income: int = RelationshipsSceneSupport._relationship_profile_income_floor_for(target, effective_job, effective_social_class)
	if seeded_income > 0:
		target.income = seeded_income
		if float(target.bank_balance) <= 0.0:
			target.bank_balance = int(round(float(seeded_income) * 0.22))

	return seeded_income


static func _relationship_profile_display_home(gs: GameState,
	target: Person) -> Dictionary:
	var out: Dictionary = {
		"city": "",
		"country": ""
	}

	if target == null:
		return out

	var city: String = str(target.home_city).strip_edges()
	var country: String = str(target.home_country).strip_edges()

	if RelationshipsSceneSupport._relationship_profile_target_should_share_player_home(gs, target):
		var player_home: Dictionary = RelationshipsSceneSupport._relationship_profile_world_anchor_home(gs)
		var player_city: String = str(player_home.get("city", "")).strip_edges()
		var player_country: String = str(player_home.get("country", "")).strip_edges()
		if not RelationshipsSceneSupport._relationship_profile_home_is_placeholder(player_city, player_country):
			city = player_city
			country = player_country

	if not RelationshipsSceneSupport._relationship_profile_home_is_placeholder(city, country):
		out ["city"] = city
		out ["country"] = country
		return out

	var anchor_home: Dictionary = RelationshipsSceneSupport._relationship_profile_world_anchor_home(gs)
	var anchor_city: String = str(anchor_home.get("city", "")).strip_edges()
	var anchor_country: String = str(anchor_home.get("country", "")).strip_edges()

	if not RelationshipsSceneSupport._relationship_profile_home_is_placeholder(anchor_city, anchor_country):
		city = anchor_city
		country = anchor_country

	if RelationshipsSceneSupport._relationship_profile_home_is_placeholder(city, country) and gs != null and gs.era_engine != null and gs.era_engine.has_method("get_birth_locations"):
		var locations: Array = gs.era_engine.get_birth_locations()
		for raw_place in locations:
			if typeof(raw_place) != TYPE_DICTIONARY:
				continue
			var place: Dictionary = raw_place as Dictionary
			var place_city: String = str(place.get("city", "")).strip_edges()
			var place_country: String = str(place.get("country", "")).strip_edges()
			if not RelationshipsSceneSupport._relationship_profile_home_is_placeholder(place_city, place_country):
				city = place_city
				country = place_country
				break

	if RelationshipsSceneSupport._relationship_profile_home_is_placeholder(city, country):
		city = "Chicago"
		country = "United States"

	target.home_city = city
	target.home_country = country

	if str(target.birth_city).strip_edges() == "" or RelationshipsSceneSupport._relationship_profile_home_is_placeholder(str(target.birth_city), str(target.birth_country)):
		target.birth_city = city
	if str(target.birth_country).strip_edges() == "" or RelationshipsSceneSupport._relationship_profile_home_is_placeholder(str(target.birth_city), str(target.birth_country)):
		target.birth_country = country

	out ["city"] = city
	out ["country"] = country
	return out


static func _relationship_profile_world_anchor_home(gs: GameState) -> Dictionary:
	var candidates: Array = []

	if gs != null and typeof(gs.custom_settings) == TYPE_DICTIONARY:
		candidates.append({
			"city": str(gs.custom_settings.get("city", gs.custom_settings.get("birth_city", gs.custom_settings.get("home_city", "")))),
			"country": str(gs.custom_settings.get("country", gs.custom_settings.get("birth_country", gs.custom_settings.get("home_country", ""))))
		})

	if gs != null and gs.player != null:
		candidates.append({
			"city": str(gs.player.home_city),
			"country": str(gs.player.home_country)
		})
		candidates.append({
			"city": str(gs.player.birth_city),
			"country": str(gs.player.birth_country)
		})

	if gs != null and gs.era_engine != null and gs.era_engine.has_method("get_birth_locations"):
		for raw_place in gs.era_engine.get_birth_locations():
			if typeof(raw_place) != TYPE_DICTIONARY:
				continue
			var place: Dictionary = raw_place as Dictionary
			candidates.append({
				"city": str(place.get("city", "")),
				"country": str(place.get("country", ""))
			})

	for raw_candidate in candidates:
		if typeof(raw_candidate) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = raw_candidate as Dictionary
		var city: String = str(candidate.get("city", "")).strip_edges()
		var country: String = str(candidate.get("country", "")).strip_edges()
		if not RelationshipsSceneSupport._relationship_profile_home_is_placeholder(city, country):
			return {
				"city": city,
				"country": country
			}

	return {
		"city": "Chicago",
		"country": "United States"
	}


static func _relationship_profile_target_should_share_player_home(gs: GameState,
	target: Person) -> bool:
	if gs == null or gs.player == null or target == null:
		return false
	if int(target.id) == int(gs.player.id):
		return true

	var target_id: int = int(target.id)
	var player: Person = gs.player

	if int(player.age) < 18 and target_id in player.parents:
		return true
	if int(target.age) < 18 and target_id in player.children:
		return true
	if player.partner != null and int(player.partner.id) == target_id:
		return true

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var member_index: Dictionary = gs.scenario_state.get("custom_household_member_index", {})
		if typeof(member_index) == TYPE_DICTIONARY:
			var player_found: bool = false
			var target_found: bool = false
			for raw_key in member_index.keys():
				var member_id: int = int(member_index.get(raw_key, -1))
				if member_id == int(player.id):
					player_found = true
				if member_id == target_id:
					target_found = true
			if player_found and target_found:
				return true

	return false


static func _relationship_profile_body_contract_from_sources(target: Person, body_truth: Dictionary, direct_key: String, body_key: String, summary_key: String) -> Dictionary:
	var out: Dictionary = {}
	var display_key: String = "display_name" if direct_key == "body_type_contract" else "display"

	var raw_direct: Variant = body_truth.get(direct_key, {})
	if typeof(raw_direct) == TYPE_DICTIONARY:
		out = (raw_direct as Dictionary).duplicate(true)

	if out.is_empty() and target != null:
		var raw_target_direct: Variant = target.get(direct_key)
		if typeof(raw_target_direct) == TYPE_DICTIONARY:
			out = (raw_target_direct as Dictionary).duplicate(true)

	if out.is_empty():
		var raw_body: Variant = body_truth.get("body_contract", {})
		if typeof(raw_body) == TYPE_DICTIONARY:
			var body_contract: Dictionary = raw_body as Dictionary
			var raw_nested: Variant = body_contract.get(body_key, {})
			if typeof(raw_nested) == TYPE_DICTIONARY:
				out = (raw_nested as Dictionary).duplicate(true)

			if out.is_empty():
				var summary: Dictionary = ValueSceneSupport._safe_dictionary(body_contract.get("summary", {}))
				var summary_display: String = str(summary.get(summary_key, "")).strip_edges()
				if summary_display != "":
					out [display_key] = summary_display

	if out.is_empty() and target != null and typeof(target.body_contract) == TYPE_DICTIONARY:
		var target_body_contract: Dictionary = target.body_contract
		var raw_target_nested: Variant = target_body_contract.get(body_key, {})
		if typeof(raw_target_nested) == TYPE_DICTIONARY:
			out = (raw_target_nested as Dictionary).duplicate(true)

		if out.is_empty():
			var target_summary: Dictionary = ValueSceneSupport._safe_dictionary(target_body_contract.get("summary", {}))
			var target_summary_display: String = str(target_summary.get(summary_key, "")).strip_edges()
			if target_summary_display != "":
				out [display_key] = target_summary_display

	return out


static func _relationship_profile_local_display_height_inches(target: Person) -> float:
	if target == null:
		return 67.0

	var age_value: int = max(0, int(target.age))
	var gender_text: String = str(target.gender).strip_edges().to_lower()
	var base_adult_height: float = 69.0

	if gender_text in ["female", "woman", "girl", "f"]:
		base_adult_height = 64.0

	var identity_offset: float = float((abs(int(target.id)) % 9) - 4) * 0.65
	var adult_height: float = clamp(base_adult_height + identity_offset, 48.0, 86.0)
	var growth_factor: float = RelationshipsSceneSupport._relationship_profile_local_height_growth_factor_for_age(age_value)

	return clamp(adult_height * growth_factor, 16.0, 90.0)


static func _relationship_profile_local_display_weight_lbs(target: Person, height_in: float, body_type: String) -> float:
	if target == null:
		return 150.0

	var age_value: int = max(0, int(target.age))
	var height_m: float = max(0.3, height_in * 0.0254)
	var adult_weight: float = 22.0 * height_m * height_m * 2.20462
	var growth_factor: float = RelationshipsSceneSupport._relationship_profile_local_height_growth_factor_for_age(age_value)
	var weight_growth_factor: float = clamp(growth_factor * growth_factor, 0.1, 1.06)
	var frame_multiplier: float = 1.0

	match str(body_type).strip_edges().to_lower():
		"ectomorph":
			frame_multiplier = 0.92
		"endomorph":
			frame_multiplier = 1.1
		_:
			frame_multiplier = 1.02

	var identity_offset: float = float((abs(int(target.id)) % 11) - 5) * 1.2
	return clamp((adult_weight * weight_growth_factor * frame_multiplier) + identity_offset, 5.0, 850.0)


static func _relationship_profile_page_cache_key(gs: GameState,

	target: Person
) -> String:
	if target == null:
		return ""

	var viewer_id: int = -1

	if gs != null and gs.player != null:
		viewer_id = int(gs.player.id)

	return "%d:%d" % [
		viewer_id,
		int(target.id)
	]


static func _relationship_profile_page_signature(gs: GameState,

	target: Person
) -> String:
	if target == null:
		return ""

	var viewer_id: int = -1
	var viewer_age: int = -1
	var viewer_bending_type: String = "none"
	var current_year: int = 0

	if gs != null:
		current_year = int(gs.year)

		if gs.player != null:
			viewer_id = int(gs.player.id)
			viewer_age = int(gs.player.age)
			viewer_bending_type = str(
				gs.player.bending_type
			)

	var signature_source: String = (
		"%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s|%s"
		% [
			viewer_id,
			int(target.id),
			current_year,
			viewer_age,
			int(target.age),
			int(round(float(target.health))),
			int(round(float(target.mental_health))),
			int(round(float(target.smarts))),
			int(round(float(target.looks))),
			int(target.bank_balance),
			RelationshipsSceneSupport._relationship_profile_popup_fast_bond_score(gs,
				target
			),
			str(target.alive),
			viewer_bending_type,
			str(target.bending_type)
		]
	)

	return str(
		signature_source.hash()
	)


static func _relationship_profile_zero_frame_shell_store(gs: GameState) -> Dictionary:
	if gs == null:
		return {}

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	var store_raw: Variant = gs.scenario_state.get("relationship_profile_zero_frame_life_shell_by_actor", {})
	var store: Dictionary = store_raw if typeof(store_raw) == TYPE_DICTIONARY else {}

	gs.scenario_state ["relationship_profile_zero_frame_life_shell_by_actor"] = store
	return store


static func _relationship_profile_popup_fast_bond_score(gs: GameState,
	target: Person) -> int:
	if gs == null or gs.player == null or target == null:
		return 0

	if typeof(gs.player.affection) == TYPE_DICTIONARY:
		return clamp(int(gs.player.affection.get(target.id, 0)), 0, 100)

	return 0


static func _relationship_profile_narrative_memory_lines(gs: GameState,
	target: Person) -> Array:
	var lines: Array = []
	if gs == null or gs.player == null or target == null:
		return lines
	if gs.narrative_engine == null:
		return lines

	var personal_rows: Array = []
	if gs.narrative_engine.has_method("get_relationship_memory_summary"):
		personal_rows = gs.narrative_engine.get_relationship_memory_summary(gs.player, target, 4)

	var conflict_rows: Array = []
	if gs.narrative_engine.has_method("build_conflicting_narrative_rows"):
		conflict_rows = gs.narrative_engine.build_conflicting_narrative_rows(gs.player, target, 4)

	if personal_rows.is_empty() and conflict_rows.is_empty():
		return lines

	lines.append("")
	lines.append("Shared Memory")

	for raw_memory in personal_rows:
		if typeof(raw_memory) != TYPE_DICTIONARY:
			continue
		var memory: Dictionary = raw_memory
		var tone: String = str(memory.get("tone", "neutral")).capitalize()
		var text: String = str(memory.get("text", "")).strip_edges()
		if text == "":
			continue
		lines.append("• %s: %s" % [tone, text])

	if not conflict_rows.is_empty():
		lines.append("")
		lines.append("Conflicting Narratives")

	for raw_conflict in conflict_rows:
		if typeof(raw_conflict) != TYPE_DICTIONARY:
			continue
		var conflict: Dictionary = raw_conflict
		var player_text: String = ""
		var target_text: String = ""

		if int(conflict.get("person_a_id", -1)) == int(gs.player.id):
			player_text = str(conflict.get("person_a_text", "")).strip_edges()
			target_text = str(conflict.get("person_b_text", "")).strip_edges()
		else:
			player_text = str(conflict.get("person_b_text", "")).strip_edges()
			target_text = str(conflict.get("person_a_text", "")).strip_edges()

		if player_text != "":
			lines.append("• You remember: %s" % player_text)
		if target_text != "":
			lines.append("• They remember: %s" % target_text)

	return lines


static func _ensure_live_person_editor_engine(gs: GameState) -> void:
	if gs == null:
		return

	if gs.live_person_editor_engine == null:
		gs.live_person_editor_engine = LivePersonEditorEngine.new(gs)


static func _relationship_profile_fling_label(gs: GameState,
	target: Person) -> String:
	if target == null or gs == null:
		return ""

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var foreign_ids: Array = gs.scenario_state.get("foreign_romance_fling_ids", []) if typeof(gs.scenario_state.get("foreign_romance_fling_ids", [])) == TYPE_ARRAY else []
		if int(target.id) in foreign_ids:
			return "Writing Fling"

		var restaurant_ids: Array = gs.scenario_state.get("restaurant_fling_ids", []) if typeof(gs.scenario_state.get("restaurant_fling_ids", [])) == TYPE_ARRAY else []
		if int(target.id) in restaurant_ids:
			return "Fling"

	return ""


static func _relationship_profile_people_share_any_parent(a: Person, b: Person) -> bool:
	if a == null or b == null:
		return false

	var a_parent_ids: Array = RelationshipsSceneSupport._relationship_safe_person_id_array(a, "parents")
	var b_parent_ids: Array = RelationshipsSceneSupport._relationship_safe_person_id_array(b, "parents")
	return RelationshipsSceneSupport._relationship_people_share_any_parent_id(a_parent_ids, b_parent_ids)


static func _is_family_like_target(gs: GameState,
	target: Person) -> bool:
	if target == null or gs.player == null:
		return false

	var p:= gs.player

	if target.id in p.parents:
		return true
	if target.id in p.children:
		return true
	if p.partner != null and p.partner.id == target.id:
		return true
	if target.id in p.ex_partners:
		return true

	for gid in RelationshipsSceneSupport._collect_ancestor_generation_ids(gs, p, 2):
		if int(gid) == target.id:
			return true

	for ggid in RelationshipsSceneSupport._collect_ancestor_generation_ids(gs, p, 3):
		if int(ggid) == target.id:
			return true

	if p.parents.size() > 0 and target.parents == p.parents and target.id != p.id:
		return true

	return false


static func _is_classmate_target(gs: GameState,
	target: Person) -> bool:
	if target == null or gs == null or gs.player == null or gs.school_engine == null:
		return false

	var p:= gs.player
	gs.school_engine.sync_person_school_fields(p)

	for c in gs.school_engine.get_classmates(p):
		if c != null and c.id == target.id:
			return true

	return false


static func _unfriend_target(gs: GameState,
	target: Person) -> Dictionary:
	if target == null or gs.player == null:
		return { "success": false, "text": "Nobody is selected."}

	gs.player.friends.erase(target.id)
	target.friends.erase(gs.player.id)

	return {
		"success": true,
		"text": "I unfriended %s %s." % [target.first_name, target.last_name]
	}


static func _relationship_profile_target_is_foreign_writing_fling(gs: GameState,
	target: Person) -> bool:
	if target == null or gs == null or gs.player == null:
		return false

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return false

	var foreign_ids: Array = gs.scenario_state.get("foreign_romance_fling_ids", []) if typeof(gs.scenario_state.get("foreign_romance_fling_ids", [])) == TYPE_ARRAY else []
	if not int(target.id) in foreign_ids:
		return false

	return RelationshipsSceneSupport._relationship_profile_target_is_in_different_country(gs, target)


static func _relationship_profile_target_is_in_different_country(gs: GameState,
	target: Person) -> bool:
	if target == null or gs == null or gs.player == null:
		return false

	var player_country: String = str(gs.player.home_country).strip_edges()
	if player_country == "":
		player_country = str(gs.player.birth_country).strip_edges()

	var target_country: String = str(target.home_country).strip_edges()
	if target_country == "":
		target_country = str(target.birth_country).strip_edges()

	if player_country == "" or target_country == "":
		return false

	return player_country.to_lower() != target_country.to_lower()


static func _is_coworker_target(gs: GameState,
	target: Person) -> bool:
	if target == null or gs == null or gs.player == null or gs.workplace_engine == null:
		return false
	for coworker in gs.workplace_engine.get_coworkers(gs.player):
		if coworker != null and int(coworker.id) == int(target.id):
			return true
	return false


static func _resolve_coworker_profile_action(gs: GameState,
	target: Person, action_id: String) -> Dictionary:
	if target == null or gs == null or gs.player == null:
		return { "success": false, "text": "No coworker is selected."}
	var player:= gs.player
	var relation_score: int = 50
	if gs.relationship_engine != null:
		relation_score = int(gs.relationship_engine.update_relationship(player, target))
	match action_id:
		"coworker_talk_shop":
			if gs.relationship_engine != null:
				gs.relationship_engine.adjust_relationship(player, target, 4)
			player.job_performance = clamp(int(player.job_performance) + 2, 0, 100)
			player.satisfaction = clamp(int(player.satisfaction) + 1, 0, 100)
			return {
				"success": true,
				"text": "You talked shop with %s %s. Work felt a little smoother." % [target.first_name, target.last_name]
			}
		"coworker_network":
			if gs.relationship_engine != null:
				gs.relationship_engine.adjust_relationship(player, target, 3)
			player.satisfaction = clamp(int(player.satisfaction) + 2, 0, 100)
			player.job_performance = clamp(int(player.job_performance) + 1, 0, 100)
			return {
				"success": true,
				"text": "You strengthened your workplace connection with %s %s." % [target.first_name, target.last_name]
			}
		"coworker_ask_referral":
			var success_chance: int = clamp(relation_score + int(player.job_performance / 2.0), 20, 95)
			var success: bool = (randi() % 100) < success_chance
			if success:
				if gs.relationship_engine != null:
					gs.relationship_engine.adjust_relationship(player, target, 5)
				player.job_performance = clamp(int(player.job_performance) + 4, 0, 100)
				player.satisfaction = clamp(int(player.satisfaction) + 3, 0, 100)
				return {
					"success": true,
					"text": "%s %s agreed to put in a good word for you." % [target.first_name, target.last_name]
				}
			if gs.relationship_engine != null:
				gs.relationship_engine.adjust_relationship(player, target, -2)
			player.work_stress = clamp(int(player.work_stress) + 2, 0, 100)
			return {
				"success": false,
				"text": "%s %s was not ready to refer you yet." % [target.first_name, target.last_name]
			}
		"coworker_set_boundary":
			player.work_stress = clamp(int(player.work_stress) - 8, 0, 100)
			player.mental_health = clamp(int(player.mental_health) + 3, 0, 100)
			if relation_score >= 55:
				if gs.relationship_engine != null:
					gs.relationship_engine.adjust_relationship(player, target, 1)
				return {
					"success": true,
					"text": "You set a clear boundary with %s %s, and they respected it." % [target.first_name, target.last_name]
				}
			if gs.relationship_engine != null:
				gs.relationship_engine.adjust_relationship(player, target, -1)
			return {
				"success": true,
				"text": "You set a clear boundary with %s %s. It was a little awkward, but clearer now." % [target.first_name, target.last_name]
			}
	return { "success": false, "text": "Unknown coworker action."}


static func _relationship_popup_default_element_for_player(gs: GameState) -> String:
	var p: Person = gs.player
	if p == null:
		return "fire"

	if str(p.bending_type) != "" and str(p.bending_type) != "none" and str(p.bending_type) != "avatar":
		return str(p.bending_type)

	var best_element:= "fire"
	var best_mastery:= -1

	for element in ["air", "water", "earth", "fire"]:
		var mastery:= int(p.bending_mastery.get(element, 0))
		if mastery > best_mastery:
			best_mastery = mastery
			best_element = element

	return best_element


static func _relationship_hub_add_climate_relationship_id(gs: GameState,
	ids: Array, seen: Dictionary, npc_id: int) -> void:
	var clean_id: int = int(npc_id)
	if clean_id <= 0:
		return
	if gs != null and gs.player != null and clean_id == int(gs.player.id):
		return
	if seen.has(clean_id):
		return

	seen [clean_id] = true
	ids.append(clean_id)


static func _collect_dead_institution_relationship_ids(gs: GameState,
	ids: Array) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	if gs == null:
		return out
	for raw_id in ids:
		var pid: int = int(raw_id)
		if pid <= 0:
			continue
		if seen.has(pid):
			continue
		var rel_person: Person = gs.get_or_reactivate_npc_by_id(pid)
		if rel_person != null:
			if not rel_person.alive:
				seen [pid] = true
				out.append(pid)
		elif gs.npc_graveyard.has(pid):
			seen [pid] = true
			out.append(pid)
	return out


static func _relationship_hub_resolve_section_id(gs: GameState,
	raw_section: String = "") -> String:
	var clean_section: String = str(raw_section).strip_edges().to_lower()

	if clean_section == "" or clean_section == "overview":
		clean_section = "family"

	if InstitutionsSceneSupport._institution_hub_section_is_allowed(gs, "relationships", clean_section):
		return clean_section

	return "family"


static func _relationship_hub_person_card_style(state: String, featured: bool, section_key: String = "", bond_value: int = 50, hovered: bool = false, pulse_strength: float = 0.0) -> StyleBoxFlat:
	var palette: Dictionary = RelationshipsSceneSupport._relationship_hub_section_palette(section_key)
	var section_accent: Color = palette.get("accent", Color(1.0, 0.48, 0.72, 0.9))
	var safe_bond: int = clamp(int(bond_value), 0, 100)
	var bond_ratio: float = clamp(float(safe_bond) / 100.0, 0.0, 1.0)
	var high_bond_pulse: float = clamp((bond_ratio - 0.7) / 0.3, 0.0, 1.0) * clamp(pulse_strength, 0.0, 1.0)

	var bg_color: Color = Color(0.09, 0.035, 0.07, 0.97)
	var border_color: Color = section_accent
	var bond_glow_color: Color = Color(section_accent.r, section_accent.g, section_accent.b, lerp(0.1, 0.42, bond_ratio))

	match str(state).strip_edges().to_lower():
		"warm":
			bg_color = Color(0.125, 0.05, 0.095, 0.97).lerp(Color(0.155, 0.06, 0.115, 0.98), bond_ratio * 0.42)
			border_color = section_accent.lerp(Color(1.0, 0.82, 0.9, 1.0), 0.3 + (bond_ratio * 0.42))
			bond_glow_color = Color(border_color.r, border_color.g, border_color.b, lerp(0.14, 0.48, bond_ratio))
		"strained":
			bg_color = Color(0.06, 0.072, 0.108, 0.97).lerp(Color(0.075, 0.085, 0.125, 0.98), bond_ratio * 0.2)
			border_color = Color(0.64, 0.74, 0.92, 0.88).lerp(section_accent, bond_ratio * 0.22)
			bond_glow_color = Color(0.24, 0.34, 0.56, lerp(0.14, 0.3, bond_ratio))
		"conflict":
			bg_color = Color(0.13, 0.042, 0.07, 0.97)
			border_color = Color(1.0, 0.42, 0.56, 0.96)
			bond_glow_color = Color(0.52, 0.08, 0.16, lerp(0.18, 0.32, bond_ratio))

	if hovered:
		border_color = border_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.38)
		bond_glow_color = bond_glow_color.lerp(Color(1.0, 1.0, 1.0, 0.72), 0.34)

	var style:= StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2 if featured else 1
	style.border_width_top = 2 if featured else 1
	style.border_width_right = 2 if featured else 1
	style.border_width_bottom = 2 if featured else 1
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = bond_glow_color
	style.shadow_size = int(round(lerp(8.0, 26.0, bond_ratio))) + (8 if hovered else 0) + int(round(high_bond_pulse * 5.0))
	style.shadow_offset = Vector2(0, 5 if featured else 4)
	return style


static func _collect_player_fling_ids(gs: GameState,
	_person: Person) -> Array:
	var out: Array = []
	var seen: Dictionary = {}

	if gs == null:
		return out

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		var restaurant_ids: Array = gs.scenario_state.get("restaurant_fling_ids", []) if typeof(gs.scenario_state.get("restaurant_fling_ids", [])) == TYPE_ARRAY else []
		for raw_restaurant_id in restaurant_ids:
			RelationshipsSceneSupport._add_unique_institution_relationship_id(out, seen, int(raw_restaurant_id))

		var foreign_ids: Array = gs.scenario_state.get("foreign_romance_fling_ids", []) if typeof(gs.scenario_state.get("foreign_romance_fling_ids", [])) == TYPE_ARRAY else []
		for raw_foreign_id in foreign_ids:
			RelationshipsSceneSupport._add_unique_institution_relationship_id(out, seen, int(raw_foreign_id))

	return out


static func _collect_alive_institution_relationship_ids(gs: GameState,
	ids: Array) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	if gs == null:
		return out
	for raw_id in ids:
		var pid: int = int(raw_id)
		if pid <= 0:
			continue
		if seen.has(pid):
			continue
		var rel_person: Person = gs.get_or_reactivate_npc_by_id(pid)
		if rel_person == null:
			continue
		if not rel_person.alive:
			continue
		seen [pid] = true
		out.append(pid)
	return out


static func _resolve_player_custodial_parent(gs: GameState,
	person: Person) -> Person:
	if person == null or gs == null:
		return null
	for raw_parent_id in person.parents:
		var parent: Person = gs.get_or_reactivate_npc_by_id(int(raw_parent_id))
		if parent != null and parent.alive:
			return parent
	return null


static func _resolve_player_household_anchor(gs: GameState,
	person: Person) -> Person:
	if person == null or gs == null:
		return null

	var household_state_raw: Variant = gs.scenario_state.get("household_state", {}) if typeof(gs.scenario_state) == TYPE_DICTIONARY else {}
	var household_state: Dictionary = household_state_raw if typeof(household_state_raw) == TYPE_DICTIONARY else {}
	var forced_self_anchor_id: int = int(household_state.get("forced_self_anchor_player_id", -1))
	if forced_self_anchor_id == int(person.id):
		return person

	if int(person.age) < 18:
		var custodial_parent: Person = RelationshipsSceneSupport._resolve_player_custodial_parent(gs, person)
		if custodial_parent != null:
			return custodial_parent

	return person
