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
var is_moving = false
var animation_timer = 0.0


func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	
	gravityForce(delta)
	move(delta)
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_hiding:
		is_moving = false
		hiding(sprite,delta)
		
	# Pop Action (Unhide)
	if Input.is_action_just_pressed("pop") and is_hiding:
		is_moving = false
		pop(sprite,delta)
	
	# Jump Action 	
	if Input.is_action_just_pressed("jump") and !is_hiding:
		jump(sprite)	
	
	# Idle Action
	if !is_hiding and !is_moving:
		sprite.play("idle")
	
	# Peek Action
	if !sprite.is_playing() and is_hiding:
		sprite.play("peek")
	
	move_and_slide()
	
func move(delta):
	
	var direction = get_x_direction()
	var sprite = $AnimatedSprite2D
	var flipped = sprite.is_flipped_h()
	var sprite_direction = 1 if !flipped else -1
	
	if $CrouchHitBox.disabled and is_hiding and sprite.get_frame() == 7:
		$StandingHitBox.disabled = true
		$CrouchHitBox.disabled = false
	
	if direction: 
		is_moving = true
		if !is_hiding:
			sprite.play("walk")
		else:
			# Implement crouch animation
			pass
		#correct sprite
		if direction != 0 and sprite_direction != direction:
			sprite.set_flip_h(!flipped)
			is_facing_right = !is_facing_right	
	else:
		is_moving = false
	
	if is_on_floor():	
		velocity.x =  (direction * SPEED)/2 if is_hiding else direction * SPEED
		velocity.x *= 2 if Input.is_key_pressed(KEY_SHIFT) and !is_hiding else 1
	else:
		apply_drag(delta)
		velocity.x = velocity.x + direction * AIR_ACCELERATION * delta
		velocity.x = min(max(-MAX_SPEED, velocity.x), MAX_SPEED)

func gravityForce(delta):
	if velocity.y < 2500:
		velocity.y += gravity * delta
	if is_on_floor():
		velocity.y = 0
		doubleJump = true
		
	# Wall Sliding
	elif is_on_wall_only() and Input.is_action_pressed("move"): 
		velocity.y += (0.3 * gravity * delta)
		velocity.y = min(velocity.y, 0.1 * gravity)
	
func get_x_direction():
	return Input.get_axis("move_left", "move_right")

func apply_drag(delta):
	velocity.x *= (1 - DRAG) ** delta

func jump(sprite):
	# Jumping from the floor		
	if is_on_floor():
		doubleJump = true
	# Wall jumping
	elif is_on_wall(): 
		velocity.x = -MAX_SPEED if is_facing_right else MAX_SPEED
		velocity.y = JUMP_VELOCITY/2
		sprite.set_flip_h(!sprite.is_flipped_h())
		is_facing_right = !is_facing_right
	# Jumping in the air	
	elif doubleJump: 
		doubleJump = false
	# No jump	
	else: return
	
	velocity.y = JUMP_VELOCITY

func hiding(sprite,delta):
	apply_drag(delta)
	velocity.x = max(SPEED/2,velocity.x)
	sprite.play("hide")
	is_hiding = true		

func pop(sprite,delta):
	sprite.play("pop")
	await get_tree().create_timer(delta * 8).timeout
	is_hiding = false
	$CrouchHitBox.disabled = true
	$StandingHitBox.disabled = false

#func waitAnimation(delta):
	#var animSpeed = $AnimatedSprite2D.sprite_frames.get_animation_speed($AnimatedSprite2D.animation)
	#await get_tree().create_timer(delta * 8).timeout
