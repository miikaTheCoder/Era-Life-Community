extends "test_living_households.gd"

const PARTNER := "partner_futures"
const MEMORY := "partner_futures_legacy"
var partner_responses := 0

class ExtraTraitOption extends TraitsContractEngine:
	func trait_action_options_for_actor(_actor: Person, _source: Dictionary, options: Array, _context: Dictionary = {}) -> Array:
		var expanded := options.duplicate(true)
		expanded.append({"id":"fixture_trait", "label":"An extra trait response"})
		return expanded

func _couple() -> GameState:
	var state := _household_fixture()
	state.player.job = ""
	return state

func _start_partner(state: GameState) -> Dictionary:
	_only(state, PARTNER)
	state.scenario_runtime_contract_engine.service_life_stories()
	return _record_for(state, PARTNER)

func _tick(state: GameState) -> void:
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _partner_node(state: GameState, record: Dictionary, node: String) -> void:
	_chapter(state, record, node)

func _snapshot(state: GameState, record: Dictionary) -> String:
	return JSON.stringify([record, state.player.affection, state.get_npc_by_id(103, false).affection,
		state.player.mental_health, state.player.smarts, state.player.memories,
		state.life_diary_contract_engine.diary_entries_for_actor(state.player_id),
		state.player.bank_balance, state.get_npc_by_id(103, false).bank_balance])

func _run() -> void:
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty(), "Partner catalog invalid: " + str(engine.content_errors))
	var ids := engine.catalog.map(func(row): return str(row.id))
	for path in ["life_stories", "shared_lives", "living_households", "sibling_stories", "partner_stories"]:
		for definition in JSON.parse_string(FileAccess.get_file_as_string("res://data/" + path + ".json")).stories:
			_check(str(definition.id) in ids, "Full catalog lost " + str(definition.id))
	_check(ids.size() == 18 and ids[12] == PARTNER and ids[13] == MEMORY, "Partner pack changed old priority")
	_test_partner_responses(engine)
	_test_partner_routes()
	_test_partner_admission()
	_test_partner_trust()
	_test_partner_money()
	_test_partner_interruptions()
	_test_established_separation()
	_test_story_choice_views()
	_test_partner_rejected_actions()
	_test_partner_memory()
	_test_partner_binary()
	print("PARTNER STORIES TESTS: ", "FAIL" if failed else "PASS", "; responses=", partner_responses)
	quit(1 if failed else 0)

func _test_partner_responses(engine: LifeStoryEngine) -> void:
	for definition in engine.catalog.filter(func(row): return row.get("series", "") == "Partner Stories"):
		for node_id in definition.nodes:
			for choice in definition.nodes[node_id].choices:
				var state := _couple()
				var record := _start_partner(state)
				if definition.id == MEMORY:
					record.status = "finished"
					record.legacy = "separate_pursuits"
					_child_memory(state)
					record = _record_for(state, MEMORY)
				_partner_node(state, record, node_id)
				var pending := _pending(state, definition.id)
				_check(not pending.is_empty() and not str(pending.get("overview", "")).contains("{person}"), "Partner chapter not rendered")
				_check_authored_view(state, pending)
				_check(_resolve(state, definition.id, choice.id).get("success", false), "Partner response failed: " + node_id + "/" + choice.id)
				var after := _snapshot(state, record)
				_check(not state.scenario_runtime_contract_engine.resolve_popup_contract(pending.id, choice.id, {"viewer_actor_id":state.player_id}).get("success", true), "Duplicate partner click accepted")
				_check(_snapshot(state, record) == after, "Duplicate click had effects")
				partner_responses += 1
	_check(partner_responses == 26, "Not all partner responses tested")
	for mutation in ["trust", "separation", "cast", "delay"]:
		var story: Dictionary = engine._definition(PARTNER).duplicate(true)
		match mutation:
			"trust": story.trust_from = "unknown"
			"separation": story.separation_node = "missing"
			"cast": story.cast = "invented_partner"
			"delay": story.nodes.notebook.choices[0].delay = 0
		_check(not LifeStoryEngine.validate_catalog({"schema":"eralife.life_stories", "version":1, "stories":[story]}).is_empty(), "Malformed selector/target accepted: " + mutation)

