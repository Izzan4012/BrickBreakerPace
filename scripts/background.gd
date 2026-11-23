extends Node2D
## Latar neon: lantai grid bergerak, partikel kotak melayang, dan bingkai arena.

const ARENA := Rect2(260, 24, 760, 690)
const SCREEN := Vector2(1280, 720)
const DOT_COLORS := [Color(0.2, 0.85, 1.0), Color(1.0, 0.25, 0.75), Color(1.0, 0.85, 0.2), Color(0.6, 0.35, 1.0)]

var _dots: Array = []
var _t: float = 0.0


func _ready() -> void:
	z_index = -10
	for i in 46:
		_dots.append({
			"p": Vector2(randf() * SCREEN.x, randf() * SCREEN.y),
			"v": randf_range(6.0, 22.0),
			"s": randf_range(2.0, 5.0),
			"c": DOT_COLORS.pick_random(),
			"a": randf_range(0.25, 0.8),
		})


func _process(delta: float) -> void:
	_t += delta
	for d in _dots:
		var p: Vector2 = d["p"]
		p.y -= float(d["v"]) * delta
		if p.y < -10.0:
			p = Vector2(randf() * SCREEN.x, SCREEN.y + 10.0)
		d["p"] = p
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.008, 0.012, 0.04))

	# Lantai grid perspektif
	var horizon := 420.0
	var grid_col := Color(0.12, 0.35, 0.95)
	for i in range(-14, 15):
		draw_line(Vector2(640.0 + i * 16.0, horizon), Vector2(640.0 + i * 130.0, SCREEN.y), Color(grid_col, 0.16), 1.0)
	var shift := fmod(_t * 0.35, 1.0)
	for j in 12:
		var f := pow((float(j) + shift) / 12.0, 2.0)
		var y := horizon + (SCREEN.y - horizon) * f
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y), Color(grid_col, 0.05 + 0.2 * f), 1.0)

	# Partikel kotak
	for d in _dots:
		var c: Color = d["c"]
		var s: float = d["s"]
		draw_rect(Rect2(d["p"], Vector2(s, s)), Color(c, float(d["a"])))

	# Arena
	draw_rect(ARENA, Color(0.015, 0.03, 0.09, 0.93))
	var x := ARENA.position.x + 40.0
	while x < ARENA.end.x:
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.3, 0.6, 1.0, 0.035), 1.0)
		x += 40.0
	var yy := ARENA.position.y + 40.0
	while yy < ARENA.end.y:
		draw_line(Vector2(ARENA.position.x, yy), Vector2(ARENA.end.x, yy), Color(0.3, 0.6, 1.0, 0.035), 1.0)
		yy += 40.0
	for k in [[14.0, 0.05], [7.0, 0.12], [3.5, 0.3]]:
		draw_rect(ARENA, Color(0.2, 0.8, 1.0, k[1]), false, k[0])
	draw_rect(ARENA, Color(0.5, 0.92, 1.0, 0.95), false, 2.0)

	# Aksen magenta di sisi luar (seperti splash)
	draw_line(Vector2(10, 380), Vector2(10, 690), Color(1.0, 0.2, 0.7, 0.8), 3.0)
	draw_line(Vector2(1270, 380), Vector2(1270, 690), Color(1.0, 0.2, 0.7, 0.8), 3.0)
	var frame := PackedVector2Array([
		Vector2(30, 6), Vector2(1250, 6), Vector2(1274, 30), Vector2(1274, 690),
		Vector2(1250, 714), Vector2(30, 714), Vector2(6, 690), Vector2(6, 30), Vector2(30, 6),
	])
	draw_polyline(frame, Color(0.2, 0.8, 1.0, 0.35), 2.0)
