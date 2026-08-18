class_name Snake
extends Object

const MAX_LENGTH : int = UINT16_MAX

var pos : Vector2i
var nextTowards : Array[Side]
var headTowards : Side

const UPDATE_POS : Dictionary[Side, Vector2i] = {
	SIDE_TOP: Vector2i.UP,
	SIDE_BOTTOM: Vector2i.DOWN,
	SIDE_LEFT: Vector2i.LEFT,
	SIDE_RIGHT: Vector2i.RIGHT
}

const OPPOSITE_SIDE : Dictionary[Side, Side] = {
	SIDE_TOP: SIDE_BOTTOM,
	SIDE_BOTTOM: SIDE_TOP,
	SIDE_LEFT: SIDE_RIGHT,
	SIDE_RIGHT: SIDE_LEFT
}

func _init(pos : Vector2i, length : int, towards : Side):
	self.pos = pos
	self.headTowards = towards
	nextTowards = []
	# clamp to file storage data size
	# do + 1 because the length includes the head but the head
	# isn't counted in the stored length field
	length = min(length, MAX_LENGTH + 1)
	if length > 1:
		nextTowards.resize(length - 1)
	# grow away from head
	nextTowards.fill(OPPOSITE_SIDE[towards])

func get_pos(idx : int = INT32_MAX) -> Vector2i:
	var lastPos : Vector2i = pos
	for t in min(idx, len(nextTowards)):
		lastPos += UPDATE_POS[nextTowards[t]]

	return lastPos

func which_pos(which : Vector2i) -> int:
	var curPos : Vector2i = pos
	if which == pos:
		return 0

	for i in len(nextTowards):
		curPos += UPDATE_POS[nextTowards[i]]
		if which == curPos:
			return i + 1

	return -1

func move(towards : Side, resize : bool = false) -> Vector2i:
	var lastPos : Vector2i
	if towards == OPPOSITE_SIDE[headTowards]:
		lastPos = pos
		pos += UPDATE_POS[towards]
		if len(nextTowards) > 0:
			nextTowards.pop_front()
			if len(nextTowards) > 0:
				headTowards = OPPOSITE_SIDE[nextTowards[0]]
	else:
		lastPos = get_pos()
		if len(nextTowards) > 0:
			# pop the tail direction
			if not resize:
				nextTowards.pop_back()

			pos += UPDATE_POS[towards]
			nextTowards.push_front(OPPOSITE_SIDE[towards])
		else:
			pos += UPDATE_POS[towards]
			if resize:
				nextTowards.push_front(OPPOSITE_SIDE[towards])

		headTowards = towards

	return lastPos

func grow(towards : Side):
	if len(nextTowards) == MAX_LENGTH:
		return
	nextTowards.append(towards)

func trim(length : int):
	nextTowards.resize(length - 1)

func print_info():
	printraw(ArrowMap.SIDE_NAME[headTowards], " ")
	for towards in nextTowards:
		printraw(ArrowMap.SIDE_NAME[towards], " ")
	printraw("\n")

func reverse():
	if len(nextTowards) == 0:
		headTowards = OPPOSITE_SIDE[headTowards]
	else:
		pos = get_pos()
		headTowards = nextTowards[-1]
		nextTowards.reverse()
		for i in len(nextTowards):
			nextTowards[i] = OPPOSITE_SIDE[nextTowards[i]]

func copy() -> Snake:
	var snake : Snake = Snake.new(pos, 0, headTowards)
	snake.nextTowards.assign(nextTowards)
	return snake

func slice(start : int, end : int) -> Snake:
	var newsnake : Snake

	if end == -1:
		end = len(nextTowards)
	var start_pos : Vector2i = get_pos(start)
	var towards : Side = headTowards
	if start == 0:
		newsnake = Snake.new(start_pos, end + 1, towards)
		for i in end:
			newsnake.nextTowards[i] = nextTowards[i]
	else:
		start -= 1
		end -= 1
		if start < len(nextTowards) - 1:
			towards = OPPOSITE_SIDE[nextTowards[start + 1]]
		newsnake = Snake.new(start_pos, end - start + 1, towards)
		for i in end - start:
			newsnake.nextTowards[i] = nextTowards[start + 1 + i]
	return newsnake

