extends RefCounted
class_name SupernaturalSceneSupport
## Supernatural support for the main scene. State, when needed, is passed explicitly.


static func _append_avatar_four_elements_phrase(target_label: RichTextLabel, phrase: String) -> void:
	if target_label == null:
		return

	var colors: Array = [
		Color(1.0, 0.28, 0.12, 1.0),
		Color(0.25, 0.62, 1.0, 1.0),
		Color(0.45, 0.78, 0.34, 1.0),
		Color(0.82, 0.94, 1.0, 1.0)
	]

	var color_index: int = 0
	for i in range(str(phrase).length()):
		var ch: String = str(phrase).substr(i, 1)
		if ch == " ":
			target_label.append_text(" ")
			continue

		var color: Color = colors [color_index % colors.size()]
		target_label.append_text("[color=#%s]%s[/color]" % [
			color.to_html(false),
			ch
		])
		color_index += 1


static func _result_is_red_bonnet_dragonball_spectator_packet(result: Dictionary) -> bool:
	if typeof(result) != TYPE_DICTIONARY or result.is_empty():
		return false

	var source_text: String = str(result.get("source", result.get("action_source", ""))).strip_edges().to_lower()
	var theme_text: String = str(result.get("theme", "")).strip_edges().to_lower()
	var title_text: String = str(result.get("popup_title", result.get("title", ""))).strip_edges().to_lower()
	var text_blob: String = str(result.get("popup_text", result.get("text", ""))).strip_edges().to_lower()

	if theme_text == "dragonball" or theme_text == "dragonballs":
		return true

	if source_text.find("red_bonnet") != -1 and source_text.find("dragon") != -1:
		return true

	if title_text.find("dragon ball") != -1:
		return true

	if text_blob.find("dragon ball") != -1 and text_blob.find("red bonnet") != -1:
		return true

	if typeof(result.get("dragonball_arrival_animation", {})) == TYPE_DICTIONARY:
		var arrival_packet: Dictionary = result.get("dragonball_arrival_animation", {}) as Dictionary
		if bool(arrival_packet.get("active", false)):
			return true

	return false


static func _dragonball_scatter_icon(star: int) -> String:
	match int(star):
		1:
			return "🟠"
		2:
			return "🟠"
		3:
			return "🟠"
		4:
			return "🟠"
		5:
			return "🟠"
		6:
			return "🟠"
		7:
			return "🟠"
		_:
			return "🟠"


static func _build_afterlife_panel_style(is_hovered: bool) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()

	style.bg_color = Color(0.03, 0.03, 0.03, 0.96) if is_hovered else Color(0.0, 0.0, 0.0, 0.93)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.22) if is_hovered else Color(1.0, 1.0, 1.0, 0.12)

	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16

	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12

	style.shadow_color = Color(1.0, 1.0, 1.0, 0.18) if is_hovered else Color(1.0, 1.0, 1.0, 0.1)
	style.shadow_size = 20 if is_hovered else 13
	style.shadow_offset = Vector2(0, 0)

	return style


static func _is_transient_afterlife_overlay_result_type(_result_type: String) -> bool:
	return false


static func _bending_hub_surface_cache_signature_for_state(
	source_gs: GameState
) -> String:
	if source_gs == null or source_gs.player == null:
		return ""

	var actor: Person = source_gs.player
	var parts: Array = [
		"schema:eralife.bending_hub_surface_cache",
		"actor:%d" % int(actor.id),
		"year:%d" % int(source_gs.year),
		"age:%d" % int(actor.age),
		"type:%s" % str(actor.bending_type),
		"nation:%s" % str(actor.bending_nation),
		"skill_points:%d" % int(actor.bending_skill_points),
		"avatar_unlocked:%s" % str(actor.avatar_state_unlocked),
		"avatar_used:%s" % str(actor.avatar_state_used)
	]

	for element in ["air", "water", "earth", "fire"]:
		parts.append(
			"%s_mastery:%s"
			% [
				element,
				str(
					actor.bending_mastery.get(
						element,
						0
					)
				)
			]
		)
		parts.append(
			"%s_potential:%s"
			% [
				element,
				str(
					actor.bending_latent_potential.get(
						element,
						0
					)
				)
			]
		)

	if typeof(
		actor.bending_tournament_profile
	) == TYPE_DICTIONARY:
		parts.append(
			"tournament_profile:%s"
			% str(
				actor.bending_tournament_profile
			)
		)

	if typeof(
		source_gs.scenario_state
	) == TYPE_DICTIONARY:
		var world_raw: Variant = (
			source_gs.scenario_state.get(
				"bending_world_championship",
				{}
			)
		)

		if typeof(world_raw) == TYPE_DICTIONARY:
			var world_state: Dictionary = world_raw

			parts.append(
				"bending_world_version:%s"
				% str(
					world_state.get(
						"version",
						0
					)
				)
			)
			parts.append(
				"bending_world_projection_revision:%s"
				% str(
					world_state.get(
						"projection_revision",
						0
					)
				)
			)
			parts.append(
				"bending_world_last_report:%s"
				% str(
					world_state.get(
						"last_report",
						{}
					)
				)
			)

	return "|".join(parts)


