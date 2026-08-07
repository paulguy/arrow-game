extends Node2D

const MIN_SIZE : Vector2i = Vector2i(3, 3)
const MAX_SIZE : Vector2i = Vector2i(200, 200)
var puzzle_size : Vector2i = Vector2i(40, 40)
const MIN_LENGTH : int = 3
const MAX_LENGTH : int = 100

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Menu = null
var title_logo : TextureRect = null
var puzzle : Node2D = null
var gen_params : RandGenParams = RandGenParams.new()

func make_menu():
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)

func make_puzzle(editor : bool):
	puzzle = load("res://puzzle.tscn").instantiate()
	puzzle.play_mode = not editor
	add_child(puzzle)
	puzzle.update_size(last_size)
	puzzle.set_puzzle_size(puzzle_size)
	# puzzle size needs to have been set
	puzzle.editor = editor
	puzzle.connect(&"puzzle_finished", puzzle_finished)

func update_sizes():
	background.update_size(last_size)
	if menu != null:
		menu.update_size(last_size)
	if puzzle != null:
		puzzle.update_size(last_size)

func _ready():
	last_size = get_viewport_rect().size
	make_menu()
	main_menu()
	update_sizes()

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		update_sizes()

func main_menu():
	# logo control needs to be recreated each time for reasons
	title_logo = TextureRect.new()
	title_logo.texture = load("res://title.png")
	menu.set_heading(title_logo)
	menu.set_items(menu_main)
	menu.update_size(last_size)

func new_game():
	# kinda hacky
	puzzle_size.x = menu_new_game[0].value
	puzzle_size.y = menu_new_game[1].value
	# length params use functions so they're already updated
	gen_params.base_chance_num = menu_advanced[0].value
	gen_params.base_chance_den = menu_advanced[1].value
	gen_params.chance_mult_num = menu_advanced[2].value
	gen_params.chance_mult_den = menu_advanced[3].value
	gen_params.forward_pref_num = menu_advanced[4].value
	gen_params.forward_pref_den = menu_advanced[5].value
	gen_params.along_snake_pref_num = menu_advanced[6].value
	gen_params.along_snake_pref_den = menu_advanced[7].value
	gen_params.quadrant_pref_num = menu_advanced[8].value
	gen_params.quadrant_pref_den = menu_advanced[9].value
	gen_params.along_edge_pref_num = menu_advanced[10].value
	gen_params.along_edge_pref_den = menu_advanced[11].value
	gen_params.update_floats()
	menu.destroy()
	title_logo.queue_free()
	make_puzzle(false)
	puzzle.generate_random(gen_params)

var menu_main : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(new_game_menu, "New Game"),
	MenuSelectionDesc.new(editor, "Editor"),
	MenuSelectionDesc.new(quit_game, "Quit Game")
]

func editor():
	menu.destroy()
	title_logo.queue_free()
	make_puzzle(true)

func quit_game():
	get_tree().quit()

func new_game_menu():
	menu.set_heading("New Game")
	menu.set_items(menu_new_game)

var menu_new_game : Array[MenuItemDesc] = [
	MenuValueDesc.new(puzzle_size.x, MIN_SIZE.x, MAX_SIZE.x, null, "Width"),
	MenuValueDesc.new(puzzle_size.y, MIN_SIZE.y, MAX_SIZE.y, null, "Height"),
	MenuValueDesc.new(gen_params.min_length, MIN_LENGTH, MAX_LENGTH, min_length_change, "Min Length"),
	MenuValueDesc.new(gen_params.max_length, MIN_LENGTH, MAX_LENGTH, max_length_change, "Max Length"),
	MenuSelectionDesc.new(advanced_menu, "Advanced >>"),
	MenuSelectionDesc.new(new_game, "Start"),
	MenuSelectionDesc.new(main_menu, "Main Menu"),
]

func min_length_change(val : int) -> int:
	gen_params.min_length = min(val, gen_params.max_length)
	return gen_params.min_length

func max_length_change(val : int) -> int:
	gen_params.max_length = max(val, gen_params.min_length)
	return gen_params.max_length

func advanced_menu():
	menu.set_heading("Advanced")
	menu.set_items(menu_advanced)

var menu_advanced : Array[MenuItemDesc] = [
	MenuValueDesc.new(gen_params.base_chance_num, 0, 1000, null, "Base Chance Num"),
	MenuValueDesc.new(gen_params.base_chance_den, 1, 1000, null, "Base Chance Den"),
	MenuValueDesc.new(gen_params.chance_mult_num, 0, 1000, null, "Chance Mult Num"),
	MenuValueDesc.new(gen_params.chance_mult_den, 1, 1000, null, "Chance Mult Den"),
	MenuValueDesc.new(gen_params.forward_pref_num, 0, 1000, null, "Forward Pref Num"),
	MenuValueDesc.new(gen_params.forward_pref_den, 1, 1000, null, "Forward Pref Den"),
	MenuValueDesc.new(gen_params.along_snake_pref_num, 0, 1000, null, "Along Snake Pref Num"),
	MenuValueDesc.new(gen_params.along_snake_pref_den, 1, 1000, null, "Along Snake Pref Den"),
	MenuValueDesc.new(gen_params.quadrant_pref_num, 0, 1000, null, "Quadrant Pref Num"),
	MenuValueDesc.new(gen_params.quadrant_pref_den, 1, 1000, null, "Quadrant Pref Den"),
	MenuValueDesc.new(gen_params.along_edge_pref_num, 0, 1000, null, "Along Edge Pref Num"),
	MenuValueDesc.new(gen_params.along_edge_pref_den, 1, 1000, null, "Along Edge Pref Den"),
	MenuSelectionDesc.new(new_game_menu, "Return")
]

func puzzle_finished():
	puzzle.queue_free()
	make_menu()
	main_menu()
	update_sizes()
