extends Control
## Splash screen: putar intro sekali, lalu loop. Tap / klik / tombol apa saja untuk mulai.

const INTRO := preload("res://assets/video/intro.ogv")
const LOOP := preload("res://assets/video/loop.ogv")
const GAME_SCENE := "res://scenes/game.tscn"

var _intro: VideoStreamPlayer
var _loop: VideoStreamPlayer
var _fade: ColorRect
var _leaving: bool = false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_loop = _make_player(LOOP)
	_intro = _make_player(INTRO)
	_loop.finished.connect(_loop.play)
	_intro.finished.connect(_on_intro_finished)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "modulate:a", 0.0, 0.4)

	_intro.play()


func _make_player(stream: VideoStream) -> VideoStreamPlayer:
	var p := VideoStreamPlayer.new()
	p.stream = stream
	p.expand = true
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func _on_intro_finished() -> void:
	_loop.play()
	var tw := create_tween()
	tw.tween_property(_intro, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_intro.hide)


func _input(event: InputEvent) -> void:
	if _leaving:
		return
	var pressed := false
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		pressed = event.is_pressed()
	elif event is InputEventKey:
		pressed = event.is_pressed() and not event.is_echo()
	if pressed:
		get_viewport().set_input_as_handled()
		_start_game()


func _start_game() -> void:
	_leaving = true
	Global.play_sfx("start")
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.45)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
