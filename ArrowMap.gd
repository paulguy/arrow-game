class_name ArrowMap
extends Object

const UNOCCUPIED_ID : int = -1
const FLY_ID : int = -2

var DEAD_SNAKE : Snake = Snake.new(Vector2i.MIN, -1, SIDE_TOP)
var size : Vector2i
var snakes : Array[Snake]
var occupied_by : PackedInt32Array

const SIDE_NAME : Dictionary[Side, String] = {
	SIDE_TOP: "top",
	SIDE_BOTTOM: "bottom",
	SIDE_LEFT: "left",
	SIDE_RIGHT: "right"
}

# mapped to the tileset rows, -1 has the effect of clearing
enum ArrowCell {
	EMPTY = -1,
	LINE_H,
	LINE_V,
	LINE_BR,
	LINE_BL,
	LINE_TR,
	LINE_TL,
	ARROW_R,
	ARROW_L,
	ARROW_B,
	ARROW_T,
	FLY
}

const NEXT_CELL : Dictionary[Vector2i, ArrowCell] = {
	Vector2i(SIDE_TOP, SIDE_TOP): ArrowCell.LINE_V,
	Vector2i(SIDE_TOP, SIDE_LEFT): ArrowCell.LINE_BL,
	Vector2i(SIDE_TOP, SIDE_RIGHT): ArrowCell.LINE_BR,
	Vector2i(SIDE_BOTTOM, SIDE_BOTTOM): ArrowCell.LINE_V,
	Vector2i(SIDE_BOTTOM, SIDE_LEFT): ArrowCell.LINE_TL,
	Vector2i(SIDE_BOTTOM, SIDE_RIGHT): ArrowCell.LINE_TR,
	Vector2i(SIDE_LEFT, SIDE_TOP): ArrowCell.LINE_TR,
	Vector2i(SIDE_LEFT, SIDE_BOTTOM): ArrowCell.LINE_BR,
	Vector2i(SIDE_LEFT, SIDE_LEFT): ArrowCell.LINE_H,
	Vector2i(SIDE_RIGHT, SIDE_TOP): ArrowCell.LINE_TL,
	Vector2i(SIDE_RIGHT, SIDE_BOTTOM): ArrowCell.LINE_BL,
	Vector2i(SIDE_RIGHT, SIDE_RIGHT): ArrowCell.LINE_H
}

func space_occupied(pos : Vector2i) -> bool:
	return occupied_by[size.x * pos.y + pos.x] >= 0

