extends "test_living_households.gd"

const CHILD := "child_ambitions"
const CHILD_MEMORY := "child_ambitions_legacy"
const FRIEND := "adult_friendship"
const FRIEND_MEMORY := "adult_friendship_legacy"
var connected_responses := 0

func _connected_fixture() -> GameState:
	var state := _household_fixture()
	state.player.age = 42
	state.get_npc_by_id(106, false).age = 18
	state.get_npc_by_id(106, false).affection[101] = 60
	return state

func _friend_fixture() -> GameState:
	var state := _connected_fixture()
	state.player.age = 12
	state.get_npc_by_id(103, false).age = 12
	state.player.partner = null
	_only(state, "childhood_pact")
	for option in ["stand_beside", "commit", "share_credit"]:
		_await_chapter(state, "childhood_pact")
		_check(_resolve(state, "childhood_pact", option).get("success", false), "Childhood setup failed")
	state.year += 8
	state.player.age = 28
	state.get_npc_by_id(103, false).age = 28
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	return state

func _start(state: GameState, id: String) -> Dictionary:
	_only(state, id)
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()
	return _record_for(state, id)

func _as_child(state: GameState, id: String) -> Dictionary:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	state.player = state.get_npc_by_id(106, false)
	state.player_id = 106
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog
	return _start(state, id)

func _run() -> void:
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty() and engine.catalog.size() == 18, "Connected catalog failed: " + str(engine.content_errors))
	_test_routes()
	_test_responses(engine)
	_test_cast_and_memory()
	_test_money_defaults_and_loss()
	_test_connections()
	_test_chronicle()
	_test_binary()
	_test_packs()
	print("CONNECTED LIVES TESTS: ", "FAIL" if failed else "PASS", "; responses=", connected_responses)
	quit(1 if failed else 0)

func _test_routes() -> void:
	var routes := [
		[CHILD, ["listen", "encourage"], "supported_direction"],
		[CHILD, ["negotiate", "ask", "adjust"], "room_to_reconsider"],
		[CHILD, ["pressure", "repair", "listen"], "trust_rebuilt"],
		[CHILD, ["pressure", "insist"], "unresolved_pressure"],
		[CHILD, ["space", "respect"], "independent_direction"],
		[FRIEND, ["meet", "help", "accept"], "mutual_friendship"],
		[FRIEND, ["honest", "agree"], "friendship_with_limits"],
		[FRIEND, ["meet", "listen", "debt", "acknowledge", "accept"], "friendship_repaired"],
		[FRIEND, ["decline"], "friendship_distance"]]
	for route in routes:
		var state := _friend_fixture() if route[0] == FRIEND else _connected_fixture()
		# All catalogs and ordinary eligibility; only competing choices use defaults.
		for option in route[1]:
			_await_chapter(state, route[0])
			_check(_resolve(state, route[0], option).get("success", false), "Connected route failed: " + str(route))
		var record := _record_for(state, route[0])
		_check(record.get("status", "") == "finished" and record.get("legacy", "") == route[2], "Connected route outcome wrong: " + str(route))
		_check(record.get("history", []).size() == route[1].size(), "Connected route duplicated history")
		var before := JSON.stringify(record)
		_year(state, route[0])
		_check(JSON.stringify(record) == before, "Completed story replayed")
		print("CONNECTED CONTRACT ROUTE: ", route, " finished=", state.year)

func _test_responses(engine: LifeStoryEngine) -> void:
	for definition in engine.catalog.filter(func(row): return str(row.get("series", "")) == "Connected Lives"):
		for node_id in definition.nodes:
			for option in definition.nodes[node_id].choices:
				var friendship: bool = definition.id in [FRIEND, FRIEND_MEMORY]
				var state := _friend_fixture() if friendship else _connected_fixture()
				var record := _start(state, FRIEND if friendship else CHILD)
				if definition.id in [CHILD_MEMORY, FRIEND_MEMORY]:
					record.status = "finished"
					record.legacy = "supported_direction"
					record = _as_child(state, definition.id)
				_check(not record.is_empty(), "Inherited chapter missing: " + str(definition.id))
				if record.is_empty():
					continue
				_chapter(state, record, node_id)
				var pending := _pending(state, definition.id)
				_check(not pending.is_empty() and not str(pending.get("overview", "")).contains("{person}"), "Connected text failed rendering")
				_check(_resolve(state, definition.id, option.id).get("success", false), "Connected response failed: " + str(definition.id) + "/" + node_id + "/" + option.id)
				var after := JSON.stringify([record, state.player.bank_balance, state.player.affection])
				_check(not state.scenario_runtime_contract_engine.resolve_popup_contract(pending.id, option.id, {"viewer_actor_id":state.player_id}).get("success", true), "Duplicate connected response accepted")
				_check(JSON.stringify([record, state.player.bank_balance, state.player.affection]) == after, "Duplicate response had effects")
				connected_responses += 1
	_check(connected_responses == 50, "Not all connected responses checked")

