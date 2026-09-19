extends RefCounted
class_name CheckpointSceneSupport
## Checkpoint support for the main scene. State, when needed, is passed explicitly.


static func _saved_lives_dir() -> String:
	return "user://saved_lives"


static func _ensure_saved_lives_dir() -> void:
	var root:= DirAccess.open("user://")
	if root == null:
		return
	if not root.dir_exists("saved_lives"):
		root.make_dir("saved_lives")


static func _sanitize_save_slot_component(text: String) -> String:
	var cleaned:= text.strip_edges().to_lower()
	for ch in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "]:
		cleaned = cleaned.replace(ch, "_")
	while cleaned.find("__") != -1:
		cleaned = cleaned.replace("__", "_")
	if cleaned == "":
		cleaned = "life"
	return cleaned


static func _checkpoint_resume_contract_from_load_options(
	load_options: Dictionary
) -> Dictionary:
	var direct_raw: Variant = load_options.get(
		"checkpoint_resume_contract",
		{}
	)

	if typeof(direct_raw) == TYPE_DICTIONARY:
		var direct_contract: Dictionary = (
			direct_raw as Dictionary
		)

		if not direct_contract.is_empty():
			return direct_contract.duplicate(false)

	var continue_raw: Variant = load_options.get(
		"continue_contract",
		{}
	)
	var continue_contract: Dictionary = (
		continue_raw as Dictionary
		if typeof(continue_raw) == TYPE_DICTIONARY
		else {}
	)
	var continue_resume_raw: Variant = continue_contract.get(
		"checkpoint_resume_contract",
		{}
	)

	if typeof(continue_resume_raw) == TYPE_DICTIONARY:
		var continue_resume: Dictionary = (
			continue_resume_raw as Dictionary
		)

		if not continue_resume.is_empty():
			return continue_resume.duplicate(false)

	var life_summary_raw: Variant = continue_contract.get(
		"life_summary",
		{}
	)
	var life_summary: Dictionary = (
		life_summary_raw as Dictionary
		if typeof(life_summary_raw) == TYPE_DICTIONARY
		else {}
	)
	var summary_resume_raw: Variant = life_summary.get(
		"checkpoint_resume_contract",
		{}
	)

	if typeof(summary_resume_raw) == TYPE_DICTIONARY:
		var summary_resume: Dictionary = (
			summary_resume_raw as Dictionary
		)

		if not summary_resume.is_empty():
			return summary_resume.duplicate(false)

	return {}


static func _saved_life_residency_signature(
	path: String
) -> String:
	var clean_path: String = str(
		path
	).strip_edges()

	if clean_path == "":
		return ""

	var modified_at: int = int(
		FileAccess.get_modified_time(
			clean_path
		)
	)
	var signature_hash: int = abs(
		hash(
			"%s|%d|resident_checkpoint"
			% [
				clean_path,
				modified_at
			]
		)
	)

	return "checkpoint:%d" % signature_hash


static func _checkpoint_resume_saved_diary_lines_from_contract(
	resume_contract: Dictionary
) -> Array:
	var lines: Array = []

	if resume_contract.is_empty():
		return lines

	var entries_raw: Variant = resume_contract.get(
		"life_diary_entries",
		[]
	)

	if typeof(entries_raw) != TYPE_ARRAY:
		return lines

	var entries: Array = (
		entries_raw as Array
	)

	for entry_raw in entries:
		var entry_lines: Array = []

		if typeof(entry_raw) == TYPE_ARRAY:
			entry_lines = (
				entry_raw as Array
			)
		elif typeof(entry_raw) == TYPE_DICTIONARY:
			var entry_dict: Dictionary = (
				entry_raw as Dictionary
			)
			var entry_lines_raw: Variant = entry_dict.get(
				"lines",
				[]
			)

			if typeof(entry_lines_raw) == TYPE_ARRAY:
				entry_lines = (
					entry_lines_raw as Array
				)
		else:
			entry_lines = [
				entry_raw
			]

		if entry_lines.is_empty():
			continue

		for raw_line in entry_lines:
			lines.append(
				str(raw_line)
			)

		lines.append("")
		lines.append("")

	return lines


