extends Node2D

const FLY_CHANCE : float = 0.01
const SLOW_RATIO : float = 1.1

@onready var tile_map : TileMapLayer = $"SubViewport/ArrowTileMap"
@onready var coll_tile_map : TileMapLayer = $"FliesViewport/Arrow Collision TileMap"
@onready var tile_map_camera : Camera2D = $"SubViewport/Camera2D"
@onready var flies_camera : Camera2D = $"FliesViewport/Camera2D"
var fly_res : Resource = preload("res://fly.tscn")

var arrow_map : ArrowMap
var last_snake : int = -1
var active_index : int = -1
var active_snake : Snake = null
var offscreen_snake : Snake = null
var offscreen_overhang : int
var astar : AStarGrid2D
var tile_size : Vector2i
var physics_delta : float = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
var last_delta : float = 0.0

func _ready():
	tile_size = tile_map.tile_set.tile_size
	$SubViewport.size = get_viewport_rect().size
	$FliesViewport.size = get_viewport_rect().size

func make_map(size : Vector2i):
	tile_map.position = (get_viewport_rect().size - Vector2(size * tile_size)) / 2.0
	coll_tile_map.position = (get_viewport_rect().size - Vector2(size * tile_size)) / 2.0

	if arrow_map != null:
		arrow_map.free()
	arrow_map = ArrowMap.new(size, 3, 10)
	arrow_map.apply_map_full(tile_map)
	arrow_map.apply_map_full(coll_tile_map)

	astar = AStarGrid2D.new()
	#astar.cell_size = Vector2.ONE
	# region's size is non-inclusive of the right and bottom edges
	astar.region = Rect2i(-Vector2i.ONE, size + Vector2i(2, 2))
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	astar.fill_solid_region(astar.region, false)
	astar.fill_solid_region(Rect2i(Vector2.ZERO, size))

	arrow_map.apply_astar(astar)
	#astar.update()

func set_snake_column(snake : Snake, column : int):
	var pos : Vector2i = snake.pos
	var y : int = tile_map.get_cell_atlas_coords(pos).y
	tile_map.set_cell(pos, 0, Vector2i(column, y))
	coll_tile_map.set_cell(pos, 0, Vector2i(column, y))
	for towards in snake.nextTowards:
		pos += ArrowMap.UPDATE_POS[towards]
		y = tile_map.get_cell_atlas_coords(pos).y
		tile_map.set_cell(pos, 0, Vector2i(column, y))
		coll_tile_map.set_cell(pos, 0, Vector2i(column, y))

func click_snake(pos : Vector2):
	if active_snake == null and \
	   offscreen_snake == null:
		var snake_idx : int = arrow_map.select_snake(pos / Vector2(tile_size))
		if snake_idx >= 0:
			if snake_idx == last_snake:
				# starting
				active_index = snake_idx
				active_snake = arrow_map.snakes[active_index].copy()
				set_snake_column(active_snake, 0)
				last_snake = -1
			else:
				if last_snake >= 0:
					set_snake_column(arrow_map.snakes[last_snake], 0)
				set_snake_column(arrow_map.snakes[snake_idx], 1)
				last_snake = snake_idx

func get_fly_path(from : Vector2i) -> Array[Vector2i]:
	var center : Vector2i = astar.region.get_center()
	var to : Vector2i = Vector2i.ZERO
	if from.x > arrow_map.size.y - 1 - from.y:
		if from.x > from.y:
			# right
			to = Vector2i(astar.region.end.x - 1, center.y)
		else:
			# bottom
			to = Vector2i(center.x, astar.region.end.y - 1)
	else:
		if from.x > from.y:
			# top
			to = Vector2i(center.x, astar.region.position.y)
		else:
			# left
			to = Vector2i(astar.region.position.x, center.y)

	return astar.get_id_path(from, to)

func clear_fly(from : Vector2i):
	# mark space empty
	arrow_map.occupied_by[arrow_map.size.x * from.y + from.x] = -1
	tile_map.erase_cell(from)
	coll_tile_map.erase_cell(from)

func pop_random_free_fly(astar : AStarGrid2D) -> Array[Vector2i]:
	# select within borders, astar grid is from -1,-1 to size+2, size+2
	var from : Vector2i = Vector2i(randi_range(0, astar.region.end.x - 2),
								   randi_range(0, astar.region.end.y - 2))
	if tile_map.get_cell_atlas_coords(from).y != ArrowMap.ArrowCell.FLY:
		# if not a fly, return
		return []

	var path : Array[Vector2i] = get_fly_path(from)
	if len(path) > 0:
		clear_fly(from)
		return path
	return []

func make_fly(flypath : Array[Vector2i]):
	var fly : RigidBody2D = fly_res.instantiate()
	fly.path = flypath
	fly.region = Rect2(tile_size, (arrow_map.size - Vector2i.ONE) * tile_size)
	fly.cell_size = tile_size
	fly.position = coll_tile_map.position + Vector2(flypath[0] * tile_size)
	$FliesViewport.add_child(fly)

