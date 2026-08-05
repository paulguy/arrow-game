class_name PuzzleData
extends Object

var size : Vector2i
var snakes : Array[Snake]
var flies : PackedByteArray

func _init(size : Vector2i,
		   snakes : Array[Snake],
		   flies : PackedByteArray):
	self.size = size
	self.snakes = snakes
	self.flies = flies

static func get_data(size : Vector2i,
					 snakes : Array[Snake],
					 occupied_by : PackedInt32Array) -> PuzzleData:
	var newsnakes : Array[Snake] = []
	for snake in snakes:
		if snake != ArrowMap.DEAD_SNAKE:
			# deep copy the whole array
			newsnakes.append(snake.copy())

	var flies : PackedByteArray = PackedByteArray()
	flies.resize(size.x * size.y / 8 + (1 if size.x * size.y % 8 > 0 else 0))
	# pack all the whole bytes in
	for i in size.x * size.y / 8:
		var i2 : int = i * 8
		flies[i] = (  1 if occupied_by[i2 + 0] == ArrowMap.FLY_ID else 0) | \
				   (  2 if occupied_by[i2 + 1] == ArrowMap.FLY_ID else 0) | \
				   (  4 if occupied_by[i2 + 2] == ArrowMap.FLY_ID else 0) | \
				   (  8 if occupied_by[i2 + 3] == ArrowMap.FLY_ID else 0) | \
				   ( 16 if occupied_by[i2 + 4] == ArrowMap.FLY_ID else 0) | \
				   ( 32 if occupied_by[i2 + 5] == ArrowMap.FLY_ID else 0) | \
				   ( 64 if occupied_by[i2 + 6] == ArrowMap.FLY_ID else 0) | \
				   (128 if occupied_by[i2 + 7] == ArrowMap.FLY_ID else 0)
	if size.x * size.y % 8 > 0:
		# pack any tail bits in
		flies[-1] = ( 1 if size.x * size.y / 8 * 8 + 0 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 0] == ArrowMap.FLY_ID else 0) | \
					( 2 if size.x * size.y / 8 * 8 + 1 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 1] == ArrowMap.FLY_ID else 0) | \
					( 4 if size.x * size.y / 8 * 8 + 2 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 2] == ArrowMap.FLY_ID else 0) | \
					( 8 if size.x * size.y / 8 * 8 + 3 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 3] == ArrowMap.FLY_ID else 0) | \
					(16 if size.x * size.y / 8 * 8 + 4 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 4] == ArrowMap.FLY_ID else 0) | \
					(32 if size.x * size.y / 8 * 8 + 5 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 5] == ArrowMap.FLY_ID else 0) | \
					(64 if size.x * size.y / 8 * 8 + 6 < len(occupied_by) - 1 and occupied_by[size.x * size.y / 8 * 8 + 6] == ArrowMap.FLY_ID else 0)

	return PuzzleData.new(size, newsnakes, flies)

func set_data(occupied_by : PackedInt32Array):
	# unpack the whole bytes
	for i in size.x * size.y / 8:
		var i2 : int = i * 8
		if flies[i] &   1:
			occupied_by[i2 + 0] = ArrowMap.FLY_ID
		if flies[i] &   2:
			occupied_by[i2 + 1] = ArrowMap.FLY_ID
		if flies[i] &   4:
			occupied_by[i2 + 2] = ArrowMap.FLY_ID
		if flies[i] &   8:
			occupied_by[i2 + 3] = ArrowMap.FLY_ID
		if flies[i] &  16:
			occupied_by[i2 + 4] = ArrowMap.FLY_ID
		if flies[i] &  32:
			occupied_by[i2 + 5] = ArrowMap.FLY_ID
		if flies[i] &  64:
			occupied_by[i2 + 6] = ArrowMap.FLY_ID
		if flies[i] & 128:
			occupied_by[i2 + 7] = ArrowMap.FLY_ID
	if size.x * size.y % 8 > 0:
		# unpack any tail bits
		if size.x * size.y / 8 * 8 + 0 < len(occupied_by) and flies[-1] &  1:
			occupied_by[size.x * size.y / 8 * 8 + 0] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 1 < len(occupied_by) and flies[-1] &  2:
			occupied_by[size.x * size.y / 8 * 8 + 1] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 2 < len(occupied_by) and flies[-1] &  4:
			occupied_by[size.x * size.y / 8 * 8 + 2] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 3 < len(occupied_by) and flies[-1] &  8:
			occupied_by[size.x * size.y / 8 * 8 + 3] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 4 < len(occupied_by) and flies[-1] & 16:
			occupied_by[size.x * size.y / 8 * 8 + 4] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 5 < len(occupied_by) and flies[-1] & 32:
			occupied_by[size.x * size.y / 8 * 8 + 5] = ArrowMap.FLY_ID
		if size.x * size.y / 8 * 8 + 6 < len(occupied_by) and flies[-1] & 64:
			occupied_by[size.x * size.y / 8 * 8 + 6] = ArrowMap.FLY_ID

	return snakes
