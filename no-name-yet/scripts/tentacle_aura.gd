extends Area2D

const BASE_RADIUS := 44.0

@export var tick_interval: float = 0.4

var _tick: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Polygon2D


func _ready() -> void:
	GameState.stats_changed.connect(_update_state)
	_update_state()


func _update_state() -> void:
	var lvl := GameState.tentacle_level
	visible = lvl > 0
	monitoring = lvl > 0
	var radius := BASE_RADIUS + float(max(lvl - 1, 0)) * 16.0
	(_shape.shape as CircleShape2D).radius = radius
	_visual.scale = Vector2.ONE * (radius / BASE_RADIUS)


func _process(delta: float) -> void:
	if GameState.tentacle_level <= 0:
		return
	rotation += delta * 3.0
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = tick_interval
	var dmg := 6.0 * float(GameState.tentacle_level)
	for b in get_overlapping_bodies():
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(dmg, global_position)
