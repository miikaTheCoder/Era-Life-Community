extends "test_life_stories.gd"

var choices_checked := 0

func _business_fixture() -> GameState:
	var state := _fixture(60)
	state.npcs[1].age = 85
	state.npcs[2].age = 55
	state.npcs[3].age = 75
	var child := Person.new()
	child.id = 106
	child.first_name = "Sam"
	child.last_name = "Story"
	child.age = 36
	child.affection = {103: 50}
	child.parents = [101]
	child.bank_balance = 500
	state.player.children = [106]
	state.npcs.append(child)
	var grandchild := Person.new()
	grandchild.id = 107
	grandchild.first_name = "Lee"
	grandchild.last_name = "Story"
	grandchild.age = 18
	grandchild.parents = [106]
	child.children = [107]
	state.npcs.append(grandchild)
	state._rebuild_npc_index()
	return state

func _found(state: GameState) -> Dictionary:
	_only(state, "family_business")
	state.scenario_runtime_contract_engine.service_life_stories()
	var result := _choose(state, "family_business", "found")
	_check(result.get("success", false), "Business founding failed: " + str(result))
	return _instance(state, "family_business")

func _chapter(state: GameState, record: Dictionary, node: String) -> void:
	state.scenario_runtime_contract_engine.active_popup_contracts.clear()
	record.node = node
	record.status = "waiting"
	record.due_year = int(state.year)
	if node == "loss":
		record.lost_person = "Robin Story"
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _business(state: GameState, record: Dictionary) -> Dictionary:
	return state.scenario_state.family_businesses.ventures[str(record.venture_id)]

func _run() -> void:
	var engine := LifeStoryEngine.new()
	_check(engine.content_errors.is_empty(), "Shared Lives content failed validation: " + str(engine.content_errors))
	_check(engine.catalog.size() == 10, "Launch stories or Shared Lives chapters were lost")
	_test_each_response(engine)
	_test_complete_saga()
	_test_business_money()
	_test_bank_world_transition()
	_test_partner_decisions()
	_test_succession()
	_test_shared_checkpoint()
	_test_absent_and_dead_cast()
	print("SHARED LIVES TESTS: ", "FAIL" if failed else "PASS", "; authored responses=", choices_checked)
	quit(1 if failed else 0)

func _test_each_response(engine: LifeStoryEngine) -> void:
	for definition in engine.catalog:
		if str(definition.get("series", "")) != "Shared Lives":
			continue
		for node_id in definition.nodes:
			for choice in definition.nodes[node_id].choices:
				var state := _business_fixture()
				var record: Dictionary
				if str(node_id) == "offer":
					_only(state, "family_business")
					state.scenario_runtime_contract_engine.service_life_stories()
					record = _instance(state, "family_business")
				else:
					record = _found(state)
					if not record.has("venture_id"):
						continue
					var venture := _business(state, record)
					state.bank_engine.credit_bank(venture.bank_owner, 5000, venture.world_id)
					if str(definition.id) == "family_business_heir":
						# Use the real stake transfer, then the controlled-life switch.
						state.scenario_runtime_contract_engine.life_story_engine.businesses().apply(state.player, record, {"action": "handover"})
						_switch_to_child(state)
						record = state.scenario_state.life_stories.actors["106"].stories.family_business_heir
					_chapter(state, record, str(node_id))
				var pending := _pending(state, str(definition.id))
				_check(not pending.is_empty(), "Missing Shared Lives chapter " + str(node_id))
				if pending.is_empty():
					continue
				_check(not str(pending.overview).contains("{cofounder}") and not str(pending.overview).contains("{business}"), "Unrendered cast or company token")
				var result: Dictionary = state.pending_situations_engine.resolve_pending_contract(str(pending.id), str(choice.id), {"viewer_actor_id": state.player.id})
				_check(result.get("success", false), "%s/%s failed: %s" % [str(node_id), str(choice.id), str(result)])
				var replay: Dictionary = state.scenario_runtime_contract_engine.resolve_popup_contract(str(pending.id), str(choice.id), {"viewer_actor_id": state.player.id})
				_check(not replay.get("success", true), "A business response resolved twice")
				choices_checked += 1
	_check(choices_checked == 46, "Not every Shared Lives response was exercised")

