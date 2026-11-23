extends Node2D
## Logika utama Brick Breaker: level, bola, paddle, brick, power-up, skor, nyawa.

const BallScript := preload("res://scripts/ball.gd")
const PaddleScript := preload("res://scripts/paddle.gd")
const BrickScript := preload("res://scripts/brick.gd")
const PowerUpScript := preload("res://scripts/powerup.gd")
const LaserScript := preload("res://scripts/laser.gd")
const BackgroundScript := preload("res://scripts/background.gd")
const HudScript := preload("res://scripts/hud.gd")
const Levels := preload("res://scripts/levels.gd")

const SPLASH_SCENE := "res://scenes/splash.tscn"

const ARENA := Rect2(260, 24, 760, 690)
const CELL := Vector2(82, 36)
const COLS := 9
const GRID_TOP := 96.0
const PADDLE_Y := 668.0
const PADDLE_WIDTH := 130.0
const PADDLE_WIDE := 195.0
const PADDLE_KEY_SPEED := 820.0
const BASE_SPEED := 430.0
const MAX_SPEED := 720.0
const START_LIVES := 3
const MAX_LIVES := 5
const MAX_BALLS := 12
const DROP_CHANCE := 0.16
const POWERUP_FALL := 165.0
const LASER_SPEED := 900.0
const BOMB_RADIUS := 115.0
const SUBSTEP := 6.0

const EFFECT_TIME := {
	"laser": 8.0,
	"paddleup": 12.0,
	"slowtime": 8.0,
	"magnet": 12.0,
	"speedup": 8.0,
	"fireball": 6.0,
	"freeze": 1.5,
}

const POWERUP_WEIGHTS := {
	"multiball": 12,
	"laser": 9,
	"shield": 9,
	"paddleup": 11,
	"slowtime": 8,
	"magnet": 7,
	"extralife": 4,
	"bomb": 8,
	"speedup": 6,
	"fireball": 7,
	"freeze": 5,
	"random": 6,
}

enum State { READY, PLAYING, CLEAR, OVER }

var state: int = State.READY
var score: int = 0
var best_at_start: int = 0
var lives: int = START_LIVES
var level_index: int = 0
var paddle_hits: int = 0
var effects: Dictionary = {}
var shield_on: bool = false
var bomb_armed: bool = false
var keyboard_mode: bool = false
var laser_cooldown: float = 0.0
var shake_time: float = 0.0
var shake_strength: float = 0.0

var world: Node2D
var bricks_layer: Node2D
var fx_layer: Node2D
var paddle  # paddle.gd (Node2D)
var shield_line: Line2D
var hud  # hud.gd (CanvasLayer)
var fade: ColorRect

var bricks: Array = []
var balls: Array = []
var powerups: Array = []
var lasers: Array = []


# ================================================================ setup

func _ready() -> void:
	randomize()
	add_child(BackgroundScript.new())

	world = Node2D.new()
	add_child(world)
	bricks_layer = Node2D.new()
	world.add_child(bricks_layer)
	fx_layer = Node2D.new()
	world.add_child(fx_layer)

	shield_line = Line2D.new()
	shield_line.points = PackedVector2Array([
		Vector2(ARENA.position.x + 4, ARENA.end.y - 8),
		Vector2(ARENA.end.x - 4, ARENA.end.y - 8),
	])
	shield_line.width = 5.0
	shield_line.default_color = Color(0.35, 0.9, 1.0)
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	shield_line.material = add_mat
	shield_line.hide()
	world.add_child(shield_line)

	paddle = PaddleScript.new()
	paddle.position = Vector2(ARENA.get_center().x, PADDLE_Y)
	world.add_child(paddle)

	hud = HudScript.new()
	add_child(hud)
	hud.pause_pressed.connect(_pause)
	hud.resume_pressed.connect(_resume)
	hud.restart_pressed.connect(_restart)
	hud.home_pressed.connect(_go_home)
	hud.next_pressed.connect(_next_level)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.5)

	_new_game()


