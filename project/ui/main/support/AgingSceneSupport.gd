extends RefCounted
class_name AgingSceneSupport
## Aging support for the main scene. State, when needed, is passed explicitly.


static func _build_age_up_loading_prewarm_signature(loading_context: Dictionary) -> String:
	var headline: String = str(loading_context.get("headline", "")).strip_edges()
	var subline: String = str(loading_context.get("subline", "")).strip_edges()
	var dominant_domain: String = str(loading_context.get("dominant_domain", "general")).strip_edges().to_lower()
	if dominant_domain == "":
		dominant_domain = "general"
	var reality_mode: String = str(loading_context.get("reality_mode", "realistic")).strip_edges().to_lower()
	if reality_mode == "":
		reality_mode = "realistic"
	var era_name: String = str(loading_context.get("era_name", "")).strip_edges().to_lower()
	var target_year: int = int(loading_context.get("target_year", 0))
	return "%s|%s|%s|%s|%s|%d" % [
		headline,
		subline,
		dominant_domain,
		reality_mode,
		era_name,
		target_year
	]


static func _build_age_up_loading_text_refresh_signature(loading: Dictionary, overlay_context: Dictionary) -> String:
	var stall_score: float = float(loading.get("stall_score", 0.0))
	return "%s|%s|%s|%s|%s|%s" % [
		str(loading.get("current_phase", "preflight")),
		str(loading.get("completion_state", "running")),
		str(loading.get("session_stage", "boot")),
		str(loading.get("subline", "")),
		str(overlay_context.get("target_year", 0)),
		str(int(floor(stall_score / 10.0)))
	]


static func _resolve_age_up_loading_text_refresh_interval_ms(loading: Dictionary, overlay_context: Dictionary) -> int:
	var current_phase: String = str(loading.get("current_phase", "preflight"))
	var completion_state: String = str(loading.get("completion_state", "running"))
	var session_stage: String = str(loading.get("session_stage", "boot"))
	var stall_score: float = float(loading.get("stall_score", 0.0))
	var interval_ms: int = 96

	if completion_state == "complete" or session_stage == "complete":
		interval_ms = 42
	elif session_stage in ["settling_previous_year", "settling_current_year"]:
		interval_ms = 56
	elif current_phase in ["core_state_resolution", "internal_identity_drift", "year_budget_pipeline_commit", "commit_settling"]:
		interval_ms = 72
	elif stall_score >= 60.0:
		interval_ms = 72
	elif stall_score >= 45.0:
		interval_ms = 84

	if str(overlay_context.get("reality_mode", "")).strip_edges().to_lower() == "chaos":
		interval_ms = min(interval_ms, 84)

	return max(28, interval_ms)


static func _build_age_up_loading_copy_bucket_key(overlay_context: Dictionary, loading: Dictionary) -> String:
	var reality_mode: String = str(overlay_context.get("reality_mode", "realistic")).strip_edges().to_lower()
	if reality_mode == "":
		reality_mode = "realistic"

	var dominant_domain: String = str(loading.get("dominant_domain", overlay_context.get("dominant_domain", "general"))).strip_edges().to_lower()
	if dominant_domain == "":
		dominant_domain = "general"

	return "%s|%s" % [reality_mode, dominant_domain]


static func _build_age_up_loading_did_you_know_static_bucket_key(overlay_context: Dictionary) -> String:
	var reality_mode: String = str(overlay_context.get("reality_mode", "realistic")).strip_edges().to_lower()
	if reality_mode == "":
		reality_mode = "realistic"

	var era_name: String = str(overlay_context.get("era_name", "")).strip_edges().to_lower()

	return "%s|%s" % [reality_mode, era_name]


static func _resolve_age_up_loading_dominant_domain(influences: Dictionary) -> String:
	var best_key: String = "general"
	var best_score: float = -1.0
	for raw_key in influences.keys():
		var key: String = str(raw_key)
		var score: float = float(influences.get(key, 0.0))
		if score > best_score:
			best_score = score
			best_key = key
	return best_key


static func _age_up_loading_phase_display_text(phase_key: String) -> String:
	match phase_key:
		"preflight":
			return "Preparing year runtime"
		"commit_settling":
			return "Settling deferred workloads"
		"core_state_resolution":
			return "Advancing the world"
		"internal_identity_drift":
			return "Simulating people and pressure"
		"year_budget_pipeline_commit":
			return "Resolving distant lives"
		"player_phase_contract":
			return "Locking the player's year"
		"choice_and_opportunity_surfacing":
			return "Surfacing scenarios and opportunities"
		"narrative_and_presentation":
			return "Composing events and world feed"
		"complete":
			return "Year resolved"
		_:
			return "Time is turning..."


