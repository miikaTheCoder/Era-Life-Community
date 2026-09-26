extends Node
## Portrait presentation of existing entry forms and modal controls.
## Original controls, signals, visibility and gameplay contracts stay authoritative.
const ROOTS := [
	"startup_intro_overlay", "household_creator_overlay", "household_creator_prompt_overlay",
	"household_creator_unfinished_overlay", "household_creator_start_selection_overlay",
	"god_mode_viewer", "choose_adventure_scenario_panel", "standard_tab_popup",
	"action_result_popup", "popup_viewer",
	"activities_hub_panel", "career_hub_panel", "relationship_hub_panel", "school_hub_panel",
	"institution_hub_overlay", "belongings_hud_panel", "bending_hud_panel",
	"rick_weapon_shop_popup", "ui_contract_surface_panel",
	"belongings_item_popup", "belongings_item_target_popup", "relationship_profile_panel",
	"world_feed_popup", "title_card_account_popup", "saved_life_picker_popup",
]
var host: Control
var dirty := true
var last_size := Vector2.ZERO
var prepared: Dictionary = {}
var named_controls: Dictionary = {}

func _ready() -> void:
	host = get_parent() as Control
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1002
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Control and host.is_ancestor_of(node):
		dirty = true

func _process(_delta: float) -> void:
	refresh()

func _control(property: String) -> Control:
	return host.get(property) as Control

func _named(surface: Node, node_name: String) -> Node:
	var key := "%d:%s" % [surface.get_instance_id(), node_name]
	var cached: WeakRef = named_controls.get(key)
	var node: Node = cached.get_ref() if cached != null else null
	if node == null:
		node = surface.find_child(node_name, true, false)
		if node != null:
			named_controls[key] = weakref(node)
	return node

func _safe_rect() -> Rect2:
	return MobileSupport.safe_viewport_rect(host)

func refresh() -> void:
	var safe := _safe_rect()
	var adapt := dirty or safe.size != last_size
	if adapt:
		# Hidden prepared roots must also adapt new content when next revealed.
		prepared.clear()
	dirty = false
	last_size = safe.size
	for property in ROOTS:
		var surface := _control(property)
		if not is_instance_valid(surface) or not surface.is_visible_in_tree():
			continue
		if adapt or not prepared.has(surface.get_instance_id()):
			_adapt_tree(surface, property in ["household_creator_overlay", "god_mode_viewer", "household_creator_prompt_overlay"])
			if property in ["activities_hub_panel", "career_hub_panel", "relationship_hub_panel", "school_hub_panel", "institution_hub_overlay", "belongings_hud_panel", "bending_hud_panel", "rick_weapon_shop_popup", "ui_contract_surface_panel", "belongings_item_popup", "belongings_item_target_popup", "relationship_profile_panel", "world_feed_popup", "title_card_account_popup"]:
				_adapt_hub_content(surface)
			prepared[surface.get_instance_id()] = true
		match property:
			"startup_intro_overlay": _layout_title(surface, safe)
			"household_creator_overlay": _layout_household(surface, safe)
			"god_mode_viewer": _layout_god(surface, safe)
			"choose_adventure_scenario_panel": _layout_narrative(surface, safe)
			"standard_tab_popup": _layout_standard(surface, safe)
			"action_result_popup": _layout_result(surface, safe)
			"popup_viewer": _layout_pending(surface, safe)
			"activities_hub_panel", "career_hub_panel": _layout_activity_career(surface, safe)
			"relationship_hub_panel", "school_hub_panel": _layout_institution(surface, safe)
			"institution_hub_overlay":
				_set_rect(_control("institution_hub_card"), safe.grow(-8))
				var tabs := _control("institution_hub_section_bar") as GridContainer
				if tabs != null:
					tabs.columns = 2
			"belongings_hud_panel", "bending_hud_panel", "rick_weapon_shop_popup", "ui_contract_surface_panel", "belongings_item_popup", "belongings_item_target_popup", "title_card_account_popup": _layout_modal_panel(surface, property, safe)
			"relationship_profile_panel": _layout_profile(surface, safe)
			"world_feed_popup": _layout_world(surface, safe)
			"saved_life_picker_popup": _set_rect(surface, safe.grow(-8))
			_: _layout_centered_prompt(surface, safe)

