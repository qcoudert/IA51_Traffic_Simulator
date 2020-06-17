extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect('body_entered', self, 'on_agent_body_entered')
	connect('body_exited', self, 'on_agent_body_exited')

func on_agent_body_entered(body):
	if "Vehicle" in body.get_name():
		get_parent().bodies_in.append(body)

func on_agent_body_exited(body):
	if "Vehicle" in body.get_name():
		get_parent().bodies_in.erase(body)
