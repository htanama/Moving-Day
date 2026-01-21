extends Node3D

var time = 0.0
# Store the starting height so the arrow doesn't "drift" away over time
@onready var start_y = position.y 

func _process(delta):
	# Only animate if the arrow is actually shown
	if visible:
		time += delta
		
		# We use 'start_y +' instead of '+=' 
		# This keeps the bobbing centered on the original spot
		position.y = start_y + sin(time * 5.0) * 0.1 
		
		# Optional: Make it spin slowly too!
		rotate_y(delta * 3.0)