func _new_game() -> void:
	score = 0
	lives = START_LIVES
	best_at_start = Global.best_score
	hud.set_score(score)
	hud.set_best(Global.best_score)
	hud.set_lives(lives)
	_start_level(0)


func _start_level(index: int) -> void:
	level_index = index
	paddle_hits = 0
	_clear_dynamic()
	for b in bricks:
		b.queue_free()
	bricks.clear()

	var layout: Array = Levels.get_layout(index)
	var origin_x: float = ARENA.position.x + (ARENA.size.x - CELL.x * COLS) * 0.5 + CELL.x * 0.5
	for row in layout.size():
		var line: String = layout[row]
		for col in mini(line.length(), COLS):
			var ch: String = line[col]
			if ch == ".":
				continue
			var brick = BrickScript.new()
			bricks_layer.add_child(brick)
			brick.setup(ch)
			var target := Vector2(origin_x + col * CELL.x, GRID_TOP + row * CELL.y + CELL.y * 0.5)
			brick.position = target - Vector2(0, 40)
			brick.modulate = Color(1, 1, 1, 0)
			var tw: Tween = brick.create_tween()
			tw.tween_interval(row * 0.06 + col * 0.025)
			tw.tween_property(brick, "position", target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(brick, "modulate:a", 1.0, 0.3)
			bricks.append(brick)

	hud.set_level(_level_label())
	paddle.position = Vector2(ARENA.get_center().x, PADDLE_Y)
	_enter_ready()


func _enter_ready() -> void:
	state = State.READY
	for b in balls:
		b.queue_free()
	balls.clear()
	var ball = _spawn_ball()
	ball.stuck = true
	ball.stick_offset = 0.0
	_place_stuck(ball)
	_refresh_looks()
	create_tween().tween_property(bricks_layer, "modulate", Color(0.45, 0.45, 0.55), 0.3)
	hud.show_ready(_level_label())


func _clear_dynamic() -> void:
	for b in balls:
		b.queue_free()
	balls.clear()
	_clear_powerups_and_lasers()
	effects.clear()
	shield_on = false
	bomb_armed = false
	_refresh_looks()


func _clear_powerups_and_lasers() -> void:
	for p in powerups:
		p.queue_free()
	powerups.clear()
	for l in lasers:
		l.queue_free()
	lasers.clear()


func _level_label() -> String:
	var n: int = Levels.count()
	return "%d-%d" % [floori(float(level_index) / n) + 1, level_index % n + 1]


func _level_speed() -> float:
	var n: int = Levels.count()
	var world_i: int = floori(float(level_index) / n)
	var stage: int = level_index % n
	return minf(BASE_SPEED + stage * 14.0 + world_i * 50.0, MAX_SPEED - 80.0)


func _current_speed() -> float:
	var s: float = _level_speed() + minf(paddle_hits * 4.0, 90.0)
	if effects.has("slowtime"):
		s *= 0.62
	if effects.has("speedup"):
		s *= 1.3
	return minf(s, MAX_SPEED)


# ================================================================ input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		keyboard_mode = false
		return
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			keyboard_mode = false
			_launch()
		return
	var st := event as InputEventScreenTouch
	if st != null:
		if st.pressed:
			keyboard_mode = false
			_launch()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.keycode:
			KEY_SPACE, KEY_ENTER, KEY_UP, KEY_W:
				_launch()
			KEY_P, KEY_ESCAPE:
				_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING and not get_tree().paused:
		_pause()


func _launch() -> void:
	if state == State.READY:
		state = State.PLAYING
		hud.hide_ready()
		create_tween().tween_property(bricks_layer, "modulate", Color.WHITE, 0.25)
		Global.play_sfx("start")
	if state != State.PLAYING:
		return
	for ball in balls:
		if ball.stuck:
			ball.stuck = false
			var off: float = clampf(float(ball.stick_offset) / (paddle.width * 0.5), -1.0, 1.0)
			var ang: float = off * deg_to_rad(55.0) if absf(off) > 0.05 else randf_range(-0.3, 0.3)
			ball.velocity = Vector2(sin(ang), -cos(ang)) * _current_speed()


func _pause() -> void:
	if state == State.PLAYING or state == State.READY:
		get_tree().paused = true
		hud.show_pause()


func _resume() -> void:
	get_tree().paused = false
	hud.hide_pause()


func _restart() -> void:
	get_tree().paused = false
	hud.hide_all()
	_new_game()


func _next_level() -> void:
	hud.hide_all()
	_start_level(level_index + 1)


func _go_home() -> void:
	get_tree().paused = false
	Global.save_data()
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.4)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(SPLASH_SCENE))


