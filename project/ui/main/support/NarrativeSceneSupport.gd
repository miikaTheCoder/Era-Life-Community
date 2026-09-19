extends RefCounted
class_name NarrativeSceneSupport
## Narrative support for the main scene. State, when needed, is passed explicitly.


static func _pending_situations_actor_display_name(actor: Person) -> String:
	if actor == null:
		return "this person"

	if actor.has_method("get_display_name"):
		var display_name: String = str(actor.call("get_display_name")).strip_edges()
		if display_name != "":
			return display_name

	if actor.has_method("get_full_name"):
		var method_name: String = str(actor.call("get_full_name")).strip_edges()
		if method_name != "":
			return method_name

	var direct_name: String = ""
	var direct_name_raw = actor.get("name")
	if direct_name_raw != null:
		direct_name = str(direct_name_raw).strip_edges()
	if direct_name != "":
		return direct_name

	var first_name: String = ""
	var first_name_raw = actor.get("first_name")
	if first_name_raw != null:
		first_name = str(first_name_raw).strip_edges()

	var last_name: String = ""
	var last_name_raw = actor.get("last_name")
	if last_name_raw != null:
		last_name = str(last_name_raw).strip_edges()

	var combined_name: String = ("%s %s" % [first_name, last_name]).strip_edges()
	if combined_name != "":
		return combined_name

	var actor_id: int = -1
	var actor_id_raw = actor.get("id")
	if actor_id_raw != null:
		actor_id = int(actor_id_raw)

	if actor_id > 0:
		return "person #%d" % actor_id

	return "this person"


static func _find_choose_ereality_entry_button_in_tree(root: Node) -> Button:
	if root == null:
		return null

	if root is Button:
		var button:= root as Button
		var role: String = str(button.get_meta("entry_role", "")).strip_edges().to_lower()
		if role in ["god_mode_alive", "choose_ereality", "ereality", "god_mode"]:
			return button

	for child in root.get_children():
		var found: Button = NarrativeSceneSupport._find_choose_ereality_entry_button_in_tree(child)
		if found != null and is_instance_valid(found):
			return found

	return null


static func _build_choose_adventure_entry_button_style(accent: Color, hovered: bool, role: String = "") -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	var narrative: bool = role == "narrative_alive" or role == "choose_adventure"
	var god_mode: bool = role == "god_mode_alive" or role == "choose_ereality"
	var base_mix: float = 0.22 if narrative else 0.14
	if god_mode:
		base_mix = 0.18
	style.bg_color = Color(
		0.055 + (accent.r * base_mix),
		0.045 + (accent.g * base_mix),
		0.08 + (accent.b * base_mix),
		0.98
	)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.86 if not hovered else 1.0)
	style.border_width_left = 2 if not hovered else 4
	style.border_width_right = 2 if not hovered else 4
	style.border_width_top = 2 if not hovered else 4
	style.border_width_bottom = 2 if not hovered else 4
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	var shadow_alpha: float = 0.22
	if narrative:
		shadow_alpha = 0.34
	elif god_mode:
		shadow_alpha = 0.28
	if hovered:
		shadow_alpha += 0.18
	style.shadow_color = Color(accent.r, accent.g, accent.b, shadow_alpha)
	style.shadow_size = 16 if not hovered else 28
	style.shadow_offset = Vector2(0, 6)
	return style


static func _build_choose_adventure_entry_card_style(accent: Color, hovered: bool, phase: float) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.09, 0.94)
	style.border_color = accent.lightened(0.1 + (0.12 * phase))
	style.border_width_left = 2 if not hovered else 4
	style.border_width_right = 2 if not hovered else 4
	style.border_width_top = 2 if not hovered else 4
	style.border_width_bottom = 2 if not hovered else 4
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.24 if not hovered else 0.42)
	style.shadow_size = 18 if not hovered else 30
	style.shadow_offset = Vector2(0, 10)
	return style


static func _apply_action_result_choice_effects(gs: GameState,
	choice: Dictionary) -> void:
	if gs == null or gs.player == null:
		return

	var stat_deltas_raw: Variant = choice.get("stat_deltas", {})
	if typeof(stat_deltas_raw) != TYPE_DICTIONARY:
		return

	var stat_deltas: Dictionary = stat_deltas_raw
	for raw_key in stat_deltas.keys():
		var stat_key: String = str(raw_key).strip_edges()
		if stat_key == "":
			continue

		var before_value: float = float(gs.player.get(stat_key))
		var delta_value: float = float(stat_deltas.get(raw_key, 0.0))
		var after_value: float = before_value + delta_value

		match stat_key:
			"health":
				after_value = clamp(after_value, 0.0, 200.0)
			"mental_health", "satisfaction", "smarts", "looks", "fame":
				after_value = clamp(after_value, 0.0, 100.0)
			_:
				pass

		gs.player.set(stat_key, after_value)


static func _pending_situations_controlled_actor(gs: GameState) -> Person:
	if gs == null or gs.player == null:
		return null
	return gs.player


static func _pending_situations_controlled_actor_id(gs: GameState) -> int:
	var actor: Person = NarrativeSceneSupport._pending_situations_controlled_actor(gs)
	if actor == null:
		return -1
	return int(actor.id)


