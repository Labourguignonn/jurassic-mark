extends CharacterBody2D
 
const SPEED = 150.0
const MAX_SPEED = 250.0
const DASH_SPEED = 450.0
const AIR_ACCELERATION = 2000.0
const JUMP_VELOCITY = -500.0
const DRAG = 0.8 # Value must be between 0 and 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var doubleJump = false
var is_crouching = false
var is_facing_right = true
var is_moving = false
var is_dashing = false
var can_dash = true
var animation_timer = 0.0

func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	
	if !is_dashing: 
		move(delta)
		gravityForce(delta)
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_crouching:
		is_moving = false
		crouch(sprite,delta)
		
	# Pop Action (Unhide)
	if Input.is_action_just_pressed("pop") and is_crouching:
		is_moving = false
		pop(sprite,delta)
	
	# Jump Action 	
	if Input.is_action_just_pressed("jump") and !is_crouching:
		jump(sprite)	
		
	if Input.is_action_just_released("jump"):
		stop_jump(sprite)	
		
	# Idle Action
	if !is_crouching and !is_moving:
		sprite.play("idle")
	
	# Peek Action
	if !sprite.is_playing() and is_crouching:
		sprite.play("peek")
	
	if Input.is_action_just_pressed("dash") and can_dash and !is_crouching: 
		dash()
	
	move_and_slide()
	
func move(delta):
	
	var direction = get_x_direction()
	var sprite = $AnimatedSprite2D
	var flipped = sprite.is_flipped_h()
	var sprite_direction = 1 if !flipped else -1
	
	if $CrouchHitBox.disabled and is_crouching and sprite.get_frame() == 7:
		$StandingHitBox.disabled = true
		$CrouchHitBox.disabled = false
	
	if direction: 
		is_moving = true
		if !is_crouching:
			sprite.play("walk")
		else:
			# Implement crouch animation
			pass
		# Flip character sprite
		if sprite_direction != direction:
			sprite.set_flip_h(!flipped)
			is_facing_right = !is_facing_right	
	else:
		is_moving = false
	
	if is_on_floor():	
		velocity.x =  (direction * SPEED)/2 if is_crouching else direction * SPEED
		velocity.x *= 2 if Input.is_key_pressed(KEY_SHIFT) and !is_crouching else 1
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

func stop_jump(sprite):
	if velocity.y <= -200:
		velocity.y = -200
	
func crouch(sprite,delta):
	apply_drag(delta)
	velocity.x = max(SPEED/2,velocity.x)
	sprite.play("hide")
	is_crouching = true		

func pop(sprite,delta):
	sprite.play("pop")
	await get_tree().create_timer(delta * 8).timeout
	is_crouching = false
	$CrouchHitBox.disabled = true
	$StandingHitBox.disabled = false

func dash():
	is_dashing = true
	can_dash = false
	velocity.x += get_x_direction() * DASH_SPEED
	$DashTimer.start()
	$DashCooldown.start()

func _on_dash_timer_timeout():
	is_dashing = false

func _on_dash_cooldown_timeout():
	if is_on_floor(): can_dash = true

func has_moved():
	return (velocity.x != 0 or velocity.y != 0)

#func waitAnimation(delta):
	#var animSpeed = $AnimatedSprite2D.sprite_frames.get_animation_speed($AnimatedSprite2D.animation)
	#await get_tree().create_timer(delta * 8).timeout