func get_free_direction(pos : Vector2i,
						towards : Side,
						gen_params : RandGenParams) -> int:
	var decision : Vector4 = Vector4(1.0, 1.0, 1.0, 1.0)

	# prefer forward
	decision[towards] = gen_params.forward_pref

	if pos.y > size.y / 2:
		decision[SIDE_TOP] = gen_params.quadrant_pref
	else:
		decision[SIDE_BOTTOM] = gen_params.quadrant_pref

	if pos.x > size.x / 2:
		decision[SIDE_LEFT] = gen_params.quadrant_pref
	else:
		decision[SIDE_RIGHT] = gen_params.quadrant_pref

	# completely disallow moving in to edges
	# but differentiate a block by edge rather than a block by a solid
	# to avoid following along edges
	var top_edge : bool = true
	var bottom_edge : bool = true
	var left_edge : bool = true
	var right_edge : bool = true
	if pos.y > 0:
		top_edge = false
	else:
		decision[SIDE_LEFT] *= gen_params.along_edge_pref
		decision[SIDE_TOP] = 0.0
		decision[SIDE_RIGHT] *= gen_params.along_edge_pref
	if pos.y < size.y - 1:
		bottom_edge = false
	else:
		decision[SIDE_LEFT] *= gen_params.along_edge_pref
		decision[SIDE_BOTTOM] = 0.0
		decision[SIDE_RIGHT] *= gen_params.along_edge_pref
	if pos.x > 0:
		left_edge = false
	else:
		decision[SIDE_TOP] *= gen_params.along_edge_pref
		decision[SIDE_LEFT] = 0.0
		decision[SIDE_BOTTOM] *= gen_params.along_edge_pref
	if pos.x < size.x - 1:
		right_edge = false
	else:
		decision[SIDE_TOP] *= gen_params.along_edge_pref
		decision[SIDE_RIGHT] = 0.0
		decision[SIDE_BOTTOM] *= gen_params.along_edge_pref

	# try to prioritize following around edges and in to crevaces
	if not top_edge:
		if not left_edge and space_occupied(pos + Vector2i.UP + Vector2i.LEFT):
			# up left blocked
			decision[SIDE_LEFT] *= gen_params.along_snake_pref
		if space_occupied(pos + Vector2i.UP):
			# up blocked
			decision[SIDE_TOP] = 0.0
			# prefer to follow parallel
			if towards == SIDE_LEFT:
				decision[SIDE_LEFT] *= gen_params.along_snake_pref
			elif towards == SIDE_RIGHT:
				decision[SIDE_RIGHT] *= gen_params.along_snake_pref
		if not right_edge and space_occupied(pos + Vector2i.UP + Vector2i.RIGHT):
			# up right blocked
			decision[SIDE_RIGHT] *= gen_params.along_snake_pref

	if not bottom_edge:
		# away from bottom edge
		if not left_edge and space_occupied(pos + Vector2i.DOWN + Vector2i.LEFT):
			# down left blocked
			decision[SIDE_LEFT] *= gen_params.along_snake_pref
		if space_occupied(pos + Vector2i.DOWN):
			# down blocked
			decision[SIDE_BOTTOM] = 0.0
			if towards == SIDE_LEFT:
				decision[SIDE_LEFT] *= gen_params.along_snake_pref
			elif towards == SIDE_RIGHT:
				decision[SIDE_RIGHT] *= gen_params.along_snake_pref
		if not right_edge and space_occupied(pos + Vector2i.DOWN + Vector2i.RIGHT):
			# down right blocked
			decision[SIDE_RIGHT] *= gen_params.along_snake_pref

	if not left_edge:
		# away from left edge
		if not top_edge and space_occupied(pos + Vector2i.UP + Vector2i.LEFT):
			# up left blocked
			decision[SIDE_TOP] *= gen_params.along_snake_pref
		if space_occupied(pos + Vector2i.LEFT):
			# left blocked
			decision[SIDE_LEFT] = 0.0
			if towards == SIDE_TOP:
				decision[SIDE_TOP] *= gen_params.along_snake_pref
			elif towards == SIDE_BOTTOM:
				decision[SIDE_BOTTOM] *= gen_params.along_snake_pref
		if not bottom_edge and space_occupied(pos + Vector2i.DOWN + Vector2i.LEFT):
			# down left blocked
			decision[SIDE_BOTTOM] *= gen_params.along_snake_pref

	if not right_edge:
		# away from right edge
		if not top_edge and space_occupied(pos + Vector2i.UP + Vector2i.RIGHT):
			# up right blocked
			decision[SIDE_TOP] *= gen_params.along_snake_pref
		if space_occupied(pos + Vector2i.RIGHT):
			# right blocked
			decision[SIDE_RIGHT] = 0.0
			if towards == SIDE_TOP:
				decision[SIDE_TOP] *= gen_params.along_snake_pref
			elif towards == SIDE_BOTTOM:
				decision[SIDE_BOTTOM] *= gen_params.along_snake_pref
		if not bottom_edge and space_occupied(pos + Vector2i.DOWN + Vector2i.RIGHT):
			# down right blocked
			decision[SIDE_BOTTOM] *= gen_params.along_snake_pref

	var sum : float = decision[SIDE_TOP] + decision[SIDE_BOTTOM] + decision[SIDE_LEFT] + decision[SIDE_RIGHT]
	if sum == 0.0:
		return -1
	decision[SIDE_RIGHT] = decision[SIDE_TOP] + decision[SIDE_BOTTOM] + decision[SIDE_LEFT]
	decision[SIDE_LEFT] = decision[SIDE_TOP] + decision[SIDE_BOTTOM]
	decision[SIDE_BOTTOM] = decision[SIDE_TOP]
	decision[SIDE_TOP] = 0.0
	var choice : float = randf_range(0, sum)
	if choice < decision[SIDE_BOTTOM]:
		return SIDE_TOP
	elif choice < decision[SIDE_LEFT]:
		return SIDE_BOTTOM
	elif choice < decision[SIDE_RIGHT]:
		return SIDE_LEFT
	return SIDE_RIGHT

