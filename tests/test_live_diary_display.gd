extends SceneTree

# Use the real display owners with an isolated state and existing HUD controls.
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

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var scene := DisplayScene.new()
	var container := Control.new()
	container.name = "UIContainer"
	var output := RichTextLabel.new()
	output.name = "OutputLabel"
	output.size = Vector2(600, 400)
	container.add_child(output)
	scene.add_child(container)
	root.add_child(scene)
	var state := GameState.new()
	state.player = Person.new()
	state.player.id = 71
	state.player_id = 71
	state.player.age = 38
	state.player.bank_balance = 10000
	state.year = 2003
	state.npcs = [state.player]
	scene.gs = state
	scene.current_panel = "life"
	scene.set_meta("checkpoint_resume_life_diary_active", true)
	var saved_entries := [["2003", "Age: 38", "An earlier chapter."]]
	var resume := {"actor_id":71, "life_diary_entries":saved_entries.duplicate(true)}
	scene.set_meta("title_card_checkpoint_resume_lens_prewarm_contract", resume)
	_check(scene._render_checkpoint_resume_life_diary_packet_only(), "Continue did not use the saved diary while its engine was unavailable")
	_check(output.get_parsed_text().contains("An earlier chapter."), "First Continue frame lost the saved diary")
	var saved_diary := LifeDiaryContractEngine.new()
	saved_diary.append_legacy_entries_for_actor(71, saved_entries)
	state.life_diary_contract_engine = LifeDiaryContractEngine.new(state)
	# The resident engine arrives before its saved history is imported.
	scene._observe_resident_life_diary_engine()
	state.life_diary_contract_engine.import_state(saved_diary.export_state())
	state.year = 2004
	state.player.age = 39
	state.life_diary_contract_engine.enqueue_intent({"type":"legacy_entry", "actor_id":71, "year":2004, "age":39, "lines":["2004", "Age: 39", "I paid for help."]})
	_check(output.get_parsed_text().contains("I paid for help."), "The committed diary event did not reach the live label")
	scene.set_meta("age_up_zero_frame_visible_result", {"year":2004, "age":39, "text":"I paid for help."})
	scene._service_zero_frame_age_up_visible_observation()
	_check(output.get_parsed_text().count("Age: 39") == 1, "Age Up observation duplicated the committed year's heading")
	# Closing a pending choice and returning to Life must not restore old text.
	scene._render_life_diary_panel()
	var text := output.get_parsed_text()
	_check(text.contains("Age: 39") and text.contains("I paid for help."), "Returning to Life replaced the new year with the checkpoint")
	_check(text.count("An earlier chapter.") == 1 and text.count("I paid for help.") == 1, "The live diary duplicated or lost history")
	scene.current_panel = "world"
	output.hide()
	state.life_diary_contract_engine.enqueue_intent({"type":"legacy_entry", "actor_id":71, "year":2004, "age":39, "lines":["2004", "Age: 39", "We agreed on next year."]})
	scene.current_panel = "life"
	scene._render_life_diary_panel()
	_check(output.get_parsed_text().contains("We agreed on next year."), "A diary event committed on another tab was lost on return")
	_check(resume.life_diary_entries == saved_entries, "Rendering mutated the immutable checkpoint")

	scene.player_stats_overlay = PanelContainer.new()
	scene.add_child(scene.player_stats_overlay)
	scene.player_stats_overlay.set_meta("player_stats_bank_actor_id", 71)
	scene.player_stats_overlay.set_meta("player_stats_bank_currency_symbol", "$")
	scene.player_stats_bank_label = Label.new()
	scene.player_stats_overlay.add_child(scene.player_stats_bank_label)
	scene.player_stats_bank_target = 10000
	scene.player_stats_bank_display_value = 10000
	state.bank_engine = BankEngine.new(state)
	state.bank_engine.ensure_bank_account_for_actor(state.player, {"import_legacy_balance":true})
	var recipient := Person.new()
	recipient.id = 72
	state.npcs.append(recipient)
	state.bank_engine.ensure_bank_account_for_actor(recipient)
	var payment: Dictionary = state.bank_engine.transfer_owner_to_owner(state.bank_engine.owner_key_from_actor(state.player), state.bank_engine.owner_key_from_actor(recipient), 300)
	_check(payment.get("success", false), "Payment fixture was rejected")
	for tick in range(60):
		scene._animate_player_stats_overlay(1.0 / 60.0)
	_check(state.player.bank_balance == 9700, "Payment fixture did not debit the authoritative bank")
	_check(scene.player_stats_bank_label.text == "$9,700", "The HUD kept the checkpoint balance after payment")
	state.bank_engine.credit_bank(state.bank_engine.owner_key_from_actor(state.player), 500)
	for tick in range(60):
		scene._animate_player_stats_overlay(1.0 / 60.0)
	_check(scene.player_stats_bank_label.text == "$10,200", "The HUD did not display an incoming payment")
	scene.gs = null
	state = null
	scene.queue_free()
	await process_frame
	print("LIVE DIARY DISPLAY TESTS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
