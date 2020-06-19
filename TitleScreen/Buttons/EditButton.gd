extends Button

const scenes = ['res://Map/Map.tscn', 'res://Map/map_intersection_scene.tscn', 'res://Map/Map2.tscn', 'res://Map/Map3.tscn']
const scenes_names = ['Classique', 'Crossroad feux', 'Stop', 'Interblocage']
var current_next = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func switch_to_next_scene():
	get_tree().get_root().get_child(0).scene_path_to_load = scenes[current_next]
	$Label.text = 'Changer de carte ( ' + scenes_names[current_next] + ' )' 
	if(current_next+1 < scenes.size()):
		current_next += 1
	else:
		current_next = 0


func _on_Play_pressed():
	switch_to_next_scene()
