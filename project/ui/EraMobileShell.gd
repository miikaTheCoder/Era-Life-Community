extends Node
## Portrait presentation. Existing buttons retain their actions and availability.
const Design = preload("res://ui/EraTheme.gd")
const DesktopShell = preload("res://ui/EraShell.gd")
const TOOL_LABELS := DesktopShell.TOOL_LABELS
var host: Control
var page: Control
var header: VBoxContainer
var name_label: Label
var detail_label: Label
var money_label: Label
var chapter: HBoxContainer
var year_label: Label
var dock: HBoxContainer
var dock_slots: Array[VBoxContainer] = []
var assets_button: Button
var metrics: GridContainer
var metric_nodes: Dictionary = {}
var drawer: PanelContainer
var drawer_scroll: ScrollContainer
var drawer_list: VBoxContainer
var drawer_title: Label
var drawer_mode := ""
var stat_scroll: ScrollContainer
var stat_slot: VBoxContainer
var last_summary := ""
var last_panel := ""

func _ready() -> void:
	host = get_parent() as Control
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1001

func _label(text: String, font_size: int, color: Color = Design.TEXT) -> Label:
	return DesktopShell.label(text, font_size, color)

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	return button

func _build() -> void:
	header = VBoxContainer.new()
	header.name = "EraMobileHeader"
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	page.move_child(header, 0)
	var brand_row := HBoxContainer.new()
	header.add_child(brand_row)
	var brand := _button("ERA / LIFE", _return_to_journal)
	brand.set_meta("era_owned", true)
	brand.flat = true
	brand.alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_color_override("font_color", Design.ACCENT)
	brand.add_theme_font_size_override("font_size", 19)
	brand_row.add_child(brand)
	var menu := _button("Menu", func(): open_drawer("explore"))
	menu.name = "EraMobileMenu"
	menu.custom_minimum_size.x = 68
	brand_row.add_child(menu)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 10)
	header.add_child(identity)
	var portrait := _button("Me", func(): open_drawer("character"))
	portrait.name = "EraMobileCharacter"
	portrait.custom_minimum_size = Vector2(48, 48)
	identity.add_child(portrait)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 3)
	identity.add_child(names)
	name_label = _label("Your life", 20)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(name_label)
	detail_label = _label("", 12, Design.MUTED)
	detail_label.clip_text = true
	names.add_child(detail_label)
	var balance := VBoxContainer.new()
	identity.add_child(balance)
	money_label = _label("", 15, Design.ACCENT)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money_label.custom_minimum_size.x = 102
	money_label.clip_text = true
	balance.add_child(money_label)
	var balance_caption := _label("BALANCE", 10, Design.MUTED)
	balance_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance.add_child(balance_caption)
	chapter = HBoxContainer.new()
	chapter.name = "EraMobileChapter"
	chapter.custom_minimum_size.y = 36
	page.add_child(chapter)
	page.move_child(chapter, 1)
	var journal := DesktopShell.label("Life journal", 24, Design.TEXT, true)
	journal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter.add_child(journal)
	year_label = _label("", 13, Design.AMBER)
	chapter.add_child(year_label)
	metrics = GridContainer.new()
	metrics.name = "EraMobileStats"
	metrics.columns = 2
	metrics.add_theme_constant_override("h_separation", 18)
	metrics.add_theme_constant_override("v_separation", 8)
	page.add_child(metrics)
	for key in ["health", "mental_health", "smarts", "looks"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 3)
		metrics.add_child(cell)
		var line := HBoxContainer.new()
		cell.add_child(line)
		var title := _label("Mood" if key == "mental_health" else key.capitalize(), 11, Design.MUTED)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(title)
		var value := _label("", 11)
		line.add_child(value)
		var bar := ProgressBar.new()
		bar.set_meta("stat_title", title.text)
		bar.show_percentage = false
		bar.custom_minimum_size.y = 5
		cell.add_child(bar)
		metric_nodes[key] = {"value": value, "bar": bar}
	dock = HBoxContainer.new()
	dock.name = "EraMobileDock"
	dock.add_theme_constant_override("separation", 4)
	dock.custom_minimum_size.y = 64
	page.add_child(dock)
	for i in range(5):
		var slot := VBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dock.add_child(slot)
		dock_slots.append(slot)
	assets_button = _button("Assets", _open_assets)
	assets_button.name = "EraMobileAssets"
	assets_button.set_meta("era_mobile_nav", true)
	dock_slots[1].add_child(assets_button)
	_build_drawer()

