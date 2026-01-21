extends CharacterBody3D

# This is the material that creates the "outline" or "glow" effect when looking at objects
@export var ghost_material: Material

# --- Constants: Values that never change during gameplay ---
const SPEED = 5.0              # How fast the player walks
const JUMP_VELOCITY = 4.5       # How high the player jumps
const MOUSE_SENSITIVITY = 0.002 # How fast the camera rotates when moving the mouse

# --- Node References: Grabbing parts of the Player scene tree ---
@onready var head = $Head                                 # The container for the camera
@onready var camera = $Head/Camera3D                     # The actual eyes of the player
@onready var raycast = $Head/Camera3D/RayCast3D           # The invisible line that "sees" objects
@onready var hold_pos = $Head/Camera3D/HoldPos           # The marker where a picked-up object floats
@onready var shadow_dot = $ShadowDot                     # Visual circle on the floor under held items
@onready var drop_ray = $Head/Camera3D/DropRay           # Calculates where the floor is for dropping
@onready var ghost_preview = $GhostPreview               # The semi-transparent preview shown on the floor
@onready var display_info_label = $DisplayInformation     # UI Text for tutorials/info
@onready var crosshair = $CanvasLayer/CenterContainer/Crosshair # The UI dot in the middle of the screen
@onready var drop_sound = $Head/Camera3D/DropSound       # Sound effect node

# --- Gameplay Variables: Values that change while playing ---
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # Gets world gravity from settings
var picked_object: RigidBody3D = null         # Stores the object currently being carried
var pull_power = 20.0                         # How strongly the physics "hand" pulls the object
var last_hovered_object: Node3D = null        # Remembers the last thing we looked at (to turn off highlight)
var is_rotating_object = false                # True if the player is holding the rotate key
var rotation_speed = 0.05                     # How fast we can spin held items
var is_tilted = false                         # State for the 90-degree tilt feature
var target_tilt_x = 0.0                       # The angle the held object should try to reach
var hud                                       # Holds the reference to our UI system

func _ready():
	# Search the entire game tree to find the HUD node
	hud = get_tree().root.find_child("HUD", true, false)
	
	# Start the intro text timer
	display_information_timer()
	
	# Hide the mouse cursor and lock it to the center
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Hide helper visuals at the start
	ghost_preview.visible = false
	shadow_dot.visible = false

	# Reset crosshair to default color
	if crosshair:
		crosshair.modulate = Color.WHITE

func display_information_timer():
	# Shows the instruction label for 5 seconds then hides it
	display_info_label.visible = true
	await get_tree().create_timer(5.0).timeout
	display_info_label.visible = false

func _unhandled_input(event):
	# Handles looking around with the mouse
	if event is InputEventMouseMotion:
		# If carrying something and rotating it, spin the item instead of the player
		if picked_object and is_rotating_object:
			var rot_amount = event.relative.x * rotation_speed
			picked_object.angular_velocity.y = rot_amount * 10.0
		else:
			# Normal camera rotation (Left/Right on body, Up/Down on head)
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			# Stop the player from doing a backflip with their neck
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# --- Basic Movement ---
	if not is_on_floor():
		velocity.y -= gravity * delta # Apply gravity if in the air

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY # Apply upward force

	# Get WASD/Joystick input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Smoothly slow down to a stop
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide() # Godot's built-in movement physics

	# --- Carrying Logic ---
	if picked_object:
		var target_pos = hold_pos.global_position
		var current_pos = picked_object.global_position
		
		# Move the item toward the 'hand' using velocity (so it can hit walls)
		var vel_vector = (target_pos - current_pos) * pull_power
		picked_object.linear_velocity = vel_vector.limit_length(25.0)
		
		# Force the object to stay at the current tilt angle
		picked_object.global_rotation.x = target_tilt_x
		picked_object.global_rotation.z = 0 
		
		# Prevent the object from spinning wildly while carrying
		if is_rotating_object:
			picked_object.angular_velocity.x = 0
			picked_object.angular_velocity.z = 0
		else:
			picked_object.angular_velocity = Vector3.ZERO

		# --- Placement Helpers (Ghost/Shadow) ---
		drop_ray.global_position = picked_object.global_position # Position the ray at the item
		if drop_ray.is_colliding():
			var hit_pos = drop_ray.get_collision_point()
			
			# Show shadow dot on the ground
			shadow_dot.visible = true
			var dist = picked_object.global_position.distance_to(hit_pos)
			var shadow_scale = clamp(1.0 - (dist * 0.3), 0.2, 1.0) # Shrink shadow if item is high up
			shadow_dot.scale = Vector3(shadow_scale, 1, shadow_scale)
			shadow_dot.global_position = hit_pos + Vector3(0, 0.01, 0) # Raise slightly to avoid flickering

			# Show the ghost preview (where the item will land)
			ghost_preview.visible = true
			ghost_preview.global_position = hit_pos + Vector3(0, 0.01, 0)
			ghost_preview.global_basis = picked_object.global_basis # Match the item's rotation
		else:
			shadow_dot.visible = false
			ghost_preview.visible = false
	else:
		# If not carrying anything, hide the helpers
		shadow_dot.visible = false
		ghost_preview.visible = false

	handle_highlight() # Run the look-at detection every frame

