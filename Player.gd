extends CharacterBody2D
 
const SPEED = 300.0
const CROUCH_SPEED = 150.0
const MAX_SPEED = 500.0
const DASH_SPEED = 900.0
const AIR_ACCELERATION = 2000.0
const JUMP_VELOCITY = -700.0
const DRAG = 0.8 # Value must be between 0 and 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var doubleJump = false
var is_hiding = false
var is_dashing = false
var can_dash = true
var is_facing_right = true
var animation_timer = 0.0

func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	
	# Idle State
	if !is_moving() and !is_hiding: sprite.play("idle")
	
	# Move State
	if !is_dashing: move(delta, sprite)
	if Input.is_action_just_pressed("dash") and can_dash: dash()
	
	# Dash Action
	#if Input.is_action_just_pressed("dash"):
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_hiding:
		sprite.play("hide")
		is_hiding = true
		
	# Pop Action (Unhide)
	if (Input.is_action_just_pressed("pop") or !is_on_floor()) and is_hiding:
		if can_stand():
			sprite.play("pop")
			is_hiding = false
			$CrouchHitBox.disabled = true
			$StandingHitBox.disabled = false
		#animation_timer = 0.3
		
	# Idle animations normally and when hiding
	#if velocity.x == 0 and velocity.y == 0 and !$AnimatedSprite2D.is_playing():
		#if !is_hiding: $AnimatedSprite2D.play("idle")
		#if is_hiding: $AnimatedSprite2D.play("peek")	

	# Gravity
	velocity.y += gravity * delta
	if is_on_floor():
		velocity.y = 0
		doubleJump = true
		
	# Wall Sliding
	elif is_on_wall_only() and Input.is_action_pressed("move"): 
		velocity.y += (0.3 * gravity * delta)
		velocity.y = min(velocity.y, 0.1 * gravity)

	if Input.is_action_just_pressed("jump"):
		jump()
	
	move_and_slide()

func is_moving():
	return (velocity.x != 0 or velocity.y != 0)

func move(delta, sprite):
	var direction = get_x_direction()
	var flipped = sprite.is_flipped_h()
	var sprite_direction = -1 if flipped else 1
	
	# THIS SHOULD BE IN THE FUNCTION THAT TOGGLES CROUCHING, NOT HERE
	# Enables/Disables character hitbox to CrouchHitbox if crouching or not
	if $CrouchHitBox.disabled and is_hiding and sprite.get_frame() == 7:
		$StandingHitBox.disabled = true
		$CrouchHitBox.disabled = false
	
	if direction: 
		if !is_hiding: sprite.play("walk")
		else: sprite.play("peek") # Placeholder animation

	if direction != 0 and sprite_direction != direction:
		sprite.set_flip_h(!flipped)
		is_facing_right = !is_facing_right
		
	if is_on_floor():
		apply_drag(delta)
		velocity.x = direction * CROUCH_SPEED if is_hiding else direction * SPEED ##change velocity if crouching
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
		$AnimatedSprite2D.set_flip_h(!$AnimatedSprite2D.is_flipped_h())
		is_facing_right = !is_facing_right
	# Jumping in the air
	elif doubleJump: 
		doubleJump = false
	# No jump	
	else: return
	
	velocity.y = JUMP_VELOCITY

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

func can_stand() -> bool:
	var result = !$CrouchRaycast1.is_colliding() and !$CrouchRaycast2.is_colliding()	
	return result	
