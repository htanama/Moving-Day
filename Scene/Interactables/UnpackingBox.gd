extends StaticBody3D

# @export allows you to drag and drop PackedScenes (your item scenes) in the Inspector
@export var contents: Array[PackedScene] = []
@export var unpack_force: float = 5.0

var is_opened: bool = false

# Use @onready to grab nodes when the game starts
@onready var spawn_point = $SpawnPoint
@onready var audio_player = $UnpackSound

func _ready():
	# Ensure the nodes exist; if not, Godot will show an error here
	pass

# This function is called by the Player script's 'pick_up_object' method
func open_box():
	# Prevent opening multiple times or opening an empty box
	if contents.size() > 0:
		var item_scene = contents.pop_front()
		
		if audio_player:
			# Randomize pitch for a more natural sound
			audio_player.pitch_scale = randf_range(0.9, 1.1)
			audio_player.play()
		print("Unpacking box...")
		# Instantiate the object (The GDScript way)
		var item = item_scene.instantiate()
			
		# Add it to the scene (usually to the level, not the box itself)
		get_parent().add_child(item)
		
		# Set position to the box's spawn point
		item.global_position = spawn_point.global_position
		# Optional: Remove the box from the world after it's empty
		# queue_free()
