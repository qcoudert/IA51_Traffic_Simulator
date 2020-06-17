extends TileMap

# You can only create an AStar node from code, not from the Scene tab
onready var astar_node = AStar.new()
# The Tilemap node doesn't have clear bounds so we're defining the map's limits here
export(Vector2) var map_size = Vector2(128, 128)

onready var roads = get_used_cells_by_id(0)
onready var _half_cell_size = cell_size / 2


# The path start and end variables use setter methods
# You can find them at the bottom of the script
var path_start_position = Vector2() setget _set_path_start_position
var path_end_position = Vector2() setget _set_path_end_position

var _point_path = []

const BASE_LINE_WIDTH = 3.0
const DRAW_COLOR = Color('#fff')

# Called when the node enters the scene tree for the first time.
func _ready():
	var walkable_cells_list = astar_add_walkable_cells()
	astar_connect_walkable_cells_autotile_coord(walkable_cells_list)
	create_crossroads(walkable_cells_list)

# Create the crossroads
func create_crossroads(point_array):
	var point_used = []
	for i in range(map_size.x):
		point_used.append([])
		for j in range(map_size.y):
			point_used[i].append(0)
	for point in point_array:
		var autotile_coord : Vector2 = get_cell_autotile_coord(point.x, point.y)
		if autotile_coord.x == 3 and autotile_coord.y == 0:
			if point_used[point.x][point.y] == 0:
				point_used[point.x-1][point.y] = 1
				point_used[point.x][point.y-1] = 1
				point_used[point.x-1][point.y-1] = 1
				point_used[point.x][point.y] = 1
				# CREATE CROSSROAD
				get_parent().create_crossroads(point.x-1, point.y-1)
		if autotile_coord.x == 5 and autotile_coord.y == 0:
			if point_used[point.x][point.y] == 0:
				point_used[point.x][point.y] = 1
				point_used[point.x+1][point.y-1] = 1
				point_used[point.x][point.y-1] = 1
				point_used[point.x+1][point.y] = 1
				# CREATE CROSSROAD
				get_parent().create_crossroads(point.x, point.y-1)
		if autotile_coord.x == 3 and autotile_coord.y == 2:
			if point_used[point.x][point.y] == 0:
				point_used[point.x][point.y] = 1
				point_used[point.x-1][point.y] = 1
				point_used[point.x][point.y+1] = 1
				point_used[point.x-1][point.y+1] = 1
				# CREATE CROSSROAD
				get_parent().create_crossroads(point.x-1, point.y)
		if autotile_coord.x == 5 and autotile_coord.y == 2:
			if point_used[point.x][point.y] == 0:
				point_used[point.x][point.y] = 1
				point_used[point.x+1][point.y] = 1
				point_used[point.x][point.y+1] = 1
				point_used[point.x+1][point.y+1] = 1
				# CREATE CROSSROAD
				get_parent().create_crossroads(point.x, point.y)



# Loops through all cells within the map's bounds and
# adds all points of road to the astar_node
func astar_add_walkable_cells():
	var points_array = []
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if point in roads:
				points_array.append(point)
				# The AStar class references points with indices
				# Using a function to calculate the index from a point's coordinates
				# ensures we always get the same index with the same input point
				var point_index = calculate_point_index(point)
				# AStar works for both 2d and 3d, so we have to convert the point
				# coordinates from and to Vector3s
				astar_node.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array

func astar_connect_walkable_cells_all(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce,
		# We connect the current point with it
		var points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)

			if is_outside_map_bounds(point_relative):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			# Note the 3rd argument. It tells the astar_node that we want the
			# connection to be bilateral: from point A to B and B to A
			# If you set this value to false, it becomes a one-way path
			# As we loop through all points we can set it to false
			astar_node.connect_points(point_index, point_relative_index, false)

