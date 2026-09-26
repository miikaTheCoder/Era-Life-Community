extends RefCounted
class_name RealitiesSceneSupport
## Realities support for the main scene. State, when needed, is passed explicitly.


static func _reality_surge_color(theme_id: String, phase: int = 0) -> Color:
	var clean_theme: String = str(theme_id).strip_edges().to_lower()

	if clean_theme == "avatar":
		var cycle: Array = [
			Color(1.0, 0.25, 0.06, 1.0),
			Color(0.2, 0.68, 1.0, 1.0),
			Color(0.54, 0.88, 0.36, 1.0),
			Color(0.86, 0.94, 1.0, 1.0)
		]
		return cycle [abs(phase) % cycle.size()]

	match clean_theme:
		"fire":
			return Color(1.0, 0.33, 0.08, 1.0)
		"water":
			return Color(0.22, 0.68, 1.0, 1.0)
		"earth":
			return Color(0.54, 0.78, 0.36, 1.0)
		"air":
			return Color(0.88, 0.94, 1.0, 1.0)
		_:
			return Color(1.0, 0.86, 0.42, 1.0)


static func _reality_surge_theme_id(surge: Dictionary) -> String:
	var surge_theme: Dictionary = {}
	var theme_raw: Variant = surge.get("theme", {})
	if typeof(theme_raw) == TYPE_DICTIONARY:
		surge_theme = theme_raw
	return str(surge_theme.get("theme_id", surge_theme.get("element", "generic"))).strip_edges().to_lower()


static func _reality_fusion_mode_warning(mode: String) -> String:
	match str(mode).strip_edges().to_lower():
		"stats_steal":
			return "STEAL this player's stats into yours? They might fight back."
		"inventory_merge":
			return "Merge their inventory into yours? Legendary objects may not arrive quietly."
		"bending_transfer":
			return "Merge their bending skills into yours? The elements may remember both souls."
		"traits_merge":
			return "Merge their traits into yours? Personality drift is possible."
		"money_transfer":
			return "Pull money from their universe? Interdimensional banking is messy."
		"bring_person_family":
			return "Queue this person and their close family for crossover."
		"friend_person":
			return "Bring only this person into your universe as an ally/friend."
		"bring_family_member":
			return "Bring only the selected family member into your universe."
		"fusion_loadout":
			return "Execute the queued Fusion Loadout. Multiple reality layers may shift at once."
		_:
			return "Merge this player's stats into yours? Could be too good to be true."


static func _reality_fusion_success_label(mode: String, source_name: String) -> String:
	match str(mode).strip_edges().to_lower():
		"stats_steal":
			return "Stole stat power from %s." % source_name
		"inventory_merge":
			return "Merged inventory echoes from %s." % source_name
		"bending_transfer":
			return "Merged bending influence from %s." % source_name
		"traits_merge":
			return "Merged trait fragments from %s." % source_name
		"money_transfer":
			return "Transferred money from %s's universe." % source_name
		"parallel_identity_import", "bring_person_family":
			return "%s and their family crossed into this universe." % source_name
		"friend_person":
			return "%s crossed into this universe as your ally." % source_name
		"bring_family_member":
			return "%s crossed into this universe alone." % source_name
		"fusion_loadout":
			return "Executed a Fusion Loadout through %s's universe." % source_name
		_:
			return "Merged stats from %s." % source_name