static func _bending_hub_valid_sections() -> Array:
	return ["profile", "stats", "training", "skill_points", "abilities", "tournaments"]


static func _bending_hub_section_title(section: String) -> String:
	var clean_section: String = str(section).strip_edges().to_lower()
	match clean_section:
		"profile":
			return "PROFILE"
		"stats":
			return "STATS"
		"tournaments":
			return "TOURNAMENTS"
		"training":
			return "TRAINING"
		"skill_points":
			return "SKILL POINTS"
		"abilities":
			return "ABILITIES"
		_:
			return "PROFILE"


static func _bending_hub_willpower_descriptor(value: int) -> String:
	if value >= 900:
		return "Avatar Limitless"
	if value >= 180:
		return "Mythic"
	if value >= 150:
		return "Legendary"
	if value >= 120:
		return "Unbreakable"
	if value >= 95:
		return "Iron"
	if value >= 75:
		return "Strong"
	if value >= 55:
		return "Steady"
	if value >= 35:
		return "Shaken"
	if value >= 15:
		return "Breaking"
	return "Collapsed"


static func _make_bending_hub_section_label(text: String) -> Label:
	var label:= Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 0.96))
	return label


static func _bending_hub_ability_visual_profile_from_ability(ability: Dictionary) -> Dictionary:
	var profile:= {
		"visual_tier": str(ability.get("visual_tier", "low")),
		"visual_rank": int(ability.get("visual_rank", 1)),
		"visual_label": str(ability.get("visual_label", "Subtle Glow")),
		"aura_radius": int(ability.get("aura_radius", 12)),
		"aura_alpha": float(ability.get("aura_alpha", 0.22)),
		"pulse_speed": float(ability.get("pulse_speed", 0.85)),
		"distortion": bool(ability.get("distortion", false)),
		"legendary_vignette": bool(ability.get("legendary_vignette", false)),
		"legendary_mastery": bool(ability.get("legendary_mastery", false)),
		"corrupted_bending": bool(ability.get("corrupted_bending", false)),
		"avatar_pulse": bool(ability.get("avatar_pulse", false)),
		"element": str(ability.get("element", "")).strip_edges().to_lower()
	}

	return profile


static func _bending_hub_level_surface(element: String, level: int) -> Dictionary:
	var clean_element: String = str(element).strip_edges().to_lower()
	var safe_level: int = clamp(int(level), 0, 100)

	var descriptor: String = "Dormant"
	var flavor: String = "The element is present, but it has not truly answered you yet."

	if safe_level >= 95:
		descriptor = "Mythic"
		flavor = "Your bending feels almost legendary. The element moves like it already knows your intent."
	elif safe_level >= 85:
		descriptor = "Masterful"
		flavor = "Your control is disciplined, dangerous, and respected. Very few benders ever reach this level."
	elif safe_level >= 70:
		descriptor = "Elite"
		flavor = "Your technique is sharp enough to change the outcome of serious danger."
	elif safe_level >= 55:
		descriptor = "Formidable"
		flavor = "Your bending has become reliable under pressure, though mastery still demands more."
	elif safe_level >= 40:
		descriptor = "Focused"
		flavor = "Your element responds with purpose. You are no longer just practicing; you are shaping."
	elif safe_level >= 25:
		descriptor = "Awakening"
		flavor = "Your bending is becoming useful, but real control still slips when pressure rises."
	elif safe_level >= 10:
		descriptor = "Unsteady"
		flavor = "The element answers in flashes. You can do something now, but not safely every time."
	elif safe_level > 0:
		descriptor = "Flickering"
		flavor = "The gift is there, but fragile. Training matters more than raw talent right now."

	match clean_element:
		"air":
			if safe_level >= 85:
				flavor = "Your airbending is calm, precise, and nearly untouchable when you stay centered."
			elif safe_level >= 40:
				flavor = "Your airbending has started to feel light, reactive, and hard to pin down."
			elif safe_level > 0:
				flavor = "Your airbending arrives in uneven bursts, like wind learning your name."
		"water":
			if safe_level >= 85:
				flavor = "Your waterbending flows with frightening patience, shifting from healing to control with ease."
			elif safe_level >= 40:
				flavor = "Your waterbending is becoming adaptable, defensive, and emotionally responsive."
			elif safe_level > 0:
				flavor = "Your waterbending moves in small surges, still tied closely to your focus."
		"earth":
			if safe_level >= 85:
				flavor = "Your earthbending feels immovable. The ground itself seems to trust your command."
			elif safe_level >= 40:
				flavor = "Your earthbending is getting heavier, steadier, and harder to break."
			elif safe_level > 0:
				flavor = "Your earthbending is rough but real, like stone shifting under a new voice."
		"fire":
			if safe_level >= 85:
				flavor = "Your firebending is controlled power, no longer just heat but discipline."
			elif safe_level >= 40:
				flavor = "Your firebending burns cleaner now, stronger without becoming reckless."
			elif safe_level > 0:
				flavor = "Your firebending sparks with potential, but it still needs breath and restraint."

	return {
		"title_text": "%s: %s" % [clean_element.capitalize(), descriptor],
		"descriptor": descriptor,
		"flavor": flavor,
		"bar_text": "Level %d" % safe_level
	}


