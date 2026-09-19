extends RefCounted
class_name NavigationSceneSupport
## Navigation support for the main scene. State, when needed, is passed explicitly.


static func _collect_runtime_focusable_controls(root: Node, out: Array) -> void:
	if root == null:
		return

	if root is Control:
		var control:= root as Control
		if control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			if not bool(control.get("disabled")):
				out.append(control)

	for child in root.get_children():
		NavigationSceneSupport._collect_runtime_focusable_controls(child, out)


static func _ui_nav_button_variant_for_key(key: String) -> String:
	return "priority" if key == "age_up" else "standard"


static func _install_zero_frame_scroll_passthrough(root: Node) -> void:
	if root == null:
		return
	if not is_instance_valid(root):
		return

	for raw_child in root.get_children():
		var child:= raw_child as Node
		if child == null:
			continue

		if child is ScrollContainer:
			var nested_scroll:= child as ScrollContainer
			nested_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
			nested_scroll.follow_focus = false
			nested_scroll.scroll_deadzone = 0
			continue

		if child is RichTextLabel:
			var rich:= child as RichTextLabel
			rich.mouse_filter = Control.MOUSE_FILTER_PASS
			rich.scroll_active = false
		elif child is Button:
			var button:= child as Button
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.focus_mode = Control.FOCUS_ALL
		elif child is Label:
			var label:= child as Label
			label.mouse_filter = Control.MOUSE_FILTER_PASS
		elif child is Control:
			var control:= child as Control
			if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				control.mouse_filter = Control.MOUSE_FILTER_PASS

		NavigationSceneSupport._install_zero_frame_scroll_passthrough(child)


static func _zero_frame_scroll_step(scroll: ScrollContainer) -> float:
	if scroll == null:
		return 68.0

	var vbar:= scroll.get_v_scroll_bar()
	if vbar == null:
		return 68.0

	return max(68.0, float(vbar.page) * 0.28)


static func _zero_frame_trackpad_scroll_multiplier(scroll: ScrollContainer) -> float:
	if scroll == null:
		return 96.0

	var vbar:= scroll.get_v_scroll_bar()
	if vbar == null:
		return 96.0

	return max(84.0, float(vbar.page) * 0.42)


static func _zero_frame_scroll_by(scroll: ScrollContainer, amount: float) -> void:
	if scroll == null:
		return
	if not is_instance_valid(scroll):
		return

	var vbar:= scroll.get_v_scroll_bar()
	if vbar == null:
		return

	var target_value: float = clamp(
		float(vbar.value) + amount,
		float(vbar.min_value),
		float(vbar.max_value)
	)

	vbar.value = target_value
	scroll.set_meta("zero_frame_scroll_last_input_ms", int(Time.get_ticks_msec()))
	scroll.set_meta("zero_frame_scroll_used_touchpad_or_wheel", true)
	scroll.queue_redraw()


static func _spawn_ready_runtime_hud_hydration_methods() -> Array:


	return []


static func _build_runtime_floating_hud_button_style(
	core_color: Color,
	state: String
) -> StyleBoxFlat:
	var clean_state: String = str(state).strip_edges().to_lower()

	var background: Color = core_color.darkened(0.74)
	var border_alpha: float = 0.64
	var border_width: int = 1
	var shadow_alpha: float = 0.24
	var shadow_size: int = 8

	match clean_state:
		"hover":
			background = core_color.darkened(0.62)
			border_alpha = 0.96
			border_width = 2
			shadow_alpha = 0.48
			shadow_size = 16
		"pressed":
			background = core_color.darkened(0.82)
			border_alpha = 1.0
			border_width = 2
			shadow_alpha = 0.36
			shadow_size = 10
		"focus":
			background = core_color.darkened(0.66)
			border_alpha = 0.92
			border_width = 2
			shadow_alpha = 0.42
			shadow_size = 14
		"disabled":
			background = core_color.darkened(0.84)
			border_alpha = 0.22
			border_width = 1
			shadow_alpha = 0.06
			shadow_size = 3

	background.a = 0.97

	var style:= StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(
		core_color.r,
		core_color.g,
		core_color.b,
		border_alpha
	)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(
		core_color.r,
		core_color.g,
		core_color.b,
		shadow_alpha
	)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0

	return style


static func _runtime_floating_hud_force_key(hud_id: String) -> String:
	return "__runtime_floating_hud_force_keep_open_%s" % str(hud_id).strip_edges().to_lower()