func adjacent(pos1 : Vector2i, pos2 : Vector2i) -> int:
	# return pos2's relation with pos1
	if pos1 + Vector2i.UP == pos2:
		return SIDE_TOP
	if pos1 + Vector2i.DOWN == pos2:
		return SIDE_BOTTOM
	if pos1 + Vector2i.LEFT == pos2:
		return SIDE_LEFT
	if pos1 + Vector2i.RIGHT == pos2:
		return SIDE_RIGHT
	return -1

func join(other : Snake):
	if len(nextTowards) + len(other.nextTowards) + 1 > MAX_LENGTH:
		# if both snakes joined would be too long, don't do anything
		# add + 1 for a head turning in to a tail piece
		return null

	var thistail : Vector2i = get_pos()
	var othertail : Vector2i = other.get_pos()
	var newsnake : Snake
	var join_dir : int
	# give this snake the head
	join_dir = adjacent(pos, other.pos)
	if join_dir >= 0:
		# other snake's head is near this snake's head
		# the new head will be at this snake's tail
		if len(nextTowards) == 0:
			# no tail
			# can only face in the attachment direction
			newsnake = Snake.new(thistail, 2 + len(other.nextTowards), OPPOSITE_SIDE[join_dir])
		else:
			# whole snake with a tail
			# faces in the tail direction
			newsnake = Snake.new(thistail, 2 + len(nextTowards) + len(other.nextTowards), nextTowards[-1])
		# trace the snake in to the new snake from tail to head
		for i in len(nextTowards):
			newsnake.nextTowards[i] = OPPOSITE_SIDE[nextTowards[-i - 1]]
		# join at the heads
		newsnake.nextTowards[len(nextTowards)] = join_dir as Side
		# trace the rest of the way through the other snake head to tail
		for i in len(other.nextTowards):
			newsnake.nextTowards[len(nextTowards) + 1 + i] = other.nextTowards[i]
		return newsnake
	join_dir = adjacent(thistail, other.pos)
	if join_dir >= 0:
		# this snake in front of the other snake
		# head stays the same
		newsnake = Snake.new(pos, 2 + len(nextTowards) + len(other.nextTowards), headTowards)
		# trace through this snake head to tail
		for i in len(nextTowards):
			newsnake.nextTowards[i] = nextTowards[i]
		# join this tail to the other head
		newsnake.nextTowards[len(nextTowards)] = join_dir as Side
		# trace through the other snake head to tail
		for i in len(other.nextTowards):
			newsnake.nextTowards[len(nextTowards) + 1 + i] = other.nextTowards[i]
		return newsnake
	join_dir = adjacent(pos, othertail)
	if join_dir >= 0:
		# this snake sniffing the other tail
		# the new head will be at this snake's tail
		if len(nextTowards) == 0:
			# no tail
			# can only face in the attachment direction
			newsnake = Snake.new(thistail, 2 + len(other.nextTowards), OPPOSITE_SIDE[join_dir])
		else:
			# whole snake with a tail
			# faces in the tail direction
			newsnake = Snake.new(thistail, 2 + len(nextTowards) + len(other.nextTowards), nextTowards[-1])
		# trace the snake in to the new snake from tail to head
		for i in len(nextTowards):
			newsnake.nextTowards[i] = OPPOSITE_SIDE[nextTowards[-i - 1]]
		# join the other tail to this head
		newsnake.nextTowards[len(nextTowards)] = join_dir as Side
		# trace through the other snake tail to head
		for i in len(other.nextTowards):
			newsnake.nextTowards[len(nextTowards) + 1 + i] = OPPOSITE_SIDE[other.nextTowards[-i - 1]]
		return newsnake
	join_dir = adjacent(thistail, othertail)
	if join_dir >= 0:
		# tail to tail
		# head stays the same
		newsnake = Snake.new(pos, 2 + len(nextTowards) + len(other.nextTowards), headTowards)
		# trace through this snake head to tail
		for i in len(nextTowards):
			newsnake.nextTowards[i] = nextTowards[i]
		# join at the tails
		newsnake.nextTowards[len(nextTowards)] = join_dir as Side
		# trace through the other snake tail to head
		for i in len(other.nextTowards):
			newsnake.nextTowards[len(nextTowards) + 1 + i] = OPPOSITE_SIDE[other.nextTowards[-i - 1]]
		return newsnake

	return null
