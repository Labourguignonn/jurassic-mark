extends Node2D
class_name  HealthComponent

var max_health := 50
var curr_health : int

func _init(max_health):
	max_health = max_health
	curr_health = max_health

func take_damage(attack):
	if curr_health <= 0:
		pass
		#animação de morte
	else:
		curr_health -= attack

func heal(qt_heal):
	curr_health += qt_heal
