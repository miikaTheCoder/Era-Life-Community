extends SceneTree
const Panels = preload("res://ui/EraMobilePanels.gd")
const Design = preload("res://ui/EraTheme.gd")
var failures: Array[String] = []

class Host extends Control:
	var controls: Dictionary = {}
	var returned := false
	var dismissed := false
	var last_back := ""
	func _get(property: StringName) -> Variant:
		return controls.get(String(property))
	func _on_standard_tab_popup_back_pressed() -> void:
		returned = true
	func _on_action_result_popup_gui_input(event: InputEvent) -> void:
		dismissed = event is InputEventKey and event.keycode == KEY_ESCAPE
	func _back_to_belongings_list_from_item_popup() -> void:
		last_back = "belongings_item_popup"
		controls[last_back].hide()
	func _back_to_belongings_list_from_artifact_target_popup() -> void:
		last_back = "belongings_item_target_popup"
		controls[last_back].hide()
	func _on_world_feed_popup_back_pressed() -> void:
		last_back = "world_feed_popup"
		controls[last_back].hide()
	func _close_title_card_account_panel() -> void:
		last_back = "title_card_account_popup"
		controls[last_back].hide()

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in range(5):
		await process_frame

func _remember(host: Host, key: String, control: Control, parent: Node) -> Control:
	host.controls[key] = control
	parent.add_child(control)
	return control

func _standard(host: Host) -> void:
	var surface := _remember(host, "standard_tab_popup", Control.new(), host)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := MarginContainer.new()
	surface.add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := _remember(host, "standard_tab_popup_card", PanelContainer.new(), outer)
	var inset := MarginContainer.new()
	card.add_child(inset)
	var stack := VBoxContainer.new()
	inset.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	var back := _remember(host, "standard_tab_popup_back_button", Button.new(), header) as Button
	back.text = "← Back"
	var title := Label.new()
	title.text = "Relationships and family"
	header.add_child(title)
	var body := _remember(host, "standard_tab_popup_body", HBoxContainer.new(), stack)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		var panel := PanelContainer.new()
		panel.custom_minimum_size.x = 360 if side == "right" else 0
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(panel)
		var scroll := _remember(host, "standard_tab_popup_" + side + "_scroll", ScrollContainer.new(), panel)
		if side == "left":
			var text := _remember(host, "standard_tab_popup_left", RichTextLabel.new(), scroll) as RichTextLabel
			text.text = "Family history and relationships. ".repeat(100)
			text.fit_content = true
			text.custom_minimum_size.y = 520
		else:
			var actions := _remember(host, "standard_tab_popup_right", VBoxContainer.new(), scroll)
			for index in range(22):
				var button := Button.new()
				button.text = "Spend time with family member %d" % index
				button.set_meta("action_id", index)
				button.disabled = index == 5
				actions.add_child(button)

func _event(host: Host) -> void:
	var surface := _remember(host, "action_result_popup", Control.new(), host)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	surface.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := _remember(host, "action_result_popup_card", PanelContainer.new(), center)
	card.custom_minimum_size = Vector2(700, 420)
	var inset := MarginContainer.new()
	card.add_child(inset)
	var stack := VBoxContainer.new()
	stack.name = "ActionResultVBox"
	inset.add_child(stack)
	var title := Label.new()
	title.text = "A difficult decision about your family's future"
	stack.add_child(title)
	var body := _remember(host, "action_result_popup_body", RichTextLabel.new(), stack) as RichTextLabel
	body.text = "Your family needs to decide what happens next. ".repeat(60)
	body.fit_content = true
	var choices := _remember(host, "action_result_popup_choices", VBoxContainer.new(), stack)
	for index in range(16):
		var button := Button.new()
		button.text = "Consider choice %d" % index
		choices.add_child(button)

func _check_readable(button: Button, context: String) -> void:
	var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	var padding := 24.0
	for state in ["normal", "hover", "pressed", "disabled"]:
		padding = maxf(padding, button.get_theme_stylebox(state).get_minimum_size().x)
	_check(button.size.x + 0.5 >= text_width + padding and button.size.x >= 44, context + " clips its label or loses touch width")
	_check(button.size.y >= 44, context + " loses touch height")