static func _bending_hub_ability_progress_text(ability: Dictionary, _player_age: int) -> String:
	var ability_name: String = str(ability.get("name", "Unknown Skill"))
	var current_level: int = int(ability.get("current_level", 0))
	var unlocked: bool = bool(ability.get("unlocked", false))
	var on_cooldown: bool = bool(ability.get("on_cooldown", false))
	var lock_text: String = str(ability.get("lock_text", "")).strip_edges()
	var upgrade_level: int = int(ability.get("upgrade_level", 0))
	var max_upgrade_level: int = int(ability.get("max_upgrade_level", 0))

	if on_cooldown:
		return "%s - Recovering" % ability_name

	if not unlocked:
		if lock_text == "":
			lock_text = "Unlock path incomplete"
		return "%s - Locked: %s" % [ability_name, lock_text]

	var tier_text: String = "Tier %d/%d" % [upgrade_level, max_upgrade_level] if max_upgrade_level > 0 else "Tier %d" % upgrade_level

	return "%s - Ready • %s • Level %d/100" % [
		ability_name,
		tier_text,
		current_level
	]


static func _bending_hub_ability_type_label(raw_type: String) -> String:
	var clean_type: String = str(raw_type).strip_edges().to_lower()
	match clean_type:
		"attack":
			return "Attack"
		"control":
			return "Control"
		"heal":
			return "Healing"
		"defense":
			return "Defense"
		"escape":
			return "Movement"
		_:
			return "Technique"


static func _bending_hub_category_bundle_text(bundle: Dictionary) -> String:
	if bundle.is_empty():
		return "No category bundle"

	var ordered_keys: Array = ["accuracy", "power", "guard", "counter", "evasion", "focus"]
	var parts: Array = []
	var used: Dictionary = {}

	for stat_name in ordered_keys:
		if not bundle.has(stat_name):
			continue

		parts.append("%s %d+" % [
			str(stat_name).capitalize(),
			int(bundle.get(stat_name, 0))
		])
		used [stat_name] = true

	for raw_key in bundle.keys():
		var clean_key: String = str(raw_key).strip_edges().to_lower()
		if clean_key == "" or bool(used.get(clean_key, false)):
			continue

		parts.append("%s %d+" % [
			clean_key.capitalize(),
			int(bundle.get(raw_key, 0))
		])

	if parts.is_empty():
		return "No category bundle"

	return ", ".join(parts)


static func _spirit_world_person_label(person: Person) -> String:
	if person == null:
		return "Unknown"

	var first_name: String = ""
	var last_name: String = ""

	if "first_name" in person:
		first_name = str(person.first_name).strip_edges()
	if "last_name" in person:
		last_name = str(person.last_name).strip_edges()

	var full_name: String = ("%s %s" % [first_name, last_name]).strip_edges()
	if full_name != "":
		return full_name

	if "name" in person:
		var direct_name: String = str(person.name).strip_edges()
		if direct_name != "":
			return direct_name

	return "Person #%d" % int(person.id)


static func _make_wizard_hub_label(text: String) -> Label:
	var label:= Label.new()
	label.text = str(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	return label


static func _make_wizard_hub_body(text: String) -> RichTextLabel:
	var body:= RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = str(text)
	return body


static func _make_wizard_hub_button(text: String) -> Button:
	var button:= Button.new()
	button.text = str(text)
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


static func _super_runtime_superhero_profile_has_access(profile: Dictionary) -> bool:
	if profile.is_empty():
		return false

	if bool(profile.get("hub_unlocked", false)):
		return true

	var alignment: String = str(profile.get("alignment", "civilian")).strip_edges().to_lower()
	if alignment != "" and alignment != "civilian":
		return true

	var registration_status: String = str(profile.get("registration_status", "unregistered")).strip_edges().to_lower()
	if registration_status not in ["", "unregistered", "unknown"]:
		return true

	if bool(profile.get("birth_power_configured", false)):
		return true

	var alias_name: String = str(profile.get("public_alias", "")).strip_edges()
	if alias_name != "":
		return true

	return false


static func _build_superpower_hub_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.018, 0.09, 0.985)
	style.border_color = Color(0.9, 0.48, 1.0, 0.86)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	style.shadow_color = Color(0.7, 0.2, 1.0, 0.36)
	style.shadow_size = 38
	style.shadow_offset = Vector2(0, 12)
	return style


static func _superpower_hub_actor_label(actor: Person) -> String:
	if actor == null:
		return "Unknown"

	var first_name: String = str(actor.get("first_name")).strip_edges()
	var last_name: String = str(actor.get("last_name")).strip_edges()
	var full_name: String = ("%s %s" % [first_name, last_name]).strip_edges()

	if full_name != "":
		return full_name
	if first_name != "":
		return first_name
	if last_name != "":
		return last_name

	return "Unknown"


static func _build_superpower_hub_entry_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.035, 0.14, 0.78)
	style.border_color = Color(0.92, 0.54, 1.0, 0.38)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


