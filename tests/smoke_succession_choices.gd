extends "smoke_desktop_modes.gd"

# The base smoke enters a real Household. Only the family/contact fixture and
# death are seeded. Every choice after death goes through the on-screen button.
const LIFE_CHOICES := "Back to life choices"
const RECONSIDER := "Choose someone else"
const KIN := "Continue Lineage"
const KNOWN := "Continue as someone you know"

func _buttons(death_menu := false) -> Array[Button]:
	var container: Control = current_scene.get("death_transition_buttons" if death_menu else "afterlife_overlay_buttons")
	var found: Array[Button] = []
	if is_instance_valid(container):
		for node in container.find_children("*", "Button", true, false):
			if node.is_visible_in_tree() and not node.is_queued_for_deletion() and not node.disabled:
				found.append(node)
	return found

func _button(label: String, death_menu := false) -> Button:
	for button in _buttons(death_menu):
		if button.text == label:
			return button
	return null

func _press(label: String, death_menu := false) -> bool:
	if not _check(await _wait_for(func(): return _button(label, death_menu) != null, 4), "Missing visible choice: " + label):
		print("SUCCESSION OPTIONS ", _buttons(death_menu).map(func(b): return b.text))
		return false
	print("SUCCESSION PRESS ", label)
	return await _click(_button(label, death_menu))

# Deliver two mouse clicks in one idle turn, before the deferred action service
# has replaced the original death menu. Only the first may affect its successor.
func _press_overlapping_choices(first: String, second: String) -> bool:
	var revision: int = current_scene.get("afterlife_prompt_revision")
	for label in [first, second]:
		var button := _button(label, true)
		if not _check(button != null, "Missing death choice during rapid input: " + label):
			return false
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
	var queued: Array = current_scene.get("afterlife_action_queue")
	if not _check(queued.size() == 2 and queued[0].action_label == first and queued[1].action_label == second, "Both original menu clicks must reach the action queue"):
		return false
	if not _check(await _wait_for(func(): return current_scene.get("afterlife_action_queue").is_empty(), 5), "Rapid choices stayed queued"):
		return false
	return _check(current_scene.get("afterlife_prompt_revision") == revision + 1, "An old queued choice replaced the new prompt")

func _mode_is(state: GameState, expected: String) -> bool:
	return _check(await _wait_for(func(): return state.afterlife_state.get("pending_mode", "") == expected, 6), "Expected " + expected + ", got " + str(state.afterlife_state.get("pending_mode")))

func _scroll_with_wheel(last: Button) -> bool:
	var scroll := last.get_parent()
	while scroll != null and not scroll is ScrollContainer:
		scroll = scroll.get_parent()
	if not _check(scroll is ScrollContainer, "Long list has no scroll container"):
		return false
	var list := scroll as ScrollContainer
	var start := list.scroll_vertical
	if not _check(start == 0, "The list opened partway down and clipped its introduction"):
		return false
	var point := root.get_final_transform() * list.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for step in range(40):
		if list.get_global_rect().encloses(last.get_global_rect()):
			break
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.position = point
			event.pressed = pressed
			Input.parse_input_event(event)
		await process_frame
	return _check(list.scroll_vertical > start and list.get_global_rect().encloses(last.get_global_rect()), "Wheel did not reveal the last choice")

