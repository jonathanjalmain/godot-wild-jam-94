extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")
const PULSE_RING_SCENE := preload("res://scenes/PulseRing.tscn")
const DASH_SPEED := 950.0
const DASH_TIME := 0.16
const DASH_BASE_COOLDOWN := 2.2
const NOVA_INTERVAL := 2.0
const PULSE_INTERVAL := 1.6

var _fire_cooldown: float = 0.0
var _nova_cooldown: float = 0.0
var _pulse_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _last_dir: Vector2 = Vector2.RIGHT
var _dash_was_pressed: bool = false

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	GameState.stats_changed.connect(_update_hitbox)
	_update_hitbox()


func _update_hitbox() -> void:
	(_collision.shape as CircleShape2D).radius = GameState.get_body_radius() * 0.9


func _physics_process(delta: float) -> void:
	if not GameState.alive:
		return
	_handle_dash(delta)
	_handle_movement()
	_handle_shooting(delta)
	_handle_nova(delta)
	_handle_pulse(delta)


func _handle_dash(delta: float) -> void:
	_dash_cooldown -= delta
	if _dash_timer > 0.0:
		_dash_timer -= delta
	GameState.invulnerable = _dash_timer > 0.0
	var pressed := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT)
	if pressed and not _dash_was_pressed and GameState.dash_level > 0 and _dash_cooldown <= 0.0:
		_dash_dir = _last_dir
		_dash_timer = DASH_TIME
		_dash_cooldown = maxf(DASH_BASE_COOLDOWN - float(GameState.dash_level - 1) * 0.4, 0.5)
		Audio.play("pickup", -4.0)
	_dash_was_pressed = pressed


func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		_last_dir = dir.normalized()
	if _dash_timer > 0.0:
		velocity = _dash_dir * DASH_SPEED
	else:
		velocity = dir.normalized() * GameState.move_speed
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	_fire_cooldown = 1.0 / max(GameState.fire_rate, 0.01)
	Audio.play("shoot", -30.0, 0.08)
	_fire_at(target.global_position)


func _handle_nova(delta: float) -> void:
	if GameState.nova_level <= 0:
		return
	_nova_cooldown -= delta
	if _nova_cooldown > 0.0:
		return
	_nova_cooldown = maxf(NOVA_INTERVAL - float(GameState.nova_level) * 0.12, 0.7)
	var n := 6 + GameState.nova_level * 2
	var dmg := GameState.get_shot_damage()
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / float(n))
		var p := PROJECTILE_SCENE.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		p.setup(dir, dmg, GameState.projectile_speed, GameState.projectile_pierce, GameState.poison_dps, GameState.poison_duration)
	Audio.play("nova", -14.0)


func _handle_pulse(delta: float) -> void:
	if GameState.pulse_level <= 0:
		return
	_pulse_cooldown -= delta
	if _pulse_cooldown > 0.0:
		return
	_pulse_cooldown = maxf(PULSE_INTERVAL - float(GameState.pulse_level) * 0.1, 0.6)
	var radius := 110.0 + float(GameState.pulse_level) * 22.0
	var dmg := GameState.get_shot_damage() * 1.5
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg, global_position)
	var ring := PULSE_RING_SCENE.instantiate()
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.max_radius = radius
	Audio.play("nova", -14.0)


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best_dist := GameState.projectile_range
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			nearest = e
	return nearest


func _fire_at(target_pos: Vector2) -> void:
	var base_dir := (target_pos - global_position).normalized()
	var count: int = max(GameState.projectile_count, 1)
	var dmg := GameState.get_shot_damage()
	var spread := deg_to_rad(12.0)
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = spread * (float(i) - float(count - 1) / 2.0)
		var dir := base_dir.rotated(offset)
		var p := PROJECTILE_SCENE.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		p.setup(dir, dmg, GameState.projectile_speed, GameState.projectile_pierce, GameState.poison_dps, GameState.poison_duration)
