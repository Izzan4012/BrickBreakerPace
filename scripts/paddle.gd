extends Node2D
## Paddle pemain. Posisi = titik tengah.

const DRAW_HEIGHT := 34.0

var width: float = 130.0
var height: float = 20.0
var sprite: Sprite2D

var _target_width: float = 130.0
var _bump: float = 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	add_child(sprite)
	set_skin("paddle_blue")


func set_skin(tex_name: String) -> void:
	var t: Texture2D = Global.tex(tex_name)
	if sprite.texture != t:
		sprite.texture = t
		_apply_scale()


func set_target_width(w: float) -> void:
	_target_width = w


func _process(delta: float) -> void:
	if not is_equal_approx(width, _target_width):
		width = move_toward(width, _target_width, 300.0 * delta)
		_apply_scale()
	_bump = move_toward(_bump, 0.0, delta * 6.0)
	sprite.position.y = _bump * 5.0


func _apply_scale() -> void:
	var t: Texture2D = sprite.texture
	if t == null:
		return
	sprite.scale = Vector2(width / (t.get_width() * 0.92), DRAW_HEIGHT / t.get_height())


func get_hit_rect() -> Rect2:
	return Rect2(position.x - width * 0.5, position.y - height * 0.5, width, height)


func bump() -> void:
	_bump = 1.0