static func _surface_guard_context_allows_render(context: Dictionary = {}) -> bool:
	if typeof(context) != TYPE_DICTIONARY:
		return false

	if bool(context.get("render_surface", false)):
		return true
	if bool(context.get("surface_already_asserted", false)):
		return true
	if bool(context.get("ui_must_not_wait_for_runtime", false)):
		return true
	if bool(context.get("surface_render_contract", false)):
		return true

	var intent: String = str(context.get("intent", context.get("mode", ""))).strip_edges().to_lower()
	if intent in ["render_surface", "surface_click", "open_surface", "assert_surface", "ui_render", "pre_life_surface"]:
		return true

	var source: String = str(context.get("source", "")).strip_edges().to_lower()
	if source.find("surface") >= 0 and source.find("render") >= 0:
		return true
	if source.find("pressed") >= 0 or source.find("clicked") >= 0:
		return true

	return false


static func _runtime_boot_cie_domain_for_action(domain_id: String, action_id: String) -> String:
	var clean_action: String = str(action_id).strip_edges().to_lower()

	if clean_action in ["track_villain", "respond_to_crime", "patrol_city"]:
		return "villains"
	if clean_action in ["recruit_ally", "recruit_sidekick", "start_team"]:
		return "sidekicks"
	if clean_action.find("duel") >= 0 and str(domain_id).strip_edges().to_lower() == "bending":
		return "bending_duels"

	return str(domain_id).strip_edges().to_lower()


static func _runtime_boot_domain_for_hub_action(action: Dictionary, fallback_domain: String, engine_property: String, payload: Dictionary) -> String:
	var clean_engine: String = str(engine_property).strip_edges().to_lower()
	if clean_engine == "power_engine":
		return "powers"
	if clean_engine == "superhero_engine":
		return "superhero"
	if clean_engine == "artifacts_engine":
		return "artifacts"
	if clean_engine == "bending_engine":
		return "bending"

	var action_id: String = str(action.get("id", payload.get("action", ""))).strip_edges().to_lower()

	if action_id.find("crime") >= 0 or action_id.find("villain") >= 0 or action_id.find("patrol") >= 0 or action_id.find("team") >= 0 or action_id.find("ally") >= 0 or action_id.find("register") >= 0:
		return "superhero"

	if action_id.find("power") >= 0 or action_id.find("mutation") >= 0 or action_id.find("training") >= 0 or action_id.find("subskill") >= 0:
		return "powers"

	if action_id.find("artifact") >= 0 or action_id.find("stone") >= 0:
		return "artifacts"

	if action_id.find("bending") >= 0 or action_id.find("dojo") >= 0:
		return "bending"

	return str(fallback_domain).strip_edges().to_lower()