static func _sanitize_age_up_loading_did_you_know_row(raw_row: Variant, fallback_index: int) -> Dictionary:
	if typeof(raw_row) != TYPE_DICTIONARY:
		return {}

	var row: Dictionary = raw_row
	if bool(row.get("_normalized", false)):
		var normalized_text: String = str(row.get("text", "")).strip_edges()
		var normalized_key: String = str(row.get("key", "")).strip_edges()
		if normalized_text == "" or normalized_key == "":
			return {}
		return {
			"key": normalized_key,
			"text": normalized_text,
			"_normalized": true
		}

	var text: String = str(row.get("text", "")).strip_edges()
	if text == "":
		return {}
	var key: String = str(row.get("key", "")).strip_edges()
	if key == "":
		key = "did_you_know_%d_%d" % [fallback_index, abs(int(text.hash()))]
	return {
		"key": key,
		"text": text,
		"_normalized": true
	}


static func _build_age_up_loading_eralife_markup_cache_key(visible_text: String, phase_bucket: int) -> String:
	return "%s|%d" % [visible_text.strip_edges(), phase_bucket]


static func _resolve_age_up_loading_theme_key(gs: GameState,
	loading_context: Dictionary = {}, overlay_context: Dictionary = {}) -> String:
	var forced_theme_key: String = str(
		loading_context.get(
			"force_target_theme_key",
			overlay_context.get("force_target_theme_key", "")
		)
	).strip_edges().to_lower()
	if forced_theme_key != "":
		return forced_theme_key
	var explicit_theme_key: String = str(
		loading_context.get(
			"theme_key",
			overlay_context.get("theme_key", "")
		)
	).strip_edges().to_lower()
	if explicit_theme_key != "":
		return explicit_theme_key
	var era_name: String = str(
		overlay_context.get(
			"era_name",
			loading_context.get("era_name", "")
		)
	).strip_edges().to_lower()
	if era_name == "":
		era_name = str(
			loading_context.get(
				"target_era_name",
				overlay_context.get("target_era_name", "")
			)
		).strip_edges().to_lower()
	if era_name == "":
		var target_year: int = int(
			overlay_context.get(
				"target_year",
				loading_context.get("target_year", 0)
			)
		)
		if target_year != 0 and gs != null and gs.era_engine != null and gs.era_engine.has_method("_era_from_year"):
			var resolved_era: Variant = gs.era_engine._era_from_year(target_year)
			if typeof(resolved_era) == TYPE_DICTIONARY:
				era_name = str(resolved_era.get("name", "")).strip_edges().to_lower()
	if era_name != "":
		if "ancient" in era_name:
			return "ancient"
		if "medieval" in era_name:
			return "medieval"
		if "industrial" in era_name:
			return "industrial"
		if "future" in era_name:
			return "future"
	return AppearanceSceneSupport._era_border_theme_key_from_world(gs)


static func _resume_nonvisible_age_up_result(gs: GameState,
	result: Dictionary) -> Dictionary:
	if gs == null or gs.life_engine == null:
		return result
	if str(result.get("type", "")) != "year_pipeline_pending":
		return result
	if gs.life_engine.has_method("continue_nonvisible_age_up_transaction"):
		return gs.life_engine.continue_nonvisible_age_up_transaction()
	return result


static func _build_speculative_year_precompute_signature(gs: GameState) -> String:
	if gs == null or gs.player == null:
		return ""
	var npc_count: int = int(gs.npcs.size())
	var dormant_count: int = int(gs.dormant_npcs.size())
	var world_feed_count: int = int(gs.world_feed.size())
	var player_age: int = int(gs.player.age)
	var player_id: int = int(gs.player.id)
	return "%d|%d|%d|%d|%d|%d|%s" % [
		int(gs.year + 1),
		player_id,
		player_age,
		npc_count,
		dormant_count,
		world_feed_count,
		str(gs.reality_mode)
	]


static func _speculative_population_precompute_lane(gs: GameState,
	next_year: int) -> Dictionary:
	var lane: Dictionary = {
		"ready": true,
		"year": next_year,
		"active_count": int(gs.npcs.size()) if gs != null else 0,
		"dormant_count": int(gs.dormant_npcs.size()) if gs != null else 0,
		"can_apply": false
	}
	if gs == null:
		return lane
	if gs.population_lifecycle_manager != null and gs.population_lifecycle_manager.has_method("speculative_precompute_next_year"):
		lane ["payload"] = gs.population_lifecycle_manager.speculative_precompute_next_year({
			"year": next_year,
			"budget_ms": 1
		})
		lane ["can_apply"] = true
	return lane


