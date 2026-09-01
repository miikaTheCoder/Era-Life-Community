extends SceneTree

var failed := false


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _person(person_id: int, age: int, ambition: int = 60) -> Person:
	var person := Person.new()
	person.id = person_id
	person.first_name = "Resident"
	person.last_name = str(person_id)
	person.age = age
	person.alive = true
	person.health = 90.0
	person.smarts = 90
	person.willpower = 82.0
	person.ambition = ambition
	person.birth_city = "New Arcadia"
	person.home_city = "New Arcadia"
	person.birth_country = "Testland"
	person.home_country = "Testland"
	person.district_id = "Harbor Ward"
	return person


func _run() -> void:
	var state := GameState.new()
	state.scenario_state = {}
	state.year = 2005
	state.era = {"name": "Modern Era"}
	state.player = _person(1, 27, 88)
	state.player_id = state.player.id
	state.npcs = [state.player]
	for index in range(12):
		state.npcs.append(_person(index + 10, 24 + index, 50 + index * 3))
	state._rebuild_npc_index()

	state.universal_faction_engine = UniversalFactionEngine.new(state)
	state.bank_engine = BankEngine.new(state)
	state.property_engine = PropertyEngine.new(state)
	state.property_engine.properties[state.player.id] = [
		{
			"id": 7001,
			"nickname": "Harbor Street Café",
			"type": "commercial_property",
			"value": 180000
		}
	]
	state.crime_world_engine = CrimeWorldEngine.new(state)
	state.simulation_director = SimulationDirector.new(state)
	state.simulation_director.register_default_runtime_listeners()
	var core_listeners: Array = state.simulation_director.runtime_phase_registry.get(
		SimulationDirector.PHASE_CORE_STATE,
		[]
	)
	var crime_listener: Dictionary = {}
	var faction_listener: Dictionary = {}
	for listener in core_listeners:
		if str(listener.get("id", "")) == "crime_world_engine.yearly_tick":
			crime_listener = listener
		elif str(listener.get("id", "")) == "universal_faction_engine.yearly_core_resolution":
			faction_listener = listener
	_check(not crime_listener.is_empty(), "Crime World was not registered in the yearly simulation")
	_check(
		faction_listener.get("meta", {}).get("depends_on", []).has("crime_world_engine.yearly_tick"),
		"Universal faction simulation can run before Crime World projects its organizations"
	)

	var owner_id: String = state.bank_engine.owner_key_from_actor(state.player)
	state.bank_engine.credit_cash(
		owner_id,
		100000.0,
		"local.world",
		"USD",
		{"text": "Crime World test funding."},
		{"actor_id": state.player.id, "source": "test_crime_world"}
	)
	var money_before: float = float(
		state.bank_engine.get_owner_summary_for_actor(state.player).get("total_accessible", 0.0)
	)
	var spend_report: Dictionary = state.bank_engine.request_actor_bank_action(
		state.player,
		{"action": "spend", "amount": 1000, "reason": "test_payment"},
		{"source": "test_crime_world"}
	)
	var money_after: float = float(
		state.bank_engine.get_owner_summary_for_actor(state.player).get("total_accessible", 0.0)
	)
	_check(bool(spend_report.get("success", false)), "BankEngine rejected an affordable Crime World payment")
	_check(is_equal_approx(money_before - money_after, 1000.0), "BankEngine spend did not debit the authoritative balance")

	var boot: Dictionary = state.crime_world_engine.bootstrap_world()
	_check(bool(boot.get("success", false)), "Crime World failed to bootstrap")
	_check(int(boot.get("organization_count", 0)) == 2, "Modern Era did not create both organized-crime factions")
	var organizations: Array = state.crime_world_engine.get_organizations_for_actor(state.player)
	_check(organizations.size() == 2, "Crime World organization registry lost an era faction")
	_check(state.universal_faction_engine.faction_contract_registry.size() == 2, "Organizations were not projected into UniversalFactionEngine")

	var first_members: Dictionary = organizations[0].get("members", {})
	var second_members: Dictionary = organizations[1].get("members", {})
	_check(first_members.size() == 6 and second_members.size() == 6, "Organizations did not receive real NPC rosters")
	for member_id in first_members.keys():
		_check(not second_members.has(member_id), "An NPC was assigned to two rival organizations")
	_check(not organizations[0].get("territory_ids", []).is_empty(), "Organization territory was not persisted")

	var organization_id: String = str(organizations[0].get("id", ""))
	var jobs_before: int = 0
	var profile: Dictionary = state.crime_world_engine.get_actor_profile(state.player)
	jobs_before = int(profile.get("successful_jobs", 0)) + int(profile.get("failed_jobs", 0))
	var job_report: Dictionary = state.crime_world_engine.perform_job(
		state.player,
		organization_id,
		"deliver_message"
	)
	profile = state.crime_world_engine.get_actor_profile(state.player)
	var jobs_after: int = int(profile.get("successful_jobs", 0)) + int(profile.get("failed_jobs", 0))
	_check(str(job_report.get("mode", "")) == "crime_world_job_resolved", "Underworld job did not resolve through CrimeWorldEngine")
	_check(jobs_after == jobs_before + 1, "Underworld job outcome was not persisted")

	var mutable_state: Dictionary = state.crime_world_engine.export_state()
	profile = mutable_state.get("actor_profiles", {}).get(str(state.player.id), {})
	profile["connected_organization_id"] = organization_id
	profile["rank_id"] = "connected"
	profile["underworld_reputation"] = 35
	profile["successful_jobs"] = 5
	mutable_state["actor_profiles"][str(state.player.id)] = profile
	state.crime_world_engine.import_state(mutable_state)
	var join_report: Dictionary = state.crime_world_engine.join_organization(state.player, organization_id)
	var promotion_report: Dictionary = state.crime_world_engine.request_promotion(state.player)
	profile = state.crime_world_engine.get_actor_profile(state.player)
	_check(bool(join_report.get("success", false)), "Connected player could not join an organization")
	_check(bool(promotion_report.get("success", false)), "Qualified Associate could not be promoted")
	_check(str(profile.get("rank_id", "")) == "soldier", "Rank progression did not reach Soldier")

	var racket_report: Dictionary = state.crime_world_engine.generate_extortion_demand(state.player, true)
	_check(bool(racket_report.get("success", false)), "Owned commercial property did not surface an extortion story")
	var extortion_case: Dictionary = racket_report.get("extortion_case", {})
	_check(int(extortion_case.get("annual_payment", 0)) > 0, "Extortion demand has no economic consequence")
	var response: Dictionary = state.crime_world_engine.respond_to_extortion(
		state.player,
		str(extortion_case.get("case_id", "")),
		"refuse"
	)
	_check(bool(response.get("success", false)), "Extortion refusal did not resolve")
	state.year += 1
	var yearly_report: Dictionary = state.crime_world_engine.yearly_tick()
	var post_year_state: Dictionary = state.crime_world_engine.export_state()
	var post_year_case: Dictionary = post_year_state.get("extortion_cases", {}).get(
		str(extortion_case.get("case_id", "")),
		{}
	)
	_check(bool(yearly_report.get("success", false)), "Crime World yearly simulation failed")
	_check(str(post_year_case.get("status", "")) in ["retaliated", "abandoned"], "Refused extortion did not produce a delayed consequence")

	var underworld_rows: Array = state.crime_world_engine.build_section_rows(state.player, "underworld")
	var organization_rows: Array = state.crime_world_engine.build_section_rows(state.player, "organizations")
	var racket_rows: Array = state.crime_world_engine.build_section_rows(state.player, "rackets")
	_check(not underworld_rows.is_empty(), "Crime Hub underworld rows are empty")
	_check(organization_rows.size() == 2, "Crime Hub does not expose both organizations")
	_check(not racket_rows.is_empty(), "Crime Hub rackets section is empty")

	state.crime_hub_contract_engine = CrimeHubContractEngine.new(state)
	var tab_ids: Array = state.crime_hub_contract_engine._section_tabs(false).map(
		func(tab: Dictionary): return str(tab.get("id", ""))
	)
	_check(tab_ids.has("underworld") and tab_ids.has("organizations") and tab_ids.has("rackets"), "Crime Hub tabs do not expose Crime World")
	var hub_route: Dictionary = state.crime_hub_contract_engine.resolve_intent(
		state.player,
		{"action_id": "crime_world_refresh", "section_id": "underworld"}
	)
	_check(bool(hub_route.get("success", false)), "Crime Hub could not route a Crime World intent")
	_check(str(hub_route.get("crime_hub_section", "")) == "underworld", "Crime World action returned to the wrong Crime Hub section")
	_check(not hub_route.get("section_contract", {}).is_empty(), "Crime World action did not refresh its resident UI surface")

	var binary_state: Dictionary = BinarySaveEngine.decode(
		BinarySaveEngine.encode(state.crime_world_engine.export_state())
	)
	state.scenario_state.erase(CrimeWorldEngine.STATE_KEY)
	state.crime_world_engine = CrimeWorldEngine.new(state)
	var import_report: Dictionary = state.crime_world_engine.import_state(binary_state)
	var restored_profile: Dictionary = state.crime_world_engine.get_actor_profile(state.player)
	_check(bool(import_report.get("success", false)), "Crime World state could not be re-imported")
	_check(state.crime_world_engine.get_organizations_for_actor(state.player).size() == 2, "Save round-trip lost organizations")
	_check(str(restored_profile.get("rank_id", "")) == "soldier", "Save round-trip lost membership rank")

	print("CRIME WORLD TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
