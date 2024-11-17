class_name Flashlight
extends RigidBody3D

signal picked_up

@onready var area = $Area3D
@onready var mesh = $MeshInstance3D
var original_material: Material
var highlight_material: StandardMaterial3D
var is_highlighted = false

func _ready():
	# Physics setup
	gravity_scale = 1.0
	mass = 1.0
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 4
	
	# Updated physics properties
	linear_damp = 1.0     # Increased from 0.2
	angular_damp = 10.0
	lock_rotation = true
	
	# Add physics material
	var physics_mat = PhysicsMaterial.new()
	physics_mat.friction = 1.0
	physics_mat.rough = true
	physics_mat.bounce = 0.0
	physics_material_override = physics_mat
	
	# Uncomment if you want to lock horizontal movement
	# axis_lock_linear_x = true
	# axis_lock_linear_z = true
	
	# Check if nodes exist
	if !area:
		push_error("Area3D node not found!")
		return
		
	if !mesh:
		push_error("MeshInstance3D node not found!")
		return
	
	# Setup collision connections
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))
	
	# Setup highlight material
	if mesh.get_surface_override_material(0):
		original_material = mesh.get_surface_override_material(0)
	else:
		original_material = StandardMaterial3D.new()
		
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1.2, 1.2, 1.2, 1.0)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(0.2, 0.2, 0.2)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.set("pickup_in_range", self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.set("pickup_in_range", null)

func highlight():
	if !is_highlighted and mesh:
		mesh.set_surface_override_material(0, highlight_material)
		is_highlighted = true

func unhighlight():
	if is_highlighted and mesh:
		mesh.set_surface_override_material(0, original_material)
		is_highlighted = false

func pickup():
	freeze = true
	emit_signal("picked_up")
	queue_free()