static func _pending_situations_current_era_name(gs: GameState) -> String:
	if gs == null:
		return "Modern Era"

	if gs.era != null:
		var era_name: String = str(gs.era.name if "name" in gs.era else "").strip_edges()
		if era_name != "":
			return era_name

	var era_text: String = str(gs.get("era_name") if "era_name" in gs else "").strip_edges()
	if era_text != "":
		return era_text

	return "Modern Era"


static func _pending_situation_result_diary_text_from_result(result: Dictionary) -> String:
	if typeof(result) != TYPE_DICTIONARY:
		return ""

	var candidate_keys: Array = [
		"life_diary_text",
		"diary_text",
		"text",
		"popup_text"
	]

	for raw_key in candidate_keys:
		var key: String = str(raw_key)
		var candidate: String = str(result.get(key, "")).strip_edges()
		if candidate == "":
			continue

		candidate = candidate.replace("Tap anywhere to continue.", "").strip_edges()
		candidate = candidate.replace("Tap to continue.", "").strip_edges()
		candidate = NarrativeSceneSupport._clean_pending_situation_diary_text(candidate)

		if candidate != "":
			return candidate

	return ""


static func _clean_pending_situation_diary_text(text: String) -> String:
	var clean_text: String = DiarySceneSupport._compact_diary_text(str(text).strip_edges())
	if clean_text == "":
		return ""

	if clean_text == "----------------------":
		return clean_text

	if clean_text.begins_with("Year: ") or clean_text.begins_with("Age: "):
		return clean_text

	if not clean_text.ends_with("!") and not clean_text.ends_with(".") and not clean_text.ends_with("?"):
		clean_text += "."

	return clean_text


static func _pending_situation_diary_fingerprint(text: String) -> String:
	var clean_text: String = NarrativeSceneSupport._clean_pending_situation_diary_text(text).to_lower()
	if clean_text == "":
		return ""

	clean_text = clean_text.replace(" i hated how much it still mattered.", "")
	clean_text = clean_text.replace(" i barely knew what to feel.", "")
	clean_text = clean_text.replace(" somehow, i still felt like this would not be the end of my story.", "")
	clean_text = clean_text.replace(" i tried to understand it through faith.", "")
	clean_text = clean_text.strip_edges()

	if clean_text == "":
		return ""

	return "pending_situation_diary:%s" % clean_text


static func _pending_situation_diary_line_exists_in_entries(entries: Array, text: String) -> bool:
	var clean_text: String = NarrativeSceneSupport._clean_pending_situation_diary_text(text)
	if clean_text == "":
		return true

	var fingerprint: String = NarrativeSceneSupport._pending_situation_diary_fingerprint(clean_text)

	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_ARRAY:
			continue

		var entry: Array = raw_entry as Array
		for raw_line in entry:
			var existing_text: String = NarrativeSceneSupport._clean_pending_situation_diary_text(str(raw_line))
			if existing_text == "":
				continue

			if existing_text == clean_text:
				return true

			if fingerprint != "" and NarrativeSceneSupport._pending_situation_diary_fingerprint(existing_text) == fingerprint:
				return true

	return false


static func _pending_situation_diary_fingerprints_from_entries(entries: Array, existing_fingerprints: Array = []) -> Array:
	var out: Array = []

	for raw_fingerprint in existing_fingerprints:
		var fingerprint: String = str(raw_fingerprint).strip_edges()
		if fingerprint != "" and fingerprint not in out:
			out.append(fingerprint)

	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_ARRAY:
			continue

		var entry: Array = raw_entry as Array
		for raw_line in entry:
			var line_text: String = str(raw_line).strip_edges()
			if line_text == "":
				continue

			var fingerprint: String = NarrativeSceneSupport._pending_situation_diary_fingerprint(line_text)
			if fingerprint != "" and fingerprint not in out:
				out.append(fingerprint)

	return out


static func _pending_situation_bank_report_from_result(result: Dictionary) -> Dictionary:
	if typeof(result) != TYPE_DICTIONARY:
		return {}

	var direct: Dictionary = ValueSceneSupport._safe_dictionary(result.get("bank_report", {}))
	if not direct.is_empty():
		return direct

	var money_direct: Dictionary = ValueSceneSupport._safe_dictionary(result.get("money_delta_report", {}))
	if not money_direct.is_empty():
		return money_direct

	var resolution_report: Dictionary = ValueSceneSupport._safe_dictionary(result.get("resolution_report", {}))
	var nested_bank: Dictionary = ValueSceneSupport._safe_dictionary(resolution_report.get("bank_report", {}))
	if not nested_bank.is_empty():
		return nested_bank

	var nested_money: Dictionary = ValueSceneSupport._safe_dictionary(resolution_report.get("money_delta_report", {}))
	if not nested_money.is_empty():
		return nested_money

	return {}


static func _pending_situation_actor_by_id(gs: GameState,
	actor_id: int) -> Person:
	if gs == null or actor_id <= 0:
		return null

	if gs.player != null and int(gs.player.id) == actor_id:
		return gs.player

	if gs.has_method("get_npc_by_id"):
		var found = gs.get_npc_by_id(actor_id)
		if found != null:
			return found

	if gs.has_method("get_or_reactivate_npc_by_id"):
		var restored = gs.get_or_reactivate_npc_by_id(actor_id)
		if restored != null:
			return restored

	return null
