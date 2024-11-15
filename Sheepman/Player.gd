extends CharacterBody3D

const SPEED = 7.0
const CROUCH_SPEED = 3.5
const SPRINT_SPEED = 10.0
const STAND_HEIGHT = 2
const CROUCH_HEIGHT = 1
const JUMP_VELOCITY = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var collision_shape := $CollisionShape3D

var is_crouching = false
var is_sprinting = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var capsule = collision_shape.shape as CapsuleShape3D
	if capsule:
		capsule.height = STAND_HEIGHT
		collision_shape.position.y = 0
		camera.position.y = STAND_HEIGHT

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_forward", "ui_back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else SPEED)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Important: This ensures proper collision detection and floor detection
	move_and_slide()
	
	# Handle crouching input
	if Input.is_action_pressed("crouch"):  # Make sure to define this action in Project Settings
		is_crouching = true
		var capsule = collision_shape.shape as CapsuleShape3D
		if capsule:
			capsule.height = CROUCH_HEIGHT
			collision_shape.position.y = (STAND_HEIGHT - CROUCH_HEIGHT)
			camera.position.y = CROUCH_HEIGHT
	elif Input.is_action_just_released("crouch"):
		is_crouching = false
		var capsule = collision_shape.shape as CapsuleShape3D
		if capsule:
			capsule.height = STAND_HEIGHT
			collision_shape.position.y = 0
			camera.position.y = STAND_HEIGHT
