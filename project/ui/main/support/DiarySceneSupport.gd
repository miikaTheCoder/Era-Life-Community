extends RefCounted
class_name DiarySceneSupport
## Diary support for the main scene. State, when needed, is passed explicitly.


static func _life_diary_year_header_text(
	line: String
) -> String:
	var clean_line: String = str(
		line
	).strip_edges()

	if clean_line.begins_with("Year: "):
		return clean_line.substr(
			6
		).strip_edges()

	return clean_line


static func _world_feed_stone_inline_color(stone_name: String) -> Color:
	match stone_name:
		"Mind Stone":
			return Color(1.0, 0.92, 0.22, 1.0)
		"Space Stone":
			return Color(0.3, 0.58, 1.0, 1.0)
		"Reality Stone":
			return Color(1.0, 0.26, 0.34, 1.0)
		"Power Stone":
			return Color(0.7, 0.4, 1.0, 1.0)
		"Time Stone":
			return Color(0.24, 0.92, 0.46, 1.0)
		"Soul Stone":
			return Color(1.0, 0.58, 0.16, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)


static func _compact_diary_text(text: String) -> String:
	var raw_text: String = str(text).strip_edges()
	if raw_text == "":
		return ""

	var out:= ""
	for raw_line in raw_text.split("\n", false):
		var line: String = str(raw_line).strip_edges()
		if line == "":
			continue
		if out != "":
			out += " "
		out += line

	return out


static func _world_feed_section_label(section_key: String) -> String:
	match section_key:
		"politics":
			return "POLITICS / STATECRAFT"
		"dynasty":
			return "DYNASTY / SUCCESSION"
		"factions":
			return "FACTIONS / POWER BLOCS"
		"conflict":
			return "CONFLICT / WAR"
		"bending":
			return "BENDING / ELEMENTAL SHIFTS"
		"cosmic":
			return "COSMIC / UNNATURAL EVENTS"
		"artifacts":
			return "ARTIFACTS / RELICS"
		"world":
			return "WORLD SHIFTS"
		_:
			return "SOCIETY / SIGNALS"


static func _world_feed_section_color(section_key: String) -> Color:
	match section_key:
		"politics":
			return Color(1.0, 0.84, 0.54, 1.0)
		"dynasty":
			return Color(1.0, 0.74, 0.88, 1.0)
		"factions":
			return Color(0.78, 0.92, 1.0, 1.0)
		"conflict":
			return Color(1.0, 0.66, 0.66, 1.0)
		"bending":
			return Color(0.64, 1.0, 0.82, 1.0)
		"cosmic":
			return Color(0.66, 0.9, 1.0, 1.0)
		"artifacts":
			return Color(1.0, 0.8, 0.28, 1.0)
		"world":
			return Color(0.86, 0.88, 1.0, 1.0)
		_:
			return Color(0.82, 0.92, 0.96, 1.0)


static func _world_feed_trimmed_lines(text: String) -> Array:
	var out: Array = []
	for raw_line in str(text).split("\n", false):
		var clean_line: String = str(raw_line).strip_edges()
		if clean_line == "":
			continue
		out.append(clean_line)
	return out


static func _world_feed_section_priority(section_key: String) -> int:
	match section_key:
		"cosmic":
			return 0
		"artifacts":
			return 1
		"conflict":
			return 2
		"politics":
			return 3
		"dynasty":
			return 4
		"factions":
			return 5
		"bending":
			return 6
		"world":
			return 7
		_:
			return 8


static func _diary_entry_has_body_lines(lines: Array) -> bool:
	for raw_line in lines:
		var line: String = str(raw_line).strip_edges()
		if line == "":
			continue
		if line == "----------------------":
			continue
		if line.begins_with("Year: "):
			continue
		if line.begins_with("Age: "):
			continue
		return true
	return false


static func _life_diary_actor_flat_cache_key(actor_id: int) -> String:
	return "life_diary_actor_%d_flat_lines" % int(actor_id)


static func _life_diary_actor_cache_key(actor_id: int) -> String:
	return "life_diary_actor_%d_entries" % int(actor_id)