static func _build_power_hub_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.038, 0.075, 0.985)
	style.border_color = Color(0.38, 0.72, 1.0, 0.86)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	style.shadow_color = Color(0.15, 0.45, 1.0, 0.34)
	style.shadow_size = 38
	style.shadow_offset = Vector2(0, 12)
	return style


static func _build_power_hub_entry_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.06, 0.12, 0.78)
	style.border_color = Color(0.38, 0.72, 1.0, 0.38)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


static func _red_bonnet_wish_is_dragon_ball_summon(wish_name: String) -> bool:
	var clean: String = str(wish_name).strip_edges().to_lower()
	return clean in [
		"summon_dragon_balls",
		"summon dragon balls",
		"summon all dragon balls"
	]


static func _bending_sum_int_dictionary_values(row: Dictionary) -> int:
	var total: int = 0
	for raw_key in row.keys():
		total += max(0, int(row.get(raw_key, 0)))
	return total


static func _populate_superpower_option_button(button: OptionButton, rows: Array, selected_value: String = "") -> void:
	if button == null:
		return

	button.clear()

	var selected_index:= 0
	var clean_selected:= str(selected_value).strip_edges().to_lower()

	for i in range(rows.size()):
		var row: Dictionary = rows [i]
		var label: String = str(row.get("label", row.get("id", "Option")))
		var value: String = str(row.get("id", label)).strip_edges().to_lower()
		button.add_item(label)
		button.set_item_metadata(i, value)
		if clean_selected != "" and value == clean_selected:
			selected_index = i

	if button.item_count > 0:
		button.select(selected_index)


static func _selected_superpower_option_value(button: OptionButton, fallback: String = "") -> String:
	if button == null or button.item_count <= 0:
		return fallback

	var idx:= button.get_selected_id()
	if idx < 0 or idx >= button.item_count:
		return fallback

	var metadata:= str(button.get_item_metadata(idx)).strip_edges().to_lower()
	if metadata != "":
		return metadata

	return str(button.get_item_text(idx)).strip_edges().to_lower()


static func _build_superpower_sandbox_celestial_panel_style() -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.025, 0.085, 0.985)
	style.border_color = Color(0.84, 0.56, 1.0, 0.88)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	style.shadow_color = Color(0.58, 0.24, 1.0, 0.36)
	style.shadow_size = 36
	style.shadow_offset = Vector2(0, 10)
	return style


static func _add_bending_style_echo_rows_to_box(box: VBoxContainer, title: String, rows: Array, max_rows: int = 8) -> void:
	var title_label:= Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.text = "\n%s" % title
	box.add_child(title_label)

	if rows.is_empty():
		var empty_label:= Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = "No style echoes have formed yet."
		box.add_child(empty_label)
		return

	for i in range(min(max_rows, rows.size())):
		if typeof(rows [i]) != TYPE_DICTIONARY:
			continue

		var row: Dictionary = rows [i]
		var label:= Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "#%d %s • %s • Echo Heat %d\n%s\nBloodline: %s | Dojo: %s | Nation: %s" % [
			i + 1,
			str(row.get("style_title", "Unformed Style")),
			str(row.get("element", "none")).capitalize(),
			int(row.get("echo_heat", 0)),
			str(row.get("myth_title", "A recognizable fighting culture is beginning to form.")),
			str(row.get("bloodline", "Unknown")),
			str(row.get("dojo_name", "Solo")),
			str(row.get("nation", "Unknown"))
		]
		box.add_child(label)


static func _add_bending_history_board_to_box(box: VBoxContainer, title: String, rows: Array) -> void:
	var title_label:= Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.text = "\n%s" % title
	box.add_child(title_label)

	if rows.is_empty():
		var empty_label:= Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = "No records yet."
		box.add_child(empty_label)
		return

	for i in range(min(5, rows.size())):
		if typeof(rows [i]) != TYPE_DICTIONARY:
			continue

		var row: Dictionary = rows [i]
		var wins: int = int(row.get("wins", 0))
		var losses: int = int(row.get("losses", 0))
		var fights: int = max(1, wins + losses)
		var win_pct: float = float(wins) / float(fights) * 100.0

		var record_label:= Label.new()
		record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		record_label.text = "#%d %s • %d-%d • %.1f%% • KO %d • Titles %d • %s" % [
			i + 1,
			str(row.get("name", "Unknown")),
			wins,
			losses,
			win_pct,
			int(row.get("kos", 0)),
			int(row.get("championships", 0)),
			str(row.get("element", "none")).capitalize()
		]
		box.add_child(record_label)


static func _grant_picker_button_label(element: String) -> String:
	return "Grant %s Bending" % element.capitalize()


static func _grantable_avatar_elements_for_target(target: Person) -> Array:
	var out: Array = []
	if target == null:
		return out

	for element in ["air", "earth", "fire", "water"]:
		if int(target.bending_mastery.get(element, 0)) <= 0:
			out.append(element)

	return out


static func _removable_avatar_elements_for_target(target: Person) -> Array:
	var out: Array = []
	if target == null:
		return out

	for element in ["air", "earth", "fire", "water"]:
		if int(target.bending_mastery.get(element, 0)) > 0:
			out.append(element)

	return out


static func _apply_afterlife_panel_visual_state(panel: PanelContainer, is_hovered: bool) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", SupernaturalSceneSupport._build_afterlife_panel_style(is_hovered))


