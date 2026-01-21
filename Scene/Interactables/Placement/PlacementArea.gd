extends Area3D

@onready var arrow = $PlacementArrow

@export var my_checklist_label: Label
@export var zone_name: String
@export var required_items: int = 3

var is_complete: bool = false
var items_in_zone: Array[RigidBody3D] = []
var is_goal_reached: bool = false

@onready var stars = $GPUParticles3D
@onready var audio = $VictorySound
@onready var hud = get_tree().root.find_child("HUD", true, false)

func _ready():
	if arrow:
		arrow.visible = false
		
	# Connect signals (Self refers to this Area3D)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	# Check if it's a RigidBody and not already in our list
	if body is RigidBody3D and not body in items_in_zone:
		items_in_zone.append(body)
		check_completion()

func _on_body_exited(body: Node3D):
	if body is RigidBody3D and body in items_in_zone:
		items_in_zone.erase(body)
		check_completion()

func check_completion():
	var count = items_in_zone.size()
	is_complete = count >= required_items

	# Update the HUD checklist
	if hud and my_checklist_label:
		# Note: Ensure HUDManager.gd has 'update_zone_status' (snake_case)
		hud.update_zone_status(my_checklist_label, zone_name, count, required_items, is_complete)

	if is_complete and not is_goal_reached:
		trigger_victory()
	elif not is_complete:
		is_goal_reached = false

func trigger_victory():
	is_goal_reached = true
	
	if hud:
		hud.play_victory_burst()
	
	# 1. Play Sound
	if audio:
		audio.play()

	# 2. Burst Stars
	if stars:
		stars.restart() # Resets the one-shot timer
		stars.emitting = true
	
	print(zone_name + " Organized!")


func show_arrow(_is_visible: bool):
	if arrow:
		arrow.visible = _is_visible
