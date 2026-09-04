extends Control
## A life branching into possible futures; native vector drawing at any scale.
const Design = preload("res://ui/EraTheme.gd")
var branch := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(100, 86)
	resized.connect(queue_redraw)

func _draw() -> void:
	var y := size.y * 0.5
	var width := minf(size.x - 16, 240)
	var points := PackedVector2Array([Vector2(8, y), Vector2(width * 0.4, y), Vector2(width * 0.66, y - 24), Vector2(width, y - 24)])
	draw_polyline(points, Design.ACCENT, 2, true)
	draw_polyline(PackedVector2Array([Vector2(width * 0.4, y), Vector2(width * 0.66, y + 24), Vector2(width, y + 24)]), Design.LINE, 2, true)
	draw_circle(Vector2(8, y), 4, Design.AMBER)
	for offset in [-24, 24]:
		draw_circle(Vector2(width, y + offset), 5, Design.ACCENT if offset == -24 else Design.MUTED, false, 1.5, true)
	if branch == 1:
		draw_circle(Vector2(width * 0.4, y), 6, Design.PANEL)
		draw_circle(Vector2(width * 0.4, y), 5, Design.AMBER, false, 1.5, true)
	elif branch == 2:
		draw_line(Vector2(width * 0.66, y - 32), Vector2(width * 0.66, y + 32), Design.AMBER, 1, true)
