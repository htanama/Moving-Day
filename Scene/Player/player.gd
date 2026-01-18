extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hold_pos: Marker3D = $Head/Camera3D/HoldPos
@onready var shadow_dot: Node3D = $ShadowDot
@onready var drop_ray: RayCast3D = $Head/Camera3D/DropRay
@onready var ghost_preview: MeshInstance3D = $GhostPreview
@onready var display_information: Label3D = $DisplayInformation



# --- NEW: Crosshair reference ---
@onready var crosshair = $CanvasLayer/CenterContainer/Crosshair 

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var picked_object = null
var pull_power = 20.0 
var last_hovered_object = null
var is_rotating_object = false
var rotation_speed = 0.05

func _ready():
	_display_information()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ghost_preview.visible = false
	shadow_dot.visible = false
	# Crosshair should start neutral
	if crosshair:
		crosshair.modulate = Color.WHITE

func _display_information():
	display_information.visible = true
	await get_tree().create_timer(5.0).timeout
	display_information.visible = false

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if picked_object and is_rotating_object:
			var rot_amount = event.relative.x * rotation_speed
			picked_object.angular_velocity.y = rot_amount * 10
		else:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	if picked_object != null:
		var target_pos = hold_pos.global_transform.origin
		var current_pos = picked_object.global_transform.origin
		
		# Move object to hand with speed limit for stability
		var velocity_vector = (target_pos - current_pos) * pull_power
		picked_object.linear_velocity = velocity_vector.limit_length(25.0)
		
		# Keep upright
		var current_y_rot = picked_object.global_rotation.y
		picked_object.global_rotation = Vector3(0, current_y_rot, 0)
		
		if is_rotating_object:
			picked_object.angular_velocity.x = 0
			picked_object.angular_velocity.z = 0
		else:
			picked_object.angular_velocity = Vector3.ZERO
		
		# Ghost/Shadow
		drop_ray.global_position = picked_object.global_position
		if drop_ray.is_colliding():
			var hit_pos = drop_ray.get_collision_point()
			shadow_dot.visible = true
			var dist = picked_object.global_position.distance_to(hit_pos)
			var shadow_scale = clamp(1.0 - (dist * 0.3), 0.2, 1.0)
			shadow_dot.scale = Vector3(shadow_scale, 1, shadow_scale)
			shadow_dot.global_position = hit_pos + Vector3(0, 0.01, 0)
			
			ghost_preview.visible = true
			ghost_preview.global_position = hit_pos + Vector3(0, 0.01, 0)
			ghost_preview.global_transform.basis = picked_object.global_transform.basis
		else:
			shadow_dot.visible = false
			ghost_preview.visible = false
	else:
		shadow_dot.visible = false
		ghost_preview.visible = false
		
	_handle_highlight()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_mouse_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("interact"): 
		if picked_object == null:
			_pick_up_object()
		else:
			_drop_object()

	if event.is_action_pressed("rotate"): 
		is_rotating_object = true
	elif event.is_action_released("rotate"):
		is_rotating_object = false

func _pick_up_object():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is RigidBody3D:
			picked_object = collider
			picked_object.gravity_scale = 0.0
			
			# Disable collision with Player (Layer 3)
			picked_object.set_collision_mask_value(3, false)
			
			var original_mesh = picked_object.find_child("*MeshInstance3D*", true)
			if original_mesh:
				ghost_preview.mesh = original_mesh.mesh
				ghost_preview.scale = original_mesh.scale

func _drop_object():
	if picked_object != null:
		if drop_ray.is_colliding():
			var hit_pos = drop_ray.get_collision_point()
			var hit_normal = drop_ray.get_collision_normal()
			picked_object.global_position = hit_pos + (hit_normal * 0.05)
			var current_y = picked_object.global_rotation.y
			picked_object.global_rotation = Vector3(0, current_y, 0)
		
		# Re-enable collision with Player
		picked_object.set_collision_mask_value(3, true)
		
		picked_object.gravity_scale = 1.0
		picked_object.linear_velocity = Vector3.ZERO
		picked_object.angular_velocity = Vector3.ZERO
		
		ghost_preview.visible = false
		ghost_preview.mesh = null
		picked_object = null 

func _handle_highlight():
	if picked_object != null:
		if crosshair: crosshair.modulate = Color.WHITE
		if last_hovered_object:
			_set_highlight(last_hovered_object, false)
		return
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is RigidBody3D:
			if crosshair: crosshair.modulate = Color.YELLOW # Change crosshair color
			
			if last_hovered_object != collider:
				if last_hovered_object:
					_set_highlight(last_hovered_object, false)
				_set_highlight(collider, true)
				last_hovered_object = collider
		else:
			_clear_highlight()
	else:
		_clear_highlight()

func _clear_highlight():
	if crosshair: crosshair.modulate = Color.WHITE # Reset crosshair
	if last_hovered_object:
		_set_highlight(last_hovered_object, false)
		last_hovered_object = null

func _set_highlight(object, enabled):    
	var mesh = object.find_child("*MeshInstance3D*", true)
	if mesh and mesh.material_overlay:
		var overlay = mesh.material_overlay
		if overlay is StandardMaterial3D:
			overlay.albedo_color.a = 1.0 if enabled else 0.0