# ================================================================ loop

func _process(delta: float) -> void:
	if state == State.PLAYING:
		_update_effects(delta)
	_update_paddle(delta)
	for ball in balls:
		if ball.stuck:
			_place_stuck(ball)
			ball.clear_trail()
	if state == State.PLAYING:
		_update_balls(delta)
	if state == State.PLAYING:
		_update_lasers(delta)
	if state == State.PLAYING:
		_update_powerups(delta)
	_update_shake(delta)
	shield_line.visible = shield_on
	if shield_on:
		shield_line.modulate = Color(1, 1, 1, 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008))
	hud.update_effects(effects, EFFECT_TIME, shield_on, bomb_armed)


func _update_effects(delta: float) -> void:
	var expired: Array = []
	for k in effects.keys():
		effects[k] = float(effects[k]) - delta
		if effects[k] <= 0.0:
			expired.append(k)
	if expired.is_empty():
		return
	for k in expired:
		effects.erase(k)
	if expired.has("magnet"):
		_launch()  # lepaskan bola yang menempel
	_refresh_looks()


func _update_paddle(delta: float) -> void:
	if state == State.CLEAR or state == State.OVER or effects.has("freeze"):
		return
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	var px: float = paddle.position.x
	if dir != 0.0:
		keyboard_mode = true
		px += dir * PADDLE_KEY_SPEED * delta
	elif not keyboard_mode:
		var mx: float = world.get_local_mouse_position().x
		px = lerpf(px, mx, clampf(delta * 30.0, 0.0, 1.0))
	var half: float = paddle.width * 0.5
	px = clampf(px, ARENA.position.x + half, ARENA.end.x - half)
	paddle.position = Vector2(px, PADDLE_Y)


func _place_stuck(ball) -> void:
	ball.position = Vector2(paddle.position.x + float(ball.stick_offset), PADDLE_Y - paddle.height * 0.5 - float(ball.radius) - 1.0)


# ================================================================ balls

func _spawn_ball():
	var b = BallScript.new()
	world.add_child(b)
	balls.append(b)
	return b


func _update_balls(delta: float) -> void:
	var speed: float = _current_speed()
	for ball in balls.duplicate():
		if state != State.PLAYING:
			return
		if not balls.has(ball) or ball.stuck:
			continue
		ball.velocity = (ball.velocity as Vector2).normalized() * speed
		var steps: int = maxi(1, ceili(speed * delta / SUBSTEP))
		var dt: float = delta / steps
		for i in steps:
			if not _step_ball(ball, dt):
				break
			if state != State.PLAYING:
				return
		if balls.has(ball):
			ball.update_trail()


