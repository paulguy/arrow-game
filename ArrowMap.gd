extends Object
class_name ArrowMap

const BASE_CHANCE : float = 0.01
const CHANCE_MULTIPLIER : float = 1.1

# base preference for an arrow to go forward
const FORWARD_PREFERENCE : float = 3.0
# preference for an arrow to follow along other arrows
const FOLLOW_PREFERENCE : float = 5.0
# bias based on what quadrant an arrow is in to try to get them towards center
const QUADRANT_PREFERENCE : float = 20.0

var DEAD_SNAKE : Snake = Snake.new(Vector2i.MIN, -1, SIDE_TOP)
var size : Vector2i
var snakes : Array[Snake]
var occupied_by : PackedInt32Array

const OPPOSITE_SIDE : Dictionary[Side, Side] = {
	SIDE_TOP: SIDE_BOTTOM,
	SIDE_BOTTOM: SIDE_TOP,
	SIDE_LEFT: SIDE_RIGHT,
	SIDE_RIGHT: SIDE_LEFT
}

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

const UPDATE_POS : Dictionary[Side, Vector2i] = {
	SIDE_TOP: Vector2i.UP,
	SIDE_BOTTOM: Vector2i.DOWN,
	SIDE_LEFT: Vector2i.LEFT,
	SIDE_RIGHT: Vector2i.RIGHT
}

func get_free_direction(pos : Vector2i, towards : Side) -> int:
	var decision : Vector4 = Vector4(1.0, 1.0, 1.0, 1.0)

	# prefer forward
	decision[towards] = FORWARD_PREFERENCE

	if pos.y > size.y / 2:
		decision[SIDE_TOP] = QUADRANT_PREFERENCE
	else:
		decision[SIDE_BOTTOM] = QUADRANT_PREFERENCE

	if pos.x > size.x / 2:
		decision[SIDE_LEFT] = QUADRANT_PREFERENCE
	else:
		decision[SIDE_RIGHT] = QUADRANT_PREFERENCE

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
		decision[SIDE_TOP] = 0.0
	if pos.y < size.y - 1:
		bottom_edge = false
	else:
		decision[SIDE_BOTTOM] = 0.0
	if pos.x > 0:
		left_edge = false
	else:
		decision[SIDE_LEFT] = 0.0
	if pos.x < size.x - 1:
		right_edge = false
	else:
		decision[SIDE_RIGHT] = 0.0

	# try to prioritize following around edges and in to crevaces
	if not top_edge:
		if not left_edge and occupied_by[size.x * (pos.y - 1) + pos.x - 1] >= 0:
			# up left blocked
			decision[SIDE_LEFT] *= FOLLOW_PREFERENCE
		if occupied_by[size.x * (pos.y - 1) + pos.x] >= 0:
			# up blocked
			decision[SIDE_TOP] = 0.0
			# prefer to follow parallel
			if towards == SIDE_LEFT:
				decision[SIDE_LEFT] *= FOLLOW_PREFERENCE
			elif towards == SIDE_RIGHT:
				decision[SIDE_RIGHT] *= FOLLOW_PREFERENCE
		if not right_edge and occupied_by[size.x * (pos.y - 1) + pos.x + 1] >= 0:
			# up right blocked
			decision[SIDE_RIGHT] *= FOLLOW_PREFERENCE

	if not bottom_edge:
		# away from bottom edge
		if not left_edge and occupied_by[size.x * (pos.y + 1) + pos.x - 1] >= 0:
			# down left blocked
			decision[SIDE_LEFT] *= FOLLOW_PREFERENCE
		if occupied_by[size.x * (pos.y + 1) + pos.x] >= 0:
			# down blocked
			decision[SIDE_BOTTOM] = 0.0
			if towards == SIDE_LEFT:
				decision[SIDE_LEFT] *= FOLLOW_PREFERENCE
			elif towards == SIDE_RIGHT:
				decision[SIDE_RIGHT] *= FOLLOW_PREFERENCE
		if not right_edge and occupied_by[size.x * (pos.y + 1) + pos.x + 1] >= 0:
			# down right blocked
			decision[SIDE_RIGHT] *= FOLLOW_PREFERENCE

	if not left_edge:
		# away from left edge
		if not top_edge and occupied_by[size.x * (pos.y - 1) + pos.x - 1] >= 0:
			# up left blocked
			decision[SIDE_TOP] *= FOLLOW_PREFERENCE
		if occupied_by[size.x * pos.y + pos.x - 1] >= 0:
			# left blocked
			decision[SIDE_LEFT] = 0.0
			if towards == SIDE_TOP:
				decision[SIDE_TOP] *= FOLLOW_PREFERENCE
			elif towards == SIDE_BOTTOM:
				decision[SIDE_BOTTOM] *= FOLLOW_PREFERENCE
		if not bottom_edge and occupied_by[size.x * (pos.y + 1) + pos.x - 1] >= 0:
			# down left blocked
			decision[SIDE_BOTTOM] *= FOLLOW_PREFERENCE

	if not right_edge:
		# away from right edge
		if not top_edge and occupied_by[size.x * (pos.y - 1) + pos.x + 1] >= 0:
			# up right blocked
			decision[SIDE_TOP] *= FOLLOW_PREFERENCE
		if occupied_by[size.x * pos.y + pos.x + 1] >= 0:
			# right blocked
			decision[SIDE_RIGHT] = 0.0
			if towards == SIDE_TOP:
				decision[SIDE_TOP] *= FOLLOW_PREFERENCE
			elif towards == SIDE_BOTTOM:
				decision[SIDE_BOTTOM] *= FOLLOW_PREFERENCE
		if not bottom_edge and occupied_by[size.x * (pos.y + 1) + pos.x + 1] >= 0:
			# down right blocked
			decision[SIDE_BOTTOM] *= FOLLOW_PREFERENCE

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