func _test_partner_routes() -> void:
	var routes := [["listen", "join", "renew"], ["materials", "practical", "room"], ["space", "respect", "name"], ["income", "account", "room"], ["income", "insist"], ["space", "respect", "private"], ["listen", "limited", "condition", "leave", "room"], ["listen", "join", "release"]]
	var outcomes := ["shared_by_invitation", "separate_pursuits", "control_reconsidered", "separate_pursuits", "unresolved_pressure", "private", "separate_pursuits", "invitation_released"]
	for i in range(routes.size()):
		var state := _couple()
		_await_chapter(state, PARTNER)
		var record := _record_for(state, PARTNER)
		var start: int = state.year
		for choice in routes[i]:
			_await_chapter(state, PARTNER)
			_check(_resolve(state, PARTNER, choice).get("success", false), "Complete partner route failed")
		_check(record.status == "finished" and record.legacy == outcomes[i] and record.history.size() == routes[i].size(), "Partner route lost outcome")
		_check(state.year - start >= 2, "Partner route has no delayed consequence")
		var prior := JSON.stringify(record)
		for year in range(3):
			_year(state, PARTNER)
		_check(JSON.stringify(record) == prior, "Finished partner story replayed")
		print("PARTNER CONTRACT ROUTE: ", routes[i], " start=", start, " finished=", record.finished_year, " outcome=", record.legacy)

func _test_partner_admission() -> void:
	for invalid in ["absent", "minor", "self", "deceased", "nonreciprocal", "actor_minor", "actor_old", "loading"]:
		var state := _couple()
		match invalid:
			"absent": state.player.partner = null
			"minor": state.player.partner.age = 17
			"self": state.player.partner = state.player
			"deceased": state.player.partner.alive = false
			"nonreciprocal": state.player.partner.partner = null
			"actor_minor": state.player.age = 17
			"actor_old": state.player.age = 86
			"loading": state.scenario_state.background_hydration_active = true
		_check(_start_partner(state).is_empty(), "Invalid partner admitted: " + invalid)
	for gate in ["cap", "cooldown"]:
		var state := _couple()
		var engine := state.scenario_runtime_contract_engine._ensure_life_story_engine() as LifeStoryEngine
		var profile := engine._actor_state(state.player_id)
		if gate == "cooldown":
			profile.last_start_year = state.year
		else:
			for id in ["household_balance", "family_business"]:
				profile.stories[id] = {"status":"waiting", "cast_id":103, "cast_name":"Casey Story", "due_year":2100}
		_tick(state)
		_check(_record_for(state, PARTNER).is_empty(), "Partner bypassed " + gate)
	for age in [18, 85]:
		var state := _couple()
		state.player.age = age
		state.player.parents = []
		state.player.children = []
		state.get_npc_by_id(106, false).parents = []
		state.player.friends = []
		state.player.coworkers = []
		state.player.bank_balance = 0
		state.crime_world_engine = null
		_tick(state)
		_check(not _record_for(state, PARTNER).is_empty(), "Childless unmarried unemployed poor couple excluded")
		_check(state.scenario_runtime_contract_engine.life_story_engine.catalog.size() == 18, "Minimal couple discovery filtered catalog")

func _test_partner_trust() -> void:
	for trust in [44, 45, 46]:
		var state := _couple()
		var record := _start_partner(state)
		_partner_node(state, record, "first_attempt")
		state.player.affection[103] = 5 if trust >= 45 else 95
		state.player.partner.affection[101] = trust
		_check(_resolve(state, PARTNER, "join").get("success", false), "Trust choice failed")
		_check(record.node == ("refusal" if trust < 45 else "shared_close"), "Trust used actor side or wrong boundary")
	# Prove pre-effect evaluation even with the no-engine reciprocal fallback.
	var state := _couple()
	var record := _start_partner(state)
	_partner_node(state, record, "first_attempt")
	state.relationship_engine = null
	state.player.partner.affection[101] = 44
	_resolve(state, PARTNER, "join")
	_check(record.node == "refusal" and state.player.partner.affection[101] == 46, "Effect bought consent at threshold")
	# Missing selector preserves the version 1 player-side, post-effect rule.
	var old := _couple()
	var old_record := _start_partner(old)
	_partner_node(old, old_record, "first_attempt")
	old.scenario_runtime_contract_engine.life_story_engine._definition(PARTNER).erase("trust_from")
	old.player.affection[103] = 44
	old.player.partner.affection[101] = 5
	_resolve(old, PARTNER, "join")
	_check(old_record.node == "shared_close", "Default trust no longer uses player side after effects")

