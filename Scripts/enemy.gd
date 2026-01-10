# THINGS TO ADD
# AWARENESS STATES - IDLE, PATROLLING, NOTICED, SEARCHING
# ACTION STATES -  CHASING, PREATTACK, ATTACK
# RECOVERY STATES - AWAIT, HURT, RETURNING
# DETECTION -> AWARENESS -> ACTION -> RECOVERY

extends CharacterBody2D

const SPEED = 30.0
const JUMP_VELOCITY = -200.0
const IDLE_DURATION := 8.0
const PATROL_DURATION := 25.0
const TURN_TIME:= 3.5
const ATTENTION_SPAN := 2.5
const CHASE_MULTIPLIER := 3.0
const AWAIT_TIME := 2.5
const NOTICE_TIME := 0.8
const MIN_ATTACK_DISTANCE := 10.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box: CollisionShape2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var detection: Area2D = $FacingPivot/Detection
@onready var raycast: RayCast2D = $FacingPivot/RaycastRight
@onready var sword_detection_area: Area2D = $FacingPivot/SwordDetectionArea
@onready var sword_detection: CollisionShape2D = $FacingPivot/SwordDetectionArea/SwordDetection
@onready var sword: CollisionShape2D = $FacingPivot/Sword/SwordHitBox
@onready var flying_sword: CollisionShape2D = $FacingPivot/Sword/SwordHitFlyingBox

enum States {IDLE, HURT, PREATTACK, ATTACK, PATROLLING, NOTICED, CHASING, SEARCHING, AWAIT, RETURNING}
var dir = 1
var current_state: States = States.IDLE
var last_state: States
var player: CharacterBody2D
var idle_time:= 0.0
var random_patrolling_time:= RandomNumberGenerator.new()
var patrolling_time: float
var turn_time:= 0.0
var await_time:= 0.0
var attention_span:= 0.0
var location_before_noticing
var returning:bool = false
var notice_time:= 0.0

func _ready() -> void:
	random_patrolling_time.randomize()
	patrolling_time = random_patrolling_time.randf_range(0.0, 10.0)
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
		States.PATROLLING:
			patrol_state(_delta)
		States.NOTICED:
			noticed_state(_delta)
		States.CHASING:
			chase_state(_delta)
		States.RETURNING:
			return_state(_delta)
		States.AWAIT:
			await_state(_delta)
	move_and_slide()

func idle_state(_delta):
	play_animation('idle')
	velocity.x = move_toward(velocity.x, 0, SPEED)
	idle_time += _delta
	turn_time += _delta
	if turn_time >= TURN_TIME:
		turn_time = 0.0
		turn_around()
	if idle_time >= IDLE_DURATION:
		idle_time = 0.0
		change_state(States.PATROLLING)

func search_state(_delta):
	attention_span += _delta
	if attention_span >= ATTENTION_SPAN:
		velocity.x = 0
		change_state(States.AWAIT)
		return
	velocity.x = dir * SPEED
	$FacingPivot.scale.x = dir

func patrol_state(_delta):
	velocity.x = dir * SPEED
	sprite.flip_h = dir < 0
	patrolling_time += _delta
	if patrolling_time >= PATROL_DURATION:
		patrolling_time = 0.0
		change_state(States.IDLE)
	if raycast.is_colliding():
		turn_around()

func noticed_state(_delta):
	velocity.x = 0
	# Too close → disengage and think
	if is_overlapping_player():
		change_state(States.AWAIT)
		return
	# In range → attack
	if sword_detection_area.overlaps_body(player):
		change_state(States.PREATTACK)
		return
	# Otherwise escalate to chase after reaction delay
	dir = sign(player.global_position.x - global_position.x)
	$FacingPivot.scale.x = dir
	notice_time += _delta
	if notice_time >= NOTICE_TIME:
		notice_time = 0.0
		change_state(States.CHASING)

func chase_state(_delta):
	dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * (SPEED * CHASE_MULTIPLIER)
	sprite.flip_h = dir < 0
	$FacingPivot.scale.x = dir

func preattack_state(_delta):
	velocity.x = 0

func attack_state(_delta):
	velocity.x = 0

func hurt_state(_delta):
	velocity.x = 0

func await_state(_delta):
	velocity.x = 0
	await_time += _delta
	if await_time < AWAIT_TIME:
		return
	await_time = 0.0
	change_state(States.RETURNING)

func return_state(_delta):
	var target_x = location_before_noticing
	var distance = target_x - global_position.x
	if abs(distance) < 2.0:
		global_position.x = target_x
		velocity.x = 0
		returning = false
		change_state(States.IDLE)
		return
	dir = sign(distance)
	velocity.x = dir * SPEED
	sprite.flip_h = dir < 0
	$FacingPivot.scale.x = dir
	returning = true

func change_state(new_state):
	if current_state == new_state:
		return
	last_state = current_state
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)

func enter_state(new_state):
	match new_state:
		States.HURT:
			play_animation("hurt")
			print("im hurt!")
		States.PREATTACK:
			play_animation("preattack")
			print("im preattacking!")
		States.ATTACK:
			play_animation("attack")
			print("im attacking!")
		States.PATROLLING:
			patrolling_time = 0.0
			play_animation("walking")
			print("im walking!")
		States.IDLE:
			idle_time = 0.0
			play_animation("idle")
			print("im idle!")
		States.CHASING:
			play_animation("running")
			print("im chasing!")
			location_before_noticing = global_position.x
		States.SEARCHING:
			play_animation("running")
			print("im searching")
			attention_span = 0.0
		States.NOTICED:
			notice_time = 0.0
			play_animation("idle")
			print("i noticed something!")
		States.AWAIT:
			play_animation("idle")
			velocity.x = -dir * 500
			print("im awaiting something!")
		States.RETURNING:
			play_animation("walking")
			print("im returning!!")

func exit_state(old_state):
	match old_state:
		States.CHASING:
			attention_span = 0.0

func is_overlapping_player() -> bool:
	return abs(player.global_position.x - global_position.x) < MIN_ATTACK_DISTANCE

func turn_around():
	dir *= -1
	sprite.flip_h = dir < 0
	$FacingPivot.scale.x = dir

func play_animation(anim_name: String):
	if sprite.animation == anim_name:
		return
	sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		States.IDLE:
			play_animation('idle')
		States.HURT:
			change_state(last_state)
		States.PREATTACK:
			change_state(States.ATTACK)
		States.ATTACK:
			change_state(States.NOTICED)

func _on_hurt_box_area_entered(area: Area2D) -> void:
	change_state(States.HURT)

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack" and current_state == States.ATTACK:
		match sprite.frame:
			0:
				sword.disabled = false
			1:
				sword.disabled = true

func _on_detection_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if current_state in [States.IDLE, States.PATROLLING, States.SEARCHING, States.RETURNING]:
		change_state(States.NOTICED)

func _on_detection_body_exited(body: Node2D) -> void:
	print('searching')
	change_state(States.SEARCHING)

func _on_sword_detection_area_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if abs(player.global_position.x - global_position.x) < MIN_ATTACK_DISTANCE:
		return
	if current_state != States.NOTICED and current_state != States.CHASING:
		return
	change_state(States.PREATTACK)
