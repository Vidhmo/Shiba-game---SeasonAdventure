extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer
@onready var player: CharacterBody2D = %Player
@onready var chase_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var dead_timer: Timer = $DeadTimer

@export var patrol_time : float = 2
@export var wait_time : float = 3
@export var chase_speed : float = 70
@export var death_time : float = 2

@export var right_chase_hitbox = 41
@export var left_chase_hitbox = -41
@export var right_attack_hitbox = 7
@export var left_attack_hitbox = -7

enum EnemyState {Run , Wait , Chase , Attack , Dead}
var state : EnemyState = EnemyState.Wait

const gravity = 900.0
@export var speed : float = 10
var health : int = 100
var is_chasing : bool = false

var dead : bool = false
var is_taking_damage : bool = false
var is_taking_knockback : bool = false
var knockback_velocity : Vector2 = Vector2.ZERO
var attacking_damage = 15
var is_attacking : bool = false

var dir : Vector2
var knockback_force = 100
var upback_force = -100
var is_patrolling : bool = false
var player_in_attack_range : bool = false
var player_in_chase_range : bool = false


var last_dir : int = 0

func _ready() -> void:
	switch_to_wait()
	
	
func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
		
	if is_taking_damage :
		velocity = knockback_velocity
		velocity.x += get_gravity().y * delta
		move_and_slide()
		
	if dead :
		velocity = Vector2.ZERO
		
	
	handle_animation()
	handle_movement()
	flips_enemy()
	last_direction()
	move_and_slide()
	die()
	
	
	
	
func handle_movement() :
	if state == EnemyState.Run :
		velocity.x = dir.x * speed
	elif state == EnemyState.Wait :
		velocity.x = 0
	elif state == EnemyState.Chase :
		dir = (player.position - position).normalized()
		velocity.x = dir.x * chase_speed
	
func last_direction() :
	if dir.x != 0 :
		last_dir = dir.x
				
func switch_to_run() :
	state = EnemyState.Run
	if last_dir == 0:
		dir.x = choose([-1 , 1])
	else :
		dir.x = -last_dir
	state_timer.start(patrol_time)
	
	
func switch_to_wait() :
	state = EnemyState.Wait
	dir.x = 0
	state_timer.start(wait_time)
	
func switch_to_death() :
	state = EnemyState.Dead
	dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	move_and_slide()
	dead_timer.start(death_time)
	state_timer.stop()
	
	
func _on_state_timer_timeout() -> void:
	if state == EnemyState.Run :
		switch_to_wait()
	elif state == EnemyState.Wait :
		switch_to_run()
		

func handle_animation():
	if state == EnemyState.Dead :
		if animated_sprite.animation != "Dead" :
			animated_sprite.play("Dead")
	elif is_taking_damage :
		if animated_sprite.animation != "Damage" :
			animated_sprite.play("Damage")
	elif state != EnemyState.Dead:
		if state == EnemyState.Run or state == EnemyState.Chase:
			if animated_sprite.animation != "Run" :
				animated_sprite.play("Run")
		elif state == EnemyState.Wait :
			if animated_sprite.animation != "Idle" :
				animated_sprite.play("Idle")
		elif state == EnemyState.Attack and is_attacking == true :
			if animated_sprite.animation != "Attack" :
				animated_sprite.play("Attack")
func die() :
	if health <= 0 and not dead :
		switch_to_death()
		return
		
func take_damage(damage_amount : int , attacker_position : Vector2 , knockback_force : int ) :
	if state == EnemyState.Dead or is_taking_damage :
		return
	
	if health > 0 :
		health -= damage_amount
		is_taking_damage = true
		print("EnemyHealth :", health)
		
		var knockback_direction = sign(global_position.x - attacker_position.x)
		if knockback_direction == 0 :
			knockback_direction = 1
			
		knockback_velocity.x = knockback_direction * knockback_force

	
		await get_tree().create_timer(0.5).timeout
		is_taking_damage = false
		knockback_velocity = Vector2.ZERO
		
	else :
		die()
		
func _on_dead_timer_timeout() -> void:
	queue_free()

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not dead:
		state = EnemyState.Chase
		player_in_chase_range = true
	
func _on_chase_area_body_exited(body: Node2D) -> void:
	state = EnemyState.Wait
	player_in_chase_range = false
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not dead :
		state = EnemyState.Attack
		is_attacking = true
		attack_timer.start(0.7)
		player_in_attack_range = true
		velocity.x = 0
		

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" and not dead :
		player_in_attack_range = false
	
func _on_attack_timer_timeout() -> void:
	if dead :
		return
		
	
	if player_in_attack_range:
		state = EnemyState.Attack
		is_attacking = true
		attack_timer.start(0.7)
		velocity.x = 0
		
	elif player_in_chase_range:
		state = EnemyState.Chase
		is_attacking = false
		player_in_attack_range = false
		
	elif not player_in_chase_range:
		if state != EnemyState.Wait :
			state = EnemyState.Wait
			if state == EnemyState.Wait :
				state = EnemyState.Run
				
				

		
func flips_enemy() :
	if dir.x > 0 :
		animated_sprite.flip_h = false
		chase_area.position.x = right_chase_hitbox
		attack_area.position.x = right_attack_hitbox
	elif dir.x < 0:
		animated_sprite.flip_h = true
		chase_area.position.x = left_chase_hitbox
		attack_area.position.x = left_attack_hitbox
		
		
func choose(array) :
	array.shuffle()
	return array.front()


func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite != null :
		if animated_sprite.animation == "Attack" :
			if animated_sprite.frame == 5 :
				if player_in_attack_range and player.has_method("take_damage") :
					player.take_damage(attacking_damage , global_position , knockback_force , upback_force )
					print("Attack hit! Player health: ", player.health)
			
