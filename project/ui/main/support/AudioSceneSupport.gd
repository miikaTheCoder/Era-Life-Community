extends RefCounted
class_name AudioSceneSupport
## Audio support for the main scene. State, when needed, is passed explicitly.


static func _luxury_exchange_shiny_audio_candidate_paths() -> Array:
	return [
		"res://audio/music/Shiny.ogg",
		"res://Audio/Music/Shiny.ogg",
		"res://audio/Shiny.ogg",
		"res://Audio/Shiny.ogg",
		"res://audio/sfx/Shiny.ogg",
		"res://Audio/SFX/Shiny.ogg",
		"res://Shiny.ogg"
	]


static func _death_transition_audio_candidate_paths() -> Array:
	return [
		"res://audio/music/Death.ogg",
		"res://Audio/Music/Death.ogg",
		"res://audio/Death.ogg",
		"res://Audio/Death.ogg",
		"res://Death.ogg"
	]


static func _grocery_store_music_profiles() -> Dictionary:
	return {
		"basket_lane_market": {
			"display_name": "Era-Mart Store Speaker",
			"context_key": "grocery_store_era_mart",
			"surface_id": "food_contract_hub_era_mart",
			"volume_db": -17.25,
			"fade_in_ms": 950,
			"fade_out_ms": 1050,
			"rotation_crossfade_ms": 1800,
			"track_variants": [
				{ "id": "era_mart_store_speaker_1", "file": "EraMartMusic.ogg"},
				{ "id": "era_mart_store_speaker_2", "file": "EraMartMusic2.ogg"},
				{ "id": "era_mart_store_speaker_3", "file": "EraMartMusic3.ogg"}
			],
			"context_keys": ["grocery_store_era_mart", "era_mart", "basket_lane_market", "food_contract_hub_era_mart"]
		},
		"goldleaf_grocers": {
			"display_name": "Goldleaf Store Speaker",
			"context_key": "grocery_store_goldleaf",
			"surface_id": "food_contract_hub_goldleaf",
			"volume_db": -18.25,
			"fade_in_ms": 950,
			"fade_out_ms": 1050,
			"rotation_crossfade_ms": 1800,
			"track_variants": [
				{ "id": "goldleaf_store_speaker_1", "file": "GoldMusic.ogg"},
				{ "id": "goldleaf_store_speaker_2", "file": "GoldMusic2.ogg"}
			],
			"context_keys": ["grocery_store_goldleaf", "goldleaf", "goldleaf_grocers", "food_contract_hub_goldleaf"]
		}
	}


static func _grocery_store_music_candidate_paths(file_name: String) -> Array:
	var clean_file: String = str(file_name).strip_edges()
	if clean_file == "":
		return []

	return [
		"res://audio/music/%s" % clean_file,
		"res://audio/%s" % clean_file,
		"res://%s" % clean_file
	]


static func _birth_intro_cry_audio_contract() -> Dictionary:
	return {
		"schema": "eralife.one_shot_audio_event_contract",
		"version": 1,
		"event_id": "birth_intro_cry",
		"display_name": "Birth Intro Cry",
		"paths": [
			"res://audio/sfx/BirthIntroCry.ogg",
			"res://audio/music/BirthIntroCry.ogg",
			"res://BirthIntroCry.ogg"
		],
		"bus": "Master",
		"volume_db": -1.25,
		"pitch_scale": 1.0,
		"play_once": true,
		"allowed_entry_kinds": ["custom", "random", "household_curated_life"]
	}


static func _character_switch_audio_contract() -> Dictionary:
	return {
		"schema": "eralife.one_shot_audio_event_contract",
		"version": 1,
		"event_id": "character_switch",
		"display_name": "Character Switch",
		"paths": [
			"res://audio/sfx/CharacterSwitch.ogg",
			"res://audio/music/CharacterSwitch.ogg",
			"res://CharacterSwitch.ogg"
		],
		"bus": "Master",
		"volume_db": -0.75,
		"pitch_scale": 1.0,
		"play_once": true,
		"duck_fade_ms": 95,
		"restore_fade_ms": 180,
		"duck_volume_drop_db": 17.0,
		"minimum_duck_volume_db": -31.0,
		"source": "relationship_profile_switch"
	}


