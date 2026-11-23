extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func check_movie_ticket() -> void:
	var state := GameState.new()
	state.era = {"name":"Modern Era"}
	var customer := Person.new()
	customer.id = 25
	customer.bank_balance = 10
	state.player = customer
	state.npcs.append(customer)
	state.bank_engine = BankEngine.new(state)
	state.food_engine = FoodEngine.new(state)
	var theater := MovieTheaterEngine.new(state)
	theater.select_theater(customer, "crown_8_cinemas")
	theater.select_movie(customer, "night_house_iii")
	theater.stand_in_ticket_line(customer)
	for step in 5:
		if theater.movie_theater_surface_state_for_actor(customer).line_ready:
			break
		theater.advance_ticket_line(customer)
	check(not theater.buy_ticket(customer).success, "An unaffordable ticket cannot be issued")
	state.bank_engine.credit_bank("person:25", 90)
	check(theater.buy_ticket(customer).success, "An affordable ticket is issued")
	var balance: Dictionary = state.bank_engine.get_owner_summary("person:25")
	check(balance.bank_balance == 86.5 and balance.cash_on_hand == 0, "Ticket price leaves the customer's funds")
	var charges: int = state.bank_engine.ledger.size()
	theater.select_movie(customer, "night_house_iii")
	check(not theater.buy_ticket(customer).success and state.bank_engine.ledger.size() == charges, "An existing ticket cannot be charged twice")
	var lobby: Dictionary = theater.get_movie_lobby_rows({})[0]
	check(str(lobby.description).begins_with("Ticket bought."), "Lobby recognizes the paid ticket")
	check(theater.movie_theater_surface_state_for_actor(customer).paid_total == 13.5, "One purchase recorded")
	var visitor := Person.new()
	visitor.id = 26
	visitor.realm_id = 12
	state.npcs.append(visitor)
	state.bank_engine.credit_bank("person:26", 20, "realm:12")
	var meal: Dictionary = state.food_engine._pay_for_food(visitor, 7)
	check(meal.success and visitor.bank_balance == 13, "A visiting NPC pays from their own realm")
	state.bank_engine = null
	state.food_engine = null

func check_legacy_routed_owner() -> void:
	var owner := "life:node_a"
	var account_id := "acct.life_node_a.earth.bank.usd"
	var wallet_id := "cash.life_node_a.earth.usd"
	var old_save := {"accounts": {account_id: {"account_id": account_id, "owner_id": owner, "world_id": "earth",
		"currency": "USD", "type": "bank", "balance": 50.0, "status": "frozen"}},
		"cash_on_hand": {wallet_id: {"wallet_id": wallet_id, "owner_id": owner, "world_id": "earth", "currency": "USD", "amount": 13.0}},
		"ledger": [{"tx_id": "tx_1", "data": {"owner_id": owner, "amount": 50.0}}], "tx_seq": 1}
	var exact := {"life_node_id": "node-a", "world_id": "earth"}
	var colliding := {"life_node_id": "node_a", "world_id": "earth"}
	var state := GameState.new()
	var bank := BankEngine.new(state)
	bank.import_state(old_save)
	for context in [exact, colliding]:
		var blocked := bank.request_bank_action({"action": "summary"}, context)
		check(blocked.get("code") == "legacy_owner_recovery_required", "A routed spelling claimed an unverified old balance")
	check(bank.cash_on_hand.size() == 1 and bank.ledger.size() == 1, "Unresolved ownership changed the old ledger or wallet")
	state.scenario_state["external_birth_intent"] = {"world_mode": "solo", "life_node_id": "node-a"}
	var other := bank.request_bank_action({"action": "summary"}, colliding)
	check(other.success and other.summary.total_accessible == 0, "A colliding route accessed the original owner's wallet")
	var restored := bank.route_command_envelope({"command": "bank.balance", "context": exact})
	check(restored.success and restored.summary.bank_balance == 50 and restored.summary.total_accessible == 13,
		"The original solo life did not regain its wallet and frozen account")
	check(not bank.request_bank_action({"action": "withdraw", "amount": 1}, exact).success, "Restoring ownership cleared a freeze")
	var snapshot := bank.export_checkpoint_state([restored.summary.owner_id])
	var round_trip := BankEngine.new()
	round_trip.import_state(BinarySaveEngine.decode(BinarySaveEngine.encode(snapshot)))
	check(round_trip.request_bank_action({"action": "summary"}, exact).summary.cash_on_hand == 13
		and round_trip.ledger == old_save.ledger, "A second load lost the verified identity or history")
	round_trip.set_account_status(account_id, "open")
	var withdrawal := round_trip.request_bank_action({"action": "withdraw", "amount": 5}, exact)
	check(withdrawal.success and round_trip.accounts[account_id].balance == 45 and round_trip.cash_on_hand[wallet_id].amount == 18,
		"A verified legacy route did not withdraw from the original account into the original wallet")
	state.player = Person.new()
	state.player.id = 87
	state.player_id = 87
	state.npcs = [state.player]
	state.bank_engine = bank
	var compact := GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()
	check(compact.bank_engine_state.cash_on_hand.has(wallet_id) and compact.scenario_state.has("external_birth_intent"),
		"The next ordinary checkpoint dropped the verified solo owner's funds or route")
	check(not round_trip.recover_legacy_routed_owner(owner, colliding).success, "A later identity replaced a verified binding")
	var recovered := BankEngine.new()
	recovered.import_state(old_save)
	check(recovered.recover_legacy_routed_owner(owner, exact).success
		and recovered.request_bank_action({"action":"summary"}, exact).summary.bank_balance == 50,
		"A verified host recovery could not restore a standalone legacy export")
	var discord := BankEngine.new()
	var numeric_owner := "discord:123:456"
	var numeric_wallet := "cash.discord_123_456.earth.usd"
	discord.import_state({"cash_on_hand": {numeric_wallet: {"owner_id": numeric_owner, "world_id": "earth",
		"currency": "USD", "wallet_id": numeric_wallet, "amount": 8.0}}})
	var numeric := discord.request_bank_action({"action": "summary"}, {"guild_id": "123", "user_id": "456", "world_id": "earth"})
	check(numeric.success and numeric.summary.cash_on_hand == 8, "A numeric Discord route lost its legacy funds")