func _adapt_tree(node: Node, stack_forms: bool) -> void:
	if node.is_queued_for_deletion():
		return
	if node is Control:
		node.custom_minimum_size.x = 0
	if node is MarginContainer:
		_margins(node, 10)
	if node is Label:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_font_size_override("font_size", clampi(node.get_theme_font_size("font_size"), 14, 24))
	elif node is RichTextLabel:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif node is BaseButton:
		node.custom_minimum_size.y = maxf(44, node.custom_minimum_size.y)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if node is Button:
			node.clip_text = true
			node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if node.tooltip_text.is_empty():
				node.tooltip_text = node.text
			node.add_theme_font_size_override("font_size", 16)
			if node.text in ["×", "✕", "X", "←"]:
				node.custom_minimum_size.x = 44
				node.size_flags_horizontal = Control.SIZE_FILL
	elif node is LineEdit or node is SpinBox:
		node.custom_minimum_size.y = maxf(44, node.custom_minimum_size.y)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if node is ScrollContainer:
		if node.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		node.follow_focus = true
	if node is GridContainer and stack_forms:
		# Legacy forms alternate label/control pairs in four desktop columns.
		node.columns = 1
	if node is HBoxContainer and stack_forms and not _is_header(node):
		_stack_row(node)
	for child in node.get_children():
		_adapt_tree(child, stack_forms)

func _is_header(node: Node) -> bool:
	return str(node.name) in ["HouseholdCreatorTopBar", "GodModeViewerHeaderRow"]

func _margins(margin: MarginContainer, amount: int) -> void:
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, amount)

func _stack_row(row: HBoxContainer) -> VBoxContainer:
	var column := row.get_node_or_null("EraPortraitColumn") as VBoxContainer
	if column != null and column.is_queued_for_deletion():
		# Owners can rebuild a row before its old children are freed this frame.
		column.name = "EraPortraitColumnRetiring"
		column.hide()
		column = null
	if column == null:
		column = VBoxContainer.new()
		column.name = "EraPortraitColumn"
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 8)
		row.add_child(column)
	for child in row.get_children():
		if child != column and not child.is_queued_for_deletion():
			child.reparent(column)
	return column

func _set_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.custom_minimum_size = Vector2.ZERO
	control.position = rect.position
	control.size = rect.size

func _layout_title(surface: Control, safe: Rect2) -> void:
	var frame := surface.get_node_or_null("StartupIntroCompositionFrame") as MarginContainer
	if frame != null:
		_set_rect(frame, safe)
		_margins(frame, 20)
		frame.add_theme_constant_override("margin_top", 140)
	for property in ["startup_intro_title_label", "startup_intro_line_label", "startup_intro_year_label", "startup_intro_subtitle_label", "startup_intro_prompt_label"]:
		var label := _control(property) as Label
		if label != null:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = 0
			label.add_theme_font_size_override("font_size", 42 if property == "startup_intro_title_label" else (22 if property == "startup_intro_line_label" else 16))

func _layout_household(surface: Control, safe: Rect2) -> void:
	var outer := surface.get_node_or_null("HouseholdCreatorOuter") as MarginContainer
	if outer != null:
		_set_rect(outer, safe)
		_margins(outer, 8)
	for name in ["HouseholdCreatorScrollUpButton", "HouseholdCreatorScrollDownButton"]:
		var arrow := _named(surface, name) as Control
		if arrow != null:
			arrow.hide()
	var back := _named(surface, "HouseholdCreatorTopBackButton") as Button
	if back != null:
		_readable_button(back, 86)
	var title := _named(surface, "HouseholdCreatorTitle") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", 20)
	# The desktop CenterContainer shrink-wraps this stack. Restore its mobile
	# width after adaptation clears the desktop minimum and clips button text.
	var empty_actions := _named(surface, "HouseholdCreatorEmptyActionStack") as Control
	if empty_actions != null:
		empty_actions.custom_minimum_size.x = maxf(0, safe.size.x - 64)
	var scroll := _control("household_creator_scroll") as ScrollContainer
	if scroll != null:
		scroll.custom_minimum_size = Vector2.ZERO

