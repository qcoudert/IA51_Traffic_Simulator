extends Node2D

var directions = ['north', 'south', 'west', 'east']
var bodies_in = []
var agentsComming = {}
var signalisations = {}
var startI
var startJ
onready var terrain = get_parent().get_node('Terrain')

# Called when the node enters the scene tree for the first time.
func _ready():
	init_signalisation()
	agentsComming.north = []
	agentsComming.west = []
	agentsComming.east = []
	agentsComming.south = []
	global_position = terrain.map_to_world(Vector2(startI, startJ), true)
	
	pass # Replace with function body.


func is_in_crossroad(i, j):
	if i == startI or i == startI+1:
		if j == startJ or j == startJ+1:
			return true
	return false

func is_in_crossroad_vector(position : Vector2):
	if position.x == startI or position.x == startI+1:
		if position.y == startJ or position.y == startJ+1:
			return true
	return false

func is_traffic_light_in_crossroad(position : Vector2):
	if(position.x == startI and position.y == startJ-1):
		return "north"
	elif(position.x == startI+2 and position.y == startJ):
		return "east"
	elif(position.x == startI+1 and position.y == startJ+2):
		return "south"
	elif(position.x == startI-1 and position.y == startJ+1):
		return "west"
	else:
		return false

func new_path(agent):
	var add = false
	var comingFrom = ''
	for point in agent.path:
		var pointMap = terrain.world_to_map(point)
		if is_in_crossroad(pointMap.x, pointMap.y):
			add = true
			comingFrom = coming_from(pointMap.x, pointMap.y)
			break;
	if add == true:
		add_agent(agent, comingFrom)
		

func coming_from(i, j):
	if i == startI and j == startJ:
		return 'north'
	elif i == startI + 1 and j == startJ:
		return 'east'
	elif i == startI and j == startJ + 1:
		return 'west'
	elif i == startI + 1 and j == startJ + 1:
		return 'south'


func add_agent(agent, comingFrom):
	agent.add_next_crossroad(self)
	agentsComming[comingFrom].append(agent)

func remove_agent(agent, comingFrom):
	agent.remove_next_crossroad(self)
	agentsComming[comingFrom].erase(agent)

func get_dist_to_crossroad(agent):
	var direction = get_agent_direction(agent)
	if direction == 'north':
		return Vector2(terrain.map_to_world_offset(Vector2(startI, startJ))).distance_to(agent.get_global_transform().get_origin())
	if direction == 'east':
		return Vector2(terrain.map_to_world_offset(Vector2(startI+1, startJ))).distance_to(agent.get_global_transform().get_origin())
	if direction == 'west':
		return Vector2(terrain.map_to_world_offset(Vector2(startI, startJ+1))).distance_to(agent.get_global_transform().get_origin())
	if direction == 'south':
		return Vector2(terrain.map_to_world_offset(Vector2(startI+1, startJ+1))).distance_to(agent.get_global_transform().get_origin())

# This return the arrays of all agents which are coming to the crossroads 
# with the distance they are from. 
# Arrays are put in a dictionnary by the directions they come from.
func get_agents_and_dist():
	var agentsWithDist = {}
	for direction in directions:
		agentsWithDist[direction] = []
		for i in range (0, len(agentsComming[direction])) :
			var dist = get_dist_to_crossroad(agentsComming[direction][i])
			var isIn = false
			for point in agentsComming[direction][i].path:
				var pointMap = terrain.world_to_map(point)
				#dist = dist + 1
				if(is_in_crossroad(pointMap.x, pointMap.y)):
					isIn = true
					break
			if isIn == true:
				agentsWithDist[direction].append({'agent':agentsComming[direction][i], 'dist':dist})
	return agentsWithDist

func get_agent_direction(agent):
	for d in directions:
		if agentsComming[d].has(agent):
			return d
	return false

func store_traffic_lights(traffic_lights):
	for tl in traffic_lights:
		if(is_traffic_light_in_crossroad(tl.position)):
			signalisations[is_traffic_light_in_crossroad(tl.position)] = {'signalisation':'trafic_light', 'object':tl}
	if(!signalisations.empty()):
		_init_traffic_lights_state()

func _init_traffic_lights_state():
	signalisations["north"]['object'].current_state = TrafficLight.TRAFFIC_LIGHT_RED
	signalisations["south"]['object'].current_state = TrafficLight.TRAFFIC_LIGHT_RED
	signalisations["east"]['object'].current_state = TrafficLight.TRAFFIC_LIGHT_GREEN
	signalisations["west"]['object'].current_state = TrafficLight.TRAFFIC_LIGHT_GREEN
	signalisations["north"]['object'].refreshTile()
	signalisations["south"]['object'].refreshTile()
	signalisations["east"]['object'].refreshTile()
	signalisations["west"]['object'].refreshTile()

func init_signalisation():
	for dir in directions:
		if !(signalisations.has(dir)):
			signalisations[dir] = {'signalisation':'none'}

func store_stops(stops):
	for s in stops:
		if(is_traffic_light_in_crossroad(s)):
			signalisations[is_traffic_light_in_crossroad(s)] = {'signalisation':'stop'}
