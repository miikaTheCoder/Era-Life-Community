extends SceneTree

class DisplayScene extends "res://scenes/MainScene.gd":
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _input(_event) -> void:
		pass
	func _unhandled_input(_event: InputEvent) -> void:
		pass
	func _notification(_what: int) -> void:
		pass

var failed := false

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	test_estate()
	test_inheriting_a_pending_estate(false)
	test_inheriting_a_pending_estate(true)
	test_restored_parent_mortality()
	test_world_and_dormant_mortality()
	test_nonplayer_estate()
	test_player_estate(true)
	test_player_estate(false)
	test_founder_death_before_choice()
	test_vehicle()
	test_maintenance_projection()
	# The real profile switch releases its projection after presentation.
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	if not failed:
		print("ESTATE AND VEHICLE PAYMENT TESTS: PASS")
	quit(1 if failed else 0)

func diary_scene(state: GameState) -> DisplayScene:
	var scene := DisplayScene.new()
	var container := Control.new()
	container.name = "UIContainer"
	var output := RichTextLabel.new()
	output.name = "OutputLabel"
	output.size = Vector2(900, 500)
	container.add_child(output)
	scene.add_child(container)
	root.add_child(scene)
	scene.gs = state
	scene.current_panel = "life"
	return scene


func check_estate_notice(scene: DisplayScene, stage: String) -> void:
	var visible_text := scene.output_label.get_parsed_text()
	check(scene.output_label.is_visible_in_tree() and visible_text.contains("frozen")
		and visible_text.contains("an account reopens or a year passes"), stage + " did not show the hold and retry guidance")
	print("ESTATE NOTICE ", stage, " ", visible_text)
	scene.queue_free()


func new_state() -> GameState:
	var state := GameState.create_resident_chassis_shell()
	var owner := Person.new()
	owner.id = 41
	owner.first_name = "Alex"
	owner.last_name = "Reed"
	owner.bank_balance = 110
	owner.children = [42]
	var heir := Person.new()
	heir.id = 42
	heir.parents = [41]
	heir.bank_balance = 20
	state.npcs = [owner, heir]
	state.player = heir
	state.player_id = heir.id
	state.era = {"name": "Modern Era"}
	state._rebuild_npc_index()
	state.bank_engine = BankEngine.new(state)
	state.vehicle_engine = VehicleEngine.new(state)
	state.family_contract_engine = FamilyContractEngine.new(state)
	return state

