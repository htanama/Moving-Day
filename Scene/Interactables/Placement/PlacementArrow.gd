extends Node3D

var time = 0.0
@onready var start_y = position.y 
@onready var mesh_node = $MeshInstance3D # Ensure this name matches your child node exactly
var material: StandardMaterial3D

# --- Settings ---
const ACTIVE_DISTANCE = 2.5 # Meters
const COLOR_NORMAL = Color.YELLOW
const COLOR_CLOSE = Color.GREEN

func _ready():
	if mesh_node:
		# We duplicate the material so each arrow can be a different color
		var original_mat = mesh_node.get_active_material(0)
		if original_mat:
			material = original_mat.duplicate()
			mesh_node.set_surface_override_material(0, material)

func _process(delta):
	# Optimization: If the arrow is hidden or missing a material, don't do math
	if not visible or not material:
		return
	
	time += delta
	
	# 1. Calculate Distance to Player Camera
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
	var dist = global_position.distance_to(camera.global_position)
	
	# 2. Change Color and Bobbing based on proximity
	if dist < ACTIVE_DISTANCE:
		# Player is CLOSE: Turn Green and vibrate fast
		material.albedo_color = COLOR_CLOSE
		# Use emission if you want it to glow in the dark!
		material.emission = COLOR_CLOSE 
		
		position.y = start_y + (sin(time * 15.0) * 0.05)
	else:
		# Player is FAR: Stay Yellow and bob slowly
		material.albedo_color = COLOR_NORMAL
		material.emission = COLOR_NORMAL
		
		position.y = start_y + (sin(time * 5.0) * 0.1)
	
	# 3. Visual Polish: Spin and Look at Player
	# We rotate the mesh itself or the parent
	rotate_y(delta * 2.0)
	
	# This makes the "flat" side of the arrow always face the player
	look_at(camera.global_position)
	rotation.x = 0
	rotation.z = 0