func _test_cast_and_memory() -> void:
	for invalid in ["no_child", "young", "old", "dead", "nonreciprocal"]:
		var state := _connected_fixture()
		var child := state.get_npc_by_id(106, false)
		match invalid:
			"no_child": state.player.children = []
			"young": child.age = 15
			"old": child.age = 31
			"dead": child.alive = false
			"nonreciprocal": child.parents = []
		_check(_start(state, CHILD).is_empty(), "Invalid child cast: " + invalid)
	var friends := _friend_fixture()
	friends.player.friends = [104]
	_check(_start(friends, FRIEND).get("cast_id", -1) == 103, "Adult story replaced original friend after drift")
	var no_origin := _connected_fixture()
	_check(_start(no_origin, FRIEND).is_empty(), "Adult friend appeared without childhood history")
	for trust in [44, 45]:
		var state := _connected_fixture()
		var record := _start(state, CHILD)
		state.get_npc_by_id(106, false).affection[101] = trust
		state.player.affection[106] = 100 if trust == 44 else 0
		_chapter(state, record, "distance")
		_resolve(state, CHILD, "repair")
		_check(record.node == ("boundary" if trust == 44 else "repair"), "Child's own trust was not respected")
	for mode in ["public", "private", "unfinished", "other_child"]:
		var state := _connected_fixture()
		var record := _start(state, CHILD)
		record.status = "finished" if mode != "unfinished" else "waiting"
		record.legacy = "private" if mode == "private" else "supported_direction"
		if mode == "other_child":
			record.cast_id = 107
		state.player.alive = false
		var before := JSON.stringify(record)
		var memory := _as_child(state, CHILD_MEMORY)
		_check(memory.is_empty() == (mode != "public"), "Child memory crossed privacy or identity: " + mode)
		if mode == "public":
			_check(memory.cast_id == 101 and memory.origin == CHILD, "Child remembered the wrong parent")
			_check(_resolve(state, CHILD_MEMORY, "adapt").get("success", false), "Child could not remember deceased parent")
		_check(JSON.stringify(record) == before, "Child rewrote parent's past")