static func _append_character_switch_duck_player(out: Array, player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.playing:
		return
	if out.has(player):
		return

	out.append(player)


static func _birth_intro_cry_should_arm_for_settings(settings: Dictionary) -> bool:
	var entry_kind: String = str(settings.get("_god_mode_entry_kind", settings.get("god_mode_entry_kind", "custom"))).strip_edges().to_lower()
	var starting_age: int = int(settings.get("starting_age", settings.get("age", 0)))

	if starting_age != 0:
		return false

	if entry_kind == "household_curated_life":
		return bool(settings.get("birth_intro_cry_allowed", false))

	return true


static func _god_mode_menu_music_transition_lead_seconds_for_stream(stream_length: float, profile: Dictionary) -> float:
	var raw_lead: float = float(profile.get("rotation_lead_seconds", 0.42))
	var min_lead: float = float(profile.get("rotation_min_lead_seconds", 0.24))
	var max_lead: float = float(profile.get("rotation_max_lead_seconds", 0.62))
	var max_tail_ratio: float = float(profile.get("rotation_max_tail_ratio", 0.018))
	var ratio_limited_lead: float = stream_length * max_tail_ratio

	if stream_length <= 1.0:
		return raw_lead

	var resolved_lead: float = raw_lead
	if ratio_limited_lead > 0.0:
		resolved_lead = min(raw_lead, ratio_limited_lead)

	return clamp(resolved_lead, min_lead, max_lead)


static func _god_mode_menu_music_resolve_path(file_name: String) -> String:
	var clean_file: String = str(file_name).strip_edges()
	if clean_file == "":
		return ""
	if clean_file.begins_with("res://"):
		return clean_file
	return "res://audio/music/%s" % clean_file


static func _grocery_store_music_resolve_path(file_name: String) -> String:
	for raw_path in AudioSceneSupport._grocery_store_music_candidate_paths(file_name):
		var path: String = str(raw_path).strip_edges()
		if path == "":
			continue
		if ResourceLoader.exists(path):
			return path

	return "res://audio/music/%s" % str(file_name).strip_edges()


static func _era_mart_store_music_candidate_paths() -> Array:
	return AudioSceneSupport._grocery_store_music_candidate_paths("EraMartMusic.ogg")


static func _era_mart_store_music_path() -> String:
	return AudioSceneSupport._grocery_store_music_resolve_path("EraMartMusic.ogg")


static func _birth_intro_cry_entry_kind_allowed(entry_kind: String) -> bool:
	var normalized: String = str(entry_kind).strip_edges().to_lower()
	if normalized == "":
		normalized = "custom"

	var contract: Dictionary = AudioSceneSupport._birth_intro_cry_audio_contract()
	var allowed: Array = contract.get("allowed_entry_kinds", ["custom", "random"])
	return allowed.has(normalized)


static func _birth_intro_cry_current_player_is_newborn_start(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	if int(gs.player.age) != 0:
		return false

	var settings: Dictionary = gs.custom_settings.duplicate(true) if typeof(gs.custom_settings) == TYPE_DICTIONARY else {}
	var entry_kind: String = str(settings.get("_god_mode_entry_kind", settings.get("god_mode_entry_kind", ""))).strip_edges().to_lower()

	if entry_kind == "household_curated_life":
		return bool(settings.get("birth_intro_cry_allowed", false))

	if bool(settings.get("birth_intro_cry_allowed", true)):
		return true

	if typeof(gs.scenario_state) == TYPE_DICTIONARY:
		if bool(gs.scenario_state.get("birth_intro_cry_allowed", false)):
			return true
		if bool(gs.scenario_state.get("birth_shell_player_is_newborn", false)):
			return true
		if bool(gs.scenario_state.get("birth_shell_intro_required", false)):
			return true
		if bool(gs.scenario_state.get("active_lineage_birth_contract", {}).get("birth_intro_cry_allowed", false)):
			return true

	return true


static func _god_mode_birth_intro_cry_should_play(gs: GameState,
	snapshot: Dictionary) -> bool:
	if gs == null or gs.player == null:
		return false

	if bool(snapshot.get("suppress_birth_intro_for_existing_life", false)):
		return false

	if bool(snapshot.get("birth_intro_cry_allowed", false)):
		return true

	return int(snapshot.get("age", int(gs.player.age))) <= 0
