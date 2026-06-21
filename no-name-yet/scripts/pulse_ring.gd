extends Node2D

var max_radius: float = 120.0

var _t: float = 0.0
var _dur: float = 0.3


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()


func _draw() -> void:
	var f := _t / _dur
	draw_arc(Vector2.ZERO, max_radius * f, 0.0, TAU, 48, Color(0.6, 1.0, 0.8, 1.0 - f), 4.0)
