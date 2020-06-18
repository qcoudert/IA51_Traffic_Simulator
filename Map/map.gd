extends Node2D

const ROAD = 0
const STOP = 1
const TRAFFIC_LIGHT_INIT = 4
const TRAFFIC_LIGHT_RED = 5
const TRAFFIC_LIGHT_ORANGE = 6
const TRAFFIC_LIGHT_GREEN = 7

<<<<<<< HEAD
const MAX_VEHICLES_NUMBER = 50
=======
const MAX_VEHICLES_NUMBER = 20
>>>>>>> 69f22c103d2fb9ead9d61269faa12990cb1cbd25

var traffic_lights = Array()

var Crossroad = preload("res://Crossroad/Crossroad.tscn") # Will load when parsing the script.
var crossroads = []

var terrain_size = Vector2()
var car_spawnable_tiles
var car_despawnable_tiles

var Vehicle = preload("res://Vehicles/Vehicle.tscn")
var vehicles = Array()
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	init_traffic_lights()
	_init_stops()
	terrain_size = _get_terrain_map_size()
	car_spawnable_tiles = _get_car_spawnable_road_tiles()
	car_despawnable_tiles = _get_car_despawnable_road_tiles()
	_init_spawn_vehicles()
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("ui_cancel"):
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://TitleScreen/TitleScreen.tscn")

func init_traffic_lights():
	"""
	Get the traffic lights in the Props tileMap and init them by 
	finding their orientation and attribute a crossroad to each of them
	"""
	var cells_to_init = $Props.get_used_cells_by_id(TRAFFIC_LIGHT_INIT)
	for cell in cells_to_init:
		traffic_lights.append(TrafficLight.new(cell, $Props, $Terrain))
	for cr in crossroads:
		cr.store_traffic_lights(traffic_lights)

func _init_stops():
	var cells_to_init = $Props.get_used_cells_by_id(STOP)
	for cr in crossroads:
		cr.store_stops(cells_to_init)

func update_crossroads_by_agent(agent):
	for crossroad in crossroads:
		crossroad.new_path(agent)

func create_crossroads(i, j):
	var new_crossroad = Crossroad.instance()
	new_crossroad.startI = i
	new_crossroad.startJ = j
	if(get_entry_number(new_crossroad)>2):
		crossroads.append(new_crossroad)
		call_deferred("add_child", new_crossroad)

func get_entry_number(crossroad):
	var entry = 0
	if($Terrain.get_cell(crossroad.startI-1,crossroad.startJ) == 0):
		entry+=1
	if($Terrain.get_cell(crossroad.startI+2,crossroad.startJ) == 0):
		entry+=1
	if($Terrain.get_cell(crossroad.startI,crossroad.startJ-1) == 0):
		entry+=1
	if($Terrain.get_cell(crossroad.startI,crossroad.startJ+2) == 0):
		entry+=1
	return entry

func _on_TrafficLightTimer_timeout():
	for tl in traffic_lights:
		if (tl.current_state == TRAFFIC_LIGHT_GREEN):
			tl.current_state = TRAFFIC_LIGHT_RED
		else:
			tl.current_state = TRAFFIC_LIGHT_GREEN
		tl.refreshTile()

func _get_terrain_map_size():
	var used_cells = $Terrain.get_used_cells()
	var map_size = Vector2(0,0)
	for pos in used_cells:
		if (pos.x > map_size.x):
			map_size.x = pos.x
		if (pos.y > map_size.y):
			map_size.y = pos.y
	return map_size

func _get_car_spawnable_road_tiles():
	"""
	Get the road tiles at the border of the terrain map where the vehicle can spawn
	"""
	var spawnable_tiles = Array()
	for i in range(self.terrain_size.x + 1):
		if($Terrain.get_cell(i, self.terrain_size.y) == ROAD and $Terrain.get_cell(i+1, self.terrain_size.y) != ROAD):
			spawnable_tiles.append(Vector2(i, self.terrain_size.y))
		if($Terrain.get_cell(i, 0) == ROAD and $Terrain.get_cell(i-1, 0) != ROAD):
			spawnable_tiles.append(Vector2(i, 0))
	for i in range(1,self.terrain_size.y):
		if($Terrain.get_cell(self.terrain_size.x, i) == ROAD and $Terrain.get_cell(self.terrain_size.x, i-1) != ROAD):
			spawnable_tiles.append(Vector2(self.terrain_size.x,i))
		if($Terrain.get_cell(0, i) == ROAD and $Terrain.get_cell(0, i+1) != ROAD):
			spawnable_tiles.append(Vector2(0,i))
	return spawnable_tiles

func _get_car_despawnable_road_tiles():
	"""
	Get the road tiles at the border of the terrain map where the vehicle can despawn (tiles that lead out of the map)
	"""
	var despawnable_tiles = Array()
	for i in range(self.terrain_size.x + 1):
		if($Terrain.get_cell(i, self.terrain_size.y) == ROAD and $Terrain.get_cell(i-1, self.terrain_size.y) != ROAD):
			despawnable_tiles.append(Vector2(i, self.terrain_size.y))
		if($Terrain.get_cell(i, 0) == ROAD and $Terrain.get_cell(i+1, 0) != ROAD):
			despawnable_tiles.append(Vector2(i, 0))
	for i in range(1,self.terrain_size.y):
		if($Terrain.get_cell(self.terrain_size.x, i) == ROAD and $Terrain.get_cell(self.terrain_size.x, i+1) != ROAD):
			despawnable_tiles.append(Vector2(self.terrain_size.x, i))
		if($Terrain.get_cell(0, i) == ROAD and $Terrain.get_cell(0, i-1) != ROAD):
			despawnable_tiles.append(Vector2(0, i))
	return despawnable_tiles

func _init_spawn_vehicles():
	_spawn_vehicle()
	if(vehicles.size() < MAX_VEHICLES_NUMBER):
		$SpawnTimer.start()

func _spawn_vehicle():
	var v = Vehicle.instance()
	var pos = self.car_spawnable_tiles[randi() % self.car_spawnable_tiles.size()]
	pos = $Terrain.map_to_world(pos)
	v.position = pos
	self.add_child(v)
	self.vehicles.append(v)
	v.go_to_position($Terrain.map_to_world(self.car_despawnable_tiles[randi() % self.car_spawnable_tiles.size()]))

func _on_Vehicle_vehicle_finished_path(vehicle):
	vehicles.erase(vehicle)
	var total = 0
	for speed in vehicle.consecutive_speeds:
		total += speed
	vehicle.hide()
	vehicle.queue_free()
	_spawn_vehicle()
