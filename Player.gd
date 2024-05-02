extends CharacterBody2D
 
const SPEED = 200.0
const JUMP_VELOCITY = -500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var doubleJump = false
var is_hiding = false

func _physics_process(delta):
	jump(delta)
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_hiding:
		$AnimatedSprite2D.play("hide")
		is_hiding = true
	# Pop Action (Unhide)
	if Input.is_action_just_pressed("pop") and is_hiding:
		$AnimatedSprite2D.play("pop")
		is_hiding = false

	# Movement Action
	# First get the axis of movement, negative for left, positive for right
	var direction = Input.get_axis("move_left", "move_right")
	# If it is hiding it cannot move
	if direction and !is_hiding:
		$AnimatedSprite2D.play("walk")
		if !$AnimatedSprite2D.is_flipped_h() and direction < 0:
			$AnimatedSprite2D.set_flip_h(true)
		elif $AnimatedSprite2D.is_flipped_h() and direction > 0:
			$AnimatedSprite2D.set_flip_h(false)
		
		velocity.x = direction * SPEED
		# Handling running
		if Input.is_key_pressed(KEY_SHIFT):
			velocity.x = direction * SPEED * 1.5
	else: # Stops walking animation if not moving
		if $AnimatedSprite2D.animation == "walk":
			$AnimatedSprite2D.stop()
		velocity.x = 0 #move_toward(velocity.x, 0, SPEED)
	
	# Idle animations normally and when hiding
	if velocity.x == 0 and velocity.y == 0 and !$AnimatedSprite2D.is_playing():
		if !is_hiding: $AnimatedSprite2D.play("idle")
		if is_hiding: $AnimatedSprite2D.play("peek")	
		
	move_and_slide()

func jump(delta):
	# Gravity and Wall Sliding y velocity
	velocity.y += gravity * delta
	if is_on_floor(): velocity.y = 0
	elif is_on_wall_only() and Input.is_action_pressed("move"): 
		velocity.y += (0.3 * gravity * delta)
		velocity.y = min(velocity.y, 0.1 * gravity)
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor(): # Jumping from the floor
			velocity.y = JUMP_VELOCITY
			doubleJump = true
		if !is_on_floor() and doubleJump: # Jumping in the air
			velocity.y = JUMP_VELOCITY
			doubleJump = false
		if is_on_wall_only() and Input.is_action_pressed("move"): # Wall jumping
			velocity.y = JUMP_VELOCITY
