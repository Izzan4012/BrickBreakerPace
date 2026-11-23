extends Sprite2D
## Power-up yang jatuh. Gerakan jatuh diatur dari game.gd.

const ICON_SIZE := 44.0

var type: String = "multiball"
var _t: float = 0.0


func setup(t: String) -> void:
	type = t
	texture = Global.tex("pu_" + t)
	var s: float = ICON_SIZE / maxf(texture.get_width(), texture.get_height())
	scale = Vector2(s, s)


func _process(delta: float) -> void:
	_t += delta
	rotation = sin(_t * 4.0) * 0.18
	self_modulate = Color.WHITE * (1.0 + 0.25 * sin(_t * 8.0))


func hit_rect() -> Rect2:
	return Rect2(position - Vector2(20, 20), Vector2(40, 40))