static func _speculative_faction_pressure_precompute_lane(gs: GameState,
	next_year: int) -> Dictionary:
	var lane: Dictionary = {
		"ready": true,
		"year": next_year,
		"faction_count": int(gs.universal_faction_state.size()) if gs != null and typeof(gs.universal_faction_state) == TYPE_DICTIONARY else 0,
		"can_apply": false
	}
	if gs == null:
		return lane
	if gs.universal_faction_engine != null and gs.universal_faction_engine.has_method("speculative_precompute_pressure"):
		lane ["payload"] = gs.universal_faction_engine.speculative_precompute_pressure({
			"year": next_year,
			"budget_ms": 1
		})
		lane ["can_apply"] = true
	return lane


static func _speculative_economy_precompute_lane(gs: GameState,
	next_year: int) -> Dictionary:
	var lane: Dictionary = {
		"ready": true,
		"year": next_year,
		"can_apply": false
	}
	if gs == null:
		return lane
	if gs.economy_engine != null and gs.economy_engine.has_method("speculative_precompute_year"):
		lane ["payload"] = gs.economy_engine.speculative_precompute_year({
			"year": next_year,
			"budget_ms": 1
		})
		lane ["can_apply"] = true
	elif gs.global_market_engine != null and gs.global_market_engine.has_method("speculative_precompute_year"):
		lane ["payload"] = gs.global_market_engine.speculative_precompute_year({
			"year": next_year,
			"budget_ms": 1
		})
		lane ["can_apply"] = true
	return lane


static func _get_age_up_loading_recent_did_you_know_keys(gs: GameState) -> Array:
	if gs == null:
		return []

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	var raw_keys: Variant = gs.scenario_state.get("age_up_loading_recent_did_you_know_keys", [])
	var keys: Array = raw_keys if typeof(raw_keys) == TYPE_ARRAY else []
	var cleaned: Array = []

	for raw_key in keys:
		var key: String = str(raw_key).strip_edges()
		if key != "":
			cleaned.append(key)

	return cleaned


static func _store_age_up_loading_recent_did_you_know_keys(gs: GameState,
	keys: Array) -> void:
	if gs == null:
		return

	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}

	gs.scenario_state ["age_up_loading_recent_did_you_know_keys"] = keys.duplicate(true)


static func _build_age_up_loading_live_did_you_know_cache_key(gs: GameState,
	overlay_context: Dictionary) -> String:
	if gs == null or gs.player == null:
		return "no_player"

	var player: Person = gs.player
	var target_year: int = int(overlay_context.get("target_year", gs.year if gs != null else 0))
	var last_name: String = str(player.last_name).strip_edges().to_lower()
	var parent_signature: int = 0
	if typeof(player.parents) == TYPE_ARRAY and not player.parents.is_empty():
		parent_signature = abs(int(str(player.parents).hash()))

	var bias_raw: Variant = gs.transient_scenario_biases.get(int(player.id), {})
	var bias: Dictionary = {}
	if typeof(bias_raw) == TYPE_ARRAY:
		var bias_bucket: Array = bias_raw
		if not bias_bucket.is_empty() and typeof(bias_bucket [0]) == TYPE_DICTIONARY:
			bias = bias_bucket [0]
	elif typeof(bias_raw) == TYPE_DICTIONARY:
		bias = bias_raw

	var faction_pressure_raw: Variant = bias.get("faction_pressure", {})
	var faction_pressure: Dictionary = faction_pressure_raw if typeof(faction_pressure_raw) == TYPE_DICTIONARY else {}

	return "%d|%d|%s|%d|%d|%d|%d|%d|%d|%d|%d" % [
		int(player.id),
		target_year,
		last_name,
		1 if bool(player.is_royal) else 0,
		parent_signature,
		int(round(float(faction_pressure.get("justice_pressure", 0.0)))),
		int(round(float(faction_pressure.get("syndicate_turf_pressure", 0.0)))),
		int(round(float(faction_pressure.get("workplace_pressure", 0.0)))),
		int(round(float(faction_pressure.get("dynasty_pressure", 0.0)))),
		int(round(float(faction_pressure.get("neighborhood_pressure", 0.0)))),
		int(round(float(faction_pressure.get("hidden_realm_instability", 0.0))))
	]
