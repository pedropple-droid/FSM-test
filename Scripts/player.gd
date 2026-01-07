extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_area: Area2D = $Sword
@onready var sword: CollisionShape2D = $Sword/SwordHitBox
@onready var flying_sword: CollisionShape2D = $Sword/SwordHitFlyingBox

enum States {IDLE, RUN, PREPARE_ATTACK, ATTACK, FALL, JUMP, JPATTACK, JATTACK, DEFENDING, HURT}

var current_state: States = States.IDLE

func _ready() -> void:
	if not is_on_floor():
		change_state(States.FALL)
	else:
		change_state(States.IDLE)

func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * _delta
	match current_state:
		States.IDLE:
			idle_state(_delta)
		States.RUN:
			run_state(_delta)
		States.ATTACK:
			attack_state(_delta)
		States.PREPARE_ATTACK:
			prepare_attack_state(_delta)
		States.FALL:
			fall_state(_delta)
		States.JUMP:
			jump_state(_delta)
		States.JPATTACK:
			jpattack_state(_delta)
		States.JATTACK:
			jattack_state(_delta)
		States.DEFENDING:
			defending_state(_delta)
		States.HURT:
			hurt_state(_delta)
	move_and_slide()

func idle_state(_delta):
	if not is_on_floor():
		change_state(States.FALL)
	play_animation("idle")
	velocity.x = move_toward(velocity.x, 0, SPEED)
	if Input.get_axis("move_left", "move_right"):
		change_state(States.RUN)
	if Input.is_action_just_pressed("move_up"):
		change_state(States.JUMP)
	if Input.is_action_just_pressed("attack"):
		change_state(States.PREPARE_ATTACK)
	if Input.is_action_just_pressed("defend"):
		change_state(States.DEFENDING)

func hurt_state(_delta):
	velocity.x = 0

func run_state(_delta):
	movement()
	play_animation("walking")
	if Input.is_action_just_pressed("move_up"):
		change_state(States.JUMP)
	if Input.is_action_just_pressed("attack"):
		change_state(States.PREPARE_ATTACK)
	if Input.is_action_just_pressed("defend"):
		change_state(States.DEFENDING)

func prepare_attack_state(_delta):
	velocity.x = 0
	if Input.is_action_just_pressed("defend"):
		change_state(States.DEFENDING)

func attack_state(_delta):
	velocity.x = 0

func jump_state(_delta):
	movement()
	if velocity.y > 0:
		change_state(States.FALL)
	else: 
		if Input.is_action_just_pressed("attack"):
			change_state(States.JPATTACK)

func fall_state(_delta):
	movement()
	if is_on_floor():
		change_state(States.IDLE)
	elif Input.is_action_just_pressed("attack"):
		change_state(States.JPATTACK)

func jpattack_state(_delta):
	if is_on_floor():
		change_state(States.JATTACK)

func jattack_state(_delta):
	velocity.x = 0

func defending_state(_delta):
	velocity.x = 0

func change_state(new_state):
	if current_state == new_state:
		return
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)

func enter_state(new_state):
	match new_state:
		States.FALL:
			play_animation("fall")
		States.JUMP:
			play_animation("jumping")
			velocity.y = JUMP_VELOCITY
		States.PREPARE_ATTACK:
			play_animation("pattacking")
		States.ATTACK:
			play_animation("attacking")
		States.JPATTACK:
			play_animation("jpattacking")
		States.JATTACK:
			play_animation("jattacking")
		States.DEFENDING:
			play_animation("defending")
		States.HURT:
			play_animation("hurt")

func exit_state(old_state):
	pass

# this is so fucking useful
func play_animation(anim_name: String):
	if sprite.animation == anim_name:
		return
	sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		States.IDLE:
			play_animation('idle')
		States.PREPARE_ATTACK:
			change_state(States.ATTACK)
		States.ATTACK:
			change_state(States.IDLE)
		States.JPATTACK:
			if is_on_floor():
				change_state(States.JATTACK)
		States.JATTACK:
			change_state(States.IDLE)
		States.DEFENDING:
			change_state(States.IDLE)
		States.HURT:
			change_state(States.IDLE)

func movement():
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		sprite.flip_h = false
		sword_area.set("position", Vector2(0, 0))
	elif direction < 0:
		sprite.flip_h = true
		sword_area.set("position", Vector2(-20, 0))
	velocity.x = direction * SPEED
	if direction == 0 and is_on_floor():
		change_state(States.IDLE)

func _on_hurt_box_area_entered(area: Area2D) -> void:
	change_state(States.HURT)

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attacking":
		match sprite.frame:
			0:
				sword.disabled = false
			2:
				sword.disabled = true
	if sprite.animation == "jattacking":
		match sprite.frame:
			0:
				flying_sword.disabled = false
			2:
				flying_sword.disabled = true
