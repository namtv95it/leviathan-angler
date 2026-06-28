## scripts/systems/audio_manager.gd
## Autoload Singleton: AudioManager
##
## CACH DUNG:
##   AudioManager.play_sfx("splash")
##   AudioManager.play_music("zone_1_theme")
##   AudioManager.set_volume("sfx", 0.8)

extends Node

# Duong dan den thu muc audio
const SFX_PATH   := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/"

# Cache am thanh da load (tranh load lai nhieu lan)
var _sfx_cache:   Dictionary = {}
var _music_cache: Dictionary = {}

# AudioStreamPlayer cho nhac nen (1 bai chay 1 luc)
var _music_player: AudioStreamPlayer
var _current_music: String = ""

# Pool AudioStreamPlayer cho SFX (cho phep chay nhieu SFX cung luc)
const SFX_POOL_SIZE := 8
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

# Am luong (0.0 -> 1.0)
var volume_music: float = 0.8 : set = _set_volume_music
var volume_sfx:   float = 1.0 : set = _set_volume_sfx

func _ready() -> void:
	_setup_music_player()
	_setup_sfx_pool()
	print("[AudioManager] San sang.")

func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

# === PHAT NHAC NEN ===
func play_music(track_name: String, loop: bool = true) -> void:
	if _current_music == track_name:
		return  # Dang phat bai nay roi

	var stream := _load_audio(MUSIC_PATH + track_name + ".ogg", _music_cache)
	if stream == null:
		push_warning("[AudioManager] Khong tim thay nhac: " + track_name)
		return

	# Neu AudioStream ho tro loop (OggVorbis)
	if stream is AudioStreamOggVorbis:
		stream.loop = loop

	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(volume_music)
	_music_player.play()
	_current_music = track_name

func stop_music() -> void:
	_music_player.stop()
	_current_music = ""

# === PHAT HIEU UNG AM THANH ===
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	var stream := _load_audio(SFX_PATH + sfx_name + ".wav", _sfx_cache)
	if stream == null:
		# Thu .ogg neu khong co .wav
		stream = _load_audio(SFX_PATH + sfx_name + ".ogg", _sfx_cache)
	if stream == null:
		push_warning("[AudioManager] Khong tim thay SFX: " + sfx_name)
		return

	# Lay player tu pool (round-robin)
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = linear_to_db(volume_sfx)
	# Bien do pitch de am thanh nghe tu nhien hon
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()

# === DIEU CHINH AM LUONG ===
func set_volume(bus: String, value: float) -> void:
	match bus:
		"music": volume_music = clampf(value, 0.0, 1.0)
		"sfx":   volume_sfx   = clampf(value, 0.0, 1.0)

func _set_volume_music(value: float) -> void:
	volume_music = value
	if _music_player:
		_music_player.volume_db = linear_to_db(value)

func _set_volume_sfx(value: float) -> void:
	volume_sfx = value
	for player in _sfx_pool:
		player.volume_db = linear_to_db(value)

# === LOAD AUDIO (co cache) ===
func _load_audio(path: String, cache: Dictionary) -> AudioStream:
	if cache.has(path):
		return cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	cache[path] = stream
	return stream