# Once you added all points to the AStar node, you've got to connect them
func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		
		if ! (Vector2(point.x, point.y - 1) in roads) :
			var point_relative_index = calculate_point_index(Vector2(point.x-1, point.y))
			if is_outside_map_bounds(Vector2(point.x-1, point.y)):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)
		
		if ! (Vector2(point.x, point.y + 1) in roads) :
			var point_relative_index = calculate_point_index(Vector2(point.x+1, point.y))
			if is_outside_map_bounds(Vector2(point.x+1, point.y)):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)
		
		if ! (Vector2(point.x - 1, point.y) in roads) :
			var point_relative_index = calculate_point_index(Vector2(point.x, point.y+1))
			if is_outside_map_bounds(Vector2(point.x, point.y+1)):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)
		
		if ! (Vector2(point.x + 1, point.y) in roads) :
			var point_relative_index = calculate_point_index(Vector2(point.x, point.y-1))
			if is_outside_map_bounds(Vector2(point.x, point.y-1)):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)
		
		if (Vector2(point.x + 1, point.y) in roads) and (Vector2(point.x - 1, point.y) in roads)  and (Vector2(point.x, point.y + 1) in roads)  and (Vector2(point.x, point.y - 1) in roads) :
			if ! (Vector2(point.x - 1, point.y - 1) in roads):
				var point_relative_index = calculate_point_index(Vector2(point.x - 1, point.y))
				if is_outside_map_bounds(Vector2(point.x - 1, point.y)):
					continue
				if not astar_node.has_point(point_relative_index):
					continue
				astar_node.connect_points(point_index, point_relative_index, false)
				
				point_relative_index = calculate_point_index(Vector2(point.x, point.y + 1))
				if is_outside_map_bounds(Vector2(point.x, point.y + 1)):
					continue
				if not astar_node.has_point(point_relative_index):
					continue
				astar_node.connect_points(point_index, point_relative_index, false)

func astar_connect_walkable_cells_autotile_coord(points_array) -> void:
	for point in points_array:
		var autotile_coord : Vector2 = get_cell_autotile_coord(point.x, point.y)
		
		if autotile_coord.x == 0 and autotile_coord.y == 0:
			astar_connect_points(point, Vector2(point.x, point.y + 1))
		
		if autotile_coord.x == 1 and autotile_coord.y == 0:
			astar_connect_points(point, Vector2(point.x - 1, point.y))
			var autotile_coord2 : Vector2 = get_cell_autotile_coord(point.x, point.y + 1)
			if autotile_coord2.x == 5 and autotile_coord2.y == 0:
				astar_connect_points(point, Vector2(point.x, point.y + 1))
		
		if autotile_coord.x == 2 and autotile_coord.y == 0:
			astar_connect_points(point, Vector2(point.x-1, point.y))
		
		if autotile_coord.x == 0 and autotile_coord.y == 1:
			astar_connect_points(point, Vector2(point.x, point.y + 1))
			var autotile_coord2 : Vector2 = get_cell_autotile_coord(point.x + 1, point.y)
			if autotile_coord2.x == 3 and autotile_coord2.y == 0:
				astar_connect_points(point, Vector2(point.x + 1, point.y))
		
		#if autotile_coord.x == 1 and autotile_coord.y == 1:
		#	astar_connect_points(point, Vector2(point.x, point.y - 1))
		
		if autotile_coord.x == 2 and autotile_coord.y == 1:
			astar_connect_points(point, Vector2(point.x, point.y - 1))
			var autotile_coord2 : Vector2 = get_cell_autotile_coord(point.x - 1, point.y)
			if autotile_coord2.x == 5 and autotile_coord2.y == 2:
				astar_connect_points(point, Vector2(point.x - 1, point.y))
		
		if autotile_coord.x == 0 and autotile_coord.y == 2:
			astar_connect_points(point, Vector2(point.x + 1, point.y))
		
		if autotile_coord.x == 1 and autotile_coord.y == 2:
			astar_connect_points(point, Vector2(point.x + 1, point.y))
			var autotile_coord2 : Vector2 = get_cell_autotile_coord(point.x, point.y - 1)
			if autotile_coord2.x == 3 and autotile_coord2.y == 2:
				astar_connect_points(point, Vector2(point.x, point.y - 1))
		
		if autotile_coord.x == 2 and autotile_coord.y == 2:
			astar_connect_points(point, Vector2(point.x, point.y - 1))
		
		if autotile_coord.x == 3 and autotile_coord.y == 0:
			astar_connect_points(point, Vector2(point.x + 1, point.y))
			astar_connect_points(point, Vector2(point.x, point.y - 1))
		
		if autotile_coord.x == 5 and autotile_coord.y == 0:
			astar_connect_points(point, Vector2(point.x + 1, point.y))
			astar_connect_points(point, Vector2(point.x, point.y + 1))
		
		if autotile_coord.x == 3 and autotile_coord.y == 2:
			astar_connect_points(point, Vector2(point.x - 1, point.y))
			astar_connect_points(point, Vector2(point.x, point.y - 1))
		
		if autotile_coord.x == 5 and autotile_coord.y == 2:
			astar_connect_points(point, Vector2(point.x - 1, point.y))
			astar_connect_points(point, Vector2(point.x, point.y + 1))
		

