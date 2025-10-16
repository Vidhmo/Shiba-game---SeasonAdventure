extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var enemy: CharacterBody2D = %Enemy

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var combo_timer: Timer = $ComboTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_hitbox: CollisionShape2D = $%AttackHitbox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_area: CollisionShape2D = $PlayerArea
@onready var death_timer: Timer = $DeathTimer

@export var animation_node : NodePath
@export var health : int

var combo_count : int  = 1
var combo_threshold : float = 2
var minimum_combo_thres : float = 0.5
var last_press_time : float = 0.0
var max_combo : int = 3
var is_attacking = false

var damage : int
var knockback_force = 40
var upback_force = -40

var dead : bool = false
var is_taking_damage : bool = false
var knockback_velocity : Vector2 = Vector2.ZERO

var enemy_in_attack_range : bool = false


var animation_script = null

func _ready():
	if animation_node :
		animation_script= get_node(animation_node)
		
		attack_hitbox.disabled = true
		health = 100
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if dead :
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_taking_damage :
		velocity = knockback_velocity
		knockback_velocity.y += get_gravity().y * delta
		move_and_slide()
		return

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
		
	die()
		
		
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

	move_and_slide()

func attack() :
	is_attacking = true
	attack_hitbox.disabled = false
	attack_timer.start(0.4)
	attack_cooldown_timer.start(0.5)
	combo_timer.start(2)
	if combo_count == 1 :
		damage = 30
	elif combo_count == 2 :
		damage = 40
	elif combo_count == 3:
		damage = 50 
		
	print("Damage :", damage)
	print("Combo_count :" , combo_count)
	
		
	animated_sprite.show()  # make sure visible
	
func die() :
	if health <= 0 and not dead :
		animated_sprite.stop()
		dead = true
		is_attacking = false
		player_area.disabled = true
		death_timer.start(2)
		
func take_damage(damage_amount : int , attacker_position : Vector2 , knockback_force : int , upback_force : int) :
	if dead or is_taking_damage :
		return
	
	if health > 0 :
		health -= damage_amount
		is_taking_damage = true
		
		var knockback_direction = sign(global_position.x - attacker_position.x)
		if knockback_direction == 0 :
			knockback_direction = 1
			
		knockback_velocity.x = knockback_direction * knockback_force
		knockback_velocity.y = upback_force

	
		await get_tree().create_timer(0.5).timeout
		is_taking_damage = false
		knockback_velocity = Vector2.ZERO
	else :
		die()


func _on_death_timer_timeout() -> void:
	get_tree().reload_current_scene()
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Attack"):
		is_attacking = false
		
func _on_attack_cooldown_timer_timeout() -> void:
	is_attacking = false

func _on_combo_timer_timeout() -> void:
	combo_count = 1
	

func _on_attack_timer_timeout() -> void:
	attack_hitbox.disabled = true
	if enemy_in_attack_range :
		enemy.take_damage(damage , global_position , knockback_force )
	

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Enemy" :
		enemy_in_attack_range = true


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Enemy" :
		enemy_in_attack_range = false
