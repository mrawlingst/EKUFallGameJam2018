extends KinematicBody2D


const GRAVITY_VEC = Vector2(0, 900)
const FLOOR_NORMAL = Vector2(0, -1)

const WALK_SPEED = 70
const STATE_WALKING = 0
const STATE_KILLED = 1

var linear_velocity = Vector2()
var direction = -1
var anim=""

var state = STATE_WALKING

var health = 20
var fire_dot_stack = 0
var fire_dot_time = 3

onready var detect_floor_left = $detect_floor_left
onready var detect_wall_left = $detect_wall_left
onready var detect_floor_right = $detect_floor_right
onready var detect_wall_right = $detect_wall_right
onready var sprite = $sprite

func _physics_process(delta):
	var new_anim = "idle"

	if state==STATE_WALKING:
		linear_velocity += GRAVITY_VEC * delta
		linear_velocity.x = direction * WALK_SPEED
		linear_velocity = move_and_slide(linear_velocity, FLOOR_NORMAL)

		if not detect_floor_left.is_colliding() or detect_wall_left.is_colliding():
			direction = 1.0

		if not detect_floor_right.is_colliding() or detect_wall_right.is_colliding():
			direction = -1.0

		sprite.scale = Vector2(direction, 1.0)
		new_anim = "walk"
	else:
		new_anim = "death"


	if anim != new_anim:
		anim = new_anim
		$anim.play(anim)

func _process(delta):
	if health < 0:
		state = STATE_KILLED
		$CollisionShape2D.disabled = true

func hit_by_fire():
	$fire_dot.start(1)
	fire_dot_time = 3
	fire_dot_stack += 1
	if fire_dot_stack > 3:
		fire_dot_stack = 3
	#state = STATE_KILLED
	#$CollisionShape2D.disabled = true

func _on_fire_dot_timeout():
	if fire_dot_time > 0:
		#$fire_dot.start(1)
		fire_dot_time -= 1
	else:
		$fire_dot.stop()
	var damage = fire_dot_stack
	health -= damage
	print("health: " + str(health))
	print("fire_dot_stack: " + str(fire_dot_stack))
	print("fire_dot_time: " + str(fire_dot_time))
