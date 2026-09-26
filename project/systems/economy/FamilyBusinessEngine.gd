extends Resource
class_name FamilyBusinessEngine

## A small, persistent partnership. BankEngine owns its money; this owner keeps
## stakes, operating policy, succession and the business's remembered decisions.
const STATE_KEY := "family_businesses"
const ACTIONS := ["found", "invest", "draw", "expense", "policy", "handover", "leave"]
var gs

func _init(state = null) -> void:
	gs = state

func _state() -> Dictionary:
	if not gs.scenario_state.get(STATE_KEY) is Dictionary:
		gs.scenario_state[STATE_KEY] = {"version": 1, "ventures": {}, "owner_index": {}}
	return gs.scenario_state[STATE_KEY]

func ventures_for(actor_id: int) -> Array:
	var out: Array = []
	var state: Dictionary = gs.scenario_state.get(STATE_KEY, {})
	for id in state.get("owner_index", {}).get(str(actor_id), []):
		var venture: Dictionary = state.get("ventures", {}).get(str(id), {})
		if int(venture.get("stakes", {}).get(str(actor_id), 0)) > 0:
			out.append(venture)
	return out

func _person(id: int) -> Person:
	return gs.player if gs.player != null and gs.player.id == id else gs.get_npc_by_id(id, false)

func balance(venture: Dictionary) -> int:
	if gs.bank_engine == null:
		return 0
	return int(gs.bank_engine.accounts.get(str(venture.get("account_id", "")), {}).get("balance", 0))

func heir_for(person: Person) -> Person:
	var heirs: Array = []
	for id in person.children:
		var child := _person(int(id))
		# Do not select a substitute while a child's identity is still unloaded.
		if child == null:
			return null
		if child.alive and child.age >= 18:
			heirs.append(child)
	heirs.sort_custom(func(a, b): return a.age > b.age if a.age != b.age else a.id < b.id)
	return heirs[0] if not heirs.is_empty() else null

func service_actor(actor: Person) -> void:
	if not gs.scenario_state.has(STATE_KEY) or gs.bank_engine == null:
		return
	if int(_state().get("version", 0)) != 1:
		return
	# Only inspect this person's parents and indexed holdings, never the world.
	for parent_id in actor.parents:
		var parent := _person(int(parent_id))
		if parent == null or parent.alive:
			continue
		var heir := heir_for(parent)
		if heir == null or heir.id != actor.id:
			continue
		for venture in ventures_for(parent.id):
			_inherit(venture, parent, actor)
			_log(venture, "succession", "%s inherited %s's stake." % [_name(actor), _name(parent)])
	for venture in ventures_for(actor.id):
		var elapsed: int = int(gs.year) - int(venture.last_year)
		if elapsed <= 0:
			continue
		# One aggregate settlement on resume. Same-year actor switches cannot pay
		# twice, and a long absence cannot cause an unbounded catch-up loop.
		var annual: int = int(round((120 + int(venture.quality) * 2 + int(venture.reputation)) * float(venture.scale)))
		var years: int = mini(elapsed, 100)
		var report: Dictionary = gs.bank_engine.credit_bank(str(venture.bank_owner), annual * years,
			str(venture.world_id), "USD", {"source": "family_business", "text": "Net operating surplus from " + str(venture.name)})
		if not bool(report.get("success", false)):
			continue
		venture.last_year = int(gs.year)
		venture.last_surplus = annual * years
		_log(venture, "operations", "%d years of net operating surplus: $%d." % [years, annual * years])
		_invalidate(venture)