func test_estate() -> void:
	var state := new_state()
	var bank: BankEngine = state.bank_engine
	var family: FamilyContractEngine = state.family_contract_engine
	var deceased: Person = state.npcs[0]
	var heir := state.player
	deceased.alive = false
	bank.ensure_bank_account_for_actor(deceased, {"import_legacy_balance": true})
	bank.credit_bank("person:41", 7, "Mars", "EUR")
	var frozen := bank.ensure_account("person:41", "Mars", "bank", "EUR")
	bank.set_account_status(frozen.account_id, "frozen")
	state.vehicle_engine.vehicles[41] = [{"id": 11, "value": 90}]
	# Deliver a single death through the normal estate subscribers.
	state.event_bus = EventBus.new(state)
	state.vehicle_engine._bind_contract_events()
	state.family_control_engine = FamilyControlEngine.new(state)
	state.event_bus.subscribe(ActionEventTypes.NPC_DIED, family, "on_npc_died")
	state.event_bus.subscribe(ActionEventTypes.NPC_DIED, state.family_control_engine, "handle_spousal_estate_inheritance")
	state.event_bus.emit(ActionEventTypes.NPC_DIED, {"npc_id": deceased.id})
	var claim: Dictionary = state.scenario_state.get("pending_lineage_estates", {}).get("41", {})
	check(int(claim.get("heir_id", -1)) == heir.id and str(claim.get("reason", "")).contains("frozen"),
		"A single NPC death did not reserve the restricted estate for its child")
	check(state.pending_inheritance_messages.size() == 1, "The heir did not receive one pending estate notice")
	check(bank.get_owner_summary("person:41").bank_balance == 110 and heir.bank_balance == 20
		and state.vehicle_engine.vehicles.has(41) and not state.vehicle_engine.vehicles.has(42),
		"A death subscriber transferred funds or a vehicle before the estate cleared")
	state = restore_checkpoint(state, "user://pending-npc-estate.bin")
	if state == null:
		return
	bank = state.bank_engine
	deceased = state.get_npc_by_id(41)
	heir = state.player
	if state.family_contract_engine == null:
		state.family_contract_engine = FamilyContractEngine.new(state)
	family = state.family_contract_engine
	var pending: Dictionary = state.scenario_state.get("pending_lineage_estates", {})
	check(int(pending.get("41", {}).get("heir_id", -1)) == heir.id and state.vehicle_engine.vehicles.has(41),
		"Cold Continue lost the claim or the deceased's vehicle")
	family.yearly_tick()
	check(pending.has("41") and heir.bank_balance == 20, "The yearly retry paid a frozen estate")
	bank.set_account_status(frozen.account_id, "open")
	check(pending.is_empty() and not state.vehicle_engine.vehicles.has(41), "Reopening did not release the whole estate")
	var vehicles: Array = state.vehicle_engine.vehicles.get(42, [])
	check(vehicles.size() == 1 and int(vehicles[0].get("id", -1)) == 11
		and int(vehicles[0].get("provenance", {}).get("last_inherited_by", -1)) == heir.id,
		"The designated heir did not receive the original vehicle with inheritance history")
	check(heir.bank_balance == 130, "NPC death failed to settle the estate for the living child")
	var settled := family.execute_estate_contract(deceased, heir)
	check(settled.success and settled.inherited_cash == 110 and settled.inherited_vehicle_count == 1,
		"Estate receipt did not describe the original transfer")
	check(settled.inherited_balances.get("EUR", 0) == 7 and bank.ensure_account("person:42", "Mars", "bank", "EUR").balance == 7,
		"Estate settlement lost the original currency or realm")
	bank.repair_legacy_player_money_mirror()
	check(heir.bank_balance == 130 and deceased.bank_balance == 0, "Estate payment disappeared on bank refresh")
	var ledger_size := bank.ledger.size()
	family.yearly_tick()
	var again := family.execute_estate_contract(deceased, heir)
	check(again.inherited_cash == 110 and again.inherited_vehicle_count == 1 and bank.ledger.size() == ledger_size,
		"Death notification or second execution rewrote the estate")
	var decoded: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(
		GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	var loaded := new_state()
	var saved_actor: Dictionary = decoded.npcs.filter(func(row): return int(row.id) == 41)[0]
	var loaded_deceased: Person = loaded._deserialize_npc(saved_actor)
	loaded.bank_engine.import_state(decoded.bank_engine_state)
	loaded.family_contract_engine.ensure_family_contract(loaded_deceased)
	var after_load: Dictionary = loaded.family_contract_engine.execute_estate_contract(loaded_deceased, loaded.player)
	check(after_load.inherited_cash == 110 and after_load.inherited_vehicle_count == 1 and loaded.player.bank_balance == 130,
		"Loading a compact checkpoint lost the estate receipt")

func test_inheriting_a_pending_estate(legacy_claim: bool) -> void:
	var state := new_state()
	var owner: Person = state.npcs[0]
	var beneficiary := state.player
	var successor := Person.new()
	successor.id = 43
	successor.parents = [beneficiary.id]
	successor.bank_balance = 5
	beneficiary.children = [successor.id]
	state.npcs.append(successor)
	state._rebuild_npc_index()
	var bank: BankEngine = state.bank_engine
	var account := bank.ensure_bank_account_for_actor(owner, {"import_legacy_balance": true})
	bank.set_account_status(account.account_id, "frozen")
	state.vehicle_engine.vehicles[owner.id] = [{"id": 77, "value": 90}]
	owner.alive = false
	var family: FamilyContractEngine = state.family_contract_engine
	check(not family.execute_estate_contract(owner, beneficiary).success, "The restricted estate paid early")
	beneficiary.alive = false
	family.retry_pending_lineage_estates()
	var claims: Dictionary = state.scenario_state.get(FamilyContractEngine.PENDING_LINEAGE_ESTATES, {})
	check(int(claims.get("41", {}).get("heir_id", -1)) == beneficiary.id,
		"A death without a succession choice reassigned the pending estate")
	var handoff := AfterlifeInfluenceEngine.new(state)._transfer_player_estate_to_descendant(beneficiary, successor)
	check(handoff.success and successor.bank_balance == 25, "The successor did not receive the beneficiary's own estate")
	check(int(claims["41"].heir_id) == successor.id, "The chosen heir did not inherit the unpaid entitlement")
	if legacy_claim:
		# Earlier saves stored the intermediate owner. Their estate receipt is
		# the durable record of the choice made at succession.
		claims["41"].heir_id = beneficiary.id
		claims["41"].erase("original_heir_id")
	state.player = successor
	state.player_id = successor.id
	var restored := restore_checkpoint(state, "user://inherited-estate-claim.bin")
	if restored == null:
		return
	var restored_bank: BankEngine = restored.bank_engine
	restored_bank.set_account_status(account.account_id, "open")
	var vehicles: Array = restored.vehicle_engine.vehicles.get(successor.id, [])
	check(restored.player.bank_balance == 135 and restored_bank.accounts[account.account_id].balance == 0,
		"An inherited estate claim was stranded or paid to the wrong account after Continue")
	check(vehicles.size() == 1 and int(vehicles[0].id) == 77 and not restored.vehicle_engine.vehicles.has(owner.id),
		"The successor did not receive the original pending vehicle")
	var ledger_count := restored_bank.ledger.size()
	var balance: float = restored.player.bank_balance
	var restored_owner := restored.get_npc_by_id(owner.id)
	var receipt: Dictionary = restored_owner.person_contract.family.estate.execution
	check(int(receipt.heir_id) == successor.id and int(receipt.original_heir_id) == beneficiary.id,
		"The receipt lost the original entitlement or final recipient")
	FamilyControlEngine.new(restored).handle_spousal_estate_inheritance({"npc_id": owner.id})
	restored.family_contract_engine.retry_pending_lineage_estates()
	check(restored.player.bank_balance == balance and restored_bank.ledger.size() == ledger_count,
		"The inherited pending estate paid twice")


func test_nonplayer_estate() -> void:
	var state := new_state()
	var deceased: Person = state.npcs[0]
	var heir := state.player
	var bystander := Person.new()
	bystander.id = 43
	state.npcs.append(bystander)
	state.player = bystander
	state.player_id = bystander.id
	state._rebuild_npc_index()
	deceased.alive = false
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(deceased, {"import_legacy_balance": true})
	state.bank_engine.set_account_status(account.account_id, "frozen")
	FamilyControlEngine.new(state).handle_spousal_estate_inheritance({"npc_id": deceased.id})
	var pending: Dictionary = state.scenario_state.get("pending_lineage_estates", {})
	check(int(pending.get("41", {}).get("heir_id", -1)) == heir.id and state.pending_inheritance_messages.is_empty(),
		"An unrelated NPC estate failed to reserve its heir or notified the player")
	check(state._npc_is_dormancy_protected(heir), "A pending NPC heir could leave the checkpoint roster")
	var serializer := GameStateSerializationRuntime.new(state)
	var ids := serializer._interactive_checkpoint_actor_ids(1)
	check(ids.has(bystander.id) and ids.has(heir.id) and ids.has(deceased.id),
		"The compact roster limit split a saved estate from its participants")
	# An already-open account restored by import gets no reopening event.
	var imported: Dictionary = state.bank_engine.export_state()
	imported.accounts[account.account_id].status = "open"
	state.bank_engine.import_state(imported)
	state.family_contract_engine.yearly_tick()
	check(pending.is_empty() and heir.bank_balance == 130 and state.pending_inheritance_messages.is_empty(),
		"The annual retry failed to pay the unrelated heir exactly once")
	var entries: int = state.bank_engine.ledger.size()
	state.family_contract_engine.yearly_tick()
	check(heir.bank_balance == 130 and state.bank_engine.ledger.size() == entries,
		"A later year repeated the NPC estate payment")


func test_restored_parent_mortality() -> void:
	var state := new_state()
	var restored := restore_checkpoint(state, "user://parent-before-mortality.bin", true)
	if restored == null:
		return
	var mother: Person = restored.get_npc_by_id(41)
	var child := restored.player
	restored.health_engine = HealthEngine.new(restored)
	restored.health_engine.try_kill(mother, "Old age")
	check(not mother.alive and child.bank_balance == 130 and mother.bank_balance == 0,
		"A parent dying after cold Continue left their estate unpaid")
	var saved: Dictionary = mother.person_contract.get("family", {}).get("estate", {})
	check(saved.get("execution", {}).get("heir_id", -1) == child.id,
		"A cold-runtime mortality did not record its actual beneficiary")
	var again := restore_checkpoint(restored, "user://parent-after-mortality.bin", true)
	if again != null:
		FamilyControlEngine.new(again).handle_spousal_estate_inheritance({"npc_id": 41})
		check(again.player.bank_balance == 130 and again.get_npc_by_id(41).bank_balance == 0,
			"A repeated death delivery after saving the heir repeated or lost the payment")



func test_world_and_dormant_mortality() -> void:
	var state := new_state()
	var owner: Person = state.npcs[0]
	var child := state.player
	owner.age = 90
	var world := WorldEngine.new(state)
	for year in range(1800, 1900):
		world._world_vitality_event_for_npc(owner, year, "normal", "Industrial Era")
		if not owner.alive:
			break
	check(not owner.alive and child.bank_balance == 130, "A newly deceased world-vitality parent left the estate unpaid")
	world._world_vitality_event_for_npc(owner, state.year, "normal", "Industrial Era")
	check(child.bank_balance == 130, "Reporting an existing death paid the estate again")

	state = new_state()
	owner = state.npcs[0]
	owner.health = 0
	state.health_engine = null
	check(state.sync_person_death_state_from_health(owner) and state.player.bank_balance == 130,
		"A health-depleted parent died before lazy engine startup and left the estate unpaid")

	state = new_state()
	owner = state.npcs[0]
	child = state.player
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(owner, {"import_legacy_balance": true})
	state.bank_engine.set_account_status(account.account_id, "frozen")
	var snapshot: Dictionary = state._serialize_npc(owner)
	snapshot["alive"] = false
	snapshot["health"] = 0
	snapshot["cause_of_death"] = "Old age"
	state.npcs.erase(owner)
	state._rebuild_npc_index()
	state._finalize_dormant_death(snapshot, 41, true)
	var claim: Dictionary = state.scenario_state.get(FamilyContractEngine.PENDING_LINEAGE_ESTATES, {}).get("41", {})
	check(claim.get("heir_id") == child.id and child.bank_balance == 20,
		"Finalizing the dormant parent lost the heir or paid frozen funds")
	var restored_owner: Person = state.get_npc_by_id(41)
	if restored_owner != null:
		var offer := state._try_apply_family_inheritance(restored_owner, "Mother")
		check(not offer.get("inherited", false), "A funeral offered a separate payment drawn from the frozen estate")
	state.bank_engine.set_account_status(account.account_id, "open")
	check(child.bank_balance == 130, "Reopening the dormant parent's account did not release the estate")


func test_founder_death_before_choice() -> void:
	var state := new_state()
	var founder: Person = state.npcs[0]
	var first_child := state.player
	var chosen_child := Person.new()
	chosen_child.id = 43
	chosen_child.parents = [founder.id]
	chosen_child.bank_balance = 5
	founder.children.append(chosen_child.id)
	state.npcs.append(chosen_child)
	state.player = founder
	state.player_id = founder.id
	state._rebuild_npc_index()
	founder.alive = false
	var family := FamilyControlEngine.new(state)
	family.handle_spousal_estate_inheritance({"npc_id": founder.id})
	check(founder.bank_balance == 110 and first_child.bank_balance == 20,
		"Death delivery before the choice screen paid the default heir")
	var estate := AfterlifeInfluenceEngine.new(state)._transfer_player_estate_to_descendant(founder, chosen_child)
	check(estate.success and estate.heir_id == chosen_child.id and chosen_child.bank_balance == 115,
		"The chosen child did not receive the reserved estate")
	var repeated: Dictionary = state.family_contract_engine.execute_estate_contract(founder, chosen_child)
	var other: Dictionary = state.family_contract_engine.execute_estate_contract(founder, first_child)
	check(repeated.success and not other.success and chosen_child.bank_balance == 115 and first_child.bank_balance == 20,
		"An already settled estate was paid again or attributed to another heir")


func test_player_estate(transfer_estate: bool) -> void:
	var state := new_state()
	var deceased: Person = state.npcs[0]
	var heir := state.player
	deceased.alive = false
	state.player = deceased
	state.player_id = deceased.id
	state.afterlife_active = true
	state.afterlife_state = {"ghost_player_id": 41, "manual_player_inheritance_authority": true,
		"continue_lineage_commit_intent": {"deceased_actor_id": 41, "target_actor_id": 42, "transfer_estate": transfer_estate}}
	FamilyControlEngine.new(state).handle_spousal_estate_inheritance(deceased)
	check(heir.bank_balance == 20, "NPC inheritance consumed a manually controlled estate")
	state.universal_switch_contract_engine = UniversalSwitchContractEngine.new(state)
	state.relationships_hub_contract_engine = RelationshipsHubContractEngine.new(state, state.universal_switch_contract_engine)
	var revision := "%d:%d:%d" % [heir.id, state.year, heir.age]
	var lens := {"actor_id": heir.id, "world_year": state.year, "age": heir.age, "life_diary_text": "My life"}
	var surface := {"actor_id": heir.id, "world_year": state.year, "age": heir.age, "pointer_revision": revision}
	state.scenario_state["profile_pointer_packet_by_actor"] = {str(heir.id): {"actor_id": heir.id,
		"pointer_revision": revision, "world_year": state.year, "surface_contract": surface,
		"press_frame_lens_cache": lens, "life_diary_lines": ["My life"], "pointer_only_profile_packet": true}}
	state.property_engine = PropertyEngine.new(state)
	state.property_engine.properties[deceased.id] = [{"id": 98}]
	state.belongings_engine = BelongingsEngine.new(state)
	state.belongings_engine.add_item(heir, {"id": 71, "display_name": "My book"}, "Books")
	state.belongings_engine.add_item(deceased, {"id": 72, "display_name": "Family journal"}, "Books")
	state.vehicle_engine._register_vehicle_for_owner(deceased, {"id": 73, "display_name": "Bicycle"})
	state.scenario_state["life_diary_state_by_npc"] = {"42": {"entries": [["2000", "Age: 0", "My life"]]}}
	var account: Dictionary = state.bank_engine.ensure_bank_account_for_actor(deceased, {"import_legacy_balance": true})
	state.bank_engine.set_account_status(account.account_id, "frozen")
	var result := AfterlifeInfluenceEngine.new(state)._commit_continue_lineage_intent_if_hot()
	check(result.get("type") == "continue_lineage_complete" and state.player_id == heir.id and state.afterlife_state.is_empty(),
		"Continuing as the heir did not complete the actual profile switch")
	if result.is_empty():
		return
	if not transfer_estate:
		state.bank_engine.set_account_status(account.account_id, "open")
		FamilyControlEngine.new(state).handle_spousal_estate_inheritance({"npc_id": deceased.id})
		check(not result.inheritance_transferred and heir.bank_balance == 20 and deceased.bank_balance == 110
			and state.vehicle_engine.vehicles.has(deceased.id),
			"A delayed death event overrode the choice to continue without inheritance")
		deceased.death_year += 1
		check(not state.should_skip_manual_player_inheritance(deceased.id),
			"A previous succession choice remained active for a later death")
		return
	check(not result.inheritance_transferred and state.property_engine.properties.get(heir.id, []).size() == 1,
		"A frozen estate misreported payment or prevented inheriting property")
	var scene := diary_scene(state)
	scene._show_age_up_output(result)
	check_estate_notice(scene, "on switch")
	check(state.belongings_engine.get_category_items(heir, "Books").size() == 2
		and state.belongings_engine.get_category_items(heir, "Vehicles").is_empty()
		and state.belongings_engine.get_category_items(deceased, "Vehicles").size() == 1,
		"Lineage continuation replaced existing possessions or released the restricted vehicle")
	var loaded := restore_checkpoint(state, "user://pending-lineage.bin", true)
	if loaded == null:
		return
	var restored_scene := diary_scene(loaded)
	restored_scene.set_meta("checkpoint_resume_life_diary_active", true)
	restored_scene.set_meta("title_card_checkpoint_resume_lens_prewarm_contract",
		loaded._read_saved_life_summary_cache("user://pending-lineage.bin").checkpoint_resume_contract)
	check(restored_scene._render_checkpoint_resume_life_diary_packet_only(), "Continue did not render the saved diary")
	check_estate_notice(restored_scene, "after Continue")
	var claims: Dictionary = loaded.scenario_state.get(FamilyContractEngine.PENDING_LINEAGE_ESTATES, {})
	check(int(claims.get("41", {}).get("heir_id", -1)) == 42 and loaded.player.bank_balance == 20,
		"Continue lost the designated heir or paid a restricted estate")
	loaded.bank_engine.set_account_status(account.account_id, "open")
	check(claims.is_empty() and loaded.player.bank_balance == 130 and loaded.bank_engine.accounts[account.account_id].balance == 0,
		"Reopening the account did not settle the saved claim")
	check(loaded.belongings_engine.get_category_items(loaded.player, "Vehicles").size() == 1
		and loaded.belongings_engine.get_category_items(loaded.get_npc_by_id(41), "Vehicles").is_empty()
		and loaded.belongings_engine.get_category_items(loaded.player, "Books").size() == 2,
		"The restored heir's inventory disagrees with the settled estate")
	var count: int = loaded.bank_engine.ledger.size()
	loaded.family_contract_engine.retry_pending_lineage_estates()
	check(loaded.player.bank_balance == 130 and loaded.bank_engine.ledger.size() == count,
		"A settled claim paid the heir twice")

func restore_checkpoint(state: GameState, save_path: String, interactive: bool = false) -> GameState:
	var serializer := GameStateSerializationRuntime.new(state)
	var saved := serializer.save_interactive_reality_checkpoint(save_path) if interactive else serializer.serialize_to_path(
		save_path, {"checkpoint_save": true, "fast_interactive_universe_save": true})
	check(saved.get("success", false), "Could not save the pending estate")
	if not saved.get("success", false):
		return null
	var payload: Dictionary = BinarySaveEngine.decode(FileAccess.get_file_as_bytes(save_path))
	var loaded := GameState.create_resident_chassis_shell()
	loaded.resident_runtime_bootstrap_complete = true
	var summary: Dictionary = loaded._read_saved_life_summary_cache(save_path)
	var resume: Dictionary = summary.get("checkpoint_resume_contract", {})
	check(int(resume.get("actor_id", -1)) == state.player_id, "The saved life has no resume contract for the heir")
	var shell := RealityResidencyManager.new(loaded)._materialize_checkpoint_resume_shell(loaded,
		resume, "estate-checkpoint", {})
	check(shell.get("success", false), "Could not restore the heir's checkpoint shell")
	loaded.era = {"name": payload.era_name}
	loaded.bank_engine = BankEngine.new(loaded)
	loaded.vehicle_engine = VehicleEngine.new(loaded)
	loaded.belongings_engine = BelongingsEngine.new(loaded)
	var hydration := GameStateHydrationRuntime.new(loaded)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household": payload.npcs},
		{"resident_restore": true, "runtime_scene_tree_access_allowed": false, "strict_one_item_per_slice": true})
	for step in 20000:
		if not hydration.is_background_hydration_active():
			break
		hydration.run_background_hydration_slice(50)
	check(not hydration.is_background_hydration_active(), "Checkpoint hydration did not finish")
	loaded._rebuild_npc_index()
	return loaded


