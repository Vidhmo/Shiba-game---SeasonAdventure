extends AnimatedSprite2D

@export var player_node_path: NodePath
var player : CharacterBody2D = null
@onready var attack_hitbox: CollisionShape2D = %AttackHitbox


func _ready() :
	if player_node_path :
		player = get_node(player_node_path)
	
func _physics_process(delta: float) -> void:
	
	if not player :
		return
	
	# Player vars 
	
	var is_attacking = player.is_attacking
	var direction = player.velocity.x
	var on_floor = player.is_on_floor()
	var combo_count = player.combo_count
	var dead = player.dead
	var is_taking_damage = player.is_taking_damage
	
	
	#Flips the player
	
	if direction > 0 :
		flip_h = false
		attack_hitbox.position.x = 14.0
		
	elif direction < 0:
		flip_h = true
		attack_hitbox.position.x = 3.0
		
	
	
	#Animations of player
	if dead: 
		if animation != "Death":
			play("Death")
	elif is_taking_damage :
		if animation != "Damage" :
			play("Damage")
	elif is_attacking:
		var anim_name = "Attack_"+str(combo_count)
		if animation != anim_name:
			play(anim_name)
	elif not on_floor:
		if animation != "Jump":
			play("Jump")
	elif direction == 0:
		if animation != "Idle":
			play("Idle")
	elif direction != 0:
		if animation != "Run":
			play("Run")
		
	
	