func _test_business_money() -> void:
	var state := _business_fixture()
	var record := _found(state)
	if not record.has("venture_id"):
		return
	var owner = state.scenario_runtime_contract_engine.life_story_engine.businesses()
	var venture := _business(state, record)
	_check(state.player.bank_balance == 8800 and owner.balance(venture) == 1200, "Opening investment did not move real money")
	_check(venture.stakes == {"101": 60, "103": 40}, "Founding shares are wrong")
	_check(record.ensemble.size() == 2 and int(record.ensemble.cofounder.id) == 103 and int(record.ensemble.mentor.id) == 102, "Ensemble did not retain distinct existing people")
	var before := JSON.stringify(venture)
	var report: Dictionary = owner.apply(state.player, record, {"action": "draw", "amount": 2000})
	_check(not report.success and JSON.stringify(venture) == before and state.player.bank_balance == 8800, "Failed draw changed ownership or money")
	report = owner.apply(state.player, record, {"action": "invest", "amount": 300})
	_check(report.success and state.player.bank_balance == 8500 and owner.balance(venture) == 1500, "Investment bypassed BankEngine")
	report = owner.apply(state.player, record, {"action": "expense", "amount": 250, "quality": 5})
	_check(report.success and owner.balance(venture) == 1250 and int(venture.quality) == 55, "Business expense changed the wrong wallet")
	state.year += 2
	owner.service_actor(state.player)
	var settled: int = owner.balance(venture)
	owner.service_actor(state.player)
	owner.service_actor(state.get_npc_by_id(103, false))
	_check(owner.balance(venture) == settled and settled > 1250, "Same-year service or another owner doubled company income")
	state.bank_engine.set_account_status(venture.account_id, "frozen")
	var personal_before_freeze: int = state.player.bank_balance
	_check(not owner.apply(state.player, record, {"action": "invest", "amount": 100}).success
		and state.player.bank_balance == personal_before_freeze and owner.balance(venture) == settled,
		"Investment bypassed the company's frozen account")
	state.year += 1
	owner.service_actor(state.player)
	_check(owner.balance(venture) == settled and int(venture.last_year) == int(state.year) - 1, "Frozen company lost its retryable settlement")
	state.bank_engine.set_account_status(venture.account_id, "open")
	owner.service_actor(state.player)
	_check(owner.balance(venture) > settled and int(venture.last_year) == state.year, "Unfreezing did not settle the missed year")
	var old_bank: int = state.player.bank_balance
	var old_reserve: int = owner.balance(venture)
	report = owner.apply(state.player, record, {"action": "leave"})
	_check(report.success and int(state.player.bank_balance) - old_bank == int(floor(old_reserve * 0.6)), "Exit did not pay the exact liquid stake")
	_check(owner.ventures_for(101).is_empty() and int(venture.stakes["103"]) == 100, "Exit left duplicate ownership")
	_check(not owner.apply(state.player, record, {"action": "leave"}).success, "A former owner cashed out twice")
	# Era transitions do not silently reprice an existing partnership.
	state = _business_fixture()
	record = _found(state)
	state.era.name = "Future Era"
	_chapter(state, record, "expansion")
	_choose(state, "family_business", "invest")
	_check(state.player.bank_balance == 8300, "Era change repriced a fixed business investment")

func _test_bank_world_transition() -> void:
	var state := _business_fixture()
	state.player.realm_id = -1
	var bank: BankEngine = state.bank_engine
	var provisional: Dictionary = bank.ensure_bank_account_for_actor(state.player, {"import_legacy_balance": true})
	state.player.realm_id = 3
	var resolved: Dictionary = bank.ensure_bank_account_for_actor(state.player, {"import_legacy_balance": true})
	_check(float(resolved.balance) == 0 and float(bank.get_owner_summary_for_actor(state.player).bank_balance) == 10000,
		"World hydration imported the legacy balance twice")
	bank.repair_legacy_player_money_mirror()
	_check(state.player.bank_balance == 10000, "Mirror repair copied money into another realm")
	bank.spend(bank.owner_key_from_actor(state.player), 10000, str(provisional.world_id))
	state.player.bank_balance = 10000 # Deliberately stale legacy mirror.
	bank.repair_legacy_player_money_mirror()
	_check(state.player.bank_balance == 0, "Repair recreated spent money")
	var saved: Dictionary = bank.export_state()
	state.player.bank_balance = 10000
	bank.import_state(saved)
	_check(state.player.bank_balance == 0, "Restoring empty accounts resurrected a stale legacy balance")

