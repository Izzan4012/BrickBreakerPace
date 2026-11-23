extends Node
## Autoload "Global": simpan skor terbaik, mute, cache tekstur, SFX, dan font.

const SAVE_PATH := "user://save.cfg"
const SFX_NAMES := ["bounce", "hit", "break", "powerup", "lose", "laser", "win", "start", "explode", "gameover"]

var best_score: int = 0
var muted: bool = false
var font_bold: SystemFont

var _tex_cache: Dictionary = {}
var _sfx: Dictionary = {}
var _players: Array = []
var _next_player: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()
	for n in SFX_NAMES:
		var path: String = "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			_sfx[n] = load(path)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	font_bold = SystemFont.new()
	font_bold.font_names = PackedStringArray(["Orbitron", "Bahnschrift", "Segoe UI", "Roboto", "Arial"])
	font_bold.font_weight = 700


func tex(tex_name: String) -> Texture2D:
	if not _tex_cache.has(tex_name):
		_tex_cache[tex_name] = load("res://assets/sprites/%s.png" % tex_name)
	return _tex_cache[tex_name]


func play_sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if muted or not _sfx.has(sfx_name):
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _sfx[sfx_name]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func set_muted(value: bool) -> void:
	muted = value
	save_data()


func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("game", "best_score", 0))
		muted = bool(cfg.get_value("game", "muted", false))


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best_score", best_score)
	cfg.set_value("game", "muted", muted)
	cfg.save(SAVE_PATH)
