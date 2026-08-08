extends Node2D

const MIN_SIZE : Vector2i = Vector2i(3, 3)
const MAX_SIZE : Vector2i = Vector2i(200, 200)
var puzzle_size : Vector2i = Vector2i(40, 40)

@onready var background : Polygon2D = $Background

var last_size : Vector2i = Vector2i.ZERO
var menu : Menu = null
var title_logo : TextureRect = null
var puzzle : Node2D = null

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

var menu_main : Array[MenuItemDesc] = [
#	MenuSelectionDesc.new(new_game_menu, "New Game"),
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
