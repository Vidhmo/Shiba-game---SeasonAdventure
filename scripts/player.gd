extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var combo_timer: Timer = $ComboTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_hitbox: CollisionShape2D = $%AttackHitbox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var animation_node : NodePath

var combo_count : int  = 1
var combo_threshold : float = 2
var minimum_combo_thres : float = 0.5
var last_press_time : float = 0.0
var max_combo : int = 3
var is_attacking = false


var animation_script = null

func _ready():
	if animation_node :
		animation_script= get_node(animation_node)
		
		attack_hitbox.disabled = true
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handles jump.
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	#Player Movement
	var direction : = Input.get_axis("moveleft", "moveright")
	
	if direction and not is_attacking :
		velocity.x = direction * SPEED
	elif not is_on_floor() :
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
	#Attacks
	if Input.is_action_just_pressed("Attack_1") and not is_attacking:
		
		if attack_timer.is_stopped() :
			attack_hitbox.disabled = true
		else :
			attack_hitbox.disabled = false
		
		if combo_timer.is_stopped():
			combo_count = 1
				
		else :
			combo_count += 1
				
		if combo_count > max_combo :
			combo_count = 1
			
		attack()
				
		print(combo_count)
	#Flips the Playe

	move_and_slide()

func attack() :
	is_attacking = true
	attack_hitbox.disabled = false
	attack_timer.start(0.4)
	attack_cooldown_timer.start(0.5)
	combo_timer.start(2)
	
	print("Playing animation:", animated_sprite.animation)
	animated_sprite.show()  # make sure visible
	
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Attack"):
		is_attacking = false
		
func _on_attack_cooldown_timer_timeout() -> void:
	is_attacking = false

func _on_combo_timer_timeout() -> void:
	combo_count = 1


func _on_attack_timer_timeout() -> void:
	attack_hitbox.disabled = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") :
		body.take_damage(20)
