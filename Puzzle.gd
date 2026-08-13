class_name Puzzle
extends Node2D

signal puzzle_finished

const DRAG_DELAY_MS : float = 200
const VIEW_OFF_RATIO : float = 0.8
const ZOOM_OCTAVE_DIV : float = 12.0
const ZOOM_MIN : float = 1.0/8.0

const BUTTON_SHADE_ALPHA : float = 0.5

const MIN_SIZE : Vector2i = Vector2i(3, 3)
const MAX_SIZE : Vector2i = Vector2i(200, 200)
const DEFAULT_PUZZLE_SIZE : Vector2i = Vector2i(40, 40)

const MIN_LENGTH : int = 3
const MAX_LENGTH : int = 100

const BORDER_TL : Vector2i = Vector2i(0, 0)
const BORDER_TL_ALT : int = 0
const BORDER_TR : Vector2i = Vector2i(1, 0)
const BORDER_TR_ALT : int = 0
const BORDER_BL : Vector2i = Vector2i(1, 0)
const BORDER_BL_ALT : int = 1
const BORDER_BR : Vector2i = Vector2i(2, 0)
const BORDER_BR_ALT : int = 0
const BORDER_T : Vector2i = Vector2i(3, 0)
const BORDER_T_ALT : int = 0
const BORDER_B : Vector2i = Vector2i(4, 0)
const BORDER_B_ALT : int = 0
const BORDER_L : Vector2i = Vector2i(3, 0)
const BORDER_L_ALT : int = 1
const BORDER_R : Vector2i = Vector2i(4, 0)
const BORDER_R_ALT : int = 1
const BORDER_BG : Vector2i = Vector2i(5, 0)
const BORDER_SHADOW_BL : Vector2i = Vector2i(0, 1)
const BORDER_SHADOW_BL_ALT : int = 0
const BORDER_SHADOW_TR : Vector2i = Vector2i(0, 1)
const BORDER_SHADOW_TR_ALT : int = 1
const BORDER_SHADOW_BR : Vector2i = Vector2i(2, 1)
const BORDER_SHADOW_BR_ALT : int = 0
const BORDER_SHADOW_B : Vector2i = Vector2i(1, 1)
const BORDER_SHADOW_B_ALT : int = 0
const BORDER_SHADOW_R : Vector2i = Vector2i(1, 1)
const BORDER_SHADOW_R_ALT : int = 1

const EDITOR_BUTTONS : Array[String] = [
	"Delete",
	"Grow",
	"Reverse",
	"Action"
]

const ACTION_NAMES : Array[String] = [
	"Select",
	"Add",
	"Split",
	"Join",
	"Flies"
]

enum Action {
	SELECT = 0,
	ADD,
	SPLIT,
	JOIN,
	FLIES,
	MAX
}

@onready var arrow_view : ArrowView = $"ArrowView"
@onready var border : TileMapLayer = $"Border"
@onready var field_bg : Polygon2D = $"Border/Field Background"
@onready var blur_viewport : Polygon2D = $"Arrow Viewport Blur"
@onready var arrow_viewport : Polygon2D = $"Arrow Viewport View"
@onready var flies_viewport : Polygon2D = $"Flies Viewport View"
@onready var overlay : Control = $"Overlay"
@onready var ui_menu : Control = $"Overlay/Menu"
@onready var d_pad : Control = $"Overlay/D-Pad"
@onready var shade : Polygon2D = $"Shade"