func _test_money_defaults_and_loss() -> void:
	for era in ["Ancient Era", "Future Era"]:
		var scaled := _connected_fixture()
		scaled.era.name = era
		_start(scaled, CHILD)
		var price := 40 if era == "Ancient Era" else 300
		var paid: Dictionary = _pending(scaled, CHILD).response_options.filter(func(row): return row.id == "materials")[0]
		_check(str(paid.label).count("$") == 1 and str(paid.label).contains(str(price)), "Child offer displayed a conflicting unscaled price")
		_check(_resolve(scaled, CHILD, "materials").get("success", false) and scaled.player.bank_balance == 10000 - price, "Child era-scaled transfer failed")
	for condition in ["poor", "frozen", "available"]:
		var state := _connected_fixture()
		if condition == "poor":
			state.player.bank_balance = 0
		var record := _start(state, CHILD)
		var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
		if condition == "frozen":
			state.bank_engine.set_account_status(account.account_id, "frozen")
		var before := JSON.stringify([record, state.player.bank_balance, state.player.affection])
		var response := _resolve(state, CHILD, "materials")
		_check(response.get("success", false) == (condition == "available"), "Child payment boundary failed")
		if condition == "available":
			_check(state.player.bank_balance == 9800 and state.get_npc_by_id(106, false).bank_balance == 700, "Child materials did not conserve personal money")
		else:
			_check(JSON.stringify([record, state.player.bank_balance, state.player.affection]) == before, "Failed child payment committed effects")
			_check(_resolve(state, CHILD, "space").get("success", false), "No free child alternative")
	for id in [CHILD, FRIEND]:
		var state := _friend_fixture() if id == FRIEND else _connected_fixture()
		var record := _start(state, id)
		var cast := state.get_npc_by_id(record.cast_id, false)
		state.npcs.erase(cast)
		state._rebuild_npc_index()
		state.year = record.deadline_year + 1
		state.scenario_runtime_contract_engine.service_life_stories()
		_check(record.history.is_empty() and record.status == "pending", "Missing cast resolved or replaced")
		state.npcs.append(cast)
		state._rebuild_npc_index()
		state.scenario_runtime_contract_engine.life_story_service_signature = ""
		state.scenario_runtime_contract_engine.service_life_stories()
		_check(record.history.size() == 1 and record.history[0].automatic, "Free expired default did not resume once")
		state = _friend_fixture() if id == FRIEND else _connected_fixture()
		record = _start(state, id)
		state.get_npc_by_id(record.cast_id, false).alive = false
		state.year += 1
		state.scenario_runtime_contract_engine.service_life_stories()
		_check(record.node == "loss", "Death missed connected bereavement chapter")
		_check(_resolve(state, id, "remember").get("success", false), "Bereavement choice unavailable")

func _test_connections() -> void:
	for privacy in ["public", "private", "unfinished"]:
		var state := _connected_fixture()
		var engine: LifeStoryEngine = state.scenario_runtime_contract_engine._ensure_life_story_engine()
		var previous := {"story_id":"partner_futures", "status":"waiting" if privacy == "unfinished" else "finished", "legacy":"private" if privacy == "private" else "separate_pursuits", "cast_id":103, "cast_name":"Casey Story", "due_year":2100}
		engine._actor_state(101).stories.partner_futures = previous
		var record := _start(state, CHILD)
		_check(record.get("connections", []).size() == (1 if privacy == "public" else 0), "Connection crossed privacy or unfinished history")
		if privacy == "public":
			_check(str(_pending(state, CHILD).overview).contains("separate pursuits"), "Saved connection not visible")
			previous.legacy = "unresolved_pressure"
			_check(record.connections[0].legacy == "separate_pursuits", "Earlier connection changed retroactively")

func _test_chronicle() -> void:
	var state := _connected_fixture()
	var record := _start(state, CHILD)
	_resolve(state, CHILD, "listen")
	_advance_to_due(state, CHILD)
	_resolve(state, CHILD, "encourage")
	var before := JSON.stringify(state.scenario_state)
	var view := FamilyChronicleContractEngine.build(state, LifeStoryEngine.new().catalog)
	_check(view.entries.size() == 3 and str(view.recap).contains("2002"), "Chronicle lost choices/outcome")
	_check(JSON.stringify(state.scenario_state) == before, "Chronicle mutated authority")
	_as_child(state, CHILD_MEMORY)
	view = FamilyChronicleContractEngine.build(state)
	_check(view.entries.size() == 1 and view.entries[0].inherited and view.entries[0].person == "Alex Story", "Chronicle did not attribute public parental outcome")
	record.legacy = "private"
	_check(FamilyChronicleContractEngine.build(state).entries.is_empty(), "Chronicle leaked a private parent story")
	record.legacy = "supported_direction"
	record.status = "waiting"
	_check(FamilyChronicleContractEngine.build(state).entries.is_empty(), "Chronicle leaked an unfinished parent story")

