extends Node

signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, needed: float, level: int)
signal level_up(new_level: int)
signal player_died
signal game_won
signal stats_changed
signal shake_requested(amount: float)

var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 220.0
var fire_rate: float = 2.0
var damage: float = 10.0
var projectile_count: int = 1
var projectile_speed: float = 500.0
var projectile_range: float = 600.0
var projectile_pierce: int = 0
var thorns_damage: float = 0.0
var poison_dps: float = 0.0
var poison_duration: float = 3.0
var orbit_level: int = 0
var pulse_level: int = 0
var damage_reduction: float = 0.0
var damage_taken_mult: float = 1.0
var regen: float = 0.0
var degen: float = 0.0
var lifesteal: float = 0.0
var crit_chance: float = 0.0
var crit_mult: float = 2.0
var knockback_mult: float = 1.0
var dash_level: int = 0
var nova_level: int = 0
var magnet_radius: float = 130.0
var invulnerable: bool = false

var stacks: Dictionary = {}
var mutation_order: Array = []

var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 5.0
var alive: bool = true

const CELL_GROUP_SIZE := 3
const BASE_CELL_RADIUS := 20.0
var selected_cell: String = "hunter"

const CELLS := {
	"hunter": {
		"name": "Hunter",
		"desc": "Aggressive. Fires an extra projectile from the start.",
		"color": Color(0.9, 0.45, 0.4),
		"stats": {},
		"start": ["extra_arm"],
	},
	"bulwark": {
		"name": "Bulwark",
		"desc": "Tanky. Slow but very hard to kill.",
		"color": Color(0.5, 0.7, 0.95),
		"stats": {"max_hp": 1.6, "move_speed": 0.9},
		"start": ["carapace"],
	},
	"sprinter": {
		"name": "Sprinter",
		"desc": "Fast and evasive. +fire rate, starts with a dash.",
		"color": Color(0.5, 0.95, 0.7),
		"stats": {"move_speed": 1.2, "fire_rate": 1.15},
		"start": ["dash"],
	},
}

const MUTATIONS := [
	{"id": "extra_arm", "title": "Extra Arm", "desc": "+1 projectile per shot", "cat": "offense"},
	{"id": "metabolism", "title": "Metabolism", "desc": "+20% fire rate", "cat": "offense"},
	{"id": "compound_eyes", "title": "Compound Eyes", "desc": "+25% range and speed", "cat": "utility"},
	{"id": "molt", "title": "Molt", "desc": "+25 max HP and full heal", "cat": "defense"},
	{"id": "orbital_spores", "title": "Orbital Spores", "desc": "Orbiting spores that shred nearby foes", "cat": "offense", "unique": true, "max": 5, "up_desc": "+2 orbiting spores and more damage"},
	{"id": "pulse_nova", "title": "Pulse Nova", "desc": "Periodic shockwave damaging all around you", "cat": "offense", "unique": true, "max": 5, "up_desc": "Wider, faster shockwave"},
	{"id": "spiny_skin", "title": "Spiny Skin", "desc": "Hurt enemies on contact", "cat": "defense"},
	{"id": "venom", "title": "Venom", "desc": "Shots poison enemies", "cat": "offense"},
	{"id": "mitosis", "title": "Mitosis", "desc": "Shots pierce +1 enemy", "cat": "offense"},
	{"id": "carapace", "title": "Carapace", "desc": "Take 12% less damage", "cat": "defense"},
	{"id": "regeneration", "title": "Regeneration", "desc": "Regen 2 HP per second", "cat": "defense"},
	{"id": "adrenaline", "title": "Adrenaline", "desc": "+15% move speed", "cat": "utility"},
	{"id": "hemovore", "title": "Hemovore", "desc": "Heal 2 HP per kill", "cat": "defense"},
	{"id": "gigantism", "title": "Gigantism", "desc": "+40 max HP, +15% damage, bigger body", "cat": "defense"},
	{"id": "mutated_cells", "title": "Mutated Cells", "desc": "+12% critical hit chance", "cat": "offense"},
	{"id": "heavy_rounds", "title": "Heavy Rounds", "desc": "+50% damage, -20% fire rate", "cat": "offense"},
	{"id": "hyper_velocity", "title": "Hyper Velocity", "desc": "+40% projectile speed, +15% range", "cat": "offense"},
	{"id": "second_heart", "title": "Second Heart", "desc": "+50 max HP, +1 HP/sec", "cat": "defense"},
	{"id": "frenzy", "title": "Frenzy", "desc": "+8% crit, +0.5 crit damage", "cat": "offense"},
	{"id": "knockback_rounds", "title": "Knockback Rounds", "desc": "+80% knockback on hit", "cat": "utility"},
	{"id": "compact_form", "title": "Compact Form", "desc": "Smaller body & hitbox, +10% speed, -15 max HP", "cat": "utility"},
	{"id": "barbed_spikes", "title": "Barbed Spikes", "desc": "+6 contact damage, more spikes", "cat": "defense"},
	{"id": "dash", "title": "Flagellar Dash", "desc": "Dash with Space/Shift (briefly invincible)", "cat": "utility", "unique": true, "max": 4, "up_desc": "Shorter dash cooldown"},
	{"id": "magnetism", "title": "Magnetism", "desc": "+90 XP pickup range", "cat": "utility"},
	{"id": "spore_nova", "title": "Spore Nova", "desc": "Periodically blast spores in all directions", "cat": "offense", "unique": true, "max": 5, "up_desc": "+2 spores per blast, fires faster"},
	{"id": "twin_spores", "title": "Twin Spores", "desc": "+1 projectile per shot", "cat": "offense"},
]

