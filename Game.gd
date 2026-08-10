class_name Game
extends Node2D

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Menu = null
var title_logo : TextureRect = null
var puzzledata : PuzzleData = null
var puzzle : Puzzle = null

var puzzle_size : Vector2i = Puzzle.DEFAULT_PUZZLE_SIZE
var gen_params : RandGenParams = RandGenParams.new()
var file_name : String = "Untitled"
var file_op : FileBrowser.FileOperation = FileBrowser.FileOperation.NONE

func make_menu():
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)

func make_puzzle(editor_mode : bool = false):
	puzzle = load("res://Puzzle.tscn").instantiate()
	puzzle.game = self
	puzzle.play_mode = not editor_mode
	add_child(puzzle)
	puzzle.update_size(last_size)
	puzzle.set_puzzle_size(puzzle_size)
	# puzzle size needs to have been set
	puzzle.editor = editor_mode
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

func update_menu(title, items : Array[MenuItemDesc]):
	menu.set_heading(title)
	menu.set_items(items)
	menu.update_size()

func main_menu():
	# logo control needs to be recreated each time for reasons
	title_logo = TextureRect.new()
	title_logo.texture = load("res://title.png")
	update_menu(title_logo, menu_main)

var menu_main : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(new_game_menu, "New Game"),
	MenuSelectionDesc.new(editor, "Editor"),
	MenuSelectionDesc.new(quit_game, "Quit Game")
]

func editor():
	menu.destroy()
	title_logo.queue_free()
	puzzle_size = Puzzle.DEFAULT_PUZZLE_SIZE
	make_puzzle(true)

func quit_game():
	get_tree().quit()

func puzzle_finished():
	puzzle.queue_free()
	make_menu()
	main_menu()
	update_sizes()

func new_game_menu():
	update_menu("New Game", menu_new_game)

var menu_new_game : Array[MenuItemDesc] = [
	MenuDoubleSelectionDesc.new(load_puzzle, random_menu, "Load", "Random"),
	MenuSelectionDesc.new(main_menu, "Main Menu")
]

func load_puzzle():
	file_op = FileBrowser.FileOperation.NONE
	var browser : FileBrowser = FileBrowser.new(menu,
												file_name,
												select_return,
												null,
												load_file)
	browser.display_menu()

func load_file(fn : String):
	file_name = fn
	file_op = FileBrowser.FileOperation.LOAD

func select_return():
	if file_op == FileBrowser.FileOperation.LOAD:
		var data : PackedByteArray = FileAccess.get_file_as_bytes(file_name)
		if len(data) == 0:
			var error : Error = FileAccess.get_open_error()
			if error == Error.OK:
				ErrorScreen.show(menu, "File %s is empty." % file_name, load_puzzle)
			else:
				ErrorScreen.show(menu, "File %s couldn't be opened: %s" % [file_name, error_string(error)], load_puzzle)
		else:
			puzzledata = PuzzleData.deserialize(data)
			if puzzledata == null:
				ErrorScreen.show(menu, "File %s is invalid or corrupt." % file_name, load_puzzle)
			else:
				if puzzledata.check_data():
					menu.destroy()
					make_puzzle()
					puzzle.set_data(puzzledata)
				else:
					ErrorScreen.show(menu, "File %s is invalid or corrupt." % file_name, load_puzzle)
				puzzledata.free()
				puzzledata = null
	else:
		new_game_menu()

func random_menu():
	puzzle_size = Puzzle.DEFAULT_PUZZLE_SIZE
	menu_random[0].value = puzzle_size.x
	menu_random[1].value = puzzle_size.y
	menu_random[2].value = gen_params.min_length
	menu_random[3].value = gen_params.max_length
	menu_advanced[0].value = gen_params.base_chance_num
	menu_advanced[1].value = gen_params.base_chance_den
	menu_advanced[2].value = gen_params.chance_mult_num
	menu_advanced[3].value = gen_params.chance_mult_den
	menu_advanced[4].value = gen_params.forward_pref_num
	menu_advanced[5].value = gen_params.forward_pref_den
	menu_advanced[6].value = gen_params.along_snake_pref_num
	menu_advanced[7].value = gen_params.along_snake_pref_den
	menu_advanced[8].value = gen_params.quadrant_pref_num
	menu_advanced[9].value = gen_params.quadrant_pref_den
	menu_advanced[10].value = gen_params.along_edge_pref_num
	menu_advanced[11].value = gen_params.along_edge_pref_den
	do_random_menu()

func do_random_menu():
	update_menu("Random", menu_random)

var menu_random : Array[MenuItemDesc] = [
	MenuValueDesc.new(puzzle_size.x, Puzzle.MIN_SIZE.x, Puzzle.MAX_SIZE.x, null, "Width"),
	MenuValueDesc.new(puzzle_size.y, Puzzle.MIN_SIZE.y, Puzzle.MAX_SIZE.y, null, "Height"),
	MenuValueDesc.new(Puzzle.MIN_LENGTH, Puzzle.MIN_LENGTH, Puzzle.MAX_LENGTH, min_length_change, "Min Length"),
	MenuValueDesc.new(Puzzle.MIN_LENGTH, Puzzle.MIN_LENGTH, Puzzle.MAX_LENGTH, max_length_change, "Max Length"),
	MenuSelectionDesc.new(advanced_menu, "Advanced >>"),
	MenuDoubleSelectionDesc.new(new_game_menu, do_random, "Cancel", "Go"),
]

func min_length_change(val : int) -> int:
	gen_params.min_length = min(val, gen_params.max_length)
	return gen_params.min_length

func max_length_change(val : int) -> int:
	gen_params.max_length = max(val, gen_params.min_length)
	return gen_params.max_length

func advanced_menu():
	update_menu("Advanced", menu_advanced)

var menu_advanced : Array[MenuItemDesc] = [
	MenuValueDesc.new(0, 0, 1000, null, "Base Chance Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Base Chance Den"),
	MenuValueDesc.new(0, 0, 1000, null, "Chance Mult Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Chance Mult Den"),
	MenuValueDesc.new(0, 0, 1000, null, "Forward Pref Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Forward Pref Den"),
	MenuValueDesc.new(0, 0, 1000, null, "Along Snake Pref Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Along Snake Pref Den"),
	MenuValueDesc.new(0, 0, 1000, null, "Quadrant Pref Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Quadrant Pref Den"),
	MenuValueDesc.new(0, 0, 1000, null, "Along Edge Pref Num"),
	MenuValueDesc.new(1, 1, 1000, null, "Along Edge Pref Den"),
	MenuSelectionDesc.new(do_random_menu, "Return")
]

func do_random():
	# length params use functions so they're already updated
	puzzle_size.x = menu_random[0].value
	puzzle_size.y = menu_random[1].value
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
	menu.destroy()
	make_puzzle()
	puzzle.generate_random(gen_params)
