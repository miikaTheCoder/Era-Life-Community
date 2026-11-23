extends Resource
class_name BankEngine

const CONTRACT_SCHEMA:= "eralife.bank_engine"
const CONTRACT_VERSION:= 1
const DEFAULT_WORLD_ID:= "local.world"
const DEFAULT_CURRENCY:= "USD"
const ACCOUNT_KIND_BANK:= "bank"
const ACCOUNT_KIND_INTERWORLD:= "interworld_credit"
const ACCOUNT_STATUS_OPEN:= "open"
const ACCOUNT_STATUS_FROZEN:= "frozen"
const ACCOUNT_STATUS_SANCTIONED:= "sanctioned"
const TRANSFER_SCOPE_LOCAL:= "local"
const TRANSFER_SCOPE_ERANET:= "eranet"
const LEDGER_LIMIT:= 500

var gs
var active_contract: Dictionary = {}
var accounts: Dictionary = {}
var cash_on_hand: Dictionary = {}
var owner_index: Dictionary = {}
# Legacy routed accounts keep their original keys and transaction references.
# An empty binding means the old save omitted the original identity.
var legacy_routed_owners: Dictionary = {}
var world_bank_policies: Dictionary = {}
var interworld_credit_routes: Dictionary = {}
var ledger: Array = []
var last_report: Dictionary = {}
var _tx_seq: int = 0

func _init(_gs = null):
	gs = _gs
	active_contract = _build_default_contract()

func reset_runtime() -> void:
	accounts.clear()
	cash_on_hand.clear()
	owner_index.clear()
	legacy_routed_owners.clear()
	world_bank_policies.clear()
	interworld_credit_routes.clear()
	ledger.clear()
	last_report.clear()
	_tx_seq = 0

func set_contract(contract: Dictionary = {}) -> Dictionary:
	if typeof(contract) == TYPE_DICTIONARY and not contract.is_empty():
		active_contract = _merge_dict(_build_default_contract(), contract)
	else:
		active_contract = _build_default_contract()
	return {
		"schema": "eralife.bank_contract_set_report",
		"version": CONTRACT_VERSION,
		"success": true,
		"contract_id": str(active_contract.get("id", "eralife_default_bank_contract")),
		"set_at_ms": int(Time.get_ticks_msec())
	}

func export_state() -> Dictionary:
	return _make_binary_safe({
		"schema": "eralife.bank_engine_state",
		"version": CONTRACT_VERSION,
		"active_contract": active_contract.duplicate(true),
		"accounts": accounts.duplicate(true),
		"cash_on_hand": cash_on_hand.duplicate(true),
		"owner_index": owner_index.duplicate(true),
		"legacy_routed_owners": legacy_routed_owners.duplicate(),
		"world_bank_policies": world_bank_policies.duplicate(true),
		"interworld_credit_routes": interworld_credit_routes.duplicate(true),
		"ledger": ledger.duplicate(true),
		"last_report": last_report.duplicate(true),
		"tx_seq": _tx_seq,
		"exported_at_ms": int(Time.get_ticks_msec())
	})

func import_state(data: Dictionary) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return { "success": false, "reason": "BankEngine import data must be a Dictionary."}

	var contract_raw: Variant = data.get("active_contract", {})
	if typeof(contract_raw) == TYPE_DICTIONARY:
		active_contract = _merge_dict(_build_default_contract(), contract_raw as Dictionary)
	else:
		active_contract = _build_default_contract()

	var accounts_raw: Variant = data.get("accounts", {})
	accounts = accounts_raw.duplicate(true) if typeof(accounts_raw) == TYPE_DICTIONARY else {}

	var cash_raw: Variant = data.get("cash_on_hand", {})
	cash_on_hand = cash_raw.duplicate(true) if typeof(cash_raw) == TYPE_DICTIONARY else {}

	var index_raw: Variant = data.get("owner_index", {})
	owner_index = index_raw.duplicate(true) if typeof(index_raw) == TYPE_DICTIONARY else {}

	var policy_raw: Variant = data.get("world_bank_policies", {})
	world_bank_policies = policy_raw.duplicate(true) if typeof(policy_raw) == TYPE_DICTIONARY else {}

	var routes_raw: Variant = data.get("interworld_credit_routes", {})
	interworld_credit_routes = routes_raw.duplicate(true) if typeof(routes_raw) == TYPE_DICTIONARY else {}

	var ledger_raw: Variant = data.get("ledger", [])
	ledger = ledger_raw.duplicate(true) if typeof(ledger_raw) == TYPE_ARRAY else []
	_tx_seq = int(data.get("tx_seq", ledger.size()))

	_rebuild_owner_index()
	legacy_routed_owners = data.get("legacy_routed_owners", {}).duplicate()
	if not data.has("legacy_routed_owners"):
		for owner in owner_index:
			_note_legacy_routed_owner(owner)
		for wallet in cash_on_hand.values():
			_note_legacy_routed_owner(wallet.get("owner_id"))
		for entry in ledger:
			var tx: Dictionary = entry.get("data", {})
			var extra: Dictionary = tx.get("extra", {})
			for owner in [tx.get("owner_id"), extra.get("target_owner_id"), extra.get("victim_owner_id")]:
				_note_legacy_routed_owner(owner)
	repair_legacy_player_money_mirror()

	last_report = {
		"schema": "eralife.bank_import_report",
		"version": CONTRACT_VERSION,
		"success": true,
		"account_count": accounts.size(),
		"wallet_count": cash_on_hand.size(),
		"legacy_routed_owners": legacy_routed_owners.duplicate(),
		"ledger_count": ledger.size(),
		"imported_at_ms": int(Time.get_ticks_msec())
	}
	return last_report.duplicate(true)

func export_checkpoint_state(owner_ids: Array) -> Dictionary:
	# Copy only indexed accounts needed by the saved household and its ventures.
	# A company account has no Person.bank_balance mirror to restore from.
	var selected_bindings := {}
	owner_ids = owner_ids.duplicate()
	for legacy in legacy_routed_owners:
		var binding: String = legacy_routed_owners[legacy]
		if binding != "" and binding in owner_ids and legacy not in owner_ids:
			owner_ids.append(legacy)
		if legacy in owner_ids:
			selected_bindings[legacy] = binding
	var selected: Dictionary = {}
	var wallets: Dictionary = {}
	for raw_owner in owner_ids:
		var owner := str(raw_owner)
		for id in _accounts_for_owner(owner):
			if not accounts.has(id):
				continue
			var account: Dictionary = accounts[id]
			selected[id] = account.duplicate(true)
	for wallet_id in cash_on_hand:
		var wallet: Dictionary = cash_on_hand[wallet_id]
		if str(wallet.owner_id) in owner_ids:
			wallets[wallet_id] = wallet.duplicate(true)
	var history: Array = []
	for transaction in ledger:
		var data: Dictionary = transaction.get("data", {})
		var extra: Dictionary = data.get("extra", {})
		if data.get("owner_id") in owner_ids or extra.get("target_owner_id") in owner_ids or extra.get("victim_owner_id") in owner_ids:
			history.append(transaction.duplicate(true))
	return {"schema": "eralife.bank_engine_state", "version": CONTRACT_VERSION,
		"active_contract": active_contract.duplicate(true), "accounts": selected, "cash_on_hand": wallets,
		"world_bank_policies": world_bank_policies.duplicate(true), "tx_seq": _tx_seq, "ledger": history,
		"legacy_routed_owners": selected_bindings}