const UNSTABLE_MUTATIONS := [
	{"id": "glass_cells", "title": "Glass Cells", "desc": "+40% damage, -30% max HP", "cat": "unstable", "unstable": true},
	{"id": "berserk", "title": "Berserk", "desc": "+50% fire rate, +25% damage taken", "cat": "unstable", "unstable": true},
	{"id": "cancerous_growth", "title": "Cancerous Growth", "desc": "+70 max HP, -20% move speed", "cat": "unstable", "unstable": true},
	{"id": "toxic_blood", "title": "Toxic Blood", "desc": "+35% damage, lose 1.5 HP/sec", "cat": "unstable", "unstable": true},
	{"id": "unstable_mitosis", "title": "Unstable Mitosis", "desc": "Pierce +2, -20% damage", "cat": "unstable", "unstable": true},
]

const CAT_COLORS := {
	"offense": Color(0.95, 0.45, 0.4),
	"defense": Color(0.45, 0.7, 0.95),
	"utility": Color(0.55, 0.95, 0.7),
	"unstable": Color(0.85, 0.45, 0.95),
}


func cat_color(cat: String) -> Color:
	return CAT_COLORS.get(cat, Color(0.7, 0.8, 0.8))


func mutation_title(id: String) -> String:
	for m in MUTATIONS:
		if m.id == id:
			return m.title
	for m in UNSTABLE_MUTATIONS:
		if m.id == id:
			return m.title
	return id


func reset() -> void:
	max_hp = 100.0
	hp = 100.0
	move_speed = 220.0
	fire_rate = 2.0
	damage = 10.0
	projectile_count = 1
	projectile_speed = 500.0
	projectile_range = 600.0
	projectile_pierce = 0
	thorns_damage = 0.0
	poison_dps = 0.0
	poison_duration = 3.0
	orbit_level = 0
	pulse_level = 0
	damage_reduction = 0.0
	damage_taken_mult = 1.0
	regen = 0.0
	degen = 0.0
	lifesteal = 0.0
	crit_chance = 0.0
	crit_mult = 2.0
	knockback_mult = 1.0
	dash_level = 0
	nova_level = 0
	magnet_radius = 130.0
	invulnerable = false
	stacks = {}
	mutation_order = []
	xp = 0.0
	level = 1
	xp_to_next = 5.0
	alive = true
	_apply_selected_cell()
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)
	stats_changed.emit()


func _apply_selected_cell() -> void:
	var cell: Dictionary = CELLS.get(selected_cell, {})
	var mods: Dictionary = cell.get("stats", {})
	damage *= float(mods.get("damage", 1.0))
	fire_rate *= float(mods.get("fire_rate", 1.0))
	move_speed *= float(mods.get("move_speed", 1.0))
	max_hp *= float(mods.get("max_hp", 1.0))
	hp = max_hp
	for id in cell.get("start", []):
		apply_mutation(id)


func get_cell_color() -> Color:
	return CELLS.get(selected_cell, {}).get("color", Color(0.45, 0.85, 0.6))


func cell_count() -> int:
	return 1 + mutation_order.size() / CELL_GROUP_SIZE


func get_cell_stacks(gen: int) -> Dictionary:
	var d := {}
	var start := gen * CELL_GROUP_SIZE
	var stop := mini(start + CELL_GROUP_SIZE, mutation_order.size())
	for i in range(start, stop):
		var id: String = mutation_order[i]
		d[id] = int(d.get(id, 0)) + 1
	return d


func get_cell_radius(gen: int) -> float:
	var s := get_cell_stacks(gen)
	var grow := int(s.get("gigantism", 0)) + int(s.get("cancerous_growth", 0))
	var shrink := int(s.get("compact_form", 0))
	return clampf(BASE_CELL_RADIUS + float(grow) * 8.0 - float(shrink) * 5.0, 9.0, 95.0)