func test_vehicle() -> void:
	var state := new_state()
	var seller := state.player
	var bank: BankEngine = state.bank_engine
	var vehicles: VehicleEngine = state.vehicle_engine
	seller.bank_balance = 1000
	var account := bank.ensure_bank_account_for_actor(seller, {"import_legacy_balance": true})
	state.belongings_engine = BelongingsEngine.new(state)
	bank.set_account_status(account.account_id, "frozen")
	var history: Array = state.belongings_engine._world_state().get("belongings_ledger", []).duplicate(true)
	var bank_history := bank.ledger.size()
	var rejected := vehicles.buy_vehicle(seller, {"display_name": "Bicycle"}, 100, 0, {"storage_destination_id": "belongings"})
	check(not rejected.success and vehicles.vehicles.is_empty() and state.belongings_engine.get_category_items(seller, "Vehicles").is_empty(),
		"A frozen purchase created a vehicle or belongings entry")
	check(state.belongings_engine._world_state().get("belongings_ledger", []) == history and bank.ledger.size() == bank_history
		and bank.accounts[account.account_id].balance == 1000, "Rejected purchase wrote acquisition history or changed funds")
	bank.set_account_status(account.account_id, "open")
	var result := vehicles.buy_vehicle(seller, {"display_name": "Bicycle"}, 100, 0, {"storage_destination_id": "belongings"})
	check(result.success and seller.bank_balance == 900, "Vehicle purchase did not debit its bank account")
	if not result.success:
		return
	var id := int(result.asset_id)
	vehicles.vehicles[41] = vehicles.vehicles[42].duplicate(true)
	bank.set_account_status(account.account_id, "sanctioned")
	check(not vehicles.run_asset_action(seller, id, "sell").success and vehicles.vehicles[42].size() == 1 and vehicles.vehicles[41].size() == 1,
		"A blocked sale removed an owned vehicle")
	bank.set_account_status(account.account_id, "open")
	var sold := vehicles.run_asset_action(seller, id, "sell")
	var sale_amount := float(bank.ledger.back().data.amount)
	bank.repair_legacy_player_money_mirror()
	check(sold.success and sale_amount >= 78 and sale_amount <= 105 and seller.bank_balance == 900 + sale_amount,
		"A vehicle sale failed to settle the actual price")
	check(not vehicles.run_asset_action(state.npcs[0], id, "sell").success,
		"Another owner could sell the same vehicle again")
	var seller_balance := float(seller.bank_balance)
	vehicles.vehicles[41] = [{"id": 102, "value": 100}]
	var trade := vehicles.trade_vehicle_between_npcs(state.npcs[0], seller, 102)
	check(trade.success and vehicles.vehicles[41].is_empty() and vehicles.vehicles[42].size() == 1,
		"NPC market did not transfer the vehicle")
	var trade_price := float(bank.ledger.back().data.amount)
	bank.repair_legacy_player_money_mirror()
	check(seller.bank_balance == seller_balance - trade_price and state.npcs[0].bank_balance == 110 + trade_price,
		"NPC trade balances disagreed with the bank ledger")