func _layout_god(surface: Control, safe: Rect2) -> void:
	var panel := surface.get("panel") as Control
	if panel != null:
		_set_rect(panel, safe.grow(-8))
	var margin := surface.get("margin") as MarginContainer
	if margin != null:
		_margins(margin, 12)

func _layout_narrative(surface: Control, safe: Rect2) -> void:
	var margin := surface.get_node_or_null("ChooseAdventureSafeMargin") as MarginContainer
	if margin == null:
		return
	_set_rect(margin, safe)
	_margins(margin, 8)
	var root := _named(surface, "ChooseAdventureScenarioRoot") as VBoxContainer
	if root != null and not root.get_parent() is ScrollContainer:
		_wrap_scroll(root, "EraNarrativeScroll")
	var choices := surface.get("choices_scroll") as ScrollContainer
	if choices != null:
		choices.custom_minimum_size.y = minf(360, safe.size.y * 0.42)
	var toolbar := surface.get("top_actions_bar") as HBoxContainer
	if toolbar != null:
		_stack_row(toolbar)
		for name in ["ChooseAdventureTopLeftActions", "ChooseAdventureTopRightActions"]:
			var row := _named(toolbar, name) as HBoxContainer
			if row != null:
				_stack_row(row)

func _layout_standard(surface: Control, safe: Rect2) -> void:
	var card := _control("standard_tab_popup_card")
	var body := _control("standard_tab_popup_body") as HBoxContainer
	if card == null or body == null:
		return
	var outer := card.get_parent() as MarginContainer
	_set_rect(outer, safe)
	_margins(outer, 8)
	_stack_row(body)
	var left_scroll := _control("standard_tab_popup_left_scroll") as ScrollContainer
	var right_scroll := _control("standard_tab_popup_right_scroll") as ScrollContainer
	if left_scroll != null:
		var left_panel := left_scroll.get_parent() as Control
		left_panel.custom_minimum_size = Vector2(0, clampf(safe.size.y * 0.24, 130, 210))
		left_panel.size_flags_vertical = Control.SIZE_FILL
		var summary := _control("standard_tab_popup_left") as RichTextLabel
		if summary != null:
			summary.custom_minimum_size = Vector2.ZERO
			summary.fit_content = true
			summary.scroll_active = false
	if right_scroll != null:
		var right_panel := right_scroll.get_parent() as Control
		right_panel.custom_minimum_size = Vector2.ZERO
		right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var back := _control("standard_tab_popup_back_button") as Button
	if back != null:
		_readable_button(back, 86)

func _wrap_scroll(content: Control, scroll_name: String) -> ScrollContainer:
	if content.get_parent() is ScrollContainer and content.get_parent().name == scroll_name:
		return content.get_parent() as ScrollContainer
	var parent := content.get_parent()
	var index := content.get_index()
	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	parent.move_child(scroll, index)
	content.reparent(scroll)
	content.custom_minimum_size = Vector2.ZERO
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return scroll

func _bound_center_card(card: Control, safe: Rect2) -> void:
	var center := card.get_parent() as CenterContainer
	if center != null:
		_set_rect(center, safe)
	card.custom_minimum_size = safe.size - Vector2(16, 24)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _layout_result(surface: Control, safe: Rect2) -> void:
	var card := _control("action_result_popup_card")
	if card == null:
		return
	_bound_center_card(card, safe)
	var body := _control("action_result_popup_body") as RichTextLabel
	if body != null:
		body.custom_minimum_size = Vector2(0, 110)
		body.fit_content = false
		body.scroll_active = true
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choices := _control("action_result_popup_choices")
	if choices != null:
		var scroll := _wrap_scroll(choices, "EraEventChoicesScroll")
		scroll.visible = choices.visible
		scroll.custom_minimum_size.y = 120 if choices.visible else 0
	var box := _named(surface, "ActionResultVBox") as VBoxContainer
	if box != null:
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _layout_pending(surface: Control, safe: Rect2) -> void:
	var card := surface.get("card") as Control
	if card == null:
		return
	_bound_center_card(card, safe)
	var body := surface.get("body_label") as RichTextLabel
	if body != null:
		body.fit_content = false
		body.scroll_active = true
		body.custom_minimum_size.y = 100
	var options := surface.get("options_box") as Control
	if options != null:
		var scroll := _wrap_scroll(options, "EraPendingOptionsScroll")
		scroll.visible = options.visible and options.get_child_count() > 0
		# A chapter needs reading space above its responses. Do not let a short
		# response list consume the screen while its story is trapped in 100px.
		scroll.size_flags_vertical = Control.SIZE_FILL
		scroll.custom_minimum_size.y = clampf(options.get_combined_minimum_size().y, 100, safe.size.y * 0.4) if scroll.visible else 0
		if body != null:
			body.size_flags_vertical = Control.SIZE_EXPAND_FILL if scroll.visible else Control.SIZE_FILL

