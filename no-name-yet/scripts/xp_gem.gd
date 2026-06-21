extends Area2D

@export var attract_speed: float = 380.0

var value: float = 1.0
var _player: Node2D
var _merged: bool = false


func _ready() -> void:
	add_to_group("xp_gems")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_refresh_size()


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if global_position.distance_to(_player.global_position) <= GameState.magnet_radius:
		global_position = global_position.move_toward(_player.global_position, attract_speed * delta)


func _on_area_entered(area: Area2D) -> void:
	if _merged or not area.is_in_group("xp_gems"):
		return
	if area.get_instance_id() < get_instance_id():
		return
	value += area.value
	area._merged = true
	area.queue_free()
	_refresh_size()


func _refresh_size() -> void:
	scale = Vector2.ONE * clampf(1.0 + (value - 1.0) * 0.12, 1.0, 2.6)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_xp(value)
		Audio.play("pickup", -6.0)
		queue_free()
