extends Node2D

signal finished(node)

const LIFETIME := 0.6
const RISE := 60.0

var _t: float = 0.0
var _text: String = ""
var _color: Color = Color.WHITE
var _size: int = 22
var _vel: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	z_index = 200
	visible = false
	set_process(false)


func show_damage(pos: Vector2, amount: float, color: Color, big: bool) -> void:
	global_position = pos
	_text = str(int(round(amount)))
	_color = color
	_size = 30 if big else 22
	_t = 0.0
	_active = true
	visible = true
	_vel = Vector2(randf_range(-22.0, 22.0), -RISE)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	position += _vel * delta
	_vel.y += 70.0 * delta
	queue_redraw()
	if _t >= LIFETIME:
		_active = false
		visible = false
		set_process(false)
		finished.emit(self)


func _draw() -> void:
	if not _active:
		return
	var f := _t / LIFETIME
	var alpha := clampf(1.0 - f * f, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
	var origin := Vector2(-w * 0.5, 0.0)
	draw_string_outline(font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, 5, Color(0.0, 0.0, 0.0, alpha))
	draw_string(font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, Color(_color.r, _color.g, _color.b, alpha))
