class_name Game
extends Node2D

const MIN_SIZE : Vector2i = Vector2i(3, 3)
const MAX_SIZE : Vector2i = Vector2i(200, 200)
var puzzle_size : Vector2i = Vector2i(40, 40)

const FILE_EXTENSION : String = "arrows"

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Menu = null
var title_logo : TextureRect = null
var puzzledata : PuzzleData = null
var puzzle : Puzzle = null

func make_menu():
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)

func make_puzzle(editor_mode : bool = false):
	puzzle = load("res://Puzzle.tscn").instantiate()
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
	MenuSelectionDesc.new(load_puzzle, "Load"),
	MenuSelectionDesc.new(random_puzzle, "Random"),
	MenuSelectionDesc.new(main_menu, "Main Menu")
]

func load_puzzle():
	var browser : FileBrowser = FileBrowser.new(menu,
												"Untitled",
												FILE_EXTENSION,
												select_return,
												null,
												load_file)
	browser.display_menu()

func load_file(fn : String):
	puzzledata = PuzzleData.deserialize(FileAccess.get_file_as_bytes(fn))

func select_return():
	if puzzledata != null:
		menu.destroy()
		make_puzzle()
		puzzle.set_data(puzzledata)

func random_puzzle():
	main_menu()
