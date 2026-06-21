extends CharacterBody2D

signal died(enemy)

const XP_GEM_SCENE := preload("res://scenes/XPGem.tscn")
const DEATH_BURST_SCENE := preload("res://scenes/DeathBurst.tscn")
const RADIUS := 14.0

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
var _phase := 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_phase = randf() * TAU


func activate(data: Dictionary, pos: Vector2) -> void:
	configure(data)
	global_position = pos
	hp = max_hp
	_dead = false
	_player = null
	_knockback = Vector2.ZERO
	_flash = 0.0
	_poison_dps = 0.0
	_poison_time = 0.0
	_contact_cooldown = 0.0
	add_to_group("enemies")
	visible = true
	_shape.disabled = false
	set_physics_process(true)
	queue_redraw()


func deactivate() -> void:
	remove_from_group("enemies")
	visible = false
	_shape.disabled = true
	set_physics_process(false)
	global_position = Vector2(1.0e6, 1.0e6)


func world_radius() -> float:
	return RADIUS * scale.x


func absorb(other) -> void:
	max_hp += other.max_hp
	hp += other.hp
	contact_damage = maxf(contact_damage, other.contact_damage)
	xp_value += other.xp_value
	var combined := sqrt(scale.x * scale.x + other.scale.x * other.scale.x)
	scale = Vector2.ONE * minf(combined, 3.2)
	queue_redraw()


func recycle() -> void:
	if _dead:
		return
	_dead = true
	_do_recycle.call_deferred()


func _do_recycle() -> void:
	deactivate()
	died.emit(self)


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
			queue_redraw()


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
	_flash = 0.1
	queue_redraw()
	var parent := get_parent()
	if parent != null and parent.has_method("spawn_damage_number"):
		var head := global_position + Vector2(0.0, -(RADIUS * scale.x + 14.0))
		parent.spawn_damage_number(head, amount, amount >= 30.0)
	if from_pos != null:
		_knockback = (global_position - from_pos).normalized() * 220.0 * GameState.knockback_mult
	if hp <= 0.0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	_do_death.call_deferred()


func _do_death() -> void:
	Audio.play("hit", -4.0)
	GameState.on_enemy_killed()
	_spawn_drops(global_position, xp_value, _color, scale.x)
	deactivate()
	died.emit(self)


func _draw() -> void:
	var c := _color
	if _flash > 0.0:
		c = c.lerp(Color(1.8, 1.8, 1.8), 0.6)
	draw_circle(Vector2.ZERO, RADIUS * 1.18, Color(c.r, c.g, c.b, 0.35))
	for i in 5:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 5.0 + _phase)
		draw_line(dir * RADIUS, dir * (RADIUS + 4.0), c.darkened(0.2), 2.0)
	draw_circle(Vector2.ZERO, RADIUS, c)
	draw_circle(Vector2.ZERO, RADIUS * 0.4, c.darkened(0.4))


func _spawn_drops(pos: Vector2, value: float, color: Color, enemy_scale: float) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var gem := XP_GEM_SCENE.instantiate()
	parent.add_child(gem)
	gem.global_position = pos
	gem.value = value
	var burst := DEATH_BURST_SCENE.instantiate()
	parent.add_child(burst)
	burst.global_position = pos
	burst.modulate = color
	burst.scale = Vector2.ONE * enemy_scale
