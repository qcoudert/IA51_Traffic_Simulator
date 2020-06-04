extends Node2D


var crossroads = []
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://TitleScreen/TitleScreen.tscn")

func update_crossroads_by_agent(agent):
	for crossroad in crossroads:
		crossroad.new_path(agent)
