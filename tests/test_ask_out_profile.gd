extends SceneTree

class ProfileScene extends "res://scenes/MainScene.gd":
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _notification(_what: int) -> void:
		pass

var failed := false
const ASK_OUT := "relationship_contract:ask_out"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func offers(hub: RelationshipsHubContractEngine, actor: Person, target: Person, action_id := ASK_OUT) -> bool:
	for action in hub._profile_actions_for_target(actor, target, "Stranger"):
		if action.get("action_id") == action_id:
			return action.target_id == target.id
	return false

func _run() -> void:
	var state := GameState.create_resident_chassis_shell()
	var actor := Person.new()
	var target := Person.new()
	actor.id = 41
	target.id = 42
	actor.gender = "Male"
	target.gender = "Female"
	actor.age = 21
	target.age = 20
	state.player = actor
	state.player_id = actor.id
	state.npcs = [actor, target]
	state._rebuild_npc_index()
	state.relationship_activities_engine = RelationshipActivitiesEngine.new(state)
	state.reality_projection_contract_engine = RealityProjectionContractEngine.new(state)
	state.narrative_engine = NarrativeEngine.new(state)
	state.relationship_engine = RelationshipEngine.new(state)
	var hub := RelationshipsHubContractEngine.new(state)
	state.relationships_hub_contract_engine = hub
	var activity: RelationshipActivitiesEngine = state.relationship_activities_engine
	check(offers(hub, actor, target), "The full profile of a single adult acquaintance lacks Ask Out")
	target.parents = [actor.id]
	check(not offers(hub, actor, target), "A parent can ask out their child")
	target.parents = [300]
	actor.parents = [301]
	state.dormant_npcs[300] = {"id": 300, "parents": [302]}
	state.dormant_npcs[301] = {"id": 301, "parents": [302]}
	actor.friends = [target.id]
	check(not offers(hub, actor, target), "A cousin with a friendship and dormant parents can be asked out")
	check(state.dormant_npcs.has(300) and state.dormant_npcs.has(301), "Checking kinship woke a dormant parent")
	target.parents.clear()
	actor.parents.clear()
	actor.friends.clear()
	target.age = 17
	check(not offers(hub, actor, target), "An adult can ask out a minor")
	target.age = 20
	target.alive = false
	check(not offers(hub, actor, target), "A deceased acquaintance can be asked out")
	target.alive = true
	var existing_partner := Person.new()
	existing_partner.id = 43
	target.partner = existing_partner
	existing_partner.partner = target
	check(not offers(hub, actor, target), "A partnered target still offers Ask Out")
	var stale := activity.resolve_relationship_action(actor, target, ASK_OUT)
	check(not stale.get("success", false) and target.partner == existing_partner and actor.partner == null,
		"A stale profile action displaced an existing partner")
	target.partner = null
	existing_partner.partner = null
	# Use fixed consent rolls so both decisions exercise the published command.
	seed(1)
	var declined := activity.resolve_relationship_action(actor, target, ASK_OUT)
	check(str(declined.get("popup_text", "")).contains("rejected") and actor.partner == null and target.partner == null,
		"A declined invitation changed the couple")
	var projection: RealityProjectionContractEngine = state.reality_projection_contract_engine
	check(not projection.has_meta("resident_relationship_section_refresh_jobs"), "A refusal queued a partner change")
	seed(3)
	var accepted := activity.resolve_relationship_action(actor, target, ASK_OUT)
	check(accepted.get("popup_title") == "Ask Out" and actor.partner == target and target.partner == actor,
		"An accepted invitation did not create the chosen reciprocal partnership")
	check(not offers(hub, actor, target) and offers(hub, actor, target, "relationship_contract:try_for_baby"),
		"The new partner profile did not replace the invitation with the family action")
	var jobs: Dictionary = projection.get_meta("resident_relationship_section_refresh_jobs", {})
	for section in ["partner", "household", "family"]:
		check(jobs.has("%d:%s" % [actor.id, section]), "Acceptance left the resident %s tab stale" % section)
	check_restored_partner_section(state, actor, target)
	if not failed:
		print("ASK OUT PROFILE TESTS: PASS")
	quit(int(failed))