func apply(actor: Person, instance: Dictionary, effect: Dictionary) -> Dictionary:
	var action := str(effect.get("action", "policy"))
	if action not in ACTIONS or gs.bank_engine == null:
		return _failure("The business banking service is unavailable.")
	var state := _state()
	if int(state.get("version", 0)) != 1:
		return _failure("This business save needs a compatible version.")
	var id := str(instance.get("venture_id", "family_business:%d" % actor.id))
	var venture: Dictionary = state.ventures.get(id, {})
	var amount := int(round(int(effect.get("amount", 0)) * float(instance.scale)))
	if action == "found":
		if not venture.is_empty() or not ventures_for(actor.id).is_empty():
			return _failure("You already hold a family business stake.")
		var partner := _person(int(instance.cast_id))
		if partner == null or not partner.alive or amount <= 0:
			return _failure("Your cofounder is unavailable.")
		var account: Dictionary = gs.bank_engine.ensure_bank_account_for_actor(actor, {"import_legacy_balance": true})
		var owner := "business:" + id
		var report: Dictionary = gs.bank_engine.transfer_owner_to_owner(gs.bank_engine.owner_key_from_actor(actor), owner,
			amount, str(account.world_id), "USD", {}, {"source": "family_business"})
		if not bool(report.get("success", false)):
			return report
		var company_account: Dictionary = gs.bank_engine.ensure_account(owner, str(account.world_id))
		venture = {"id": id, "name": actor.last_name + " & Co.", "founder_id": actor.id,
			"manager_id": actor.id, "cofounder_id": partner.id, "cast": instance.ensemble.duplicate(true),
			"stakes": {str(actor.id): 60, str(partner.id): 40}, "inherited_from": {},
			"bank_owner": owner, "account_id": company_account.account_id, "world_id": account.world_id,
			"scale": float(instance.scale), "quality": 50, "reputation": 50, "policy": "shared_decisions",
			"founded_year": int(gs.year), "last_year": int(gs.year), "last_surplus": 0, "history": [], "legacy": "new_partnership"}
		state.ventures[id] = venture
		instance.venture_id = id
		_index(venture, actor.id)
		_index(venture, partner.id)
		actor.career_profile["career_history"].append({"kind": "family_business_founder", "organization_id": id,
			"organization_name": venture.name, "year": int(gs.year), "part_time": true})
	else:
		if venture.is_empty() or int(venture.stakes.get(str(actor.id), 0)) <= 0:
			return _failure("This life does not own a stake in that business.")
		if action in ["policy", "invest", "expense", "handover"] and int(venture.manager_id) != actor.id:
			return _failure("The business is now managed by another family member.")
		var account: Dictionary = gs.bank_engine.accounts.get(str(venture.account_id), {})
		if account.is_empty():
			return _failure("The business account has not finished loading.")
		var heir: Person = heir_for(actor) if action == "handover" else null
		if action == "handover" and heir == null:
			return _failure("An adult child must be present to take over. You can keep managing instead.")
		var partner := _person(int(venture.cofounder_id))
		if action == "leave" and (partner == null or not partner.alive or partner.id == actor.id):
			return _failure("Your original cofounder cannot take over. Keep the business in the family instead.")
		if action in ["invest", "draw", "expense", "leave"]:
			gs.bank_engine.ensure_bank_account_for_actor(actor, {"import_legacy_balance": true})
			var owner: String = gs.bank_engine.owner_key_from_actor(actor)
			var report: Dictionary = {"success": true}
			if action == "invest":
				report = gs.bank_engine.transfer_owner_to_owner(owner, venture.bank_owner, amount, venture.world_id)
			elif action == "expense":
				report = gs.bank_engine.spend(venture.bank_owner, amount, venture.world_id, "USD", {"reason": "family_business_investment"})
			else:
				var available := int(floor(balance(venture) * int(venture.stakes[str(actor.id)]) / 100.0))
				if action == "leave":
					amount = available
				elif amount > available:
					return _failure("That draw exceeds your share of the business reserves. Keep the money in the business instead.")
				if amount > 0:
					report = gs.bank_engine.transfer_owner_to_owner(venture.bank_owner, owner, amount, venture.world_id)
			if not bool(report.get("success", false)):
				return report
		if action == "handover":
			_inherit(venture, actor, heir)
		if action == "leave":
			_transfer_stake(venture, actor.id, partner.id)
	for field in ["quality", "reputation"]:
		venture[field] = clampi(int(venture[field]) + int(effect.get(field, 0)), 0, 100)
	if effect.has("policy"):
		venture.policy = str(effect.policy)
	if effect.has("legacy"):
		venture.legacy = str(effect.legacy)
	_log(venture, action, str(effect.get("note", action.replace("_", " ").capitalize())))
	_invalidate(venture)
	return {"success": true, "venture_id": id, "business_balance": balance(venture)}

func describe(venture: Dictionary, actor_id: int) -> String:
	return "%s · %d%% ownership\nBusiness reserves: $%d · Quality: %d/100 · Reputation: %d/100\nPolicy: %s. Legacy: %s.\nNet annual surplus is retained by the business; it is separate from your personal bank balance." % [
		str(venture.name), int(venture.stakes.get(str(actor_id), 0)), balance(venture), int(venture.quality), int(venture.reputation),
		str(venture.policy).replace("_", " "), str(venture.legacy).replace("_", " ")]

func portfolio(actor_id: int) -> Dictionary:
	var rows: Array = []
	var lines: Array[String] = []
	for venture in ventures_for(actor_id):
		rows.append({"id": venture.id, "name": venture.name, "stake_percent": int(venture.stakes[str(actor_id)]),
			"reserves": balance(venture), "legacy": venture.legacy, "manager_id": venture.manager_id})
		lines.append(describe(venture, actor_id))
	return {"rows": rows, "text": "\n\n".join(lines)}

func _inherit(venture: Dictionary, parent: Person, heir: Person) -> void:
	_transfer_stake(venture, parent.id, heir.id)
	venture.inherited_from[str(heir.id)] = parent.id
	var partner := _person(int(venture.cofounder_id))
	if partner != null and partner.alive and partner.id != heir.id and gs.relationship_engine != null:
		var remembered := clampi(int(parent.affection.get(partner.id, 50)) - 50, -20, 20)
		gs.relationship_engine.adjust_relationship(heir, partner, remembered)

func _transfer_stake(venture: Dictionary, old_id: int, new_id: int) -> void:
	var stake := int(venture.stakes.get(str(old_id), 0))
	venture.stakes[str(new_id)] = int(venture.stakes.get(str(new_id), 0)) + stake
	venture.stakes.erase(str(old_id))
	if int(venture.manager_id) == old_id:
		venture.manager_id = new_id
	_index(venture, new_id)
	_invalidate(venture)
	if gs.assets_contract_engine != null:
		gs.assets_contract_engine.invalidate_actor(old_id)

func _index(venture: Dictionary, actor_id: int) -> void:
	var index: Dictionary = _state().owner_index
	if not index.has(str(actor_id)):
		index[str(actor_id)] = []
	if str(venture.id) not in index[str(actor_id)]:
		index[str(actor_id)].append(str(venture.id))

func _log(venture: Dictionary, action: String, text: String) -> void:
	venture.history.append({"year": int(gs.year), "action": action, "text": text})
	while venture.history.size() > 48:
		venture.history.pop_front()

func _invalidate(venture: Dictionary) -> void:
	if gs.assets_contract_engine != null:
		for id in venture.stakes:
			gs.assets_contract_engine.invalidate_actor(int(id))

func _name(person: Person) -> String:
	return (person.first_name + " " + person.last_name).strip_edges()

func _failure(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
