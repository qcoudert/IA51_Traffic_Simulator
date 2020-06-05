extends Node2D

const ROAD = 0
const TRAFFIC_LIGHT_INIT = 4
const TRAFFIC_LIGHT_RED = 5
const TRAFFIC_LIGHT_ORANGE = 6
const TRAFFIC_LIGHT_GREEN = 7

var traffic_lights = Array()

var crossroads = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init_traffic_lights()
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("ui_cancel"):
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://TitleScreen/TitleScreen.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func init_traffic_lights():
	var cells_to_init = $Props.get_used_cells_by_id(TRAFFIC_LIGHT_INIT)
	for cell in cells_to_init:
		traffic_lights.append(TrafficLight.new(cell, $Props, $Terrain))

func update_crossroads_by_agent(agent):
	for crossroad in crossroads:
		crossroad.new_path(agent)