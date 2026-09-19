extends Node
const Design = preload("res://ui/EraTheme.gd")
const BranchMark = preload("res://ui/EraBranchMark.gd")
const TOOL_SIZE := Vector2(112, 46)
const TOOL_GAP := 12.0
const TOOL_RIGHT := 20.0
const TOOL_BOTTOM := 88.0
const TOOL_TOP := 84.0
# Match the runtime stack order; gameplay still owns availability and modal layering.
const TOOL_LABELS := {
	"boxing": "Boxing", "belongings": "Belongings", "food_lifestyle": "Food",
	"restaurant_lifestyle": "Dining", "rick_weapon_shop": "Weapons", "bending": "Bending",
	"crown": "Realm", "superpower": "Superpowers", "power": "Powers", "wizard": "Magic"}
var host: Control
var navigation: HBoxContainer
var navigation_scroll: ScrollContainer
var header: HBoxContainer
var chapter: Label
var identity: Label
var footer: HBoxContainer
var year_label: Label
var stats_toggle: Button
var stats_open := false
var last_panel := ""
var was_narrow := false

static func label(text: String, size: int = 16, color: Color = Design.TEXT, display := false) -> Label:
	var node := Label.new()
	node.set_meta("era_owned", true)
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", Design.DISPLAY if display else Design.BODY)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", 0)
	node.add_theme_constant_override("shadow_outline_size", 0)
	node.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	return node

static func mount_menu(scene: Control) -> void:
	var overlay: Control = scene.get("choose_adventure_entry_overlay")
	var scroll := ScrollContainer.new()
	scroll.name = "ChooseAdventureEntryCenter"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	overlay.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	scroll.add_child(margin)
	var page := VBoxContainer.new()
	page.name = "EraMenuPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 22)
	margin.add_child(page)
	var masthead := HBoxContainer.new()
	page.add_child(masthead)
	var brand := label("ERA / LIFE", 22, Design.ACCENT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(brand)
	masthead.add_child(label("COMMUNITY EDITION", 13, Design.MUTED))
	page.add_child(HSeparator.new())
	var heading := label("Every life starts somewhere.", 48, Design.TEXT, true)
	heading.name = "EraMenuHeading"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(heading)
	var hint := label("Choose the beginning. See who you become.", 18, Design.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(hint)
	var grid := GridContainer.new()
	grid.name = "ChooseAdventureEntryTripleShell"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	scene.set("choose_adventure_entry_shell", grid)
	overlay.resized.connect(layout_menu.bind(scene))
	layout_menu.call_deferred(scene)

static func create_entry_card(contract: Dictionary) -> PanelContainer:
	var role := str(contract.get("button_role", ""))
	var index := ["narrative_alive", "household_alive", "god_mode_alive"].find(role)
	index = maxi(0, index)
	var titles := ["Follow a story", "Build a household", "Shape a world"]
	var descriptions := [
		"Start with a story. Make the choices that shape your past, then step into the life that follows.",
		"Create the people, define their relationships, and choose whose life you want to lead.",
		"Choose an era and create a character from the ground up. Set the conditions for a life of your own."]
	var details := ["NARRATIVE MODE", "HOUSEHOLD MODE", "GOD MODE"]
	var card := PanelContainer.new()
	card.name = "ChooseAdventureEntryCard_" + str(contract.get("id", "entry"))
	card.set_meta("era_owned", true)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mobile := MobileSupport.is_enabled()
	var surface := Design.box(Design.PANEL, Design.LINE, 6, 16 if mobile else 24)
	surface.content_margin_top = 16 if mobile else 24
	surface.content_margin_bottom = 16 if mobile else 24
	card.add_theme_stylebox_override("panel", surface)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10 if mobile else 18)
	card.add_child(box)
	var eyebrow := label("0%d  /  %s" % [index + 1, details[index]], 13, Design.AMBER)
	eyebrow.name = "EntryCardEyebrow"
	box.add_child(eyebrow)
	var mark := BranchMark.new()
	mark.branch = index
	mark.visible = not mobile
	box.add_child(mark)
	var title := label(titles[index], 24 if mobile else 32, Design.TEXT, true)
	title.name = "EntryCardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var subtitle := label(descriptions[index], 15 if mobile else 17, Design.MUTED)
	subtitle.name = "EntryCardSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(subtitle)
	var button := Button.new()
	button.name = "EntryCardButton"
	button.text = str(contract.get("button_text", "Continue"))
	button.custom_minimum_size.y = 48
	button.set_meta("entry_role", role)
	button.disabled = bool(contract.get("demo_temporarily_unavailable", false))
	button.set_meta("entry_accent", Design.ACCENT)
	button.tooltip_text = descriptions[index]
	box.add_child(button)
	card.set_meta("entry_button", button)
	card.set_meta("accent", Design.ACCENT)
	var refresh := refresh_entry_card.bind(card, button)
	button.mouse_entered.connect(refresh)
	button.mouse_exited.connect(refresh)
	button.focus_entered.connect(refresh)
	button.focus_exited.connect(refresh)
	return card

static func refresh_entry_card(card: PanelContainer, button: Button) -> void:
	var active := button.is_hovered() or button.has_focus()
	var surface := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	surface.border_color = Design.ACCENT if active else Design.LINE
	surface.shadow_color = Color(Design.ACCENT, 0.14 if active else 0.0)
	surface.shadow_size = 10 if active else 0
	card.add_theme_stylebox_override("panel", surface)

static func layout_menu(scene: Control) -> void:
	var grid := scene.get("choose_adventure_entry_shell") as GridContainer
	if not is_instance_valid(grid):
		return
	var viewport := scene.get_viewport_rect().size
	var narrow := viewport.x < 960
	grid.columns = 1 if narrow else 3
	grid.custom_minimum_size = Vector2.ZERO
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for card in grid.get_children():
		card.custom_minimum_size = Vector2(0, 220 if MobileSupport.is_enabled() else (340 if narrow else 420))
	var scroll := scene.get("choose_adventure_entry_overlay").get_node("ChooseAdventureEntryCenter") as ScrollContainer
	var margin := scroll.get_child(0) as MarginContainer
	var side := 20 if narrow else int(maxf(40, (viewport.x - 1320) * 0.5))
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)
	var heading := margin.find_child("EraMenuHeading", true, false) as Label
	heading.add_theme_font_size_override("font_size", 28 if MobileSupport.is_enabled() else (36 if narrow else 48))
	if MobileSupport.is_enabled():
		var safe := MobileSupport.safe_viewport_rect(scene)
		scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scroll.position = safe.position
		scroll.size = safe.size
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)