static func _read_reality_fusion_save_payload(path: String) -> Dictionary:
	var clean_path: String = str(path).strip_edges()
	if clean_path == "" or not FileAccess.file_exists(clean_path):
		return {}
	var lower_path: String = clean_path.to_lower()
	if lower_path.ends_with(".bin"):
		var f_bin = FileAccess.open(clean_path, FileAccess.READ)
		if f_bin == null:
			return {}
		var bytes: PackedByteArray = f_bin.get_buffer(f_bin.get_length())
		f_bin.close()
		var decoded: Variant = BinarySaveEngine.decode(bytes)
		return decoded if typeof(decoded) == TYPE_DICTIONARY else {}
	var f_json = FileAccess.open(clean_path, FileAccess.READ)
	if f_json == null:
		return {}
	var parsed: Variant = JSON.parse_string(f_json.get_as_text())
	f_json.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func _reality_fusion_save_person_alive(npc: Dictionary) -> bool:
	if npc.is_empty():
		return false
	return bool(npc.get("alive", true))


static func _build_current_auto_preserve_path(gs: GameState) -> String:
	CheckpointSceneSupport._ensure_saved_lives_dir()

	if gs == null or gs.player == null:
		return "%s/autopreserve_current.bin" % CheckpointSceneSupport._saved_lives_dir()

	if typeof(gs.custom_settings) != TYPE_DICTIONARY:
		gs.custom_settings = {}

	var cached:= str(gs.custom_settings.get("_auto_preserve_slot_path", "")).strip_edges()
	if cached != "":
		return cached

	var player_name:= CheckpointSceneSupport._sanitize_save_slot_component("%s_%s" % [
		gs.player.first_name,
		gs.player.last_name
	])
	var birth_city:= CheckpointSceneSupport._sanitize_save_slot_component(str(gs.player.birth_city))
	var birth_country:= CheckpointSceneSupport._sanitize_save_slot_component(str(gs.player.birth_country))
	var birth_month:= int(gs.player.birthday.get("month", 1))
	var birth_day:= int(gs.player.birthday.get("day", 1))

	var slot_path:= "%s/%s_%s_%s_%02d_%02d_autopreserve.bin" % [
		CheckpointSceneSupport._saved_lives_dir(),
		player_name,
		birth_city,
		birth_country,
		birth_month,
		birth_day
	]

	gs.custom_settings ["_auto_preserve_slot_path"] = slot_path
	return slot_path


static func _save_load_reality_build_status_from_scheduler(gs: GameState) -> String:
	if gs == null or not gs.has_method("get_runtime_boot_scheduler_snapshot"):
		return "Reality is assembling..."

	var snapshot: Dictionary = gs.get_runtime_boot_scheduler_snapshot()
	var domain_states: Dictionary = snapshot.get("domain_states", {}) if typeof(snapshot.get("domain_states", {})) == TYPE_DICTIONARY else {}

	if domain_states.has("world"):
		var world_state: Dictionary = domain_states.get("world", {}) if typeof(domain_states.get("world", {})) == TYPE_DICTIONARY else {}
		var execution_state: String = str(world_state.get("execution_state", "")).strip_edges()
		if execution_state == "streaming":
			return str(world_state.get("player_status_text", "World hydration is streaming in the background."))

	return "Your playable shell is live."


static func _checkpoint_residency_signature_from_load_options(
	path: String,
	load_options: Dictionary
) -> String:
	var resume_contract: Dictionary = (
		CheckpointSceneSupport._checkpoint_resume_contract_from_load_options(
			load_options
		)
	)
	var continue_raw: Variant = load_options.get(
		"continue_contract",
		{}
	)
	var continue_contract: Dictionary = (
		continue_raw as Dictionary
		if typeof(continue_raw) == TYPE_DICTIONARY
		else {}
	)
	var life_summary_raw: Variant = continue_contract.get(
		"life_summary",
		{}
	)
	var life_summary: Dictionary = (
		life_summary_raw as Dictionary
		if typeof(life_summary_raw) == TYPE_DICTIONARY
		else {}
	)
	var candidates: Array = [
		load_options.get(
			"residency_signature",
			""
		),
		resume_contract.get(
			"residency_signature",
			""
		),
		continue_contract.get(
			"residency_signature",
			""
		),
		life_summary.get(
			"residency_signature",
			""
		)
	]

	for raw_candidate in candidates:
		var candidate: String = str(
			raw_candidate
		).strip_edges()

		if candidate != "":
			return candidate

	return CheckpointSceneSupport._saved_life_residency_signature(
		path
	)