var game : Game
var tile_size : Vector2i
var map_size : Vector2i
var view_pos : Vector2 = Vector2.ZERO
var view_zoom : float = 1.0
var last_drag : int = 0
var last_size : Vector2i
var menu_display : bool = false
var menu : Control = null
var puzzledata : PuzzleData = null
# whether this was started from a new game or the editor option
var play_mode : bool = true
# whether the editor should display (or test mode)
var editor : bool = false:
	set(mode):
		if mode:
			if not editor:
				arrow_view.select_snake(-1)
				# restore the list of snakes
				if puzzledata != null:
					arrow_view.set_data(puzzledata)
					puzzledata.free()
					puzzledata = null
				$"Overlay/Menu/Mode/Margins/Text".text = "Test"
				for item in EDITOR_BUTTONS:
					get_node(NodePath("Overlay/Menu/%s" % item)).visible = true
				$"Overlay/D-Pad".visible = true
		else:
			if editor:
				arrow_view.select_snake(-1)
				# backup the list of snakes
				puzzledata = arrow_view.get_data()
				$"Overlay/Menu/Mode/Margins/Text".text = "Edit"
				# update the collisions for flies
				arrow_view.update_astar()
				for item in EDITOR_BUTTONS:
					get_node(NodePath("Overlay/Menu/%s" % item)).visible = false
				$"Overlay/D-Pad".visible = false
		editor = mode
var grow : bool = false:
	set(val):
		if val:
			$"Overlay/Menu/Grow".modulate.a = 1.0
		else:
			$"Overlay/Menu/Grow".modulate.a = BUTTON_SHADE_ALPHA
		grow = val
var action : Action = Action.SELECT
var file_name : String = "Untitled"
var browser : FileBrowser = null

func _ready():
	$"Overlay/Menu/Menu/Margins/Text".text = "Menu"
	if not play_mode:
		# in edit mode, make edit items visible
		$"Overlay/Menu/Mode/Margins/Text".text = "Mode"
		$"Overlay/Menu/Mode".visible = true
		$"Overlay/Menu/Mode".modulate.a = BUTTON_SHADE_ALPHA
		for item in EDITOR_BUTTONS:
			var button : MarginContainer = get_node(NodePath("Overlay/Menu/%s" % item))
			button.visible = true
			button.modulate.a = BUTTON_SHADE_ALPHA
			var label : Label = button.get_node("Margins/Text")
			label.text = item
		$"Overlay/Menu/Action/Margins/Text".text = ACTION_NAMES[action]
		$"Overlay/D-Pad/Up/Margins/Text".text = "▲"
		$"Overlay/D-Pad/Left/Margins/Text".text = "◀"
		$"Overlay/D-Pad/Right/Margins/Text".text = "▶"
		$"Overlay/D-Pad/Down/Margins/Text".text = "▼"
		$"Overlay/D-Pad".visible = true
		$"Overlay/D-Pad".modulate.a = BUTTON_SHADE_ALPHA

	var viewport_texture : ViewportTexture = arrow_view.get_viewport_texture()
	blur_viewport.texture = viewport_texture
	arrow_viewport.texture = viewport_texture
	flies_viewport.texture = arrow_view.get_flies_viewport_texture()

	arrow_view.connect(&"puzzle_finished", puzzle_clear)

func _process(_delta : float):
	# HACK: free browser when it's done.
	# This is the only way a function is guaranteed to run after
	# returning from the file browser, since free can't be called
	# in any of the browser callbacks.
	if browser != null and browser.done:
		browser.free()

func _physics_process(_delta : float):
	if not editor:
		arrow_view.step()

func get_view_rel_pos(screen_pos : Vector2):
	return (screen_pos - Vector2(view_pos)) / view_zoom

func update_border_pos():
	border.scale = Vector2(view_zoom, view_zoom)
	# add border to view pos
	border.position = Vector2i(view_pos) - Vector2i(tile_size * view_zoom)

func update_view_positions():
	var view_size : Vector2 = Vector2(last_size)
	var view_off_ratio : float = VIEW_OFF_RATIO + ((1.0 - VIEW_OFF_RATIO) - (1.0 - VIEW_OFF_RATIO) / view_zoom)
	# clamp view position to prevent going offscreen
	view_pos.x = max(map_size.x * tile_size.x * view_zoom * -view_off_ratio, view_pos.x)
	view_pos.x = min(view_size.x - (map_size.x * tile_size.x * view_zoom * (1.0 - view_off_ratio)), view_pos.x)
	view_pos.y = max(map_size.y * tile_size.y * view_zoom * -view_off_ratio, view_pos.y)
	view_pos.y = min(view_size.y - (map_size.y * tile_size.y * view_zoom * (1.0 - view_off_ratio)), view_pos.y)
	arrow_view.update_zoom_pos(view_zoom, view_pos)
	update_border_pos()

