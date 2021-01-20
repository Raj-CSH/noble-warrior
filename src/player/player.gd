extends KinematicBody2D
class_name Player

const ATTACK2_TIME = 0.6
const ATTACK3_TIME = 0.8

const ACCELERATION = 500
const FRICTION = 500
const GRAVITY = 500 
const JUMP_HEIGHT = 250
const MAX_SPEED = 200 
const TARGET_VELOCITY = Vector2(0 * MAX_SPEED, 1 * JUMP_HEIGHT)

enum {
		MOVE,
		ATTACK_INPUT,
		ATTACK1,
		ATTACK2,
		ATTACK3
}

var direction = 1
var next_attack_state = ATTACK1
var velocity = TARGET_VELOCITY
var state = MOVE
var uninterruptible_animation = false

onready var animation_player = $AnimationPlayer
onready var attack2_timer = $Attack2Timer
onready var attack3_timer = $Attack3Timer

func _ready():
	attack2_timer.connect("timeout", self, "attack2_timeout")
	attack3_timer.connect("timeout", self, "attack3_timeout")

func _process(delta):
	match state:
		ATTACK_INPUT:
			attack_input_state()
		ATTACK1:
			attack1_state()
		ATTACK2:
			attack2_state()
		ATTACK3:
			attack3_state()

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)

func set_direction(dir):
	if direction != dir and dir != 0:
		direction = dir
		apply_scale(Vector2(-1, 1))

func activate_uninterruptible_animation():
	uninterruptible_animation = true
	print("Activated!")

func deactivate_uninterruptible_animation():
	uninterruptible_animation = false
	print("Deactivated!")

func play_animation(animation, queue=false, prioritize=false):
	if not uninterruptible_animation or prioritize and not queue:
		animation_player.play(animation)
	else:
		animation_player.queue(animation)

func attack_input_state():
	if Input.is_action_just_pressed("attack"):
		attack2_timer.stop()
		attack3_timer.stop()
		print("Attack Input!")
		state = next_attack_state
	else:
		state = MOVE

func attack1_state():
	print("Attack 1!")
	activate_uninterruptible_animation()
	play_animation("Attack1", false, true)
	attack2_timer.start(ATTACK2_TIME)
	state = MOVE 
	next_attack_state = ATTACK2

func attack2_state():
	print("Attack 2!")
	activate_uninterruptible_animation()
	play_animation("Attack2", false, true)
	attack3_timer.start(ATTACK3_TIME)
	state = ATTACK_INPUT
	next_attack_state = ATTACK3

func attack3_state():
	print("Attack 3!")
	activate_uninterruptible_animation()
	play_animation("Attack3", false, true)
	state = MOVE 
	next_attack_state = ATTACK1

func attack2_timeout():
	print("Attack 2 timed out!")
	state = MOVE
	next_attack_state = ATTACK1

func attack3_timeout():
	print("Attack 3 timed out!")
	state = MOVE
	next_attack_state = ATTACK1

func move_state(delta):
	var inert_velocity = Vector2(0, GRAVITY * delta)
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.is_action_just_pressed("jump") as int
	input_vector = input_vector.normalized()

	if input_vector.x:
		set_direction(sign(input_vector.x))
		play_animation("Run")
		velocity.x = move_toward(velocity.x, input_vector.x * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, TARGET_VELOCITY.x, FRICTION * delta)

	if input_vector.y and is_on_floor():
		play_animation("Jump")
		velocity.y = -JUMP_HEIGHT
	else:
		velocity.y = move_toward(velocity.y, TARGET_VELOCITY.y, GRAVITY * delta)

	if not is_on_floor():
		play_animation("Fall", true)

	if velocity == inert_velocity:
		play_animation("Idle")

	velocity = move_and_slide(velocity, Vector2.UP)
	state = ATTACK_INPUT

