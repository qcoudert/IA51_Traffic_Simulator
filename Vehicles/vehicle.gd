extends RigidBody2D

enum STATES { IDLE, FOLLOW }
enum DIRECTION {NONE, NORTH, SOUTH, WEST, EAST}
var _state = null
var path = []
var target_point_world = Vector2()
var target_position = Vector2()

onready var terrain = get_parent().get_node('Terrain')

export var maxSpeed = 100
export var maxAcceleration = 100
export var angleSpeed = 0.1

const defaultDirection = Vector2(-1, 0)

var currentDirection

func _ready():
	$AnimatedSprite.play("default")
	currentDirection = defaultDirection
	_change_state(STATES.IDLE)

func _process(delta):
	#Ce bloc permet de contrôler l'accélération du véhicule sur les touches de direction
	"""	var vel = Vector2()
	if Input.is_action_pressed("ui_up"):
		vel.y = -maxAcceleration
	if Input.is_action_pressed("ui_down"):
		vel.y = maxAcceleration
	if Input.is_action_pressed("ui_left"):
		vel.x = -maxAcceleration
	if Input.is_action_pressed("ui_right"):
		vel.x = maxAcceleration
		
	self.applied_force = vel"""
	
	#Ce bloc permet de gérer un véhicule en utilisant les touches avant et arrière comme accélération/décélération
	#et les touches gauches et droites pour tourner le véhicule
	if Input.is_action_pressed("ui_up"):
		self.applied_force = maxAcceleration * currentDirection.normalized()
	elif Input.is_action_pressed("ui_down"):
		self.applied_force = -maxAcceleration * currentDirection.normalized()
	else:
		self.applied_force = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		currentDirection = currentDirection.rotated(-angleSpeed)
		self.linear_velocity = self.linear_velocity.rotated(-angleSpeed)
	if Input.is_action_pressed("ui_right"):
		currentDirection = currentDirection.rotated(angleSpeed)
		self.linear_velocity = self.linear_velocity.rotated(angleSpeed)
	# ASTAR
	if _state == STATES.FOLLOW:
		var arrived_to_next_point = move_to(target_point_world)
		if arrived_to_next_point:
			path.remove(0)
			if len(path) == 0:
				_change_state(STATES.IDLE)
				return
			elif len(path) == 1:
				target_point_world = path[0]
			else :
				target_point_world = get_point_right_driving(path[0], path[1])
	
	self.rotation = defaultDirection.angle_to(currentDirection)

func move_to(world_position):
	var MASS = 10.0
	var ARRIVE_DISTANCE = 10.0
	var desired_velocity = (world_position - position).normalized() * maxSpeed
	var steering = desired_velocity - self.linear_velocity
	self.linear_velocity += steering / MASS
	position += self.linear_velocity * get_process_delta_time()
	rotation = self.linear_velocity.angle()
	return position.distance_to(world_position) < ARRIVE_DISTANCE

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				global_position = get_global_mouse_position()
			else:
				target_position = get_global_mouse_position()
			_change_state(STATES.FOLLOW)

func _change_state(new_state):
	if new_state == STATES.FOLLOW:
		path = get_parent().get_node('Terrain')._get_path(position, target_position)
		if not path or len(path) == 1:
			_change_state(STATES.IDLE)
			return
		# The index 0 is the starting cell
		# we don't want the character to move back to it in this example
		target_point_world = get_point_right_driving(path[0], path[1])
	_state = new_state
	
func get_point_right_driving(point, point_next):
	var point_direction = DIRECTION.NONE
	var point_tile = terrain.world_to_map(point)
	var point_next_tile = terrain.world_to_map(point_next)
	print("point : " + str(point) + "point_next : " + str(point_next))
	if point_tile.x - 1 == point_next_tile.x:
		point_direction = DIRECTION.WEST
	elif point_tile.x + 1 == point_next_tile.x:
		point_direction = DIRECTION.EAST
	elif point_tile.y - 1 == point_next_tile.y:
		point_direction = DIRECTION.NORTH
	elif point_tile.y + 1 == point_next_tile.y:
		point_direction = DIRECTION.SOUTH
	print("DIRECTION : " + str(DIRECTION.SOUTH) + " ; actual : " + str(point_direction))
	var autotile_coord = terrain.get_cell_autotile_coord(point_tile.x, point_tile.y)
	if point_direction == DIRECTION.SOUTH:
		if autotile_coord.x == 2 and autotile_coord.y == 1:
			return terrain.map_to_world(Vector2(point_tile.x - 1, point_tile.y))
	if point_direction == DIRECTION.NORTH:
		if autotile_coord.x == 0 and autotile_coord.y == 1:
			return terrain.map_to_world(Vector2(point_tile.x + 1, point_tile.y))
	if point_direction == DIRECTION.WEST:
		if autotile_coord.x == 1 and autotile_coord.y == 2:
			return terrain.map_to_world(Vector2(point_tile.x, point_tile.y - 1))
	if point_direction == DIRECTION.EAST:
		if autotile_coord.x == 1 and autotile_coord.y == 0:
			return terrain.map_to_world(Vector2(point_tile.x, point_tile.y + 1))
	return Vector2(point.x, point.y)