func _ready() -> void:
	host = get_parent() as Control
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1001

func _build_live(root: Control) -> void:
	header = HBoxContainer.new()
	header.name = "EraMasthead"
	header.custom_minimum_size.y = 54
	root.add_child(header)
	root.move_child(header, 0)
	header.add_child(label("ERA / LIFE", 23, Design.ACCENT))
	identity = label("", 15, Design.MUTED)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(identity)
	stats_toggle = Button.new()
	stats_toggle.text = "Character"
	stats_toggle.toggle_mode = true
	stats_toggle.toggled.connect(func(open: bool): stats_open = open)
	header.add_child(stats_toggle)
	navigation_scroll = ScrollContainer.new()
	navigation_scroll.name = "EraNavigation"
	navigation_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	navigation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	navigation_scroll.follow_focus = true
	navigation_scroll.custom_minimum_size.y = 52
	root.add_child(navigation_scroll)
	root.move_child(navigation_scroll, 1)
	navigation = HBoxContainer.new()
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_theme_constant_override("separation", 4)
	navigation_scroll.add_child(navigation)
	chapter = label("Life journal", 30, Design.TEXT, true)
	chapter.name = "EraChapter"
	chapter.custom_minimum_size.y = 54
	root.add_child(chapter)
	root.move_child(chapter, 2)
	footer = HBoxContainer.new()
	footer.name = "EraProgression"
	footer.custom_minimum_size.y = 64
	root.add_child(footer)
	year_label = label("", 15, Design.MUTED)
	year_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(year_label)

func _process(_delta: float) -> void:
	var root := host.get_node_or_null("UIContainer") as Control
	if root == null:
		return
	var gs = host.get("gs")
	if gs == null or gs.player == null or not root.visible:
		return
	if not is_instance_valid(navigation):
		_build_live(root)
	var narrow := host.get_viewport_rect().size.x < 1000
	stats_toggle.visible = narrow
	var stats: Control = host.get("player_stats_overlay")
	if is_instance_valid(stats):
		if narrow:
			stats.visible = stats_open
		elif was_narrow:
			stats.visible = true
		stats.set_anchors_preset(Control.PRESET_TOP_LEFT)
		stats.position = Vector2(16, 84 if narrow else 18)
		stats.size = Vector2(252, host.get_viewport_rect().size.y - (102 if narrow else 36))
	last_panel = str(host.get("current_panel"))
	was_narrow = narrow
	var buttons: Dictionary = host.get("ui_nav_buttons")
	for key in buttons:
		var button := buttons[key] as Button
		if not is_instance_valid(button):
			continue
		var parent: Control = footer if key == "age_up" else navigation
		if button.get_parent() != parent:
			button.reparent(parent)
		button.custom_minimum_size = Vector2(156, 46) if key == "age_up" else Vector2(76, 40)
		button.size_flags_horizontal = Control.SIZE_FILL if key == "age_up" else Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.scale = Vector2.ONE
		button.rotation = 0
		# The selected underline must follow tab changes even when its contract is cached.
		if button.get_meta("era_selected_panel", "") != last_panel:
			button.set_meta("era_selected_panel", last_panel)
			host.get_node("EraInterface")._queue(button.get_instance_id())
	root.move_child(footer, root.get_child_count() - 1)
	_layout_tools()
	layout_live(host)
	identity.text = "%s  /  Age %d" % [gs.player._display_name(), gs.player.age]
	identity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.clip_text = true
	year_label.text = "%s   •   Your next chapter awaits" % ("%d BCE" % absi(gs.year) if gs.year < 0 else str(gs.year))
	year_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	year_label.clip_text = true
	chapter.text = "Life journal" if last_panel == "life" else last_panel.capitalize()

