extends RigidBody2D

enum STATES { IDLE, FOLLOW}
enum DIRECTION {NONE, NORTH, SOUTH, WEST, EAST}

var directions = ['north', 'south', 'west', 'east']
var right_priority_by_dir = {'south':'east', 'east':'north', 'north':'west', 'west':'south'}
var face_priority_by_dir = {'south':'north', 'east':'west', 'north':'south', 'west':'east'}

var _state = null
var path = []
var target_point_world = Vector2()
var target_position = Vector2()

var bodies_near = []

onready var area = get_node("Area2D")

onready var map = get_parent()
onready var terrain = get_parent().get_node('Terrain')

export var RIGHT_DISTANCE = 48
export var DIST_TO_STOP = 32
export var DIST_TO_CAR = 20

export var distanceArrive = 5.0 #distance à partir du quel on considère qu'on doit passé au point astar suivant
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
var dist_min_priority
var stop_timer = 0
const STOP_TIME = 1

var next_crossroads = []

var consecutive_speeds = Array()
signal vehicle_finished_path(vehicle)

func _ready():
	$AnimatedSprite.play("default")
	currentDirection = defaultDirection
	currentMaxSpeed = maxSpeed
	_change_state(STATES.IDLE)
	connect("vehicle_finished_path", get_parent(), "_on_Vehicle_vehicle_finished_path")
	dist_min_priority = RIGHT_DISTANCE / agressivity

func _process(delta):
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
	#self.rotation = defaultDirection.angle_to(currentDirection)
	

func calc_acc(self_velocity, other_velocity, safe_dist, dist):
	if dist == 0:
		return 0
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
	var dist_in_path = 0
	for i in range(path.size()):
		if i < path.size() - 1:
			dist_in_path += path[i].distance_to(path[i+1])
		else :
			dist_in_path += path[i].distance_to(position)
	currentMaxSpeed = min(maxSpeed, calc_acc(currentSpeed, 0, 0, dist_in_path) * delta + currentSpeed)
	
	var speedFollow = maxSpeed
	for body in bodies_near:
		var dist_to_body = get_global_transform().get_origin().distance_to(body.get_global_transform().get_origin())
		speedFollow = min(speedFollow, calc_acc(speedFollow, body.currentSpeed, DIST_TO_CAR, dist_to_body) * delta + currentSpeed)
		#speedFollow = min(speedFollow, maxSpeed * exp(get_global_transform().get_origin().distance_to(body.get_global_transform().get_origin())-22))
	currentMaxSpeed = min(speedFollow, currentMaxSpeed)
	currentMaxSpeed = min(currentMaxSpeed, get_crossroad_max_speed(delta))
	currentMaxSpeed = min(currentMaxSpeed, maxSpeed)
	currentMaxSpeed = max(0, currentMaxSpeed)
	currentSpeed = currentMaxSpeed

func get_crossroad_max_speed(delta):
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
	if can_pass_crossroad(next_crossroad, delta) :
		return maxSpeed
	else :
		return calc_acc(currentSpeed, 0, DIST_TO_STOP, next_crossroad_dist) * delta + currentSpeed

func can_pass_crossroad(crossroad, delta):
	var agent_dir = crossroad.get_agent_direction(self)
	var other_dir = directions
	other_dir.erase(agent_dir) 
	var agents_and_dist = crossroad.get_agents_and_dist()
	if crossroad.bodies_in.has(self): # Si l'agent est engagé, on trace
		stop_timer = 0
		return true
	if !(crossroad.bodies_in.empty()): # Si quelqu'un est engagé on s'arrête
		return false
	if crossroad.is_agent_going_left(self) and !(agents_and_dist[face_priority_by_dir[agent_dir]].empty()):
		return false
	if crossroad.signalisations[agent_dir]['signalisation'] == 'trafic_light':
		if crossroad.signalisations[agent_dir]['object'].current_state == TrafficLight.TRAFFIC_LIGHT_GREEN:
			return true
		else:
			return false
	if crossroad.signalisations[agent_dir]['signalisation'] == 'stop':
		return stop_priority(delta, other_dir, agents_and_dist, crossroad)
	
	return right_priority(agent_dir, agents_and_dist, crossroad)
	#Sinon, on test si on peut s'engager
	

func right_priority(agent_dir, agents_and_dist, crossroad):
	var right_dir = right_priority_by_dir[agent_dir]
	for agent in agents_and_dist[right_dir]:
		if crossroad.signalisations[right_dir]['signalisation'] == 'none' and agent.dist < dist_min_priority :
			return false
	return true

func stop_priority(delta, other_dir, agents_and_dist, crossroad):
	if stop_timer <= STOP_TIME:
		if currentSpeed == 0:
			stop_timer += delta
		return false
	else :
		for dir in other_dir:
			for agent in agents_and_dist[dir]:
				if crossroad.signalisations[dir]['signalisation'] == 'none' and agent.dist < dist_min_priority :
					return false
		return true

#Return the dictionary {agent, dist} of the first agent in the direction given
func first_agent_in_dir(agents_and_dist, dir):
	var first_agent = null
	for agent in agents_and_dist[dir]:
		if first_agent == null:
			first_agent = agent
		elif agent.dist < first_agent.dist:
			first_agent = agent
	return first_agent

func move_to(delta, world_position):
	update_current_speed(delta)
	var desired_velocity:Vector2 = (world_position - position).normalized() * currentSpeed
	var acceleration = Vector2(min(desired_velocity.x, maxAcceleration),min(desired_velocity.y, maxAcceleration))
	var steering = acceleration - self.linear_velocity
	self.linear_velocity += steering
	self.position += self.linear_velocity * get_process_delta_time()
	self.consecutive_speeds.append(currentSpeed)
	if self.linear_velocity.length() != 0:
		#self.rotation = self.linear_velocity.angle()
		self.rotation = defaultDirection.angle_to(linear_velocity)
	
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
			self.emit_signal("vehicle_finished_path", self)
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
