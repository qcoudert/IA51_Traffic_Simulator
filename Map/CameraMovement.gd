extends Camera2D

const zoomChange = Vector2(0.1, 0.1)
const transition_time = 0.20
const maxZoomOffset = 100

var mousePos = Vector2()
var screen_size
var cam_pos = Vector2()
export var movespeed = 500
export var x_limit = 75
export var y_limit = 75

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = (get_viewport_rect().size)
	#Get the screen size to compare with mouse position

func _input(event):
	if (event is InputEventMouseButton) && (event.is_pressed()):
		var diffVec = get_global_mouse_position() - self.get_camera_position()
		if diffVec.length() > maxZoomOffset:
			diffVec = diffVec.normalized() * maxZoomOffset
		
		if event.button_index == BUTTON_WHEEL_UP:
			zoom_in(diffVec + self.get_camera_position())
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom_out(diffVec + self.get_camera_position())
	elif (event.is_action_pressed("ui_accept")):
		transition_camera(Vector2.ONE, Vector2(640,360))

func _process(delta):
	
	#Using mouse position on screen to change camera position on the map
	mousePos = get_viewport().get_mouse_position()
	
	#If the mouse is in the bottom part of the screen
	if mousePos.y > (screen_size.y - y_limit):
		cam_pos.y = ((1) * movespeed)
		
	#If the mouse is in the top part of the screen
	elif mousePos.y < y_limit:
		cam_pos.y = ((-1) * movespeed)
		
	else:
		cam_pos.y = 0
	
	#If the mouse is in the right part of the screen
	if mousePos.x > (screen_size.x - x_limit):
		cam_pos.x = ((1) * movespeed)
		
	#If the mouse is in the left part of the screen
	elif  mousePos.x < x_limit:
		cam_pos.x = ((-1) * movespeed)
		
	else:
		cam_pos.x = 0
	
	self.position += cam_pos * delta

#Function used to move the camera or zoom in the map
func transition_camera(new_zoom, new_position):
	if new_zoom.x > 0.3 && new_zoom.x < 1.5:
		$Tween.interpolate_property(self, "zoom", self.zoom, new_zoom, transition_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.interpolate_property(self, "position", self.position, new_position, transition_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()

func zoom_in(new_offset):
	transition_camera(self.zoom - zoomChange, new_offset)

func zoom_out(new_offset):
	transition_camera(self.zoom + zoomChange, new_offset)
