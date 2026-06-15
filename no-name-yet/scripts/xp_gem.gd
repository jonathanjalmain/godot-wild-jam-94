extends Area2D

@export var attract_radius: float = 90.0
@export var attract_speed: float = 340.0

var value: float = 1.0
var _player: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if global_position.distance_to(_player.global_position) <= attract_radius:
		global_position = global_position.move_toward(_player.global_position, attract_speed * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_xp(value)
		queue_free()
