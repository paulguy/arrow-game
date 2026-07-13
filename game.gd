extends Node2D

const DEFAULT_SIZE : Vector2i = Vector2i(40, 40)

@onready var puzzle : Node2D = $Puzzle
@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO

func _ready():
	last_size = get_viewport_rect().size
	puzzle.update_size(last_size)
	background.update_size(last_size)
	puzzle.setup_map(DEFAULT_SIZE)

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		puzzle.update_size(last_size)
		background.update_size(last_size)