func _layout_tools() -> void:
	var stack_index := 0
	var adapter := host.get_node("EraInterface")
	for key in TOOL_LABELS:
		var button := host.get(key + "_hud_button") as Button
		if not is_instance_valid(button):
			continue
		# Clip and set the font before replacing an icon with a word. Otherwise
		# the old 28px font expands the minimum size and shifts right-anchored buttons.
		adapter.style_tool_button(button, TOOL_LABELS[key])
		button.focus_mode = Control.FOCUS_ALL
		if not button.is_visible_in_tree():
			continue
		button.modulate = Color.WHITE
		layout_tool_button(button, stack_index, host.get_viewport_rect().size)
		stack_index += 1
	var bending_border := host.get("bending_hud_button_border_overlay") as Control
	if is_instance_valid(bending_border):
		bending_border.hide()
	var crime := host.get("crime_hud_button") as Button
	if is_instance_valid(crime):
		crime.text = "Crime & justice"
		crime.custom_minimum_size.y = 40

static func tool_rows_per_column(viewport: Vector2) -> int:
	var usable_height := maxf(TOOL_SIZE.y, viewport.y - TOOL_BOTTOM - TOOL_TOP)
	return maxi(1, int(floor((usable_height + TOOL_GAP) / (TOOL_SIZE.y + TOOL_GAP))))

static func layout_tool_button(button: Button, stack_index: int, viewport: Vector2) -> void:
	if not is_instance_valid(button):
		return
	if button.get_meta("era_mobile_tool", false):
		return
	var index := maxi(0, stack_index)
	var rows := tool_rows_per_column(viewport)
	var column := int(floor(float(index) / rows))
	var row := index % rows
	var right := -TOOL_RIGHT - column * (TOOL_SIZE.x + TOOL_GAP)
	var bottom := -TOOL_BOTTOM - row * (TOOL_SIZE.y + TOOL_GAP)
	button.clip_text = true
	button.custom_minimum_size = TOOL_SIZE
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button.scale = Vector2.ONE
	button.rotation = 0.0
	button.pivot_offset = TOOL_SIZE * 0.5
	# Assign size before position and restore the whole rectangle. Individual
	# offset writes can retain shifts caused by a previous minimum-size change.
	button.size = TOOL_SIZE
	button.position = viewport + Vector2(right, bottom) - TOOL_SIZE
	button.set_meta("runtime_floating_hud_stack_index", index)
	button.set_meta("runtime_floating_hud_stack_row", row)
	button.set_meta("runtime_floating_hud_stack_column", column)
	button.set_meta("runtime_floating_hud_rows_per_column", rows)
	button.set_meta("runtime_floating_hud_stack_slot_top", bottom - TOOL_SIZE.y)
	button.set_meta("runtime_floating_hud_stack_slot_bottom", bottom)
	button.set_meta("runtime_floating_hud_stack_horizontal_gap", TOOL_GAP)
	button.set_meta("runtime_floating_hud_stack_vertical_gap", TOOL_GAP)
	button.set_meta("runtime_floating_hud_stack_geometry_resolved", true)
	button.set_meta("runtime_floating_hud_stack_geometry_resolved_at_ms", Time.get_ticks_msec())
	button.set_meta("runtime_floating_hud_never_requires_fullscreen", true)
	if MobileSupport.is_enabled():
		button.set_meta("mobile_stack_viewport", viewport)
		button.set_meta("mobile_stack_rect", button.get_rect())

static func layout_live(scene: Control) -> void:
	if MobileSupport.is_enabled():
		var mobile := scene.get_node_or_null("EraShell")
		if mobile != null and mobile.has_method("layout_mobile"):
			mobile.layout_mobile()
		return
	var root := scene.get_node_or_null("UIContainer") as Control
	if root == null:
		return
	var viewport := scene.get_viewport_rect().size
	var narrow := viewport.x < 1000
	var left := 16.0 if narrow else 288.0
	var tool_count := 0
	for key in TOOL_LABELS:
		var button := scene.get(key + "_hud_button") as Button
		if is_instance_valid(button) and button.is_visible_in_tree():
			tool_count += 1
	var columns := maxi(1, int(ceil(float(tool_count) / tool_rows_per_column(viewport))))
	var right := viewport.x - TOOL_RIGHT - columns * (TOOL_SIZE.x + TOOL_GAP)
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(left, 18)
	root.size = Vector2(maxf(280, right - left), viewport.y - 36)
	root.custom_minimum_size = Vector2.ZERO
	var diary: RichTextLabel = scene.get("output_label")
	if is_instance_valid(diary):
		diary.custom_minimum_size = Vector2.ZERO
		diary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		diary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diary.scroll_active = true
		if not diary.has_meta("era_journal"):
			diary.set_meta("era_journal", true)
			var paper := Design.box(Design.PANEL, Design.LINE, 6, 24)
			paper.content_margin_top = 22
			paper.content_margin_bottom = 22
			diary.add_theme_stylebox_override("normal", paper)
