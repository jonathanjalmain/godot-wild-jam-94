extends CanvasLayer

@onready var _root: Control = $Control
@onready var _resume: Button = $Control/Center/Panel/VBox/Resume
@onready var _quit: Button = $Control/Center/Panel/VBox/Quit

var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_resume.pressed.connect(close)
	_quit.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _open:
		close()
	elif not get_tree().paused and GameState.alive:
		_open_menu()
	get_viewport().set_input_as_handled()


func _open_menu() -> void:
	_open = true
	_root.visible = true
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	_open = false
	_root.visible = false
	get_tree().paused = false


func _on_quit_pressed() -> void:
	_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
