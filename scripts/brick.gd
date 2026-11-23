extends Sprite2D
## Satu brick. Posisi = titik tengah.

const BODY := Vector2(78, 32)        # area tabrakan
const DRAW_SIZE := Vector2(90, 42)   # ukuran gambar (termasuk glow)

var kind: String = "b"
var hp: int = 1
var breakable: bool = true
var always_drop: bool = false
var points: int = 50
var color: Color = Color.WHITE
var crack_tex: String = ""


func setup(k: String) -> void:
	kind = k
	match k:
		"b": _configure("brick_blue", 1, Color(0.25, 0.55, 1.0), 50)
		"p": _configure("brick_purple", 1, Color(0.7, 0.3, 1.0), 50)
		"g": _configure("brick_green", 1, Color(0.3, 1.0, 0.35), 50)
		"o": _configure("brick_orange", 1, Color(1.0, 0.65, 0.1), 50)
		"r": _configure("brick_red", 1, Color(1.0, 0.2, 0.25), 50)
		"B":
			_configure("brick_blue", 2, Color(0.25, 0.55, 1.0), 100)
			crack_tex = "brick_blue_crack"
		"P":
			_configure("brick_purple", 2, Color(0.7, 0.3, 1.0), 100)
			crack_tex = "brick_purple_crack"
		"S":
			_configure("brick_steel", 3, Color(0.7, 0.8, 1.0), 150)
			crack_tex = "brick_steel_crack"
		"X":
			_configure("brick_hazard", 1, Color(1.0, 0.75, 0.1), 0)
			breakable = false
		"*":
			_configure("brick_star", 1, Color(1.0, 0.75, 0.15), 100)
			always_drop = true
		_:
			_configure("brick_blue", 1, Color(0.25, 0.55, 1.0), 50)


func _configure(tex_name: String, new_hp: int, c: Color, pts: int) -> void:
	_set_texture(tex_name)
	hp = new_hp
	color = c
	points = pts


func _set_texture(tex_name: String) -> void:
	texture = Global.tex(tex_name)
	scale = DRAW_SIZE / texture.get_size()


func hit_rect() -> Rect2:
	return Rect2(position - BODY * 0.5, BODY)


## Kembalikan true kalau brick hancur.
func hit(dmg: int) -> bool:
	if not breakable:
		flash()
		return false
	hp -= dmg
	if hp <= 0:
		return true
	if crack_tex != "":
		_set_texture(crack_tex)
	if kind == "S" and hp == 1:
		self_modulate = Color(1.0, 0.75, 0.75)
	flash()
	return false


func flash() -> void:
	var base := self_modulate
	self_modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(self, "self_modulate", base, 0.15)


func die() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.3, 0.14)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(queue_free)
