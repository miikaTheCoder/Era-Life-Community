extends "smoke_desktop_modes.gd"

# Run scripts/test-desktop-modes.sh with ERA_NATURAL_FAMILY=1 and reuse the isolated profile.
# All choices use the same controls as the desktop player.
var deceased_parent: Person

func _available(label: String, scope: Node = null) -> Button:
	if scope == null:
		scope = current_scene
	for button in scope.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and not button.disabled and not button.is_queued_for_deletion() and button.text.strip_edges() == label:
			return button
	return null

func _press(label: String, scope: Node = null) -> bool:
	if not _check(await _wait_for(func(): return _available(label, scope) != null, 6), "Missing visible button: " + label):
		var visible := current_scene.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and not b.disabled)
		print("FAMILY OPTIONS ", visible.map(func(b): return b.text))
		return false
	print("FAMILY CHOICE ", label)
	if not await _click(_available(label, scope)):
		return false
	await create_timer(0.5).timeout
	return true

func _dismiss_result() -> void:
	var card: Control = current_scene.get("action_result_popup_card")
	for response in range(4):
		if not is_instance_valid(card) or not card.is_visible_in_tree():
			return
		print("FAMILY RESULT ", current_scene.get("action_result_popup_title").text, " ", current_scene.get("action_result_popup_body").get_parsed_text())
		if _available("Keep it", card) != null:
			await _press("Keep it", card)
		elif _available("Stay", card) != null:
			await _press("Stay", card)
		else:
			await _click_at(card.get_global_rect().get_center())
		await create_timer(0.4).timeout

func _return_to_life() -> void:
	await _dismiss_result()
	for label in ["Back", "×", "← RETURN TO LIFE"]:
		if _available(label) != null:
			await _press(label)
	await _click(_navigation_button("life"))

func _open_partner_profile() -> bool:
	var state: GameState = current_scene.get("gs")
	if not await _click(_navigation_button("relationships")) or not await _press("PARTNER"):
		return false
	if state.get_valid_partner(state.player, true, true) == null:
		return await _press("Meet a man" if state.player.gender == "Female" else "Meet a woman")
	return await _press("Open full relationship profile")

func _advance_one_year() -> bool:
	if failed or not await super._advance_one_year():
		return false
	var naming: Control = current_scene.get("player_line_birth_naming_popup")
	if not is_instance_valid(naming) or not naming.is_visible_in_tree():
		return true
	var state: GameState = current_scene.get("gs")
	var parent := state.player
	var previous_children := parent.children.duplicate()
	var chosen_name := "Robin" if previous_children.is_empty() else "Rowan"
	var field: LineEdit = current_scene.get("player_line_birth_first_name_input")
	if not await _click(field):
		return false
	for character in chosen_name:
		for down in [true, false]:
			var event := InputEventKey.new()
			event.keycode = character.to_upper().unicode_at(0)
			event.unicode = character.unicode_at(0)
			event.pressed = down
			Input.parse_input_event(event)
			await process_frame
	if not _check(field.text == chosen_name, "Baby name input did not retain the typed name"):
		return false
	await _capture("name-" + chosen_name)
	if not await _press("Okay", naming):
		return false
	if not _check(await _wait_for(func(): return parent.children.size() > previous_children.size(), 8), "Confirming the name did not register a child"):
		return false
	for id in parent.children:
		if id not in previous_children:
			var child := state.get_npc_by_id(int(id))
			if not _check(child != null and child.first_name == chosen_name and parent.id in child.parents, "Newborn identity or family link is incomplete"):
				return false
			print("FAMILY BIRTH ", child.id, " ", child.first_name, " ", child.last_name, " parents=", child.parents, " year=", state.year)
	await _return_to_life()
	await _save_and_resume()
	return not failed

func _save_and_resume() -> void:
	await _save([])
	if failed:
		return
	if _available("← Back") != null:
		await _press("← Back")
	await _click(_navigation_button("life"))

func _r17_pending() -> void:
	var state: GameState = current_scene.get("gs")
	var actor := state.player
	var planning_family := actor.children.is_empty() or (actor.children.size() == 1 and actor.age >= 32)
	if actor.age < 18 or actor.age > 40 or not planning_family or actor.pregnancy_progress >= 0:
		return
	if not await _open_partner_profile():
		return
	var partner := state.get_valid_partner(actor, true, true)
	if partner == null:
		if not await _press("Ask Out"):
			return
		await _dismiss_result()
		partner = state.get_valid_partner(actor, true, true)
		if partner != null:
			_check(partner.partner == actor, "Dating did not establish a reciprocal partnership")
			print("FAMILY DATING ", actor.id, " with ", partner.id, " ", partner.first_name, " ", partner.last_name)
			await _capture("dating-%d" % actor.age)
		await _return_to_life()
		if partner == null:
			return
		# Preserve the ordinary relationship choice before attempting its next action.
		await _save_and_resume()
		if failed or not await _open_partner_profile():
			return
	if actor.gender == "Male" and partner.pregnancy_progress >= 0:
		await _return_to_life()
		return
	if await _press("Try for Baby"):
		await _capture("family-planning-%d" % actor.age)
		await _dismiss_result()
		print("FAMILY PLANNING age=", actor.age, " pregnancy=", maxi(actor.pregnancy_progress, partner.pregnancy_progress))
	await _return_to_life()

