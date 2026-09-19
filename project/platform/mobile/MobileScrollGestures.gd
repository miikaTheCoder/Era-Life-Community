extends Node

## Own touch gestures inside scrollable content before child controls act on them.
## Godot 4.4 sends the emulated mouse event before its corresponding touch event.
## Defer the mouse press until we know this is a tap or a horizontal control drag.
const DRAG_THRESHOLD := 12.0
const FLICK_DECELERATION := 2200.0

enum Gesture { NONE, PENDING, SCROLL, CONTROL }
var gesture := Gesture.NONE
var surface: Control
var target: Control
var press_event: InputEventMouseButton
var start_position := Vector2.ZERO
var previous_position := Vector2.ZERO
var velocity := Vector2.ZERO
var last_motion_ms := 0
var suppress_touch := false
var touch_index := -1
var replaying := false
var text_fields: Array[WeakRef] = []
var muted_keyboards: Array[LineEdit] = []


func _ready() -> void:
	get_tree().node_added.connect(_watch_node)
	_watch_branch(get_parent())
	set_process(false)


func _watch_branch(node: Node) -> void:
	_watch_node(node)
	for child in node.get_children():
		_watch_branch(child)


func _watch_node(node: Node) -> void:
	if node is Control and get_parent().is_ancestor_of(node) and node.get_viewport() == get_viewport():
		var callback := _on_control_input.bind(node)
		if not node.gui_input.is_connected(callback):
			node.gui_input.connect(callback)
			if node is LineEdit:
				text_fields.append(weakref(node))


func _defer_touch_keyboard_focus() -> void:
	# Viewport grants focus before gui_input. On Android, LineEdit opens the
	# keyboard at that point, even if we then accept the press as a possible swipe.
	# Mute only this event's focus transition; a confirmed tap replays normally.
	for index in range(text_fields.size() - 1, -1, -1):
		var field := text_fields[index].get_ref() as LineEdit
		if field == null:
			text_fields.remove_at(index)
		elif field.is_visible_in_tree() and not field.has_focus() and field.virtual_keyboard_enabled and _scroll_surface(field) != null:
			field.virtual_keyboard_enabled = false
			muted_keyboards.append(field)
	_restore_touch_keyboards.call_deferred()


func _restore_touch_keyboards() -> void:
	for field in muted_keyboards:
		if not is_instance_valid(field):
			continue
		var resume_editing := field.is_editing()
		if resume_editing:
			field.unedit()
		field.virtual_keyboard_enabled = true
		if resume_editing:
			field.edit()
	muted_keyboards.clear()


func _scroll_surface(control: Control) -> Control:
	# Scrollbar thumbs retain their native drag behavior.
	if control is ScrollBar:
		return null
	var current: Node = control
	while current is Control:
		if current is ScrollContainer or (current is RichTextLabel and current.scroll_active):
			var bars := _bars(current)
			for bar in bars:
				if bar != null and bar.max_value - bar.page > bar.min_value:
					return current
		current = current.get_parent()
	return null


func _bars(control: Control) -> Array:
	if control is ScrollContainer:
		return [
			control.get_h_scroll_bar() if control.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED else null,
			control.get_v_scroll_bar() if control.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED else null,
		]
	if control is RichTextLabel:
		return [null, control.get_v_scroll_bar()]
	return [null, null]


func _on_control_input(event: InputEvent, control: Control) -> void:
	if replaying or gesture != Gesture.NONE:
		return
	if not event is InputEventMouseButton or event.device != InputEvent.DEVICE_ID_EMULATION:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var candidate := _scroll_surface(control)
	if candidate == null:
		return
	surface = candidate
	target = control
	press_event = event.xformed_by(control.get_global_transform_with_canvas()) as InputEventMouseButton
	start_position = press_event.position
	previous_position = start_position
	velocity = Vector2.ZERO
	last_motion_ms = Time.get_ticks_msec()
	gesture = Gesture.PENDING
	suppress_touch = true
	touch_index = -1
	if control is LineEdit and control in muted_keyboards:
		control.unedit()
	control.accept_event()


func _input(event: InputEvent) -> void:
	if replaying:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if suppress_touch:
			# Do not also run the legacy ScreenDrag handlers (double scrolling).
			get_viewport().set_input_as_handled()
			if event is InputEventScreenTouch:
				if event.pressed and touch_index == -1:
					touch_index = event.index
				elif not event.pressed and event.index == touch_index:
					suppress_touch = false
		return
	if not event is InputEventMouse or event.device != InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.pressed:
		set_process(false)
		velocity = Vector2.ZERO
		if gesture == Gesture.NONE and event.button_index == MOUSE_BUTTON_LEFT:
			_defer_touch_keyboard_focus()
	if gesture == Gesture.NONE:
		return
	if not is_instance_valid(surface) or not surface.is_visible_in_tree() or not is_instance_valid(target) or not target.is_visible_in_tree():
		gesture = Gesture.NONE
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var distance: Vector2 = event.position - start_position
		if gesture == Gesture.PENDING and distance.length() >= DRAG_THRESHOLD:
			var horizontal_control := target is HSlider or target is LineEdit or target.get_parent() is SpinBox
			if horizontal_control and absf(distance.x) > absf(distance.y):
				gesture = Gesture.CONTROL
				_send_mouse(press_event)
			else:
				gesture = Gesture.SCROLL
				surface.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
				if surface is ScrollContainer:
					surface.scroll_started.emit()
				# The delayed press has not edited, toggled or opened any control.
		if gesture == Gesture.CONTROL:
			return
		if gesture == Gesture.SCROLL:
			var delta: Vector2 = event.position - previous_position
			_move_scroll(-delta)
			var now := Time.get_ticks_msec()
			velocity = (-delta / maxf(float(now - last_motion_ms) / 1000.0, 0.001)).limit_length(2400)
			last_motion_ms = now
		previous_position = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var completed := gesture
		gesture = Gesture.NONE
		if completed == Gesture.CONTROL:
			return
		get_viewport().set_input_as_handled()
		if completed == Gesture.PENDING and not event.canceled:
			_replay_tap.call_deferred(press_event, target)
		elif completed == Gesture.SCROLL:
			surface.propagate_notification(Control.NOTIFICATION_SCROLL_END)
			if surface is ScrollContainer:
				surface.scroll_ended.emit()
			if not event.canceled and Time.get_ticks_msec() - last_motion_ms < 100:
				set_process(true)


func _move_scroll(delta: Vector2) -> void:
	var bars := _bars(surface)
	for axis in range(2):
		var bar: Range = bars[axis]
		if bar != null:
			bar.value = clampf(bar.value + delta[axis], bar.min_value, maxf(bar.min_value, bar.max_value - bar.page))


func _process(delta: float) -> void:
	if not is_instance_valid(surface) or not surface.is_visible_in_tree() or velocity.length() < 5:
		set_process(false)
		return
	_move_scroll(velocity * delta)
	velocity = velocity.move_toward(Vector2.ZERO, FLICK_DECELERATION * delta)


func _replay_tap(press: InputEventMouseButton, control: Control) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return
	# Preserve the original hit position, and don't click through a moved/closed UI.
	if not control.get_global_rect().has_point(press.position):
		return
	_send_mouse(press)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.button_mask = 0
	_send_mouse(release)


func _send_mouse(event: InputEventMouseButton) -> void:
	replaying = true
	get_viewport().push_input(event.duplicate(), true)
	replaying = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		gesture = Gesture.NONE
		suppress_touch = false
		set_process(false)
