extends CharacterBody2D

const XP_GEM_SCENE := preload("res://scenes/XPGem.tscn")

@export var max_hp: float = 30.0
@export var speed: float = 90.0
@export var contact_damage: float = 10.0
@export var contact_interval: float = 0.5
@export var xp_value: float = 1.0

var hp: float
var _player: Node2D
var _contact_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	_handle_contact(delta)


func _handle_contact(delta: float) -> void:
	_contact_cooldown -= delta
	if _contact_cooldown > 0.0:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_collider() == _player:
			GameState.take_damage(contact_damage)
			_contact_cooldown = contact_interval
			return


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()


func _die() -> void:
	var gem := XP_GEM_SCENE.instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
	gem.value = xp_value
	queue_free()