func _layout_centered_prompt(surface: Control, safe: Rect2) -> void:
	for child in surface.get_children():
		if child is CenterContainer:
			for card in child.get_children():
				if card is PanelContainer:
					_bound_center_card(card, safe)
					var margin := card.get_child(0) as MarginContainer
					if margin != null and margin.get_child_count() > 0:
						var content := margin.get_child(0) as Control
						if not content is ScrollContainer:
							_wrap_scroll(content, "EraPromptScroll")

func _adapt_hub_content(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	# Keep horizontal section strips; collapse desktop grids inside their content.
	if node is GridContainer and not (node.get_parent() is ScrollContainer and node.get_parent().vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED):
		node.columns = 1
	if node is ScrollContainer and node.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		node.custom_minimum_size = Vector2.ZERO
		for child in node.get_children():
			if child is Container:
				_adapt_scroll_rows(child)
	for child in node.get_children():
		_adapt_hub_content(child)

func _adapt_scroll_rows(node: Node) -> void:
	if node.is_queued_for_deletion():
		return
	if node is HBoxContainer and not node.get_meta("era_keep_inline", false) and node.get_node_or_null("PasswordVisibilityButton") == null:
		_stack_row(node)
	for child in node.get_children():
		_adapt_scroll_rows(child)

func _horizontal_tabs(bar: Container) -> void:
	var scroll := bar.get_parent() as ScrollContainer
	if scroll == null:
		scroll = _wrap_scroll(bar, "EraSectionTabs")
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 56)
	scroll.size_flags_vertical = Control.SIZE_FILL
	bar.size_flags_horizontal = Control.SIZE_FILL
	if bar is GridContainer:
		bar.columns = maxi(1, bar.get_child_count())
	for child in bar.get_children():
		if child is Button and not child.is_queued_for_deletion():
			_readable_button(child)

func _readable_button(button: Button, minimum_width: float = 44) -> void:
	# The global legacy style pass can enable clipping and collapse text minima.
	# Reserve the actual label width independently of clip/overrun behavior.
	var label_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	var padding := 24.0
	for state in ["normal", "hover", "pressed", "disabled"]:
		padding = maxf(padding, button.get_theme_stylebox(state).get_minimum_size().x)
	button.custom_minimum_size = Vector2(maxf(minimum_width, ceilf(label_width + padding)), 44)
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.size_flags_horizontal = Control.SIZE_FILL

func _layout_activity_career(surface: Control, safe: Rect2) -> void:
	_set_rect(surface, safe.grow(-8))
	var back := surface.get("back_button") as Button
	var title := surface.get("title_label") as Label
	if back != null and title != null:
		var row := back.get_parent() as HBoxContainer
		var title_box := title.get_parent() as Control
		if row != null:
			for child in row.get_children():
				if child == back or child == title_box:
					continue
				var time_label := surface.get("time_label") as Control if surface is CareerHubPanel else null
				if time_label != null and child.is_ancestor_of(time_label):
					child.reparent(title_box)
				else:
					child.hide() # Decorative brand badge duplicates the page title.
			row.move_child(back, 0)
			back.text = "← Back"
			_readable_button(back, 86)
			title.add_theme_font_size_override("font_size", 20)
	var tabs := surface.get("section_bar") as Container
	if tabs != null:
		_horizontal_tabs(tabs)
	if surface is CareerHubPanel:
		surface.identity_metrics_grid.columns = 2
	var content := surface.get("content_scroll") as ScrollContainer
	if content != null:
		content.custom_minimum_size = Vector2.ZERO

