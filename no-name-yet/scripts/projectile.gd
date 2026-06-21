extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _damage: float = 10.0
var _speed: float = 500.0
var _lifetime: float = 1.4
var _pierce: int = 0
var _poison_dps: float = 0.0
var _poison_dur: float = 0.0


func setup(direction: Vector2, damage: float, speed: float, pierce: int = 0, poison_dps: float = 0.0, poison_dur: float = 0.0) -> void:
	_direction = direction.normalized()
	_damage = damage
	_speed = speed
	_pierce = pierce
	_poison_dps = poison_dps
	_poison_dur = poison_dur
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage, global_position)
	if _poison_dps > 0.0 and body.has_method("apply_poison"):
		body.apply_poison(_poison_dps, _poison_dur)
	if _pierce > 0:
		_pierce -= 1
	else:
		queue_free()
