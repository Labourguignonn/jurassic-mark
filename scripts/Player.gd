extends CharacterBody2D

const SPEED = 150.0
const MAX_SPEED = 250.0
const DASH_SPEED = 450.0
const JUMP_SPEED = -500.0
const AIR_ACCELERATION = 2000.0
const DRAG = 0.8 # Value must be between 0 and 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var wall_direction: int
var can_have_tolerance_timer = false
var double_jump 	= false
var wall_jump 		= false
var is_crouching 	= false
var is_dashing 		= false
var can_dash 		= true
var health = 50

func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	move_and_slide()
	
	if is_on_wall():
		if $LeftRayCast.is_colliding(): 
			wall_direction = 1 # To the right
		if $RightRayCast.is_colliding(): 
			wall_direction = -1 # To the left
	
	if $CrouchHitBox.disabled and is_crouching and sprite.get_frame() == 7:
		$StandingHitBox.disabled = true
		$CrouchHitBox.disabled = false
	
	if !is_dashing:
		if $AnimationTimer.is_stopped(): move(sprite, delta)
		gravityForce(delta)
	
	# Hide Action
	if Input.is_action_just_pressed("hide") and is_on_floor() and !is_crouching:
		crouch(sprite, delta)
	
	# Pop Action (Unhide)
	if Input.is_action_just_pressed("pop") and is_crouching and !$CrouchRayCast.is_colliding():
		pop(sprite,delta)
	
	# Jump Action 
	if Input.is_action_just_pressed("jump") and !is_crouching:
		jump(sprite, delta)
	
	if Input.is_action_just_released("jump"):
		stop_jump()
	
	# Idle Action
	if !is_moving() and !is_crouching:
		sprite.play("idle")
	
	# Peek Action
	if !sprite.is_playing() and is_crouching:
		sprite.play("peek")
	
	if Input.is_action_just_pressed("dash") and can_dash and !is_crouching: 
		dash(sprite)

func gravityForce(delta):
	if velocity.y < 2500:
		velocity.y += gravity * delta
	
	if is_on_floor():
		double_jump = true
		can_have_tolerance_timer = true
		if $DashCooldown.is_stopped(): can_dash = true
		velocity.y = 0
	# Wall Sliding
	elif is_on_wall():
		wall_jump = true
		can_have_tolerance_timer = true
		velocity.y = min(velocity.y, 0.05 * gravity)
	# Tolerance time for jumping right after starting to fall
	elif can_have_tolerance_timer:
		$ToleranceTimer.start()
		can_have_tolerance_timer = false

enum MODE{MD, SD, VD}
func get_x_direction(mode:MODE, sprite:AnimatedSprite2D):
	match mode:
		MODE.MD: # movement direction
			return Input.get_axis("move_left", "move_right")
		MODE.SD: # sprite direction
			return 1 if !sprite.is_flipped_h() else -1
		MODE.VD: # velocity direction
			return 1 if velocity.x >= 0 else -1

func accelerate(sprite:AnimatedSprite2D, delta:float, speed:float, 
				acceleration:float = 1.0):
	# # Acceleration has to be > 0
	var move_direction = get_x_direction(MODE.SD, sprite)
	velocity.x += move_direction * delta * acceleration * speed
	if move_direction * velocity.x >= speed: velocity.x = move_direction * speed

func decerelate(sprite:AnimatedSprite2D, delta:float, speed:float, 
				acceleration:float = 1.0):
	# Acceleration has to be > 0
	var velocity_direction = get_x_direction(MODE.VD, sprite)
	velocity.x -= velocity_direction * speed * delta * acceleration
	if velocity_direction * velocity.x <= 0: velocity.x = 0

func apply_drag(delta:float):
	velocity.x *= (1 - DRAG) ** delta
	
func is_moving():
	return (velocity.x != 0 or velocity.y != 0)

func move(sprite:AnimatedSprite2D, delta:float):
	var move_dir = get_x_direction(MODE.MD, sprite)
	var sprite_dir = get_x_direction(MODE.SD, sprite)
	
	if move_dir:
		# Flip character sprite horizontally
		if sprite_dir != move_dir: sprite.set_flip_h(!sprite.is_flipped_h())
		if is_on_floor() and !is_crouching:
			accelerate(sprite, delta, SPEED, 4)
			sprite.play("walk")
		elif is_on_floor() and is_crouching:
			accelerate(sprite, delta, SPEED/2, 4)
		else:
			apply_drag(delta)
			velocity.x += move_dir * AIR_ACCELERATION * delta
			velocity.x = min(max(-MAX_SPEED, velocity.x), MAX_SPEED)
	elif is_moving():
		decerelate(sprite, delta, SPEED, 4)

func jump(sprite:AnimatedSprite2D, delta):
	# Can jump if any of these conditions are satisfied in this specific order:
	# is on floor? >>> is on wall? >>> is in air and tolerance timer is running?
	# >>> is in air and has double jump? If all fail, you can't jump.
	if is_on_floor(): pass
	elif wall_jump:
		double_jump = false
		if wall_direction == 1: # To the right
			sprite.set_flip_h(false)
		if wall_direction == -1: # To the left
			sprite.set_flip_h(true)
		velocity.x = wall_direction * MAX_SPEED
		$AnimationTimer.start()
	elif $ToleranceTimer.get_time_left() > 0 and !can_have_tolerance_timer: pass
	elif double_jump: double_jump = false
	else: return
	velocity.y = JUMP_SPEED

func stop_jump():
	if velocity.y <= -200:
		velocity.y = -200

func crouch(sprite,delta):
	apply_drag(delta)
	sprite.play("hide")
	is_crouching = true

func pop(sprite,delta):
	sprite.play("pop")
	await get_tree().create_timer(delta * 8).timeout
	is_crouching = false
	$CrouchHitBox.disabled = true
	$StandingHitBox.disabled = false

func dash(sprite):
	is_dashing = true
	can_dash = false
	velocity.y = 0
	velocity.x = get_x_direction(MODE.SD, sprite) * DASH_SPEED
	$AnimationTimer.start()
	$DashCooldown.start()

func _on_animation_timer_timeout():
	if is_dashing: is_dashing = false
	if wall_jump: wall_jump = false

func _on_tolerance_timer_timeout():
	if wall_jump and $AnimationTimer.is_stopped(): wall_jump = false 
