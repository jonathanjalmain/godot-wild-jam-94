extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const SURVIVE_SECONDS := 600.0

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


func _ready() -> void:
	GameState.reset()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)


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
	var count := 1 + int(_elapsed / 90.0)
	for i in count:
		_spawn_one()


func _spawn_one() -> void:
	var data: Dictionary = ENEMY_TYPES[_pick_type()]
	var angle := randf() * TAU
	var pos := _player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	var enemy := ENEMY_SCENE.instantiate()
	enemy.configure(data)
	add_child(enemy)
	enemy.global_position = pos


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
