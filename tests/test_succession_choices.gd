extends SceneTree

const BACK := "Back to life choices"
const RECONSIDER := "Choose someone else"

var failed := false
var state := GameState.new()
var afterlife := AfterlifeInfluenceEngine.new(state)
var parent := Person.new()

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _death() -> Dictionary:
	afterlife.enter_afterlife_for_player(parent, {"cause": "Old age"})
	return afterlife.get_pending_choice_result()

func _labels_for_actor(id: int) -> Array:
	var labels := []
	for label in state.afterlife_state.pending_options:
		var row: Dictionary = state.afterlife_state.pending_lookup.get(label, {})
		if int(row.get("target_id", row.get("descendant_id", -1))) == id:
			labels.append(label)
	return labels

func _test_route(known: bool, first: Person, second: Person) -> void:
	var initial := _death()
	var start := "Continue as someone you know" if known else "Continue Lineage"
	var selector_type := "afterlife_continue_known_person_target" if known else "afterlife_continue_lineage_target"
	var selected := afterlife.choose_pending_option(start)
	var labels1 := _labels_for_actor(first.id)
	var labels2 := _labels_for_actor(second.id)
	_check(selected.get("type") == selector_type, "Wrong selector for " + start)
	_check(labels1.size() == 1 and labels2.size() == 1, "Identically named candidates overwrote each other in " + start)
	_check(BACK in selected.get("opps", []), "Candidate selector has no return to the death menu")
	if labels1.size() != 1 or labels2.size() != 1:
		return
	for person in [first, second]:
		var labels := _labels_for_actor(person.id)
		if not _check_label_count(labels):
			return
		var confirmation := afterlife.choose_pending_option(labels[0])
		_check(confirmation.get("type") == "afterlife_continue_lineage_transfer_toggle", "Candidate did not open confirmation")
		_check(state.afterlife_state.continue_lineage_target_id == person.id, "Choice selected the other candidate")
		_check(str(confirmation.text).contains("record %d" % person.id), "Confirmation hid the distinction between two identical names")
		_check(confirmation.opps.has("Continue Lineage + Inheritance") != known, "Inappropriate inheritance option")
		_check(state.afterlife_state.continue_lineage_commit_intent.is_empty(), "Browsing queued a switch")
		if not confirmation.opps.has(RECONSIDER):
			_check(false, "Confirmation cannot return to candidates")
			return
		var again := afterlife.choose_pending_option(RECONSIDER)
		_check(again.get("type") == selector_type, "Reconsider opened the wrong group")
	_check(state.afterlife_state.continue_lineage_target_id == -1, "Reconsider retained a selected target")
	_check(state.player == parent and parent.bank_balance == 350, "Browsing changed control or the estate")
	var restored := afterlife.choose_pending_option(BACK)
	_check(restored == initial, "Returning did not reconstruct the original death prompt")
	_check(state.afterlife_state.death_popup_open and not state.afterlife_state.overlay_open, "Death menu flags were not restored")

func _check_label_count(labels: Array) -> bool:
	_check(labels.size() == 1, "Candidate missing after reconsidering")
	return labels.size() == 1

func _test_stale_and_old_choices(first: Person, second: Person) -> void:
	_death()
	afterlife.choose_pending_option("Continue Lineage")
	var label: String = _labels_for_actor(first.id)[0]
	afterlife.choose_pending_option(label)
	first.alive = false
	var refreshed := afterlife.choose_pending_option("Continue Lineage + Inheritance")
	_check(refreshed.get("type") == "afterlife_continue_lineage_target", "Confirmation accepted a newly deceased heir")
	_check(_labels_for_actor(first.id).is_empty() and not _labels_for_actor(second.id).is_empty(), "Refreshed candidates are stale")
	_check(state.afterlife_state.continue_lineage_commit_intent.is_empty(), "Stale confirmation queued a switch")
	first.alive = true
	_death()
	afterlife.choose_pending_option("Continue as someone you know")
	label = _labels_for_actor(first.id)[0]
	parent.friends.erase(first.id)
	refreshed = afterlife.choose_pending_option(label)
	_check(refreshed.get("type") == "afterlife_continue_known_person_target" and _labels_for_actor(first.id).is_empty(), "A former friend remained selectable")
	parent.friends.clear()
	# Round-trip a legacy empty selector as it was stored before Back existed.
	state.afterlife_state["pending_lookup"] = {}
	state.afterlife_state["pending_options"] = []
	state.afterlife_state = BinarySaveEngine.decode(BinarySaveEngine.encode(state.afterlife_state))
	refreshed = afterlife.get_pending_choice_result()
	_check(refreshed.get("opps") == [BACK], "Saved empty selector cannot recover")
	_check(afterlife.choose_pending_option(BACK).get("text", "").contains("Old age"), "Legacy selector lost the cause of death")
	afterlife.choose_pending_option("Continue Lineage")
	afterlife.choose_pending_option(_labels_for_actor(first.id)[0])
	state.afterlife_state.pending_options.erase(RECONSIDER)
	state.afterlife_state.pending_lookup.erase(RECONSIDER)
	state.afterlife_state = BinarySaveEngine.decode(BinarySaveEngine.encode(state.afterlife_state))
	refreshed = afterlife.choose_pending_option(RECONSIDER)
	_check(refreshed.get("type") == "afterlife_continue_lineage_target", "A legacy confirmation could not reconsider")
	_check(parent.bank_balance == 350 and state.player == parent, "Stale or restored selection spent the estate")