func _test_partner_money() -> void:
	for node in ["notebook", "first_attempt"]:
		var choice := "materials" if node == "notebook" else "practical"
		var cost := 150 if node == "notebook" else 75
		for failure in ["frozen", "poor", "recipient_frozen"]:
			var state := _couple()
			var record := _start_partner(state)
			_partner_node(state, record, node)
			var actor_account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
			var cast_account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player.partner, {"import_legacy_balance":true})
			if failure == "poor":
				state.bank_engine.spend(state.bank_engine.owner_key_from_actor(state.player), 10000)
			else:
				state.bank_engine.set_account_status(actor_account.account_id if failure == "frozen" else cast_account.account_id, "frozen")
			var before := _snapshot(state, record)
			_check(not _resolve(state, PARTNER, choice).get("success", true), "Invalid payment accepted: " + failure)
			_check(_snapshot(state, record) == before, "Failed payment changed state")
			_check(_resolve(state, PARTNER, "space" if node == "notebook" else "limited").get("success", false), "Free alternative unavailable")
		var state := _couple()
		var business := _found(state)
		var company := _business(state, business)
		state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
		state.year += 2
		var record := _start_partner(state)
		_partner_node(state, record, node)
		var reserves := FamilyBusinessEngine.new(state).balance(company)
		var total: int = state.player.bank_balance + state.player.partner.bank_balance
		var before: int = state.player.bank_balance
		var trust: int = state.player.partner.affection[101]
		_check(_resolve(state, PARTNER, choice).get("success", false), "Personal transfer failed")
		_check(state.player.bank_balance == before - cost and state.player.bank_balance + state.player.partner.bank_balance == total, "Transfer did not conserve funds")
		_check(FamilyBusinessEngine.new(state).balance(company) == reserves and state.player.partner.affection[101] == trust, "Money bought trust or used company funds")
	for era in ["Ancient Era", "Future Era"]:
		var state := _couple()
		state.era.name = era
		var record := _start_partner(state)
		var cost := 30 if era == "Ancient Era" else 225
		_check(str(_pending(state, PARTNER).response_options).contains(str(cost)), "Price hidden")
		state.era.name = "Modern Era"
		_resolve(state, PARTNER, "materials")
		_check(state.player.bank_balance == 10000 - cost and record.scale != 1, "Saved price changed with era")

func _test_partner_interruptions() -> void:
	var state := _couple()
	var record := _start_partner(state)
	var cast := state.player.partner
	state.npcs.erase(cast)
	state._rebuild_npc_index()
	var before := JSON.stringify(record)
	_check(not _resolve(state, PARTNER, "materials").get("success", true), "Unloaded cast accepted money")
	state.year = int(record.deadline_year) + 2
	_tick(state)
	_check(JSON.stringify(record) == before, "Unloaded cast triggered deadline or substitution")
	state.npcs.append(cast)
	state._rebuild_npc_index()
	_tick(state)
	_tick(state)
	_check(record.history.size() == 1 and record.history[0].choice == "space" and record.history[0].automatic, "Return did not resume default exactly once")
	for interruption in ["breakup", "remarriage", "death", "loading", "partial"]:
		state = _couple()
		record = _start_partner(state)
		cast = state.player.partner
		var pending := _pending(state, PARTNER)
		if interruption == "breakup":
			state.end_partnership(state.player, true)
		state.player.partner = null
		cast.partner = null
		match interruption:
			"remarriage":
				state.player.partner = state.get_npc_by_id(104, false)
				state.player.partner.partner = state.player
			"death":
				state.player.ex_partners.append(cast.id)
				cast.alive = false
			"loading":
				state.player.ex_partners.append(cast.id)
				state.scenario_state.loading_runtime = {"active":true}
		before = _snapshot(state, record)
		_check(not _resolve(state, PARTNER, "materials").get("success", true), "Stale paid option accepted: " + interruption)
		_check(state.player.bank_balance == 10000 and record.history.is_empty(), "Stale option spent money or wrote history")
		_tick(state)
		if interruption in ["loading", "partial"]:
			_check(_snapshot(state, record) == before, "Partial restoration inferred breakup")
			continue
		_check(record.cast_id == 103 and record.node == ("loss" if interruption == "death" else "separation"), "Interruption lost precedence/cast")
		_check(not state.scenario_runtime_contract_engine.active_popup_contracts.has(pending.id), "Stale projection retained")
		_check(_resolve(state, PARTNER, "remember" if interruption == "death" else "release").get("success", false), "Interruption cannot finish")
		_check(record.status == "finished", "Interruption incomplete")
	# Death after a surfaced separation still takes precedence.
	state = _couple()
	record = _start_partner(state)
	cast = state.player.partner
	state.player.ex_partners.append(cast.id)
	state.player.partner = null
	cast.partner = null
	_tick(state)
	cast.alive = false
	state.year += 1
	_tick(state)
	_check(record.node == "loss", "Death did not supersede separation")

