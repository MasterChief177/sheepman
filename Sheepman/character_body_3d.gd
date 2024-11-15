extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const CROUCH_SPEED = 1.5
const SPRINT_SPEED = 10.0
const STAND_HEIGHT = 2.0
const CROUCH_HEIGHT = 0.5

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

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))

func has_space_to_stand() -> bool:
	var space_check_start = global_transform.origin
	var space_check_end = global_transform.origin + Vector3(0, STAND_HEIGHT, 0)
	var space_check_params = PhysicsRayQueryParameters3D.new()
	space_check_params.from = space_check_start
	space_check_params.to = space_check_end
	space_check_params.exclude = [self]
	var space_check = get_world_3d().direct_space_state.intersect_ray(space_check_params)
	return space_check.is_empty()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else SPEED)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Handle crouching and standing
	if Input.is_action_pressed("crouch"):
		if not is_crouching:
			is_crouching = true
			var capsule = collision_shape.shape as CapsuleShape3D
			if capsule:
				capsule.height = CROUCH_HEIGHT
				collision_shape.position.y = (STAND_HEIGHT - CROUCH_HEIGHT) / 2
				camera.position.y = CROUCH_HEIGHT
	elif not is_crouching or (is_crouching and has_space_to_stand()):
		if has_space_to_stand():
			is_crouching = false
			var capsule = collision_shape.shape as CapsuleShape3D
			if capsule:
				capsule.height = STAND_HEIGHT
				collision_shape.position.y = 0
				camera.position.y = STAND_HEIGHT

	# Handle sprinting input
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