func delete_map(pos : Vector2i,
				_snake_part : int,
				_snake_index : int,
				_arg):
	occupied_by[size.x * pos.y + pos.x] = -1

func delete_tilemap(pos : Vector2i,
					_snake_part : int,
					_snake_index : int,
					tile_map : TileMapLayer):
	tile_map.erase_cell(pos)

func delete_both(pos : Vector2i,
				 _snake_part : int,
				 _snake_index : int,
				 tile_map : TileMapLayer):
	occupied_by[size.x * pos.y + pos.x] = -1
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
		pos += UPDATE_POS[snake.nextTowards[0]]
		action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[0], snake.nextTowards[0])], index, action_arg)
	else:
		for i in len(snake.nextTowards) - 1:
			pos += UPDATE_POS[snake.nextTowards[i]]
			action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[i], snake.nextTowards[i+1])], index, action_arg)
		pos += UPDATE_POS[snake.nextTowards[-1]]
		action.call(pos, NEXT_CELL[Vector2i(snake.nextTowards[-1], snake.nextTowards[-1])], index, action_arg)

func apply_snake_map(index : int):
	do_apply_snake(index, apply_map)

func apply_snake_map_checked(index : int):
	do_apply_snake(index, apply_map_checked)

func apply_snake_tilemap(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, apply_tilemap, tile_map)

func apply_snake_both(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, apply_both, tile_map)

func delete_snake_map(index : int):
	var snake : Snake = snakes[index]
	if snake == DEAD_SNAKE:
		return
	do_apply_snake(index, delete_map)
	snakes[index] = DEAD_SNAKE

func delete_snake_tilemap(index : int, tile_map : TileMapLayer):
	do_apply_snake(index, delete_tilemap, tile_map)

func delete_snake_both(index : int, tile_map : TileMapLayer):
	var snake : Snake = snakes[index]
	if snake == DEAD_SNAKE:
		return
	do_apply_snake(index, delete_both, tile_map)
	snakes[index] = DEAD_SNAKE

func delete_snake_astar(index : int, astar : AStarGrid2D):
	do_apply_snake(index, delete_astar, astar)

func apply_map_full(tile_map : TileMapLayer):
	tile_map.clear()

	for i in len(snakes):
		apply_snake_tilemap(i, tile_map)

	tile_map.notify_runtime_tile_data_update()

func apply_astar(astar : AStarGrid2D):
	for y in size.y:
		for x in size.x:
			if occupied_by[size.x * y + x] < 0:
				astar.set_point_solid(Vector2i(x, y), false)

func do_move_snake(index : int,
				   towards : Side,
				   action : Callable,
				   action_arg = null):
	var snake : Snake = snakes[index]

	# replace head piece
	var pos : Vector2i = snake.pos
	if len(snake.nextTowards) > 0:
		action.call(pos, NEXT_CELL[Vector2i(snake.headTowards, towards)], index, action_arg)

	# update snake position and clear tail
	action.call(snake.move(towards), ArrowCell.EMPTY, -1, action_arg)

	# get new head
	pos = snake.pos
	match towards:
		SIDE_TOP:
			action.call(pos, ArrowCell.ARROW_T, index, action_arg)
		SIDE_BOTTOM:
			action.call(pos, ArrowCell.ARROW_B, index, action_arg)
		SIDE_LEFT:
			action.call(pos, ArrowCell.ARROW_L, index, action_arg)
		SIDE_RIGHT:
			action.call(pos, ArrowCell.ARROW_R, index, action_arg)

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

