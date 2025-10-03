extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $StateTimer
@onready var player: CharacterBody2D = %Player
@onready var chase_area: Area2D = $ChaseArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer

@export var patrol_time : float = 2
@export var wait_time : float = 3
@export var chase_speed : float = 70

@export var right_chase_hitbox = 41
@export var left_chase_hitbox = -41
@export var right_attack_hitbox = 7
@export var left_attack_hitbox = -7

enum EnemyState {Run , Wait , Chase , Attack}
var state : EnemyState = EnemyState.Wait

const gravity = 900.0
@export var speed : float = 10
var health : int = 100
var health_max : int = 100
var health_min : int = 0
var is_chasing : bool = false

var dead : bool 
var taking_damage : bool
var attacking_damage = 15
var is_attacking : bool = false

var dir : Vector2
var knockback_force = 200
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
	
	handle_animation()
	handle_movement()
	flips_enemy()
	last_direction()
	move_and_slide()
	
	
	
	
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
	
func _on_state_timer_timeout() -> void:
	if state == EnemyState.Run :
		switch_to_wait()
	elif state == EnemyState.Wait :
		switch_to_run()
		

func handle_animation():
	if not dead and not taking_damage:
		if state == EnemyState.Run or state == EnemyState.Chase:
			if animated_sprite.animation != "Run" :
				animated_sprite.play("Run")
		elif state == EnemyState.Wait :
			if animated_sprite.animation != "Idle" :
				animated_sprite.play("Idle")
		if state == EnemyState.Attack and is_attacking == true :
			if animated_sprite.animation != "Attack" :
				animated_sprite.play("Attack")
								

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" :
		state = EnemyState.Chase
		player_in_chase_range = true
	
func _on_chase_area_body_exited(body: Node2D) -> void:
	state = EnemyState.Wait
	player_in_chase_range = false
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" :
		state = EnemyState.Attack
		is_attacking = true
		attack_timer.start(0.7)
		player_in_attack_range = true
		velocity.x = 0

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" :
		player_in_attack_range = false
	
func _on_attack_timer_timeout() -> void:
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