func _test_waiting_cancel(first: Person) -> void:
	# This life has a child, but their destination packet is not ready.
	_death()
	var hub: Variant = state.relationships_hub_contract_engine
	state.relationships_hub_contract_engine = null
	afterlife.choose_pending_option("Continue Lineage")
	afterlife.choose_pending_option(_labels_for_actor(first.id)[0])
	var waiting := afterlife.choose_pending_option("Continue Lineage + Inheritance")
	_check(waiting.get("type") == "afterlife_continue_lineage_commit_pending" and RECONSIDER in waiting.get("opps", []), "Waiting for an heir cannot be cancelled")
	_check(state.afterlife_state.continue_lineage_commit_intent.get("target_actor_id") == first.id, "Confirmed choice lost its target")
	_check(parent.bank_balance == 350 and state.player == parent, "Pending transfer moved the estate")
	afterlife.choose_pending_option(RECONSIDER)
	state.relationships_hub_contract_engine = hub
	afterlife._on_continue_lineage_destination_packet_published(first.id, {"target_actor_id": first.id})
	_check(state.afterlife_state.continue_lineage_commit_intent.is_empty(), "Cancelled intent survived a later publication")
	_check(afterlife.get_pending_choice_result().get("type") == "afterlife_continue_lineage_target" and state.player == parent and parent.bank_balance == 350, "A late publication committed the cancelled choice")

func _test_delayed_funeral() -> void:
	_death()
	var selector := afterlife.choose_pending_option("Continue Lineage")
	for step in range(64):
		if state.afterlife_state.has("funeral_text"):
			break
		afterlife._service_death_entry_enrichment_quantum()
	_check(not str(state.afterlife_state.get("funeral_text", "")).is_empty(), "Funeral enrichment did not run")
	_check(afterlife.get_pending_choice_result() == selector, "Late funeral enrichment replaced the current choice")
	var death_prompt := afterlife.choose_pending_option(BACK)
	_check(str(death_prompt.text).contains(state.afterlife_state.get("funeral_text", "")), "Returning lost the funeral")
	_check(death_prompt.text.contains("Old age"), "Returning lost the cause of death")

func _test_journal_name_fallbacks() -> void:
	var unnamed := Person.new()
	_check(afterlife._succession_memory_text(unnamed, "mother") == "I remember my mother.", "Unnamed relative lost the family relationship")
	_check(afterlife._succession_memory_text(unnamed, "predecessor") == "I remember the person who came before me.", "Unnamed predecessor left an incomplete sentence")
	unnamed.name = "Ren"
	_check(afterlife._succession_memory_text(unnamed, "predecessor") == "I remember Ren.", "A legacy display name was lost")
	unnamed.first_name = "Ren\nAsh"
	_check(afterlife._succession_memory_text(unnamed, "friend") == "I remember my friend, Ren Ash.", "A multi-line name split the memory")

func _run() -> void:
	parent.id = 41
	parent.first_name = "Ren"
	parent.alive = false
	parent.health = 0
	parent.bank_balance = 350
	state.player = parent
	state.player_id = parent.id
	state.npcs = [parent]
	state.relationships_hub_contract_engine = RelationshipsHubContractEngine.new(state)
	state._rebuild_npc_index()
	for action in ["Continue Lineage", "Continue as someone you know"]:
		var initial := _death()
		var empty := afterlife.choose_pending_option(action)
		_check(empty.get("opps", []) == [BACK], "Empty selector stranded the player: " + action)
		if BACK in empty.get("opps", []):
			_check(afterlife.choose_pending_option(BACK) == initial, "Empty selector lost death choices")
	var twins: Array[Person] = []
	for id in [42, 43]:
		var child := Person.new()
		child.id = id
		child.first_name = "Alex"
		child.last_name = "Vale"
		child.age = 27
		child.gender = "Female"
		child.job = "Teacher"
		child.parents = [parent.id]
		parent.children.append(id)
		parent.friends.append(id)
		child.friends = [parent.id]
		state.npcs.append(child)
		twins.append(child)
	state._rebuild_npc_index()
	_test_route(false, twins[0], twins[1])
	_test_route(true, twins[0], twins[1])
	_test_stale_and_old_choices(twins[0], twins[1])
	_test_waiting_cancel(twins[0])
	_test_delayed_funeral()
	_test_journal_name_fallbacks()
	if not failed:
		print("SUCCESSION CHOICES TESTS: PASS")
	quit(1 if failed else 0)
