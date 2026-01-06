extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword: CollisionShape2D = $Sword/HurtBox

enum States {IDLE, RUN, ATTACK, FALL, JUMP, JPATTACK, JATTACK}

var current_state: States = States.IDLE

func _ready() -> void:
	if not is_on_floor():
		change_state(States.FALL)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	match current_state:
		States.IDLE:
			idle_state(delta)
		States.RUN:
			run_state(delta)
		States.ATTACK:
			attack_state(delta)
		States.FALL:
			fall_state(delta)
		States.JUMP:
			jump_state(delta)
		States.JPATTACK:
			jpattack_state(delta)
		States.JATTACK:
			jattack_state(delta)
	move_and_slide()

func idle_state(delta):
	if not is_on_floor():
		change_state(States.FALL)
	velocity.x = move_toward(velocity.x, 0, SPEED)
	play_animation('idle')
	if Input.get_axis("move_left", "move_right"):
		change_state(States.RUN)
	if Input.is_action_just_pressed("move_up"):
		change_state(States.JUMP)
	if Input.is_action_just_pressed("attack"):
		change_state(States.ATTACK)

func run_state(delta):
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		sprite.flip_h = false
		sword.set("position", Vector2(10, 0))
	elif direction < 0:
		sprite.flip_h = true
		sword.set("position", Vector2(-10, 0))
	play_animation("walking")
	velocity.x = direction * SPEED
	if direction == 0:
		change_state(States.IDLE)
	if Input.is_action_just_pressed("move_up"):
		change_state(States.JUMP)
	if Input.is_action_just_pressed("attack"):
		change_state(States.ATTACK)

func attack_state(delta):
	velocity.x = 0
	play_animation("attacking")

func jump_state(delta):
	play_animation("jumping")
	if velocity.y > 0:
		change_state(States.FALL)
	else: 
		if Input.is_action_just_pressed("attack"):
			change_state(States.JPATTACK)

func fall_state(delta):
	play_animation("fall")
	if is_on_floor():
		change_state(States.IDLE)
	elif Input.is_action_just_pressed("attack"):
		change_state(States.JPATTACK)

func jpattack_state(delta):
	play_animation("jpattacking")
	if is_on_floor():
		change_state(States.JATTACK)

func jattack_state(delta):
	play_animation("jattacking")
	velocity.x = 0

func change_state(new_state):
	if current_state == new_state:
		return
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)

func enter_state(new_state):
	match new_state:
		States.JUMP:
			velocity.y = JUMP_VELOCITY
		States.ATTACK:
			sword.visible = true
		States.JATTACK:
			sword.visible = true

func exit_state(old_state):
	match old_state:
		States.ATTACK:
			sword.visible = false
		States.JATTACK:
			sword.visible = false

# this is so fucking useful
func play_animation(anim_name: String):
	if sprite.animation == anim_name:
		return
	sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		States.ATTACK:
			change_state(States.IDLE)
		States.JPATTACK:
			if is_on_floor():
				change_state(States.JATTACK)
		States.JATTACK:
			change_state(States.IDLE)
