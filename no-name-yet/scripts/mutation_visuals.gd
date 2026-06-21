extends Node2D

const UNSTABLE_IDS := ["glass_cells", "berserk", "cancerous_growth", "toxic_blood", "unstable_mitosis"]

var _t: float = 0.0


func _ready() -> void:
	GameState.stats_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var count := GameState.cell_count()
	var base := GameState.get_cell_color()
	var r_main := GameState.get_cell_radius(0)

	# Positions: main cell at center, satellites bonded around it
	var positions: Array = [Vector2.ZERO]
	for g in range(1, count):
		var a := TAU * float(g - 1) / float(maxi(count - 1, 1)) + _t * 0.1
		var rs := GameState.get_cell_radius(g)
		var dist := r_main + rs * 0.85
		positions.append(Vector2.RIGHT.rotated(a) * dist)

	# Bonds linking each satellite to the core (behind cells)
	var bond_col := Color(base.r, base.g, base.b, 0.3)
	for g in range(1, count):
		var w := minf(r_main, GameState.get_cell_radius(g))
		draw_line(Vector2.ZERO, positions[g], bond_col, w * 0.9)
		draw_line(Vector2.ZERO, positions[g], base, w * 0.45)

	# Each cell drawn from its own generation's mutations
	for g in range(count):
		draw_set_transform(positions[g])
		_draw_cell(GameState.get_cell_radius(g), GameState.get_cell_stacks(g), base)
	draw_set_transform(Vector2.ZERO)