static func _bending_feature_enabled_by_reality_contract(gs: GameState) -> bool:
	if gs == null:
		return false




	if typeof(
		gs.custom_settings
	) == TYPE_DICTIONARY:
		var custom_overrides_raw: Variant = (
			gs.custom_settings.get(
				"feature_overrides",
				{}
			)
		)

		if typeof(
			custom_overrides_raw
		) == TYPE_DICTIONARY:
			var custom_overrides: Dictionary = (
				custom_overrides_raw as Dictionary
			)

			if custom_overrides.has(
				"bending"
			):
				return bool(
					custom_overrides.get(
						"bending",
						false
					)
				)

	if typeof(
		gs.reality_feature_overrides
	) == TYPE_DICTIONARY:
		if gs.reality_feature_overrides.has(
			"bending"
		):
			return bool(
				gs.reality_feature_overrides.get(
					"bending",
					false
				)
			)

	return bool(
		gs.player_bending_enabled
	)


static func _create_spirit_world_avatar_echo(gs: GameState,
	actor: Person, avatar_record: Dictionary = {}) -> Person:
	if gs == null or actor == null:
		return null
	if gs.npc_factory == null:
		return null

	var echo: Person = gs.npc_factory.create_random_npc()
	if echo == null:
		return null

	var element: String = str(avatar_record.get("native_element", "")).strip_edges().to_lower()
	if element == "" and gs.bending_engine != null and gs.bending_engine.has_method("_bending_person_primary_element"):
		element = str(gs.bending_engine.call("_bending_person_primary_element", actor)).strip_edges().to_lower()

	if element not in ["air", "water", "earth", "fire"]:
		element = ["air", "water", "earth", "fire"].pick_random()

	var avatar_name: String = str(avatar_record.get("name", "Avatar Echo")).strip_edges()
	if avatar_name == "":
		avatar_name = "Avatar Echo"

	echo.first_name = avatar_name
	echo.last_name = ""
	echo.age = max(24, int(actor.age) + 20)
	echo.alive = true
	echo.health = max(90, int(actor.health) + 20)
	echo.mental_health = 100
	echo.smarts = max(80, int(actor.smarts))
	echo.ambition = max(75, int(actor.ambition))
	echo.motivation = max(85, int(actor.motivation))
	echo.bending_type = "avatar"
	echo.bending_nation = str(actor.bending_nation)

	var actor_level: int = SupernaturalSceneSupport._spirit_world_actor_bending_level(gs, actor, element)
	var avatar_score: int = int(avatar_record.get("spirit_score", actor_level + 18))
	var echo_level: int = clamp(max(actor_level + 18, avatar_score), 35, 120)

	if gs.bending_engine != null and gs.bending_engine.has_method("force_bending_type"):
		gs.bending_engine.force_bending_type(echo, element, echo_level)

	echo.bending_type = "avatar"
	echo.bending_nation = str(actor.bending_nation)

	if typeof(echo.bending_mastery) == TYPE_DICTIONARY:
		for base_element in ["air", "water", "earth", "fire"]:
			var base_value: int = int(echo.bending_mastery.get(base_element, 0))
			if base_element == element:
				echo.bending_mastery [base_element] = max(base_value, echo_level)
			else:
				echo.bending_mastery [base_element] = max(base_value, clamp(echo_level - 18, 25, 100))

	if "willpower_engine" in gs and gs.willpower_engine != null and gs.willpower_engine.has_method("ensure_willpower"):
		gs.willpower_engine.ensure_willpower(echo, {
			"source": "spirit_world_echo_spawn",
			"duel_scope": "bending",
			"previous_avatar_name": avatar_name,
			"previous_avatar_element": element
		})

	if "npcs" in gs and typeof(gs.npcs) == TYPE_ARRAY and echo not in gs.npcs:
		gs.npcs.append(echo)

	return echo


static func _spirit_world_previous_avatar_records(gs: GameState,
	actor: Person) -> Array:
	if gs == null or actor == null:
		return []

	if "avatar_influence_engine" in gs and gs.avatar_influence_engine != null:
		if gs.avatar_influence_engine.has_method("_previous_avatar_records_for"):
			var records_raw: Variant = gs.avatar_influence_engine.call("_previous_avatar_records_for", actor)
			if typeof(records_raw) == TYPE_ARRAY:
				return records_raw

	return []


static func _spirit_world_actor_bending_level(gs: GameState,
	actor: Person, element: String = "") -> int:
	if actor == null:
		return 1

	var clean_element: String = str(element).strip_edges().to_lower()
	if clean_element == "":
		clean_element = "fire"

	if gs != null and gs.bending_engine != null and gs.bending_engine.has_method("get_bending_level"):
		return int(gs.bending_engine.call("get_bending_level", actor, clean_element))

	if typeof(actor.bending_mastery) == TYPE_DICTIONARY:
		return int(actor.bending_mastery.get(clean_element, 1))

	return 1


