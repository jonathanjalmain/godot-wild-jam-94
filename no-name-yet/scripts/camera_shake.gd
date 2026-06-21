extends Camera2D

@export var decay: float = 2.5
@export var max_offset: float = 10.0
@export var reference_radius: float = 22.0
@export var min_zoom: float = 0.6
@export var zoom_speed: float = 4.0

var _trauma: float = 0.0


func _ready() -> void:
	GameState.shake_requested.connect(_add_trauma)
	var z := _target_zoom()
	zoom = Vector2(z, z)


func _add_trauma(amount: float) -> void:
	_trauma = min(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	var z := _target_zoom()
	zoom = zoom.lerp(Vector2(z, z), minf(zoom_speed * delta, 1.0))

	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = max(_trauma - decay * delta, 0.0)
	var amount := _trauma * _trauma * max_offset
	offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _target_zoom() -> float:
	return clampf(reference_radius / GameState.get_molecule_extent(), min_zoom, 1.0)
