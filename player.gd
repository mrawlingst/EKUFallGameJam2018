extends KinematicBody2D

export(int) var WALK_SPEED = 250
export(int) var BULLET_VELOCITY = 500

const GRAVITY_VEC = Vector2(0, 900)
const FLOOR_NORMAL = Vector2(0, -1)
const SLOPE_SLIDE_STOP = 25.0
const MIN_ONAIR_TIME = 0.1
#const WALK_SPEED = 250 # pixels/sec
const JUMP_SPEED = 480
const SIDING_CHANGE_SPEED = 10
#const BULLET_VELOCITY = 1000
const SHOOT_TIME_SHOW_WEAPON = 0.2

var linear_vel = Vector2()
var onair_time = 0 #
var on_floor = false
var shoot_time=99999 #time since last shot

var anim=""

#cache the sprite here for fast access (we will set scale to flip it often)
onready var sprite = $sprite

enum ELEMENTS {
	Wood = 0,
	Fire = 1,
	Earth = 2,
	Metal = 3,
	Water = 4
}

var currentElement
var currentElementIndex
var fire = preload("res://scenes/ability_fire.tscn").instance()
var fire_pos
var learnedElements = []

func _ready():
	learnedElements.push_back(ELEMENTS.Wood)
	learnedElements.push_back(ELEMENTS.Fire)
	#learnedElements.push_back(ELEMENTS.Earth)
	print(learnedElements)
	
	currentElementIndex = 0
	currentElement = learnedElements[currentElementIndex]

func _physics_process(delta):
	#increment counters

	onair_time += delta
	shoot_time += delta

	### MOVEMENT ###

	# Apply Gravity
	linear_vel += delta * GRAVITY_VEC
	# Move and Slide
	linear_vel = move_and_slide(linear_vel, FLOOR_NORMAL, SLOPE_SLIDE_STOP)
	# Detect Floor
	if is_on_floor():
		onair_time = 0

	on_floor = onair_time < MIN_ONAIR_TIME
	
	if has_node("ability_fire"):
		fire = get_node("ability_fire")
	else:
		fire = null

	### CONTROL ###

	if Input.is_action_just_pressed("cycle_left"):
		cycle_elements(true)
	elif Input.is_action_just_pressed("cycle_right"):
		cycle_elements(false)
	
	update_userinterface()

	# Horizontal Movement
	var target_speed = 0
	if Input.is_action_pressed("move_left"):
		target_speed += -1
	if Input.is_action_pressed("move_right"):
		target_speed +=  1

	target_speed *= WALK_SPEED
	linear_vel.x = lerp(linear_vel.x, target_speed, 0.1)

	# Jumping
	if on_floor and Input.is_action_just_pressed("jump"):
		linear_vel.y = -JUMP_SPEED
		$sound_jump.play()

	# Shooting
	if Input.is_action_just_pressed("ability"):
		if currentElement == ELEMENTS.Wood:
			var bullet = preload("res://bullet.tscn").instance()
			bullet.position = $sprite/bullet_shoot.global_position #use node for shoot position
			bullet.linear_velocity = Vector2(sprite.scale.x * BULLET_VELOCITY, 0)
			bullet.add_collision_exception_with(self) # don't want player to collide with bullet
			get_parent().add_child(bullet) #don't want bullet to move with me, so add it as child of parent
			$sound_shoot.play()
			shoot_time = 0
		elif currentElement == ELEMENTS.Fire:
			fire = preload("res://scenes/ability_fire.tscn").instance()
			fire_pos = $sprite/bullet_shoot.position
			fire.position = fire_pos
			fire.position.x += 15
			#fire.add_collision_exception_with(self)
			self.add_child(fire)
			fire.scale = Vector2(1.75, 1.75)

	### ANIMATION ###

	var new_anim = "idle"

	if on_floor:
		if linear_vel.x < -SIDING_CHANGE_SPEED:
			sprite.scale.x = -1
			if fire != null and currentElement == ELEMENTS.Fire:
				fire.scale.x = -1.75
				fire.position = fire_pos
				fire.position.x -= 40
			new_anim = "walk"

		if linear_vel.x > SIDING_CHANGE_SPEED:
			sprite.scale.x = 1
			if fire != null and currentElement == ELEMENTS.Fire:
				fire.scale.x = 1.75
				fire.position = fire_pos
				fire.position.x += 15
			new_anim = "walk"
	else:
		# We want the character to immediately change facing side when the player
		# tries to change direction, during air control.
		# This allows for example the player to shoot quickly left then right.
		if Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			sprite.scale.x = -1
			if fire != null and currentElement == ELEMENTS.Fire:
				fire.scale.x = -1.75
				fire.position = fire_pos
				fire.position.x -= 40
		if Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			sprite.scale.x = 1
			if fire != null and currentElement == ELEMENTS.Fire:
				fire.scale.x = 1.75
				fire.position = fire_pos
				fire.position.x += 15

		if linear_vel.y < 0:
			new_anim = "jumping"
		else:
			new_anim = "falling"

	#if shoot_time < SHOOT_TIME_SHOW_WEAPON:
		#new_anim += "_weapon"

	if new_anim != anim:
		anim = new_anim
		$anim.play(anim)

func cycle_elements(left):
	if learnedElements.size() == 1:
		return
	
	if left:
		currentElementIndex -= 1
		if currentElementIndex < 0:
			currentElementIndex = learnedElements.size() - 1
		currentElement = learnedElements[currentElementIndex]
	else:
		currentElementIndex += 1
		if currentElementIndex > learnedElements.size() - 1:
			currentElementIndex = 0
		currentElement = learnedElements[currentElementIndex]

func getElementStr(element):
	if element == ELEMENTS.Wood:
		return "Wood"
	elif element == ELEMENTS.Fire:
		return "Fire"
	elif element == ELEMENTS.Earth:
		return "Earth"
	elif element == ELEMENTS.Metal:
		return "Metal"
	else:
		return "Water"

func update_userinterface():
	var elementUI = get_parent().get_node("user_interface/Element")
	if elementUI != null:
		elementUI.text = "Element: " + getElementStr(currentElement)
