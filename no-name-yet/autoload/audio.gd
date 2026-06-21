extends Node

const SFX_PATHS := {
	"shoot": "res://audio/shoot.wav",
	"hit": "res://audio/hit.wav",
	"pickup": "res://audio/pickup.wav",
	"level_up": "res://audio/level_up.wav",
	"death": "res://audio/death.wav",
}
const MUSIC_PATH := "res://audio/music.ogg"
const VOICE_COUNT := 8

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
var _sfx: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICE_COUNT:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	for key in SFX_PATHS:
		if ResourceLoader.exists(SFX_PATHS[key]):
			_sfx[key] = load(SFX_PATHS[key])


func play(sfx_name: String, volume_db: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[sfx_name]
	p.volume_db = volume_db
	p.play()


func play_music() -> void:
	if _music.playing or not ResourceLoader.exists(MUSIC_PATH):
		return
	_music.stream = load(MUSIC_PATH)
	_music.volume_db = -10.0
	_music.play()