func _build_drawer() -> void:
	drawer = PanelContainer.new()
	drawer.name = "EraMobileDrawer"
	drawer.z_index = 110
	drawer.visible = false
	host.add_child(drawer)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	drawer.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var top := HBoxContainer.new()
	content.add_child(top)
	top.add_child(_button("‹ Back", close_drawer))
	drawer_title = _label("Explore your life", 21)
	drawer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(drawer_title)
	drawer_scroll = ScrollContainer.new()
	drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(drawer_scroll)
	drawer_list = VBoxContainer.new()
	drawer_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawer_list.add_theme_constant_override("separation", 10)
	drawer_scroll.add_child(drawer_list)
	stat_scroll = ScrollContainer.new()
	stat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(stat_scroll)
	stat_slot = VBoxContainer.new()
	stat_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_scroll.add_child(stat_slot)

func _process(_delta: float) -> void:
	page = host.get_node_or_null("UIContainer") as Control
	var gs = host.get("gs")
	if page == null or gs == null or gs.player == null or not page.visible:
		if is_instance_valid(drawer):
			close_drawer()
		return
	if not is_instance_valid(header):
		_build()
	layout_mobile()
	_update_summary(gs)

func layout_mobile() -> void:
	if not is_instance_valid(header):
		return
	var safe := MobileSupport.safe_viewport_rect(host)
	page.set_anchors_preset(Control.PRESET_TOP_LEFT)
	page.custom_minimum_size = Vector2.ZERO
	page.size = safe.size - Vector2(24, 16)
	page.position = safe.position + Vector2(12, 8)
	page.add_theme_constant_override("separation", 10)
	var gs = host.get("gs")
	var career_key := "school" if gs != null and gs.player != null and gs.player.age < 18 else "career"
	var nav: Dictionary = host.get("ui_nav_buttons")
	for key in nav:
		var button := nav[key] as Button
		if not is_instance_valid(button):
			continue
		var destination: Container = drawer_list
		if key == career_key:
			destination = dock_slots[0]
		elif key == "age_up":
			destination = dock_slots[2]
		elif key == "relationships":
			destination = dock_slots[3]
		elif key == "activities":
			destination = dock_slots[4]
		_place_button(button, destination, true)
		if key == "age_up":
			button.text = "+\nAge"
		elif key == "relationships":
			button.text = "People"
		elif key == "life":
			button.text = "Life journal"
		elif key in ["school", "career", "activities"]:
			button.text = key.capitalize()
		if not button.pressed.is_connected(close_drawer):
			button.pressed.connect(close_drawer)
		var selected: bool = key == str(host.get("current_panel"))
		if button.get_meta("era_selected", false) != selected:
			button.set_meta("era_selected", selected)
			host.get_node("EraInterface")._queue(button.get_instance_id())
	assets_button.custom_minimum_size = Vector2(0, 64)
	assets_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var assets := host.get("belongings_hud_button") as Button
	assets_button.disabled = not is_instance_valid(assets) or not assets.visible or assets.disabled
	for key in TOOL_LABELS:
		var tool := host.get(key + "_hud_button") as Button
		if not is_instance_valid(tool):
			continue
		tool.set_meta("era_mobile_tool", true)
		host.get_node("EraInterface").style_tool_button(tool, TOOL_LABELS[key])
		_place_button(tool, drawer_list, false)
		if not tool.pressed.is_connected(close_drawer):
			tool.pressed.connect(close_drawer)
	var border := host.get("bending_hud_button_border_overlay") as Control
	if is_instance_valid(border):
		border.hide()
	var stats := host.get("player_stats_overlay") as Control
	if is_instance_valid(stats):
		if stats.get_parent() != stat_slot:
			stats.reparent(stat_slot)
		stats.custom_minimum_size = Vector2(0, 580)
		stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.visible = true
		stats.mouse_filter = Control.MOUSE_FILTER_PASS
		stats.z_as_relative = true
		stats.z_index = 0
		stats.scale = Vector2.ONE
		stats.position = Vector2.ZERO
		stats.size.x = maxf(0, safe.size.x - 32)
	var diary := host.get("output_label") as RichTextLabel
	if is_instance_valid(diary):
		diary.custom_minimum_size = Vector2.ZERO
		diary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		diary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diary.fit_content = false
		diary.scroll_active = true
		diary.add_theme_font_size_override("normal_font_size", 15)
		diary.add_theme_font_size_override("bold_font_size", 15)
		if not diary.has_meta("era_mobile_journal"):
			diary.set_meta("era_mobile_journal", true)
			diary.add_theme_stylebox_override("normal", Design.box(Design.PANEL, Design.LINE, 6, 14))
		page.move_child(diary, 2)
	page.move_child(metrics, page.get_child_count() - 1)
	page.move_child(dock, page.get_child_count() - 1)
	drawer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	drawer.size = safe.size
	drawer.position = safe.position