## Kembalikan false kalau bola hilang atau menempel.
func _step_ball(ball, dt: float) -> bool:
	var r: float = ball.radius
	var pos: Vector2 = ball.position
	var vel: Vector2 = ball.velocity
	pos += vel * dt

	# Dinding
	if pos.x - r < ARENA.position.x:
		pos.x = ARENA.position.x + r
		vel.x = absf(vel.x)
		Global.play_sfx("bounce", 1.4, -10.0)
	elif pos.x + r > ARENA.end.x:
		pos.x = ARENA.end.x - r
		vel.x = -absf(vel.x)
		Global.play_sfx("bounce", 1.4, -10.0)
	if pos.y - r < ARENA.position.y:
		pos.y = ARENA.position.y + r
		vel.y = absf(vel.y)
		Global.play_sfx("bounce", 1.4, -10.0)
	ball.position = pos
	ball.velocity = vel

	# Shield
	var shield_y: float = ARENA.end.y - 8.0
	if shield_on and vel.y > 0.0 and pos.y + r >= shield_y:
		ball.position = Vector2(pos.x, shield_y - r)
		ball.velocity = Vector2(vel.x, -absf(vel.y))
		shield_on = false
		Global.play_sfx("hit", 0.8)
		_spawn_debris(Vector2(pos.x, shield_y), Color(0.35, 0.9, 1.0), 20)
		return true

	# Paddle
	if vel.y > 0.0:
		var pr: Rect2 = paddle.get_hit_rect()
		if _circle_hits_rect(pos, r, pr) and pos.y < pr.end.y:
			_paddle_bounce(ball, pr)
			return not ball.stuck

	# Jatuh
	if pos.y - r > ARENA.end.y:
		_lose_ball(ball)
		return false

	# Brick
	for brick in bricks:
		var br: Rect2 = brick.hit_rect()
		var closest := Vector2(clampf(pos.x, br.position.x, br.end.x), clampf(pos.y, br.position.y, br.end.y))
		var d: Vector2 = pos - closest
		if d.length_squared() <= r * r:
			_ball_hit_brick(ball, brick, br, d)
			break

	_ensure_angle(ball)
	return true


func _circle_hits_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var closest := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
	return c.distance_squared_to(closest) <= r * r


func _paddle_bounce(ball, pr: Rect2) -> void:
	var half: float = pr.size.x * 0.5
	var pos: Vector2 = ball.position
	var off: float = clampf((pos.x - (pr.position.x + half)) / half, -1.0, 1.0)
	var ang: float = off * deg_to_rad(62.0)
	var spd: float = (ball.velocity as Vector2).length()
	ball.velocity = Vector2(sin(ang), -cos(ang)) * spd
	ball.position = Vector2(pos.x, pr.position.y - float(ball.radius) - 0.5)
	paddle.bump()
	paddle_hits += 1
	Global.play_sfx("bounce")
	if effects.has("magnet"):
		ball.stuck = true
		ball.stick_offset = pos.x - paddle.position.x


func _ball_hit_brick(ball, brick, br: Rect2, d: Vector2) -> void:
	var r: float = ball.radius
	var breakable: bool = brick.breakable
	if bomb_armed:
		bomb_armed = false
		if not breakable:
			brick.hit(1)
		_explode(brick.position)
		_refresh_looks()
	elif effects.has("fireball") and breakable:
		_damage_brick(brick, 99)
		return  # tembus, tidak memantul
	else:
		_damage_brick(brick, 1)

	var vel: Vector2 = ball.velocity
	var pos: Vector2 = ball.position
	var n: Vector2 = d.normalized() if d.length_squared() > 0.0001 else -vel.normalized()
	if absf(n.x) > absf(n.y):
		vel.x = absf(vel.x) * signf(n.x)
		pos.x = br.end.x + r if n.x > 0.0 else br.position.x - r
	else:
		vel.y = absf(vel.y) * signf(n.y)
		pos.y = br.end.y + r if n.y > 0.0 else br.position.y - r
	ball.velocity = vel
	ball.position = pos


func _ensure_angle(ball) -> void:
	var v: Vector2 = ball.velocity
	var spd: float = v.length()
	if spd < 1.0:
		return
	var min_y: float = spd * 0.3
	if absf(v.y) < min_y:
		var sy: float = signf(v.y) if v.y != 0.0 else -1.0
		var sx: float = signf(v.x) if v.x != 0.0 else 1.0
		v.y = min_y * sy
		v.x = sx * sqrt(maxf(spd * spd - v.y * v.y, 0.0))
		ball.velocity = v


func _lose_ball(ball) -> void:
	balls.erase(ball)
	ball.queue_free()
	if balls.is_empty():
		_lose_life()


func _lose_life() -> void:
	lives -= 1
	hud.set_lives(lives)
	Global.play_sfx("lose")
	_shake(10.0, 0.35)
	effects.clear()
	shield_on = false
	bomb_armed = false
	_clear_powerups_and_lasers()
	if lives <= 0:
		_game_over()
	else:
		_enter_ready()


