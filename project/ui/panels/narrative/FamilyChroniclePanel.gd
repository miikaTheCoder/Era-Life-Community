extends AcceptDialog

const Design = preload("res://ui/EraTheme.gd")
var body: RichTextLabel

func _ready() -> void:
	title = "Family chronicle"
	name = "FamilyChronicle"
	get_ok_button().text = "Return to life"
	exclusive = true
	close_requested.connect(hide)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	body = RichTextLabel.new()
	body.name = "ChronicleTimeline"
	body.bbcode_enabled = false
	body.selection_enabled = true
	body.focus_mode = Control.FOCUS_ALL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_override("normal_font", Design.BODY)
	body.add_theme_font_override("bold_font", Design.BOLD)
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_color_override("default_color", Design.TEXT)
	body.add_theme_stylebox_override("normal", Design.box(Design.PANEL))
	margin.add_child(body)
	# AcceptDialog's internal button row does not discover sibling content when
	# traversing focus. Link the reading surface and return control explicitly.
	get_ok_button().focus_next = get_ok_button().get_path_to(body)
	get_ok_button().focus_previous = get_ok_button().get_path_to(body)
	body.focus_next = body.get_path_to(get_ok_button())
	body.focus_previous = body.get_path_to(get_ok_button())

func present(contract: Dictionary, viewport: Vector2) -> void:
	body.clear()
	body.push_font(Design.DISPLAY)
	body.push_font_size(28)
	body.add_text(str(contract.get("person", "")) + "\n")
	body.pop()
	body.pop()
	body.push_color(Design.MUTED)
	body.add_text("Choices remembered. Public family outcomes inherited.\n\n")
	body.pop()
	if not contract.get("pack_errors", []).is_empty():
		body.push_color(Design.ACCENT)
		body.add_text("Some community stories are unavailable (%d loading errors).\n" % contract.pack_errors.size())
		body.pop()
		for error in contract.pack_errors:
			body.add_text(str(error) + "\n")
		body.add_text("\n")
	if contract.get("entries", []).is_empty():
		body.add_text("There are no story memories yet. Keep living and respond to Life Stories in Pending Situations. Your choices will appear here.")
	for entry in contract.get("entries", []):
		body.push_color(Design.ACCENT)
		body.add_text("%d  /  %s\n" % [int(entry.year), str(entry.title)])
		body.pop()
		body.push_color(Design.MUTED)
		body.add_text(("Inherited from " if bool(entry.inherited) else "Remembered by ") + str(entry.person))
		if not str(entry.get("cast", "")).is_empty():
			body.add_text(" · with " + str(entry.cast))
		body.add_text("\n")
		body.pop()
		# add_text treats authored text and names literally, including BBCode-like input.
		body.add_text(str(entry.text) + "\n\n")
	if bool(contract.get("truncated", false)):
		body.add_text("Showing the latest 200 entries. Earlier history remains in your save.")
	# Deferred text/theme minimum-size updates can shrink a wrapped dialog after
	# opening. Keep the viewport-bounded reading area, including on later opens.
	min_size = Vector2i(minf(860, maxf(280, viewport.x - 32)), minf(680, maxf(240, viewport.y - 48)))
	popup_centered(min_size)
	body.scroll_to_line(0)
	get_ok_button().grab_focus()