func fit_puzzle_to_screen():
	# set zoom value to a sensible level to fit the puzzle on screen
	var map_px_diff : Vector2i = last_size - (map_size * tile_size)
	view_zoom = Vector2(last_size)[map_px_diff.min_axis_index()] / Vector2(map_size * tile_size)[map_px_diff.min_axis_index()] * VIEW_OFF_RATIO
	view_pos = (Vector2(last_size) - (map_size * tile_size * view_zoom)) / 2

func update_size(new_size : Vector2i):
	var last_ar : Vector2 = Vector2(last_size) / last_size[last_size.min_axis_index()]
	var new_ar : Vector2 = Vector2(new_size) / new_size[new_size.min_axis_index()]
	var center : Vector2 = view_pos + Vector2(map_size * tile_size * view_zoom / 2.0)
	view_pos = (center / last_ar * new_ar) - Vector2(map_size * tile_size * view_zoom / 2.0)
	last_size = new_size

	arrow_view.update_size(last_size)
	var view_size : Vector2 = Vector2(last_size)
	var polygon : PackedVector2Array = blur_viewport.polygon
	polygon[1].x = view_size.x
	polygon[2] = view_size
	polygon[3].y = view_size.y
	blur_viewport.polygon = polygon
	blur_viewport.uv = polygon
	arrow_viewport.polygon = polygon
	arrow_viewport.uv = polygon
	flies_viewport.polygon = polygon
	flies_viewport.uv = polygon
	shade.polygon = polygon

	if menu != null:
		menu.update_size(view_size)

	overlay.size = view_size

	update_view_positions()

func update_zoom(amount : float, pos : Vector2):
	var cursor_pos : Vector2 = get_view_rel_pos(pos)
	view_zoom *= 2 ** amount
	view_zoom = maxf(view_zoom, ZOOM_MIN)
	view_pos = pos - (cursor_pos * view_zoom)
	update_view_positions()

func update_border(size : Vector2i):
	border.clear()
	border.set_cell(Vector2i(0, 0), 0, BORDER_TL, BORDER_TL_ALT)
	border.set_cell(Vector2i(size.x + 1, 0), 0, BORDER_TR, BORDER_TR_ALT)
	border.set_cell(Vector2i(0, size.y + 1), 0, BORDER_BL, BORDER_BL_ALT)
	border.set_cell(Vector2i(size.x + 1, size.y + 1), 0, BORDER_BR, BORDER_BR_ALT)
	border.set_cell(Vector2i(0, size.y + 2), 0, BORDER_SHADOW_BL, BORDER_SHADOW_BL_ALT)
	border.set_cell(Vector2i(size.x + 2, 0), 0, BORDER_SHADOW_TR, BORDER_SHADOW_TR_ALT)
	border.set_cell(Vector2i(size.x + 1, size.y + 2), 0, BORDER_SHADOW_B, BORDER_SHADOW_B_ALT)
	border.set_cell(Vector2i(size.x + 2, size.y + 1), 0, BORDER_SHADOW_R, BORDER_SHADOW_R_ALT)
	border.set_cell(Vector2i(size.x + 2, size.y + 2), 0, BORDER_SHADOW_BR, BORDER_SHADOW_BR_ALT)
	for x in size.x:
		border.set_cell(Vector2i(x + 1, 0), 0, BORDER_T, BORDER_T_ALT)
		border.set_cell(Vector2i(x + 1, size.y + 1), 0, BORDER_B, BORDER_B_ALT)
		border.set_cell(Vector2i(x + 1, size.y + 2), 0, BORDER_SHADOW_B, BORDER_SHADOW_B_ALT)
	for y in size.y:
		border.set_cell(Vector2i(0, y + 1), 0, BORDER_L, BORDER_L_ALT)
		border.set_cell(Vector2i(size.x + 1, y + 1), 0, BORDER_R, BORDER_R_ALT)
		border.set_cell(Vector2i(size.x + 2, y + 1), 0, BORDER_SHADOW_R, BORDER_SHADOW_R_ALT)
	field_bg.position = tile_size
	field_bg.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size.x, 0) * Vector2(tile_size),
		Vector2(size) * Vector2(tile_size),
		Vector2(0, size.y) * Vector2(tile_size)
	])
	field_bg.uv = field_bg.polygon