func _process(delta : float):
	# keep track of real frame time
	last_delta = delta

func _physics_process(_delta : float):
	if last_delta < physics_delta * SLOW_RATIO:
		# only try to make flies if it's not running slow
		for i in arrow_map.size.x * arrow_map.size.y * FLY_CHANCE:
			var flypath : Array[Vector2i] = pop_random_free_fly(astar)
			if len(flypath) > 0 and flypath[0].x >= 0 and flypath[0].y >= 0:
				make_fly(flypath)

	if active_snake != null:
		var snake = arrow_map.snakes[active_index]
		var pos : Vector2i = snake.pos
		if (active_snake.headTowards == SIDE_LEFT and pos.x == 0) or \
		   (active_snake.headTowards == SIDE_RIGHT and pos.x == arrow_map.size.x - 1) or \
		   (active_snake.headTowards == SIDE_TOP and pos.y == 0) or \
		   (active_snake.headTowards == SIDE_BOTTOM and pos.y == arrow_map.size.y - 1):
			# reached edge

			# copy the snake
			offscreen_snake = arrow_map.snakes[active_index].copy()
			offscreen_overhang = len(offscreen_snake.nextTowards) + 1
			# clear the snake from the map only
			arrow_map.delete_snake_map(active_index)
			# need to append to the arrow_map's array of snakes first
			arrow_map.snakes.append(active_snake)
			# delete the snake in its original position from the AStarGrid2D
			arrow_map.delete_snake_astar(len(arrow_map.snakes) - 1, astar)
			arrow_map.snakes.pop_back()

			active_snake.free()
			active_snake = null
		else:
			pos += ArrowMap.UPDATE_POS[active_snake.headTowards]
			# check for flies and immediately release them
			if tile_map.get_cell_atlas_coords(pos).y == ArrowMap.ArrowCell.FLY:
				clear_fly(pos)
				var path : Array[Vector2i] = get_fly_path(pos)
				if len(path) == 0:
					path = [pos]
				make_fly(path)

			# check if the space is empty or will be empty when the snake moves
			if arrow_map.occupied_by[arrow_map.size.x * pos.y + pos.x] < 0 or \
			   pos == arrow_map.snakes[active_index].get_tail_pos():
				# moving
				arrow_map.move_snake_both(active_index, active_snake.headTowards, tile_map)
				arrow_map.apply_snake_both(active_index, coll_tile_map)
			else:
				# hit snake
				arrow_map.delete_snake_both(active_index, tile_map)
				arrow_map.delete_snake_both(active_index, coll_tile_map)
				# restore original snake
				arrow_map.snakes[active_index] = active_snake
				arrow_map.apply_snake_both(active_index, tile_map)
				arrow_map.apply_snake_both(active_index, coll_tile_map)
				active_snake = null
				active_index = -1

	if offscreen_snake != null:
		# snake moving out of the map
		if (offscreen_snake.headTowards == SIDE_LEFT and \
		   (offscreen_snake.pos.x + offscreen_overhang) * tile_size.x + tile_map.position.x - tile_map_camera.position.x < 0) or \
		   (offscreen_snake.headTowards == SIDE_RIGHT and \
		   (offscreen_snake.pos.x - offscreen_overhang) * tile_size.x + tile_map.position.x - tile_map_camera.position.x > get_viewport_rect().end.x) or \
		   (offscreen_snake.headTowards == SIDE_TOP and \
		   (offscreen_snake.pos.y + offscreen_overhang) * tile_size.y + tile_map.position.y - tile_map_camera.position.y < 0) or \
		   (offscreen_snake.headTowards == SIDE_BOTTOM and \
		   (offscreen_snake.pos.y - offscreen_overhang) * tile_size.y + tile_map.position.y - tile_map_camera.position.y > get_viewport_rect().end.y):
			# went offscreen
			arrow_map.snakes.append(offscreen_snake)
			arrow_map.delete_snake_tilemap(len(arrow_map.snakes) - 1, tile_map)
			arrow_map.delete_snake_tilemap(len(arrow_map.snakes) - 1, coll_tile_map)
			arrow_map.snakes.pop_back()
			offscreen_snake.free()
			offscreen_snake = null
		else:
			arrow_map.snakes.append(offscreen_snake)
			arrow_map.move_snake_tilemap(len(arrow_map.snakes) - 1, offscreen_snake.headTowards, tile_map)
			arrow_map.apply_snake_tilemap(len(arrow_map.snakes) - 1, coll_tile_map)
			arrow_map.snakes.pop_back()

func get_viewport_texture() -> ViewportTexture:
	return $SubViewport.get_texture()

func get_flies_viewport_texture() -> ViewportTexture:
	return $FliesViewport.get_texture()

func set_view(pos : Vector2):
	tile_map_camera.position = -pos
	flies_camera.position = -pos
