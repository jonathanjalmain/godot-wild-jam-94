extends Node

signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, needed: float, level: int)
signal level_up(new_level: int)
signal player_died

var max_hp: float = 100.0
var hp: float = 100.0
var move_speed: float = 220.0
var fire_rate: float = 2.0
var damage: float = 10.0
var projectile_count: int = 1
var projectile_speed: float = 500.0
var projectile_range: float = 600.0

var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 5.0
var alive: bool = true


func reset() -> void:
	max_hp = 100.0
	hp = 100.0
	move_speed = 220.0
	fire_rate = 2.0
	damage = 10.0
	projectile_count = 1
	projectile_speed = 500.0
	projectile_range = 600.0
	xp = 0.0
	level = 1
	xp_to_next = 5.0
	alive = true


func take_damage(amount: float) -> void:
	if not alive:
		return
	hp = max(hp - amount, 0.0)
	hp_changed.emit(hp, max_hp)
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
