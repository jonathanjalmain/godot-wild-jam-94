extends CharacterBody2D

const XP_GEM_SCENE := preload("res://scenes/XPGem.tscn")
const DEATH_BURST_SCENE := preload("res://scenes/DeathBurst.tscn")

@export var max_hp: float = 30.0
@export var speed: float = 90.0
@export var contact_damage: float = 10.0
@export var contact_interval: float = 0.5
@export var xp_value: float = 1.0

var hp: float
var _player: Node2D
var _contact_cooldown: float = 0.0
var _color := Color(0.9, 0.3, 0.3)
var _knockback := Vector2.ZERO
var _flash := 0.0
var _poison_dps := 0.0
var _poison_time := 0.0
var _dead := false

@onready var _polygon: Polygon2D = $Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_polygon.color = _color


func configure(data: Dictionary) -> void:
	max_hp = data.get("hp", max_hp)
	speed = data.get("speed", speed)
	contact_damage = data.get("damage", contact_damage)
	xp_value = data.get("xp", xp_value)
	_color = data.get("color", _color)
	scale = Vector2.ONE * float(data.get("scale", 1.0))


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * speed + _knockback
	move_and_slide()
	_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	_handle_contact(delta)
	_handle_flash(delta)
	_handle_poison(delta)


func _handle_contact(delta: float) -> void:
	_contact_cooldown -= delta
	if _contact_cooldown > 0.0:
		return
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == _player:
			GameState.take_damage(contact_damage)
			_contact_cooldown = contact_interval
			if GameState.thorns_damage > 0.0:
				take_damage(GameState.thorns_damage, _player.global_position)
			return


func _handle_flash(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			_polygon.color = _color


func _handle_poison(delta: float) -> void:
	if _poison_time > 0.0:
		_poison_time -= delta
		hp -= _poison_dps * delta
		if hp <= 0.0:
			_die()


func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = max(_poison_dps, dps)
	_poison_time = max(_poison_time, duration)


func take_damage(amount: float, from_pos = null) -> void:
	if _dead:
		return
	hp -= amount
	_flash = 0.08
	_polygon.color = Color(1.8, 1.8, 1.8)
	if from_pos != null:
		_knockback = (global_position - from_pos).normalized() * 220.0
	if hp <= 0.0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	var gem := XP_GEM_SCENE.instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
	gem.value = xp_value
	var burst := DEATH_BURST_SCENE.instantiate()
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.modulate = _color
	queue_free()
