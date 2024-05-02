extends CharacterBody2D
 
const SPEED = 200.0
const JUMP_VELOCITY = -500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var doubleJump = false
var is_hiding = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_on_floor():
		doubleJump = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		doubleJump = true
	if Input.is_action_just_pressed("jump") and !is_on_floor() and doubleJump:
		velocity.y = JUMP_VELOCITY
		doubleJump = false
	if Input.is_action_just_pressed("hide") and is_on_floor():
		$AnimatedSprite2D.play("hide")
		is_hiding = true
	if Input.is_action_just_pressed("pop") and is_on_floor() and is_hiding:
		$AnimatedSprite2D.play("pop")
		is_hiding = false
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		$AnimatedSprite2D.play("walk")
		if !$AnimatedSprite2D.is_flipped_h() and direction < 0:
			$AnimatedSprite2D.set_flip_h(true)
		elif $AnimatedSprite2D.is_flipped_h() and direction > 0:
			$AnimatedSprite2D.set_flip_h(false)
			
		velocity.x = direction * SPEED
		if Input.is_key_pressed(KEY_SHIFT):
			velocity.x = direction * SPEED * 1.5
	else:
		velocity.x = 0 #move_toward(velocity.x, 0, SPEED)
	
	if velocity.x == 0 and velocity.y == 0 and !is_hiding:
		$AnimatedSprite2D.play("idle")
	elif velocity.x == 0 and velocity.y == 0 and is_hiding:
		$AnimatedSprite2D.play("peek")
	
		
	move_and_slide()