static func _world_feed_entry_is_desktop_world_tab_candidate(entry: Dictionary, current_year: int, min_recent_year: int) -> bool:
	if typeof(entry) != TYPE_DICTIONARY:
		return false

	var entry_year: int = int(entry.get("year", current_year))
	if entry_year >= min_recent_year:
		return true

	var category: String = str(entry.get("category", "")).strip_edges().to_lower()
	var event_name: String = str(entry.get("event_name", "")).strip_edges().to_lower()
	var text: String = str(entry.get("text", entry.get("display_text", ""))).strip_edges().to_lower()

	if bool(entry.get("personally_relevant", false)):
		return true

	if category == "bending":
		return true

	if event_name.find("bending") >= 0:
		return true

	if event_name.find("tournament") >= 0:
		return true

	if event_name.find("spawn") >= 0:
		return true

	if event_name.find("birth") >= 0:
		return true

	if text.find("bending") >= 0 and text.find("tournament") >= 0:
		return true

	return false


static func _world_feed_display_dedupe_key(gs: GameState,
	entry: Dictionary) -> String:
	if typeof(entry) != TYPE_DICTIONARY or entry.is_empty():
		return ""

	return "%s|%s|%s|%d" % [
		str(entry.get("event_name", "")).strip_edges(),
		str(entry.get("tournament_id", "")).strip_edges(),
		str(entry.get("world_text", entry.get("text", ""))).strip_edges(),
		int(entry.get("year", gs.year if gs != null else 0))
	]


static func _is_personally_relevant_relic_feed_entry(gs: GameState,
	entry: Dictionary) -> bool:
	var normalized: Dictionary = entry
	if gs != null:
		normalized = gs.normalize_world_feed_entry(entry)

	if not bool(normalized.get("personally_relevant", false)):
		return false

	var event_name: String = str(normalized.get("event_name", "")).strip_edges()
	var category: String = str(normalized.get("category", "")).strip_edges().to_lower()
	var text: String = str(normalized.get("text", "")).to_lower()

	if category == "artifact":
		return true
	if text.findn("infinity stone") != -1:
		return true
	if text.findn("red bonnet") != -1:
		return true
	if text.findn("infinity gauntlet") != -1:
		return true
	if event_name == "red_bonnet_acquired" or event_name == "red_bonnet_rumor":
		return true
	if event_name == str(ActionEventTypes.GAUNTLET_FORGED):
		return true
	return false


static func _push_new_life_world_feed_entries(gs: GameState) -> void:
	if gs == null:
		return

	var seed_text:= "World Seed: Unknown"
	if gs.seed_engine != null:
		seed_text = "World Seed: %s" % str(gs.seed_engine.seed_value)

	var seed_entry:= gs.make_world_feed_entry(seed_text, {
		"category": "system",
		"event_name": "startup_seed",
		"source": "new_life_intro"
	})

	var existing_seed_index:= -1
	for i in range(gs.world_feed.size()):
		var entry:= gs.normalize_world_feed_entry(gs.world_feed [i])
		if str(entry.get("event_name", "")) == "startup_seed":
			existing_seed_index = i
			break

	if existing_seed_index != -1:
		gs.world_feed.remove_at(existing_seed_index)

	gs.world_feed.insert(0, seed_entry)

	if SupernaturalSceneSupport._player_is_avatar_birth(gs):
		var p: Person = gs.player
		var birth_city: String = str(p.birth_city).strip_edges()
		var birth_country: String = str(p.birth_country).strip_edges()

		if birth_city == "":
			birth_city = str(p.home_city).strip_edges()
		if birth_country == "":
			birth_country = str(p.home_country).strip_edges()
		if birth_city == "":
			birth_city = "an unknown city"
		if birth_country == "":
			birth_country = "an unknown nation"

		var avatar_text: String = "🌌The Avatar has been reincarnated in %s, %s." % [
			birth_city,
			birth_country
		]

		var existing_avatar_index:= -1
		for i in range(gs.world_feed.size()):
			var entry:= gs.normalize_world_feed_entry(gs.world_feed [i])
			if str(entry.get("event_name", "")) == "avatar_player_birth_reincarnation":
				existing_avatar_index = i
				break

		if existing_avatar_index != -1:
			gs.world_feed.remove_at(existing_avatar_index)

		var avatar_entry:= gs.make_world_feed_entry(avatar_text, {
			"npc_id": int(p.id),
			"personally_relevant": false,
			"category": "bending",
			"event_name": "avatar_player_birth_reincarnation",
			"source": "new_life_intro",
			"birth_city": birth_city,
			"birth_country": birth_country
		})

		gs.world_feed.insert(min(1, gs.world_feed.size()), avatar_entry)

	while gs.world_feed.size() > gs.WORLD_FEED_LIMIT:
		gs.world_feed.pop_back()