func _test_binary() -> void:
	var state := _connected_fixture()
	_start(state, CHILD)
	_resolve(state, CHILD, "materials")
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	var restored := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	RealityResidencyManager.new(restored)._materialize_checkpoint_resume_shell(restored, {"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "connected-checkpoint", {})
	restored.era = {"name":payload.era_name}
	restored.bank_engine = BankEngine.new(restored)
	var hydration := GameStateHydrationRuntime.new(restored)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]}, {"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	for step in range(20000):
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	_check(not hydration.is_background_hydration_active(), "Connected hydration incomplete")
	_check(JSON.parse_string(JSON.stringify(restored.scenario_state.life_stories)) == payload.scenario_state.life_stories, "Binary restore changed connected histories")
	_check(restored.player.bank_balance == 9800 and restored.get_npc_by_id(106, false).bank_balance == 700, "Binary restore changed child funds")
	restored.resident_runtime_bootstrap_complete = true
	restored.relationship_engine = RelationshipEngine.new(restored)
	restored.memory_engine = MemoryEngine.new(restored)
	restored.life_diary_contract_engine = LifeDiaryContractEngine.new(restored)
	restored.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(restored)
	restored.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(restored)
	restored.pending_situations_engine = PendingSituationsEngine.new(restored)
	_only(restored, CHILD)
	_advance_to_due(restored, CHILD)
	_check(_resolve(restored, CHILD, "encourage").get("success", false), "Restored child story cannot finish")
	_check(_record_for(restored, CHILD).history.size() == 2, "Restored child choice replayed")

func _test_packs() -> void:
	var sample_path := ProjectSettings.globalize_path("res://../examples/story-packs/community_first_story.json")
	var sample: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sample_path))
	_check(ModLoader.validate_story_pack(sample).is_empty(), "Example pack invalid")
	for mutation in ["container", "stat", "choice", "cycle", "missing", "cost", "role", "namespace", "collision", "float"]:
		var bad := sample.duplicate(true)
		var story: Dictionary = bad.stories[0]
		match mutation:
			"container": story.nodes.invitation.choices = "wrong"
			"stat": story.nodes.invitation.choices[0].stats = {"smarts":"wrong"}
			"choice": story.nodes.invitation.choices[0] = []
			"cycle": story.nodes.later.choices[0].next = "invitation"
			"missing": story.nodes.later.choices[0].next = "absent"
			"cost": story.nodes.invitation.choices[1].transfer = -50
			"role": story.cast = "unknown"
			"namespace": story.id = "../bad"
			"collision": pass
			"float": story.nodes.invitation.deadline = 1.5
		_check(not ModLoader.validate_story_pack(bad, [str(story.id)] if mutation == "collision" else []).is_empty(), "Invalid pack accepted: " + mutation)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ModLoader.STORY_PACK_FOLDER))
	var path := ModLoader.STORY_PACK_FOLDER.path_join("sample.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(sample))
	file.close()
	file = FileAccess.open(ModLoader.STORY_PACK_FOLDER.path_join("bad.json"), FileAccess.WRITE)
	file.store_string('{"stories":[null],"version":1}')
	file.close()
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty() and engine.catalog.size() == 19 and engine.pack_report.errors.size() == 1, "Bad pack disabled good packs or built-ins")
	var state := _connected_fixture()
	var id := str(sample.stories[0].id)
	state.get_npc_by_id(103, false).age = state.player.age
	_start(state, id)
	_check(_resolve(state, id, "walk").get("success", false), "Installed sample pack cannot play")
	var before := JSON.stringify(_record_for(state, id))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	state.scenario_runtime_contract_engine.life_story_engine = LifeStoryEngine.new(state)
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(JSON.stringify(_record_for(state, id)) == before, "Removed pack destroyed saved progress")
	var incompatible := sample.duplicate(true)
	incompatible.stories[0].nodes.after_walk = incompatible.stories[0].nodes.later
	incompatible.stories[0].nodes.erase("later")
	incompatible.stories[0].nodes.invitation.choices[0].next = "after_walk"
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(incompatible))
	file.close()
	state.scenario_runtime_contract_engine.life_story_engine = LifeStoryEngine.new(state)
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(JSON.stringify(_record_for(state, id)) == before, "Incompatible pack changed saved progress")
	_check(str(state.scenario_runtime_contract_engine.life_story_engine.pack_report.errors).contains("saved chapter is missing"), "Incompatible pack did not explain its paused chapter")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(sample))
	file.close()
	state.scenario_runtime_contract_engine.life_story_engine = LifeStoryEngine.new(state)
	_advance_to_due(state, id)
	_check(_resolve(state, id, "again").get("success", false), "Reinstalled sample cannot continue")
	_check(_record_for(state, id).history.size() == 2, "Sample pack replayed or lost progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ModLoader.STORY_PACK_FOLDER.path_join("bad.json")))
