extends "test_connected_lives.gd"

const PACK_ID := "community_first_story.shared_walk"
const PACK_FILE := "user://mods/stories/safety.json"

func _sample() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://../examples/story-packs/community_first_story.json")))

func _install(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ModLoader.STORY_PACK_FOLDER))
	var file := FileAccess.open(PACK_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _pack_fixture() -> GameState:
	var state := _connected_fixture()
	state.get_npc_by_id(103, false).age = state.player.age
	return state

func _reload(state: GameState) -> LifeStoryEngine:
	var engine := LifeStoryEngine.new(state)
	engine.catalog = engine.catalog.filter(func(row): return str(row.id).begins_with("community_first_story."))
	state.scenario_runtime_contract_engine.life_story_engine = engine
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	return engine

func _tick(state: GameState) -> void:
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if "--story-pack-cold" in args:
		_cold_case(args[args.find("--story-pack-cold") + 1])
	elif "--story-pack-text" in args:
		_test_authored_text()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PACK_FILE))
	else:
		_test_identifiers()
		_test_opening_timeout()
		_test_capacity()
		for stage in ["pending", "waiting"]:
			for missing in [true, false]:
				_test_pause(stage, missing)
		for mode in ["click_first", "service_first", "legacy_projection"]:
			_test_replaced_offer(mode)
		_test_authored_text()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PACK_FILE))
	print("STORY PACK SAFETY TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func _test_identifiers() -> void:
	for mutation in ["choice_space", "choice_blank", "choice_collision", "node_space", "node_blank", "default_space", "start_space", "next_space", "death_space", "control"]:
		var data := _sample()
		var story: Dictionary = data.stories[0]
		match mutation:
			"choice_space":
				story.nodes.invitation.choices[1].id = "pass "
				story.nodes.invitation.default = "pass "
			"choice_blank":
				story.nodes.invitation.choices[1].id = " "
				story.nodes.invitation.default = " "
			"choice_collision": story.nodes.invitation.choices[0].id = " pass "
			"node_space", "node_blank":
				var name := " invitation " if mutation == "node_space" else " "
				story.nodes[name] = story.nodes.invitation
				story.nodes.erase("invitation")
				story.start = name
			"default_space": story.nodes.invitation.default = " pass "
			"start_space": story.start = " invitation "
			"next_space": story.nodes.invitation.choices[0].next = "later "
			"death_space": story.death_node = " later "
			"control": story.nodes.invitation.choices[0].id = "wa\nlk"
		_check(not ModLoader.validate_story_pack(data).is_empty(), "Noncanonical authored ID accepted: " + mutation)
	_install(_sample())
	var state := _pack_fixture()
	_reload(state)
	_tick(state)
	var record := _record_for(state, PACK_ID)
	state.year = int(record.deadline_year) + 1
	_tick(state)
	_check(record.status == "finished" and record.history.size() == 1 and record.history[0].choice == "pass" and record.history[0].automatic, "Validated default could not resolve through expiry")

func _test_opening_timeout() -> void:
	var state := _friend_fixture()
	_start(state, FRIEND)
	for choice in ["meet", "listen", "debt", "acknowledge"]:
		_await_chapter(state, FRIEND)
		_check(_resolve(state, FRIEND, choice).get("success", false), "Repair route failed before opening")
	_await_chapter(state, FRIEND)
	var record := _record_for(state, FRIEND)
	_check(record.node == "opening", "Repair route did not reach opening")
	var affection := state.player.affection.duplicate(true)
	state.year = int(record.deadline_year) + 1
	_tick(state)
	_check(record.status == "finished" and record.legacy == "friendship_distance" and record.history.back().automatic, "Silence accepted renewed friendship")
	_check(state.player.affection == affection and not str(record.history.back().text).contains("began again"), "Silence invented affection or agreement")

func _test_capacity() -> void:
	var data := _sample()
	data.stories[0].nodes.invitation.deadline = 50
	for name in ["second_walk", "third_walk"]:
		var extra: Dictionary = data.stories[0].duplicate(true)
		extra.id = "community_first_story." + name
		data.stories.append(extra)
	_install(data)
	var state := _pack_fixture()
	_reload(state)
	_tick(state)
	var first := _record_for(state, PACK_ID)
	var cast_id: int = first.cast_id
	state.year += 2
	_tick(state)
	var absent := data.duplicate(true)
	absent.stories.remove_at(0)
	_install(absent)
	_reload(state)
	state.year += 2
	_tick(state)
	_check(not _record_for(state, "community_first_story.third_walk").is_empty(), "Missing pack did not release its slot")
	_install(data)
	_reload(state)
	state.year += 2
	_tick(state)
	_check(_pending(state, PACK_ID).is_empty() and first.has("suspension"), "Reinstated pack bypassed occupied slots")
	_check(state.scenario_runtime_contract_engine.active_popup_contracts.size() == 2, "More than two saved stories resumed together")
	_resolve(state, "community_first_story.second_walk", "pass")
	_tick(state)
	_check(not first.has("suspension") and not _pending(state, PACK_ID).is_empty(), "Suspended story did not resume in the released slot")
	_check(first.cast_id == cast_id and first.history.is_empty(), "Capacity suspension changed cast or history")
	_check(state.scenario_runtime_contract_engine.active_popup_contracts.size() == 2, "Resumption exceeded the cap after a slot opened")

func _test_pause(stage: String, missing: bool) -> void:
	var data := _sample()
	_install(data)
	var state := _pack_fixture()
	_reload(state)
	_tick(state)
	if stage == "waiting":
		_resolve(state, PACK_ID, "walk")
	state.year += 1
	_tick(state)
	var record := _record_for(state, PACK_ID)
	var remaining: int = int(record.deadline_year if stage == "pending" else record.due_year) - int(state.year)
	var original := record.duplicate(true)
	var old_offer := _pending(state, PACK_ID).duplicate(true)
	if missing:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PACK_FILE))
	else:
		var incompatible := data.duplicate(true)
		var node_id := str(record.node)
		incompatible.stories[0].nodes.renamed = incompatible.stories[0].nodes[node_id]
		incompatible.stories[0].nodes.erase(node_id)
		if stage == "pending":
			incompatible.stories[0].start = "renamed"
		else:
			incompatible.stories[0].nodes.invitation.choices[0].next = "renamed"
		_install(incompatible)
	_reload(state)
	_tick(state)
	_check(record.has("suspension") and _pending(state, PACK_ID).is_empty(), "Unavailable pack kept a live choice: " + stage)
	if not old_offer.is_empty():
		_check(not state.scenario_runtime_contract_engine.resolve_popup_contract(old_offer.id, "walk", {"viewer_actor_id":101}).get("success", true), "Unavailable pack accepted a stale choice")
	state.year += 6
	_tick(state)
	_cold_launch(state, {"case":"pause", "stage":stage, "remaining":remaining, "original":original, "pack":data})