func _test_partner_decisions() -> void:
	for trust in [25, 75]:
		var state := _business_fixture()
		var record := _found(state)
		state.player.affection[103] = trust
		_chapter(state, record, "accounts")
		_choose(state, "family_business", "listen")
		_check(str(record.node) == ("ultimatum" if trust < 45 else "expansion"), "Cofounder's own response ignored the relationship")
		_advance_to_due(state, "family_business")
		_check(str(_pending(state, "family_business").overview).contains("Casey Story"), "Follow-up replaced the partner")
	var state := _business_fixture()
	var record := _found(state)
	_chapter(state, record, "work")
	var before: int = state.get_npc_by_id(103, false).affection.get(102, 50)
	_choose(state, "family_business", "train")
	_check(int(state.get_npc_by_id(103, false).affection.get(102, 50)) > before, "Choice did not change the relationship between two NPCs")

func _switch_to_child(state: GameState) -> void:
	state.player = state.get_npc_by_id(106, false)
	state.player_id = 106
	state.scenario_runtime_contract_engine.life_story_engine.catalog = LifeStoryEngine.new().catalog.filter(func(row): return str(row.id) == "family_business_heir")
	state.scenario_runtime_contract_engine.life_story_service_signature = ""
	state.scenario_runtime_contract_engine.service_life_stories()

func _test_succession() -> void:
	for handover in [true, false]:
		var state := _business_fixture()
		var parent := state.player
		var record := _found(state)
		var venture := _business(state, record)
		var owner = state.scenario_runtime_contract_engine.life_story_engine.businesses()
		parent.affection[103] = 25
		if handover:
			_chapter(state, record, "succession")
			_check(_choose(state, "family_business", "handover").get("success", false), "Living handover failed")
		else:
			parent.alive = false
		_switch_to_child(state)
		_check(int(venture.stakes.get("106", 0)) == 60 and not venture.stakes.has("101"), "Succession duplicated or lost the stake")
		_check(int(venture.manager_id) == 106 and owner.balance(venture) == 1200, "Succession lost management or bank reserves")
		_check(int(state.player.affection.get(103, 50)) == 30, "Inherited family tension was not remembered by the original cofounder")
		var pending := _pending(state, "family_business_heir")
		_check(not pending.is_empty() and str(pending.overview).contains("Casey Story"), "Descendant's chapter lost the founding cast")
		owner.service_actor(state.player)
		_check(int(venture.stakes["106"]) == 60 and int(state.player.affection.get(103, 50)) == 30, "Succession was replayed on maintenance")
		var result: Dictionary = state.pending_situations_engine.resolve_pending_contract(str(pending.id), "read", {"viewer_actor_id": 106})
		_check(result.get("success", false), "Descendant could not play the inherited story")
	var state := _business_fixture()
	var record := _found(state)
	state.player.children.clear()
	_chapter(state, record, "succession")
	var before := JSON.stringify(_business(state, record))
	_check(not _choose(state, "family_business", "handover").get("success", true), "Handover invented a child")
	_check(JSON.stringify(_business(state, record)) == before and str(record.status) == "pending", "Rejected handover mutated the business")
	_check(_choose(state, "family_business", "keep").get("success", false), "No-child household lacked a playable alternative")

