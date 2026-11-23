extends CanvasLayer
## HUD: panel skor/level/nyawa/power-up, petunjuk mulai, menu jeda, game over, dan victory.

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal home_pressed
signal next_pressed

const CYAN := Color(0.25, 0.85, 1.0)
const MAGENTA := Color(1.0, 0.25, 0.75)
const GOLD := Color(1.0, 0.8, 0.2)
const ARENA_CENTER := Vector2(640, 369)

const NAMES := {
	"multiball": "MULTI BALL",
	"laser": "LASER",
	"shield": "SHIELD",
	"paddleup": "PADDLE UP",
	"slowtime": "SLOW TIME",
	"magnet": "MAGNET",
	"extralife": "EXTRA LIFE",
	"bomb": "BOMB",
	"speedup": "SPEED UP",
	"random": "RANDOM",
	"fireball": "FIREBALL",
	"freeze": "FREEZE",
}

var _root: Control
var _score_value: Label
var _best_value: Label
var _level_value: Label
var _hearts: HBoxContainer
var _effects_box: VBoxContainer
var _no_effect: Label
var _effect_rows: Dictionary = {}
var _sound_btn: TextureButton

var _ready_box: Panel
var _ready_title: Label
var _ready_hint: Label
var _hint_tween: Tween

var _dim: ColorRect
var _pause_box: Panel
var _over_box: Panel
var _over_score: Label
var _over_best: Label
var _over_record: Label
var _clear_box: Panel
var _clear_title: Label
var _clear_bonus: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_left()
	_build_right()
	_build_ready_box()
	_build_toast()
	_build_overlays()


# ---------------------------------------------------------------- helpers

func _style(border: Color, bg_alpha: float = 0.8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.06, 0.18, bg_alpha)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.corner_detail = 1  # sudut terpotong seperti aset
	sb.shadow_color = Color(border, 0.35)
	sb.shadow_size = 10
	return sb


func _panel(parent: Control, pos: Vector2, size: Vector2, border: Color = CYAN) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(border))
	parent.add_child(p)
	return p


func _label(parent: Control, text: String, font_size: int, color: Color, pos: Vector2, size: Vector2, glow: Color = CYAN) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", Global.font_bold)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(glow, 0.45))
	l.add_theme_constant_override("outline_size", maxi(2, font_size / 6))
	parent.add_child(l)
	return l


