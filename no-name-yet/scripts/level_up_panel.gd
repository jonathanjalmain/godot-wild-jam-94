extends CanvasLayer

@onready var _root: Control = $Control
@onready var _choices: HBoxContainer = $Control/Center/Box/Choices
@onready var _sub: Label = $Control/Center/Box/Sub

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
	_sub.text = "Level %d reached - choose an evolution" % GameState.level
	for c in _choices.get_children():
		c.queue_free()
	for m in GameState.get_random_mutations(3):
		_choices.add_child(_make_card(m))
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Control).grab_focus()
	_root.visible = true
	get_tree().paused = true


func _make_card(m: Dictionary) -> Button:
	var unstable: bool = m.get("unstable", false)
	var owned: int = int(GameState.stacks.get(m.id, 0))
	var is_upgrade: bool = m.get("unique", false) and owned > 0
	var accent: Color = GameState.cat_color(m.cat)
	var tag_text: String = "UNSTABLE" if unstable else String(m.cat).to_upper()
	var desc_text: String = m.desc
	if is_upgrade:
		accent = Color(1.0, 0.82, 0.3)
		tag_text = "UPGRADE  Lv %d -> %d" % [owned, owned + 1]
		desc_text = m.get("up_desc", m.desc)

	var card := Button.new()
	card.custom_minimum_size = Vector2(300, 330)
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _card_box(accent, 0.0))
	card.add_theme_stylebox_override("hover", _card_box(accent, 0.7))
	card.add_theme_stylebox_override("pressed", _card_box(accent, 0.9))
	card.add_theme_stylebox_override("focus", _card_box(accent, 0.7))
	card.pressed.connect(_on_choice.bind(m.id))

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20
	vb.offset_top = 20
	vb.offset_right = -20
	vb.offset_bottom = -20
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vb)

	vb.add_child(_label(tag_text, 16, accent))

	var title := _label(m.title, 28, Color(0.96, 1.0, 0.97))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(title)

	if owned > 0 and not m.get("unique", false):
		vb.add_child(_label("OWNED x%d" % owned, 15, Color(1.0, 0.85, 0.4)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(spacer)

	var desc := _label(desc_text, 17, Color(0.74, 0.85, 0.83))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	return card


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _card_box(accent: Color, highlight: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06 + accent.r * 0.05 * highlight, 0.12 + accent.g * 0.04 * highlight, 0.14, 0.97)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.45 + 0.55 * highlight)
	sb.set_border_width_all(2)
	sb.border_width_top = 5
	sb.set_corner_radius_all(16)
	return sb


func _on_choice(id: String) -> void:
	GameState.apply_mutation(id)
	_show_next()