func _input(event):
	# Escape key to free the mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	# Clicking back into the game locks the mouse
	if event.is_action_pressed("left_mouse_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Interact Key (E)
	if event.is_action_pressed("interact"):
		if picked_object == null:
			pick_up_object()
		else:
			drop_object()

	# R key: Tilts the object 90 degrees (useful for plates/boxes)
	if event.is_action_pressed("toggle_tilt") and picked_object:
		is_tilted = !is_tilted
		if is_tilted:
			target_tilt_x = deg_to_rad(90) if target_tilt_x == 0 else 0.0
		else:
			target_tilt_x = 0.0

	# Mouse Right Click (Hold): Allows spinning the object
	if event.is_action_pressed("rotate"):
		is_rotating_object = true
	elif event.is_action_released("rotate"):
		is_rotating_object = false

func pick_up_object():
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		# Case 1: If it's the StaticBody box, trigger the 'Burst' code
		if collider.has_method("open_box"):
			collider.open_box()

		# Case 2: If it's a physics item (RigidBody), pick it up
		if collider is RigidBody3D:
			picked_object = collider
			picked_object.gravity_scale = 0.0 # Disable gravity so it stays in hand
			picked_object.set_collision_mask_value(3, false) # Disable collision with Player (Layer 3)
			
			# Tell all PlacementAreas to show arrows
			var areas = get_tree().get_nodes_in_group("PlacementArea")
			for area in areas:
				if area.has_method("show_arrow"):
					area.show_arrow(true)
			
			# --- Setup Ghost Preview ---
			# Clear old mesh parts from the ghost node
			for child in ghost_preview.get_children():
				child.queue_free()

			# Find all meshes in the picked item and copy them to the ghost
			var meshes = picked_object.find_children("*", "MeshInstance3D", true)
			for original_mesh in meshes:
				if not original_mesh.visible: continue
				
				var ghost_part = original_mesh.duplicate() # Create a copy of the mesh
				ghost_preview.add_child(ghost_part)
				ghost_part.transform = original_mesh.transform # Keep local position relative to parent
				ghost_part.material_overlay = null # Remove highlight from ghost
				ghost_part.material_override = ghost_material # Apply transparent material
				
			_show_placement_arrow()


func drop_object():
	if picked_object:
		# Play the drop sound with slight pitch variation
		if drop_sound:
			drop_sound.pitch_scale = randf_range(0.9, 1.1)
			drop_sound.play()
		
		_hide_placement_arrow()
		
		# Teleport item to the ghost position if it's hitting a floor
		if drop_ray.is_colliding():
			var hit_pos = drop_ray.get_collision_point()
			var hit_normal = drop_ray.get_collision_normal()
			# Place slightly above floor to prevent clipping
			picked_object.global_position = hit_pos + (hit_normal * 0.05)
			# Level the object out so it doesn't land at a weird tilt
			picked_object.global_rotation.x = 0
			picked_object.global_rotation.z = 0
			
		# Re-enable physics and collision
		picked_object.set_collision_mask_value(3, true)
		picked_object.gravity_scale = 1.0
		picked_object.linear_velocity = Vector3.ZERO
		picked_object.angular_velocity = Vector3.ZERO
		
		# Tell all PlacementAreas to hide arrows
		var areas = get_tree().get_nodes_in_group("PlacementArea")
		for area in areas:
			if area.has_method("show_arrow"):
				area.show_arrow(false)
		
		ghost_preview.visible = false
		picked_object = null

func handle_highlight():
	# If we are already holding something, we don't need to highlight other items
	if picked_object:
		if crosshair: crosshair.modulate = Color.WHITE
		if hud: hud.show_holding_hints()
		if last_hovered_object:
			set_highlight(last_hovered_object, false)
		return

	# If the raycast is hitting something
	if raycast.is_colliding():
		var collider = raycast.get_collider()
			
		# --- Check for RigidBodies (Items) ---
		if collider is RigidBody3D:
			if crosshair: crosshair.modulate = Color.YELLOW
			if hud: hud.show_pickup_hint()
			
				
			# If looking at a NEW object, swap the highlights
			if last_hovered_object != collider:
				if last_hovered_object:
					set_highlight(last_hovered_object, false)
				set_highlight(collider, true)
				last_hovered_object = collider
		
		# --- Check for UnpackingBox script ---
		elif collider.has_method("open_box"):
			if crosshair: crosshair.modulate = Color.YELLOW
			if hud: hud.show_pickup_hint()
			
			if last_hovered_object != collider:
				if last_hovered_object:
					set_highlight(last_hovered_object, false)
				set_highlight(collider, true)
				last_hovered_object = collider
			
		# If hitting something but it's not an item or a box
		else:
			clear_highlight()
			if hud: hud.hide_all_tips()
	else:
		# Raycast is hitting empty space
		clear_highlight()
		if hud: hud.hide_all_tips()


func clear_highlight():
	# Resets the visual state when looking away from things
	if crosshair: crosshair.modulate = Color.WHITE
	if last_hovered_object:
		set_highlight(last_hovered_object, false)
		last_hovered_object = null

func set_highlight(obj: Node3D, enabled: bool):
	if not obj: return
	
	# 'true' searches children and grandchildren (essential for Kenney models)
	var all_meshes = obj.find_children("*", "MeshInstance3D", true)
	
	for mesh in all_meshes:
		# If your material uses transparency/alpha to show the highlight
		if mesh.material_overlay is StandardMaterial3D:
			# Set alpha to 1.0 (visible) or 0.0 (invisible)
			mesh.material_overlay.albedo_color.a = 1.0 if enabled else 0.0


func _show_placement_arrow():
	# Tell all PlacementAreas to show arrows
	var areas = get_tree().get_nodes_in_group("PlacementArea")
	for area in areas:
		if area.has_method("show_arrow"):
			area.show_arrow(true)


func _hide_placement_arrow():
	# Tell all PlacementAreas to show arrows
	var areas = get_tree().get_nodes_in_group("PlacementArea")
	for area in areas:
		if area.has_method("show_arrow"):
			area.show_arrow(true)