static func _spirit_world_avatar_path_combat_ui(gs: GameState,
	actor: Person, context: Dictionary = {}) -> Dictionary:
	var active_element: String = str(context.get("active_element", "avatar")).strip_edges().to_lower()
	var phase: String = str(context.get("phase", "threshold")).strip_edges().to_lower()
	var status_text: String = str(context.get("status_text", "Spirit World • Avatar Cycle")).strip_edges()

	return {
		"visible": true,
		"theme": "bending_avatar",
		"status_text": status_text,
		"player_label": "%s • Living Avatar" % SupernaturalSceneSupport._spirit_world_person_label(actor),
		"player_value": clamp(SupernaturalSceneSupport._spirit_world_actor_bending_level(gs, actor, active_element), 1, 120),
		"player_max": 120,
		"enemy_label": "The Avatar Cycle • Listening",
		"enemy_value": 100,
		"enemy_max": 100,
		"player_avatar_pulse": true,
		"enemy_avatar_pulse": true,
		"spirit_world": true,
		"phase": phase,
		"impact_shake": true,
		"impact_shake_amount": 4.0,
		"elemental_screen_damage": {
			"enabled": true,
			"screen_damage": "soft",
			"screen_damage_intensity": 0.28,
			"screen_fracture": false,
			"screen_bleed": false,
			"time_dilation": 0.82,
			"audio_muffle": 0.18,
			"element": active_element,
			"finish_move": "Spirit World crossing",
			"motion": "avatar_cycle_veil_breathe"
		},
		"surge_vector": {
			"enabled": true,
			"direction": "cycle_to_avatar",
			"origin_id": -1,
			"target_id": int(actor.id) if actor != null else -1,
			"element": active_element,
			"mode": "spiritual_threshold",
			"text": "The Avatar Cycle bends softly around you."
		}
	}


static func _begin_spirit_world_avatar_duel(gs: GameState,
	actor: Person, avatar_record: Dictionary) -> Dictionary:
	var echo: Person = SupernaturalSceneSupport._create_spirit_world_avatar_echo(gs, actor, avatar_record)
	if echo == null:
		return {
			"type": "scenario_commit_complete",
			"text": "The Spirit World duel could not begin because no echo formed.",
			"popup_title": "Spirit World",
			"popup_text": "The previous Avatar's echo flickered but never fully arrived.",
			"popup_footer": "Tap anywhere to continue.",
			"opps": []
		}

	var avatar_name: String = str(avatar_record.get("name", ("%s %s" % [echo.first_name, echo.last_name]).strip_edges()))
	var avatar_element: String = str(avatar_record.get("native_element", "avatar")).strip_edges().to_lower()

	var duel_scenario: Dictionary = {
		"id": "spirit_world_duel_%d_%d" % [int(actor.id), int(Time.get_ticks_msec())],
		"source": "scenario_engine",
		"category": "bending",
		"target_id": int(echo.id),
		"bending_duel_target_id": int(echo.id),
		"bending_duel_target_name": avatar_name,
		"previous_avatar_name": avatar_name,
		"previous_avatar_element": avatar_element,
		"combat_ui": SupernaturalSceneSupport._spirit_world_avatar_path_combat_ui(gs, actor, {
			"status_text": "Spirit World Duel • %s" % avatar_name,
			"phase": "avatar_duel_start",
			"active_element": avatar_element
		}),
		"bending_duel_contract": {
			"schema": "eralife.spirit_world_bending_duel_contract",
			"version": 2,
			"source": "spirit_world",
			"uses_scenario_panel": true,
			"damage_reflects_on_stats": false,
			"world_feed_enabled": false,
			"previous_avatar_name": avatar_name,
			"previous_avatar_element": avatar_element
		}
	}

	return SupernaturalSceneSupport._spirit_world_begin_bending_duel(gs, actor, echo, duel_scenario)


static func _spirit_world_queue_external_scenario(gs: GameState,
	scenario: Dictionary) -> Dictionary:
	if gs == null or gs.scenario_engine == null:
		return {
			"success": false,
			"popup_title": "Scenario Runtime Missing",
			"popup_text": "ScenarioEngine is unavailable.",
			"popup_footer": "Tap anywhere to continue."
		}

	if not gs.scenario_engine.has_method("queue_external_scenario"):
		return {
			"success": false,
			"popup_title": "Scenario Runtime Missing",
			"popup_text": "ScenarioEngine.queue_external_scenario() is unavailable.",
			"popup_footer": "Tap anywhere to continue."
		}

	var queued_result: Variant = gs.scenario_engine.call("queue_external_scenario", scenario)
	if typeof(queued_result) == TYPE_DICTIONARY:
		return queued_result

	return {
		"success": false,
		"popup_title": "Scenario Runtime Missing",
		"popup_text": "ScenarioEngine.queue_external_scenario() did not return a Dictionary.",
		"popup_footer": "Tap anywhere to continue."
	}


