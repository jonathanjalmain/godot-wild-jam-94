extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const DAMAGE_NUMBER := preload("res://scripts/damage_number.gd")
const SURVIVE_SECONDS := 600.0
const MAX_ENEMIES := 140
const DESPAWN_DIST := 1800.0
const MAX_DAMAGE_NUMBERS := 120

const ENEMY_TYPES := {
	"grunt": {"hp": 30.0, "speed": 90.0, "damage": 10.0, "xp": 1.0, "color": Color(0.9, 0.3, 0.3), "scale": 1.0},
	"runner": {"hp": 18.0, "speed": 165.0, "damage": 8.0, "xp": 1.0, "color": Color(0.95, 0.7, 0.2), "scale": 0.8},
	"brute": {"hp": 95.0, "speed": 60.0, "damage": 18.0, "xp": 3.0, "color": Color(0.7, 0.2, 0.55), "scale": 1.5},
}

@export var spawn_radius: float = 700.0

@onready var _player: Node2D = $Player
@onready var _spawn_timer: Timer = $SpawnTimer

var _elapsed: float = 0.0
var _won: bool = false
var _pool: Array = []
var _dmg_pool: Array = []
var _dmg_total: int = 0


func _ready() -> void:
	GameState.reset()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	Audio.play_music()


func _process(delta: float) -> void:
	if not GameState.alive or _won:
		return
	_elapsed += delta
	_spawn_timer.wait_time = max(0.25, 1.0 - _elapsed * 0.004)
	if _elapsed >= SURVIVE_SECONDS:
		_win()


func _on_spawn_timer_timeout() -> void:
	if not GameState.alive or _won:
		return
	_cull_far_enemies()
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
		_merge_crowd()
	var room := MAX_ENEMIES - get_tree().get_nodes_in_group("enemies").size()
	if room <= 0:
		return
	var count := mini(1 + int(_elapsed / 90.0), room)
	for i in count:
		_spawn_one()


func _merge_crowd() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var merged := {}
	var done := 0
	for i in enemies.size():
		var a = enemies[i]
		if merged.has(a):
			continue
		for j in range(i + 1, enemies.size()):
			var b = enemies[j]
			if merged.has(b):
				continue
			if a.global_position.distance_to(b.global_position) <= a.world_radius() + b.world_radius():
				a.absorb(b)
				b.recycle()
				merged[a] = true
				merged[b] = true
				done += 1
				break
		if done >= 25:
			return


func _cull_far_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(_player.global_position) > DESPAWN_DIST:
			e.recycle()


func _get_enemy() -> Node:
	if _pool.size() > 0:
		return _pool.pop_back()
	var e := ENEMY_SCENE.instantiate()
	e.died.connect(_release_enemy)
	add_child(e)
	return e


func _release_enemy(e: Node) -> void:
	_pool.append(e)


func spawn_damage_number(pos: Vector2, amount: float, big: bool = false) -> void:
	if amount <= 0.0:
		return
	var dn
	if _dmg_pool.size() > 0:
		dn = _dmg_pool.pop_back()
	else:
		if _dmg_total >= MAX_DAMAGE_NUMBERS:
			return
		dn = DAMAGE_NUMBER.new()
		dn.finished.connect(_release_damage_number)
		add_child(dn)
		_dmg_total += 1
	dn.show_damage(pos, amount, Color(1.0, 0.95, 0.6), big)


func _release_damage_number(dn) -> void:
	_dmg_pool.append(dn)


func _spawn_one() -> void:
	var src: Dictionary = ENEMY_TYPES[_pick_type()]
	var data := src.duplicate()
	data["hp"] = float(src["hp"]) * (1.0 + _elapsed * 0.013)
	data["damage"] = float(src["damage"]) * (1.0 + _elapsed * 0.004)
	data["speed"] = float(src["speed"]) * (1.0 + _elapsed * 0.0008)
	data["xp"] = float(src["xp"]) * (1.0 + _elapsed * 0.006)
	var angle := randf() * TAU
	var pos := _player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	_get_enemy().activate(data, pos)


func _pick_type() -> String:
	var pool := ["grunt"]
	if _elapsed > 60.0:
		pool.append("runner")
	if _elapsed > 150.0:
		pool.append("brute")
	return pool.pick_random()


func _win() -> void:
	_won = true
	GameState.game_won.emit()