func test_maintenance_projection() -> void:
	var state := new_state()
	state.year = 2000
	state.player.bank_balance = 1000
	state.belongings_engine = BelongingsEngine.new(state)
	var result: Dictionary = state.vehicle_engine.buy_vehicle(
		state.player, {"display_name": "Bicycle"}, 100, 0, {"storage_destination_id": "belongings"}
	)
	check(result.get("success", false), "Maintenance fixture could not buy its bicycle")
	if not result.get("success", false):
		return
	var ledger: Array = state.belongings_engine._world_state().get("belongings_ledger", [])
	check(ledger.any(func(event): return event.event_type == "item_acquired" and event.item_id == result.asset_id),
		"Acquiring a vehicle did not publish an acquisition")
	var event_count := ledger.size()
	state.year += 1
	state.vehicle_engine.yearly_maintenance()
	var mirror: Array = state.belongings_engine.get_category_items(state.player, "Vehicles")
	var asset: Dictionary = state.vehicle_engine.vehicles[state.player.id][0]
	check(mirror.size() == 1 and mirror[0].condition == asset.condition and mirror[0].value == asset.value and asset.condition < 100.0,
		"Annual maintenance did not update the same vehicle's condition and value")
	check(state.belongings_engine._world_state().get("belongings_ledger", []).size() == event_count,
		"Annual maintenance published a belongings transaction")