func _real_hubs(host: Host, adapter: Node) -> void:
	var tabs := [{"id": "all", "label": "All opportunities"}, {"id": "social", "label": "Friends and family"}, {"id": "work", "label": "Work and education"}]
	for property in ["activities_hub_panel", "career_hub_panel", "relationship_hub_panel", "school_hub_panel"]:
		var panel: Control
		if property == "activities_hub_panel":
			panel = ActivitiesHubPanel.new()
		elif property == "career_hub_panel":
			panel = CareerHubPanel.new()
		elif property == "relationship_hub_panel":
			panel = RelationshipHubPanel.new()
		else:
			panel = SchoolHubPanel.new()
		host.controls[property] = panel
		host.add_child(panel)
		if panel is InstitutionHubPanelBase:
			panel.prepare_surface()
			panel._render_tabs(tabs)
			panel.show_surface()
			panel.close_requested.connect(panel.hide_surface)
		else:
			panel.open_contract({"title": "Everyday life and opportunities", "subtitle": "Choose what happens next", "section_tabs": tabs})
		for dimensions in [Vector2i(420, 747), Vector2i(360, 640)]:
			root.content_scale_size = dimensions
			await _settle()
			var shell: Control = panel.shell if panel is InstitutionHubPanelBase else panel
			_check(shell.get_global_rect().position.x >= 0 and shell.get_global_rect().end.x <= dimensions.x and shell.get_global_rect().end.y <= dimensions.y, property + " exceeds portrait bounds")
			var content: Control = panel.section_surface_host if panel is InstitutionHubPanelBase else panel.content_scroll
			_check(content.size.y >= 130, property + " leaves no usable scrolling content")
			var tab_scroll: ScrollContainer = panel.tab_scroll if panel is InstitutionHubPanelBase else panel.section_bar.get_parent()
			_check(tab_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, property + " loses horizontal section navigation")
			var bar: Container = panel.tab_grid if panel is InstitutionHubPanelBase else panel.section_bar
			_check(bar.get_child_count() >= 3, property + " fixture has no populated tabs")
			for button in bar.get_children():
				if button is Button:
					_check_readable(button, property + " section tab")
			var back: Button = panel.close_button if panel is InstitutionHubPanelBase else panel.back_button
			_check_readable(back, property + " Back")
			# Recreate the legacy style/minimum overwrite that produced blank pills.
			for button in bar.get_children():
				if button is Button:
					button.clip_text = true
					button.custom_minimum_size.x = 0
			adapter.refresh()
			await _settle()
			for button in bar.get_children():
				if button is Button:
					_check_readable(button, property + " restyled section tab")
		_check(adapter.handle_back() and not panel.visible, property + " Back bypasses its close signal")
		panel.queue_free()
		host.controls.erase(property)
		await process_frame

