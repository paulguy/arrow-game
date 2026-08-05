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

static func append_snakedata(snakedata : PackedByteArray,
							 filled : int,
							 value : Side):
	# lengthen the array if needed
	if (filled + 1) / 4 >= len(snakedata):
		snakedata.append(0)

	# initialize new byte with 0
	if filled % 4 == 0:
		snakedata[filled / 4] = 0

	snakedata[filled / 4] |= (value & 0x3) << ((filled % 4) * 2)

static func get_snakedata(snakedata : PackedByteArray,
						  index : int):
	return snakedata[index / 4] >> (index % 4 * 2) & 0x3

static func get_snakedata_len(datas : int):
	return (datas / 4) + (1 if datas % 4 > 0 else 0)

func serialize() -> PackedByteArray:
	var data : PackedByteArray = PackedByteArray()
	var snakedata : PackedByteArray = PackedByteArray()
	var snakedatalen : int

	# store size
	data.append(size.x)
	data.append(size.y)

	# store snakes: x, y, count, 
	for snake in snakes:
		data.append(snake.pos.x)
		data.append(snake.pos.y)
		data.append(0)
		data.append(0)
		data.append(0)
		data.append(0)
		data.encode_u32(len(data) - 4, len(snake.nextTowards))
		append_snakedata(snakedata, 0, snake.headTowards)
		for i in len(snake.nextTowards):
			append_snakedata(snakedata, i + 1, snake.nextTowards[i])
		data.append_array(snakedata.slice(0, get_snakedata_len(len(snake.nextTowards) + 1)))
	data.append(255)

	data.append_array(flies)

	return data

static func deserialize(data : PackedByteArray) -> PuzzleData:
	var size : Vector2i
	var snakes : Array[Snake] = []

	size.x = data[0]
	size.y = data[1]

	var datapos : int = 2
	var snakepos : Vector2i
	var snakelen : int
	var headTowards : Side
	var nextTowards : Array[Side]
	while true:
		# get position
		snakepos.x = data[datapos]
		prints(snakepos.x, "%02x" % snakepos.x)
		# 255 is the magic byte for the last snake
		if snakepos.x == 255:
			datapos += 1
			break
		snakepos.y = data[datapos + 1]
		# get length
		snakelen = data.decode_u32(datapos + 2)
		# advance snake header
		datapos += 6
		# get snake head
		headTowards = get_snakedata(data, datapos * 4)
		# get snake tail pieces
		nextTowards = []
		for i in snakelen:
			nextTowards.append(get_snakedata(data, datapos * 4 + i + 1))
		# advance the number of bytes needed for nextTowards including any tail byte
		datapos += get_snakedata_len(len(nextTowards) + 1)
		print(datapos)

		snakes.append(Snake.new(snakepos, 1, headTowards))
		snakes[-1].nextTowards = nextTowards

	# the rest of the data is flies
	return PuzzleData.new(size, snakes, data.slice(datapos))
