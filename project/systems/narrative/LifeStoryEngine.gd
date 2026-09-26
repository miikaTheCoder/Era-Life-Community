extends Resource
class_name LifeStoryEngine

## Persistent, authored stories for the controlled life. Presentation remains in
## the existing pending-situation contracts; this owner never builds UI controls.
const STATE_KEY := "life_stories"
const STATE_VERSION := 1
const CONTENT_PATH := "res://data/life_stories.json"
const MAX_ACTIVE_STORIES := 2
const START_COOLDOWN_YEARS := 2
const STAT_KEYS := ["smarts", "mental_health", "health", "job_performance"]

var gs
var catalog: Array = []
var content_errors: Array = []
var family_business_engine: Variant = null

func _init(state = null) -> void:
	gs = state
	for path in [CONTENT_PATH, "res://data/shared_lives.json"]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			content_errors.append("Story content could not be opened: " + path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		var errors := validate_catalog(parsed)
		content_errors.append_array(errors)
		if errors.is_empty():
			catalog.append_array(parsed.stories)

func businesses():
	if family_business_engine == null:
		family_business_engine = load("res://systems/economy/FamilyBusinessEngine.gd").new(gs)
	return family_business_engine

static func validate_catalog(data: Variant) -> Array:
	var errors: Array = []
	if not data is Dictionary or data.get("schema", "") != "eralife.life_stories" or int(data.get("version", 0)) != 1:
		return ["Unsupported Life Stories content schema."]
	if not data.get("stories") is Array or data.stories.is_empty():
		return ["Life Stories requires a nonempty story catalog."]
	var ids: Dictionary = {}
	for story in data.stories:
		if not story is Dictionary or str(story.get("id", "")) == "" or not story.get("nodes") is Dictionary:
			errors.append("Invalid story definition.")
			continue
		var id: String = str(story.id)
		if str(story.get("cast", "")) not in ["friend", "relative", "mentor", "parent", "accomplice", "legacy", "business_partners", "business_heir"]:
			errors.append(id + ": unknown cast role.")
		if ids.has(id):
			errors.append("Duplicate story: " + id)
		ids[id] = true
		if not story.nodes.has(str(story.get("start", ""))):
			errors.append(id + ": missing starting chapter.")
		for node_id in story.nodes:
			var node: Variant = story.nodes[node_id]
			if not node is Dictionary or not node.get("choices") is Array or node.choices.is_empty():
				errors.append(id + ": invalid chapter " + str(node_id))
				continue
			if str(node.get("title", "")) == "" or str(node.get("text", "")) == "" or int(node.get("deadline", 2)) < 1:
				errors.append(id + ": missing chapter text or invalid deadline.")
			var choices: Dictionary = {}
			for choice in node.choices:
				if not choice is Dictionary or str(choice.get("id", "")) == "":
					errors.append(id + ": invalid choice.")
					continue
				if choices.has(choice.id):
					errors.append(id + ": duplicate choice " + str(choice.id))
				choices[choice.id] = choice
				if str(choice.get("label", "")) == "" or str(choice.get("result", "")) == "":
					errors.append(id + ": a response needs its label and outcome text.")
				if choice.has("cash"):
					errors.append(id + ": money effects must be transfers between participants.")
				var next: String = str(choice.get("next", ""))
				for destination in _destinations(choice):
					if not story.nodes.has(destination):
						errors.append(id + ": missing destination " + destination)
				var business: Dictionary = choice.get("business", {})
				if not business.is_empty():
					if str(story.cast) not in ["business_partners", "business_heir"] or int(choice.get("transfer", 0)) != 0:
						errors.append(id + ": business effects require an ensemble and cannot mix money owners.")
					if str(business.get("action", "policy")) not in ["found", "invest", "draw", "expense", "policy", "handover", "leave"]:
						errors.append(id + ": unknown business action.")
					if str(business.get("action", "policy")) in ["found", "invest", "draw", "expense"] and int(business.get("amount", 0)) <= 0:
						errors.append(id + ": money actions require a positive amount.")
				for relation in choice.get("relationships", []):
					if str(relation.get("from", "player")) not in ["player", "cofounder", "mentor"] or str(relation.get("to", "")) not in ["player", "cofounder", "mentor"]:
						errors.append(id + ": unknown relationship role.")
				if next != "" and int(choice.get("delay", 1)) < 1:
					errors.append(id + ": follow-ups must occur in a later year.")
				for stat in choice.get("stats", {}):
					if stat not in STAT_KEYS:
						errors.append(id + ": unknown stat " + str(stat))
			var fallback: Dictionary = choices.get(str(node.get("default", "")), {})
			if fallback.is_empty() or int(fallback.get("transfer", 0)) != 0 or int(fallback.get("cash", 0)) != 0 or int(fallback.get("business", {}).get("amount", 0)) != 0:
				errors.append(id + ": each chapter needs a free deadline choice.")
		if errors.is_empty():
			var visited: Dictionary = {}
			if not _acyclic(story.nodes, str(story.start), {}, visited):
				errors.append(id + ": chapter cycle would replay an already resolved choice.")
			if story.has("death_node"):
				var death_node := str(story.death_node)
				if not story.nodes.has(death_node) or not _acyclic(story.nodes, death_node, {}, visited):
					errors.append(id + ": invalid bereavement chapter.")
			if visited.size() != story.nodes.size():
				errors.append(id + ": a chapter cannot be reached from the start.")
	return errors

static func _acyclic(nodes: Dictionary, id: String, path: Dictionary, visited: Dictionary) -> bool:
	if path.has(id):
		return false
	if visited.has(id):
		return true
	path[id] = true
	for choice in nodes[id].choices:
		for next in _destinations(choice):
			if not _acyclic(nodes, next, path, visited):
				return false
	path.erase(id)
	visited[id] = true
	return true

static func _destinations(choice: Dictionary) -> Array:
	var out: Array = []
	for key in ["next", "next_untrusted"]:
		if str(choice.get(key, "")) != "":
			out.append(str(choice[key]))
	return out

func _state() -> Dictionary:
	if not gs.scenario_state.get(STATE_KEY) is Dictionary:
		gs.scenario_state[STATE_KEY] = {"version": STATE_VERSION, "actors": {}}
	return gs.scenario_state[STATE_KEY]

func _actor_state(actor_id: int) -> Dictionary:
	var state: Dictionary = _state()
	var key := str(actor_id)
	if not state.actors.has(key):
		state.actors[key] = {"stories": {}, "last_start_year": -2000000000}
	return state.actors[key]

func _person(id: int) -> Person:
	if gs.player != null and int(gs.player.id) == id:
		return gs.player
	# Story casting uses indexed, resident people, never a population-wide scan.
	return gs.get_npc_by_id(id, false)

func _definition(id: String) -> Dictionary:
	for story in catalog:
		if str(story.id) == id:
			return story
	return {}

func service_year() -> Dictionary:
	if gs == null or gs.player == null or not gs.player.alive or not content_errors.is_empty():
		return {"success": false, "reason": "story_runtime_unavailable"}
	var actor: Person = gs.player
	var state: Dictionary = _state()
	if int(state.get("version", 0)) != STATE_VERSION:
		return {"success": false, "reason": "unsupported_story_save_version"}
	if gs.scenario_state.has("family_businesses"):
		businesses().service_actor(actor)
	var profile: Dictionary = _actor_state(actor.id)
	var active := 0
	var surfaced := 0
	for id in profile.stories.keys():
		var instance: Dictionary = profile.stories[id]
		if str(instance.status) == "finished":
			continue
		var definition: Dictionary = _definition(str(id))
		if definition.is_empty():
			continue # Keep unknown content in saves for a later compatible pack.
		var cast: Person = _person(int(instance.cast_id))
		if cast == null:
			active += 1 # A temporarily unloaded participant must not be replaced.
			continue
		var absent := false
		var lost_name := "" if cast.alive else str(instance.cast_name)
		for participant in instance.get("ensemble", {}).values():
			var person := _person(int(participant.id))
			if person == null:
				absent = true
			elif not person.alive:
				lost_name = str(participant.name)
		if absent:
			active += 1
			continue
		if lost_name != "" and not bool(definition.get("allow_deceased_cast", false)):
			if definition.has("death_node"):
				if not instance.has("lost_person"):
					gs.scenario_runtime_contract_engine.active_popup_contracts.erase(_contract_id(instance))
					gs.scenario_runtime_contract_engine._commit_state()
					instance.lost_person = lost_name
					instance.node = str(definition.death_node)
					instance.status = "waiting"
					instance.due_year = int(gs.year)
			else:
				_interrupt(actor, instance)
				continue
		active += 1
		if int(gs.year) < int(instance.due_year):
			continue
		var contract_id := _contract_id(instance)
		if str(instance.status) == "pending" and int(gs.year) > int(instance.deadline_year):
			# Restore the contract first if a compact checkpoint omitted projections.
			_surface(actor, definition, instance)
			var node: Dictionary = definition.nodes[instance.node]
			gs.scenario_runtime_contract_engine.resolve_popup_contract(contract_id, str(node.default), {
				"viewer_actor_id": actor.id, "life_story_automatic": true
			})
			continue
		if _surface(actor, definition, instance):
			surfaced += 1
	if active < MAX_ACTIVE_STORIES and int(gs.year) - int(profile.last_start_year) >= START_COOLDOWN_YEARS:
		for definition in catalog:
			if profile.stories.has(definition.id) or not _eligible(actor, definition):
				continue
			var casting: Dictionary = _cast(actor, definition)
			if casting.is_empty():
				continue
			var cast: Person = casting.person
			var instance: Dictionary = {
				"story_id": definition.id, "actor_id": actor.id,
				"cast_id": cast.id, "cast_name": _name(cast),
				"node": definition.start, "status": "waiting", "due_year": int(gs.year),
				"started_year": int(gs.year), "history": [], "legacy": "unfinished",
				"origin": casting.get("origin", ""), "origin_legacy": casting.get("legacy", ""),
				"scale": float(casting.get("scale", _era_scale())),
				"ensemble": casting.get("ensemble", {})
			}
			if casting.has("venture_id"):
				instance.venture_id = casting.venture_id
			profile.stories[definition.id] = instance
			profile.last_start_year = int(gs.year)
			if _surface(actor, definition, instance):
				surfaced += 1
			break
	return {"success": true, "surfaced": surfaced}

func _eligible(actor: Person, definition: Dictionary) -> bool:
	var gate: Dictionary = definition.get("eligibility", {})
	if actor.age < int(gate.get("min_age", 8)) or actor.age > int(gate.get("max_age", 150)):
		return false
	if bool(gate.get("employed", false)) and actor.job.strip_edges() == "":
		return false
	if bool(gate.get("crime_history", false)):
		if gs.crime_world_engine == null:
			return false
		var profile: Dictionary = gs.crime_world_engine.get_actor_profile(actor)
		if int(profile.get("successful_jobs", 0)) < 1:
			return false
	return true

func _cast(actor: Person, definition: Dictionary) -> Dictionary:
	var role: String = str(definition.cast)
	if role in ["business_partners", "business_heir"]:
		return _business_cast(actor, role)
	var candidates: Array = []
	match role:
		"friend": candidates = actor.friends.duplicate()
		"mentor": candidates = actor.coworkers.duplicate()
		"parent", "relative":
			candidates = actor.parents.duplicate()
			if role == "relative":
				for parent_id in actor.parents:
					var parent: Person = _person(int(parent_id))
					if parent != null:
						candidates.append_array(parent.children)
		"accomplice":
			var profile: Dictionary = gs.crime_world_engine.get_actor_profile(actor)
			var organization_id: String = str(profile.get("organization_id", profile.get("connected_organization_id", "")))
			for organization in gs.crime_world_engine.get_organizations_for_actor(actor):
				if str(organization.get("id", "")) == organization_id:
					candidates.append_array(organization.get("members", {}).keys())
		"legacy":
			for parent_id in actor.parents:
				var parent_stories: Dictionary = _state().actors.get(str(int(parent_id)), {}).get("stories", {})
				for record in parent_stories.values():
					if str(record.get("legacy", "unfinished")) in ["unfinished", "private"]:
						continue
					var person: Person = _person(int(record.cast_id))
					if person != null and person.alive and person.id != actor.id:
						return {"person": person, "origin": str(record.story_id), "legacy": str(record.legacy)}
	candidates.sort_custom(func(a, b): return int(a) < int(b))
	for candidate in candidates.slice(0, 32):
		var person: Person = _person(int(candidate))
		if person == null or not person.alive or person.id == actor.id:
			continue
		if role == "friend" and abs(person.age - actor.age) > 5:
			continue
		if role in ["relative", "mentor", "accomplice"] and person.age < 18:
			continue
		if role == "parent" and person.age < 55:
			continue
		if role == "mentor" and (person.job == "" or person.age < actor.age + 5):
			continue
		if role == "relative" and float(person.bank_balance) < 600.0 * _era_scale():
			continue
		return {"person": person}
	return {}

func _business_cast(actor: Person, role: String) -> Dictionary:
	var owned: Array = businesses().ventures_for(actor.id)
	if role == "business_heir":
		for venture in owned:
			if not venture.inherited_from.has(str(actor.id)) or int(venture.manager_id) != actor.id:
				continue
			var partner := _person(int(venture.cofounder_id))
			if partner != null:
				return {"person": partner, "ensemble": venture.cast.duplicate(true), "venture_id": venture.id, "scale": venture.scale}
		return {}
	if not owned.is_empty():
		return {}
	var candidates: Array = actor.friends.duplicate()
	for parent_id in actor.parents:
		var parent := _person(int(parent_id))
		if parent != null:
			candidates.append_array(parent.children)
	candidates.sort_custom(func(a, b): return int(a) < int(b))
	var mentors: Array = actor.coworkers.duplicate()
	mentors.append_array(actor.parents)
	mentors.sort_custom(func(a, b): return int(a) < int(b))
	for id in candidates.slice(0, 32):
		var partner := _person(int(id))
		if partner == null or not partner.alive or partner.age < 18 or partner.id == actor.id:
			continue
		for mentor_id in mentors.slice(0, 32):
			var mentor := _person(int(mentor_id))
			if mentor == null or not mentor.alive or mentor.age < actor.age + 5 or mentor.id in [actor.id, partner.id]:
				continue
			return {"person": partner, "ensemble": {"cofounder": {"id": partner.id, "name": _name(partner)},
				"mentor": {"id": mentor.id, "name": _name(mentor)}}}
	return {}

func _surface(actor: Person, definition: Dictionary, instance: Dictionary) -> bool:
	var runtime = gs.scenario_runtime_contract_engine
	var id := _contract_id(instance)
	if runtime.active_popup_contracts.has(id):
		return false
	var node: Dictionary = definition.nodes[instance.node]
	if str(instance.status) != "pending":
		instance.deadline_year = int(gs.year) + int(node.get("deadline", 2))
	var choices: Array = []
	for choice in node.choices:
		var cost: int = _amount(int(choice.get("transfer", 0)), instance)
		var label: String = _render(str(choice.label), instance)
		if cost != 0:
			label += " ($%d)" % abs(cost)
		var business: Dictionary = choice.get("business", {})
		if int(business.get("amount", 0)) > 0:
			var source := "company" if str(business.action) in ["expense", "draw"] else "your bank"
			label += "\n$%d · from %s" % [_amount(int(business.amount), instance), source]
		choices.append({"id": choice.id, "label": label, "source_resolves": true,
			"priority": 0 if str(choice.id) == str(node.default) else 50})
	var details: String = _render(str(node.text), instance)
	var context: String = str(definition.get("era_context", {}).get(str(gs.era.get("name", "Modern Era")), ""))
	if context != "":
		details += "\n\n" + context
	if instance.has("venture_id"):
		var venture: Dictionary = gs.scenario_state.get("family_businesses", {}).get("ventures", {}).get(str(instance.venture_id), {})
		if not venture.is_empty():
			details += "\n\n" + businesses().describe(venture, actor.id)
	if not instance.get("ensemble", {}).is_empty():
		details += "\n\nRecurring cast: " + ", ".join(instance.ensemble.values().map(func(row): return str(row.name)))
	if not instance.history.is_empty():
		var previous: Dictionary = instance.history.back()
		details += "\n\nPreviously, in %d: %s" % [int(previous.year), str(previous.text)]
	if str(instance.origin) != "":
		details += "\n\nYour family's story: %s (%s)." % [str(instance.origin).replace("_", " ").capitalize(), str(instance.origin_legacy).replace("_", " ")]
	# A pending contract may remain open across years. Use its absolute deadline
	# so the saved projection never shows a stale relative countdown.
	details += "\n\nYou can respond through year %d. If you leave this unanswered: %s." % [int(instance.deadline_year), _choice_label(node, str(node.default))]
	var report: Dictionary = gs.scenario_popup_contract_engine.emit_popup_contract({
		"id": id, "target_id": actor.id, "issuer_id": instance.cast_id,
		"participant_ids": _participant_ids(actor, instance), "decision_actor_ids": [actor.id],
		"audience_ids": [actor.id], "request": "life_story", "category": definition.category,
		"title": "%s · %s — %s" % [str(definition.get("series", "Life Stories")), str(definition.title), str(node.title)],
		"overview": details, "details": details, "response_options": choices,
		"urgency": 65, "expires_age": -1, "source": "life_stories",
		"source_result": {"story_id": instance.story_id, "node_id": instance.node}
	}, {"source": "life_stories", "target_id": actor.id})
	if not bool(report.get("success", false)):
		return false
	instance.status = "pending"
	return true

func resolve_choice(contract: Dictionary, option_id: String, payload: Dictionary) -> Dictionary:
	var actor_id: int = int(contract.get("target_id", -1))
	var viewer: int = int(payload.get("viewer_actor_id", payload.get("perspective_actor_id", payload.get("target_id", actor_id))))
	if gs.player == null or int(gs.player.id) != actor_id or viewer != actor_id:
		return _failure("This chapter belongs to a different life.")
	var actor: Person = gs.player
	var source: Dictionary = contract.get("source_result", {})
	var instance: Dictionary = _actor_state(actor_id).stories.get(str(source.get("story_id", "")), {})
	if instance.is_empty() or str(instance.status) != "pending" or _contract_id(instance) != str(contract.id):
		return _failure("This chapter has already moved on.")
	var definition: Dictionary = _definition(str(instance.story_id))
	var node: Dictionary = definition.get("nodes", {}).get(str(instance.node), {})
	var choice: Dictionary = {}
	for row in node.get("choices", []):
		if str(row.id) == option_id:
			choice = row
	if choice.is_empty():
		return _failure("That response is not available in this chapter.")
	var cast: Person = _person(int(instance.cast_id))
	if cast == null or (not cast.alive and not instance.has("lost_person") and not bool(definition.get("allow_deceased_cast", false))) or not actor.alive:
		return _failure("A participant is unavailable. Advance the year to settle this story.")
	if int(gs.year) > int(instance.deadline_year) and option_id != str(node.default):
		return _failure("Time has passed for this choice. Advance the year to see the outcome.")
	for participant in instance.get("ensemble", {}).values():
		var person := _person(int(participant.id))
		if person == null or (not person.alive and not instance.has("lost_person") and not bool(definition.get("allow_deceased_cast", false))):
			return _failure("A participant is unavailable. Advance the year to settle this story.")
	var previous_balance: int = int(actor.bank_balance)
	var previous_relationship: int = int(actor.affection.get(cast.id, 50))
	var effects: Array = []
	var transfer_amount: int = _amount(int(choice.get("transfer", 0)), instance)
	var bank_report: Dictionary = businesses().apply(actor, instance, choice.business) if choice.has("business") else _transfer(actor, cast, transfer_amount)
	if not bool(bank_report.get("success", false)):
		return _failure(str(bank_report.get("reason", "This payment is not affordable.")))
	if transfer_amount != 0:
		bank_report.merge({"actor_id": actor.id, "bank_delta": int(actor.bank_balance) - previous_balance,
			"previous_balance": previous_balance, "new_balance": int(actor.bank_balance)}, true)
		effects.append("Money: %s$%d" % ["+" if transfer_amount > 0 else "-", abs(transfer_amount)])
	if choice.has("business"):
		bank_report.merge({"actor_id": actor.id, "bank_delta": int(actor.bank_balance) - previous_balance,
			"previous_balance": previous_balance, "new_balance": int(actor.bank_balance)}, true)
		effects.append("Your bank balance: $%d (%+d)." % [int(actor.bank_balance), int(actor.bank_balance) - previous_balance])
		if bank_report.has("business_balance"):
			effects.append("Business reserves: $%d." % int(bank_report.business_balance))
	for relation in choice.get("relationships", []):
		var from := _role_person(actor, instance, str(relation.get("from", "player")))
		var to := _role_person(actor, instance, str(relation.to))
		if from != null and to != null and from.alive and to.alive and from != to:
			if gs.relationship_engine != null:
				gs.relationship_engine.adjust_relationship(from, to, int(relation.delta))
			effects.append("%s and %s: %+d relationship." % [_name(from), _name(to), int(relation.delta)])
	var relationship_delta: int = int(choice.get("relationship", 0))
	if relationship_delta != 0:
		if gs.relationship_engine != null:
			gs.relationship_engine.adjust_relationship(actor, cast, relationship_delta)
		else:
			actor.affection[cast.id] = clampi(int(actor.affection.get(cast.id, 50)) + relationship_delta, 0, 100)
			cast.affection[actor.id] = clampi(int(cast.affection.get(actor.id, 50)) + relationship_delta, 0, 100)
		effects.append("Relationship with %s: %+d" % [str(instance.cast_name), int(actor.affection.get(cast.id, 50)) - previous_relationship])
	for stat in choice.get("stats", {}):
		var before: float = float(actor.get(str(stat)))
		actor.set(str(stat), clampf(before + float(choice.stats[stat]), 0, 100))
		effects.append("%s: %+d" % [str(stat).replace("_", " ").capitalize(), int(float(actor.get(str(stat))) - before)])
	var text: String = _render(str(choice.result), instance)
	var automatic: bool = bool(payload.get("life_story_automatic", false))
	if automatic:
		text = "I let the moment pass. " + text
	instance.history.append({"year": int(gs.year), "node": instance.node, "choice": option_id, "text": text, "automatic": automatic})
	instance.legacy = str(choice.get("legacy", instance.legacy))
	var next: String = str(choice.get("next", ""))
	if choice.has("next_untrusted") and int(actor.affection.get(int(instance.cast_id), 50)) < 45:
		next = str(choice.next_untrusted)
	if next == "":
		instance.status = "finished"
		instance.outcome = str(choice.get("outcome", "A chapter closed"))
		instance.finished_year = int(gs.year)
	else:
		instance.node = next
		instance.status = "waiting"
		instance.due_year = int(gs.year) + int(choice.get("delay", 1))
	_record(actor, instance, text)
	var footer: String = "Story complete: %s." % str(instance.outcome) if next == "" else "This story will return in a later year."
	var consequences: String = "\n\n" + "\n".join(effects) if not effects.is_empty() else ""
	return {"success": true, "text": text, "popup_title": str(definition.title),
		"popup_text": text + consequences + "\n\n" + footer, "bank_report": bank_report,
		"diary_already_committed": gs.life_diary_contract_engine != null,
		"story_id": instance.story_id, "story_status": instance.status}

func _transfer(actor: Person, cast: Person, amount: int) -> Dictionary:
	if amount == 0:
		return {"success": true}
	var payer: Person = cast if amount > 0 else actor
	var recipient: Person = actor if amount > 0 else cast
	if gs.bank_engine != null:
		gs.bank_engine.ensure_bank_account_for_actor(payer, {"import_legacy_balance": true})
		gs.bank_engine.ensure_bank_account_for_actor(recipient, {"import_legacy_balance": true})
		return gs.bank_engine.request_actor_bank_action(payer, {
			"action": "transfer", "amount": abs(amount),
			"target_owner_id": gs.bank_engine.owner_key_from_actor(recipient),
			"text": "A Life Stories promise changed hands."
		}, {"source": "life_stories"})
	if float(payer.bank_balance) < abs(amount):
		return {"success": false, "reason": "%s cannot afford this payment. Choose another response." % _name(payer)}
	payer.bank_balance -= abs(amount)
	recipient.bank_balance += abs(amount)
	return {"success": true, "amount": abs(amount)}

func _record(actor: Person, instance: Dictionary, text: String) -> void:
	if gs.memory_engine != null:
		gs.memory_engine.remember_packet(actor.id, {"text": text, "event_name": "life_story_choice",
			"story_id": instance.story_id, "target_id": instance.cast_id, "source": "life_stories"})
	else:
		actor.memories.append(text)
	# Commit narrative history even when a deadline is serviced without an open UI.
	if gs.life_diary_contract_engine != null:
		gs.life_diary_contract_engine.enqueue_intent({"type": "legacy_entry", "actor_id": actor.id,
			"year": int(gs.year), "age": actor.age, "lines": [text], "preserve_lines_exactly": true},
			{"source": "life_stories"})

func _interrupt(actor: Person, instance: Dictionary) -> void:
	var id := _contract_id(instance)
	gs.scenario_runtime_contract_engine.active_popup_contracts.erase(id)
	gs.scenario_runtime_contract_engine._commit_state()
	instance.status = "finished"
	instance.outcome = "An unfinished conversation"
	instance.finished_year = int(gs.year)
	_record(actor, instance, "%s died before our story was finished. I remember what passed between us." % str(instance.cast_name))

func _contract_id(instance: Dictionary) -> String:
	return "life_story:%d:%s:%s" % [int(instance.actor_id), str(instance.story_id), str(instance.node)]

func _render(text: String, instance: Dictionary) -> String:
	var out := text.replace("{person}", str(instance.cast_name))
	for role in instance.get("ensemble", {}):
		out = out.replace("{" + str(role) + "}", str(instance.ensemble[role].name))
	out = out.replace("{lost_person}", str(instance.get("lost_person", "Someone close to us")))
	if instance.has("venture_id"):
		var venture: Dictionary = gs.scenario_state.get("family_businesses", {}).get("ventures", {}).get(str(instance.venture_id), {})
		out = out.replace("{business}", str(venture.get("name", "the family business")))
		out = out.replace("{legacy}", str(venture.get("legacy", "new partnership")).replace("_", " "))
	return out

func _role_person(actor: Person, instance: Dictionary, role: String) -> Person:
	return actor if role == "player" else _person(int(instance.get("ensemble", {}).get(role, {}).get("id", -1)))

func _participant_ids(actor: Person, instance: Dictionary) -> Array:
	var ids: Array = [actor.id]
	for raw_id in [int(instance.cast_id)] + instance.get("ensemble", {}).values().map(func(row): return int(row.id)):
		if raw_id not in ids:
			ids.append(raw_id)
	return ids

func _name(person: Person) -> String:
	return (person.first_name + " " + person.last_name).strip_edges()

func _era_scale() -> float:
	return float({"Ancient Era": 0.2, "Medieval Era": 0.3, "Industrial Era": 0.6,
		"Modern Era": 1.0, "Future Era": 1.5}.get(str(gs.era.get("name", "Modern Era")), 1.0))

func _amount(base: int, instance: Dictionary) -> int:
	return int(round(float(base) * float(instance.scale)))

func _choice_label(node: Dictionary, id: String) -> String:
	for choice in node.choices:
		if str(choice.id) == id:
			return str(choice.label)
	return "the opportunity passes"

func _failure(reason: String) -> Dictionary:
	return {"success": false, "reason": reason, "popup_title": "Life Stories", "popup_text": reason}