func _subpages(host: Host, adapter: Node) -> void:
	var profile := RelationshipProfilePanel.new()
	host.controls.relationship_profile_panel = profile
	host.add_child(profile)
	var profile_back := [false]
	profile.request_back.connect(func(): profile_back[0] = true)
	var actions: Array = []
	for index in range(18):
		actions.append({"id": "family_%d" % index, "label": "Spend time with family member %d" % index})
	profile.open_contract({"title": "A close family member", "profile_text": "Family history. ".repeat(120), "actions": actions})
	for dimensions in [Vector2i(420, 747), Vector2i(360, 640)]:
		root.content_scale_size = dimensions
		await _settle()
		_check(profile.card.get_global_rect().end.x <= dimensions.x and profile.card.get_global_rect().end.y <= dimensions.y, "Relationship profile exceeds portrait bounds")
		var scroll := profile.card.find_child("EraProfileScroll", true, false) as ScrollContainer
		_check(scroll != null and scroll.get_v_scroll_bar().max_value > scroll.size.y, "Profile sections cannot be reached by scrolling")
		_check(profile.actions_scroll.get_v_scroll_bar().max_value > profile.actions_scroll.size.y, "Profile actions cannot scroll")
		_check(profile.action_button_pool[0].get_meta("action_id") == "family_0", "Profile adaptation changed action identities")
		_check_readable(profile.back_button, "Profile Back")
	_check(adapter.handle_back() and not profile.visible and profile_back[0], "Profile Back bypasses request_back")
	profile.queue_free()
	host.controls.erase("relationship_profile_panel")
	await process_frame
	for property in ["belongings_item_popup", "belongings_item_target_popup", "title_card_account_popup"]:
		var popup := _remember(host, property, PanelContainer.new(), host)
		popup.custom_minimum_size = Vector2(520, 500)
		var content: Node = popup
		if property == "title_card_account_popup":
			var scroll := ScrollContainer.new()
			popup.add_child(scroll)
			content = scroll
		var margin := MarginContainer.new()
		content.add_child(margin)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(box)
		var title := Label.new()
		title.text = "Choose how to use this family belonging"
		box.add_child(title)
		if property == "belongings_item_target_popup":
			host.controls.belongings_item_target_popup_title = title
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for index in range(16):
			var row := HBoxContainer.new()
			list.add_child(row)
			var label := Label.new()
			label.text = "An available person or account setting"
			row.add_child(label)
			var button := Button.new()
			button.text = "Choose %d" % index
			row.add_child(button)
		for dimensions in [Vector2i(420, 747), Vector2i(360, 640)]:
			root.content_scale_size = dimensions
			await _settle()
			_check(popup.get_global_rect().position.x >= 0 and popup.get_global_rect().end.x <= dimensions.x and popup.get_global_rect().end.y <= dimensions.y, property + " exceeds portrait bounds")
			_check(scroll.get_v_scroll_bar().max_value > scroll.size.y, property + " loses scrolling content")
		if property == "belongings_item_target_popup":
			var back := box.get_node("EraAssetTargetBack") as Button
			_check(back.size.y >= 44, "Item target has no touch Back")
			back.pressed.emit()
			_check(host.last_back == property and not popup.visible, "Item target touch Back bypasses original return route")
			popup.show()
		_check(adapter.handle_back() and host.last_back == property and not popup.visible, property + " Android Back bypasses original return route")
		popup.queue_free()
		host.controls.erase(property)
		await process_frame
	await _world_subpage(host, adapter)

