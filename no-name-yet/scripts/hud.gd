extends CanvasLayer

@onready var _hp_bar: ProgressBar = $HPBar
@onready var _xp_bar: ProgressBar = $XPBar
@onready var _level_label: Label = $LevelLabel
@onready var _time_label: Label = $TimeLabel

var _time: float = 0.0


func _ready() -> void:
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	_on_hp_changed(GameState.hp, GameState.max_hp)
	_on_xp_changed(GameState.xp, GameState.xp_to_next, GameState.level)


func _process(delta: float) -> void:
	if GameState.alive:
		_time += delta
	var minutes := int(_time) / 60
	var seconds := int(_time) % 60
	_time_label.text = "%02d:%02d" % [minutes, seconds]


func _on_hp_changed(current: float, maximum: float) -> void:
	_hp_bar.value = (current / maximum * 100.0) if maximum > 0.0 else 0.0


func _on_xp_changed(current: float, needed: float, level: int) -> void:
	_xp_bar.value = (current / needed * 100.0) if needed > 0.0 else 0.0
	_level_label.text = "Level %d" % level