func _initialize() -> void:
	check_legacy_routed_owner()
	check_movie_ticket()
	var bank := BankEngine.new()
	bank.credit_bank("family:a-b", 100)
	bank.credit_bank("family:a_b", 25)
	check(bank.get_owner_summary("family:a-b").bank_balance == 100, "Separate account identities")
	check(bank.get_owner_summary("family:a_b").bank_balance == 25, "Second owner receives own credit")
	for node in ["node-a", "node_a"]:
		bank.request_bank_action({"action":"credit_cash", "amount":8}, {"life_node_id":node})
		check(bank.request_bank_action({"action":"summary"}, {"life_node_id":node}).summary.cash_on_hand == 8, "Routed life identities remain separate")
	var account := bank.ensure_account("family:a-b")
	bank.set_account_status(account.account_id, "frozen")
	check(bank.get_owner_summary("family:a-b").total_accessible == 0, "Frozen funds excluded")
	bank.credit_bank("person:9", 100, "earth")
	var transfer := bank.transfer_owner_to_owner("person:9", "person:2", 10, "earth", "USD", {"target_world_id":"mars"})
	check(not transfer.success, "Local transfer stays in its world")

	var actor := Person.new()
	actor.id = 9
	actor.bank_balance = 100
	var payment := bank.settle_obligation_for_actor(actor, 30, {}, {"world_id":"mars"})
	check(not payment.success and bank.get_owner_summary("person:9").bank_balance == 100, "Obligation preserves money across worlds")

	bank.credit_cash("guest", 100, "earth", "EUR")
	var restored := BankEngine.new()
	restored.import_state(bank.export_checkpoint_state(["guest"]))
	check(restored.ensure_cash_wallet("guest", "earth", "EUR").amount == 100, "Cash-only wallet survives checkpoint")
	check(bank.steal_cash("other", "guest", 10, "earth", "EUR", {"governed":true}).success, "Theft checks selected currency")
	restored.import_state(bank.export_checkpoint_state(["guest"]))
	var theft := bank.ledger.back() as Dictionary
	check(theft in restored.ledger, "Victim checkpoint retains the theft history")
	check(bank.export_checkpoint_state(["other", "guest"]).ledger.count(theft) == 1, "Shared checkpoint includes a theft only once")
	var routed_theft := bank.request_bank_action({"action": "steal_cash", "owner_id": "other", "victim_owner_id": "guest",
		"amount": 1, "currency": "EUR", "governed": true}, {"world_id": "earth", "currency": "USD"})
	check(routed_theft.success and routed_theft.currency == "EUR", "Routed theft used a different currency from the transaction")
	bank.set_contract({"permissions":{"max_cash_theft_percent":0.0}})
	check(not bank.steal_cash("other", "guest", 1, "earth", "EUR", {"governed":true}).success, "Zero percentage blocks theft")
	bank.set_contract({})
	var count := bank.ledger.size()
	check(not bank.steal_cash("guest", "guest", 1, "earth", "EUR", {"governed":true}).success and bank.ledger.size() == count, "Self-theft rejected without history")
	check(not bank.credit_bank("guest", INF).success and not bank.credit_bank("guest", NAN).success, "Nonfinite income rejected")
	check(not bank.settle_obligation("guest", INF).success, "Nonfinite obligation cannot report a successful payment")
	var large_bank := BankEngine.new()
	check(large_bank.credit_bank("guest", 1.0e308).success, "Finite income accepted")
	check(not large_bank.credit_bank("guest", 1.0e308).success, "Balance overflow rejected")
	large_bank.credit_cash("guest", 1.0e308)
	check(not large_bank.withdraw("guest", 1.0e308).success and not large_bank.deposit("guest", 1.0e308).success,
		"An overflowing withdrawal or deposit must reject both legs")
	check(large_bank.ensure_cash_wallet("guest").amount == 1.0e308 and large_bank.ensure_account("guest").balance == 1.0e308,
		"A rejected transaction left both original balances intact")
	var snapshot := bank.export_checkpoint_state(["family:a-b"])
	snapshot.ledger[0].data.amount = 12
	check(bank.ledger[0].data.amount == 100, "Checkpoint history independent of live history")

	var state := GameState.new()
	state.npcs.append(actor)
	state.player_id = actor.id
	state.player = actor
	state.entity_registry = {1:{"entity_type":"animal", "owner_person_id":9}}
	state.bank_engine = BankEngine.new(state)
	var debts := DebtContractEngine.new(state)
	var ids := {}
	for i in 12:
		ids[debts.create_education_debt(actor, 10).debt_id] = true
	check(ids.size() == 12, "Every obligation has a unique ID")
	actor.bank_balance = -10
	var report := debts.yearly_tick()
	check(report.reports[0].paid_amount == 0 and report.reports[0].unpaid_amount == 35, "Upkeep cannot produce a negative payment")
	state.bank_engine.credit_bank("person:9", 100)
	debts.yearly_tick()
	state.bank_engine.repair_legacy_player_money_mirror()
	check(actor.bank_balance == 65, "Maintenance payment survives mirror repair")
	state.bank_engine.credit_cash("person:9", 42)
	var payload: Dictionary = GameStateSerializationRuntime.new(state)._build_interactive_checkpoint_payload()
	var decoded: Dictionary = BinarySaveEngine.decode(BinarySaveEngine.encode(payload))
	var restored_state := GameState.new()
	restored_state.scenario_state = decoded.scenario_state
	var restored_debts := DebtContractEngine.new(restored_state)
	var saved_debts: Dictionary = restored_state.scenario_state.get(DebtContractEngine.STATE_KEY, {})
	check(saved_debts.get("debts", []).size() == 13, "Household debts survive checkpoint")
	var next_debt := restored_debts.create_education_debt(actor, 10)
	check(next_debt.debt_id == "debt:v2:9:14", "Debt sequence survives restore")
	var loaded := BankEngine.new()
	loaded.import_state(decoded.get("bank_engine_state", {}))
	check(loaded.get_owner_summary("person:9").cash_on_hand == 42, "Non-business interactive checkpoint preserves cash")
	var legacy := BankEngine.new()
	var old_account := "acct.family_a_b.earth.bank.usd"
	var old_wallet := "cash.family_a_b.earth.usd"
	legacy.import_state({"accounts": {old_account: {"account_id":old_account, "owner_id":"family:a-b", "world_id":"earth", "currency":"USD", "type":"bank", "balance":100}},
		"cash_on_hand": {old_wallet: {"wallet_id":old_wallet, "owner_id":"family:a-b", "world_id":"earth", "currency":"USD", "amount":30}}})
	legacy.credit_bank("family:a_b", 25, "earth")
	legacy.credit_cash("family:a_b", 15, "earth")
	check(legacy.ensure_account("family:a-b", "earth").account_id == old_account, "Legacy account reference preserved")
	check(legacy.ensure_cash_wallet("family:a-b", "earth").wallet_id == old_wallet, "Legacy wallet reference preserved")
	check(legacy.get_owner_summary("family:a-b", {"world_id":"earth"}).total_accessible == 130, "Historical owner isolated from colliding owner")
	state.bank_engine = null

	if failures.is_empty():
		print("FINANCIAL INTEGRITY TESTS: PASS")
	for message in failures:
		push_error(message)
	quit(0 if failures.is_empty() else 1)
