extends Node3D

var particles: GPUParticles3D
var sfx: AudioStreamPlayer3D

func _ready():
	# 'get_children()' returns a list of every node attached to this one.
	# 'for child in ...' picks them up one by one so we can inspect them.
	for child in get_children():
		if child is GPUParticles3D:
			particles = child
		elif child is AudioStreamPlayer3D:
			sfx = child
			
	
	if not particles:
		return
	
	if particles:
		particles.emitting = true
	if sfx:
		sfx.play()

	# Wait and Clean up
	await get_tree().create_timer(10.0).timeout
	queue_free()
