extends CanvasLayer
## Present existing OptionButton choices in the same viewport as the phone UI.
const Design = preload("res://ui/EraTheme.gd")
var host: Control
var sheet: PanelContainer
var list: VBoxContainer
var scroll: ScrollContainer
var title: Label
var source: OptionButton

func _ready() -> void:
	host = get_parent() as Control
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_watch)
	_watch_tree(host)
	set_process(false)

func _watch_tree(node: Node) -> void:
	_watch(node)
	for child in node.get_children():
		_watch_tree(child)

func _watch(node: Node) -> void:
	if node is OptionButton and host.is_ancestor_of(node):
		var callback := _request_open.bind(node)
		if not node.get_popup().about_to_popup.is_connected(callback):
			node.get_popup().about_to_popup.connect(callback)

func _request_open(option: OptionButton) -> void:
	# PopupMenu finishes opening after about_to_popup. Replace it before drawing.
	open.call_deferred(option)

func open(option: OptionButton) -> void:
	if not is_instance_valid(option):
		return
	option.get_popup().hide()
	if option.disabled or not option.is_visible_in_tree():
		return
	close()
	source = option
	sheet = PanelContainer.new()
	sheet.name = "MobileOptionSheet"
	sheet.theme = Design.create()
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sheet)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	sheet.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	margin.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	var back := Button.new()
	back.text = "‹ Back"
	back.custom_minimum_size = Vector2(88, 48)
	back.pressed.connect(close)
	header.add_child(back)
	title = Label.new()
	title.text = "Choose an option"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var selected: Button
	for index in option.item_count:
		if option.is_item_separator(index):
			var separator := Label.new()
			separator.text = option.get_item_text(index)
			list.add_child(separator)
			continue
		var button := Button.new()
		button.text = option.get_item_text(index)
		button.icon = option.get_item_icon(index)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = option.is_item_disabled(index)
		button.set_meta("option_index", index)
		button.toggle_mode = true
		button.button_pressed = index == option.selected
		button.pressed.connect(_select.bind(index))
		list.add_child(button)
		if index == option.selected:
			selected = button
	_layout()
	set_process(true)
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(selected):
		scroll.ensure_control_visible(selected)

func _select(index: int) -> void:
	if not is_instance_valid(source) or source.disabled or index >= source.item_count or source.is_item_disabled(index):
		return
	var option := source
	close()
	option.select(index)
	option.item_selected.emit(index)

func close() -> void:
	set_process(false)
	source = null
	if is_instance_valid(sheet):
		sheet.hide()
		sheet.queue_free()
	sheet = null

func handle_back() -> bool:
	if not is_instance_valid(sheet):
		return false
	close()
	return true

func _process(_delta: float) -> void:
	if not is_instance_valid(source) or not source.is_visible_in_tree():
		close()
		return
	_layout()

func _layout() -> void:
	var safe := MobileSupport.safe_viewport_rect(host)
	sheet.position = safe.position
	sheet.size = safe.size
