extends Node2D

var directions = ['north', 'south', 'west', 'east']
var agentsComming = {}
var signalisations = {}
var startI
var startJ

onready var terrain = get_parent().get_node('Terrain')

# Called when the node enters the scene tree for the first time.
func _ready():
	agentsComming.north = []
	agentsComming.west = []
	agentsComming.east = []
	agentsComming.south = []
	pass # Replace with function body.

func is_in_crossroad(i, j):
	if i == startI or i == startI+1:
		if j == startJ or j == startJ+1:
			return true

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
	agentsComming[comingFrom].append(agent)

# This return the arrays of all agents which are coming to the crossroads 
# with the distance they are from. 
# Arrays are put in a dictionnary by the directions they come from.
func get_agents_and_dist():
	var agentsWithDist = {}
	for direction in directions:
		agentsWithDist[direction] = []
		var toDelete = []
		for i in range (0, len(agentsComming[direction])) :
			var dist = 0
			var isIn = false
			for point in agentsComming[direction][i].path:
				var pointMap = terrain.world_to_map(point)
				dist = dist + 1
				if(is_in_crossroad(pointMap.x, pointMap.y)):
					isIn = true
					break
			if isIn == false:
				toDelete.append(i)
			else:
				agentsWithDist[direction].append({agentsComming[direction][i] : dist})
		
		toDelete.invert()
		for i in toDelete:
			agentsComming[direction].remove(i)
	return agentsWithDist

