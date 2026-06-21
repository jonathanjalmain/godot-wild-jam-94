extends Node2D

const ORB_RADIUS := 12.0
const ORBIT_DIST := 78.0

@export var tick: float = 0.3
@export var spin: float = 2.6

var _angle: float = 0.0
var _tick_t: float = 0.0
var _orbs: Array = []


func _ready() -> void:
	GameState.stats_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	var want := GameState.orbit_level * 2
	while _orbs.size() < want:
		var o := Area2D.new()
		o.collision_layer = 0
		o.collision_mask = 2
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = ORB_RADIUS
		cs.shape = sh
		o.add_child(cs)
		add_child(o)
		_orbs.append(o)
	while _orbs.size() > want:
		_orbs.pop_back().queue_free()
	visible = want > 0


func _process(delta: float) -> void:
	if GameState.orbit_level <= 0:
		return
	_angle += spin * delta
	var n := _orbs.size()
	for i in n:
		_orbs[i].position = Vector2.RIGHT.rotated(_angle + TAU * float(i) / float(n)) * ORBIT_DIST
	queue_redraw()
	_tick_t -= delta
	if _tick_t > 0.0:
		return
	_tick_t = tick
	var dmg := 7.0 * float(GameState.orbit_level)
	for o in _orbs:
		for b in o.get_overlapping_bodies():
			if b.is_in_group("enemies") and b.has_method("take_damage"):
				b.take_damage(dmg, o.global_position)


func _draw() -> void:
	for o in _orbs:
		draw_circle(o.position, ORB_RADIUS, Color(0.5, 0.95, 0.7, 0.9))
		draw_circle(o.position, ORB_RADIUS * 0.5, Color(0.2, 0.55, 0.45))