func _tbtn(parent: Control, tex_name: String, size: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = Global.tex(tex_name)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = size
	b.size = size
	b.pivot_offset = size * 0.5
	b.mouse_entered.connect(func() -> void: b.modulate = Color(1.3, 1.3, 1.3))
	b.mouse_exited.connect(func() -> void: b.modulate = Color.WHITE)
	b.button_down.connect(func() -> void: b.scale = Vector2(0.93, 0.93))
	b.button_up.connect(func() -> void: b.scale = Vector2.ONE)
	b.pressed.connect(func() -> void: Global.play_sfx("hit", 1.3, -6.0))
	parent.add_child(b)
	return b


func _stat_panel(parent: Control, pos: Vector2, title: String, border: Color = CYAN) -> Label:
	var p := _panel(parent, pos, Vector2(212, 92), border)
	_label(p, title, 16, Color(0.75, 0.92, 1.0), Vector2(0, 8), Vector2(212, 22))
	return _label(p, "0", 36, Color.WHITE, Vector2(0, 32), Vector2(212, 52))


# ---------------------------------------------------------------- build

func _build_left() -> void:
	_label(_root, "BRICK", 30, Color.WHITE, Vector2(24, 18), Vector2(212, 34))
	_label(_root, "BREAKER", 30, Color.WHITE, Vector2(24, 48), Vector2(212, 34))
	_score_value = _stat_panel(_root, Vector2(24, 100), "SCORE")
	_best_value = _stat_panel(_root, Vector2(24, 206), "BEST SCORE")
	_level_value = _stat_panel(_root, Vector2(24, 312), "LEVEL")
	var help := _panel(_root, Vector2(24, 560), Vector2(212, 132), Color(0.3, 0.5, 0.9))
	var txt := "GERAK\nmouse / jari / A-D / panah\n\nLUNCURKAN\nklik / tap / spasi\n\nJEDA:  P / Esc"
	var l := _label(help, txt, 12, Color(0.7, 0.8, 1.0), Vector2(0, 6), Vector2(212, 120), Color(0, 0, 0, 0))
	l.add_theme_constant_override("line_spacing", -2)


func _build_right() -> void:
	var lives_panel := _panel(_root, Vector2(1044, 100), Vector2(212, 92), MAGENTA)
	_label(lives_panel, "LIVES", 16, Color(1.0, 0.8, 0.92), Vector2(0, 8), Vector2(212, 22), MAGENTA)
	_hearts = HBoxContainer.new()
	_hearts.position = Vector2(0, 38)
	_hearts.size = Vector2(212, 42)
	_hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	_hearts.add_theme_constant_override("separation", 4)
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives_panel.add_child(_hearts)

	var fx_panel := _panel(_root, Vector2(1044, 206), Vector2(212, 282))
	_label(fx_panel, "POWER-UP", 16, Color(0.75, 0.92, 1.0), Vector2(0, 8), Vector2(212, 22))
	_no_effect = _label(fx_panel, "-", 18, Color(0.5, 0.6, 0.8), Vector2(0, 40), Vector2(212, 40))
	_effects_box = VBoxContainer.new()
	_effects_box.position = Vector2(14, 38)
	_effects_box.size = Vector2(184, 236)
	_effects_box.add_theme_constant_override("separation", 6)
	_effects_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_panel.add_child(_effects_box)

	var pause_btn := _tbtn(_root, "btn_pause", Vector2(200, 52))
	pause_btn.position = Vector2(1050, 506)
	pause_btn.pressed.connect(func() -> void: pause_pressed.emit())

	_sound_btn = _tbtn(_root, "ic_sound", Vector2(52, 52))
	_sound_btn.position = Vector2(1124, 574)
	_sound_btn.pressed.connect(_toggle_sound)
	_refresh_sound_btn()


func _build_ready_box() -> void:
	_ready_box = _panel(_root, Vector2(ARENA_CENTER.x - 210, 390), Vector2(420, 150))
	_ready_title = _label(_ready_box, "LEVEL 1-1", 34, Color.WHITE, Vector2(0, 12), Vector2(420, 46))
	_ready_hint = _label(_ready_box, "TAP / KLIK UNTUK MELUNCURKAN", 18, Color(1.0, 0.45, 0.85), Vector2(0, 66), Vector2(420, 30), MAGENTA)
	_label(_ready_box, "geser mouse / jari untuk menggerakkan paddle", 12, Color(0.65, 0.75, 0.95), Vector2(0, 106), Vector2(420, 24), Color(0, 0, 0, 0))
	_ready_box.hide()


func _build_toast() -> void:
	_toast = _label(_root, "", 26, Color.WHITE, Vector2(260, 560), Vector2(760, 40))
	_toast.hide()


func _build_overlays() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.03, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)

	# --- Pause
	_pause_box = _panel(_dim, ARENA_CENTER - Vector2(190, 150), Vector2(380, 300))
	_label(_pause_box, "PAUSED", 40, Color.WHITE, Vector2(0, 22), Vector2(380, 56))
	var resume := _tbtn(_pause_box, "btn_resume", Vector2(260, 62))
	resume.position = Vector2(60, 100)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	_icon_row(_pause_box, Vector2(0, 196), 380)

	# --- Game over
	_over_box = _panel(_dim, ARENA_CENTER - Vector2(210, 190), Vector2(420, 380), Color(1.0, 0.3, 0.35))
	var banner := _tex_rect(_over_box, "btn_gameover", Vector2(30, 20), Vector2(360, 84))
	banner.pivot_offset = banner.size * 0.5
	_over_score = _label(_over_box, "SCORE 0", 32, Color.WHITE, Vector2(0, 116), Vector2(420, 44))
	_over_best = _label(_over_box, "BEST 0", 20, Color(0.7, 0.9, 1.0), Vector2(0, 162), Vector2(420, 30))
	_over_record = _label(_over_box, "REKOR BARU!", 22, GOLD, Vector2(0, 196), Vector2(420, 32), GOLD)
	_icon_row(_over_box, Vector2(0, 262), 420)

	# --- Victory / level clear
	_clear_box = _panel(_dim, ARENA_CENTER - Vector2(210, 170), Vector2(420, 340), GOLD)
	_tex_rect(_clear_box, "btn_victory", Vector2(30, 20), Vector2(360, 84))
	_clear_title = _label(_clear_box, "LEVEL 1-1 SELESAI", 26, Color.WHITE, Vector2(0, 116), Vector2(420, 40))
	_clear_bonus = _label(_clear_box, "BONUS +0", 22, GOLD, Vector2(0, 160), Vector2(420, 32), GOLD)
	var next := _tbtn(_clear_box, "btn_play", Vector2(260, 68))
	next.position = Vector2(80, 230)
	next.pressed.connect(func() -> void: next_pressed.emit())

	hide_all()


