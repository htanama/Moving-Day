extends Control

@export_group("Level Completion Requirements")
@export var label_counter_area: Label
@export var label_cabinet_area: Label
@export var label_zone_area: Label
@export var total_zones_required: int = 3

var completed_zones: int = 0
var fade_tween: Tween

@onready var screen_stars = $ScreenStars
@onready var pickup_tip = $VBoxContainer/PickupTip
@onready var place_tip = $VBoxContainer/PlaceTip
@onready var rotate_tip = $VBoxContainer/RotateTip

func _ready():
	# Set initial transparency to 0 (invisible)
	pickup_tip.modulate.a = 0.0
	place_tip.modulate.a = 0.0
	rotate_tip.modulate.a = 0.0
	
	# Initial text setup
	if label_counter_area:
		label_counter_area.text = "[ ] Stove and Counter Area (0/3)"
	if label_cabinet_area:
		label_cabinet_area.text = "[ ] Cabinet Area (0/3)"
	if label_zone_area:
		label_zone_area.text = "[ ] Zone Area Book Case (0/3)"
		
		

func hide_all_tips():
	fade_to(pickup_tip, 0.0)
	fade_to(place_tip, 0.0)
	fade_to(rotate_tip, 0.0)

func show_pickup_hint():
	pickup_tip.text = "Click Left Mouse Button to Pick Up "
	fade_to(pickup_tip, 1.0)
	fade_to(place_tip, 0.0)
	fade_to(rotate_tip, 0.0)

func show_holding_hints():
	fade_to(pickup_tip, 0.0)
	fade_to(place_tip, 1.0)
	fade_to(rotate_tip, 1.0)

func fade_to(node: CanvasItem, target_opacity: float):
	# Don't restart a tween if we are already at the target
	if is_equal_approx(node.modulate.a, target_opacity):
		return

	var tween = get_tree().create_tween()
	tween.tween_property(node, "modulate:a", target_opacity, 0.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func play_victory_burst():
	if screen_stars:
		screen_stars.emitting = false
		screen_stars.restart()
		screen_stars.emitting = true

func update_zone_status(target_label: Label, zone_name: String, current: int, required: int, is_done: bool):
	if not target_label: return

	var status = "[DONE]" if is_done else "[  ]"
	target_label.text = status + " " + zone_name + " (" + str(current) + "/" + str(required) + ")"

	# Give the text a little nudge color-wise
	target_label.modulate = Color.GREEN if is_done else Color.WHITE

	# Visual "Pop" effect
	apply_bounce_effect(target_label)

	check_overall_victory()

func check_overall_victory():
	# Get all zones in the group "PlacementArea"
	var all_areas = get_tree().get_nodes_in_group("PlacementArea")
	var finished_count = 0

	for node in all_areas:
		# Check if the node has the 'is_complete' variable (our PlacementZone script)
		if "is_complete" in node and node.is_complete:
			finished_count += 1

	if finished_count >= total_zones_required:
		trigger_level_victory()

func apply_bounce_effect(label: Label):
	var tween = get_tree().create_tween()
	# Note: Scale requires the Label's Pivot Offset to be centered for best look
	tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.1)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

func trigger_level_victory():
	play_victory_burst()
	print("KITCHEN ORGANIZED! LEVEL COMPLETE!")
	# Add your "Next Level" menu or big banner logic here
