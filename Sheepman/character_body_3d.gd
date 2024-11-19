extends CharacterBody3D

const SPEED = 3.0 # Player speed
const JUMP_VELOCITY = 4.0 # Player jump velocity (upward force)
const CROUCH_SPEED = 1.0 # How fast the player can crouch
const CROUCHED_MOVE_SPEED = 1.5  # Player speed while crouched
const SPRINT_SPEED = 8.0 # Player speed while sprinting
const STAND_HEIGHT = 2.0 # Player height while standing
const CROUCH_HEIGHT = 0.5 # Player height while crouching
const JUMP_COST_STAMINA = 5 # Stamina cost for jumping

const MAX_STAMINA = 100.0 # Maximum stamina
const STAMINA_DRAIN_RATE = 10.0 # Stamina drain rate while sprinting
const STAMINA_RECOVERY_RATE = 5.0 # Stamina recovery rate while not sprinting
const CROUCH_STAMINA_RECOVERY_MULTIPLIER = 2.0  # Stamina recovery multiplier while crouching

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var collision_shape := $CollisionShape3D
@onready var stamina_bar := $StaminaLayer/StaminaBar
@onready var reach = $Neck/Camera3D/reach
@onready var hand = $Neck/Hand
@onready var Taschnelampe = preload("res://Taschenlampe.tscn")

var WeaponToSpawn
var WeaponToDorp
var is_crouching = false
var stamina = MAX_STAMINA
var is_sprinting = false
var is_jumping = false
var pickup_in_range = null 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var capsule = collision_shape.shape as CapsuleShape3D
	if capsule:
		capsule.height = STAND_HEIGHT
		collision_shape.position.y = 0
		camera.position.y = STAND_HEIGHT
		stamina_bar.max_value = MAX_STAMINA
		stamina_bar.value = stamina
		add_to_group("player")

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

func _input(event):
	if event.is_action_pressed("pickup") and pickup_in_range:
		pickup_in_range.pickup()
		pickup_in_range = null

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

	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, neck.global_rotation.y).normalized()

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and stamina >= JUMP_COST_STAMINA:
		velocity.y = JUMP_VELOCITY
		stamina -= JUMP_COST_STAMINA

	# Get the input direction and handle the movement/deceleration.
	var current_speed = SPEED  # Default to normal speed

	if is_crouching:
		current_speed = CROUCHED_MOVE_SPEED
	elif Input.is_action_pressed("sprint") and stamina > 0:
		current_speed = SPRINT_SPEED
		stamina -= STAMINA_DRAIN_RATE * delta
		if stamina <= 0:
			stamina = 0
			current_speed = SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Only recover stamina when on floor
	if is_on_floor():
		var recovery_rate = STAMINA_RECOVERY_RATE
		if is_crouching:
			recovery_rate *= CROUCH_STAMINA_RECOVERY_MULTIPLIER
		stamina += recovery_rate * delta

	stamina = clamp(stamina, 0, MAX_STAMINA)
	stamina_bar.value = stamina

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
				
				
	# Handle object pickup
	if Input.is_action_just_pressed("pickup") and pickup_in_range:
		pickup_in_range.emit_signal("picked_up")
		pickup_in_range.queue_free() # Objekt aus der Szene entfernen
		pickup_in_range = null
		
	# Handle sprinting input
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	
func _on_body_entered(body):
	if body.is_in_group("pickupable"):
		pickup_in_range = body
		
func _on_body_exited(body):
	if body == pickup_in_range:
		pickup_in_range = null
		
func _process(delta):
	if reach.is_colliding():
		if reach.get_collider().get_name() == "Taschnelampe":
			WeaponToSpawn = Taschnelampe.instantiate()
		else:
			WeaponToSpawn = null
	else:
		WeaponToSpawn = null
		
	if hand.get_child(0) != null:
		if hand.get_child(0).get_name() == "Taschnelampe":
			WeaponToDorp = Taschnelampe.instantiate()
	else:
		WeaponToSpawn = null
		
	if Input.is_action_just_pressed("interact"):
		if WeaponToSpawn != null:
			if hand.get_child(0) != null:
				get_parent().add_child(WeaponToSpawn)
				WeaponToDorp.global_transform = hand.global_transform
				WeaponToDorp.dropped = true
				hand.get_child(0).queue_free()
				reach.get_collider().queue_free()
				hand.add_child(WeaponToSpawn)
				WeaponToSpawn. rotation = hand.rotation