func credit_bank(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	if owner_id.strip_edges() == "" or amount <= 0.0:
		return {"success": false, "reason": "Bank income needs an owner and a positive amount."}
	var account := ensure_account(owner_id, _resolve_world_id({"world_id": world_id}), ACCOUNT_KIND_BANK, currency)
	var id := str(account.account_id)
	var gate := _can_credit_or_debit(id, amount, "credit", {})
	if not bool(gate.get("allowed", false)):
		return {"success": false, "reason": str(gate.get("reason", "Income blocked."))}
	accounts[id].balance = float(accounts[id].balance) + amount
	accounts[id].updated_at_ms = int(Time.get_ticks_msec())
	_sync_actor_by_owner(owner_id)
	var report := _finish_money_action("bank_income", owner_id, amount, str(account.world_id), str(account.currency), payload)
	last_report = report.duplicate(true)
	return report

func repair_legacy_player_money_mirror() -> Dictionary:
	if gs == null or gs.player == null:
		return { "success": false, "reason": "No player to repair."}

	var actor = gs.player
	var context := {"source": "legacy_bank_balance_repair", "import_legacy_balance": true}
	var account: Dictionary = ensure_bank_account_for_actor(actor, context)
	if account.is_empty():
		return {"success": false, "reason": "Could not resolve player bank account."}

	_sync_actor_money_mirror(actor)
	return get_owner_summary_for_actor(actor, context)

func ensure_bank_account_for_actor(actor, context: Dictionary = {}) -> Dictionary:
	if actor == null:
		return {}
	var owner_id: String = owner_key_from_actor(actor)
	var world_id: String = _resolve_world_id(context)
	var currency: String = _resolve_currency(context)
	var has_bank := false
	for id in _accounts_for_owner(owner_id):
		if str(accounts.get(id, {}).get("type", "")) == ACCOUNT_KIND_BANK:
			has_bank = true
			break
	var import_legacy := bool(context.get("import_legacy_balance", false)) and not has_bank
	return ensure_account(owner_id, world_id, ACCOUNT_KIND_BANK, currency, {
		"actor_id": int(actor.id) if actor.get("id") != null else -1,
		# Import once per owner, not once per realm. Empty accounts also remain
		# authoritative: repairing a stale mirror must never restore spent funds.
		"starting_balance": max(0.0, float(actor.bank_balance)) if import_legacy else 0.0,
		"transfer_scope": TRANSFER_SCOPE_LOCAL
	})

func ensure_interworld_account_for_actor(actor, context: Dictionary = {}) -> Dictionary:
	if actor == null:
		return {}
	var owner_id: String = owner_key_from_actor(actor)
	var world_id: String = _resolve_world_id(context)
	var currency: String = _resolve_currency(context)
	return ensure_account(owner_id, world_id, ACCOUNT_KIND_INTERWORLD, currency, {
		"actor_id": int(actor.id) if actor.get("id") != null else -1,
		"transfer_scope": TRANSFER_SCOPE_ERANET
	})

func ensure_account(owner_id: String, world_id: String = "", account_kind: String = ACCOUNT_KIND_BANK, currency: String = DEFAULT_CURRENCY, options: Dictionary = {}) -> Dictionary:
	var clean_owner: String = str(owner_id).strip_edges()
	if clean_owner == "":
		clean_owner = "owner:unknown"

	var clean_world: String = str(world_id).strip_edges()
	if clean_world == "":
		clean_world = DEFAULT_WORLD_ID

	var clean_kind: String = str(account_kind).strip_edges().to_lower()
	if clean_kind == "":
		clean_kind = ACCOUNT_KIND_BANK

	var clean_currency: String = str(currency).strip_edges().to_upper()
	if clean_currency == "":
		clean_currency = DEFAULT_CURRENCY

	var account_id: String = _account_id(clean_owner, clean_world, clean_kind, clean_currency)
	if not accounts.has(account_id):
		accounts [account_id] = {
			"schema": "eralife.money_account",
			"version": CONTRACT_VERSION,
			"account_id": account_id,
			"owner_id": clean_owner,
			"world_id": clean_world,
			"balance": _money_amount(options.get("starting_balance", 0.0)),
			"type": clean_kind,
			"currency": clean_currency,
			"transfer_scope": str(options.get("transfer_scope", TRANSFER_SCOPE_LOCAL)),
			"status": ACCOUNT_STATUS_OPEN,
			"flags": [],
			"actor_id": int(options.get("actor_id", -1)),
			"metadata": options.get("metadata", {}).duplicate(true) if typeof(options.get("metadata", {})) == TYPE_DICTIONARY else {},
			"created_at_ms": int(Time.get_ticks_msec()),
			"updated_at_ms": int(Time.get_ticks_msec())
		}
		_index_account(account_id, clean_owner)

	return accounts.get(account_id, {}).duplicate(true)

func get_owner_summary_for_actor(actor, context: Dictionary = {}) -> Dictionary:
	if actor == null:
		return {}
	ensure_bank_account_for_actor(actor, context)
	ensure_interworld_account_for_actor(actor, context)
	return get_owner_summary(owner_key_from_actor(actor), context)

func get_owner_summary(owner_id: String, context: Dictionary = {}) -> Dictionary:
	var clean_owner: String = str(owner_id).strip_edges()
	if clean_owner == "":
		return {}

	var world_id: String = _resolve_world_id(context)
	var currency: String = _resolve_currency(context)
	var wallet: Dictionary = ensure_cash_wallet(clean_owner, world_id, currency, context)
	var bank_balance: float = 0.0
	var interworld_balance: float = 0.0
	var total_secured: float = 0.0
	var accessible_secured: float = 0.0

	for account_id in _accounts_for_owner(clean_owner):
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_raw
		if str(account.get("currency", currency)).to_upper() != currency:
			continue
		var balance: float = max(0.0, float(account.get("balance", 0.0)))
		if str(account.get("type", "")) == ACCOUNT_KIND_INTERWORLD:
			interworld_balance += balance
		else:
			bank_balance += balance
		total_secured += balance
		if _can_credit_or_debit(account_id, balance, "debit").allowed:
			accessible_secured += balance

	return {
		"schema": "eralife.money_owner_summary",
		"version": CONTRACT_VERSION,
		"owner_id": clean_owner,
		"world_id": world_id,
		"currency": currency,
		"cash_on_hand": max(0.0, float(wallet.get("amount", 0.0))),
		"bank_balance": bank_balance,
		"interworld_credit": interworld_balance,
		"secured_total": total_secured,
		"total_accessible": max(0.0, float(wallet.get("amount", 0.0))) + accessible_secured,
		"wallet_id": str(wallet.get("wallet_id", "")),
		"account_count": _accounts_for_owner(clean_owner).size(),
		"updated_at_ms": int(Time.get_ticks_msec())
	}

func ensure_cash_wallet(owner_id: String, world_id: String = "", currency: String = DEFAULT_CURRENCY, context: Dictionary = {}) -> Dictionary:
	var clean_owner: String = str(owner_id).strip_edges()
	if clean_owner == "":
		clean_owner = "owner:unknown"
	var clean_world: String = str(world_id).strip_edges()
	if clean_world == "":
		clean_world = _resolve_world_id(context)
	var clean_currency: String = str(currency).strip_edges().to_upper()
	if clean_currency == "":
		clean_currency = DEFAULT_CURRENCY
	var wallet_id: String = _wallet_id(clean_owner, clean_world, clean_currency)
	if not cash_on_hand.has(wallet_id):
		cash_on_hand [wallet_id] = {
			"schema": "eralife.cash_wallet",
			"version": CONTRACT_VERSION,
			"wallet_id": wallet_id,
			"owner_id": clean_owner,
			"world_id": clean_world,
			"currency": clean_currency,
			"amount": _money_amount(context.get("starting_cash", 0.0)),
			"risk_surface": "physical",
			"created_at_ms": int(Time.get_ticks_msec()),
			"updated_at_ms": int(Time.get_ticks_msec())
		}
	return cash_on_hand.get(wallet_id, {}).duplicate(true)

func deposit_for_player(actor, payload: Dictionary = {}) -> Dictionary:
	var merged: Dictionary = payload.duplicate(true)
	merged ["action"] = "deposit"
	return request_actor_bank_action(actor, merged, payload)

func withdraw_for_player(actor, payload: Dictionary = {}) -> Dictionary:
	var merged: Dictionary = payload.duplicate(true)
	merged ["action"] = "withdraw"
	return request_actor_bank_action(actor, merged, payload)

func request_actor_bank_action(actor, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if actor == null:
		return { "success": false, "reason": "No actor supplied."}

	var merged_context: Dictionary = context.duplicate(true)
	merged_context ["actor_id"] = int(actor.id) if actor.get("id") != null else -1
	merged_context ["owner_id"] = owner_key_from_actor(actor)
	merged_context ["world_id"] = _resolve_world_id(context)
	return request_bank_action(payload, merged_context)

func request_bank_action(payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var action: String = str(payload.get("action", payload.get("command", ""))).strip_edges().to_lower()
	var owner_id: String = str(payload.get("owner_id", context.get("owner_id", ""))).strip_edges()
	if owner_id == "":
		var route := _resolve_bank_owner(context)
		if not route.success:
			return route
		owner_id = route.owner_id
	if owner_id == "":
		return { "success": false, "reason": "Bank action missing owner_id."}

	var amount: float = _money_amount(payload.get("amount", payload.get("value", 0.0)))
	var world_id: String = _resolve_world_id(context)
	var currency := str(payload.get("currency", "")).strip_edges().to_upper()
	if currency == "":
		currency = _resolve_currency(context)

	match action:
		"deposit", "deposit_money":
			return deposit(owner_id, amount, world_id, currency, context)
		"deposit_all", "deposit_all_cash":
			var wallet: Dictionary = ensure_cash_wallet(owner_id, world_id, currency, context)
			return deposit(owner_id, float(wallet.get("amount", 0.0)), world_id, currency, context)
		"withdraw", "withdraw_money":
			return withdraw(owner_id, amount, world_id, currency, context)
		"spend", "pay", "debit", "service_payment":
			return spend(owner_id, amount, world_id, currency, payload, context)
		"credit_cash", "crime_payout_cash":
			return credit_cash(owner_id, amount, world_id, currency, payload, context)
		"transfer", "transfer_money":
			return transfer_owner_to_owner(owner_id, str(payload.get("target_owner_id", "")), amount, world_id, currency, payload, context)
		"steal_cash", "rob_cash":
			return steal_cash(str(payload.get("thief_owner_id", owner_id)), str(payload.get("victim_owner_id", "")), amount, world_id, currency, payload, context)
		"apply_justice_penalty", "justice_fine", "justice_restitution", "asset_seizure":
			return apply_justice_penalty(owner_id, amount, world_id, currency, payload, context)
		"freeze_owner_accounts":
			return freeze_owner_accounts(owner_id, payload, context)
		"freeze_account":
			return set_account_status(str(payload.get("account_id", "")), ACCOUNT_STATUS_FROZEN, payload, context)
		"unfreeze_account":
			return set_account_status(str(payload.get("account_id", "")), ACCOUNT_STATUS_OPEN, payload, context)
		"summary", "status", "balance":
			return { "success": true, "summary": get_owner_summary(owner_id, context)}
		_:
			return { "success": false, "reason": "Unsupported bank action '%s'." % action}

func route_command_envelope(envelope: Dictionary) -> Dictionary:
	if typeof(envelope) != TYPE_DICTIONARY:
		return { "success": false, "reason": "Bank command envelope must be a Dictionary."}
	var payload_raw: Variant = envelope.get("payload", envelope.get("args", {}))
	var payload: Dictionary = payload_raw.duplicate(true) if typeof(payload_raw) == TYPE_DICTIONARY else {}
	var context_raw: Variant = envelope.get("context", {})
	var context: Dictionary = context_raw.duplicate(true) if typeof(context_raw) == TYPE_DICTIONARY else {}
	context ["source"] = str(envelope.get("source", context.get("source", "command_envelope")))
	context ["world_id"] = str(context.get("world_id", envelope.get("world_container_id", envelope.get("guild_id", ""))))
	# Keep explicit request context while also accepting the flat command format.
	for key in ["owner_id", "player_id", "actor_id", "user_id", "external_user_id", "guild_id", "world_container_id", "life_node_id"]:
		if envelope.has(key) and str(context.get(key, "")).strip_edges() == "":
			context[key] = envelope[key]
	if str(payload.get("action", "")).strip_edges() == "":
		payload ["action"] = _bank_action_from_command(str(envelope.get("command", envelope.get("action_id", ""))))
	return request_bank_action(payload, context)

func deposit(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	if amount <= 0.0:
		return { "success": false, "reason": "Deposit amount must be positive."}

	var clean_owner: String = str(owner_id).strip_edges()
	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var wallet: Dictionary = ensure_cash_wallet(clean_owner, clean_world, clean_currency, context)
	var wallet_id: String = str(wallet.get("wallet_id", ""))
	var available_cash: float = max(0.0, float(wallet.get("amount", 0.0)))
	if amount > available_cash:
		return { "success": false, "reason": "Not enough cash on hand.", "available_cash": available_cash}

	var account: Dictionary = ensure_account(clean_owner, clean_world, ACCOUNT_KIND_BANK, clean_currency, { "transfer_scope": TRANSFER_SCOPE_LOCAL})
	var account_id: String = str(account.get("account_id", ""))
	var gate: Dictionary = _can_credit_or_debit(account_id, amount, "credit", context)
	if not bool(gate.get("allowed", true)):
		return { "success": false, "reason": str(gate.get("reason", "Deposit blocked.")), "gate": gate}

	cash_on_hand [wallet_id] ["amount"] = max(0.0, available_cash - amount)
	cash_on_hand [wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	accounts [account_id] ["balance"] = max(0.0, float(accounts [account_id].get("balance", 0.0)) + amount)
	accounts [account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	_sync_actor_by_owner(clean_owner)

	var report: Dictionary = _finish_money_action("money_deposited", clean_owner, amount, clean_world, clean_currency, {
		"account_id": account_id,
		"wallet_id": wallet_id,
		"text": "Money moved from physical cash into the bank."
	})
	last_report = report.duplicate(true)
	return report

func withdraw(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	if amount <= 0.0:
		return { "success": false, "reason": "Withdrawal amount must be positive."}

	var clean_owner: String = str(owner_id).strip_edges()
	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var account: Dictionary = ensure_account(clean_owner, clean_world, ACCOUNT_KIND_BANK, clean_currency, { "transfer_scope": TRANSFER_SCOPE_LOCAL})
	var account_id: String = str(account.get("account_id", ""))
	var balance: float = max(0.0, float(accounts [account_id].get("balance", 0.0)))
	if amount > balance:
		return { "success": false, "reason": "Not enough money in the bank.", "bank_balance": balance}
	var gate: Dictionary = _can_credit_or_debit(account_id, amount, "debit", context)
	if not bool(gate.get("allowed", true)):
		return { "success": false, "reason": str(gate.get("reason", "Withdrawal blocked.")), "gate": gate}

	var wallet: Dictionary = ensure_cash_wallet(clean_owner, clean_world, clean_currency, context)
	var wallet_id: String = str(wallet.get("wallet_id", ""))
	var cash_after := float(wallet.amount) + amount
	if not is_finite(cash_after):
		return {"success": false, "reason": "Withdrawal exceeds the supported wallet balance."}
	accounts [account_id] ["balance"] = max(0.0, balance - amount)
	accounts [account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	cash_on_hand [wallet_id] ["amount"] = cash_after
	cash_on_hand [wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	_sync_actor_by_owner(clean_owner)

	var report: Dictionary = _finish_money_action("money_withdrawn", clean_owner, amount, clean_world, clean_currency, {
		"account_id": account_id,
		"wallet_id": wallet_id,
		"text": "Money moved from the bank into physical cash."
	})
	last_report = report.duplicate(true)
	return report

func spend(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	if amount <= 0.0:
		return { "success": false, "reason": "Payment amount must be positive."}

	var clean_owner: String = str(owner_id).strip_edges()
	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var wallet: Dictionary = ensure_cash_wallet(clean_owner, clean_world, clean_currency, context)
	var wallet_id: String = str(wallet.get("wallet_id", ""))
	var spendable_accounts: Array = []
	var available: float = max(0.0, float(cash_on_hand [wallet_id].get("amount", 0.0)))

	for account_id in _accounts_for_owner(clean_owner):
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_raw
		if str(account.get("currency", clean_currency)).to_upper() != clean_currency:
			continue
		var balance: float = max(0.0, float(account.get("balance", 0.0)))
		if balance <= 0.0:
			continue
		var gate: Dictionary = _can_credit_or_debit(str(account_id), minf(balance, amount), "debit", context)
		if not bool(gate.get("allowed", true)):
			continue
		spendable_accounts.append(str(account_id))
		available += balance

	if amount > available:
		return {
			"success": false,
			"reason": "Not enough accessible money for this payment.",
			"requested_amount": amount,
			"available_amount": available
		}

	var remaining: float = amount
	var debits: Array = []
	for account_id in spendable_accounts:
		if remaining <= 0.0:
			break
		var balance: float = max(0.0, float(accounts [account_id].get("balance", 0.0)))
		var debit: float = minf(balance, remaining)
		accounts [account_id] ["balance"] = max(0.0, balance - debit)
		accounts [account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
		remaining -= debit
		debits.append({
			"source": "bank_account",
			"account_id": account_id,
			"amount": debit
		})

	if remaining > 0.0:
		var cash_available: float = max(0.0, float(cash_on_hand [wallet_id].get("amount", 0.0)))
		var cash_debit: float = minf(cash_available, remaining)
		cash_on_hand [wallet_id] ["amount"] = max(0.0, cash_available - cash_debit)
		cash_on_hand [wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
		remaining -= cash_debit
		debits.append({
			"source": "cash_wallet",
			"wallet_id": wallet_id,
			"amount": cash_debit
		})

	_sync_actor_by_owner(clean_owner)
	var report: Dictionary = _finish_money_action(ActionEventTypes.MONEY_SPENT, clean_owner, amount, clean_world, clean_currency, {
		"reason": str(payload.get("reason", context.get("reason", "payment"))),
		"source": str(context.get("source", payload.get("source", "bank_engine"))),
		"debits": debits.duplicate(true),
		"text": str(payload.get("text", "A payment was made through BankEngine."))
	})
	report ["debits"] = debits.duplicate(true)
	last_report = report.duplicate(true)
	return report

func credit_cash(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	if amount <= 0.0:
		return { "success": false, "reason": "Cash credit amount must be positive."}

	var clean_owner: String = str(owner_id).strip_edges()
	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var wallet: Dictionary = ensure_cash_wallet(clean_owner, clean_world, clean_currency, context)
	var wallet_id: String = str(wallet.get("wallet_id", ""))

	var cash_after := float(wallet.amount) + amount
	if not is_finite(cash_after):
		return {"success": false, "reason": "Cash credit exceeds the supported wallet balance."}
	cash_on_hand[wallet_id].amount = cash_after
	cash_on_hand [wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	_sync_actor_by_owner(clean_owner)

	var report: Dictionary = _finish_money_action("cash_credited", clean_owner, amount, clean_world, clean_currency, {
		"wallet_id": wallet_id,
		"case_id": str(payload.get("case_id", context.get("case_id", ""))),
		"source": str(context.get("source", payload.get("source", "bank_engine"))),
		"text": str(payload.get("text", "Physical cash was added to a wallet."))
	})
	last_report = report.duplicate(true)
	return report

func apply_justice_penalty(owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if not is_finite(amount):
		return {"success": false, "reason": "Penalty amount must be finite."}
	amount = _money_amount(amount)
	if amount <= 0.0:
		return { "success": true, "skipped": true, "reason": "No justice penalty amount."}

	var clean_owner: String = str(owner_id).strip_edges()
	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var remaining: float = amount
	var paid: float = 0.0
	var debits: Array = []

	for account_id in _accounts_for_owner(clean_owner):
		if remaining <= 0.0:
			break
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_raw
		if str(account.get("currency", clean_currency)).to_upper() != clean_currency:
			continue

		var balance: float = max(0.0, float(account.get("balance", 0.0)))
		if balance <= 0.0:
			continue

		var debit: float = min(balance, remaining)
		accounts [account_id] ["balance"] = max(0.0, balance - debit)
		accounts [account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
		remaining -= debit
		paid += debit
		debits.append({
			"source": "bank_account",
			"account_id": account_id,
			"amount": debit
		})

	if remaining > 0.0:
		var wallet: Dictionary = ensure_cash_wallet(clean_owner, clean_world, clean_currency, context)
		var wallet_id: String = str(wallet.get("wallet_id", ""))
		var cash_available: float = max(0.0, float(cash_on_hand [wallet_id].get("amount", 0.0)))
		var cash_debit: float = min(cash_available, remaining)

		if cash_debit > 0.0:
			cash_on_hand [wallet_id] ["amount"] = max(0.0, cash_available - cash_debit)
			cash_on_hand [wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
			remaining -= cash_debit
			paid += cash_debit
			debits.append({
				"source": "cash_wallet",
				"wallet_id": wallet_id,
				"amount": cash_debit
			})

	var target_owner_id: String = str(payload.get("target_owner_id", "")).strip_edges()
	if target_owner_id != "" and paid > 0.0:
		var target_account: Dictionary = ensure_account(target_owner_id, clean_world, ACCOUNT_KIND_BANK, clean_currency, {
			"transfer_scope": TRANSFER_SCOPE_LOCAL
		})
		var target_account_id: String = str(target_account.get("account_id", ""))
		accounts [target_account_id] ["balance"] = max(0.0, float(accounts [target_account_id].get("balance", 0.0)) + paid)
		accounts [target_account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
		_sync_actor_by_owner(target_owner_id)

	_sync_actor_by_owner(clean_owner)

	var report: Dictionary = _finish_money_action("justice_economic_penalty", clean_owner, paid, clean_world, clean_currency, {
		"case_id": str(payload.get("case_id", context.get("case_id", ""))),
		"penalty_type": str(payload.get("penalty_type", "justice_penalty")),
		"requested_amount": amount,
		"paid_amount": paid,
		"unpaid_amount": max(0.0, remaining),
		"debits": debits.duplicate(true),
		"target_owner_id": target_owner_id,
		"text": "A court-ordered financial penalty was applied through BankEngine."
	})
	report ["requested_amount"] = amount
	report ["paid_amount"] = paid
	report ["unpaid_amount"] = max(0.0, remaining)
	last_report = report.duplicate(true)
	return report

func freeze_owner_accounts(owner_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var clean_owner: String = str(owner_id).strip_edges()
	if clean_owner == "":
		return { "success": false, "reason": "freeze_owner_accounts needs owner_id."}

	var frozen: Array = []
	for account_id in _accounts_for_owner(clean_owner):
		if not accounts.has(account_id):
			continue
		accounts [account_id] ["status"] = ACCOUNT_STATUS_FROZEN
		accounts [account_id] ["status_reason"] = str(payload.get("reason", context.get("reason", "justice_freeze")))
		accounts [account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
		frozen.append(account_id)

	var report: Dictionary = _finish_money_action("owner_accounts_frozen", clean_owner, 0.0, _resolve_world_id(context), _resolve_currency(context), {
		"frozen_accounts": frozen.duplicate(true),
		"case_id": str(payload.get("case_id", context.get("case_id", ""))),
		"text": "Court authority froze this owner's BankEngine accounts."
	})
	report ["frozen_accounts"] = frozen.duplicate(true)
	last_report = report.duplicate(true)
	return report


# Settle the ordinary bank accounts represented by Person.bank_balance. Each
# currency stays in its original world. Validate every leg before moving funds.
func settle_estate_accounts(deceased: Person, heir: Person) -> Dictionary:
	if deceased == null or heir == null or deceased.id <= 0 or heir.id <= 0 or deceased.id == heir.id:
		return {"success": false, "reason": "An estate needs two different owners."}

	for actor in [deceased, heir]:
		var context := {"import_legacy_balance": true}
		if actor.realm_id >= 0:
			context["world_id"] = "realm:%d" % actor.realm_id
		ensure_bank_account_for_actor(actor, context)
	var from_owner := owner_key_from_actor(deceased)
	var to_owner := owner_key_from_actor(heir)
	var payouts: Array[Dictionary] = []
	var totals := {}
	for id in _accounts_for_owner(from_owner):
		var source: Dictionary = accounts[id]
		if source.type != ACCOUNT_KIND_BANK or source.balance == 0.0:
			continue
		var amount := float(source.balance)
		var target := ensure_account(to_owner, source.world_id, ACCOUNT_KIND_BANK, source.currency)
		var debit := _can_credit_or_debit(id, amount, "debit")
		var credit := _can_credit_or_debit(target.account_id, amount, "credit")
		if not debit.allowed:
			return {"success": false, "reason": debit.reason}
		if not credit.allowed:
			return {"success": false, "reason": credit.reason}
		var total := float(totals.get(source.currency, 0.0)) + amount
		var target_balance := float(target.balance) + amount
		if amount < 0.0 or not is_finite(total) or not is_finite(target_balance):
			return {"success": false, "reason": "Unsupported estate balance."}
		totals[source.currency] = total
		payouts.append({"source": id, "target": target.account_id, "amount": amount,
			"target_balance": target_balance, "world": source.world_id, "currency": source.currency})

	for payout in payouts:
		accounts[payout.source].balance = 0.0
		accounts[payout.target].balance = payout.target_balance
		var now := Time.get_ticks_msec()
		accounts[payout.source].updated_at_ms = now
		accounts[payout.target].updated_at_ms = now
		_record_ledger("money_transferred", {"owner_id": from_owner, "amount": payout.amount,
			"world_id": payout.world, "currency": payout.currency, "extra": {
				"target_owner_id": to_owner, "from_account_id": payout.source,
				"to_account_id": payout.target, "reason": "inheritance"}})
	_sync_actor_money_mirror(deceased)
	_sync_actor_money_mirror(heir)
	return {"success": true, "totals": totals}

func transfer_owner_to_owner(from_owner_id: String, to_owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	var clean_from: String = str(from_owner_id).strip_edges()
	var clean_to: String = str(to_owner_id).strip_edges()
	if clean_from == "" or clean_to == "":
		return { "success": false, "reason": "Transfer needs both from_owner_id and target_owner_id."}
	if clean_from == clean_to:
		return { "success": false, "reason": "Cannot transfer money to the same owner."}
	if amount <= 0.0:
		return { "success": false, "reason": "Transfer amount must be positive."}

	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var scope: String = str(payload.get("transfer_scope", context.get("transfer_scope", TRANSFER_SCOPE_LOCAL))).strip_edges().to_lower()
	var account_kind: String = ACCOUNT_KIND_INTERWORLD if scope == TRANSFER_SCOPE_ERANET else ACCOUNT_KIND_BANK
	var to_world: String = str(payload.get("target_world_id", clean_world)).strip_edges()
	if to_world == "":
		to_world = clean_world
	if scope != TRANSFER_SCOPE_ERANET and to_world != clean_world:
		return {"success": false, "reason": "Local transfers must stay in the same world."}
	var from_account: Dictionary = ensure_account(clean_from, clean_world, account_kind, clean_currency, { "transfer_scope": scope})
	var to_account: Dictionary = ensure_account(clean_to, to_world, account_kind, clean_currency, { "transfer_scope": scope})
	var from_account_id: String = str(from_account.get("account_id", ""))
	var to_account_id: String = str(to_account.get("account_id", ""))

	if scope == TRANSFER_SCOPE_ERANET and not _interworld_allowed(clean_world, to_world, payload, context):
		return { "success": false, "reason": "InterWorld transfer blocked by bank contract policy."}

	var balance: float = max(0.0, float(accounts [from_account_id].get("balance", 0.0)))
	if amount > balance:
		return { "success": false, "reason": "Not enough secured funds for transfer.", "bank_balance": balance}
	var gate: Dictionary = _can_credit_or_debit(from_account_id, amount, "debit", context)
	if not bool(gate.get("allowed", true)):
		return { "success": false, "reason": str(gate.get("reason", "Transfer blocked.")), "gate": gate}
	var target_gate: Dictionary = _can_credit_or_debit(to_account_id, amount, "credit", context)
	if not bool(target_gate.get("allowed", true)):
		return {"success": false, "reason": str(target_gate.get("reason", "Transfer blocked.")), "gate": target_gate}

	accounts [from_account_id] ["balance"] = max(0.0, balance - amount)
	accounts [from_account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	accounts [to_account_id] ["balance"] = max(0.0, float(accounts [to_account_id].get("balance", 0.0)) + amount)
	accounts [to_account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	_sync_actor_by_owner(clean_from)
	_sync_actor_by_owner(clean_to)

	var report: Dictionary = _finish_money_action("money_transferred", clean_from, amount, clean_world, clean_currency, {
		"from_account_id": from_account_id,
		"to_account_id": to_account_id,
		"target_owner_id": clean_to,
		"target_world_id": to_world,
		"transfer_scope": scope,
		"text": "Money moved through the Bank Engine."
	})
	last_report = report.duplicate(true)
	return report

func steal_cash(thief_owner_id: String, victim_owner_id: String, amount: float, world_id: String = "", currency: String = DEFAULT_CURRENCY, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	amount = _money_amount(amount)
	var thief: String = str(thief_owner_id).strip_edges()
	var victim: String = str(victim_owner_id).strip_edges()
	if thief == victim:
		return {"success": false, "reason": "Cash theft requires different owners."}
	if thief == "" or victim == "":
		return { "success": false, "reason": "Cash theft needs thief_owner_id and victim_owner_id."}
	if amount <= 0.0:
		return { "success": false, "reason": "Theft amount must be positive."}

	var clean_world: String = _resolve_world_id({ "world_id": world_id})
	var clean_currency: String = str(currency).strip_edges().to_upper()
	var gate: Dictionary = _can_steal_cash(thief, victim, amount, clean_world, clean_currency, payload, context)
	if not bool(gate.get("allowed", false)):
		return { "success": false, "reason": str(gate.get("reason", "Cash theft blocked.")), "gate": gate}

	var victim_wallet: Dictionary = ensure_cash_wallet(victim, clean_world, clean_currency, context)
	var victim_wallet_id: String = str(victim_wallet.get("wallet_id", ""))
	var victim_cash: float = max(0.0, float(cash_on_hand [victim_wallet_id].get("amount", 0.0)))
	var resolved_amount: float = min(amount, victim_cash)
	if resolved_amount <= 0.0:
		return { "success": false, "reason": "Victim has no cash on hand.", "victim_cash": victim_cash}

	var thief_wallet: Dictionary = ensure_cash_wallet(thief, clean_world, clean_currency, context)
	var thief_wallet_id: String = str(thief_wallet.get("wallet_id", ""))
	var cash_after := float(thief_wallet.amount) + resolved_amount
	if not is_finite(cash_after):
		return {"success": false, "reason": "Theft exceeds the supported wallet balance."}
	cash_on_hand [victim_wallet_id] ["amount"] = max(0.0, victim_cash - resolved_amount)
	cash_on_hand [victim_wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	cash_on_hand [thief_wallet_id] ["amount"] = cash_after
	cash_on_hand [thief_wallet_id] ["updated_at_ms"] = int(Time.get_ticks_msec())

	var report: Dictionary = _finish_money_action("cash_stolen", thief, resolved_amount, clean_world, clean_currency, {
		"victim_owner_id": victim,
		"thief_wallet_id": thief_wallet_id,
		"victim_wallet_id": victim_wallet_id,
		"governed": true,
		"text": "Physical cash changed hands. Bank funds were not touched."
	})
	last_report = report.duplicate(true)
	return report

func set_account_status(account_id: String, status: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var clean_account_id: String = str(account_id).strip_edges()
	if clean_account_id == "" or not accounts.has(clean_account_id):
		return { "success": false, "reason": "Unknown account_id."}
	var clean_status: String = str(status).strip_edges().to_lower()
	if clean_status == "":
		clean_status = ACCOUNT_STATUS_OPEN
	accounts [clean_account_id] ["status"] = clean_status
	accounts [clean_account_id] ["status_reason"] = str(payload.get("reason", context.get("reason", ""))).strip_edges()
	accounts [clean_account_id] ["updated_at_ms"] = int(Time.get_ticks_msec())
	var report: Dictionary = _finish_money_action("account_status_changed", str(accounts [clean_account_id].get("owner_id", "")), 0.0, str(accounts [clean_account_id].get("world_id", DEFAULT_WORLD_ID)), str(accounts [clean_account_id].get("currency", DEFAULT_CURRENCY)), {
		"account_id": clean_account_id,
		"status": clean_status,
		"text": "A Bank Engine account status changed."
	})
	if clean_status == ACCOUNT_STATUS_OPEN and gs != null and not gs.scenario_state.get(FamilyContractEngine.PENDING_LINEAGE_ESTATES, {}).is_empty():
		if gs.family_contract_engine == null:
			gs.family_contract_engine = FamilyContractEngine.new(gs)
		gs.family_contract_engine.retry_pending_lineage_estates(str(accounts[clean_account_id].owner_id))
	last_report = report.duplicate(true)
	return report

func get_player_bank_rows(context: Dictionary = {}) -> Array:
	if gs == null or gs.player == null:
		return []
	repair_legacy_player_money_mirror()
	var summary: Dictionary = get_owner_summary_for_actor(gs.player, context)
	return [
		{
			"label": "💵 Cash on hand: %s — physical, risky, stealable, droppable." % _format_money(float(summary.get("cash_on_hand", 0.0)), str(summary.get("currency", DEFAULT_CURRENCY))),
			"kind": "cash",
			"value": float(summary.get("cash_on_hand", 0.0))
		},
		{
			"label": "🏦 Bank balance: %s — secured money for rent, businesses, contracts, lawsuits, investments, and big purchases." % _format_money(float(summary.get("bank_balance", 0.0)), str(summary.get("currency", DEFAULT_CURRENCY))),
			"kind": "bank",
			"value": float(summary.get("bank_balance", 0.0))
		},
		{
			"label": "🌐 InterWorld Credit: %s — cross-server / cross-realm credit, only if policy allows it." % _format_money(float(summary.get("interworld_credit", 0.0)), str(summary.get("currency", DEFAULT_CURRENCY))),
			"kind": "interworld_credit",
			"value": float(summary.get("interworld_credit", 0.0))
		},
		{
			"label": "🧾 Total accessible money: %s" % _format_money(float(summary.get("total_accessible", 0.0)), str(summary.get("currency", DEFAULT_CURRENCY))),
			"kind": "summary",
			"value": float(summary.get("total_accessible", 0.0))
		}
	]

func get_player_cash_rows(context: Dictionary = {}) -> Array:
	if gs == null or gs.player == null:
		return []
	repair_legacy_player_money_mirror()
	var owner_id: String = owner_key_from_actor(gs.player)
	var world_id: String = _resolve_world_id(context)
	var currency: String = _resolve_currency(context)
	var wallet: Dictionary = ensure_cash_wallet(owner_id, world_id, currency, context)
	return [
		{
			"label": "Cash wallet: %s in %s. This can be robbed, dropped, seized, or lost in events." % [_format_money(float(wallet.get("amount", 0.0)), currency), world_id],
			"wallet_id": str(wallet.get("wallet_id", "")),
			"kind": "cash_wallet"
		}
	]

func get_player_account_rows(_context: Dictionary = {}) -> Array:
	if gs == null or gs.player == null:
		return []
	repair_legacy_player_money_mirror()
	var owner_id: String = owner_key_from_actor(gs.player)
	var out: Array = []
	for account_id in _accounts_for_owner(owner_id):
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) != TYPE_DICTIONARY:
			continue
		var account: Dictionary = account_raw
		out.append({
			"label": "%s %s • %s • %s • %s" % [
				"🌐" if str(account.get("type", "")) == ACCOUNT_KIND_INTERWORLD else "🏦",
				str(account.get("type", "bank")).capitalize(),
				_format_money(float(account.get("balance", 0.0)), str(account.get("currency", DEFAULT_CURRENCY))),
				str(account.get("world_id", DEFAULT_WORLD_ID)),
				str(account.get("status", ACCOUNT_STATUS_OPEN))
			],
			"account_id": account_id,
			"kind": str(account.get("type", ACCOUNT_KIND_BANK))
		})
	return out

func get_risk_rows(_context: Dictionary = {}) -> Array:
	return [
		{ "label": "Cash can be stolen, robbed, dropped, seized, burned by disaster, or lost in world events."},
		{ "label": "Bank money is safer but can be frozen by courts, sanctions, fraud investigations, bankruptcy, war collapse, or bank failure."},
		{ "label": "InterWorld Credit can cross Discord worlds / realms only when era, route, and policy gates allow it."},
		{ "label": "Legacy Person.bank_balance is now a mirror. BankEngine owns the truth."}
	]

func _finish_money_action(event_name: String, owner_id: String, amount: float, world_id: String, currency: String, extra: Dictionary = {}) -> Dictionary:
	var tx: Dictionary = _record_ledger(event_name, {
		"owner_id": owner_id,
		"amount": amount,
		"world_id": world_id,
		"currency": currency,
		"extra": extra.duplicate(true)
	})
	var text: String = str(extra.get("text", event_name)).strip_edges()
	if gs != null and gs.event_bus != null and gs.event_bus.has_method("emit"):
		gs.event_bus.emit(event_name, {
			"source": "bank_engine",
			"owner_id": owner_id,
			"amount": amount,
			"world_id": world_id,
			"currency": currency,
			"transaction": tx.duplicate(true),
			"text": text,
			"qos_tier": "important"
		})
	if gs != null and gs.has_method("push_world_feed") and amount > 0.0:
		gs.push_world_feed(text, {
			"category": "money",
			"event_name": event_name,
			"source": "bank_engine",
			"owner_id": owner_id,
			"amount": amount,
			"currency": currency,
			"world_id": world_id
		})
	return {
		"schema": "eralife.bank_action_report",
		"version": CONTRACT_VERSION,
		"success": true,
		"event_name": event_name,
		"owner_id": owner_id,
		"amount": amount,
		"world_id": world_id,
		"currency": currency,
		"transaction": tx.duplicate(true),
		"summary": get_owner_summary(owner_id, { "world_id": world_id, "currency": currency}),
		"completed_at_ms": int(Time.get_ticks_msec())
	}

func _record_ledger(event_name: String, data: Dictionary = {}) -> Dictionary:
	_tx_seq += 1
	var tx:= {
		"schema": "eralife.money_transaction",
		"version": CONTRACT_VERSION,
		"tx_id": "tx_%d" % _tx_seq,
		"event_name": event_name,
		"data": data.duplicate(true),
		"created_at_ms": int(Time.get_ticks_msec()),
		"year": int(gs.year) if gs != null and gs.get("year") != null else 0
	}
	ledger.append(tx)
	if ledger.size() > LEDGER_LIMIT:
		ledger = ledger.slice(ledger.size() - LEDGER_LIMIT, ledger.size())
	return tx

func owner_key_from_actor(actor) -> String:
	if actor == null:
		return ""
	if actor.get("id") != null:
		return "person:%d" % int(actor.id)
	return "person:unknown"

func _note_legacy_routed_owner(owner: Variant) -> void:
	if owner is String and (owner.begins_with("life:") or owner.begins_with("discord:")):
		legacy_routed_owners[owner] = ""


func _routed_identity(context: Dictionary) -> Dictionary:
	var user := str(context.get("user_id", context.get("external_user_id", ""))).strip_edges()
	var guild := str(context.get("guild_id", context.get("world_container_id", ""))).strip_edges()
	if user != "" and guild != "":
		return {"key": "discord2:%s:%s" % [guild.uri_encode(), user.uri_encode()],
			"legacy": "discord:%s:%s" % [_safe_id(guild), _safe_id(user)],
			"unambiguous": _numeric_identity(guild) and _numeric_identity(user)}
	var life := str(context.get("life_node_id", "")).strip_edges()
	if life != "":
		return {"key": "life2:" + life, "legacy": "life:" + _safe_id(life), "unambiguous": _numeric_identity(life)}
	return {}


func external_birth_bank_owners() -> Array:
	var result: Array = []
	if gs == null:
		return result
	var birth: Dictionary = gs.scenario_state.get("external_birth_intent", {})
	if birth.get("world_mode") != "solo":
		return result
	for context in [birth, {"life_node_id": birth.get("life_node_id", "")}]:
		if not _routed_identity(context).is_empty():
			var route := _resolve_bank_owner(context)
			if route.success and route.owner_id not in result:
				result.append(route.owner_id)
	return result


func _numeric_identity(value: String) -> bool:
	return value.is_valid_int() and not value.begins_with("-") and not value.begins_with("+")


# Local save recovery only. The host supplies the verified original identity
# after reconciling its records. Player commands cannot create a binding.
func recover_legacy_routed_owner(legacy: String, verified_identity: Dictionary) -> Dictionary:
	var identity := _routed_identity(verified_identity)
	if not legacy_routed_owners.has(legacy) or identity.get("legacy") != legacy:
		return {"success": false, "reason": "The verified identity does not match this saved owner."}
	if legacy_routed_owners[legacy] not in ["", identity.key]:
		return {"success": false, "reason": "This saved owner already belongs to another identity."}
	legacy_routed_owners[legacy] = identity.key
	return {"success": true, "owner_id": legacy}


func _resolve_bank_owner(context: Dictionary) -> Dictionary:
	var direct := str(context.get("owner_id", "")).strip_edges()
	if direct != "":
		return {"success": true, "owner_id": direct}
	var actor_id := int(context.get("player_id", context.get("actor_id", -1)))
	if actor_id > 0:
		return {"success": true, "owner_id": "person:%d" % actor_id}
	var identity := _routed_identity(context)
	if identity.is_empty():
		return {"success": true, "owner_id": owner_key_from_actor(gs.player) if gs != null else ""}
	var legacy: String = identity.legacy
	if not legacy_routed_owners.has(legacy):
		return {"success": true, "owner_id": identity.key}
	if legacy_routed_owners[legacy] == "":
		if identity.unambiguous:
			return recover_legacy_routed_owner(legacy, context)
		# A solo save can identify the original owner from its stored birth
		# record, even if a different spelling makes the first request.
		if gs != null:
			var birth: Dictionary = gs.scenario_state.get("external_birth_intent", {})
			if birth.get("world_mode") == "solo":
				var original := {"life_node_id": birth.get("life_node_id", "")} if legacy.begins_with("life:") else birth
				if _routed_identity(original).get("legacy") == legacy:
					recover_legacy_routed_owner(legacy, original)
	if legacy_routed_owners[legacy] == "":
		return {"success": false, "code": "legacy_owner_recovery_required", "legacy_owner_id": legacy,
			"reason": "This save needs its original bank owner verified before using these funds."}
	var owner: String = legacy if legacy_routed_owners[legacy] == identity.key else identity.key
	return {"success": true, "owner_id": owner}


func settle_obligation_for_actor(
	actor,
	amount: float,
	payload: Dictionary = {},
	context: Dictionary = {}
) -> Dictionary:
	if actor == null:
		return {
			"success": false,
			"reason": "No actor supplied."
		}

	var merged_context: Dictionary = context.duplicate(
		true
	)
	merged_context ["actor_id"] = (
		int(actor.id)
		if actor.get("id") != null
		else -1
	)
	merged_context [
		"owner_id"
	] = owner_key_from_actor(
		actor
	)
	if not context.has("world_id") and not context.has("world_container_id") and not context.has("guild_id"):
		if actor.get("realm_id") != null and int(actor.realm_id) >= 0:
			merged_context["world_id"] = "realm:%d" % int(actor.realm_id)

	merged_context["import_legacy_balance"] = true
	var account: Dictionary = ensure_bank_account_for_actor(
		actor,
		merged_context
	)
	var account_id: String = str(
		account.get(
			"account_id",
			""
		)
	)

	if account_id == "":
		return {
			"success": false,
			"reason": "Could not resolve the actor's bank account."
		}


	return settle_obligation(
		owner_key_from_actor(
			actor
		),
		amount,
		str(
			account.get(
				"world_id",
				_resolve_world_id(
					context
				)
			)
		),
		str(
			account.get(
				"currency",
				_resolve_currency(
					context
				)
			)
		),
		payload,
		merged_context
	)


func settle_obligation(
	owner_id: String,
	amount: float,
	world_id: String = "",
	currency: String = DEFAULT_CURRENCY,
	payload: Dictionary = {},
	context: Dictionary = {}
) -> Dictionary:
	if not is_finite(amount):
		return {"success": false, "reason": "Obligation amount must be finite."}
	amount = _money_amount(
		amount
	)

	if amount <= 0.0:
		return {
			"success": true,
			"skipped": true,
			"amount": 0.0,
			"reason": "No obligation amount."
		}

	var clean_owner: String = str(
		owner_id
	).strip_edges()

	if clean_owner == "":
		return {
			"success": false,
			"reason": "Obligation is missing an owner."
		}

	var resolution_context: Dictionary = context.duplicate(
		true
	)

	if str(world_id).strip_edges() != "":
		resolution_context [
			"world_id"
		] = world_id

	var clean_world: String = _resolve_world_id(
		resolution_context
	)
	var clean_currency: String = str(
		currency
	).strip_edges().to_upper()

	if clean_currency == "":
		clean_currency = _resolve_currency(
			resolution_context
		)

	var account: Dictionary = ensure_account(
		clean_owner,
		clean_world,
		ACCOUNT_KIND_BANK,
		clean_currency,
		{
			"transfer_scope": TRANSFER_SCOPE_LOCAL
		}
	)
	var account_id: String = str(
		account.get(
			"account_id",
			""
		)
	)

	if account_id == "":
		return {
			"success": false,
			"reason": "No bank account could settle the obligation."
		}

	var balance: float = max(
		0.0,
		float(
			accounts [
				account_id
			].get(
				"balance",
				0.0
			)
		)
	)

	if amount > balance:
		return {
			"success": false,
			"reason": "Not enough money in the bank.",
			"bank_balance": balance,
			"required_amount": amount
		}

	var gate: Dictionary = _can_credit_or_debit(
		account_id,
		amount,
		"debit",
		resolution_context
	)

	if not bool(
		gate.get(
			"allowed",
			true
		)
	):
		return {
			"success": false,
			"reason": str(
				gate.get(
					"reason",
					"Payment blocked."
				)
			),
			"gate": gate
		}

	accounts [
		account_id
	] ["balance"] = max(
		0.0,
		balance - amount
	)
	accounts [
		account_id
	] ["updated_at_ms"] = int(
		Time.get_ticks_msec()
	)

	_sync_actor_by_owner(
		clean_owner
	)

	var report: Dictionary = _finish_money_action(
		"money_obligation_settled",
		clean_owner,
		amount,
		clean_world,
		clean_currency,
		{
			"account_id": account_id,
			"reason": str(
				payload.get(
					"reason",
					context.get(
						"reason",
						"obligation"
					)
				)
			),
			"program_id": str(
				payload.get(
					"program_id",
					""
				)
			),
			"text": str(
				payload.get(
					"text",
					"An obligation was paid from the bank."
				)
			)
		}
	)

	last_report = report.duplicate(
		true
	)

	return report
func _resolve_world_id(context: Dictionary = {}) -> String:
	var clean: String = str(context.get("world_id", context.get("world_container_id", context.get("guild_id", "")))).strip_edges()
	if clean != "":
		return clean
	if gs != null and gs.player != null and gs.player.get("realm_id") != null and int(gs.player.realm_id) >= 0:
		return "realm:%d" % int(gs.player.realm_id)
	return DEFAULT_WORLD_ID

func _resolve_currency(context: Dictionary = {}) -> String:
	var clean: String = str(context.get("currency", DEFAULT_CURRENCY)).strip_edges().to_upper()
	if clean == "":
		clean = DEFAULT_CURRENCY
	return clean

func _bank_action_from_command(command_id: String) -> String:
	var clean: String = str(command_id).strip_edges().to_lower()
	match clean:
		"bank.deposit", "deposit_money":
			return "deposit"
		"bank.withdraw", "withdraw_money":
			return "withdraw"
		"bank.credit_cash", "bank.crime_payout_cash":
			return "credit_cash"
		"bank.transfer", "transfer_money":
			return "transfer"
		"bank.status", "bank.balance", "bank.summary":
			return "summary"
		"bank.steal_cash", "bank.rob_cash":
			return "steal_cash"
		"bank.apply_justice_penalty", "bank.justice_fine", "bank.justice_restitution", "bank.asset_seizure":
			return "apply_justice_penalty"
		"bank.freeze_owner_accounts":
			return "freeze_owner_accounts"
		_:
			return clean.replace("bank.", "")

func _account_id(owner_id: String, world_id: String, account_kind: String, currency: String) -> String:
	var legacy := "acct.%s.%s.%s.%s" % [_safe_id(owner_id), _safe_id(world_id), _safe_id(account_kind), _safe_id(currency)]
	var row: Dictionary = accounts.get(legacy, {})
	if row.get("owner_id") == owner_id and row.get("world_id") == world_id and row.get("type") == account_kind and row.get("currency") == currency:
		return legacy
	return "acct2:" + JSON.stringify([owner_id, world_id, account_kind, currency])

func _wallet_id(owner_id: String, world_id: String, currency: String) -> String:
	var legacy := "cash.%s.%s.%s" % [_safe_id(owner_id), _safe_id(world_id), _safe_id(currency)]
	var row: Dictionary = cash_on_hand.get(legacy, {})
	if row.get("owner_id") == owner_id and row.get("world_id") == world_id and row.get("currency") == currency:
		return legacy
	return "cash2:" + JSON.stringify([owner_id, world_id, currency])

func _safe_id(value: Variant) -> String:
	var out: String = str(value).strip_edges().to_lower()
	out = out.replace(" ", "_")
	out = out.replace(":", "_")
	out = out.replace("/", "_")
	out = out.replace(".", "_")
	out = out.replace("-", "_")
	if out == "":
		out = "unknown"
	return out

func _money_amount(value: Variant) -> float:
	var amount: float = float(value)
	if not is_finite(amount) or amount < 0.0:
		amount = 0.0
	return amount

func _can_credit_or_debit(account_id: String, amount: float, direction: String, _context: Dictionary = {}) -> Dictionary:
	if not accounts.has(account_id):
		return { "allowed": false, "reason": "Account does not exist."}
	var account: Dictionary = accounts.get(account_id, {})
	var status: String = str(account.get("status", ACCOUNT_STATUS_OPEN)).strip_edges().to_lower()
	if status in [ACCOUNT_STATUS_FROZEN, ACCOUNT_STATUS_SANCTIONED]:
		return { "allowed": false, "reason": "Account is %s." % status, "status": status}
	if direction == "credit" and not is_finite(float(account.balance) + amount):
		return {"allowed": false, "reason": "Credit exceeds the supported account balance."}
	return { "allowed": true, "amount": amount, "direction": direction}

func _can_steal_cash(_thief_owner_id: String, victim_owner_id: String, amount: float, world_id: String, currency: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var permissions_raw: Variant = active_contract.get("permissions", {})
	var permissions: Dictionary = permissions_raw if typeof(permissions_raw) == TYPE_DICTIONARY else {}
	if not bool(permissions.get("allow_cash_theft", true)):
		return { "allowed": false, "reason": "Cash theft disabled by bank contract."}
	if bool(permissions.get("require_governed_theft", true)) and not bool(payload.get("governed", context.get("governed", false))):
		return { "allowed": false, "reason": "Cash theft must be routed by a governed crime/event/system."}
	var wallet: Dictionary = ensure_cash_wallet(victim_owner_id, world_id, currency, context)
	var victim_cash: float = max(0.0, float(wallet.get("amount", 0.0)))
	var max_percent: float = clamp(float(permissions.get("max_cash_theft_percent", 0.35)), 0.0, 1.0)
	var max_allowed: float = maxf(1.0, floor(victim_cash * max_percent)) if max_percent > 0.0 else 0.0
	if amount > max_allowed:
		return { "allowed": false, "reason": "Requested theft exceeds governed theft limit.", "max_allowed": max_allowed, "victim_cash": victim_cash}
	return { "allowed": true, "max_allowed": max_allowed, "victim_cash": victim_cash}

func _interworld_allowed(_from_world_id: String, _to_world_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> bool:
	var permissions_raw: Variant = active_contract.get("permissions", {})
	var permissions: Dictionary = permissions_raw if typeof(permissions_raw) == TYPE_DICTIONARY else {}
	if not bool(permissions.get("allow_interworld_credit", true)):
		return false
	var from_era: String = str(payload.get("from_era", context.get("from_era", ""))).strip_edges().to_lower()
	var to_era: String = str(payload.get("to_era", context.get("to_era", from_era))).strip_edges().to_lower()
	if from_era != "" and to_era != "" and from_era != to_era:
		return bool(payload.get("allow_cross_era", false))
	return true

func _sync_actor_by_owner(owner_id: String) -> void:
	if not owner_id.begins_with("person:"):
		return
	if gs == null or not gs.has_method("get_npc_by_id"):
		return
	var id_text: String = owner_id.replace("person:", "")
	if not id_text.is_valid_int():
		return
	var actor = gs.player if gs.player != null and gs.player.id == int(id_text) else gs.get_npc_by_id(int(id_text))
	if actor != null:
		_sync_actor_money_mirror(actor)

func _sync_actor_money_mirror(actor) -> void:
	if actor == null or actor.get("bank_balance") == null:
		return
	var summary: Dictionary = get_owner_summary_for_actor(actor, {})
	actor.bank_balance = float(summary.get("bank_balance", 0.0))

func _accounts_for_owner(owner_id: String) -> Array:
	var clean: String = str(owner_id).strip_edges()
	if owner_index.has(clean) and typeof(owner_index.get(clean, [])) == TYPE_ARRAY:
		return owner_index.get(clean, []).duplicate(true)
	var out: Array = []
	for account_id in accounts.keys():
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) == TYPE_DICTIONARY and str((account_raw as Dictionary).get("owner_id", "")) == clean:
			out.append(str(account_id))
	owner_index [clean] = out.duplicate(true)
	return out

func _index_account(account_id: String, owner_id: String) -> void:
	var clean_owner: String = str(owner_id).strip_edges()
	if clean_owner == "":
		return
	var arr: Array = owner_index.get(clean_owner, []) if typeof(owner_index.get(clean_owner, [])) == TYPE_ARRAY else []
	if account_id not in arr:
		arr.append(account_id)
	owner_index [clean_owner] = arr

func _rebuild_owner_index() -> void:
	owner_index.clear()
	for account_id in accounts.keys():
		var account_raw: Variant = accounts.get(account_id, {})
		if typeof(account_raw) != TYPE_DICTIONARY:
			continue
		_index_account(str(account_id), str((account_raw as Dictionary).get("owner_id", "")))

func _format_money(amount: float, currency: String = DEFAULT_CURRENCY) -> String:
	var clean_currency: String = str(currency).strip_edges().to_upper()
	if clean_currency == "":
		clean_currency = DEFAULT_CURRENCY
	return "%s %.2f" % [clean_currency, amount]

func _build_default_contract() -> Dictionary:
	return {
		"schema": "eralife.bank_contract",
		"version": CONTRACT_VERSION,
		"id": "eralife_default_bank_contract",
		"money_authority": "bank_engine",
		"legacy_money_mirror": "Person.bank_balance",
		"account_types": [ACCOUNT_KIND_BANK, ACCOUNT_KIND_INTERWORLD],
		"cash_policy": {
			"physical": true,
			"stealable": true,
			"droppable": true,
		},
		"permissions": {
			"allow_cash_theft": true,
			"require_governed_theft": true,
			"max_cash_theft_percent": 0.35,
			"allow_interworld_credit": true,
		},
		"routes": {
			"large_purchases": "bank",
			"rent": "bank",
			"businesses": "bank",
			"investments": "bank",
			"lawsuits": "bank",
			"royal_taxes": "bank",
			"contracts": "bank",
			"boxing_purses": "bank",
			"server_economies": "interworld_credit"
		},
		"metadata": {
			"save_persistent": true,
			"backwards_compatible": true
		}
	}

func _merge_dict(base: Dictionary, patch: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key in patch.keys():
		var patch_value: Variant = patch [key]
		if typeof(patch_value) == TYPE_DICTIONARY and typeof(out.get(key, {})) == TYPE_DICTIONARY:
			out [key] = _merge_dict(out.get(key, {}), patch_value as Dictionary)
		else:
			out [key] = patch_value
	return out

func _make_binary_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var out:= {}
			for key in value.keys():
				out [str(key)] = _make_binary_safe(value [key])
			return out
		TYPE_ARRAY:
			var arr:= []
			for item in value:
				arr.append(_make_binary_safe(item))
			return arr
		TYPE_COLOR:
			var c: Color = value
			return "#%s" % c.to_html(true)
		TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_BOOL:
			return value
		TYPE_NIL:
			return null
		_:
			return str(value)
