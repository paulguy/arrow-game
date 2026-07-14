extends Node2D

const DEFAULT_SIZE : Vector2i = Vector2i(40, 40)

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var title : Sprite2D = null
var puzzle : Node2D = null

func make_puzzle():
	puzzle = load("res://puzzle.tscn").instantiate()
	add_child(puzzle)
	puzzle.setup_map(DEFAULT_SIZE)
	puzzle.update_size(last_size)

func update_title():
	var tsize_ratio : Vector2i = Vector2(last_size) / title.texture.get_size()
	var tsize : int = max(1, tsize_ratio[tsize_ratio.min_axis_index()])
	title.scale = Vector2(tsize, tsize)
	title.position = last_size / 2

func _ready():
	last_size = get_viewport_rect().size
	background.update_size(last_size)
	# TODO make and instantiate menu
	title = Sprite2D.new()
	title.texture = ImageTexture.create_from_image(Image.load_from_file("res://title.png"))
	add_child(title)
	update_title()

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		background.update_size(last_size)
		if puzzle != null:
			puzzle.update_size(last_size)
		else:
			# title is visible
			update_title()

func _input(e : InputEvent):
	if e is InputEventScreenTouch:
		if puzzle == null:
			title.queue_free()
			make_puzzle()