func check_restored_partner_section(state: GameState, actor: Person, target: Person) -> void:
	var projection: RealityProjectionContractEngine = state.reality_projection_contract_engine
	var scene := ProfileScene.new()
	var container := Control.new()
	container.name = "UIContainer"
	scene.add_child(container)
	var output := RichTextLabel.new()
	output.name = "OutputLabel"
	container.add_child(output)
	root.add_child(scene)
	scene.gs = state
	scene.reality_residency_attached_signature = "restored-founder"
	scene.relationship_hub_panel = RelationshipHubPanel.new()
	scene.add_child(scene.relationship_hub_panel)
	scene.relationship_hub_panel.active_actor_id = actor.id
	scene.relationship_hub_panel.active_contract = {"actor_id": actor.id, "active_section_id": "partner",
		"surface_revision": "%d:%d:partner:prior" % [actor.id, state.year]}
	# Checkpoint attachment keeps the section producer and rebinds its GameState.
	var old_host := GameState.create_resident_chassis_shell()
	old_host.year = state.year
	old_host.reality_projection_contract_engine = projection
	projection.gs = old_host
	scene._bind_resident_relationship_section_signal(old_host)

	var other_state := GameState.create_resident_chassis_shell()
	other_state.year = state.year
	other_state.player = Person.new()
	other_state.player.id = actor.id
	other_state.player_id = actor.id
	other_state.reality_projection_contract_engine = RealityProjectionContractEngine.new(other_state)
	scene._bind_resident_relationship_section_signal(other_state)
	var other_packet := {"surface_revision": "%d:%d:partner" % [actor.id, state.year]}
	other_state.reality_projection_contract_engine.resident_relationship_section_contract_ready.emit(
		"", actor.id, "partner", other_packet
	)
	check(not scene.has_meta("resident_main_tab_surface_contracts"), "A second unsigned runtime replaced the active Partner tab")
	projection.resident_relationship_section_contract_ready.emit("", actor.id, "partner", other_packet)
	check(not scene.has_meta("resident_main_tab_surface_contracts"), "A producer still attached to the old host changed the current tab")
	projection.gs = state
	var stale_packet := {"surface_revision": "%d:%d:partner" % [actor.id, state.year - 1]}
	projection.resident_relationship_section_contract_ready.emit("", actor.id, "partner", stale_packet)
	check(not scene.has_meta("resident_main_tab_surface_contracts"), "A stale-year Partner section replaced the active tab")
	var partner_ids := []
	projection.resident_relationship_section_contract_ready.connect(
		func(_signature: String, actor_id: int, section: String, packet: Dictionary) -> void:
			if actor_id == actor.id and section == "partner":
				for group in packet.get("groups", []):
					for card in group.get("cards", []):
						partner_ids.append(card.get("target_id", -1))
	)
	for step in 16:
		projection._service_resident_relationship_section_refresh_queue()
		if target.id in partner_ids:
			break
	check(target.id in partner_ids, "The refreshed resident Partner tab omitted the accepted partner")
	var surfaces: Dictionary = scene.get_meta("resident_main_tab_surface_contracts", {})
	var installed: Dictionary = surfaces.get("relationships", {}).get("section_contracts", {}).get("partner", {})
	var installed_ids := []
	for group in installed.get("groups", []):
		for card in group.get("cards", []):
			installed_ids.append(card.get("target_id", -1))
	check(target.id in installed_ids, "Cold Continue discarded the current runtime's updated partner card")
	# A restored actor can age while the last rendered tab still shows last year.
	state.year += 1
	state.scenario_state["reality_residency_signature"] = ""
	state.scenario_state["god_mode_life_prewarm_signature"] = ""
	state.scenario_state["resident_runtime_attached_signature"] = scene.reality_residency_attached_signature
	var signature := projection._runtime_signature(state)
	check(signature == scene.reality_residency_attached_signature, "Blank prewarm identity hid the attached runtime signature")
	var next_year_packet := {"surface_revision": "%d:%d:partner:renewed" % [actor.id, state.year], "groups": installed.groups}
	projection.resident_relationship_section_contract_ready.emit(signature, actor.id, "partner", next_year_packet)
	var renewed: Dictionary = scene.get_meta("resident_main_tab_surface_contracts", {}).get("relationships", {}).get("section_contracts", {}).get("partner", {})
	check(renewed.get("surface_revision") == next_year_packet.surface_revision, "A visible tab from last year discarded the current signed partner card")
	scene.free()
