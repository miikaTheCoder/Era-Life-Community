extends SceneTree

var failures: Array[String] = []
var clicks := 0
var screen: Control
var scroll: ScrollContainer

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _touch(point: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await process_frame

func _swipe(control: Control, movement := Vector2(0, -120), canceled := false) -> void:
	var start := control.get_global_rect().get_center()
	await _touch(start, true)
	for step in range(1, 9):
		var event := InputEventScreenDrag.new()
		event.position = root.get_final_transform() * (start + movement * step / 8.0)
		event.relative = root.get_final_transform().basis_xform(movement / 8.0)
		Input.parse_input_event(event)
		await create_timer(0.02).timeout
	await _touch(start + movement, false, canceled)
	await create_timer(0.05).timeout

func _run() -> void:
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	screen = Control.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.emulate_mouse_from_touch = true
	if "--without-mobile-scroll" not in OS.get_cmdline_user_args():
		MobileSupport.configure(screen)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(40, 40)
	scroll.size = Vector2(500, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 150
	content.add_child(spacer)
	var button := Button.new()
	button.text = "A swipe must not click me"
	button.pressed.connect(func(): clicks += 1)
	var edit := LineEdit.new()
	edit.text = "Keep this name"
	var picker := OptionButton.new()
	picker.add_item("First")
	picker.add_item("Second")
	var check := CheckBox.new()
	check.text = "A swipe must not toggle me"
	var slider := HSlider.new()
	slider.value = 50
	var label := Label.new()
	label.text = "Non-interactive text"
	var panel := PanelContainer.new()
	var widgets: Array[Control] = [button, edit, picker, check, slider, label, panel]
	for widget in widgets:
		widget.custom_minimum_size.y = 60
		content.add_child(widget)
	var bottom := Control.new()
	bottom.custom_minimum_size.y = 1200
	content.add_child(bottom)
	await create_timer(0.1).timeout
	for widget in widgets:
		scroll.scroll_vertical = int(widget.position.y - 220)
		await create_timer(0.1).timeout
		var before := scroll.scroll_vertical
		await _swipe(widget)
		_check(scroll.scroll_vertical > before + 50, "Swipe over %s did not scroll" % widget.get_class())
		_check(clicks == 0, "Scrolling activated a button")
		_check(not picker.get_popup().visible, "Scrolling opened a dropdown")
		picker.get_popup().hide()
		_check(not check.button_pressed, "Scrolling toggled a checkbox")
		_check(slider.value == 50, "Vertical scrolling changed a slider")
		_check(edit.text == "Keep this name", "Scrolling changed text")
		if widget == edit:
			_check(not edit.is_editing(), "A name-field swipe entered text editing")
			_check(edit.virtual_keyboard_enabled, "Swipe left the keyboard disabled")
		# End any flick before positioning the next test's target.
		await _touch(Vector2(900, 500), true)
		await _touch(Vector2(900, 500), false)
	# A genuine tap still takes the native input path exactly once.
	scroll.scroll_vertical = 0
	await create_timer(0.1).timeout
	await _touch(button.get_global_rect().get_center(), true)
	await _touch(button.get_global_rect().get_center(), false)
	await process_frame
	_check(clicks == 1, "A button tap should activate exactly once")
	scroll.ensure_control_visible(edit)
	await create_timer(0.1).timeout
	await _touch(edit.get_global_rect().get_center(), true)
	_check(not edit.is_editing(), "Name field entered editing before the tap ended")
	await _touch(edit.get_global_rect().get_center(), false)
	await process_frame
	_check(edit.is_editing() and edit.virtual_keyboard_enabled, "A name-field tap did not enable editing")
	edit.release_focus()
	scroll.ensure_control_visible(picker)
	await create_timer(0.1).timeout
	await _touch(picker.get_global_rect().get_center(), true)
	_check(not picker.get_popup().visible, "Dropdown opened before the tap ended")
	await _touch(picker.get_global_rect().get_center(), false)
	await process_frame
	_check(picker.get_popup().visible, "A dropdown tap did not open its popup")
	picker.get_popup().hide()
	scroll.scroll_vertical = int(slider.position.y - 220)
	await create_timer(0.1).timeout
	var before := scroll.scroll_vertical
	await _swipe(slider, Vector2(120, 0))
	_check(slider.value > 60, "Horizontal slider drag stopped working")
	_check(scroll.scroll_vertical == before, "Horizontal slider drag scrolled the form")
	scroll.scroll_vertical = 0
	await create_timer(0.1).timeout
	await _touch(button.get_global_rect().get_center(), true)
	await _touch(button.get_global_rect().get_center(), false, true)
	await process_frame
	_check(clicks == 1, "Canceled touch activated a button")
	# The gameplay diary is itself a scrollable RichTextLabel, without a container.
	var diary := RichTextLabel.new()
	diary.position = Vector2(580, 40)
	diary.size = Vector2(330, 420)
	diary.selection_enabled = true
	diary.text = "Swipe the diary text\n".repeat(100)
	screen.add_child(diary)
	await create_timer(0.1).timeout
	await _swipe(diary)
	_check(diary.get_v_scroll_bar().value > 50, "Diary text swipe did not scroll")
	_check(diary.get_selected_text().is_empty(), "Diary swipe selected text instead of scrolling")
	screen.queue_free()
	await process_frame
	print("MOBILE SCROLL TESTS: ", "PASS" if failures.is_empty() else "FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)
