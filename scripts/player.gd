extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var is_attacking = false
var is_running = true


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	#Player Movement
	var direction := Input.get_axis("moveleft", "moveright")
	
	if direction and not is_attacking :
		velocity.x = direction * SPEED
	elif not is_on_floor() :
		velocity.x = direction * SPEED
	
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
	#Attacks
	if Input.is_action_just_pressed("Attack_1") and not is_attacking:
		attack()
	
	#Flips the Player
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0 : 
		animated_sprite.flip_h = true
	
	# Last direction
	@warning_ignore("unused_variable")
	var lastdir
	if direction != 0 :
		lastdir = direction
		
#Run and Idle Animation of player
	if not is_attacking :
		if is_on_floor() :
			if direction == 0 and is_attacking == false:
				animated_sprite.play("Idle")
			else :
				animated_sprite.play("Run")	
		else :
			animated_sprite.play("Jump")

	move_and_slide()

func attack() :
	is_attacking = true
	animated_sprite.play("Attack_1")
	
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "Attack_1" :
		is_attacking = false
