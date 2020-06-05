extends TileMap

const TRAFFIC_LIGHT_INIT = 4
const TRAFFIC_LIGHT_RED = 5
const TRAFFIC_LIGHT_ORANGE = 6
const TRAFFIC_LIGHT_GREEN = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	var traffic_lights = self.get_used_cells_by_id(TRAFFIC_LIGHT_INIT)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