func _tex_rect(parent: Control, tex_name: String, pos: Vector2, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Global.tex(tex_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = pos
	t.size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _icon_row(parent: Control, pos: Vector2, width: float) -> void:
	var row := HBoxContainer.new()
	row.position = pos
	row.size = Vector2(width, 72)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	parent.add_child(row)
	var restart := _tbtn(row, "ic_restart", Vector2(64, 64))
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	var home := _tbtn(row, "ic_home", Vector2(64, 64))
	home.pressed.connect(func() -> void: home_pressed.emit())


func _make_effect_row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = Global.tex("pu_" + key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_label := Label.new()
	name_label.text = String(NAMES.get(key, key)).to_upper()
	name_label.add_theme_font_override("font", Global.font_bold)
	name_label.add_theme_font_size_override("font_size", 13)
	col.add_child(name_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.15, 0.3)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	row.set_meta("bar", bar)
	_effects_box.add_child(row)
	return row


# ---------------------------------------------------------------- API

func set_score(v: int) -> void:
	_score_value.text = str(v)


func set_best(v: int) -> void:
	_best_value.text = str(v)


func set_level(text: String) -> void:
	_level_value.text = text


func set_lives(n: int) -> void:
	for c in _hearts.get_children():
		_hearts.remove_child(c)
		c.queue_free()
	for i in n:
		var h := TextureRect.new()
		h.texture = Global.tex("heart")
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.custom_minimum_size = Vector2(34, 32)
		_hearts.add_child(h)


func powerup_name(key: String) -> String:
	return String(NAMES.get(key, key))


func update_effects(effects: Dictionary, totals: Dictionary, shield: bool, bomb: bool) -> void:
	var active := {}
	for k in effects.keys():
		active[k] = clampf(float(effects[k]) / float(totals.get(k, 1.0)), 0.0, 1.0)
	if shield:
		active["shield"] = 1.0
	if bomb:
		active["bomb"] = 1.0
	for k in _effect_rows.keys():
		if not active.has(k):
			_effect_rows[k].queue_free()
			_effect_rows.erase(k)
	for k in active.keys():
		if not _effect_rows.has(k):
			_effect_rows[k] = _make_effect_row(k)
		var bar: ProgressBar = _effect_rows[k].get_meta("bar")
		bar.value = float(active[k]) * 100.0
	_no_effect.visible = active.is_empty()


func show_ready(level_text: String) -> void:
	_ready_title.text = "LEVEL " + level_text
	_ready_box.show()
	_ready_box.modulate.a = 0.0
	create_tween().tween_property(_ready_box, "modulate:a", 1.0, 0.3)
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_ready_hint, "modulate:a", 0.35, 0.6)
	_hint_tween.tween_property(_ready_hint, "modulate:a", 1.0, 0.6)


func hide_ready() -> void:
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	var tw := create_tween()
	tw.tween_property(_ready_box, "modulate:a", 0.0, 0.2)
	tw.tween_callback(_ready_box.hide)


func show_toast(text: String, negative: bool = false) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast.text = text
	_toast.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55) if negative else Color.WHITE)
	_toast.position.y = 580
	_toast.modulate.a = 1.0
	_toast.show()
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast, "position:y", 540.0, 0.9)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.9).set_delay(0.3)


func show_pause() -> void:
	_show_box(_pause_box)


func hide_pause() -> void:
	hide_all()


func show_game_over(score: int, best: int, record: bool) -> void:
	_over_score.text = "SCORE  %d" % score
	_over_best.text = "BEST  %d" % best
	_over_record.visible = record
	_show_box(_over_box)


func show_victory(level_text: String, bonus: int) -> void:
	_clear_title.text = "LEVEL %s SELESAI" % level_text
	_clear_bonus.text = "BONUS +%d" % bonus
	_show_box(_clear_box)


func hide_all() -> void:
	_dim.hide()
	_pause_box.hide()
	_over_box.hide()
	_clear_box.hide()


func is_paused_menu_open() -> bool:
	return _dim.visible and _pause_box.visible


func _show_box(box: Panel) -> void:
	hide_all()
	_dim.show()
	box.show()
	box.pivot_offset = box.size * 0.5
	box.scale = Vector2(0.8, 0.8)
	box.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 1.0, 0.2)


func _toggle_sound() -> void:
	Global.set_muted(not Global.muted)
	_refresh_sound_btn()


func _refresh_sound_btn() -> void:
	_sound_btn.self_modulate = Color(1, 1, 1, 0.3) if Global.muted else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	var key: int = ke.keycode
	if _pause_box.visible and (key == KEY_P or key == KEY_ESCAPE):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()
	elif _over_box.visible and (key == KEY_ENTER or key == KEY_SPACE):
		restart_pressed.emit()
		get_viewport().set_input_as_handled()
	elif _clear_box.visible and (key == KEY_ENTER or key == KEY_SPACE):
		next_pressed.emit()
		get_viewport().set_input_as_handled()