func move_snake_random(index : int) -> bool:
	var snake : Snake = snakes[index]
	var next : int = get_free_direction(snake.pos, snake.headTowards)
	if next < 0:
		return false
	var towards : Side = next as Side
	do_move_snake(index, towards, apply_map_checked)

	return true

func make_snake(pos : Vector2i,
				length : int,
				towards : Side,
				initial : int):
	var snake : Snake = Snake.new(pos, length, towards)
	snakes.append(snake)
	var index : int = len(snakes) - 1
	do_apply_snake(index, apply_map_checked)
	var update : Vector2i = UPDATE_POS[towards]
	for i in initial:
		if occupied_by[size.x * (snake.pos.y + update.y) + (snake.pos.x + update.x)] >= 0:
			break
		do_move_snake(index, towards, apply_map_checked)
	for i in length - 2:
		if not move_snake_random(index):
			break

	# find if the snake goes off the screen and trim it
	var bodypos : Vector2i = snake.pos
	for i in len(snake.nextTowards):
		bodypos += UPDATE_POS[snake.nextTowards[i]]
		if bodypos.x < 0 or bodypos.x > size.x - 1 or \
		   bodypos.y < 0 or bodypos.y > size.y - 1:
			snake.trim(i + 1)
			break

func _init(size : Vector2i,
			min_length : int,
			max_length : int):
	self.size = size
	occupied_by = PackedInt32Array()
	occupied_by.resize(size.x * size.y)
	occupied_by.fill(-1)
	snakes = []

	var empties : bool = true
	var chance : float = BASE_CHANCE
	while empties:
		empties = false
		for x in size.x - 1:
			if occupied_by[x] < 0:
				empties = true
				if randf() < chance:
					make_snake(Vector2i(x, 0),
							   randi_range(min_length, max_length),
							   SIDE_BOTTOM,
							   randi_range(size.y / 2, size.y - 1))
					chance = BASE_CHANCE
			chance *= CHANCE_MULTIPLIER
			if occupied_by[size.x * (size.y - 1) + x] < 0:
				empties = true
				if randf() < chance:
					make_snake(Vector2i(x, size.y - 1),
							   randi_range(min_length, max_length),
							   SIDE_TOP,
							   randi_range(size.y / 2, size.y - 1))
					chance = BASE_CHANCE
			chance *= CHANCE_MULTIPLIER
		for y in size.x - 1:
			if occupied_by[size.x * y] < 0:
				empties = true
				if randf() < chance:
					make_snake(Vector2i(0, y),
							   randi_range(min_length, max_length),
							   SIDE_RIGHT,
							   randi_range(size.x / 2, size.x - 1))
					chance = BASE_CHANCE
			chance *= CHANCE_MULTIPLIER
			if occupied_by[size.x * y + (size.x - 1)] < 0:
				empties = true
				if randf() < chance:
					make_snake(Vector2i(size.y - 1, y),
							   randi_range(min_length, max_length),
							   SIDE_LEFT,
							   randi_range(size.x / 2, size.x - 1))
					chance = BASE_CHANCE
			chance *= CHANCE_MULTIPLIER

	# final process the snakes
	for i in len(snakes):
		# delete overly short snakes
		if len(snakes[i].nextTowards) < min_length - 1:
			# TODO create flies
			delete_snake_map(i)
		else:
			# snakes are coming in from the edges, so point them back towards the edges
			snakes[i].reverse()
			do_apply_snake(i, apply_map)

func select_snake(pos : Vector2i) -> int:
	if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
		return -1
	return occupied_by[size.x * pos.y + pos.x]

func get_random_free_fly(astar : AStarGrid2D) -> Array[Vector2i]:
	var from : Vector2i = Vector2i(randi_range(astar.region.position.x + 1, astar.region.end.x - 2),
								   randi_range(astar.region.position.y + 1, astar.region.end.y - 2))
	# TODO select from flies
	return []

	var center : Vector2i = astar.region.get_center()
	var to : Vector2i = Vector2i.ZERO
	if from.x > size.y - 1 - from.y:
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

	var path : Array[Vector2i] = astar.get_id_path(from, to)
	if len(path) > 0:
		# TODO delete fly
		return path
	return []
