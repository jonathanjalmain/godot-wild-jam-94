extends Control

@onready var _play: Button = $Center/VBox/Play
@onready var _quit: Button = $Center/VBox/Quit


func _ready() -> void:
	_play.pressed.connect(_on_play_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_play.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