static func _normalize_ui_nav_button_text(button_text: String) -> String:
	var raw: String = str(button_text).strip_edges().to_lower()
	if raw == "":
		return ""

	var compact: String = raw
	compact = compact.replace(" ", "")
	compact = compact.replace("\t", "")
	compact = compact.replace("\n", "")
	compact = compact.replace("
", "")
	compact = compact.replace("_", "")
	compact = compact.replace("-", "")
	compact = compact.replace(":", "")
	compact = compact.replace(".", "")
	compact = compact.replace(",", "")
	compact = compact.replace("!", "")
	compact = compact.replace("?", "")
	compact = compact.strip_edges()

	if compact == "":
		return ""

	if compact.begins_with("profile"):
		return ""

	if compact == "ageup" or compact.begins_with("ageup"):
		return "age_up"

	if compact == "world" or compact.begins_with("world"):
		return "world"

	if compact == "life" or compact.begins_with("life"):
		return "life"

	if compact == "school" or compact.begins_with("school"):
		return "school"

	if compact == "activities" or compact.begins_with("activities"):
		return "activities"

	if compact == "relationships" or compact.begins_with("relationships"):
		return "relationships"

	if compact == "career" or compact.begins_with("career"):
		return "career"
	if compact == "mods" or compact.begins_with("mods"):
		return "mods"
	return ""


static func _first_handled_command_report(report: Dictionary) -> Dictionary:
	var handled_raw: Variant = report.get("handled", [])
	if typeof(handled_raw) == TYPE_ARRAY:
		for raw_handled in handled_raw:
			if typeof(raw_handled) == TYPE_DICTIONARY:
				var handled_report: Dictionary = (raw_handled as Dictionary).duplicate(true)
				if handled_report.has("mode") or handled_report.has("message") or handled_report.has("reason"):
					return handled_report

	var failed_raw: Variant = report.get("failed", [])
	if typeof(failed_raw) == TYPE_ARRAY:
		for raw_failed in failed_raw:
			if typeof(raw_failed) == TYPE_DICTIONARY:
				var failed_report: Dictionary = (raw_failed as Dictionary).duplicate(true)
				if failed_report.has("mode") or failed_report.has("message") or failed_report.has("reason"):
					return failed_report

	return report.duplicate(true)


static func _resident_actor_lens_push_candidate_id(
	raw_id: Variant,
	out: Array,
	seen: Dictionary
) -> void:
	var clean_id: int = int(raw_id)

	if clean_id <= 0:
		return

	if seen.has(clean_id):
		return

	seen [clean_id] = true
	out.append(clean_id)


static func _switch_action_label_for_target(target: Person) -> String:
	if target == null:
		return "SWITCH TO THEM"
	if str(target.gender) == "Male":
		return "SWITCH TO HIM"
	if str(target.gender) == "Female":
		return "SWITCH TO HER"
	return "SWITCH TO THEM"


static func _collect_interactive_surface_authority_candidates(node: Node, out: Array) -> void:
	if node == null:
		return

	for child in node.get_children():
		if child is Control:
			var control_child: Control = child
			if bool(control_child.get_meta("interactive_surface_claimed", false)):
				out.append(control_child)

		NavigationSceneSupport._collect_interactive_surface_authority_candidates(child, out)


static func _prime_panel_transition_surface(surface: Control) -> void:
	if surface == null:
		return
	if not surface.has_meta("ui_panel_transition_base_position"):
		surface.set_meta("ui_panel_transition_base_position", surface.position)
	if not surface.has_meta("ui_panel_transition_base_scale"):
		surface.set_meta("ui_panel_transition_base_scale", surface.scale)
	surface.pivot_offset = surface.size * 0.5


static func _main_tab_default_section_for_panel(panel_id: String) -> String:
	match str(panel_id).strip_edges().to_lower():
		"relationships":
			return "relationships"
		"career":
			return "full_time_jobs"
		"school":
			return "overview"
		"world":
			return "overview"
		"activities":
			return "activities"
		"mods":
			return "installed"
		_:
			return ""


static func _main_tab_panel_uses_native_zero_frame_door(panel_id: String) -> bool:
	var clean_panel: String = str(panel_id).strip_edges().to_lower()
	return clean_panel in ["world", "relationships", "career", "school", "activities", "mods"]


static func _main_tab_label_for_panel(panel_id: String) -> String:
	match str(panel_id).strip_edges().to_lower():
		"life":
			return "LIFE / DIARY"
		"relationships":
			return "RELATIONSHIPS"
		"career":
			return "CAREER"
		"school":
			return "SCHOOL"
		"activities":
			return "ACTIVITIES"
		"world":
			return "WORLD"
		_:
			return "ERALIFE"


static func _main_tab_prewarm_surface_rows() -> Array:
	return [
		{
			"surface_id": "life_panel",
			"active_section_id": "",
			"context": {
				"main_tab": "life",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		},
		{
			"surface_id": "desktop_relationships_panel",
			"active_section_id": "relationships",
			"context": {
				"main_tab": "relationships",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		},
		{
			"surface_id": "desktop_career_panel",
			"active_section_id": "full_time_jobs",
			"context": {
				"main_tab": "career",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		},
		{
			"surface_id": "desktop_school_panel",
			"active_section_id": "overview",
			"context": {
				"main_tab": "school",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		},
		{
			"surface_id": "desktop_activities_panel",
			"active_section_id": "activities",
			"context": {
				"main_tab": "activities",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		},
		{
			"surface_id": "world_feed_panel",
			"active_section_id": "overview",
			"context": {
				"main_tab": "world",
				"packet_contract_required": true,
				"click_path_must_not_build": true
			}
		}
	]


static func _main_tab_uses_desktop_native_renderer(panel_id: String) -> bool:
	var clean_panel: String = str(panel_id).strip_edges().to_lower()

	match clean_panel:
		"life", "world", "relationships", "career", "school", "activities", "mods":
			return true
		_:
			return false


static func _main_tab_hot_surface_key(panel_id: String) -> String:
	return str(panel_id).strip_edges().to_lower()


static func _runtime_focus_navigation_enabled(gs: GameState) -> bool:
	if gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return false

	var guard_raw: Variant = gs.scenario_state.get("runtime_guard", {})
	var guard: Dictionary = guard_raw if typeof(guard_raw) == TYPE_DICTIONARY else {}

	if bool(guard.get("ui_focus_navigation_enabled", false)):
		return true

	var profile_raw: Variant = gs.scenario_state.get("runtime_capability_profile", {})
	var profile: Dictionary = profile_raw if typeof(profile_raw) == TYPE_DICTIONARY else {}

	var device_class: String = str(profile.get("device_class", "")).strip_edges().to_lower()
	var input_mode: String = str(profile.get("input_mode", "")).strip_edges().to_lower()

	return device_class == "smart_tv" or input_mode in ["focus_remote", "remote"]


static func _reset_transient_engine_for_menu_return(engine: Object) -> void:
	if engine == null:
		return

	if engine.has_method("stop_grocery_store_realtime_session"):
		engine.call("stop_grocery_store_realtime_session", "")

	for property_name in [
		"active_runtime_contracts",
		"runtime_contract_index",
		"runtime_contract_observations",
		"public_space_sessions",
		"actor_public_space_sessions",
		"runtime_contract_public_space_keys",
		"movie_theater_sessions_by_actor_id",
		"restaurant_carts_by_actor_id",
		"restaurant_date_state_by_actor_id",
		"restaurant_public_sessions_by_restaurant_id",
		"grocery_carts_by_actor_id",
		"grocery_shopper_sessions_by_store_id",
		"grocery_store_worker_sessions_by_store_id",
		"grocery_self_checkout_sessions_by_actor_id",
		"cached_runtime_rows_by_actor_id",
		"active_sessions",
		"sessions_by_actor_id",
		"last_report"
	]:
		AssetsSceneSupport._clear_dictionary_property_if_present(engine, property_name)

	for property_name in [
		"runtime_contract_mutation_log",
		"visit_ledger",
		"grocery_ledger"
	]:
		AssetsSceneSupport._clear_array_property_if_present(engine, property_name)

	if engine.has_method("reset_runtime"):
		engine.call("reset_runtime")


static func _global_intent_current_actor_id(gs: GameState) -> int:
	if gs == null:
		return -1
	if gs.player != null:
		return int(gs.player.id)
	if "player_id" in gs:
		return int(gs.player_id)
	return -1


static func _get_era_panel_transition_style(gs: GameState) -> Dictionary:
	var era_name: String = ""
	if gs != null and gs.era != null:
		era_name = str(gs.era.name)

	match era_name:
		"Ancient Era":
			return {
				"duration": 0.24,
				"x_distance": 22.0,
				"y_distance": 7.0,
				"start_scale": 0.974
			}
		"Medieval Era":
			return {
				"duration": 0.21,
				"x_distance": 18.0,
				"y_distance": 5.0,
				"start_scale": 0.979
			}
		"Industrial Era":
			return {
				"duration": 0.18,
				"x_distance": 15.0,
				"y_distance": 3.0,
				"start_scale": 0.984
			}
		"Modern Era":
			return {
				"duration": 0.16,
				"x_distance": 12.0,
				"y_distance": 2.0,
				"start_scale": 0.988
			}
		"Future Era":
			return {
				"duration": 0.14,
				"x_distance": 20.0,
				"y_distance": 1.0,
				"start_scale": 0.992
			}
		_:
			return {
				"duration": 0.18,
				"x_distance": 10.0,
				"y_distance": 2.0,
				"start_scale": 0.985
			}


static func _process_realtime_notifications(gs: GameState):
	if gs.pending_death_messages.size() > 0:
		for msg in gs.pending_death_messages:
			EraLog.truth(msg)
		gs.pending_death_messages.clear()


static func _playable_life_viewer_packet_tail_apply_forbidden(packet: Dictionary, reason: String = "") -> bool:
	if typeof(packet) != TYPE_DICTIONARY:
		return true

	var clean_reason: String = str(reason).strip_edges().to_lower()
	if clean_reason.find("relationship_profile_switch") != -1:
		return true
	if clean_reason.find("relationship_switch") != -1:
		return true

	if bool(packet.get("tail_apply_forbidden", false)):
		return true
	if bool(packet.get("relationship_profile_switch_tail_apply_forbidden", false)):
		return true
	if bool(packet.get("switch_packet_fully_consumed_before_modal_close", false)):
		return true

	var render_policy: Dictionary = ValueSceneSupport._safe_dictionary(packet.get("render_policy", {}))
	if bool(render_policy.get("tail_apply_forbidden", false)):
		return true
	if bool(render_policy.get("relationship_profile_switch_tail_apply_forbidden", false)):
		return true
	if bool(render_policy.get("switch_packet_fully_consumed_before_modal_close", false)):
		return true

	var surface: Dictionary = ValueSceneSupport._safe_dictionary(packet.get("surface_contract", {}))
	if bool(surface.get("tail_apply_forbidden", false)):
		return true
	if bool(surface.get("relationship_profile_switch_tail_apply_forbidden", false)):
		return true
	if bool(surface.get("switch_packet_fully_consumed_before_modal_close", false)):
		return true

	return false


static func _locked_zero_frame_switch_surface(gs: GameState) -> Dictionary:
	if gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return {}

	var surface: Dictionary = ValueSceneSupport._safe_dictionary(gs.scenario_state.get("zero_frame_consciousness_switch_surface", {}))
	if surface.is_empty():
		return {}

	if gs.player != null:
		var surface_actor_id: int = int(surface.get("actor_id", -1))
		if surface_actor_id > 0 and surface_actor_id != int(gs.player.id):
			return {}

	return surface.duplicate(true)


static func _main_tab_packet_is_desktop_forbidden(
	packet: Dictionary
) -> bool:
	if typeof(packet) != TYPE_DICTIONARY:
		return true

	var surface_id: String = str(
		packet.get(
			"surface_id",
			packet.get(
				"id",
				""
			)
		)
	).strip_edges().to_lower()
	var source: String = str(
		packet.get(
			"source",
			packet.get(
				"runtime_source",
				""
			)
		)
	).strip_edges().to_lower()
	var shell_kind: String = str(
		packet.get(
			"shell_kind",
			packet.get(
				"platform",
				""
			)
		)
	).strip_edges().to_lower()
	var title: String = str(
		packet.get(
			"title",
			""
		)
	).strip_edges().to_lower()
	var subtitle: String = str(
		packet.get(
			"subtitle",
			""
		)
	).strip_edges().to_lower()
	var description: String = str(
		packet.get(
			"description",
			""
		)
	).strip_edges().to_lower()
	var tags: Array = ValueSceneSupport._safe_array(
		packet.get(
			"tags",
			[]
		)
	)

	if surface_id in [
		"discord_life_hub",
		"relationship_contract_hub",
		"career_contract_hub",
		"school_contract_hub",
		"activity_contract_hub",
		"realm_contract_hub"
	]:
		return true

	if surface_id.begins_with(
		"discord_"
	):
		return true

	if source.find("discord") >= 0:
		return true

	if shell_kind in [
		"discord",
		"discord_remote_shell",
		"remote_discord_shell"
	]:
		return true

	for raw_tag in tags:
		if str(
			raw_tag
		).strip_edges().to_lower().find(
			"discord"
		) >= 0:
			return true

	for text_value in [
		title,
		subtitle,
		description
	]:
		if text_value.find(
			"discord"
		) >= 0:
			return true

	return false


static func _desktop_ui_contract_surface_is_allowed(
	surface_contract: Dictionary
) -> bool:
	if surface_contract.is_empty():
		return false

	if NavigationSceneSupport._main_tab_packet_is_desktop_forbidden(
		surface_contract
	):
		return false

	var platform_scope: String = str(
		surface_contract.get(
			"platform_scope",
			surface_contract.get(
				"shell_scope",
				""
			)
		)
	).strip_edges().to_lower()

	if platform_scope in [
		"discord",
		"discord_only",
		"remote_shell",
		"remote_shell_only"
	]:
		return false

	return true


static func _main_tab_packet_is_renderable(packet: Dictionary) -> bool:
	if typeof(packet) != TYPE_DICTIONARY:
		return false
	if packet.is_empty():
		return false
	if NavigationSceneSupport._main_tab_packet_is_desktop_forbidden(packet):
		return false
	if not bool(packet.get("success", false)):
		return false
	if not bool(packet.get("ui_safe", false)):
		return false
	if str(packet.get("contract_status", "")) != "satisfied":
		return false
	return true


static func _runtime_hud_snapshot_flag(gs: GameState,
	key: String, fallback: bool = false) -> bool:
	if gs == null or typeof(gs.scenario_state) != TYPE_DICTIONARY:
		return fallback

	var snapshot: Dictionary = ValueSceneSupport._safe_dictionary(gs.scenario_state.get("runtime_hud_visibility_snapshot", {}))
	if snapshot.is_empty():
		return fallback

	return bool(snapshot.get(key, fallback))
