extends RigidBody3D

@export var contents: Array[PackedScene] = []
@export var burst_force: float = 8.0 # Higher force for the "explosion" effect

@onready var spawn_point = $SpawnPoint
@onready var audio_player = $UnpackSound

func open_box():
	if contents.size() == 0:
		print("Box is already empty!")
		return

	print("Bursting box open!")
	
	# Loop through EVERY item in the array at once
	for item_scene in contents:
		if item_scene == null: continue
		
		var item = item_scene.instantiate()
		get_tree().current_scene.add_child(item)
		
		item.global_position = spawn_point.global_position
		
		if item is RigidBody3D:
			# Create a random direction so they fly out like an explosion
			var random_dir = Vector3(
				randf_range(-1.0, 1.0), 
				1.5, # High upward bias
				randf_range(-1.0, 1.0)
			).normalized()
			
			item.apply_central_impulse(random_dir * burst_force)
	
	# Clear the array so it can't be triggered again
	contents.clear()
	
	if audio_player:
		audio_player.play()
