extends Node2D

const DEFAULT_SIZE : Vector2i = Vector2i(40, 40)

@onready var background : Node2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var puzzle : Node2D = null

func _ready():
	last_size = get_viewport_rect().size
	background.update_size(last_size)

	puzzle = load("res://puzzle.tscn").instantiate()
	add_child(puzzle)
	puzzle.setup_map(DEFAULT_SIZE)
	puzzle.update_size(last_size)

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		background.update_size(last_size)
		if puzzle != null:
			puzzle.update_size(last_size)