# ================================================================ bricks

func _damage_brick(brick, dmg: int) -> void:
	if not bricks.has(brick):
		return
	if not brick.breakable:
		brick.hit(dmg)
		Global.play_sfx("hit", 0.7)
		return
	var destroyed: bool = brick.hit(dmg)
	if not destroyed:
		_add_score(10)
		Global.play_sfx("hit")
		return
	bricks.erase(brick)
	var pos: Vector2 = brick.position
	_add_score(brick.points)
	_spawn_debris(pos, brick.color, 16)
	_shake(4.0, 0.12)
	Global.play_sfx("break", randf_range(0.9, 1.15))
	if brick.always_drop or randf() < DROP_CHANCE:
		_spawn_powerup(pos)
	brick.die()
	if _breakable_left() == 0:
		_level_clear()


func _breakable_left() -> int:
	var n := 0
	for b in bricks:
		if b.breakable:
			n += 1
	return n


func _explode(center: Vector2) -> void:
	Global.play_sfx("explode")
	_shake(12.0, 0.3)
	_spawn_debris(center, Color(1.0, 0.55, 0.2), 40, Vector2(60, 40))
	for b in bricks.duplicate():
		var bp: Vector2 = b.position
		if b.breakable and bp.distance_to(center) <= BOMB_RADIUS:
			_damage_brick(b, 99)


func _spawn_debris(pos: Vector2, color: Color, amount: int, extents: Vector2 = Vector2(34, 12)) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 240.0
	p.gravity = Vector2(0, 520)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	fx_layer.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _shake(strength: float, time: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, time)


