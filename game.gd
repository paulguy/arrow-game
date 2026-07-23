extends Node2D

const MAX_SIZE : Vector2i = Vector2i(200, 200)
var puzzle_size : Vector2i = Vector2i(40, 40)
const MIN_LENGTH : int = 3
var min_length : int = 3
const MAX_LENGTH : int = 100
var max_length : int = 10

var base_chance_num : int = 1
var base_chance_den : int = 100
var chance_mult_num : int = 11
var chance_mult_den : int = 10
var forward_pref_num : int = 4
var forward_pref_den : int = 1
var along_snake_pref_num : int = 8
var along_snake_pref_den : int = 1
var quadrant_pref_num : int = 10
var quadrant_pref_den : int = 1
var along_edge_pref_num : int = 1
var along_edge_pref_den : int = 10

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Control = null
var puzzle : Node2D = null
var title_logo : TextureRect

# TODO: detect game end and end game menu

func make_menu():
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)

func make_puzzle():
	puzzle = load("res://puzzle.tscn").instantiate()
	add_child(puzzle)
	puzzle.setup_map(puzzle_size, min_length, max_length)
	puzzle.update_size(last_size)
	puzzle.connect(&"puzzle_finished", puzzle_finished)

func update_sizes():
	background.update_size(last_size)
	if menu != null:
		menu.update_size(last_size)
	if puzzle != null:
		puzzle.update_size(last_size)
	title_logo.custom_minimum_size = Vector2(last_size.x, last_size.y / 2.0)

func _ready():
	last_size = get_viewport_rect().size
	title_logo = TextureRect.new()
	title_logo.texture = load("res://title.png")
	title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	make_menu()
	main_menu()
	update_sizes()

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		update_sizes()

func main_menu():
	menu.set_heading(title_logo)
	menu.set_items(menu_main)

func new_game():
	# kinda hacky
	puzzle_size.x = menu_new_game[0].value
	puzzle_size.y = menu_new_game[1].value
	min_length = menu_new_game[2].value
	max_length = menu_new_game[3].value
	base_chance_num = menu_advanced[0].value
	base_chance_den = menu_advanced[1].value
	chance_mult_num = menu_advanced[2].value
	chance_mult_den = menu_advanced[3].value
	forward_pref_num = menu_advanced[4].value
	forward_pref_den = menu_advanced[5].value
	along_snake_pref_num = menu_advanced[6].value
	along_snake_pref_den = menu_advanced[7].value
	quadrant_pref_num = menu_advanced[8].value
	quadrant_pref_den = menu_advanced[9].value
	along_edge_pref_num = menu_advanced[10].value
	along_edge_pref_den = menu_advanced[11].value
	menu.destroy()
	make_puzzle()

var menu_main : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(new_game_menu, "New Game"),
	MenuSelectionDesc.new(editor, "Editor"),
	MenuSelectionDesc.new(quit_game, "Quit Game")
]

func editor():
	return

func quit_game():
	get_tree().quit()

func new_game_menu():
	menu.set_heading("New Game")
	menu.set_items(menu_new_game)

var menu_new_game : Array[MenuItemDesc] = [
	MenuValueDesc.new(puzzle_size.x, 0, MAX_SIZE.x, null, "Width"),
	MenuValueDesc.new(puzzle_size.y, 0, MAX_SIZE.y, null, "Height"),
	MenuValueDesc.new(min_length, MIN_LENGTH, MAX_LENGTH, min_length_change, "Min Length"),
	MenuValueDesc.new(max_length, MIN_LENGTH, MAX_LENGTH, max_length_change, "Max Length"),
	MenuSelectionDesc.new(advanced_menu, "Advanced >>"),
	MenuSelectionDesc.new(new_game, "Start"),
	MenuSelectionDesc.new(main_menu, "Main Menu"),
]

func min_length_change(val : int) -> int:
	min_length = min(val, max_length)
	return min_length

func max_length_change(val : int) -> int:
	max_length = max(val, min_length)
	return max_length

func advanced_menu():
	menu.set_heading("Advanced")
	menu.set_items(menu_advanced)

var menu_advanced : Array[MenuItemDesc] = [
	MenuValueDesc.new(base_chance_num, 0, 1000, null, "Base Chance Num"),
	MenuValueDesc.new(base_chance_den, 1, 1000, null, "Base Chance Den"),
	MenuValueDesc.new(chance_mult_num, 0, 1000, null, "Chance Mult Num"),
	MenuValueDesc.new(chance_mult_den, 1, 1000, null, "Chance Mult Den"),
	MenuValueDesc.new(forward_pref_num, 0, 1000, null, "Forward Pref Num"),
	MenuValueDesc.new(forward_pref_den, 1, 1000, null, "Forward Pref Den"),
	MenuValueDesc.new(along_snake_pref_num, 0, 1000, null, "Along Snake Pref Num"),
	MenuValueDesc.new(along_snake_pref_den, 1, 1000, null, "Along Snake Pref Den"),
	MenuValueDesc.new(quadrant_pref_num, 0, 1000, null, "Quadrant Pref Num"),
	MenuValueDesc.new(quadrant_pref_den, 1, 1000, null, "Quadrant Pref Den"),
	MenuValueDesc.new(along_edge_pref_num, 0, 1000, null, "Along Edge Pref Num"),
	MenuValueDesc.new(along_edge_pref_den, 1, 1000, null, "Along Edge Pref Den"),
	MenuSelectionDesc.new(new_game_menu, "Return")
]

func puzzle_finished():
	puzzle.queue_free()
	make_menu()
	main_menu()
	update_sizes()
