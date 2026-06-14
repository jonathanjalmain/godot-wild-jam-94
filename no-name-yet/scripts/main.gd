extends Node2D

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

@export var spawn_radius: float = 700.0

@onready var _player: Node2D = $Player
@onready var _spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	GameState.reset()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	GameState.player_died.connect(_on_player_died)


func _on_spawn_timer_timeout() -> void:
	if not GameState.alive:
		return
	var angle := randf() * TAU
	var pos := _player.global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = pos


func _on_player_died() -> void:
	print("Game Over")