func update_map_size():
	map_size = arrow_view.get_map_size()
	update_border(map_size)
	fit_puzzle_to_screen()
	update_view_positions()

func set_puzzle_size(size : Vector2i):
	arrow_view.make_map(size)
	tile_size = arrow_view.tile_size
	update_map_size()

func set_data(puzzledata : PuzzleData):
	arrow_view.set_data(puzzledata)
	update_map_size()
	arrow_view.update_astar()

func generate_random(gen_params : RandGenParams):
	gen_params.update_floats()
	arrow_view.generate_random(gen_params)

func ui_event(e : InputEvent, c : Control):
	if menu_display:
		return

	var zoom_rel : float = 0.0
	var zoom_pos : Vector2

	if Menu.e_is_activate(e):
		var snake_idx : int
		snake_idx = arrow_view.pick_snake(get_view_rel_pos(e.position + c.position))
		if editor:
			if action == Action.ADD:
				if snake_idx < 0:
					# only add a snake if no snake was there
					var pos : Vector2i = Vector2i(get_view_rel_pos(e.position + c.position)) / tile_size
					# point it towards the outside
					var towards : Side = arrow_view.get_side(pos)
					arrow_view.add_snake(pos, 1, towards)
				else:
					# select clicked snakes in add mode anyway
					arrow_view.select_snake(snake_idx)
			elif action == Action.SPLIT:
				if snake_idx >= 0:
					var pos : Vector2i = Vector2i(get_view_rel_pos(e.position + c.position)) / tile_size
					arrow_view.split_selected_snake(pos)
			elif action == Action.JOIN:
				if snake_idx >= 0:
					arrow_view.join_selected_snake(snake_idx)
			elif action == Action.FLIES:
				if snake_idx < 0:
					var pos : Vector2i = Vector2i(get_view_rel_pos(e.position + c.position)) / tile_size
					arrow_view.place_fly(pos)
			else:
				# Default action: select
				arrow_view.select_snake(snake_idx)
		else:
			if arrow_view.last_snake >= 0 and snake_idx == arrow_view.last_snake:
				arrow_view.activate_snake()
			else:
				arrow_view.select_snake(snake_idx)
	elif Menu.e_is_dragging(e):
		view_pos += e.relative
		last_drag = Time.get_ticks_msec()
		update_view_positions()
	elif e is InputEventMouseButton:
		var mouse_e : InputEventMouseButton = e as InputEventMouseButton
		zoom_pos = mouse_e.position + c.position
		if mouse_e.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_rel = 1.0
			if mouse_e.factor != 0.0:
				zoom_rel = mouse_e.factor
			zoom_rel /= ZOOM_OCTAVE_DIV
		elif mouse_e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_rel = -1.0
			if mouse_e.factor != 0.0:
				zoom_rel = -mouse_e.factor
			zoom_rel /= ZOOM_OCTAVE_DIV
	elif e is InputEventMagnifyGesture:
		var gesture_e : InputEventMagnifyGesture = e as InputEventMagnifyGesture
		zoom_pos = gesture_e.position + c.position
		zoom_rel = gesture_e.factor

	if zoom_rel != 0.0:
		update_zoom(zoom_rel, zoom_pos)
		update_view_positions()

