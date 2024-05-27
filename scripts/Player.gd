extends CharacterBody2D
 
const SPEED = 150.0
const MAX_SPEED = 250.0
const DASH_SPEED = 450.0
const KNOCKBACK_SPEED = 200.0
const AIR_ACCELERATION = 2000.0
const JUMP_VELOCITY = -500.0
const DRAG = 0.8 # Value must be between 0 and 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_have_tolerance_timer = false
var double_jump 	= false
var wall_jump 		= false
var is_crouching 	= false
var is_dashing 		= false
var can_dash 		= true
var knockback_vector := Vector2.ZERO
@export var max_health : int

#import de classes
@onready var healthcomp = HealthComponent.new(max_health)

func _physics_process(delta):
	var sprite = $AnimatedSprite2D
	
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
		jump(sprite)
	
	if Input.is_action_just_released("jump"):
		stop_jump()
	
	# Idle Action
	if !is_moving() and !is_crouching:
		sprite.play("idle")
	
	# Peek Action
	if !sprite.is_playing() and is_crouching:
		sprite.play("peek")
	
	if Input.is_action_just_pressed("dash") and can_dash and !is_crouching: 
		dash()
	
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
	move_and_slide()

func gravityForce(delta):
	if velocity.y < 2500:
		velocity.y += gravity * delta
	
	if is_on_floor():
		can_have_tolerance_timer = true
		double_jump = true
		velocity.y = 0
	# Wall Sliding
	elif is_on_wall():
		can_have_tolerance_timer = true
		wall_jump = true
		velocity.y = min(velocity.y, 0.05 * gravity)
	# Tolerance time for jumping right after starting to fall
	elif can_have_tolerance_timer:
		$ToleranceTimer.start()
		can_have_tolerance_timer = false

func get_x_direction():
	return Input.get_axis("move_left", "move_right")

func apply_drag(delta):
	velocity.x *= (1 - DRAG) ** delta

func is_moving():
	return (velocity.x != 0 or velocity.y != 0)

func move(sprite, delta):
	var direction = get_x_direction()
	var flipped = sprite.is_flipped_h()
	var sprite_direction = 1 if !flipped else -1
	
	if $CrouchHitBox.disabled and is_crouching and sprite.get_frame() == 7:
		$StandingHitBox.disabled = true
		$CrouchHitBox.disabled = false
	
	if direction: 
		if !is_crouching:
			sprite.play("walk")
		else:
			# Implement crouch animation
			pass
		# Flip character sprite
		if sprite_direction != direction:
			sprite.set_flip_h(!flipped)	
	
	if is_on_floor():
		velocity.x = (direction * SPEED)/2 if is_crouching else direction * SPEED
	else:
		apply_drag(delta)
		velocity.x = velocity.x + direction * AIR_ACCELERATION * delta
		velocity.x = min(max(-MAX_SPEED, velocity.x), MAX_SPEED)

func jump(sprite):
	# Can jump if any of these conditions are satisfied in this specific order:
	# is on floor? >>> is on wall? >>> is in air and tolerance timer is running? 
	# >>> is in air and has double jump? If all fail, you can't jump.
	var sprite_direction: int
	
	if is_on_floor(): pass
	elif wall_jump:
		double_jump = false
		if $LeftRayCast.is_colliding(): 
			sprite_direction = 1
			sprite.set_flip_h(false)
		if $RightRayCast.is_colliding(): 
			sprite_direction = -1
			sprite.set_flip_h(true)
		velocity.x = sprite_direction * MAX_SPEED
		$AnimationTimer.start()
	elif $ToleranceTimer.get_time_left() > 0 and !can_have_tolerance_timer: pass
	elif double_jump: double_jump = false
	else: return
	velocity.y = JUMP_VELOCITY

func stop_jump():
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
	$AnimationTimer.start()
	$DashCooldown.start()

func _on_animation_timer_timeout():
	if is_dashing: is_dashing = false
	if wall_jump: wall_jump = false

func _on_dash_cooldown_timeout():
	if is_on_floor(): can_dash = true

func _on_tolerance_timer_timeout():
	if wall_jump and $AnimationTimer.is_stopped(): wall_jump = false 

func _on_hurtbox_body_entered(body):
	if body.name == "Enemy":
		healthcomp.take_damage(10)
		print(healthcomp.curr_health)
		if $RightRayCast.is_colliding():
			knockback(Vector2(-300,-200))
		elif $LeftRayCast.is_colliding():
			knockback(Vector2(300,-200))
			
func knockback(knockback_force := Vector2.ZERO):
	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force
		
	var knockback_tween = get_tree().create_tween()
	knockback_tween.parallel().tween_property(self, "knockback_vector", Vector2.ZERO, 0.25)
	$AnimatedSprite2D.modulate = Color(1,0,0,1)
	knockback_tween.parallel().tween_property($AnimatedSprite2D,"modulate", Color(1,1,1,1), 0.5)
