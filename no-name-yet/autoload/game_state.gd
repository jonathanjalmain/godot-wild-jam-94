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
var tentacle_level: int = 0

var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 5.0
var alive: bool = true

const MUTATIONS := [
	{"id": "extra_arm", "title": "Extra Arm", "desc": "+1 projectile per shot"},
	{"id": "metabolism", "title": "Metabolism", "desc": "+20% fire rate"},
	{"id": "compound_eyes", "title": "Compound Eyes", "desc": "+25% range and speed"},
	{"id": "molt", "title": "Molt", "desc": "+25 max HP and full heal"},
	{"id": "tentacles", "title": "Tentacles", "desc": "Spinning melee aura"},
	{"id": "spiny_skin", "title": "Spiny Skin", "desc": "Hurt enemies on contact"},
	{"id": "venom", "title": "Venom", "desc": "Shots poison enemies"},
	{"id": "mitosis", "title": "Mitosis", "desc": "Shots pierce +1 enemy"},
]


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
	tentacle_level = 0
	xp = 0.0
	level = 1
	xp_to_next = 5.0
	alive = true


func take_damage(amount: float) -> void:
	if not alive:
		return
	hp = max(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
	shake_requested.emit(0.45)
	if hp <= 0.0:
		alive = false
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
	xp_changed.emit(xp, xp_to_next, level)


func get_random_mutations(count: int) -> Array:
	var pool := MUTATIONS.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


func apply_mutation(id: String) -> void:
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
		"tentacles":
			tentacle_level += 1
		"spiny_skin":
			thorns_damage += 8.0
		"venom":
			poison_dps += 6.0
		"mitosis":
			projectile_pierce += 1
	stats_changed.emit()