func _age_and_save() -> void:
	var state: GameState = current_scene.get("gs")
	var founder := state.player
	var contacts := OS.get_environment("ERA_SUCCESSION_ROUTE") == "contacts"
	var candidate: Person
	for person in state.npcs:
		if person.first_name == ("Cora" if contacts else "Bea") and person.last_name == "Desktop":
			candidate = person
	if not _check(candidate != null, "Household fixture member is missing"):
		return
	founder.friends.clear()
	if contacts:
		founder.children.clear()
		for person in state.npcs:
			person.parents.erase(founder.id)
		founder.friends.append(candidate.id)
		if not candidate.friends.has(founder.id):
			candidate.friends.append(founder.id)
	else:
		# Include a namesake and enough candidates to exceed the desktop list.
		for index in range(20):
			var child := Person.new()
			child.id = state.next_id
			state.next_id += 1
			child.first_name = candidate.first_name if index == 0 else "Alex %02d" % index
			child.last_name = candidate.last_name
			child.gender = candidate.gender
			child.age = candidate.age
			child.job = candidate.job
			child.parents = [founder.id]
			founder.children.append(child.id)
			state.npcs.append(child)
		state._rebuild_npc_index()
	var original_money: float = founder.bank_balance
	var candidate_money: float = candidate.bank_balance
	founder.cause_of_death = "Old age"
	founder.alive = false
	founder.health = 0.0
	if not _check(current_scene.call("_try_surface_controlled_death_after_age_up", "succession_smoke"), "Death did not surface"):
		return
	await _capture("death-menu")
	var route := KNOWN if contacts else KIN
	var other := KIN if contacts else KNOWN
	var expected_mode := "continue_known_person_target" if contacts else "continue_lineage_target"
	if not await _press(route, true) or not await _mode_is(state, expected_mode):
		return
	var focused := root.gui_get_focus_owner()
	if not _check(focused is Button and focused in _buttons(), "Candidate list did not receive keyboard focus: " + str(focused)):
		return
	var original_label := ""
	var matching := 0
	var lookup: Dictionary = state.afterlife_state.pending_lookup
	for button in _buttons():
		if button.text.contains(candidate.first_name + " " + candidate.last_name):
			matching += 1
			var row: Dictionary = lookup.get(button.text, {})
			if int(row.get("descendant_id", row.get("target_id", 0))) == candidate.id:
				original_label = button.text
	await _capture("candidate-list")
	if not _check(matching == (1 if contacts else 2) and not original_label.is_empty(), "Cannot independently select the intended person by the displayed choices"):
		return
	if not contacts:
		var last := _button(LIFE_CHOICES)
		if not _check(last != null, "Long list has no return choice") or not await _scroll_with_wheel(last):
			return
		await _capture("last-choice")
	if not await _press(original_label) or not await _mode_is(state, "continue_lineage_transfer_toggle"):
		return
	if not _check(state.afterlife_state.continue_lineage_target_id == candidate.id, "The selected button pointed at the wrong person"):
		return
	await _capture("confirmation")
	if not await _press(RECONSIDER) or not await _mode_is(state, expected_mode) or not await _press(LIFE_CHOICES):
		return
	if not await _mode_is(state, "death_prompt"):
		return
	if not _check(current_scene.get("death_transition_body").get_parsed_text().contains("Old age"), "Death choices lost the original cause"):
		return
	if not await _press_overlapping_choices(other, "Custom Life"):
		return
	if not await _mode_is(state, "continue_lineage_target" if contacts else "continue_known_person_target"):
		return
	await _capture("empty-list")
	if not _check(_buttons().size() == 1 and _button(LIFE_CHOICES) != null, "Empty list did not offer a return to life choices"):
		return
	if not _check(root.gui_get_focus_owner() == _button(LIFE_CHOICES), "Empty list did not focus its only action"):
		return
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await process_frame
	if not await _mode_is(state, "death_prompt"):
		return
	if not _check(state.player_id == founder.id and state.player == founder and founder.bank_balance == original_money and candidate.bank_balance == candidate_money, "Browsing changed control or money"):
		return
	if not await _press(route, true) or not await _press(original_label) or not await _press("Continue as Them" if contacts else KIN):
		return
	if not _check(await _wait_for(func(): return state.player_id == candidate.id and state.player == candidate and not state.afterlife_active, 60), "Committed successor did not become playable"):
		return
	if not _check(candidate.bank_balance == candidate_money, "Continuing without inheritance changed the chosen person's balance"):
		return
	await _capture("new-life")
	if not contacts:
		await super._age_and_save()
		if failed:
			return
	print("SUCCESSION GRAPHICAL: PASS route=", route, " deceased=", founder.id, " successor=", candidate.id)