func astar_connect_points(point_a, point_b):
	var point_index = calculate_point_index(point_a)
	var point_relative_index = calculate_point_index(point_b)
	if is_outside_map_bounds(point_b):
		return
	if not astar_node.has_point(point_relative_index):
		return
	astar_node.connect_points(point_index, point_relative_index, false)

func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y


func calculate_point_index(point):
	return point.x + map_size.x * point.y


func _get_path(world_start, world_end):
	self.path_start_position = world_to_map(world_start)
	self.path_end_position = world_to_map(world_end)
	_recalculate_path()
	var path_world = []
	for point in _point_path:
		var point_world = map_to_world(Vector2(point.x, point.y)) + _half_cell_size
		path_world.append(point_world)
	return path_world


func _recalculate_path():
	#clear_previous_path_drawing()
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	# This method gives us an array of points. Note you need the start and end
	# points' indices as input
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)
	# Redraw the lines and circles from the start to the end point
	update()
"""
func clear_previous_path_drawing():
	if not _point_path:
		return
	var point_start = _point_path[0]
	var point_end = _point_path[len(_point_path) - 1]
	set_cell(point_start.x, point_start.y, -1)
	set_cell(point_end.x, point_end.y, -1)
"""
# Setters for the start and end path values.
func _set_path_start_position(value):
	if !(value in roads):
		return
	if is_outside_map_bounds(value):
		return

	#set_cell(path_start_position.x, path_start_position.y, -1)
	#set_cell(value.x, value.y, 1)
	path_start_position = value
	if path_end_position and path_end_position != path_start_position:
		_recalculate_path()


func _set_path_end_position(value):
	if !(value in roads):
		return
	if is_outside_map_bounds(value):
		return

	#set_cell(path_start_position.x, path_start_position.y, -1)
	#set_cell(value.x, value.y, 2)
	path_end_position = value
	if path_start_position != value:
		_recalculate_path()

"""
func _draw():
	if not _point_path:
		return
	var point_start = _point_path[0]
	var point_end = _point_path[len(_point_path) - 1]

	set_cell(point_start.x, point_start.y, 1)
	set_cell(point_end.x, point_end.y, 2)

	var last_point = map_to_world(Vector2(point_start.x, point_start.y)) + _half_cell_size
	for index in range(1, len(_point_path)):
		var current_point = map_to_world(Vector2(_point_path[index].x, _point_path[index].y)) + _half_cell_size
		draw_line(last_point, current_point, DRAW_COLOR, BASE_LINE_WIDTH, true)
		draw_circle(current_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR)
		last_point = current_point
"""
