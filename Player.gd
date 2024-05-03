extends CharacterBody2D
 
const SPEED = 300.0
const MAX_SPEED = 500.0
const AIR_ACCELERATION = 2000.0
const JUMP_VELOCITY = -700.0
const DRAG = 0.8 # Value must be between 0 and 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var doubleJump = false
var is_hiding = false
var is_facing_right = true

func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_hiding:
		sprite.play("hide")
		is_hiding = true
		
	# Pop Action (Unhide)
	if Input.is_action_just_pressed("pop") and is_hiding:
		sprite.play("pop")
		is_hiding = false
	
	# Idle animations normally and when hiding
	if velocity.x == 0 and velocity.y == 0 and !$AnimatedSprite2D.is_playing():
		if !is_hiding: $AnimatedSprite2D.play("idle")
		if is_hiding: $AnimatedSprite2D.play("peek")	
			 
	# Gravity
	velocity.y += gravity * delta
	if is_on_floor():
		velocity.y = 0
		
	# Wall Sliding
	elif is_on_wall_only() and Input.is_action_pressed("move"): 
		velocity.y += (0.3 * gravity * delta)
		velocity.y = min(velocity.y, 0.1 * gravity)
	move(delta)
	if Input.is_action_just_pressed("jump"):
		jump()
	move_and_slide()
	
	
	
func move(delta):
	if is_hiding:
		apply_drag(delta)
		return
	
	var direction = get_x_direction()
	var sprite = $AnimatedSprite2D
	var flipped = sprite.is_flipped_h()
	var sprite_direction = 1 if !flipped else -1
	
	if direction: sprite.play("walk")
	
	if direction != 0 and sprite_direction != direction:
		sprite.set_flip_h(!flipped)
		is_facing_right = !is_facing_right
		
	if is_on_floor():	
		velocity.x = direction * SPEED
		velocity.x *= 2 if Input.is_key_pressed(KEY_SHIFT) else 1
	else:
		apply_drag(delta)
		velocity.x = velocity.x + direction * AIR_ACCELERATION * delta
		velocity.x = min(max(-MAX_SPEED, velocity.x), MAX_SPEED)
		 
		
func get_x_direction():
	return Input.get_axis("move_left", "move_right")

func apply_drag(delta):
	velocity.x *= (1 - DRAG) ** delta

func jump():
	# Jumping from the floor		
	if is_on_floor():
		doubleJump = true
	# Wall jumping
	elif is_on_wall(): 
		velocity.x = -MAX_SPEED if is_facing_right else MAX_SPEED
		print(velocity.x)
		$AnimatedSprite2D.set_flip_h(!$AnimatedSprite2D.is_flipped_h())
		is_facing_right = !is_facing_right
	# Jumping in the air	
	elif doubleJump: 
		doubleJump = false
	# No jump	
	else: return
	
	print("a")
	velocity.y = JUMP_VELOCITY
		
		
			