func _update_shake(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var k: float = clampf(shake_time / 0.3, 0.0, 1.0)
		world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * k
	else:
		shake_strength = 0.0
		world.position = Vector2.ZERO


func _add_score(n: int) -> void:
	var mult: int = 2 if effects.has("speedup") else 1
	score += n * mult
	hud.set_score(score)
	if score > Global.best_score:
		Global.best_score = score
		hud.set_best(score)


# ================================================================ power-ups

func _spawn_powerup(pos: Vector2) -> void:
	var pu = PowerUpScript.new()
	world.add_child(pu)
	pu.setup(_pick_powerup(true))
	pu.position = pos
	powerups.append(pu)


func _pick_powerup(allow_random: bool) -> String:
	var total := 0
	for k in POWERUP_WEIGHTS.keys():
		if k == "random" and not allow_random:
			continue
		total += int(POWERUP_WEIGHTS[k])
	var roll: int = randi() % total
	for k in POWERUP_WEIGHTS.keys():
		if k == "random" and not allow_random:
			continue
		roll -= int(POWERUP_WEIGHTS[k])
		if roll < 0:
			return String(k)
	return "multiball"


func _update_powerups(delta: float) -> void:
	var pr: Rect2 = paddle.get_hit_rect()
	pr = pr.grow(4.0)
	for pu in powerups.duplicate():
		var p: Vector2 = pu.position
		p.y += POWERUP_FALL * delta
		pu.position = p
		var r: Rect2 = pu.hit_rect()
		if r.intersects(pr):
			powerups.erase(pu)
			var t: String = pu.type
			pu.queue_free()
			_apply_powerup(t)
		elif p.y > ARENA.end.y + 30.0:
			powerups.erase(pu)
			pu.queue_free()
		if state != State.PLAYING:
			return


func _apply_powerup(type: String) -> void:
	var t := type
	if t == "random":
		t = _pick_powerup(false)
	Global.play_sfx("powerup")
	_add_score(25)
	var prefix := "? " if type == "random" else "+ "
	hud.show_toast(prefix + hud.powerup_name(t), t == "speedup" or t == "freeze")
	match t:
		"multiball":
			_multiball()
		"shield":
			shield_on = true
		"extralife":
			lives = mini(lives + 1, MAX_LIVES)
			hud.set_lives(lives)
		"bomb":
			bomb_armed = true
		_:
			effects[t] = EFFECT_TIME[t]
			if t == "slowtime":
				effects.erase("speedup")
			elif t == "speedup":
				effects.erase("slowtime")
	_refresh_looks()


func _multiball() -> void:
	if balls.is_empty():
		return
	var source = null
	for b in balls:
		if not b.stuck:
			source = b
			break
	if source == null:
		source = balls[0]
		source.stuck = false
		source.velocity = Vector2(0, -1) * _current_speed()
	var base_v: Vector2 = source.velocity
	var base_p: Vector2 = source.position
	for ang in [-0.45, 0.45]:
		if balls.size() >= MAX_BALLS:
			break
		var nb = _spawn_ball()
		nb.position = base_p
		nb.velocity = base_v.rotated(ang)


func _update_lasers(delta: float) -> void:
	if effects.has("laser"):
		laser_cooldown -= delta
		if laser_cooldown <= 0.0:
			laser_cooldown = 0.38
			for sx in [-1.0, 1.0]:
				var shot = LaserScript.new()
				shot.position = Vector2(paddle.position.x + sx * (paddle.width * 0.5 - 12.0), PADDLE_Y - 14.0)
				world.add_child(shot)
				lasers.append(shot)
			Global.play_sfx("laser", randf_range(0.95, 1.1), -6.0)
	for shot in lasers.duplicate():
		var p: Vector2 = shot.position
		p.y -= LASER_SPEED * delta
		shot.position = p
		var hit := p.y < ARENA.position.y
		if not hit:
			var sr := Rect2(p - Vector2(2, 9), Vector2(4, 18))
			for brick in bricks:
				var br: Rect2 = brick.hit_rect()
				if br.intersects(sr):
					_damage_brick(brick, 1)
					hit = true
					break
		if hit:
			lasers.erase(shot)
			shot.queue_free()
		if state != State.PLAYING:
			return


func _refresh_looks() -> void:
	if paddle == null:
		return
	paddle.set_target_width(PADDLE_WIDE if effects.has("paddleup") else PADDLE_WIDTH)
	var skin := "paddle_blue"
	if effects.has("freeze"):
		skin = "paddle_silver"
	elif effects.has("laser"):
		skin = "paddle_red"
	elif effects.has("magnet"):
		skin = "paddle_purple"
	elif effects.has("paddleup"):
		skin = "paddle_gold"
	paddle.set_skin(skin)
	paddle.modulate = Color(0.6, 0.9, 1.4) if effects.has("freeze") else Color.WHITE

	var tex := "ball_blue"
	var col := Color(0.3, 0.7, 1.0)
	if bomb_armed:
		tex = "ball_magenta"
		col = Color(1.0, 0.3, 0.8)
	elif effects.has("fireball"):
		tex = "ball_gold"
		col = Color(1.0, 0.5, 0.15)
	elif effects.has("speedup"):
		tex = "ball_green"
		col = Color(0.3, 1.0, 0.5)
	elif effects.has("slowtime"):
		tex = "ball_purple"
		col = Color(0.6, 0.4, 1.0)
	for b in balls:
		b.set_look(tex, col)


# ================================================================ end states

func _level_clear() -> void:
	if state != State.PLAYING:
		return
	state = State.CLEAR
	var bonus: int = 500 + lives * 100
	score += bonus
	hud.set_score(score)
	if score > Global.best_score:
		Global.best_score = score
		hud.set_best(score)
	Global.save_data()
	for b in balls:
		b.queue_free()
	balls.clear()
	_clear_powerups_and_lasers()
	effects.clear()
	shield_on = false
	bomb_armed = false
	_refresh_looks()
	Global.play_sfx("win")
	await get_tree().create_timer(0.6).timeout
	if state == State.CLEAR:
		hud.show_victory(_level_label(), bonus)


func _game_over() -> void:
	state = State.OVER
	for b in balls:
		b.queue_free()
	balls.clear()
	var record: bool = score > best_at_start and score > 0
	Global.save_data()
	Global.play_sfx("gameover")
	hud.show_game_over(score, Global.best_score, record)