func _world_subpage(host: Host, adapter: Node) -> void:
	var surface := _remember(host, "world_feed_popup", Control.new(), host)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := MarginContainer.new()
	surface.add_child(outer)
	var card := _remember(host, "world_feed_popup_card", PanelContainer.new(), outer)
	var box := VBoxContainer.new()
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var back := _remember(host, "world_feed_popup_back_button", Button.new(), header) as Button
	back.text = "← Back"
	var capsule := HBoxContainer.new()
	box.add_child(capsule)
	var label := _remember(host, "world_feed_popup_capsule_label", Label.new(), capsule) as Label
	label.text = "Reality Link: Copy this life as a portable world."
	var copy := Button.new()
	copy.text = "Copy Reality Link"
	capsule.add_child(copy)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var feed := _remember(host, "world_feed_popup_feed", RichTextLabel.new(), body) as RichTextLabel
	feed.text = "The world evolves. ".repeat(80)
	feed.scroll_active = true
	var actions := _remember(host, "world_action_panel", PanelContainer.new(), body)
	actions.custom_minimum_size.x = 300
	var scroll := ScrollContainer.new()
	actions.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for text in ["Auto-Preserve", "Save Game", "Load Game", "Reality Fusion", "Return to main menu", "Near By", "Other Countries/Realms"]:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size.y = 64
		list.add_child(button)
	for dimensions in [Vector2i(420, 747), Vector2i(360, 640)]:
		root.content_scale_size = dimensions
		await _settle()
		_check(card.get_global_rect().end.x <= dimensions.x and card.get_global_rect().end.y <= dimensions.y, "World panel exceeds portrait bounds")
		_check(feed.get_global_rect().end.y <= actions.get_global_rect().position.y, "World feed and save actions are not stacked")
		_check(scroll.size.y >= 130 and scroll.get_v_scroll_bar().max_value > scroll.size.y, "World actions lack usable scrolling space")
		_check_readable(back, "World Back")
	_check(adapter.handle_back() and host.last_back == "world_feed_popup" and not surface.visible, "World Back bypasses original route")
	surface.queue_free()
	host.controls.erase("world_feed_popup")
	await process_frame

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = Design.create()
	_standard(host)
	var original_body: HBoxContainer = host.controls.standard_tab_popup_body
	var first_action: Button = host.controls.standard_tab_popup_right.get_child(0)
	var invoked := [false]
	first_action.pressed.connect(func(): invoked[0] = true)
	var adapter := Panels.new()
	host.add_child(adapter)
	for dimensions in [Vector2i(420, 747), Vector2i(420, 933), Vector2i(360, 640)]:
		root.content_scale_size = dimensions
		await _settle()
		var card: Control = host.controls.standard_tab_popup_card
		_check(card.get_global_rect().end.x <= dimensions.x and card.get_global_rect().end.y <= dimensions.y, "Portrait tab exceeds viewport at " + str(dimensions))
		_check(original_body == host.controls.standard_tab_popup_body, "Replaced the runtime's typed HBox reference")
		var left: Control = host.controls.standard_tab_popup_left_scroll.get_parent()
		var right: Control = host.controls.standard_tab_popup_right_scroll.get_parent()
		_check(left.get_global_rect().end.y <= right.get_global_rect().position.y, "Portrait tab content is not stacked")
		_check(right.size.x >= dimensions.x - 90, "Portrait actions are not full width")
		_check(host.controls.standard_tab_popup_right_scroll.get_v_scroll_bar().max_value > right.size.y, "Long action list cannot scroll")
		_check(first_action.size.y >= 44, "Action lost its touch target")
		_check(host.controls.standard_tab_popup_right.get_child(5).disabled, "Presentation enabled an unavailable action")
		_check(first_action.get_meta("action_id") == 0, "Presentation changed action identity")
	_check(adapter.handle_back() and host.returned, "Back bypasses the standard popup's navigation handler")
	first_action.pressed.emit()
	_check(invoked[0], "Reparenting disconnected an action")
	host.controls.standard_tab_popup.hide()
	var hidden_action := Button.new()
	hidden_action.text = "Added while hidden"
	hidden_action.custom_minimum_size = Vector2(600, 18)
	host.controls.standard_tab_popup_right.add_child(hidden_action)
	await _settle() # Consume node-added dirty while the prepared root is hidden.
	host.controls.standard_tab_popup.show()
	await _settle()
	_check(hidden_action.custom_minimum_size.x == 0 and hidden_action.size.y >= 44, "Hidden rebuilt panel did not adapt on reveal")
	_check(host.controls.standard_tab_popup_card.get_global_rect().end.x <= root.content_scale_size.x, "Hidden rebuilt content widens the revealed popup")
	host.controls.standard_tab_popup.hide()
	_event(host)
	for dimensions in [Vector2i(420, 747), Vector2i(360, 640)]:
		root.content_scale_size = dimensions
		await _settle()
		var card: Control = host.controls.action_result_popup_card
		_check(card.get_global_rect().position.x >= 0 and card.get_global_rect().end.x <= dimensions.x and card.get_global_rect().end.y <= dimensions.y, "Event choices force the card beyond the screen")
		var choices: Control = host.controls.action_result_popup_choices
		_check(choices.get_parent() is ScrollContainer, "Long event choices have no scroll container")
		_check(choices.get_parent().get_v_scroll_bar().max_value > choices.get_parent().size.y, "Event choices are inaccessible below the fold")
	_check(adapter.handle_back() and host.dismissed, "Event dismissal bypasses its guarded input route")
	host.controls.action_result_popup.hide()
	await _real_hubs(host, adapter)
	await _subpages(host, adapter)
	# Narrative rebuilds its top actions with queue_free before the next frame.
	var row := HBoxContainer.new()
	host.add_child(row)
	var old_button := Button.new()
	row.add_child(old_button)
	var retired: Control = adapter._stack_row(row)
	retired.queue_free()
	var replacement := Button.new()
	replacement.text = "Back to stories"
	row.add_child(replacement)
	adapter._stack_row(row)
	await _settle()
	_check(is_instance_valid(replacement) and row.is_ancestor_of(replacement), "Rebuilt actions were reparented into a retiring portrait wrapper")
	host.queue_free()
	await process_frame
	print("MOBILE PANELS TEST: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
