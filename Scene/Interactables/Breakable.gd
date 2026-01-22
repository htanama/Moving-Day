extends RigidBody3D


@export var broken_version: PackedScene # A scene containing the "shards"
var break_speed_threshold = 15.0 # Speed required to break (m/s)
var is_broken = false

func _ready():
	# Connect the hit signal to our own function
	# This is like setting a trap: "Tell me when you hit something!"
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	if is_broken: return

	# Calculate the speed at the moment of impact
	# .length() converts the Vector3 velocity into a single number (speed)
	var impact_speed = linear_velocity.length()
	
	if _body.is_in_group("Floor"):
		if impact_speed < 1.0: # Much lower than table threshold
			shatter()
			return
	
	if impact_speed >= break_speed_threshold:
		shatter()
	#else:
		# Debug: This will tell you exactly what speed it hit the floor with
		#print("Hit ", _body.name, " at speed: ", impact_speed)
		

func shatter():
	is_broken = true
	
	# 1. Play a sound (optional)
	# You could spawn a sound effect node here
	
	# 2. Spawn the "Broken Shards" scene if you have one
	if broken_version:
		var shards = broken_version.instantiate()
		get_tree().root.add_child(shards)
		shards.global_position = self.global_position
		shards.global_basis = self.global_basis

	# 3. Delete the original unbroken object
	queue_free()