func _layout_institution(surface: Control, safe: Rect2) -> void:
	var shell := surface.get("shell") as Control
	if shell == null:
		return
	_set_rect(shell, safe.grow(-8))
	var chip := surface.get("header_chip") as Control
	var stack := surface.get("shell_root") as VBoxContainer
	if chip != null and stack != null and chip.get_parent() != stack:
		chip.reparent(stack)
		stack.move_child(chip, 1)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := surface.get("close_button") as Button
	if back != null:
		_readable_button(back, 86)
	var tabs := surface.get("tab_grid") as Container
	if tabs != null:
		_horizontal_tabs(tabs)
	var content := surface.get("section_surface_host") as Control
	if content != null:
		content.custom_minimum_size = Vector2.ZERO

func _layout_modal_panel(surface: Control, property: String, safe: Rect2) -> void:
	_set_rect(surface, safe.grow(-8))
	if property == "belongings_hud_panel":
		var content := _control("belongings_hud_root") as VBoxContainer
		if content != null and content.get_node_or_null("EraAssetsBack") == null:
			var back := Button.new()
			back.name = "EraAssetsBack"
			back.text = "← Back"
			back.custom_minimum_size.y = 44
			back.pressed.connect(Callable(host, "_toggle_belongings_hud"))
			content.add_child(back)
			content.move_child(back, 0)
	elif property == "belongings_item_target_popup":
		var title := _control("belongings_item_target_popup_title")
		if title != null:
			var content := title.get_parent()
			if content.get_node_or_null("EraAssetTargetBack") == null:
				var back := Button.new()
				back.name = "EraAssetTargetBack"
				back.text = "← Back"
				back.custom_minimum_size.y = 44
				back.pressed.connect(Callable(host, "_back_to_belongings_list_from_artifact_target_popup"))
				content.add_child(back)
				content.move_child(back, 0)
	elif property == "belongings_item_popup":
		var back := _control("belongings_item_popup_close_button") as Button
		if back != null:
			_readable_button(back, 86)
	elif property == "title_card_account_popup":
		var toggle := _control("title_card_account_password_toggle_button") as Button
		if toggle != null:
			toggle.custom_minimum_size = Vector2(44, 44)
			toggle.size_flags_horizontal = Control.SIZE_FILL
	elif property == "bending_hud_panel":
		var tabs := _control("bending_hud_section_bar") as Container
		if tabs != null:
			_horizontal_tabs(tabs)

func _layout_profile(surface: Control, safe: Rect2) -> void:
	var card := surface.get("card") as Control
	if card == null:
		return
	_set_rect(card, safe.grow(-8))
	var back := surface.get("back_button") as Button
	var top_bar := back.get_parent() as HBoxContainer
	if top_bar != null and not top_bar.has_meta("era_keep_inline"):
		top_bar.set_meta("era_keep_inline", true)
		var root := top_bar.get_parent()
		var bank := surface.get("bank_label") as Control
		bank.reparent(root)
		root.move_child(bank, 1)
		var actions := HBoxContainer.new()
		actions.name = "EraProfileActions"
		actions.set_meta("era_keep_inline", true)
		actions.add_theme_constant_override("separation", 8)
		root.add_child(actions)
		root.move_child(actions, 2)
		for property in ["switch_button", "edit_button"]:
			var button := surface.get(property) as Control
			button.reparent(actions)
		_wrap_scroll(root, "EraProfileScroll")
	_readable_button(back, 86)
	surface.get("stats_grid").columns = 2
	var profile_scroll := surface.get("profile_scroll") as ScrollContainer
	profile_scroll.custom_minimum_size = Vector2(0, 160)
	var text := surface.get("profile_text") as RichTextLabel
	text.custom_minimum_size = Vector2.ZERO
	text.fit_content = true
	var actions_scroll := surface.get("actions_scroll") as ScrollContainer
	actions_scroll.custom_minimum_size = Vector2(0, 240)
	surface.get("actions_box").custom_minimum_size = Vector2.ZERO