func menu_button_event(e : InputEvent, c : Control) -> void:
	get_viewport().set_input_as_handled()
	if Menu.e_is_activate(e):
		for item in ui_menu.get_children():
			if c == item:
				match c.name:
					"Menu":
						if editor:
							editor_menu()
						else:
							ingame_menu()
					"Mode":
						editor = not editor
					"Delete":
						arrow_view.delete_selected_snake()
					"Grow":
						grow = not grow
					"Reverse":
						arrow_view.reverse_selected_snake()
					"Action":
						action = ((action + 1) % Action.MAX) as Action
						$"Overlay/Menu/Action/Margins/Text".text = ACTION_NAMES[action]
		for item in d_pad.get_children():
			if c == item:
				match c.name:
					"Up":
						if grow:
							arrow_view.grow_selected_snake(SIDE_TOP)
						else:
							arrow_view.move_selected_snake(SIDE_TOP)
					"Down":
						if grow:
							arrow_view.grow_selected_snake(SIDE_BOTTOM)
						else:
							arrow_view.move_selected_snake(SIDE_BOTTOM)
					"Left":
						if grow:
							arrow_view.grow_selected_snake(SIDE_LEFT)
						else:
							arrow_view.move_selected_snake(SIDE_LEFT)
					"Right":
						if grow:
							arrow_view.grow_selected_snake(SIDE_RIGHT)
						else:
							arrow_view.move_selected_snake(SIDE_RIGHT)

func update_menu(title : String, items : Array[MenuItemDesc]):
	menu.set_heading(title)
	menu.set_items(items)
	menu.update_size()

func make_menu():
	# bit more involved because the menu is only loaded when needed
	shade.visible = true
	overlay.visible = false
	menu_display = true
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)
	menu.update_size(last_size)

func ingame_menu():
	make_menu()
	update_menu("Game Menu", menu_ingame)

var menu_ingame : Array[MenuItemDesc] = [
	MenuDoubleSelectionDesc.new(return_to_game, return_to_menu, "Return", "Main Menu")
]

func return_to_game():
	menu.destroy()
	menu_display = false
	overlay.visible = true
	shade.visible = false

func return_to_menu():
	menu.destroy()
	arrow_view.cleanup()
	puzzle_finished.emit()

func puzzle_clear():
	if play_mode:
		endgame_menu()
	else:
		arrow_view.clear_offscreen_snake()
		editor = true

func endgame_menu():
	make_menu()
	update_menu("Game Over", menu_endgame)

var menu_endgame : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_menu, "Return to Main Menu")
]

func editor_menu():
	make_menu()
	do_editor_menu()

func do_editor_menu():
	update_menu("Editor Menu", menu_editor)

var menu_editor : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(file_menu, "File"),
	MenuSelectionDesc.new(clear_menu, "Clear"),
	MenuSelectionDesc.new(random_menu, "Random"),
	MenuSelectionDesc.new(resize_menu, "Resize"),
	MenuDoubleSelectionDesc.new(return_to_game, return_to_menu, "Return", "Main Menu")
]

func file_menu():
	browser = FileBrowser.new(menu,
							  file_name,
							  select_return,
							  set_file_name,
							  save_file,
							  load_file,
							  arrow_view.get_data())
	browser.display_menu()

func set_file_name(fn : String):
	file_name = fn

func save_file():
	# nothing to do, just succeeded
	return_to_game()

func load_file(puzzledata : PuzzleData):
	arrow_view.select_snake(-1)
	set_data(puzzledata)
	puzzledata.free()
	return_to_game()

func select_return():
	do_editor_menu()

func resize_menu():
	menu_resize[0].value = 0
	menu_resize[1].value = 0
	menu_resize[2].value = map_size.x
	menu_resize[3].value = map_size.y
	update_menu("Resize", menu_resize)

