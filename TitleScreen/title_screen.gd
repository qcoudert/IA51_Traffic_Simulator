extends Control

var scene_path_to_load = ['res://Map/Map.tscn']

# Called when the node enters the scene tree for the first time.
func _ready():
	var button = $Menu/CenterRow/Buttons/PlayButton
	button.grab_focus()
	button.connect("pressed", self, "_on_Button_pressed")


func _on_Button_pressed():
	$FadeIn.show()
	$FadeIn.fade_in()


func _on_FadeIn_fade_finished():
	get_tree().change_scene(scene_path_to_load)
