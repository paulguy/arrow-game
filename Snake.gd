extends Object
class_name Snake

var pos : Vector2i
var nextTowards : Array[Side]
var headTowards : Side

func _init(pos : Vector2i, length : int, towards : Side):
	self.pos = pos
	self.headTowards = towards
	nextTowards = []
	if length > 1:
		nextTowards.resize(length - 1)
	# grow away from head
	match towards:
		SIDE_TOP:
			nextTowards.fill(SIDE_BOTTOM)
		SIDE_BOTTOM:
			nextTowards.fill(SIDE_TOP)
		SIDE_LEFT:
			nextTowards.fill(SIDE_RIGHT)
		SIDE_RIGHT:
			nextTowards.fill(SIDE_LEFT)

func get_tail_pos() -> Vector2i:
	var lastPos : Vector2i = pos
	for t in nextTowards:
		match t:
			SIDE_TOP:
				lastPos.y -= 1
			SIDE_BOTTOM:
				lastPos.y += 1
			SIDE_LEFT:
				lastPos.x -= 1
			SIDE_RIGHT:
				lastPos.x += 1

	return lastPos

func move(towards : Side) -> Vector2i:
	var lastPos : Vector2i = get_tail_pos()
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

func print_info():
	printraw(ArrowMap.SIDE_NAME[headTowards], " ")
	for towards in nextTowards:
		printraw(ArrowMap.SIDE_NAME[towards], " ")
	printraw("\n")

func reverse():
	if len(nextTowards) == 0:
		headTowards = ArrowMap.OPPOSITE_SIDE[headTowards]
	else:
		pos = get_tail_pos()
		headTowards = nextTowards[-1]
		nextTowards.reverse()
		for i in len(nextTowards):
			nextTowards[i] = ArrowMap.OPPOSITE_SIDE[nextTowards[i]]

func copy() -> Snake:
	var snake : Snake = Snake.new(pos, 0, headTowards)
	snake.nextTowards.assign(nextTowards)
	return snake

func trim(length : int):
	nextTowards.resize(length - 1)