func _test_replaced_offer(mode: String) -> void:
	var data := _sample()
	data.stories[0].nodes.invitation.choices[0].transfer = -200
	_install(data)
	var state := _pack_fixture()
	_reload(state)
	_tick(state)
	var offer := _pending(state, PACK_ID)
	_check(str(offer.response_options[0].label).contains("$200"), "Original offer did not display its price")
	if mode == "legacy_projection":
		var record := _record_for(state, PACK_ID)
		record.erase("offer_revision")
		state.scenario_runtime_contract_engine.active_popup_contracts.erase(offer.id)
		offer.id = "life_story:101:" + PACK_ID + ":invitation"
		offer.source_result.erase("offer_revision")
		state.scenario_runtime_contract_engine.active_popup_contracts[offer.id] = offer
	data.stories[0].nodes.invitation.choices[0].transfer = -2000
	_install(data)
	_cold_launch(state, {"case":"offer", "mode":mode, "old_id":offer.id})

func _test_authored_text() -> void:
	var data := _sample()
	data.stories[0].nodes.invitation.text = "A [b]literal chapter[/b] with {person}, the Mind Stone and 4 Elements."
	data.stories[0].nodes.invitation.choices[0].result = "I kept [color=red]literal results[/color] with {person}."
	_install(data)
	var state := _pack_fixture()
	state.get_npc_by_id(103, false).first_name = "[i]Casey[/i]"
	_reload(state)
	_tick(state)
	_inspect_text(state, true)
	_cold_launch(state, {"case":"text_pending"})
	# The cold process uses a separate hydrated state, so this choice remains pending.
	_resolve(state, PACK_ID, "walk")
	_inspect_text(state, false)
	_cold_launch(state, {"case":"text_history"})