func apply_map(pos : Vector2i,
			   _snake_part : int,
			   snake_index : int,
			   _arg):
	occupied_by[size.x * pos.y + pos.x] = snake_index

func apply_map_checked(pos : Vector2i,
					   _snake_part : int,
					   snake_index : int,
					   _arg):
	# do nothing if it's out of range
	if pos.x >= 0 and pos.x < size.x and \
	   pos.y >= 0 and pos.y < size.y:
		occupied_by[size.x * pos.y + pos.x] = snake_index

func apply_tilemap(pos : Vector2i,
				   snake_part : int,
				   _snake_index : int,
				   tile_map : TileMapLayer):
	tile_map.set_cell(pos, 0, Vector2i(0, snake_part))

func apply_both(pos : Vector2i,
				snake_part : int,
				snake_index : int,
				tile_map : TileMapLayer):
	occupied_by[size.x * pos.y + pos.x] = snake_index
	tile_map.set_cell(pos, 0, Vector2i(0, snake_part))

func apply_many(pos : Vector2i,
				snake_part : int,
				snake_index : int,
				tile_maps : Array[TileMapLayer]):
	occupied_by[size.x * pos.y + pos.x] = snake_index
	for tile_map in tile_maps:
		tile_map.set_cell(pos, 0, Vector2i(0, snake_part))

func apply_fly(pos : Vector2i,
			   _snake_part : int,
			   _snake_index : int,
			   _arg):
	occupied_by[size.x * pos.y + pos.x] = FLY_ID

func delete_map(pos : Vector2i,
				_snake_part : int,
				_snake_index : int,
				_arg):
	occupied_by[size.x * pos.y + pos.x] = UNOCCUPIED_ID

func delete_map_checked(pos : Vector2i,
						_snake_part : int,
						_snake_index : int,
						_arg):
	# do nothing if it's out of range
	if pos.x >= 0 and pos.x < size.x and \
	   pos.y >= 0 and pos.y < size.y:
		occupied_by[size.x * pos.y + pos.x] = UNOCCUPIED_ID

func delete_tilemap(pos : Vector2i,
					_snake_part : int,
					_snake_index : int,
					tile_map : TileMapLayer):
	tile_map.erase_cell(pos)

func delete_both(pos : Vector2i,
				 _snake_part : int,
				 _snake_index : int,
				 tile_map : TileMapLayer):
	occupied_by[size.x * pos.y + pos.x] = UNOCCUPIED_ID
	tile_map.erase_cell(pos)

func delete_astar(pos : Vector2i,
				 _snake_part : int,
				 _snake_index : int,
				 astar : AStarGrid2D):
	astar.set_point_solid(pos, false)

func do_apply_snake(index : int,
					action : Callable,
					action_arg = null):
	var snake : Snake = snakes[index]
	var pos : Vector2i = snake.pos

	match snake.headTowards:
		SIDE_TOP:
			action.call(pos, ArrowCell.ARROW_T, index, action_arg)
		SIDE_BOTTOM:
			action.call(pos, ArrowCell.ARROW_B, index, action_arg)
		SIDE_LEFT:
			action.call(pos, ArrowCell.ARROW_L, index, action_arg)
		SIDE_RIGHT:
			action.call(pos, ArrowCell.ARROW_R, index, action_arg)

	if len(snake.nextTowards) == 0:
		pass
	elif len(snake.nextTowards) == 1:
		pos += Snake.UPDATE_POS[snake.nextTowards[0]]
		action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[0], snake.nextTowards[0])], index, action_arg)
	else:
		for i in len(snake.nextTowards) - 1:
			pos += Snake.UPDATE_POS[snake.nextTowards[i]]
			action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[i], snake.nextTowards[i+1])], index, action_arg)
		pos += Snake.UPDATE_POS[snake.nextTowards[-1]]
		action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[-1], snake.nextTowards[-1])], index, action_arg)

func apply_snake_map(index : int):
	do_apply_snake(index, apply_map)

func apply_snake_map_checked(index : int):
	do_apply_snake(index, apply_map_checked)

func apply_snake_tilemap(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, apply_tilemap, tile_map)

func apply_snake_both(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, apply_both, tile_map)

func apply_snake_many(index : int, tile_maps : Array[TileMapLayer]):
	do_apply_snake(index, apply_many, tile_maps)