func _child_memory(state: GameState, full := false) -> void:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	var parent := state.player
	state.player = state.get_npc_by_id(106, false)
	_check(state.player.age >= 18 and parent.children.has(state.player.id) and state.player.parents.has(parent.id), "Inheritance fixture requires an actual reciprocal adult child")
	state.player_id = state.player.id
	state.register_controlled_character(state.player_id)
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	if not full:
		_only(state, MEMORY)
	_tick(state)

func _test_partner_memory() -> void:
	for outcome in ["separate_pursuits", "partnership_ended", "private", "unfinished"]:
		var state := _couple()
		var source := _start_partner(state)
		if outcome == "partnership_ended":
			state.player.ex_partners.append(103)
			state.player.partner.partner = null
			state.player.partner = null
			_tick(state)
			_resolve(state, PARTNER, "release")
		elif outcome != "unfinished":
			for choice in ["space", "respect", "private" if outcome == "private" else "room"]:
				if _pending(state, PARTNER).is_empty():
					_advance_to_due(state, PARTNER)
				_resolve(state, PARTNER, choice)
		var before := JSON.stringify(source)
		state.get_npc_by_id(103, false).alive = false
		_child_memory(state)
		if outcome in ["unfinished", "private"]:
			_check(_record_for(state, MEMORY).is_empty(), "Private/unfinished story inherited")
		else:
			var inherited := _record_for(state, MEMORY)
			_check(inherited.cast_id == 103 and inherited.origin == PARTNER and inherited.origin_legacy == outcome, "Child lost original partner or actual outcome")
			_check(str(_pending(state, MEMORY).overview).contains(source.outcome), "Actual public outcome not readable")
			_resolve(state, MEMORY, "preserve")
			_check(inherited.origin_legacy == outcome, "Child overwrote origin legacy")
		_check(JSON.stringify(source) == before, "Child rewrote parent record")
	var state := _couple()
	_await_chapter(state, PARTNER)
	for choice in ["income", "insist"]:
		_await_chapter(state, PARTNER)
		_resolve(state, PARTNER, choice)
	_child_memory(state, true)
	_await_chapter(state, MEMORY)
	_check(_resolve(state, MEMORY, "adapt").get("success", false), "Full-catalog child memory unreachable")

