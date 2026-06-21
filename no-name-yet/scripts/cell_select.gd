extends Control

@onready var _row: HBoxContainer = $Center/Main/Row
@onready var _back: Button = $Center/Main/Back

const ORDER := ["hunter", "bulwark", "sprinter"]
const STAT_LABELS := {
	"max_hp": "HP",
	"move_speed": "Speed",
	"fire_rate": "Fire Rate",
	"damage": "Damage",
}


func _ready() -> void:
	_back.pressed.connect(_on_back_pressed)
	var first: Button = null
	for id in ORDER:
		var card := _make_card(id)
		_row.add_child(card)
		if first == null:
			first = card
	if first:
		first.grab_focus()


func _make_card(id: String) -> Button:
	var data: Dictionary = GameState.CELLS[id]
	var color: Color = data.color

	var card := Button.new()
	card.custom_minimum_size = Vector2(320, 440)
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _card_box(color, 0.0))
	card.add_theme_stylebox_override("hover", _card_box(color, 0.7))
	card.add_theme_stylebox_override("pressed", _card_box(color, 0.9))
	card.add_theme_stylebox_override("focus", _card_box(color, 0.7))
	card.pressed.connect(_choose.bind(id))

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 22
	vb.offset_top = 24
	vb.offset_right = -22
	vb.offset_bottom = -22
	vb.add_theme_constant_override("separation", 12)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vb)

	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_make_preview(color))
	vb.add_child(holder)

	vb.add_child(_label(data.name, 34, color.lightened(0.25), true))
	vb.add_child(_label(data.desc, 17, Color(0.74, 0.85, 0.83), true))

	var stats := _format_stats(data)
	if stats != "":
		vb.add_child(_label(stats, 16, Color(0.9, 0.95, 0.8), true))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(spacer)

	var start_ids: Array = data.get("start", [])
	if start_ids.size() > 0:
		vb.add_child(_label("Starts with: %s" % GameState.mutation_title(start_ids[0]), 16, color.lightened(0.3), true))

	return card


func _make_preview(color: Color) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(160, 160)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var body := Panel.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(color.r, color.g, color.b, 0.85)
	bs.set_corner_radius_all(80)
	bs.border_color = color.lightened(0.35)
	bs.set_border_width_all(5)
	body.add_theme_stylebox_override("panel", bs)
	holder.add_child(body)

	var nucleus := Panel.new()
	nucleus.size = Vector2(60, 60)
	nucleus.position = Vector2(50, 50)
	nucleus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ns := StyleBoxFlat.new()
	ns.bg_color = color.darkened(0.45)
	ns.set_corner_radius_all(30)
	nucleus.add_theme_stylebox_override("panel", ns)
	holder.add_child(nucleus)

	return holder


func _label(text: String, size: int, color: Color, center: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _card_box(color: Color, highlight: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06 + color.r * 0.05 * highlight, 0.12 + color.g * 0.04 * highlight, 0.15, 0.96)
	sb.border_color = Color(color.r, color.g, color.b, 0.45 + 0.55 * highlight)
	sb.set_border_width_all(2)
	sb.border_width_top = 5
	sb.set_corner_radius_all(18)
	return sb


func _format_stats(data: Dictionary) -> String:
	var mods: Dictionary = data.get("stats", {})
	var parts: Array = []
	for k in mods:
		var pct := int(round((float(mods[k]) - 1.0) * 100.0))
		if pct == 0:
			continue
		var sign := "+" if pct > 0 else ""
		parts.append("%s%d%% %s" % [sign, pct, STAT_LABELS.get(k, k)])
	return "   ".join(parts)


func _choose(id: String) -> void:
	GameState.selected_cell = id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