func delete_snake_map(index : int):
	var snake : Snake = snakes[index]
	if snake == DEAD_SNAKE:
		return
	do_apply_snake(index, delete_map)
	snakes[index].free()
	snakes[index] = DEAD_SNAKE

func delete_snake_fly(index : int):
	var snake : Snake = snakes[index]
	if snake == DEAD_SNAKE:
		return
	do_apply_snake(index, apply_fly)
	snakes[index].free()
	snakes[index] = DEAD_SNAKE

func delete_snake_tilemap(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, delete_tilemap, tile_map)

func delete_snake_both(index : int, tile_map : TileMapLayer):
	var snake : Snake = snakes[index]
	if snake == DEAD_SNAKE:
		return
	do_apply_snake(index, delete_both, tile_map)
	snakes[index].free()
	snakes[index] = DEAD_SNAKE

func delete_snake_astar(index : int, astar : AStarGrid2D):
	do_apply_snake(index, delete_astar, astar)

func apply_astar(astar : AStarGrid2D):
	var pos : Vector2i

	for y in size.y:
		for x in size.x:
			pos = Vector2i(x, y)
			if not space_occupied(pos):
				astar.set_point_solid(pos, false)

func place_head(pos : Vector2i,
				index : int,
				towards : Side,
				action : Callable,
				action_arg):
	match towards:
		SIDE_TOP:
			action.call(pos, ArrowCell.ARROW_T, index, action_arg)
		SIDE_BOTTOM:
			action.call(pos, ArrowCell.ARROW_B, index, action_arg)
		SIDE_LEFT:
			action.call(pos, ArrowCell.ARROW_L, index, action_arg)
		SIDE_RIGHT:
			action.call(pos, ArrowCell.ARROW_R, index, action_arg)

func do_move_snake(index : int,
				   towards : Side,
				   action : Callable,
				   action_arg = null,
				   grow = false):
	var snake : Snake = snakes[index]
	var pos : Vector2i = snake.pos

	if len(snake.nextTowards) == 0:
		# change head direction for single segment snakes
		# this is so if the snake is growing, it'll have the
		# correct direction
		snake.headTowards = towards

	# replace head piece with body piece
	if len(snake.nextTowards) > 0 or grow:
		action.call(pos, NEXT_CELL[Vector2i(snake.headTowards, towards)], index, action_arg)

	# update snake position and clear tail
	var tailpos : Vector2i = snake.move(towards, grow)
	if not grow:
		action.call(tailpos, ArrowCell.EMPTY, UNOCCUPIED_ID, action_arg)

	# get new head
	place_head(snake.pos, index, towards, action, action_arg)

func move_snake_map(index : int, towards : Side):
	do_move_snake(index, towards, apply_map)

func move_snake_map_checked(index : int, towards : Side):
	do_move_snake(index, towards, apply_map_checked)

func move_snake_tilemap(index : int,
						towards : Side,
						tile_map : TileMapLayer):
	do_move_snake(index, towards, apply_tilemap, tile_map)

func move_snake_both(index : int,
					 towards : Side,
					 tile_map : TileMapLayer):
	do_move_snake(index, towards, apply_both, tile_map)

func grow_snake_both(index : int,
					 towards : Side,
					 tile_map : TileMapLayer):
	do_move_snake(index, towards, apply_both, tile_map, true)

func do_shrink_snake(index : int,
					towards : Side,
					action : Callable,
					action_arg = null):
	# only works correctly if the snake is moved back into itself
	var snake : Snake = snakes[index]

	# update snake position and clear head
	action.call(snake.move(towards), ArrowCell.EMPTY, UNOCCUPIED_ID, action_arg)

	# replace head
	place_head(snake.pos, index, snake.headTowards, action, action_arg)

func shrink_snake_both(index : int,
					   towards : Side,
					   tile_map : TileMapLayer):
	do_shrink_snake(index, towards, apply_both, tile_map)

func do_reverse_snake(index : int,
					  action : Callable,
					  action_arg = null):
	var snake : Snake = snakes[index]
	var pos : Vector2i = snake.pos
	snake.reverse()
	place_head(snake.pos, index, snake.headTowards, action, action_arg)
	if len(snake.nextTowards) > 0:
		if len(snake.nextTowards) == 1:
			action.call(pos, NEXT_CELL[Vector2i(Snake.OPPOSITE_SIDE[snake.headTowards], snake.nextTowards[-1])], index, action_arg)
		else:
			action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[-2], snake.nextTowards[-1])], index, action_arg)

