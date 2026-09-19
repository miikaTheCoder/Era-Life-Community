extends RefCounted
class_name FoodSceneSupport
## Food support for the main scene. State, when needed, is passed explicitly.


static func _grocery_item_contract_visual_profile(row_dict: Dictionary = {}) -> Dictionary:
	var row_kind: String = str(row_dict.get("kind", "")).strip_edges().to_lower()
	if row_kind != "grocery_item":
		return {}

	var store_id: String = str(row_dict.get("store_id", "")).strip_edges()
	var food_id: String = str(row_dict.get("food_id", "")).strip_edges().to_lower()
	var label_text: String = str(row_dict.get("label", "")).strip_edges().to_lower()
	var quality: String = str(row_dict.get("quality", row_dict.get("quality_tier", ""))).strip_edges().to_lower()

	var visual: Dictionary = {
		"bg": Color(0.115, 0.064, 0.07, 0.97),
		"border": Color(0.98, 0.58, 0.48, 0.76),
		"font": Color(1.0, 0.93, 0.9, 1.0),
		"description_font": Color(1.0, 0.84, 0.82, 0.94),
		"border_width": 2,
		"radius": 16,
		"title_size": 16
	}

	if quality.find("legendary") >= 0:
		visual ["bg"] = Color(0.138, 0.086, 0.05, 0.98)
		visual ["border"] = Color(1.0, 0.86, 0.34, 0.92)
		visual ["font"] = Color(1.0, 0.96, 0.8, 1.0)
		visual ["description_font"] = Color(0.98, 0.88, 0.66, 0.96)
		visual ["border_width"] = 3
		visual ["pulse_glow"] = true
		visual ["pulse_tint"] = Color(1.0, 0.9, 0.56, 1.0)
		visual ["pulse_seconds"] = 0.82
	elif quality.find("elite") >= 0 or quality.find("premium") >= 0 or quality.find("organic") >= 0 or quality.find("high_quality") >= 0:
		visual ["bg"] = Color(0.084, 0.094, 0.074, 0.97)
		visual ["border"] = Color(0.66, 0.96, 0.76, 0.88)
		visual ["font"] = Color(0.92, 1.0, 0.94, 1.0)
		visual ["description_font"] = Color(0.78, 0.96, 0.86, 0.95)
		visual ["border_width"] = 3
		visual ["pulse_glow"] = true
		visual ["pulse_tint"] = Color(0.74, 1.0, 0.84, 1.0)
		visual ["pulse_seconds"] = 0.86
	elif quality.find("cheap") >= 0 or quality.find("budget") >= 0 or quality.find("working_class") >= 0:
		visual ["bg"] = Color(0.084, 0.058, 0.056, 0.96)
		visual ["border"] = Color(0.72, 0.56, 0.54, 0.72)
		visual ["font"] = Color(0.94, 0.88, 0.86, 1.0)
		visual ["description_font"] = Color(0.86, 0.76, 0.74, 0.92)
	elif quality.find("sugary") >= 0 or quality.find("sweet") >= 0 or quality.find("chocolate") >= 0 or quality.find("fun_") >= 0:
		visual ["bg"] = Color(0.126, 0.058, 0.078, 0.97)
		visual ["border"] = Color(1.0, 0.52, 0.7, 0.82)
		visual ["font"] = Color(1.0, 0.9, 0.94, 1.0)
		visual ["description_font"] = Color(1.0, 0.82, 0.88, 0.94)
	else:
		visual ["bg"] = Color(0.11, 0.062, 0.068, 0.97)
		visual ["border"] = Color(1.0, 0.56, 0.48, 0.78)
		visual ["font"] = Color(1.0, 0.92, 0.9, 1.0)
		visual ["description_font"] = Color(1.0, 0.82, 0.8, 0.94)

	if store_id == "goldleaf_grocers" or food_id.begins_with("goldleaf_"):
		visual ["bg"] = Color(0.118, 0.082, 0.04, 0.98)
		visual ["border"] = Color(1.0, 0.84, 0.36, 0.94)
		visual ["font"] = Color(1.0, 0.96, 0.82, 1.0)
		visual ["description_font"] = Color(0.98, 0.88, 0.66, 0.96)
		visual ["border_width"] = 3
		visual ["pulse_glow"] = true
		visual ["pulse_tint"] = Color(1.0, 0.92, 0.54, 1.0)
		visual ["pulse_seconds"] = 0.74

	if food_id == "acrellos_cereal" or label_text.find("acrello") >= 0:
		visual ["orbit_color"] = Color(0.68, 0.34, 1.0, 1.0)
		visual ["orbit_seconds"] = 2.1
		visual ["border_width"] = max(int(visual.get("border_width", 2)), 3)

	if food_id.find("fatcakes") >= 0 or label_text.find("fatcakes") >= 0:
		visual ["orbit_color"] = Color(1.0, 0.42, 0.74, 1.0)
		visual ["orbit_seconds"] = 1.9
		visual ["border_width"] = max(int(visual.get("border_width", 2)), 3)

	return visual


static func _grocery_aisle_carousel_direction_from_route(action: Dictionary, report: Dictionary) -> int:
	var report_direction: int = int(report.get("aisle_slide_direction", 0))
	if report_direction < 0:
		return -1
	if report_direction > 0:
		return 1

	var action_style: String = str(action.get("style", "")).strip_edges().to_lower()
	if action_style == "secondary":
		return -1
	if action_style == "primary":
		return 1

	return 1