static func _reality_fusion_execute_button_style(selected: bool, pressed: bool, disabled: bool) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	if disabled:
		style.bg_color = Color(0.28, 0.22, 0.1, 0.72)
		style.border_color = Color(0.72, 0.56, 0.22, 0.38)
		style.set_border_width_all(1)
		return style

	if pressed:
		style.bg_color = Color(1.0, 0.78, 0.08, 1.0)
		style.border_color = Color(1.0, 1.0, 1.0, 0.96)
		style.shadow_color = Color(1.0, 1.0, 1.0, 0.55)
		style.shadow_size = 18
		style.shadow_offset = Vector2.ZERO
		style.set_border_width_all(3)
		return style

	if selected:
		style.bg_color = Color(0.96, 0.66, 0.05, 0.96)
		style.border_color = Color(1.0, 0.95, 0.64, 0.86)
		style.shadow_color = Color(1.0, 0.95, 0.74, 0.34)
		style.shadow_size = 10
		style.shadow_offset = Vector2.ZERO
		style.set_border_width_all(2)
		return style

	style.bg_color = Color(0.72, 0.46, 0.04, 0.92)
	style.border_color = Color(1.0, 0.88, 0.42, 0.72)
	style.shadow_color = Color(1.0, 0.92, 0.58, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2.ZERO
	style.set_border_width_all(2)
	return style


static func _collect_reality_fusion_buttons(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	for child in root.get_children():
		if child is Button:
			out.append(child)
		out.append_array(RealitiesSceneSupport._collect_reality_fusion_buttons(child))
	return out


static func _reality_fusion_source_identity_from_preview(source_player: Dictionary) -> String:
	var bits: Array = []

	var age: int = int(source_player.get("age", 0))
	if age > 0:
		bits.append("age %d" % age)

	var identity: String = str(source_player.get("identity", "")).strip_edges()
	if identity != "":
		bits.append(identity)

	var bending_type: String = str(source_player.get("bending_type", "none")).strip_edges()
	if bending_type != "" and bending_type.to_lower() != "none":
		if bending_type.to_lower() == "avatar":
			bits.append("Avatar")
		else:
			bits.append("%s bender" % bending_type.capitalize())

	if bool(source_player.get("avatar_state_unlocked", false)):
		bits.append("Avatar State unlocked")

	var traits: Array = source_player.get("traits", []) if typeof(source_player.get("traits", [])) == TYPE_ARRAY else []
	if not traits.is_empty():
		bits.append("%d traits" % traits.size())

	if bits.is_empty():
		return "a parallel identity"

	return ", ".join(bits)


static func _reality_fusion_animation_bucket(period_ms: float) -> int:
	var safe_period_ms: float = max(1.0, period_ms)
	return int(float(Time.get_ticks_msec()) / safe_period_ms)


static func _reality_fusion_loadout_effect_line(mode: String) -> String:
	match str(mode).strip_edges().to_lower():
		"stats_blend":
			return "Merge their stats into yours without fully stealing their identity."
		"stats_steal":
			return "Try to overpower their stats and pull the strongest values into your body. Resistance risk rises."
		"traits_merge":
			return "Blend personality traits into your identity. Useful, but it can create selfhood drift."
		"money_transfer":
			return "Pull money through interdimensional banking. Low body risk, messy timeline trace."
		"inventory_merge":
			return "Preserve inventory/artifact packets for crossover. Legendary objects may destabilize the save."
		"bending_transfer":
			return "Transfer bending mastery echoes. Avatar or multi-element influence can leave residue."
		"bring_person_family":
			return "Bring the saved character and close family branches into this universe."
		"friend_person":
			return "Try to bring the saved character alone as an ally or friend."
		"bring_family_member":
			return "Bring only the selected family member through the breach."
		_:
			return "Apply this reality layer through the fusion contract."


static func _reality_fusion_append_family_id(out: Array, seen: Dictionary, person_id: int) -> void:
	if person_id <= 0:
		return
	if seen.has(person_id):
		return
	seen [person_id] = true
	out.append(person_id)


static func _reality_fusion_gendered_family_label(npc: Dictionary, male_label: String, female_label: String, neutral_label: String) -> String:
	var gender: String = str(npc.get("gender", "")).strip_edges().to_lower()
	if gender == "male" or gender == "man" or gender == "boy":
		return male_label
	if gender == "female" or gender == "woman" or gender == "girl":
		return female_label
	return neutral_label


static func _reality_fusion_merge_policy(scope: Array, friend_link: String, root_person_id: int = -1) -> Dictionary:
	return {
		"relationship_scope": scope.duplicate(true),
		"friend_link": friend_link,
		"root_person_id": root_person_id,
		"lineage_strategy": "preserve" if not scope.is_empty() else "none",
		"id_strategy": "remap_safe",
		"conflict_resolution": "parallel_identity",
		"world_integration": {
			"register_npcs": true,
			"rebuild_index": true,
			"ensure_lineage": not scope.is_empty()
		}
	}


static func _reality_fusion_stat_keys() -> Array:
	return [
		"health",
		"mental_health",
		"smarts",
		"looks",
		"imagination",
		"fertility",
		"satisfaction",
		"job_performance",
		"motivation",
		"ambition",
		"fame"
	]


static func _reality_fusion_mode_title(mode: String) -> String:
	match str(mode).strip_edges().to_lower():
		"stats_blend":
			return "Merge Stats"
		"stats_steal":
			return "STEAL Stats"
		"traits_merge":
			return "Take Traits"
		"money_transfer":
			return "Drain Money"
		"inventory_merge":
			return "Inventory"
		"bending_transfer":
			return "Transfer Bending"
		"bring_person_family", "parallel_identity_import":
			return "Bring Family"
		"friend_person":
			return "Bring Ally"
		"bring_family_member":
			return "Bring Family Member"
		"fusion_loadout":
			return "Fusion Loadout"
		_:
			return mode.capitalize()


static func _reality_fusion_mode_button_text(text: String, mode: String) -> String:
	match str(mode).strip_edges().to_lower():
		"stats_blend":
			return "🧬 %s" % text
		"stats_steal":
			return "🩸 %s" % text
		"traits_merge":
			return "🎭 %s" % text
		"money_transfer":
			return "💰 %s" % text
		"inventory_merge":
			return "🎒 %s" % text
		"bending_transfer":
			return "🌊 %s" % text
		"bring_person_family":
			return "👨‍👩‍👧 %s" % text
		"friend_person":
			return "🤝 %s" % text
		"bring_family_member":
			return "🧍 %s" % text
		"pick_family_member":
			return "🔎 %s" % text
		"enter_universe":
			return "🚪 %s" % text
		_:
			return text


static func _reality_fusion_mode_color(mode: String) -> Color:
	match str(mode).strip_edges().to_lower():
		"stats_blend":
			return Color(0.2, 0.36, 0.56, 0.92)
		"stats_steal":
			return Color(0.56, 0.13, 0.18, 0.94)
		"traits_merge":
			return Color(0.38, 0.22, 0.58, 0.92)
		"money_transfer":
			return Color(0.17, 0.48, 0.26, 0.92)
		"inventory_merge":
			return Color(0.44, 0.34, 0.18, 0.92)
		"bending_transfer":
			return Color(0.14, 0.4, 0.55, 0.92)
		"bring_person_family":
			return Color(0.42, 0.28, 0.58, 0.92)
		"friend_person":
			return Color(0.17, 0.46, 0.42, 0.92)
		"bring_family_member":
			return Color(0.46, 0.28, 0.52, 0.92)
		"pick_family_member":
			return Color(0.28, 0.35, 0.52, 0.92)
		"enter_universe":
			return Color(0.18, 0.18, 0.22, 0.92)
		"execute_fusion":
			return Color(0.6, 0.32, 0.12, 0.96)
		"clear_loadout":
			return Color(0.18, 0.18, 0.2, 0.88)
		_:
			return Color(0.24, 0.26, 0.28, 0.9)


static func _reality_residency_route_result(
		report: Dictionary
) -> Dictionary:
	var route_raw: Variant = report.get(
		"route_report",
		{}
	)

	if typeof(
		route_raw
	) == TYPE_DICTIONARY:
		var route_result: Dictionary = (
			route_raw as Dictionary
		)

		if not route_result.is_empty():
			return route_result

	var result_raw: Variant = report.get(
		"result",
		{}
	)

	if typeof(
		result_raw
	) == TYPE_DICTIONARY:
		var result: Dictionary = (
			result_raw as Dictionary
		)

		if not result.is_empty():
			return result



	return report


static func _global_reality_intake_hide_button_style(hovered: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.84, 0.1, 1.0) if not hovered else Color(1.0, 0.94, 0.32, 1.0)
	style.border_color = Color(1.0, 1.0, 0.72, 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	style.shadow_color = Color(1.0, 0.78, 0.08, 0.34)
	style.shadow_size = 8 if hovered else 5
	return style


static func _global_reality_intake_tab_style(hovered: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	style.bg_color = Color(0.026, 0.028, 0.038, 0.94) if not hovered else Color(0.05, 0.054, 0.07, 0.98)
	style.border_color = Color(1.0, 0.84, 0.1, 0.62)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(1.0, 0.84, 0.1, 0.18)
	style.shadow_size = 10 if hovered else 6
	return style


static func _global_reality_intake_button_style(hovered: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()

	if pressed:
		style.bg_color = Color(0.018, 0.02, 0.028, 0.98)
	elif hovered:
		style.bg_color = Color(0.05, 0.054, 0.07, 0.98)
	else:
		style.bg_color = Color(0.026, 0.028, 0.038, 0.94)

	style.border_color = Color(0.86, 0.92, 1.0, 0.62) if hovered else Color(0.72, 0.78, 0.9, 0.36)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.5, 0.64, 1.0, 0.2 if hovered else 0.1)
	style.shadow_size = 14 if hovered else 8
	return style


static func _ensure_universal_switch_contract_engine(gs: GameState) -> void:
	if gs == null:
		return
	if gs.universal_switch_contract_engine == null:
		gs.universal_switch_contract_engine = UniversalSwitchContractEngine.new(gs)


static func _build_reality_surge_panel_style(theme_id: String, phase: int = 0) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	var clean_theme: String = str(theme_id).strip_edges().to_lower()
	var border: Color = RealitiesSceneSupport._reality_surge_color(clean_theme, phase)
	var dark: Color = RealitiesSceneSupport._reality_surge_dark_color(clean_theme, phase)

	style.bg_color = dark
	style.border_color = border
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(border.r, border.g, border.b, 0.55)
	style.shadow_size = 22
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 24
	style.content_margin_top = 22
	style.content_margin_right = 24
	style.content_margin_bottom = 22

	return style


static func _reality_surge_dark_color(theme_id: String, phase: int = 0) -> Color:
	var glow: Color = RealitiesSceneSupport._reality_surge_color(theme_id, phase)
	return Color(
		clamp(glow.r * 0.16, 0.03, 0.2),
		clamp(glow.g * 0.14, 0.03, 0.2),
		clamp(glow.b * 0.14, 0.04, 0.22),
		0.96
	)


static func _reality_fusion_current_universe_matches_path(gs: GameState,
	path: String) -> bool:
	var clean_path: String = str(path).strip_edges()
	if clean_path == "" or gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return false

	var entered_raw: Variant = gs.scenario_state.get("reality_fusion_entered_universe", {})
	if typeof(entered_raw) != TYPE_DICTIONARY:
		return false

	var entered: Dictionary = entered_raw
	var entered_path: String = str(entered.get("path", "")).strip_edges()
	return entered_path != "" and entered_path == clean_path


static func _build_reality_fusion_contract(mode: String) -> Dictionary:
	var clean_mode: String = str(mode).strip_edges().to_lower()
	var contract: Dictionary = {
		"schema": "eralife.reality_fusion_contract",
		"version": 1,
		"id": "main_scene_%s" % clean_mode,
		"mode": clean_mode,
		"extract": {
			"relationships": "none"
		},
		"transform": {},
		"reconcile": {
			"source_world": "unchanged",
			"write_source_save": false,
			"compensation": "none"
		},
		"balance": {
			"fatigue_cost": 4.0,
			"mental_strain": 2.0,
			"identity_instability": 1.0,
			"mutation_risk": 0.0,
			"cooldown_ms": 2500
		},
		"source_resistance": {
			"enabled": false,
			"chance": 0.0
		},
		"ui": {
			"label": clean_mode,
		}
	}
	match clean_mode:
		"stats_steal":
			contract ["extract"] ["stats"] = RealitiesSceneSupport._reality_fusion_stat_keys()
			contract ["transform"] ["stats"] = {
				"mode": "max",
				"cap": 100
			}
			contract ["source_resistance"] = {
				"enabled": true,
				"chance": 0.18
			}
			contract ["balance"] = {
				"fatigue_cost": 12.0,
				"mental_strain": 9.0,
				"identity_instability": 6.0,
				"mutation_risk": 0.1,
				"cooldown_ms": 8500
			}
		"inventory_merge":
			contract ["extract"] ["inventory"] = {
				"enabled": true,
				"filter": "rarity:legendary",
			}
			contract ["transform"] ["inventory"] = {
				"mode": "inject",
				"conflict": "stack_or_replace"
			}
			contract ["balance"] = {
				"fatigue_cost": 3.0,
				"mental_strain": 1.0,
				"identity_instability": 1.0,
				"mutation_risk": 0.02,
				"cooldown_ms": 3000
			}
		"bending_transfer":
			contract ["extract"] ["bending"] = {
				"enabled": true,
				"skills": true,
			}
			contract ["transform"] ["bending"] = {
				"mode": "skill_transfer",
				"cap": 100,
				"multiple_avatar_influence": true
			}
			contract ["balance"] = {
				"fatigue_cost": 9.0,
				"mental_strain": 7.0,
				"identity_instability": 4.0,
				"mutation_risk": 0.08,
				"cooldown_ms": 7000
			}
		"traits_merge":
			contract ["extract"] ["traits"] = {
				"include": [],
				"exclude": ["addiction", "reckless"]
			}
			contract ["transform"] ["traits"] = {
				"mode": "union",
				"mutation_chance": 0.08
			}
			contract ["balance"] = {
				"fatigue_cost": 2.0,
				"mental_strain": 6.0,
				"identity_instability": 5.0,
				"mutation_risk": 0.08,
				"cooldown_ms": 5000
			}
		"money_transfer":
			contract ["extract"] ["money"] = true
			contract ["transform"] ["money"] = {
				"mode": "add",
				"multiplier": 0.25,
				"cap": 1000000
			}
			contract ["source_resistance"] = {
				"enabled": true,
				"chance": 0.08
			}
			contract ["balance"] = {
				"fatigue_cost": 1.0,
				"mental_strain": 2.0,
				"identity_instability": 2.0,
				"mutation_risk": 0.03,
				"cooldown_ms": 4000
			}
		"bring_person_family":
			contract ["mode"] = "parallel_identity_import"
			contract ["merge_policy"] = RealitiesSceneSupport._reality_fusion_merge_policy([
				"parents",
				"children",
				"spouse",
				"partner",
				"ex_partners",
				"siblings",
				"grandparents",
				"grandchildren",
				"family_web",
				"extended_family"
			], "bidirectional", -1)
			contract ["balance"] = {
				"fatigue_cost": 3.0,
				"mental_strain": 3.0,
				"identity_instability": 2.0,
				"mutation_risk": 0.02,
				"cooldown_ms": 4000
			}
		"friend_person":
			contract ["mode"] = "friend_person"
			contract ["merge_policy"] = RealitiesSceneSupport._reality_fusion_merge_policy([], "bidirectional", -1)
			contract ["balance"] = {
				"fatigue_cost": 1.0,
				"mental_strain": 1.0,
				"identity_instability": 0.5,
				"mutation_risk": 0.0,
				"cooldown_ms": 2500
			}
		"bring_family_member":
			contract ["mode"] = "bring_family_member"
			contract ["merge_policy"] = RealitiesSceneSupport._reality_fusion_merge_policy([], "bidirectional", -1)
			contract ["balance"] = {
				"fatigue_cost": 1.5,
				"mental_strain": 2.0,
				"identity_instability": 1.0,
				"mutation_risk": 0.0,
				"cooldown_ms": 3000
			}
		_:
			contract ["extract"] ["stats"] = RealitiesSceneSupport._reality_fusion_stat_keys()
			contract ["transform"] ["stats"] = {
				"mode": "weighted_blend",
				"weight_self": 0.7,
				"weight_source": 0.3,
				"cap": 100
			}
	return contract


static func _reality_fusion_mode_titles(modes: Array) -> Array:
	var out: Array = []
	for raw_mode in modes:
		out.append(RealitiesSceneSupport._reality_fusion_mode_title(str(raw_mode)))
	return out


static func _reality_fusion_mode_button_style(mode: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	var style:= StyleBoxFlat.new()
	var color: Color = RealitiesSceneSupport._reality_fusion_mode_color(mode)
	if selected:
		color = color.lerp(Color(1.0, 1.0, 1.0, color.a), 0.18)
	if disabled:
		color = color.lerp(Color(0.02, 0.02, 0.02, color.a), 0.45)
		color.a = 0.58
	style.bg_color = color
	style.border_color = Color(1.0, 1.0, 1.0, 0.26 if selected else 0.14)
	style.border_width_left = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(color.r, color.g, color.b, 0.24 if selected else 0.1)
	style.shadow_size = 8 if selected else 3
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func _reality_fusion_foreign_timeline_pressure(gs: GameState) -> float:
	if gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return 0.0

	var entered_raw: Variant = gs.scenario_state.get("reality_fusion_entered_universe", {})
	if typeof(entered_raw) != TYPE_DICTIONARY:
		return 0.0

	var entered: Dictionary = entered_raw
	if entered.is_empty():
		return 0.0

	var pressure: float = 1.0
	if bool(entered.get("mode_mismatch", false)):
		pressure += 0.65

	pressure += clamp(float(gs.scenario_state.get("tva_engine_heat", 0.0)) / 4.0, 0.0, 2.5)
	pressure += clamp(float(gs.scenario_state.get("reality_fusion_identity_instability", 0.0)) / 18.0, 0.0, 2.0)

	return clamp(pressure, 0.0, 4.0)
