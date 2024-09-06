extends Area2D

@onready var sprite = $sprite
@onready var collision = $collision


# Called when the node enters the scene tree for the first time.
func _ready():
	collision.shape.size = sprite.get_rect().size

	
			


func _on_body_entered(body):
	if body.name == "PlayerScene" && body.has_method("knockback"):
		print("OI") 
