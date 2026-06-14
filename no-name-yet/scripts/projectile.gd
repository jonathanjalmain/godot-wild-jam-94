extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _damage: float = 10.0
var _speed: float = 500.0
var _lifetime: float = 2.0


func setup(direction: Vector2, damage: float, speed: float) -> void:
	_direction = direction.normalized()
	_damage = damage
	_speed = speed
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(_damage)
		queue_free()
