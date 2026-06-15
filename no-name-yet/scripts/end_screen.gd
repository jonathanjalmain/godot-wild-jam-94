extends CanvasLayer

@onready var _root: Control = $Control
@onready var _title: Label = $Control/Center/Panel/VBox/Title
@onready var _restart: Button = $Control/Center/Panel/VBox/Restart


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_restart.pressed.connect(_on_restart_pressed)
	GameState.player_died.connect(_on_player_died)
	GameState.game_won.connect(_on_game_won)


func _on_player_died() -> void:
	_show("You Died")


func _on_game_won() -> void:
	_show("You Survived!")


func _show(text: String) -> void:
	_title.text = text
	_root.visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