func _place_button(button: Button, destination: Container, navigation: bool) -> void:
	if button.get_parent() != destination:
		button.reparent(destination)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.custom_minimum_size = Vector2(0, 64 if destination != drawer_list else 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL if destination != drawer_list else Control.SIZE_FILL
	button.scale = Vector2.ONE
	button.rotation = 0
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("era_mobile_nav", navigation and destination != drawer_list)
	# Keep the real modal/input layering, but avoid a floating HUD drawing over its own drawer.
	button.z_as_relative = true
	button.z_index = 0

func _update_summary(gs: GameState) -> void:
	var actor: Person = gs.player
	var summary := str([actor.id, actor.first_name, actor.last_name, actor.age, actor.job, actor.bank_balance, gs.year, actor.health, actor.mental_health, actor.smarts, actor.looks])
	if summary == last_summary:
		return
	last_summary = summary
	name_label.text = actor._display_name()
	var occupation := actor.job if not actor.job.is_empty() else "A life unfolding"
	detail_label.text = "Age %d  ·  %s" % [actor.age, occupation]
	money_label.text = str(host.call("_format_standard_tab_money", int(actor.bank_balance)))
	year_label.text = "%d BCE" % absi(gs.year) if gs.year < 0 else str(gs.year)
	for key in metric_nodes:
		var value := clampf(float(actor.get(key)), 0, 100)
		metric_nodes[key].value.text = "%d%%" % roundi(value)
		metric_nodes[key].bar.value = value

func open_drawer(mode: String) -> void:
	drawer_mode = mode
	drawer_title.text = "Your character" if mode == "character" else "Explore your life"
	stat_scroll.visible = mode == "character"
	drawer_scroll.visible = mode != "character"
	drawer.show()

func close_drawer() -> void:
	drawer_mode = ""
	if is_instance_valid(drawer):
		drawer.hide()

func handle_mobile_back() -> bool:
	var panels := host.get_node_or_null("EraMobilePanels")
	if panels != null and panels.handle_back():
		return true
	if is_instance_valid(drawer) and drawer.visible:
		close_drawer()
		return true
	if str(host.get("current_panel")) != "life":
		_return_to_journal()
		return true
	return false

func _return_to_journal() -> void:
	close_drawer()
	var button := host.get("ui_nav_buttons").get("life") as Button
	if is_instance_valid(button) and button.visible and not button.disabled:
		button.pressed.emit()

func _open_assets() -> void:
	var button := host.get("belongings_hud_button") as Button
	if is_instance_valid(button) and button.visible and not button.disabled:
		button.pressed.emit()
