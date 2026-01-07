extends CharacterBody2D

const SPEED = 120.0
const JUMP_VELOCITY = -200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: CollisionShape2D = $HitBox
@onready var sword: CollisionShape2D = $Sword/SwordHitBox
@onready var flying_sword: CollisionShape2D = $Sword/SwordHitFlyingBox

enum States {IDLE, HURT, PREATTACK, ATTACK, SEARCHING, CHASING, BATTLING}

var current_state: States = States.IDLE
var player: CharacterBody2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	change_state(States.IDLE)

func _physics_process(_delta: float) -> void:
	if not is_on_floor():	
		velocity += get_gravity() * _delta
	match current_state:
		States.IDLE:
			idle_state(_delta)
		States.HURT:
			hurt_state(_delta)
		States.ATTACK:
			attack_state(_delta)
		States.PREATTACK:
			preattack_state(_delta)
		States.SEARCHING:
			search_state(_delta)
		States.CHASING:
			chase_state(_delta)
		States.BATTLING:
			battle_state(_delta)
	move_and_slide()

func idle_state(_delta):
	play_animation('idle')
	velocity.x = move_toward(velocity.x, 0, SPEED)
	if Input.is_action_just_pressed("debug_key"):
		change_state(States.PREATTACK)
	if can_see_player():
		change_state(States.CHASING)
	#searching is a temporary state, not a definite, idle is different

func search_state(_delta):
	#checking for last player location
	if can_see_player():
		change_state(States.CHASING)
	elif search_timer_expired():
		change_state(States.SEARCHING)

func chase_state(_delta):
	var player_location: float = player.position.length()
	var my_location: float = global_position.length()
	#here he goes after the last location player has been seen within his vision
	#move_toward(from: float, to: float, delta: float)
	move_toward(my_location, player_location, SPEED)
	pass

func battle_state(_delta):
	#player is within battling range
	pass

func preattack_state(_delta):
	velocity.x = 0

func attack_state(_delta):
	velocity.x = 0

func hurt_state(_delta):
	velocity.x = 0

func change_state(new_state):
	if current_state == new_state:
		return
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)

func enter_state(new_state):
	match new_state:
		States.HURT:
			play_animation("hurt")
		States.PREATTACK:
			play_animation("preattack")
		States.ATTACK:
			play_animation("attack")

func can_see_player():
	pass

func search_timer_expired():
	pass

func exit_state(old_state):
	pass

func play_animation(anim_name: String):
	if sprite.animation == anim_name:
		return
	sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		States.IDLE:
			play_animation('idle')
		States.HURT:
			change_state(States.IDLE)
		States.PREATTACK:
			change_state(States.ATTACK)
		States.ATTACK:
			change_state(States.IDLE)

func _on_hurt_box_area_entered(area: Area2D) -> void:
	change_state(States.HURT)

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack":
		match sprite.frame:
			0:
				sword.disabled = false
			2:
				sword.disabled = true
