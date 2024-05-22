extends CharacterBody2D

@onready var anim := $Anim as AnimationPlayer

func _physics_process(delta):
	pass
	move_and_slide()


func _on_hitbox_body_entered(body: Node) -> void:
	pass # Replace with function body.
