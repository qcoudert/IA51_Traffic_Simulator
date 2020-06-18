extends RigidBody2D

enum STATES { IDLE, FOLLOW}
enum DIRECTION {NONE, NORTH, SOUTH, WEST, EAST}

var right_priority_by_dir = {'south':'east', 'east':'north', 'north':'west', 'west':'south'}

var _state = null
var path = []
var target_point_world = Vector2()
var target_position = Vector2()

var bodies_near = []

onready var area = get_node("Area2D")

onready var map = get_parent()
onready var terrain = get_parent().get_node('Terrain')

export var RIGHT_DISTANCE = 32

export var distanceArrive = 10.0 #distance à partir du quel on considère qu'on doit passé au point astar suivant
export var maxSpeed = 100
export var maxAcceleration = 100
export var angleSpeed = 0.1
export var agressivity = 1
export var T = 0 #human reaction time
export var delta_following = 4 #acceleration exponent
const MAIN_BSAVE =  6

const defaultDirection = Vector2(-1, 0)

var currentDirection
var currentMaxSpeed
var currentSpeed = 0

var next_crossroads = []

signal vehicle_finished_path(vehicle)

func _ready():
	$AnimatedSprite.play("default")
	currentDirection = defaultDirection
	currentMaxSpeed = maxSpeed
	_change_state(STATES.IDLE)
	connect("vehicle_finished_path", get_parent(), "_on_Vehicle_vehicle_finished_path")

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
		var arrived_to_next_point = move_to(delta, target_point_world)
		if arrived_to_next_point:
			path.remove(0)
			if len(path) == 0:
				currentSpeed = 0
				_change_state(STATES.IDLE)
				self.emit_signal("vehicle_finished_path", self)
				return
			elif len(path) == 1:
				currentSpeed = maxSpeed/2
				target_point_world = path[0]
			else :
				currentSpeed = maxSpeed
				target_point_world = get_point_right_driving(path[0], path[1])
		currentDirection = self.linear_velocity.normalized()
	else:
		var arrived_to_next_point = move_to(delta, position)
	self.rotation = defaultDirection.angle_to(currentDirection)
	
	#for crossroad in get_parent().crossroads:
	#	if crossroad.is_in_crossroad(terrain.world_to_map(position).x, terrain.world_to_map(position).y):
	#		var list_agents = crossroad.get_agents_and_dist()

func calc_acc(self_velocity, other_velocity, safe_dist, dist):
	var delta_v = self_velocity - other_velocity
	var s = dist
	var vel = self_velocity
	var s_star_raw = safe_dist + vel * self.T\
			+ (vel * delta_v) / (2 * maxAcceleration)
	var s_star = max(s_star_raw, safe_dist)
	var acc = maxAcceleration * (1 - pow(vel / maxSpeed, delta_following) - pow(s_star,2) / pow(s,2))
	#acc = max(acc, -MAIN_BSAVE)
	return acc

func add_next_crossroad(crossroad):
	next_crossroads.append(crossroad)
	
func remove_next_crossroad(crossroad):
	next_crossroads.erase(crossroad)

func update_current_speed(delta):
	if len(path) == 0:
		currentMaxSpeed = 0
		return
	elif len(path) == 1:
		currentMaxSpeed = maxSpeed/2
	else :
		currentMaxSpeed = maxSpeed
	
	
	var speedFollow = maxSpeed
	for body in bodies_near:
		speedFollow = min(speedFollow, maxSpeed * exp(get_global_transform().get_origin().distance_to(body.get_global_transform().get_origin())-22))
	currentMaxSpeed = min(speedFollow, currentMaxSpeed)
	currentMaxSpeed = min(currentMaxSpeed, get_crossroad_max_speed(delta, currentMaxSpeed))
	currentMaxSpeed = min(currentMaxSpeed, maxSpeed)
	currentMaxSpeed = max(0, currentMaxSpeed)
	currentSpeed = currentMaxSpeed

func get_crossroad_max_speed(delta, currentMaxSpeed):
	if next_crossroads.empty():
		return maxSpeed
	var next_crossroad
	var next_crossroad_dist = 100000
	var dist
	for crossroad in next_crossroads:
		dist = crossroad.get_dist_to_crossroad(self)
		if dist < next_crossroad_dist:
			next_crossroad_dist = dist
			next_crossroad = crossroad
	if can_pass_crossroad(next_crossroad) :
		return maxSpeed
	else :
		return calc_acc(currentMaxSpeed, 0, 15, dist) * delta + currentSpeed

func can_pass_crossroad(crossroad):
	var agent_dir = crossroad.get_agent_direction(self)
	var agents_and_dist = crossroad.get_agents_and_dist()
	if crossroad.bodies_in.has(self): # Si l'agent est engagé, on trace
		return true
	if !(crossroad.bodies_in.empty()): # Si quelqu'un est engagé on s'arrête
		return false
	
	
	return right_priority(agent_dir, agents_and_dist)
	#Sinon, on test si on peut s'engager
	

func right_priority(agent_dir, agents_and_dist):
	var dist_max = RIGHT_DISTANCE / agressivity
	for agent in agents_and_dist[right_priority_by_dir[agent_dir]]:
		if agent.dist < dist_max :
			return false
	return true

func move_to(delta, world_position):
	update_current_speed(delta)
	var desired_velocity:Vector2 = (world_position - position).normalized() * currentSpeed
	var acceleration = Vector2(min(desired_velocity.x, maxAcceleration),min(desired_velocity.y, maxAcceleration))
	var steering = acceleration - self.linear_velocity
	self.linear_velocity += steering
	self.position += self.linear_velocity * get_process_delta_time()
	self.rotation = self.linear_velocity.angle()
	
	return position.distance_to(world_position) < distanceArrive

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
		update_crossroads()
		target_point_world = get_point_right_driving(path[0], path[1])
	_state = new_state

func go_to_position(pos : Vector2):
	target_position = pos
	_change_state(STATES.FOLLOW)

func update_crossroads():
	var nothing
	#map.update_crossroads_by_agent(self)

func get_point_right_driving(point, point_next):
	return Vector2(point.x, point.y) 
	"""
	var point_direction = DIRECTION.NONE
	var point_tile = terrain.world_to_map(point)
	var point_next_tile = terrain.world_to_map(point_next)
	if point_tile.x - 1 == point_next_tile.x:
		point_direction = DIRECTION.WEST
	elif point_tile.x + 1 == point_next_tile.x:
		point_direction = DIRECTION.EAST
	elif point_tile.y - 1 == point_next_tile.y:
		point_direction = DIRECTION.NORTH
	elif point_tile.y + 1 == point_next_tile.y:
		point_direction = DIRECTION.SOUTH
		
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
	"""
