extends SceneTree

var failed := false
var state := GameState.new()
var hub := RelationshipsHubContractEngine.new(state)

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _local(id: int, gender: String, age: int) -> Person:
	var person := Person.new()
	person.id = id
	person.age = age
	person.gender = gender
	person.home_city = "Riga"
	person.home_country = "Latvia"
	state.register_npc(person)
	return person

func _run() -> void:
	var actor := _local(1, "Female", 18)
	state.player = actor
	state.player_id = actor.id
	state.romance_contract_engine = RomanceContractEngine.new(state)
	state.relationship_activities_engine = RelationshipActivitiesEngine.new(state)
	state.relationships_hub_contract_engine = hub
	var sibling := _local(2, "Male", 20)
	sibling.parents = [40]
	actor.parents = [40]
	_local(3, "Male", 17)
	var taken := _local(4, "Male", 19)
	taken.marital_status = "married"
	state.next_id = 5
	var original_size := state.npcs.size()
	var streamed := hub._resident_relationship_group_quantum(actor, "partner", 0, {})
	var full := hub._hub_group_contracts(actor, "partner", {})
	var actions: Array = streamed.get("actions", [])
	_check(actions.size() == 2 and full[0] == streamed, "Single adults need introductions through both Partner tab builders.")
	_check(state.npcs.size() == original_size, "Opening the Partner tab created an NPC.")
	if actions.size() != 2:
		quit(1)
		return
	var row: Dictionary = actions[0]
	var result := hub.resolve_intent(actor, row)
	var person := state.get_npc_by_id(int(result.get("target_id", -1)), false)
	var profile: Dictionary = result.get("profile_contract", {})
	_check(person != null and profile.get("target_id") == person.id, "Introduction did not return the registered person's profile.")
	if person == null:
		quit(1)
		return
	_check(state.npcs.size() == original_size + 1 and person.id == 5 and person.age >= 18, "A relative, minor, or married resident was offered.")
	_check(person.home_city == actor.home_city and person.gender == row.gender, "Newly introduced person did not match the local introduction.")
	_check(actor.partner == null and person.partner == null and state.relationship_activities_engine.can_ask_out(actor, person), "An introduction must leave the proposal up to the people involved.")
	# Legacy locations can contain a birthplace only, or no location at all.
	person.birth_city = person.home_city
	person.home_city = ""
	actor.birth_country = ""
	actor.home_country = ""
	var again := hub.resolve_intent(actor, row)
	_check(again.get("target_id") == person.id and state.npcs.size() == original_size + 1, "Opening a profile again generated an unnecessary second resident.")
	actor.partner = person
	person.partner = actor
	_check(not hub.resolve_intent(actor, row).get("success", true), "A stale button overwrote an existing partner.")
	_check(not hub._resident_relationship_group_quantum(actor, "partner", 0, {}).has("actions"), "Partnered actor still sees introductions.")
	person.partner = null
	actor.partner = null
	actor.age = 17
	_check(not hub.resolve_intent(actor, row).get("success", true) and not hub._hub_group_contracts(actor, "partner", {})[0].has("actions"), "Minors received the adult introduction.")
	actor.age = 18
	state.player = sibling
	_check(not hub.resolve_intent(actor, row).get("success", true) and state.npcs.size() == original_size + 1, "An old actor's button created a new introduction after a switch.")
	if not failed:
		print("LOCAL INTRODUCTION TESTS: PASS")
	quit(1 if failed else 0)
