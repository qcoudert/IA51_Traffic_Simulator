extends Object

class_name TrafficLight

const ROAD = 0
const TRAFFIC_LIGHT_INIT = 4
const TRAFFIC_LIGHT_RED = 5
const TRAFFIC_LIGHT_ORANGE = 6
const TRAFFIC_LIGHT_GREEN = 7

const UP = 0
const DOWN = 1
const RIGHT = 2
const LEFT = 3

var position : Vector2
var current_state : int
var orientation : int
var tileMapTL : TileMap
var tileMapRoad : TileMap

func _init(pos : Vector2, tmaptl : TileMap, tmapr : TileMap):
	self.position = pos
	self.tileMapTL = tmaptl
	self.tileMapRoad = tmapr
	self.orientation = self.findTileOrientation()
	self.current_state = TRAFFIC_LIGHT_RED
	self.refreshTile()

func findTileOrientation():
	#Check if the road is heading to the left side
	if(tileMapRoad.get_cell_autotile_coord(position.x, position.y) == Vector2(1,0)):
		return LEFT
	#Check if the road is heading to the right side
	elif(tileMapRoad.get_cell_autotile_coord(position.x, position.y) == Vector2(1,2)):
		return RIGHT
	#Check if the road is heading to the bottom side
	elif(tileMapRoad.get_cell_autotile_coord(position.x, position.y) == Vector2(0,1)):
		return DOWN
	#Check if the road is heading to the top side
	elif(tileMapRoad.get_cell_autotile_coord(position.x, position.y) == Vector2(2,1)):
		return UP
	else:
		return DOWN

func refreshTile():
	match self.orientation:
		UP:
			tileMapTL.set_cell(position.x, position.y, current_state)
		DOWN:
			self.tileMapTL.set_cell(position.x, position.y, current_state, true, true, false)
		LEFT:
			self.tileMapTL.set_cell(position.x, position.y, current_state, false, true, true)
		RIGHT:
			self.tileMapTL.set_cell(position.x, position.y, current_state, true, false, true)