func _test_shared_checkpoint() -> void:
	var state := _business_fixture()
	var record := _found(state)
	var venture := _business(state, record)
	state.bank_engine.credit_bank(venture.bank_owner, 731, venture.world_id)
	var payload: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()))
	_check(not payload.get("bank_engine_state", {}).get("ledger", []).is_empty(), "Checkpoint lost the business transaction history")
	_check(payload.has("bank_engine_state") and payload.bank_engine_state.accounts.has(venture.account_id), "Checkpoint omitted the company account")
	for id in [101,102,103,106]:
		_check(payload.npcs.any(func(row): return int(row.id) == id), "Checkpoint omitted shared cast or heir %d" % id)
	var restored := GameState.new()
	var snapshot: Dictionary = payload.npcs.filter(func(row): return int(row.id) == 101)[0]
	var shell: Dictionary = RealityResidencyManager.new(restored)._materialize_checkpoint_resume_shell(restored,
		{"actor_id":101,"actor_snapshot":snapshot,"year":payload.year}, "shared-life-checkpoint", {})
	_check(shell.get("success", false), "Shared story checkpoint shell failed")
	restored.era = {"name":payload.era_name}
	restored.bank_engine = BankEngine.new(restored)
	# A live runtime can have a partial contract registry. Compact checkpoint
	# banking must still load even when another slice makes that registry nonempty.
	restored.game_state_contract_engine = GameStateContractEngine.new(restored)
	restored.game_state_contract_engine.save_slice_registry = {
		"life_diary_contract_engine_state": {"id": "life_diary_contract_engine_state", "save_key": "life_diary_contract_engine_state", "engine_id": "life_diary_contract_engine", "import_method": "import_state"}
	}
	var hydration := GameStateHydrationRuntime.new(restored)
	hydration.begin_resident_checkpoint_spatial_hydration(payload, {"household":payload.npcs,"city":[],"realm":[],"world":[]},
		{"resident_restore":true,"runtime_scene_tree_access_allowed":false,"strict_one_item_per_slice":true})
	var steps := 0
	while hydration.is_background_hydration_active() and steps < 20000:
		hydration.run_background_hydration_slice(50)
		steps += 1
	_check(not hydration.is_background_hydration_active(), "Shared Lives hydration did not finish")
	restored._rebuild_npc_index()
	var business := FamilyBusinessEngine.new(restored)
	_check(business.ventures_for(101).size() == 1, "Restored life lost the family business")
	if business.ventures_for(101).is_empty():
		return
	var saved: Dictionary = business.ventures_for(101)[0]
	_check(business.balance(saved) == 1931 and int(restored.player.bank_balance) == 8800, "Hydration did not restore exact company and personal balances")
	business.service_actor(restored.player)
	_check(business.balance(saved) == 1931, "Loading awarded the same year's income twice")
	_check(saved.cast == JSON.parse_string(JSON.stringify(venture.cast)), "Checkpoint silently replaced the ensemble")
	# Projection is read-only and includes a counted real ownership row.
	var portfolio: Dictionary = business.portfolio(101)
	_check(portfolio.rows.size() == 1 and portfolio.text.contains("1931"), "Wealth contract omitted the company's reserve")
	var assets := AssetsContractEngine.new(restored)
	var contract: Dictionary = assets.emit_assets_surface_contract(restored.player)
	_check(contract.get("business_asset_rows", []).size() == 1 and int(contract.total_asset_count) == 1, "Assets authority omitted or failed to count the stake")
	assets.invalidate_actor(101)
	var observation: Dictionary = {}
	for step in range(1000):
		observation = assets.service_actor_portfolio_observation_quantum(restored.player)
		if bool(observation.get("complete", false)):
			break
	var live_contract: Dictionary = observation.get("assets_surface_contract", {})
	_check(live_contract.get("business_asset_rows", []).size() == 1 and int(live_contract.get("total_asset_count", 0)) == 1,
		"Incremental Assets publication dropped the company stake")
	var panel := AssetsPanel.new()
	root.add_child(panel)
	panel.open_observable_partial(restored.player)
	panel.apply_progressive_surface_patch(observation.get("surface_patch", {}))
	_check(panel.securities_label.text.contains("1931") and panel.wealth_label.text.contains("Controlled Assets: 1"),
		"Published company was absent from the visible Assets labels")
	panel.free()

func _test_absent_and_dead_cast() -> void:
	var state := _business_fixture()
	var record := _found(state)
	var mentor: Person = state.get_npc_by_id(102, false)
	state.npcs.erase(mentor)
	state._rebuild_npc_index()
	_advance_to_due(state, "family_business")
	_check(_pending(state, "family_business").is_empty() and str(record.node) == "agreement", "Temporarily absent mentor was recast or treated as dead")
	state.npcs.append(mentor)
	state._rebuild_npc_index()
	mentor.alive = false
	state.year += 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(str(record.node) == "loss" and str(record.lost_person) == "Robin Story", "Death did not surface the named bereavement chapter")
	_check(_choose(state, "family_business", "remember").get("success", false), "Bereavement chapter could not be resolved")
	_check(state.scenario_runtime_contract_engine.life_story_engine.businesses().balance(_business(state, record)) > 0, "A cast death deleted the business reserve")
	# Ignoring a chapter still follows an authored, cost-free response.
	state = _business_fixture()
	_only(state, "family_business")
	state.scenario_runtime_contract_engine.service_life_stories()
	record = _instance(state, "family_business")
	state.year = int(record.deadline_year) + 1
	state.scenario_runtime_contract_engine.service_life_stories()
	_check(str(record.status) == "finished" and int(state.player.bank_balance) == 10000, "Expired offer spent money or stayed pending")

func _test_complete_saga() -> void:
	var state := _business_fixture()
	var record := _found(state)
	for option in ["shared", "smaller", "rotate", "reduce", "open", "stay", "scale_back", "steady", "keep", "reserve"]:
		_advance_to_due(state, "family_business")
		_check(_choose(state, "family_business", option).get("success", false), "Complete saga failed at " + option)
	_check(str(record.status) == "finished" and record.history.size() == 11, "Complete founder saga did not retain every chapter exactly once")
	_check(int(state.year) == 2015, "The saga did not unfold over its authored years")
	_check(_business(state, record).legacy == "reserves_and_promises", "Founder's last choice did not become the company's inherited legacy")
