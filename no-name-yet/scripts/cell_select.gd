extends Control


func _ready() -> void:
	$Center/Main/HBox/Hunter/VBox/Select.pressed.connect(_choose.bind("hunter"))
	$Center/Main/HBox/Bulwark/VBox/Select.pressed.connect(_choose.bind("bulwark"))
	$Center/Main/HBox/Sprinter/VBox/Select.pressed.connect(_choose.bind("sprinter"))
	$Center/Main/Back.pressed.connect(_on_back_pressed)
	$Center/Main/HBox/Hunter/VBox/Select.grab_focus()


func _choose(id: String) -> void:
	GameState.selected_cell = id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
