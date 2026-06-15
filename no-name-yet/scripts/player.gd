extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

var _fire_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not GameState.alive:
		return
	_handle_movement()
	_handle_shooting(delta)


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
	_fire_at(target.global_position)


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
	var spread := deg_to_rad(12.0)
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = spread * (float(i) - float(count - 1) / 2.0)
		var dir := base_dir.rotated(offset)
		var p := PROJECTILE_SCENE.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		p.setup(dir, GameState.damage, GameState.projectile_speed, GameState.projectile_pierce, GameState.poison_dps, GameState.poison_duration)
