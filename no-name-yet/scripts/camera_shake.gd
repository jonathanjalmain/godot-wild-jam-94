extends Camera2D

@export var decay: float = 2.5
@export var max_offset: float = 10.0

var _trauma: float = 0.0


func _ready() -> void:
	GameState.shake_requested.connect(_add_trauma)


func _add_trauma(amount: float) -> void:
	_trauma = min(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = max(_trauma - decay * delta, 0.0)
	var amount := _trauma * _trauma * max_offset
	offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