func get_molecule_extent() -> float:
	var main := get_cell_radius(0)
	if cell_count() <= 1:
		return main
	var maxsat := BASE_CELL_RADIUS
	for g in range(1, cell_count()):
		maxsat = maxf(maxsat, get_cell_radius(g))
	return main + 1.8 * maxsat


func _process(delta: float) -> void:
	if not alive:
		return
	var net := regen - degen
	if net > 0.0 and hp < max_hp:
		heal(net * delta)
	elif net < 0.0:
		hp = max(hp + net * delta, 0.0)
		hp_changed.emit(hp, max_hp)
		if hp <= 0.0:
			alive = false
			Audio.play("death")
			player_died.emit()


func get_body_radius() -> float:
	return get_cell_radius(0)


func get_shot_damage() -> float:
	if crit_chance > 0.0 and randf() < crit_chance:
		return damage * crit_mult
	return damage


func on_enemy_killed() -> void:
	if lifesteal > 0.0:
		heal(lifesteal)


func take_damage(amount: float) -> void:
	if not alive or invulnerable:
		return
	amount *= 1.0 - clampf(damage_reduction, 0.0, 0.85)
	amount *= damage_taken_mult
	hp = max(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
	shake_requested.emit(0.45)
	Audio.play("hurt", -9.0)
	if hp <= 0.0:
		alive = false
		Audio.play("death")
		player_died.emit()


func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = ceil(xp_to_next * 1.25)
		level_up.emit(level)
		Audio.play("level_up", -2.0)
	xp_changed.emit(xp, xp_to_next, level)


func get_random_mutations(count: int) -> Array:
	var normal := []
	for m in MUTATIONS:
		if m.get("unique", false) and int(stacks.get(m.id, 0)) >= int(m.get("max", 1)):
			continue
		normal.append(m)
	var risky := UNSTABLE_MUTATIONS.duplicate()
	normal.shuffle()
	risky.shuffle()
	var result := []
	while result.size() < count and (normal.size() + risky.size()) > 0:
		if risky.size() > 0 and (normal.size() == 0 or randf() < 0.3):
			result.append(risky.pop_back())
		else:
			result.append(normal.pop_back())
	return result


func apply_mutation(id: String) -> void:
	stacks[id] = int(stacks.get(id, 0)) + 1
	mutation_order.append(id)
	match id:
		"extra_arm":
			projectile_count += 1
		"metabolism":
			fire_rate *= 1.2
		"compound_eyes":
			projectile_range *= 1.25
			projectile_speed *= 1.25
		"molt":
			max_hp += 25.0
			hp = max_hp
			hp_changed.emit(hp, max_hp)
		"orbital_spores":
			orbit_level += 1
		"pulse_nova":
			pulse_level += 1
		"spiny_skin":
			thorns_damage += 8.0
		"venom":
			poison_dps += 6.0
		"mitosis":
			projectile_pierce += 1
		"carapace":
			damage_reduction += 0.12
		"regeneration":
			regen += 2.0
		"adrenaline":
			move_speed *= 1.15
		"hemovore":
			lifesteal += 2.0
		"gigantism":
			max_hp += 40.0
			hp += 40.0
			damage *= 1.15
			hp_changed.emit(hp, max_hp)
		"mutated_cells":
			crit_chance += 0.12
		"heavy_rounds":
			damage *= 1.5
			fire_rate *= 0.8
		"hyper_velocity":
			projectile_speed *= 1.4
			projectile_range *= 1.15
		"second_heart":
			max_hp += 50.0
			hp += 50.0
			regen += 1.0
			hp_changed.emit(hp, max_hp)
		"frenzy":
			crit_chance += 0.08
			crit_mult += 0.5
		"knockback_rounds":
			knockback_mult *= 1.8
		"compact_form":
			move_speed *= 1.1
			max_hp = max(max_hp - 15.0, 30.0)
			hp = min(hp, max_hp)
			hp_changed.emit(hp, max_hp)
		"barbed_spikes":
			thorns_damage += 6.0
		"dash":
			dash_level += 1
		"magnetism":
			magnet_radius += 90.0
		"spore_nova":
			nova_level += 1
		"twin_spores":
			projectile_count += 1
		"glass_cells":
			damage *= 1.4
			max_hp *= 0.7
			hp = min(hp, max_hp)
			hp_changed.emit(hp, max_hp)
		"berserk":
			fire_rate *= 1.5
			damage_taken_mult *= 1.25
		"cancerous_growth":
			max_hp += 70.0
			hp += 70.0
			move_speed *= 0.8
			hp_changed.emit(hp, max_hp)
		"toxic_blood":
			damage *= 1.35
			degen += 1.5
		"unstable_mitosis":
			projectile_pierce += 2
			damage *= 0.8
	stats_changed.emit()