# 255 is a position tag for snake list termination
var menu_resize : Array[MenuItemDesc] = [
	MenuValueDesc.new(0, -254, 254, null, "Left"),
	MenuValueDesc.new(0, -254, 254, null, "Top"),
	MenuValueDesc.new(0, 1, 254, null, "New Width"),
	MenuValueDesc.new(0, 1, 254, null, "New Height"),
	MenuDoubleSelectionDesc.new(do_editor_menu, resize, "Return", "Resize")
]

func resize():
	var new_bounds : Rect2i = Rect2i(Vector2i(menu_resize[0].value, menu_resize[1].value),
									 Vector2i(menu_resize[2].value, menu_resize[3].value))
	arrow_view.resize_puzzle(new_bounds)
	update_map_size()
	return_to_game()

func clear_menu():
	update_menu("Clear?", menu_clear)

var menu_clear : Array[MenuItemDesc] = [
	MenuDoubleSelectionDesc.new(do_editor_menu, do_clear, "No", "Yes")
]

func do_clear():
	arrow_view.clear()
	update_map_size()
	return_to_game()

func random_menu():
	menu_random[0].value = game.gen_params.min_length
	menu_random[1].value = game.gen_params.max_length
	menu_advanced[0].value = game.gen_params.base_chance_num
	menu_advanced[1].value = game.gen_params.base_chance_den
	menu_advanced[2].value = game.gen_params.chance_mult_num
	menu_advanced[3].value = game.gen_params.chance_mult_den
	menu_advanced[4].value = game.gen_params.forward_pref_num
	menu_advanced[5].value = game.gen_params.forward_pref_den
	menu_advanced[6].value = game.gen_params.along_snake_pref_num
	menu_advanced[7].value = game.gen_params.along_snake_pref_den
	menu_advanced[8].value = game.gen_params.quadrant_pref_num
	menu_advanced[9].value = game.gen_params.quadrant_pref_den
	menu_advanced[10].value = game.gen_params.along_edge_pref_num
	menu_advanced[11].value = game.gen_params.along_edge_pref_den
	do_random_menu()

func do_random_menu():
	update_menu("Randomize", menu_random)

var menu_random : Array[MenuItemDesc] = [
	MenuValueDesc.new(MIN_LENGTH, MIN_LENGTH, MAX_LENGTH, min_length_change, "Min Length"),
	MenuValueDesc.new(MIN_LENGTH, MIN_LENGTH, MAX_LENGTH, max_length_change, "Max Length"),
	MenuSelectionDesc.new(advanced_menu, "Advanced >>"),
	MenuDoubleSelectionDesc.new(do_editor_menu, do_random, "Cancel", "Go"),
]

func min_length_change(val : int) -> int:
	game.gen_params.min_length = min(val, game.gen_params.max_length)
	return game.gen_params.min_length

func max_length_change(val : int) -> int:
	game.gen_params.max_length = max(val, game.gen_params.min_length)
	return game.gen_params.max_length

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
	game.gen_params.base_chance_num = menu_advanced[0].value
	game.gen_params.base_chance_den = menu_advanced[1].value
	game.gen_params.chance_mult_num = menu_advanced[2].value
	game.gen_params.chance_mult_den = menu_advanced[3].value
	game.gen_params.forward_pref_num = menu_advanced[4].value
	game.gen_params.forward_pref_den = menu_advanced[5].value
	game.gen_params.along_snake_pref_num = menu_advanced[6].value
	game.gen_params.along_snake_pref_den = menu_advanced[7].value
	game.gen_params.quadrant_pref_num = menu_advanced[8].value
	game.gen_params.quadrant_pref_den = menu_advanced[9].value
	game.gen_params.along_edge_pref_num = menu_advanced[10].value
	game.gen_params.along_edge_pref_den = menu_advanced[11].value
	generate_random(game.gen_params)
	return_to_game()
