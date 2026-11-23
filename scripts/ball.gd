extends Node2D
## Bola. Gerakan dan tabrakan diatur dari game.gd.

const TRAIL_LENGTH := 12

var velocity: Vector2 = Vector2.ZERO
var radius: float = 10.0
var stuck: bool = false
var stick_offset: float = 0.0

var sprite: Sprite2D
var trail: Line2D
var _trail_pts: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 18.0
	trail.z_index = -1
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.55))
	trail.gradient = g
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.15))
	c.add_point(Vector2(1.0, 1.0))
	trail.width_curve = c
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	trail.material = mat
	add_child(trail)

	sprite = Sprite2D.new()
	add_child(sprite)
	set_look("ball_blue", Color(0.3, 0.7, 1.0))


func set_look(tex_name: String, trail_color: Color) -> void:
	var t: Texture2D = Global.tex(tex_name)
	sprite.texture = t
	# Badan bola kira-kira 78% dari lebar gambar (sisanya glow)
	sprite.scale = Vector2.ONE * (radius * 2.0 / (t.get_width() * 0.78))
	trail.modulate = trail_color


func _process(delta: float) -> void:
	sprite.rotation += delta * 2.0


func update_trail() -> void:
	_trail_pts.append(global_position)
	if _trail_pts.size() > TRAIL_LENGTH:
		_trail_pts.remove_at(0)
	trail.points = _trail_pts


func clear_trail() -> void:
	_trail_pts.clear()
	trail.points = _trail_pts