func _layout_world(_surface: Control, safe: Rect2) -> void:
	var card := _control("world_feed_popup_card")
	if card == null:
		return
	var outer := card.get_parent() as MarginContainer
	_set_rect(outer, safe)
	_margins(outer, 8)
	var back := _control("world_feed_popup_back_button") as Button
	if back != null:
		_readable_button(back, 86)
	var capsule := _control("world_feed_popup_capsule_label")
	if capsule != null and capsule.get_parent() is HBoxContainer:
		_stack_row(capsule.get_parent())
	var feed := _control("world_feed_popup_feed") as RichTextLabel
	if feed != null:
		if feed.get_parent() is HBoxContainer:
			_stack_row(feed.get_parent())
		feed.custom_minimum_size = Vector2(0, clampf(safe.size.y * 0.25, 130, 210))
		feed.size_flags_vertical = Control.SIZE_FILL
	var actions := _control("world_action_panel")
	if actions != null:
		actions.custom_minimum_size = Vector2.ZERO
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.size_flags_vertical = Control.SIZE_EXPAND_FILL

func handle_back() -> bool:
	# Close the top visible surface, never an underlying tab or creator.
	var topmost: Control = null
	var property := ""
	var top_z := -100000
	var top_layer := -100000
	for key in ROOTS:
		var panel := _control(key)
		if is_instance_valid(panel) and panel.is_visible_in_tree():
			var canvas := panel.get_canvas_layer_node()
			var layer := canvas.layer if canvas != null else 0
			var draw_z := MobileSupport._effective_z(panel)
			if layer > top_layer or (layer == top_layer and draw_z >= top_z):
				topmost = panel
				property = key
				top_layer = layer
				top_z = draw_z
	if topmost == null:
		return false
	if property == "action_result_popup":
		# This route retains choice, input-lock, rename and follow-up guards.
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = true
		host.call("_on_action_result_popup_gui_input", event)
		return true
	if property == "relationship_profile_panel":
		topmost.get("back_button").pressed.emit()
		return true
	if property in ["activities_hub_panel", "career_hub_panel"]:
		topmost.call("close_panel")
		return true
	if property in ["relationship_hub_panel", "school_hub_panel"]:
		topmost.emit_signal("close_requested")
		return true
	if property in ["choose_adventure_scenario_panel", "household_creator_start_selection_overlay"]:
		var branch: Node = topmost.get("top_left_actions") if property == "choose_adventure_scenario_panel" else topmost
		if branch != null:
			for button in branch.find_children("*", "Button", true, false):
				if "back" in button.text.to_lower() and button.is_visible_in_tree() and not button.disabled and not button.is_queued_for_deletion():
					button.pressed.emit()
					return true
		return false
	if property == "popup_viewer":
		topmost.call("_on_close_pressed")
		return true
	var routes := {
		"belongings_item_popup": "_back_to_belongings_list_from_item_popup",
		"belongings_item_target_popup": "_back_to_belongings_list_from_artifact_target_popup",
		"world_feed_popup": "_on_world_feed_popup_back_pressed",
		"saved_life_picker_popup": "_close_saved_life_picker",
		"title_card_account_popup": "_close_title_card_account_panel",
		"ui_contract_surface_panel": "_close_contract_surface_panel",
		"rick_weapon_shop_popup": "_close_rick_weapon_shop_popup",
		"bending_hud_panel": "_toggle_bending_hud",
		"belongings_hud_panel": "_toggle_belongings_hud",
		"household_creator_prompt_overlay": "_household_creator_close_choice_prompt",
		"household_creator_unfinished_overlay": "_household_creator_close_unfinished_households_popup",
		"standard_tab_popup": "_on_standard_tab_popup_back_pressed",
		"institution_hub_overlay": "_on_institution_hub_back_pressed",
		"household_creator_overlay": "_on_household_creator_back_pressed",
	}
	if routes.has(property):
		host.call(routes[property])
		return true
	return false
