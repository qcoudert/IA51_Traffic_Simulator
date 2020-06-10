extends Node2D


var agentsComming = []
var startI
var startJ

onready var terrain = get_parent().get_node('Terrain')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func is_in_crossroad(i, j):
	if i == startI or i == startI+1:
		if j == startJ or j == startJ+1:
			return true

func new_path(agent):
	var add = false
	for point in agent.path:
		var pointMap = terrain.world_to_map(point)
		if is_in_crossroad(pointMap.x, pointMap.y):
			add = true
	if add == true:
		add_agent(agent)

func add_agent(agent):
	agentsComming.append(agent)
	
func get_agents_and_dist():
	print("oui")
	print(agentsComming)
	var agentsWithDist = []
	var toDelete = []
	for i in range (0, len(agentsComming)) :
		var dist = 0
		var isIn = false
		for point in agentsComming[i].path:
			var pointMap = terrain.world_to_map(point)
			dist = dist + 1
			if(is_in_crossroad(pointMap.x, pointMap.y)):
				isIn = true
				break
		if isIn == false:
			toDelete.append(i)
		else:
			agentsWithDist.append({dist:agentsComming[i]})
		
	toDelete.invert()
	for i in toDelete:
		agentsComming.remove(i)
		
	return agentsWithDist

