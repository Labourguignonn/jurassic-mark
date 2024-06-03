extends CharacterBody2D

@export var max_health : int
#import de classes
@onready var healthcomp = HealthComponent.new(max_health)

func _on_hitbox_body_entered(body):
	if body.name == "Player":
		print (healthcomp.curr_health)
		healthcomp.take_damage(10) # Replace with function body.
