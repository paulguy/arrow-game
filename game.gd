extends Node2D

const MAX_SIZE : Vector2i = Vector2i(200, 200)
var puzzle_size : Vector2i = Vector2i(40, 40)

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Control = null
var puzzle : Node2D = null

var MENU_MAIN : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(new_game_menu, "New Game"),
	MenuSelectionDesc.new(editor, "Editor"),
	MenuSelectionDesc.new(quit_game, "Quit Game")
]

var MENU_NEW_GAME : Array[MenuItemDesc] = [
	MenuValueDesc.new(puzzle_size.x, 0, MAX_SIZE.x, width_change, "Width"),
	MenuValueDesc.new(puzzle_size.y, 0, MAX_SIZE.y, height_change, "Height"),
	MenuSelectionDesc.new(new_game, "Start"),
	MenuSelectionDesc.new(main_menu, "Main Menu"),
]

func make_puzzle():
	puzzle = load("res://puzzle.tscn").instantiate()
	add_child(puzzle)
	puzzle.setup_map(puzzle_size)
	puzzle.update_size(last_size)

func update_sizes():
	background.update_size(last_size)
	if menu != null:
		menu.update_size(last_size)
	if puzzle != null:
		puzzle.update_size(last_size)

func main_menu():
	var title_control : TextureRect = TextureRect.new()
	title_control.texture = load("res://title.png")
	title_control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu.set_heading(title_control)
	menu.set_items(MENU_MAIN)

func _ready():
	last_size = get_viewport_rect().size
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)
	main_menu()
	update_sizes()

func _process(_delta : float):
	var new_size : Vector2i = get_viewport_rect().size
	if new_size != last_size:
		last_size = new_size
		update_sizes()

func new_game():
	menu.queue_free()
	menu = null
	make_puzzle()

func editor():
	return

func quit_game():
	get_tree().quit()

func new_game_menu():
	var title_control : Label = Label.new()
	title_control.text = "New Game"
	menu.set_heading(title_control)
	menu.set_items(MENU_NEW_GAME)

func width_change(val : int):
	puzzle_size.x = val

func height_change(val : int):
	puzzle_size.y = val