func _r17_work() -> void:
	if failed:
		return
	if not await _click(_navigation_button("career")):
		return
	if await _press("OCCUPATIONS"):
		for category in ["PART-TIME", "FULL-TIME"]:
			if not await _press(category):
				break
			if _available("APPLY") != null:
				await _press("APPLY")
				await _dismiss_result()
				break
			print("FAMILY WORK no application available in ", category)
	await _capture("work-%d" % current_scene.get("gs").player.age)
	await _return_to_life()

func _r17_visit_family() -> void:
	if deceased_parent == null:
		return
	var successor: Person = current_scene.get("gs").player
	var estate: Dictionary = deceased_parent.person_contract.get("family", {}).get("estate", {}).get("execution", {})
	if not _check(estate.get("executed", false) and int(estate.get("heir_id", -1)) == successor.id, "The selected child did not receive an executed estate"):
		return
	print("FAMILY ESTATE RECEIPT heir=", successor.id, " balances=", estate.get("inherited_balances", {}), " cash=", successor.bank_balance)
	await _save_and_resume()
	if failed or not await _open_partner_profile():
		return
	var state: GameState = current_scene.get("gs")
	var label := "Converse" if state.get_valid_partner(state.player, true, true) != null else "Ask Out"
	if await _press(label):
		var card: Control = current_scene.get("action_result_popup_card")
		if not _check(await _wait_for(func(): return is_instance_valid(card) and card.is_visible_in_tree(), 6), "The heir choice produced no visible result"):
			return
		await _capture("heir-choice")
		await _dismiss_result()
		print("FAMILY HEIR CHOICE ", state.player.first_name, " ", label)
	await _return_to_life()

func _r17_afterlife() -> void:
	var state: GameState = current_scene.get("gs")
	var founder := state.player
	deceased_parent = founder
	print("FAMILY ESTATE founder=", founder.id, " cash=", founder.bank_balance, " children=", founder.children)
	await super._r17_afterlife()
	_check(state.player != founder and state.player.parents.has(founder.id), "Natural death did not lead to a playable child")

func _verify_shared_checkpoint(payload: Dictionary, state: GameState) -> void:
	super._verify_shared_checkpoint(payload, state)
	var saved_people: Dictionary = {}
	for row in payload.npcs:
		saved_people[int(row.id)] = row
	var actor: Dictionary = saved_people[state.player_id]
	var partner_id := int(actor.get("partner_id", -1))
	if saved_people.get(partner_id, {}).get("alive", false):
		var partner := state.get_valid_partner(state.player, true, true)
		_check(partner != null and partner.id == partner_id, "Cold Continue lost the saved reciprocal partnership")
	for child_id in state.player.children:
		var child: Person = state.get_npc_by_id(int(child_id), false)
		var parent_ids: Array = child.parents if child != null else state.get_dormant_npc_snapshot(int(child_id)).get("parents", [])
		_check(state.player_id in parent_ids, "Cold Continue broke the child's parent link")
	var family_owner_ids := [state.bank_engine.owner_key_from_actor(state.player)]
	for parent_id in state.player.parents:
		var parent: Person = state.get_npc_by_id(int(parent_id), false)
		if parent == null:
			continue
		family_owner_ids.append(state.bank_engine.owner_key_from_actor(parent))
		var receipt: Dictionary = saved_people.get(int(parent_id), {}).get("person_contract", {}).get("family", {}).get("estate", {}).get("execution", {})
		if receipt.get("executed", false) and int(receipt.get("heir_id", -1)) == state.player_id:
			var restored: Dictionary = parent.person_contract.get("family", {}).get("estate", {}).get("execution", {})
			_check(int(restored.get("heir_id", -1)) == state.player_id and restored.get("inherited_balances") == receipt.get("inherited_balances"), "Cold Continue changed an executed parental estate")
			print("FAMILY RESTORED ESTATE ", parent.id, " to ", state.player_id, " balances=", restored.get("inherited_balances"))
	var saved_accounts: Dictionary = payload.get("bank_engine_state", {}).get("accounts", {})
	for account_id in saved_accounts:
		var account: Dictionary = saved_accounts[account_id]
		if account.get("owner_id") in family_owner_ids:
			var restored: Dictionary = state.bank_engine.accounts.get(account_id, {})
			_check(restored.get("balance") == account.get("balance") and restored.get("currency") == account.get("currency"), "Cold Continue changed family bank account " + str(account_id))
	print("FAMILY RESTORED actor=", state.player_id, " partner=", partner_id, " parents=", state.player.parents, " children=", state.player.children, " balance=", state.player.bank_balance)