func _cold_launch(state: GameState, expected: Dictionary) -> void:
	var bundle := {"payload":GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload(),
		"runtime":state.scenario_runtime_contract_engine.export_state(), "expected":expected}
	var path := ProjectSettings.globalize_path("user://story-pack-cold.bin")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(BinarySaveEngine.encode(bundle))
	file.close()
	var output: Array = []
	var status := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", get_script().resource_path, "--", "--story-pack-cold", path], output, true)
	for line in output:
		print(str(line))
	_check(status == 0, "Cold-process case failed: " + str(expected))

func _hydrate(payload: Dictionary, runtime: Dictionary) -> GameState:
	var state := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	RealityResidencyManager.new(state)._materialize_checkpoint_resume_shell(state, {"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "pack-safety-checkpoint", {})
	state.era = {"name":payload.era_name}
	state.bank_engine = BankEngine.new(state)
	var hydration := GameStateHydrationRuntime.new(state)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]}, {"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	for step in range(20000):
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	_check(not hydration.is_background_hydration_active(), "Pack safety hydration incomplete")
	state.resident_runtime_bootstrap_complete = true
	state.relationship_engine = RelationshipEngine.new(state)
	state.memory_engine = MemoryEngine.new(state)
	# Hydration already imported this authority. Replacing it would discard the
	# restored diary stream and turn a rendering check into an invalid fixture.
	_check(state.life_diary_contract_engine != null, "Hydration omitted the diary authority")
	state.scenario_runtime_contract_engine = ScenarioRuntimeContractEngine.new(state)
	state.scenario_runtime_contract_engine.import_state(runtime)
	state.scenario_popup_contract_engine = ScenarioPopupContractEngine.new(state)
	state.pending_situations_engine = PendingSituationsEngine.new(state)
	_reload(state)
	return state

func _cold_case(path: String) -> void:
	var bundle := BinarySaveEngine.decode(FileAccess.get_file_as_bytes(path))
	var state := _hydrate(bundle.payload, bundle.runtime)
	var expected: Dictionary = bundle.expected
	var record := _record_for(state, PACK_ID)
	match str(expected.case):
		"pause":
			_tick(state)
			state.year += 4
			_tick(state)
			_install(expected.pack)
			_reload(state)
			_tick(state)
			_check(JSON.stringify(record.history) == JSON.stringify(expected.original.history) and record.cast_id == expected.original.cast_id, "Cold resume consumed history or changed cast")
			var clock: int = int(record.deadline_year if expected.stage == "pending" else record.due_year)
			_check(clock == int(state.year) + int(expected.remaining) and not record.has("suspension"), "Cold resume lost remaining story time")
			if expected.stage == "waiting":
				_check(_pending(state, PACK_ID).is_empty(), "Waiting chapter surfaced before its remaining delay")
				state.year = clock
				_tick(state)
			_check(_resolve(state, PACK_ID, "walk" if expected.stage == "pending" else "again").get("success", false), "Cold resumed choice was not playable")
		"offer":
			_check(str(_pending(state, PACK_ID).response_options[0].label).contains("$200)"), "Full restore did not retain the old offer fixture")
			if expected.mode == "service_first":
				_tick(state)
			var before := JSON.stringify([state.player.bank_balance, state.player.affection, record.history])
			var response: Dictionary = state.scenario_runtime_contract_engine.resolve_popup_contract(expected.old_id, "walk", {"viewer_actor_id":101})
			_check(not response.get("success", true) and JSON.stringify([state.player.bank_balance, state.player.affection, record.history]) == before, "Stale displayed payment charged new effects")
			_tick(state)
			var fresh := _pending(state, PACK_ID)
			_check(not fresh.is_empty() and fresh.id != expected.old_id and str(fresh.response_options[0].label).contains("$2000)"), "Updated offer did not require a new displayed contract")
			if not fresh.is_empty():
				_check(_resolve(state, PACK_ID, "walk").get("success", false) and state.player.bank_balance == 8000, "Updated displayed and charged amounts disagree")
		"text_pending":
			_tick(state)
			_inspect_text(state, true)
			_resolve(state, PACK_ID, "walk")
			_inspect_text(state, false)
		"text_history": _inspect_text(state, false)
	print("PACK COLD CASE: ", expected.case, " ", expected.get("stage", expected.get("mode", "")), " ", "FAIL" if failed else "PASS")

func _inspect_text(state: GameState, pending: bool) -> void:
	if pending:
		var viewer = load("res://ui/viewers/PopupViewer.gd").new()
		root.add_child(viewer)
		viewer.present_contract(_pending(state, PACK_ID))
		_check(viewer.body_label.get_parsed_text().contains("[b]literal chapter[/b]") and viewer.body_label.get_parsed_text().contains("[i]Casey[/i]"), "Pending view parsed authored markup or names")
		viewer.free()
		return
	var scene = load("res://scenes/MainScene.gd").new()
	scene.gs = state
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	scene.output_label = label
	var result := str(_record_for(state, PACK_ID).history.back().text)
	var diary := JSON.stringify(state.life_diary_contract_engine.diary_entries_for_actor(101))
	_check(diary.contains("[color=red]literal results[/color]") and diary.contains("[i]Casey[/i]"), "Saved diary lost literal authored text")
	for line in [result, "Year: [b]year-looking text[/b]", "Age: [i]age-looking text[/i]", "[b]Mind Stone[/b] and [i]4 Elements[/i]"]:
		label.clear()
		scene._append_formatted_life_diary_line(label, line)
		_check(label.get_parsed_text().contains(line.trim_prefix("Year: ")), "Diary parsed authored line: " + line)
	label.clear()
	scene._apply_playable_life_viewer_life_diary_packet_zero_frame({"lines":[result], "text":result}, {})
	_check(label.get_parsed_text().contains(result), "Restored diary packet parsed authored results")
	label.clear()
	scene._apply_playable_life_viewer_life_diary_packet_zero_frame({"text":result}, {})
	_check(label.get_parsed_text().contains(result), "Text-only diary packet parsed authored results")
	_inspect_switch_text(state, scene, label, result)
	label.free()
	scene.free()

func _inspect_switch_text(state: GameState, scene: Node, label: RichTextLabel, result: String) -> void:
	var switching := UniversalSwitchContractEngine.new(state)
	var packet := switching.prepare_profile_pointer_packet(state.player, {"source":"story_pack_literal_text"})
	_check(packet.get("success", false) and str(packet.get("press_frame_lens_cache", {}).get("life_diary_text", "")).contains(result), "Real profile pointer packet lost authored history")
	for mode in ["packet", "cached_text_only", "fallback_text", "lines_only"]:
		var view := packet.duplicate(true)
		var containers: Array = [view, view.surface_contract, view.press_frame_lens_cache, view.surface_contract.press_frame_lens_cache, view.life_diary_packet]
		if mode in ["cached_text_only", "fallback_text"]:
			for container in containers:
				for key in ["life_diary_lines", "life_diary_entries", "lines", "entries"]:
					container.erase(key)
		if mode in ["fallback_text", "lines_only"]:
			view.press_frame_lens_cache.life_diary_text = ""
			view.surface_contract.press_frame_lens_cache.life_diary_text = ""
		if mode == "fallback_text":
			view.life_diary_packet.text = result
		label.clear()
		if label.has_meta("visible_truth_anchor_signature"):
			label.remove_meta("visible_truth_anchor_signature")
		scene._apply_playable_life_viewer_packet_press_frame_lens_only(view, result if mode == "fallback_text" else "", "relationship_profile_switch_literal_test")
		_check(label.get_parsed_text().contains(result), "Profile press-frame view parsed or lost authored results: " + mode)
		label.clear()
		var installed: bool = scene._install_switched_actor_life_diary_from_published_packet(state.player, view, "story_pack_literal_text", {"actor_id":state.player_id})
		_check(installed and label.get_parsed_text().contains(result), "Published switch diary parsed or lost authored results: " + mode)
