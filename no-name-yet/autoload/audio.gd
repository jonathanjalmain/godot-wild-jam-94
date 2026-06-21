extends Node

const VOICE_COUNT := 8
const SFX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
var _sfx: Dictionary = {}
var _music_stream: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICE_COUNT:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_sfx["shoot"] = _gen_shoot()
	_sfx["nova"] = _gen_nova()
	_music_stream = _gen_ambient()


func play(sfx_name: String, volume_db: float = 0.0, pitch_var: float = 0.0) -> void:
	if not _sfx.has(sfx_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_music() -> void:
	if _music.playing or _music_stream == null:
		return
	_music.stream = _music_stream
	_music.volume_db = -14.0
	_music.play()


func _make_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SFX_RATE
	w.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


func _gen_shoot() -> AudioStreamWAV:
	var dur := 0.09
	var n := int(SFX_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / SFX_RATE
		var env := exp(-t * 40.0)
		var freq := 900.0 - 520.0 * (t / dur)
		var val := sin(TAU * freq * t)
		val = 0.6 * val + 0.4 * signf(val)
		s[i] = val * env * 0.5
	return _make_wav(s, false)


func _gen_nova() -> AudioStreamWAV:
	var dur := 0.55
	var n := int(SFX_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / SFX_RATE
		var p := t / dur
		var env := exp(-t * 5.5)
		var freq := 230.0 - 160.0 * p
		var tone := sin(TAU * freq * t)
		var noise := randf() * 2.0 - 1.0
		var noise_env := exp(-t * 17.0)
		s[i] = (tone * 0.7 + noise * 0.5 * noise_env) * env * 0.75
	return _make_wav(s, false)


func _gen_ambient() -> AudioStreamWAV:
	var dur := 8.0
	var n := int(SFX_RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var partials := [
		{"cyc": 880.0, "amp": 0.5, "lfo": 1.0, "depth": 0.45},
		{"cyc": 1320.0, "amp": 0.32, "lfo": 2.0, "depth": 0.5},
		{"cyc": 1760.0, "amp": 0.26, "lfo": 3.0, "depth": 0.5},
		{"cyc": 2636.0, "amp": 0.16, "lfo": 2.0, "depth": 0.6},
	]
	for i in n:
		var ph := float(i) / float(n)
		var v := 0.0
		for pa in partials:
			var lfo: float = 0.5 + 0.5 * sin(TAU * float(pa.lfo) * ph)
			var amp: float = float(pa.amp) * (1.0 - float(pa.depth) + float(pa.depth) * lfo)
			v += sin(TAU * float(pa.cyc) * ph) * amp
		s[i] = v * 0.22
	return _make_wav(s, true)
