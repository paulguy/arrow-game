extends Node2D

const FLY_CHANCE : float = 0.01

@onready var tile_map : TileMapLayer = $"ArrowTileMap"
var fly_res : Resource = preload("res://fly.tscn")

var arrow_map : ArrowMap
var last_snake : int = -1
var active_index : int = -1
var active_snake : Snake = null
var offscreen_snake : Snake = null
var offscreen_overhang : int
var astar : AStarGrid2D

func _ready():
	position = tile_map.tile_set.tile_size

func make_map(size : Vector2i):
	if arrow_map != null:
		arrow_map.free()
	arrow_map = ArrowMap.new(size, 3, 10)
	arrow_map.apply_map_full(tile_map)

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
	tile_map.set_cell(pos, 0, Vector2i(column, tile_map.get_cell_atlas_coords(pos).y))
	for towards in snake.nextTowards:
		pos += ArrowMap.UPDATE_POS[towards]
		tile_map.set_cell(pos, 0, Vector2i(column, tile_map.get_cell_atlas_coords(pos).y))

func _input(e : InputEvent):
	if active_snake == null and \
	   offscreen_snake == null and \
	   e is InputEventMouseButton:
		var mouse_e : InputEventMouseButton = e as InputEventMouseButton
		if mouse_e.pressed and mouse_e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var snake_idx : int = arrow_map.select_snake(get_local_mouse_position() / Vector2(tile_map.tile_set.tile_size))
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
	fly.region = Rect2(tile_map.tile_set.tile_size, (arrow_map.size - Vector2i.ONE) * tile_map.tile_set.tile_size)
	fly.cell_size = tile_map.tile_set.tile_size
	fly.position = Vector2(flypath[0] * tile_map.tile_set.tile_size)
	add_child(fly)

func _physics_process(_delta : float):
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
			else:
				# hit snake
				arrow_map.delete_snake_both(active_index, tile_map)
				# restore original snake
				arrow_map.snakes[active_index] = active_snake
				arrow_map.apply_snake_both(active_index, tile_map)
				active_snake = null
				active_index = -1

	if offscreen_snake != null:
		# snake moving out of the map
		if (offscreen_snake.headTowards == SIDE_LEFT and \
		   (offscreen_snake.pos.x + offscreen_overhang) * tile_map.tile_set.tile_size.x + global_position.x < 0) or \
		   (offscreen_snake.headTowards == SIDE_RIGHT and \
		   (offscreen_snake.pos.x - offscreen_overhang) * tile_map.tile_set.tile_size.x + global_position.x > get_viewport_rect().end.x) or \
		   (offscreen_snake.headTowards == SIDE_TOP and \
		   (offscreen_snake.pos.y + offscreen_overhang) * tile_map.tile_set.tile_size.y + global_position.y < 0) or \
		   (offscreen_snake.headTowards == SIDE_BOTTOM and \
		   (offscreen_snake.pos.y - offscreen_overhang) * tile_map.tile_set.tile_size.y + global_position.y > get_viewport_rect().end.y):
			# went offscreen
			arrow_map.snakes.append(offscreen_snake)
			arrow_map.delete_snake_tilemap(len(arrow_map.snakes) - 1, tile_map)
			arrow_map.snakes.pop_back()
			offscreen_snake.free()
			offscreen_snake = null
		else:
			arrow_map.snakes.append(offscreen_snake)
			arrow_map.move_snake_tilemap(len(arrow_map.snakes) - 1, offscreen_snake.headTowards, tile_map)
			arrow_map.snakes.pop_back()

	tile_map.notify_runtime_tile_data_update()

func get_tile_size() -> Vector2i:
	return tile_map.tile_set.tile_size
