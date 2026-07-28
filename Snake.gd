extends Object
class_name Snake

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
	if length > 1:
		nextTowards.resize(length - 1)
	# grow away from head
	nextTowards.fill(OPPOSITE_SIDE[towards])

func get_pos(idx : int = TYPE_MAX) -> Vector2i:
	var lastPos : Vector2i = pos
	for t in min(idx, len(nextTowards)):
		lastPos += UPDATE_POS[nextTowards[t]]

	return lastPos

func move(towards : Side) -> Vector2i:
	var lastPos : Vector2i = get_pos()
	if len(nextTowards) > 0:
		# pop the tail direction
		nextTowards.pop_back()

		match towards:
			SIDE_TOP:
				pos.y -= 1
				nextTowards.push_front(SIDE_BOTTOM)
			SIDE_BOTTOM:
				pos.y += 1
				nextTowards.push_front(SIDE_TOP)
			SIDE_LEFT:
				pos.x -= 1
				nextTowards.push_front(SIDE_RIGHT)
			SIDE_RIGHT:
				pos.x += 1
				nextTowards.push_front(SIDE_LEFT)
	else:
		match towards:
			SIDE_TOP:
				pos.y -= 1
			SIDE_BOTTOM:
				pos.y += 1
			SIDE_LEFT:
				pos.x -= 1
			SIDE_RIGHT:
				pos.x += 1

	headTowards = towards

	return lastPos

func grow(towards : Side):
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
		end = len(nextTowards) + 1
	var start_pos : Vector2i = get_pos(start)
	var towards : Side = headTowards
	if start > 0:
		towards = OPPOSITE_SIDE[nextTowards[start]]
		newsnake = Snake.new(start_pos, end - start, towards)
		for i in end - start:
			newsnake.nextTowards[i] = nextTowards[start + i]
	else:
		newsnake = Snake.new(start_pos, end, towards)
		for i in end - 1:
			newsnake.nextTowards[i] = nextTowards[start + i]
	return newsnake
