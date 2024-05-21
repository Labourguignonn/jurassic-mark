extends CollisionShape2D

@export var health_component : Health
# Called when the node enters the scene tree for the first time.
##func damage(attack: Attack):
	##if health_component:
		##health_component.damage(attack)