static func _should_use_grocery_aisle_carousel_transition(surface_id: String, action_id: String, report: Dictionary) -> bool:
	if str(surface_id).strip_edges() != "food_contract_hub":
		return false

	if not str(action_id).strip_edges().begins_with("grocery_aisle:"):
		return false

	if str(report.get("target_section", report.get("active_section_id", ""))).strip_edges() != "aisles":
		return false

	return true


static func _grocery_aisle_display_name_for_popup(aisle_id: String) -> String:
	var clean_aisle_id: String = str(aisle_id).strip_edges()
	if clean_aisle_id == "":
		return "Aisle"
	return clean_aisle_id.replace("_", " ").capitalize()


static func _grocery_clear_popup_grid(grid: Control) -> void:
	if grid == null or not is_instance_valid(grid):
		return

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()


static func _food_lifestyle_actor_is_old_enough(actor: Person) -> bool:
	return actor != null and int(actor.age) >= 15


static func _food_lifestyle_normalized_era_key_for_mainscene(era_name: String) -> String:
	var clean: String = str(era_name).strip_edges().to_lower()
	clean = clean.replace(" era", "")
	clean = clean.replace(" ", "_")
	return clean


static func _food_lifestyle_era_key_from_year_for_mainscene(year_value: int) -> String:
	if year_value <= 499:
		return "Ancient"
	if year_value <= 1799:
		return "Medieval"
	if year_value <= 1949:
		return "Industrial"
	if year_value <= 2049:
		return "Modern"
	return "Future"


static func _restaurant_lifestyle_empty_surface_state() -> Dictionary:
	return {
		"restaurant_mode": "",
		"restaurant_plan_chosen": false,
		"restaurant_category": "",
		"restaurant_id": "",
		"restaurant_service_mode": "",
		"candidate_id": -1,
		"candidate_name": "",
		"date_partner_id": -1,
		"date_partner_name": "",
		"notice": ""
	}


static func _grocery_store_display_name_for_popup(gs: GameState,
	store_id: String) -> String:
	var clean_store_id: String = str(store_id).strip_edges()

	match clean_store_id:
		"basket_lane_market":
			return "EraMart"
		"goldleaf_grocers":
			return "Goldleaf"
		"nutripod_exchange":
			return "Nutripod Exchange"

	if gs != null and gs.grocery_store_engine != null and gs.grocery_store_engine.has_method("get_store"):
		var store: Dictionary = gs.grocery_store_engine.get_store(clean_store_id)
		var store_name: String = str(store.get("name", "")).strip_edges()
		if store_name != "":
			return store_name.replace("Era-Mart", "EraMart")

	if clean_store_id == "":
		return "Grocery Store"

	return clean_store_id.replace("_", " ").capitalize()


static func _food_lifestyle_active_actor(gs: GameState) -> Person:
	if gs == null:
		return null
	return gs.player


static func _food_lifestyle_era_supports_modern_future_hubs(era_name: String) -> bool:
	var clean_era: String = FoodSceneSupport._food_lifestyle_normalized_era_key_for_mainscene(era_name)
	return clean_era == "modern" or clean_era == "future"


static func _food_lifestyle_era_name_from_year_for_mainscene(year_value: int) -> String:
	match FoodSceneSupport._food_lifestyle_era_key_from_year_for_mainscene(year_value):
		"Ancient":
			return "Ancient Era"
		"Medieval":
			return "Medieval Era"
		"Industrial":
			return "Industrial Era"
		"Modern":
			return "Modern Era"
		"Future":
			return "Future Era"
		_:
			return ""


static func _food_lifestyle_publish_year_era_truth(gs: GameState,
	era_name: String) -> void:
	if gs == null:
		return
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	gs.scenario_state ["year_era_authority"] = "mainscene.year_threshold"
	gs.scenario_state ["year_era_name"] = era_name
	gs.scenario_state ["era_name"] = era_name
	gs.scenario_state ["era"] = FoodSceneSupport._food_lifestyle_normalized_era_key_for_mainscene(era_name).capitalize()
	gs.scenario_state ["year_era_source_year"] = int(gs.year)
	gs.scenario_state ["year_era_synced_at_ms"] = int(Time.get_ticks_msec())


static func _stage_food_lifestyle_hud_truth_for_zero_frame_entry(gs: GameState,

	snapshot: Dictionary,
	reason: String = "god_mode_food_lifestyle_stage"
) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(false)

	if gs == null:
		return out

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	var era_name: String = (
		str(gs.era.name).strip_edges()
		if gs.era != null
		else str(out.get("era_name", ""))
	)
	var grocery_allowed: bool = bool(
		gs.scenario_state.get(
			"grocery_hud_allowed",
			out.get(
				"grocery_hud_allowed",
				false
			)
		)
	)
	var restaurant_allowed: bool = bool(
		gs.scenario_state.get(
			"restaurant_hud_allowed",
			out.get(
				"restaurant_hud_allowed",
				false
			)
		)
	)

	out ["food_lifestyle_hud_allowed"] = (
		grocery_allowed
		or restaurant_allowed
	)
	out ["food_lifestyle_hud_era_name"] = era_name
	out ["food_lifestyle_available"] = grocery_allowed
	out ["restaurant_lifestyle_available"] = restaurant_allowed
	out ["grocery_hud_allowed"] = grocery_allowed
	out ["restaurant_hud_allowed"] = restaurant_allowed
	out ["industrial_food_lifestyle_expansion_slot_reserved"] = true
	out ["food_lifestyle_stage_reason"] = reason
	out ["food_lifestyle_stage_called_engine"] = false
	out ["food_lifestyle_ready_gate_member"] = false

	return out