static func _spirit_world_begin_bending_duel(gs: GameState,
	actor: Person, target: Person, duel_scenario: Dictionary) -> Dictionary:
	if gs == null or gs.scenario_engine == null:
		return {
			"type": "scenario_commit_complete",
			"text": "The Spirit World duel could not begin because ScenarioEngine was unavailable.",
			"popup_title": "Spirit World Duel",
			"popup_text": "The previous Avatar stepped forward, but the duel runtime was missing.",
			"popup_footer": "Tap anywhere to continue.",
			"opps": []
		}

	if gs.scenario_engine.has_method("_begin_bending_duel_scenario"):
		var duel_result: Variant = gs.scenario_engine.call("_begin_bending_duel_scenario", actor, target, duel_scenario)
		if typeof(duel_result) == TYPE_DICTIONARY:
			return duel_result

	if gs.scenario_engine.has_method("queue_external_scenario"):
		var fallback_scenario: Dictionary = duel_scenario.duplicate(true)
		fallback_scenario ["resolver_owner"] = "scenario_engine"
		fallback_scenario ["resolver_method"] = "_resolve_bending_duel_choice"
		fallback_scenario ["panel_title"] = str(fallback_scenario.get("panel_title", "SPIRIT WORLD DUEL"))
		fallback_scenario ["footer_text"] = str(fallback_scenario.get("footer_text", "The previous Avatar waits."))
		fallback_scenario ["prompt"] = str(fallback_scenario.get("prompt", "%s steps forward through the veil.\n\nThe duel begins when you accept." % SupernaturalSceneSupport._spirit_world_person_label(target)))
		fallback_scenario ["choices"] = [
			{
				"id": "bending_duel_accept",
				"label": "Begin the spiritual duel",
				"journal_text": "I began a spiritual duel with a previous Avatar.",
				"choice_family": "duel",
				"button_theme": "bending_ability",
				"power_source": "spirit_world",
				"bending_duel_target_id": int(target.id)
			},
			{
				"id": "bending_duel_decline",
				"label": "Step back",
				"journal_text": "I stepped back from the spiritual duel.",
				"choice_family": "leave",
				"button_theme": "defensive_escape",
				"power_source": "survival",
				"bending_duel_target_id": int(target.id)
			}
		]
		return SupernaturalSceneSupport._spirit_world_queue_external_scenario(gs, fallback_scenario)

	return {
		"type": "scenario_commit_complete",
		"text": "The Spirit World duel could not begin because no compatible duel route was available.",
		"popup_title": "Spirit World Duel",
		"popup_text": "The previous Avatar waited, but the duel runtime could not accept the scenario.",
		"popup_footer": "Tap anywhere to continue.",
		"opps": []
	}


static func _bending_hub_default_player_element(gs: GameState) -> String:
	if gs == null or gs.player == null:
		return ""

	var p:= gs.player
	var bending_type: String = str(p.bending_type).strip_edges().to_lower()

	if bending_type in ["air", "water", "earth", "fire"]:
		return bending_type

	if gs.bending_engine != null:
		var best_element: String = ""
		var best_score: float = -999999.0

		for element in ["air", "water", "earth", "fire"]:
			var level: int = int(gs.bending_engine.get_bending_level(p, element))
			var potential: int = 0
			if gs.bending_engine.has_method("get_bending_latent_potential"):
				potential = int(gs.bending_engine.get_bending_latent_potential(p, element))

			var score: float = float(potential) - (float(level) * 0.65)
			if level <= 0:
				score += 6.0

			if score > best_score:
				best_score = score
				best_element = element

		return best_element

	return ""