func reverse_snake_both(index : int,
						tile_map : TileMapLayer):
	do_reverse_snake(index, apply_both, tile_map)

func slice_map_snake(snake : Snake,
					 index : int,
					 head : int,
					 tail : int,
					 tile_maps : Array[TileMapLayer],
					 used_index : bool) -> bool:
	# create the new snake slice
	var newsnake : Snake = snake.slice(head, tail)

	if not used_index:
		# reuse the original snake index
		snakes[index] = newsnake
		# lay the new snake on to the maps
		if len(tile_maps) == 0:
			apply_snake_map(index)
		else:
			apply_snake_many(index, tile_maps)
		return true
	else:
		snakes.append(newsnake)
		if len(tile_maps) == 0:
			apply_snake_map(len(snakes) - 1)
		else:
			apply_snake_many(len(snakes) - 1, tile_maps)

	return false

func trim_snake_to_fit(index : int, tile_maps : Array[TileMapLayer] = []) -> bool:
	var trimmed : bool = false
	var fully_out : bool = true

	var snake : Snake = snakes[index]
	# find if the snake is off the screen and split it
	# head is position 0
	var first : int = 0
	var used_index : bool = false
	var bodypos : Vector2i = snake.pos
	if bodypos.x < 0 or bodypos.x >= size.x or \
	   bodypos.y < 0 or bodypos.y >= size.y:
		# if already out of bounds, the head is not the first piece
		first = -1

	for i in len(snake.nextTowards):
		bodypos += Snake.UPDATE_POS[snake.nextTowards[i]]
		if bodypos.x < 0 or bodypos.x >= size.x or \
		   bodypos.y < 0 or bodypos.y >= size.y:
			# out of bounds
			if first != -1:
				# just transitioned out of bounds, make the slice
				# i counts tail pieces so it's 1 less than the snake position
				# but this i is 1 out of bounds so it's 1 more than it should be
				# so it cancels out
				used_index = slice_map_snake(snake, index, first, i, tile_maps, used_index)
				trimmed = true
				first = -1
		elif i == len(snake.nextTowards) - 1:
			# end of snake
			if first != -1:
				# i counts tail pieces so it's 1 less than it should be
				used_index = slice_map_snake(snake, index, first, i + 1, tile_maps, used_index)
				trimmed = true
				first = -1
		else:
			fully_out = false
			# in bounds
			if i == len(snake.nextTowards) - 1:
				# snake poking into bounds
				# same note about i as above
				used_index = slice_map_snake(snake, index, first, i + 1, tile_maps, used_index)
				trimmed = true
			elif first == -1:
				# just transitioned in bounds, so mark the first i
				# 0 is the head and i counts body pieces
				first = i + 1

	if fully_out:
		snakes[index].free()
		snakes[index] = DEAD_SNAKE

	if trimmed:
		snake.free()

	return trimmed

func add_snake(snake : Snake) -> int:
	snakes.append(snake)
	return len(snakes) - 1

func rand_snake(pos : Vector2i,
				length : int,
				towards : Side,
				initial : int,
				gen_params : RandGenParams):
	var snake : Snake = Snake.new(pos, length, towards)
	var index : int = add_snake(snake)
	do_apply_snake(index, apply_map_checked)
	for i in initial:
		if space_occupied(snake.pos + Snake.UPDATE_POS[towards]):
			if i == 0:
				# if a snake turns immediately, it can permanently block escape
				snake.trim(1)
				return
			break
		do_move_snake(index, towards, apply_map_checked)
	for i in length - 2:
		var next : int = get_free_direction(snake.pos, snake.headTowards, gen_params)
		if next < 0:
			break
		do_move_snake(index, next as Side, apply_map_checked)

	trim_snake_to_fit(index)