func _test_partner_binary() -> void:
	var state := _couple()
	var record := _start_partner(state)
	_resolve(state, PARTNER, "materials")
	# Optional fields absent in version 1 remain supported; unknown packs survive.
	record.erase("ensemble")
	record.erase("context")
	state.scenario_state.life_stories.actors["101"].stories["future_pack"] = {"status":"waiting", "opaque":[1,2,3]}
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	var restored := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	RealityResidencyManager.new(restored)._materialize_checkpoint_resume_shell(restored, {"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "partner-checkpoint", {})
	restored.era = {"name":payload.era_name}
	restored.bank_engine = BankEngine.new(restored)
	var hydration := GameStateHydrationRuntime.new(restored)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]}, {"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	for step in range(20000):
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	_check(not hydration.is_background_hydration_active(), "Partner binary hydration did not complete")
	_check(JSON.parse_string(JSON.stringify(restored.scenario_state.life_stories)) == payload.scenario_state.life_stories, "Binary restore changed story records")
	for id in [101,103]:
		var original := state.get_npc_by_id(id, false)
		var person := restored.get_npc_by_id(id, false)
		_check(person != null and person.partner != null and person.partner.id == original.partner.id, "Binary restore lost partner link")
		_check(person.bank_balance == original.bank_balance and JSON.parse_string(JSON.stringify(person.affection)) == JSON.parse_string(JSON.stringify(original.affection)), "Binary restore lost funds or directed affection")
	restored.resident_runtime_bootstrap_complete = true
	restored.relationship_engine = RelationshipEngine.new(restored)
	restored.memory_engine = MemoryEngine.new(restored)
	restored.life_diary_contract_engine = LifeDiaryContractEngine.new(restored)
	restored.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(restored)
	restored.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(restored)
	restored.pending_situations_engine = PendingSituationsEngine.new(restored)
	_only(restored, PARTNER)
	_advance_to_due(restored, PARTNER)
	_check(_resolve(restored, PARTNER, "join").get("success", false), "Old optional fields prevented continuation")
	_check(JSON.parse_string(JSON.stringify(_record_for(restored, "future_pack"))) == JSON.parse_string('{"status":"waiting", "opaque":[1,2,3]}'), "Unknown record changed")


func _check_authored_view(state: GameState, source: Dictionary) -> void:
	state.traits_contract_engine = ExtraTraitOption.new(state)
	var builder := ContractViewLayerContractEngine.new(state)
	var view := builder.build_view_contract(source, state.player)
	_check(view.get("response_options", []) == source.response_options, "Completed Life Story view added responses its source cannot resolve")
	var cached := builder.build_view_contract(source, state.player)
	_check(cached.get("resident_view_contract_cache_hit", false) and cached.response_options == source.response_options, "Authored-only view lost its valid cache")
	# Simulate a persisted view from the old generic trait-enrichment policy.
	var old_view := view.duplicate(true)
	old_view.response_options.append({"id":"fixture_trait", "label":"An extra trait response"})
	old_view.projection_semantic_revision = builder._view_projection_semantic_revision(source, state.player_id, str(view.perspective))
	builder.view_contracts[str(view.view_contract_id)] = old_view
	var rebuilt := builder.build_view_contract(source, state.player)
	_check(rebuilt.response_options == source.response_options and not rebuilt.get("resident_view_contract_cache_hit", false), "Old cached trait responses survived Life Story rebuild")

func _test_story_choice_views() -> void:
	var state := _couple()
	_start_care(state)
	var source := _pending(state, CARE)
	_check_authored_view(state, source)
	var generic := source.duplicate(true)
	generic.id = "generic-trait-fixture"
	generic.request = "ordinary_situation"
	var builder := ContractViewLayerContractEngine.new(state)
	var view := builder.build_view_contract(generic, state.player)
	_check(view.response_options.size() == generic.response_options.size() + 1 and view.response_options[-1].id == "fixture_trait", "Non-story view lost supported trait responses")

func _test_established_separation() -> void:
	for mode in ["manual", "expired"]:
		var state := _couple()
		var record := _start_partner(state)
		var cast := state.player.partner
		var other := state.get_npc_by_id(104, false)
		cast.partner = null
		state.player.partner = other
		other.partner = state.player
		_check(not state.player.ex_partners.has(cast.id) and not cast.ex_partners.has(state.player_id), "Separation fixture accidentally has permanent ex-partner evidence")
		_check(not _resolve(state, PARTNER, "materials").get("success", true), "Stale payment bypassed confirmed new partnership")
		_check(record.get("separated", false) and record.history.is_empty() and state.player.bank_balance == 10000, "Separation did not preserve choice/money boundary")
		# Use normal servicing, without the test helper clearing its signature.
		state.scenario_runtime_contract_engine.service_life_stories()
		var pending := _pending(state, PARTNER)
		_check(not pending.is_empty() and record.node == "separation", "Stale-choice recovery did not publish separation in the same year")
		state.npcs.erase(other)
		state._rebuild_npc_index()
		_check(state.get_npc_by_id(other.id, false) == null, "New partner was not unloaded")
		if mode == "manual":
			state.scenario_state.background_hydration_active = true
			_check(not _resolve(state, PARTNER, "release").get("success", true), "Established separation bypassed hydration guard")
			state.scenario_state.background_hydration_active = false
			state.npcs.erase(cast)
			state._rebuild_npc_index()
			_check(not _resolve(state, PARTNER, "release").get("success", true), "Established separation bypassed original cast residency")
			state.npcs.append(cast)
			state._rebuild_npc_index()
			_check(_resolve(state, PARTNER, "release").get("success", false), "Confirmed separation became unresolvable after the third person unloaded")
		else:
			state.year = int(record.deadline_year) + 1
			state.scenario_runtime_contract_engine.service_life_stories()
			state.scenario_runtime_contract_engine.service_life_stories()
		_check(record.status == "finished" and record.history.size() == 1, "Established separation did not finish exactly once: " + mode)
		if not record.history.is_empty():
			_check(record.history[0].choice == "release" and record.history[0].automatic == (mode == "expired"), "Separation completed through the wrong response mode")
		_check(record.cast_id == cast.id and state.player.bank_balance == 10000 and cast.bank_balance == 10000, "Separation completion changed cast or spent money")

func _test_partner_rejected_actions() -> void:
	for invalid in ["viewer", "option", "expired"]:
		var state := _couple()
		var record := _start_partner(state)
		var source := _pending(state, PARTNER)
		if invalid == "expired":
			state.year = int(record.deadline_year) + 1
		var before := _snapshot(state, record)
		var result: Dictionary = state.pending_situations_engine.resolve_pending_contract(str(source.id), "invented" if invalid == "option" else "materials", {"viewer_actor_id":103 if invalid == "viewer" else state.player_id})
		_check(not result.get("success", true) and _snapshot(state, record) == before, "Rejected partner action changed state: " + invalid)
