extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var coming_from = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	connect('body_entered', self, 'on_agent_body_entered')
	connect('body_exited', self, 'on_agent_body_exited')

func on_agent_body_entered(body):
	if "Vehicle" in body.get_name():
		get_parent().add_agent(body, coming_from)

func on_agent_body_exited(body):
	if "Vehicle" in body.get_name():
		get_parent().remove_agent(body, coming_from)
