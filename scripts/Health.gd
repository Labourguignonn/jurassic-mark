extends Node
class_name Health

@export var MAX_HEALTH := 10
var health : float
# Called when the node enters the scene tree for the first time.
func _ready():
	health = MAX_HEALTH

# Called every frame. 'delta' is the elapsed time since the previous frame.
##func damage(attack: Attack):
	##health -= attack.attack_damage
	##if health <= 0:
		##get_parent().queue_free()
##func cure(cure: Cure):
	##health += cure.cure_amount