static func print_last_history(gs: GameState):
	var hist = gs.historical_timeline_engine.get_last_years(5)

	EraLog.truth("===== HISTORY =====")
	for y in hist.keys():
		EraLog.truth("Year:", y)
		for e in hist [y]:
			EraLog.truth(" -", e)
	EraLog.truth("===================")


static func _world_feed_section_key(gs: GameState,
	entry: Dictionary) -> String:
	var normalized: Dictionary = entry
	if gs != null:
		normalized = gs.normalize_world_feed_entry(entry)
	var category: String = str(normalized.get("category", "")).strip_edges().to_lower()
	var event_name: String = str(normalized.get("event_name", "")).strip_edges().to_lower()
	var text: String = str(normalized.get("text", "")).to_lower()

	if category in ["politics", "realm"]:
		return "politics"
	if category == "dynasty":
		return "dynasty"
	if category == "faction":
		return "factions"
	if category in ["war", "military"]:
		return "conflict"
	if category == "bending":
		return "bending"
	if category == "cosmic":
		return "cosmic"
	if category == "artifact":
		if event_name == "artifact_world_pressure" or text.findn("infinity stone") != -1 or text.findn("reality destabilizes") != -1:
			return "cosmic"
		return "artifacts"
	if category == "world":
		return "world"
	return "society"


static func _should_render_world_feed_entry_as_compact_block(gs: GameState,
	entry: Dictionary) -> bool:
	var normalized: Dictionary = entry
	if gs != null:
		normalized = gs.normalize_world_feed_entry(entry)
	var section_key: String = DiarySceneSupport._world_feed_section_key(gs, normalized)
	var lines: Array = DiarySceneSupport._world_feed_trimmed_lines(str(gs.get_world_feed_text(normalized)) if gs != null else str(normalized.get("text", "")))
	if lines.size() <= 1:
		return false
	return section_key in ["politics", "society", "world"]


static func _current_life_diary_owner_id(gs: GameState) -> int:
	if gs == null or gs.player == null:
		return -1
	return int(gs.player.id)


static func _life_diary_bridge_context(gs: GameState,
	reason: String = "life_diary_bridge", extra: Dictionary = {}) -> Dictionary:
	var context: Dictionary = extra.duplicate(true)
	context ["source"] = str(context.get("source", reason))
	context ["bridge"] = "mainscene_legacy_life_diary_bridge"
	context ["ui_is_reader_only"] = true
	context ["legacy_call_intercepted"] = true
	context ["year"] = int(gs.year if gs != null else 0)
	context ["actor_id"] = DiarySceneSupport._current_life_diary_owner_id(gs)
	if gs != null and gs.player != null:
		context ["age"] = int(gs.player.age)
	return context


static func _ensure_life_diary_state_store(gs: GameState) -> Dictionary:
	if gs == null:
		return {}
	if typeof(gs.scenario_state) != TYPE_DICTIONARY:
		gs.scenario_state = {}
	var store_raw: Variant = gs.scenario_state.get("life_diary_state_by_npc", {})
	if typeof(store_raw) != TYPE_DICTIONARY:
		gs.scenario_state ["life_diary_state_by_npc"] = {}
		store_raw = gs.scenario_state.get("life_diary_state_by_npc", {})
	return store_raw if typeof(store_raw) == TYPE_DICTIONARY else {}


static func _world_feed_entry_importance_score(gs: GameState,
	entry: Dictionary) -> float:
	var normalized: Dictionary = entry
	if gs != null:
		normalized = gs.normalize_world_feed_entry(entry)
	var section_key: String = DiarySceneSupport._world_feed_section_key(gs, normalized)
	var event_name: String = str(normalized.get("event_name", "")).strip_edges().to_lower()
	var text: String = str(normalized.get("text", "")).strip_edges()
	var line_count: int = max(1, DiarySceneSupport._world_feed_trimmed_lines(text).size())
	var score: float = 10.0 + (float(line_count) * 0.35)
	if bool(normalized.get("personally_relevant", false)):
		score += 18.0
	match section_key:
		"cosmic":
			score += 32.0
		"artifacts":
			score += 24.0
		"conflict":
			score += 20.0
		"politics":
			score += 16.0
		"dynasty":
			score += 14.0
		"factions":
			score += 12.0
		"bending":
			score += 10.0
		"world":
			score += 8.0
		_:
			score += 6.0
	if event_name in [
		"artifact_birth_loadout",
		"artifact_world_pressure",
		str(ActionEventTypes.COSMIC_ENFORCER_SPAWNED).to_lower()
	]:
		score += 10.0
	return score