func _draw_cell(r: float, st: Dictionary, base: Color) -> void:
	var pulse := 1.0 + 0.05 * sin(_t * 3.0)

	var body := base
	var venom := _count(st, "venom") + _count(st, "toxic_blood")
	if venom > 0:
		body = body.lerp(Color(0.55, 1.0, 0.2), minf(venom * 0.28, 0.85))
	var hemo := _count(st, "hemovore") + _count(st, "second_heart")
	if hemo > 0:
		body = body.lerp(Color(0.9, 0.2, 0.25), minf(hemo * 0.22, 0.65))
	var unstable := 0
	for id in UNSTABLE_IDS:
		unstable += _count(st, id)
	if unstable > 0:
		body = body.lerp(Color(0.55, 0.15, 0.5), minf(unstable * 0.16, 0.55))

	var molt := _count(st, "molt")
	if molt > 0:
		var ring := Color(body.r, body.g, body.b, 0.12 * float(mini(molt, 3)))
		draw_arc(Vector2.ZERO, r * (1.3 + 0.08 * sin(_t * 1.5)), 0.0, TAU, 40, ring, 3.0)

	var knock := _count(st, "knockback_rounds")
	if knock > 0:
		var kr := r * (1.18 + 0.12 * absf(sin(_t * 2.0)))
		draw_arc(Vector2.ZERO, kr, 0.0, TAU, 40, Color(1.0, 0.7, 0.3, 0.25), 2.5)

	var flag := _count(st, "hyper_velocity")
	for i in flag:
		var pts := PackedVector2Array()
		for s in 9:
			var f := float(s) / 8.0
			var x := sin(_t * 7.0 + f * 6.0 + float(i)) * 6.0 * f + float(i) * 5.0 - float(flag) * 2.0
			pts.append(Vector2(x, r * 0.8 + f * (22.0 + float(i) * 4.0)))
		draw_polyline(pts, body.darkened(0.2), 2.5)

	var arms := _count(st, "extra_arm") + _count(st, "twin_spores")
	for i in arms:
		var side := 1.0 if i % 2 == 0 else -1.0
		var idx := i / 2
		var a := side * (PI * 0.5 + 0.35 + float(idx) * 0.4)
		var shoulder := Vector2.RIGHT.rotated(a) * r
		var hand := Vector2.RIGHT.rotated(a) * (r + 14.0 + float(idx) * 4.0)
		draw_line(shoulder, hand, body.darkened(0.2), 5.0)
		draw_circle(hand, 4.0, body.darkened(0.05))

	var mito := _count(st, "mitosis") + _count(st, "unstable_mitosis")
	if mito > 0:
		var ghost := body
		ghost.a = 0.3
		draw_circle(Vector2(r * 0.75, 0.0), r * 0.85, ghost)

	var cara := _count(st, "carapace")
	if cara > 0:
		draw_circle(Vector2.ZERO, r + 3.0 + float(cara) * 1.5, Color(0.2, 0.26, 0.32))

	var membrane := Color(body.r, body.g, body.b, 0.32)
	draw_circle(Vector2.ZERO, r * 1.15 * pulse, membrane)
	draw_circle(Vector2.ZERO, r, body)

	var cilia := _count(st, "adrenaline")
	if cilia > 0:
		var n := 10 + cilia * 4
		for i in n:
			var a := TAU * float(i) / float(n)
			var b := Vector2.RIGHT.rotated(a) * r
			var tip := b + Vector2.RIGHT.rotated(a + sin(_t * 8.0 + float(i)) * 0.3) * (5.0 + float(cilia))
			draw_line(b, tip, body.darkened(0.1), 1.5)

	var spikes := _count(st, "spiny_skin") + _count(st, "barbed_spikes")
	if spikes > 0:
		var n := 6 + spikes * 2
		var length := 6.0 + float(spikes) * 2.0
		for i in n:
			var a := TAU * float(i) / float(n)
			var dir := Vector2.RIGHT.rotated(a)
			var perp := Vector2.RIGHT.rotated(a + PI * 0.5) * 3.0
			var b := dir * r
			var tip := dir * (r + length)
			draw_colored_polygon(PackedVector2Array([b - perp, b + perp, tip]), Color(0.85, 0.85, 0.92))

	draw_circle(Vector2.ZERO, r * 0.4, body.darkened(0.4))

	var organelles: Array = []
	_collect(organelles, st, "metabolism", Color(1.0, 0.55, 0.1))
	_collect(organelles, st, "berserk", Color(1.0, 0.4, 0.1))
	_collect(organelles, st, "heavy_rounds", Color(0.16, 0.16, 0.22))
	_collect(organelles, st, "glass_cells", Color(0.8, 0.95, 1.0))
	_collect(organelles, st, "toxic_blood", Color(0.7, 0.95, 0.2))
	_collect(organelles, st, "second_heart", Color(0.95, 0.3, 0.35))
	_collect(organelles, st, "regeneration", Color(0.4, 1.0, 0.5))
	_collect(organelles, st, "dash", Color(0.4, 0.95, 1.0))
	_collect(organelles, st, "magnetism", Color(0.6, 0.6, 0.95))
	_collect(organelles, st, "spore_nova", Color(0.9, 0.95, 0.5))
	_collect(organelles, st, "orbital_spores", Color(0.5, 0.95, 0.7))
	_collect(organelles, st, "pulse_nova", Color(0.7, 0.95, 1.0))
	for i in organelles.size():
		var ang := float(i) * 2.39996 + _t * 0.4
		var dist := r * 0.62 * sqrt(float(i + 1) / float(organelles.size() + 1))
		var p := Vector2.RIGHT.rotated(ang) * dist
		var size := clampf(r * 0.13, 2.0, 6.0) * (1.0 + 0.15 * sin(_t * 4.0 + float(i)))
		draw_circle(p, size, organelles[i])

	var eyes := _count(st, "compound_eyes")
	if eyes > 0:
		var n := mini(eyes + 1, 6)
		for i in n:
			var a := -PI * 0.5 + (float(i) - float(n - 1) * 0.5) * 0.5
			var pos := Vector2.RIGHT.rotated(a) * r * 0.55
			draw_circle(pos, 4.0, Color.WHITE)
			draw_circle(pos, 2.0, Color.BLACK)

	var crit := _count(st, "mutated_cells") + _count(st, "frenzy")
	if crit > 0:
		var top := Vector2(0.0, -r * 0.55)
		draw_circle(top, 5.0, Color(1.0, 0.9, 0.2))
		draw_circle(top, 2.5, Color.BLACK)


func _count(st: Dictionary, id: String) -> int:
	return int(st.get(id, 0))


func _collect(into: Array, st: Dictionary, id: String, color: Color) -> void:
	for i in _count(st, id):
		into.append(color)