static func _player_has_visible_wizard_magic(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	if gs.wizard_engine == null:
		return false
	if not gs.wizard_engine.has_method("has_wizard_magic"):
		return false
	return gs.wizard_engine.has_wizard_magic(gs.player)


static func _wizard_hub_signature(gs: GameState) -> String:
	if gs == null or gs.player == null:
		return "no-player"
	var profile: Dictionary = gs.player.wizard_profile if typeof(gs.player.wizard_profile) == TYPE_DICTIONARY else {}
	var skill: Dictionary = profile.get("skill", {}) if typeof(profile.get("skill", {})) == TYPE_DICTIONARY else {}
	var wand: Dictionary = profile.get("wand", {}) if typeof(profile.get("wand", {})) == TYPE_DICTIONARY else {}
	var competition: Dictionary = profile.get("competition", {}) if typeof(profile.get("competition", {})) == TYPE_DICTIONARY else {}
	return "%s|%s|%s|%s|%s|%s|%s|%s" % [
		str(profile.get("magic_status", "")),
		str(profile.get("wizard_blood_status", "")),
		str(profile.get("full_wizard", false)),
		str(wand.get("name", "")),
		str(wand.get("level", 0)),
		str(skill.get("spellcraft", 0)),
		str(skill.get("spell_theory", 0)),
		str(competition.get("available", false))
	]


static func _player_has_red_bonnet_artifact(gs: GameState) -> bool:
	return ItemsSceneSupport._player_has_named_artifact(gs, "Red Bonnet")


static func _build_red_bonnet_wish_button_style(aura_strength: float, is_hovered: bool = false) -> StyleBoxFlat:
	var accent:= ItemsSceneSupport._artifact_item_color({
		"name": "Red Bonnet",
		"color": "red"
	})
	var gold:= Color(1.0, 0.84, 0.36, 1.0)

	var style:= StyleBoxFlat.new()
	var bg_alpha: float = 0.22 + aura_strength * 0.16 + (0.08 if is_hovered else 0.0)
	var border_alpha: float = 0.62 + aura_strength * 0.22 + (0.1 if is_hovered else 0.0)
	var glow_alpha: float = 0.28 + aura_strength * 0.3 + (0.1 if is_hovered else 0.0)

	var bg_color:= Color(0.42, 0.08, 0.1, bg_alpha)
	bg_color = bg_color.lerp(Color(gold.r, gold.g, gold.b, bg_alpha), 0.1 + aura_strength * 0.06)

	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(gold.r, gold.g, gold.b, border_alpha).lerp(
		Color(accent.r, accent.g, accent.b, border_alpha),
		0.42
	)
	style.shadow_color = Color(accent.r, accent.g, accent.b, glow_alpha)
	style.shadow_size = 10 + int(round(aura_strength * 6.0)) + (2 if is_hovered else 0)
	style.shadow_offset = Vector2(0, 0)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style


static func _player_has_bending_power_source(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	var bending_type: String = str(gs.player.bending_type).strip_edges().to_lower()
	if bending_type != "" and bending_type != "none":
		return true

	if typeof(gs.player.bending_mastery) == TYPE_DICTIONARY:
		for raw_key in gs.player.bending_mastery.keys():
			if int(gs.player.bending_mastery.get(raw_key, 0)) > 0:
				return true

	return false


static func _invalidate_super_runtime_surface_cache(gs: GameState,
	reason: String = "changed") -> void:
	if gs != null and typeof(gs.scenario_state) == TYPE_DICTIONARY:
		gs.scenario_state.erase("super_runtime_surface_cache")
		gs.scenario_state ["super_runtime_surface_cache_invalidated_reason"] = reason
		gs.scenario_state ["super_runtime_surface_cache_invalidated_at_ms"] = int(Time.get_ticks_msec())


static func _superpower_catalog_ids(gs: GameState) -> Array:
	var out: Array = []
	if gs != null and gs.power_engine != null:
		var registry_raw: Variant = gs.power_engine.contract_registry
		if typeof(registry_raw) == TYPE_DICTIONARY:
			var registry: Dictionary = registry_raw
			for raw_key in registry.keys():
				var power_id: String = str(raw_key).strip_edges().to_lower()
				if power_id == "":
					continue
				out.append(power_id)

	out.sort()

	if out.is_empty():
		out = [
			"super_strength",
			"super_speed",
			"spider_abilities",
			"infant_chaos_polymorph",
			"energy_projection",
			"telepathy",
			"probability_manipulation",
			"super_serum",
			"adamantium_skeleton"
		]

	return out


static func _superpower_catalog_label(gs: GameState,
	power_id: String) -> String:
	var clean_power_id:= str(power_id).strip_edges().to_lower()
	if gs != null and gs.power_engine != null and gs.power_engine.has_method("get_power_contract"):
		var contract: Dictionary = gs.power_engine.get_power_contract(clean_power_id)
		if typeof(contract) == TYPE_DICTIONARY and not contract.is_empty():
			return str(contract.get("display_name", clean_power_id.replace("_", " ").capitalize()))

	return clean_power_id.replace("_", " ").capitalize()


static func _build_superpower_sandbox_summary(gs: GameState,
	config: Dictionary) -> String:
	if config.is_empty():
		return "No power is bound yet. The bloodline is quiet, but the sky is listening."

	var scope_label:= str(config.get("scope", "only_me")).replace("_", " ").capitalize()
	var origin_label:= str(config.get("origin", "born_hidden")).replace("_", " ").capitalize()
	var power_label:= SupernaturalSceneSupport._superpower_catalog_label(gs, str(config.get("primary_power", "super_strength")))
	var identity_label:= str(config.get("public_identity", "secret")).replace("_", " ").capitalize()

	var awakening: Dictionary = config.get("awakening", {})
	var awakening_label:= str(awakening.get("mode", "latent")).replace("_", " ").capitalize()

	var inheritance: Dictionary = config.get("inheritance", {})
	var flags: Array = []

	if bool(inheritance.get("awakens_under_trauma", false)):
		flags.append("trauma ignition")
	if bool(inheritance.get("awakens_at_age_13", false)):
		flags.append("age 13 spark")
	if bool(inheritance.get("only_firstborn", false)):
		flags.append("firstborn seal")
	if bool(inheritance.get("only_avatars_benders", false)):
		flags.append("bender-linked genome")
	if bool(inheritance.get("corrupts_bloodline_over_time", false)):
		flags.append("bloodline decay")

	var flag_text:= ""
	if not flags.is_empty():
		flag_text = " • %s" % ", ".join(flags)

	return "Bound Power: %s • Origin: %s • Awakening: %s • Scope: %s • Identity: %s%s" % [
		power_label,
		origin_label,
		awakening_label,
		scope_label,
		identity_label,
		flag_text
	]


static func _player_is_avatar_birth(gs: GameState) -> bool:
	if gs == null or gs.player == null:
		return false

	return str(gs.player.bending_type).strip_edges().to_lower() == "avatar"


static func _can_avatar_alter_bending(gs: GameState) -> bool:
	var p: Person = gs.player
	if p == null:
		return false
	if str(p.bending_type) != "avatar":
		return false
	return p.age >= 12