func generate_random(gen_params : RandGenParams) -> int:
	var active_snakes : int = 0

	# just access occupied_by directly here because flies aren't placed yet
	var empties : bool = true
	var chance : float = gen_params.base_chance
	while empties:
		empties = false
		for x in size.x - 1:
			if occupied_by[x] < 0:
				empties = true
				if randf() < chance:
					rand_snake(Vector2i(x, 0),
							   randi_range(1, gen_params.max_length),
							   SIDE_BOTTOM,
							   randi_range(size.y / 2, size.y - 1),
							   gen_params)
					active_snakes += 1
					chance = gen_params.base_chance
			chance *= gen_params.chance_mult
			if occupied_by[size.x * (size.y - 1) + x] < 0:
				empties = true
				if randf() < chance:
					rand_snake(Vector2i(x, size.y - 1),
							   randi_range(1, gen_params.max_length),
							   SIDE_TOP,
							   randi_range(size.y / 2, size.y - 1),
							   gen_params)
					active_snakes += 1
					chance = gen_params.base_chance
			chance *= gen_params.chance_mult
		for y in size.y - 1:
			if occupied_by[size.x * y] < 0:
				empties = true
				if randf() < chance:
					rand_snake(Vector2i(0, y),
							   randi_range(1, gen_params.max_length),
							   SIDE_RIGHT,
							   randi_range(size.x / 2, size.x - 1),
							   gen_params)
					active_snakes += 1
					chance = gen_params.base_chance
			chance *= gen_params.chance_mult
			if occupied_by[size.x * y + (size.x - 1)] < 0:
				empties = true
				if randf() < chance:
					rand_snake(Vector2i(size.x - 1, y),
							   randi_range(1, gen_params.max_length),
							   SIDE_LEFT,
							   randi_range(size.x / 2, size.x - 1),
							   gen_params)
					active_snakes += 1
					chance = gen_params.base_chance
			chance *= gen_params.chance_mult

	for i in len(snakes):
		# delete overly short snakes
		if len(snakes[i].nextTowards) < gen_params.min_length - 1:
			delete_snake_fly(i)
			active_snakes -= 1
			pass
		else:
			# snakes are coming in from the edges, so point them back towards the edges
			snakes[i].reverse()

	for y in size.y - 1:
		for x in size.x - 1:
			if occupied_by[size.x * y + x] < 0:
				occupied_by[size.x * y + x] = FLY_ID

	return active_snakes

func clear():
	occupied_by = PackedInt32Array()
	occupied_by.resize(size.x * size.y)
	occupied_by.fill(UNOCCUPIED_ID)
	snakes = []

func _init(size : Vector2i):
	self.size = size
	clear()

func resize_puzzle(new_bounds : Rect2i, tile_maps : Array[TileMapLayer]):
	# just clear any tilemaps entirely
	for tile_map in tile_maps:
		tile_map.clear()

	occupied_by = PackedInt32Array()
	occupied_by.resize(new_bounds.size.x * new_bounds.size.y)
	occupied_by.fill(UNOCCUPIED_ID)
	size = new_bounds.size

	# trim snakes to new size
	for i in len(snakes):
		if snakes[i] == DEAD_SNAKE:
			continue
		# reorigin the snakes
		snakes[i].pos -= new_bounds.position
		if not trim_snake_to_fit(i, tile_maps):
			# if they weren't trimmed, just place them on the new tilemap
			apply_snake_many(i, tile_maps)

func apply_tilemap_full(tile_map : TileMapLayer):
	tile_map.clear()

	for i in len(snakes):
		apply_snake_tilemap(i, tile_map)
	for y in size.y:
		for x in size.x:
			if occupied_by[size.x * y + x] == FLY_ID:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, ArrowCell.FLY))

	tile_map.notify_runtime_tile_data_update()

func select_snake(pos : Vector2i) -> int:
	if pos.x < 0 or pos.y < 0 or \
	   pos.x >= size.x or pos.y >= size.y or \
	   not space_occupied(pos):
		return -1
	return occupied_by[size.x * pos.y + pos.x]

func get_snakes() -> Array[Snake]:
	var newsnakes : Array[Snake] = []
	for snake in snakes:
		if snake != DEAD_SNAKE:
			# deep copy the whole array
			newsnakes.append(snake.copy())

	return newsnakes

func set_snakes(newsnakes : Array[Snake], tile_map : TileMapLayer = null):
	clear()
	snakes = newsnakes
	for index in len(snakes):
		if tile_map == null:
			apply_snake_map(index)
		else:
			apply_snake_both(index, tile_map)
