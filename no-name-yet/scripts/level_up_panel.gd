extends CanvasLayer

@onready var _root: Control = $Control
@onready var _choices: VBoxContainer = $Control/Center/Panel/VBox/Choices

var _pending: int = 0
var _showing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	GameState.level_up.connect(_on_level_up)


func _on_level_up(_new_level: int) -> void:
	_pending += 1
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _pending <= 0:
		_root.visible = false
		_showing = false
		get_tree().paused = false
		return
	_pending -= 1
	_showing = true
	for c in _choices.get_children():
		c.queue_free()
	for m in GameState.get_random_mutations(3):
		var b := Button.new()
		b.text = "%s\n%s" % [m.title, m.desc]
		b.custom_minimum_size = Vector2(380, 80)
		b.pressed.connect(_on_choice.bind(m.id))
		_choices.add_child(b)
	_root.visible = true
	get_tree().paused = true


func _on_choice(id: String) -> void:
	GameState.apply_mutation(id)
	_show_next()
