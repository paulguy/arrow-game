extends Node2D

signal puzzle_finished

const FILE_EXTENSION : String = "arrows"

const DRAG_DELAY_MS : float = 200
const VIEW_OFF_RATIO : float = 0.8
const ZOOM_OCTAVE_DIV : float = 12.0
const ZOOM_MIN : float = 1.0/8.0

const BUTTON_SHADE_ALPHA : float = 0.5

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

@onready var border : TileMapLayer = $"Border"
@onready var field_bg : Polygon2D = $"Border/Field Background"
@onready var blur_viewport : Polygon2D = $"Arrow Viewport Blur"
@onready var arrow_viewport : Polygon2D = $"Arrow Viewport View"
@onready var flies_viewport : Polygon2D = $"Flies Viewport View"
@onready var overlay : Control = $"Overlay"
@onready var ui_menu : Control = $"Overlay/Menu"
@onready var d_pad : Control = $"Overlay/D-Pad"
@onready var shade : Polygon2D = $"Shade"

var arrow_view : ArrowView = null
var tile_size : Vector2i
var map_size : Vector2i
var view_pos : Vector2 = Vector2.ZERO
var view_zoom : float = 1.0
var last_drag : int = 0
var last_size : Vector2i
var menu_display : bool = false
var menu : Control = null
var puzzle_data : PuzzleData = null
# whether this was started from a new game or the editor option
var play_mode : bool = true
# whether the editor should display (or test mode)
var editor : bool = false:
	set(mode):
		if mode:
			if not editor:
				arrow_view.select_snake(-1)
				# restore the list of snakes
				if puzzle_data != null:
					arrow_view.set_data(puzzle_data)
					puzzle_data.free()
					puzzle_data = null
				$"Overlay/Menu/Mode/Margins/Text".text = "Test"
				for item in EDITOR_BUTTONS:
					get_node(NodePath("Overlay/Menu/%s" % item)).visible = true
				$"Overlay/D-Pad".visible = true
		else:
			if editor:
				arrow_view.select_snake(-1)
				# backup the list of snakes
				puzzle_data = arrow_view.get_data()
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
var select_return_func : Callable = return_to_game
var menu_select : Array[MenuItemDesc]

func fix_file_name(fn : String) -> String:
	if not fn.begins_with("user://") or \
	   not fn.begins_with("res://"):
		fn = "user://%s" % fn

	if not fn.ends_with(".%s" % FILE_EXTENSION):
		fn = "%s.%s" % [fn, FILE_EXTENSION]

	return fn

func _ready():
	arrow_view = load("res://ArrowView.tscn").instantiate()
	add_child(arrow_view)
	move_child(arrow_view, border.get_index() + 1)

	file_name = fix_file_name(file_name)

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
		#menu.size = view_size
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

func generate_random(gen_params : RandGenParams):
	arrow_view.generate_random(gen_params)

func ui_event(e : InputEvent, c : Control):
	if menu_display:
		return

	get_viewport().set_input_as_handled()

	var zoom_rel : float = 0.0
	var zoom_pos : Vector2

	if e is InputEventScreenTouch:
		var touch_e : InputEventScreenTouch = e as InputEventScreenTouch
		if touch_e.pressed:
			var snake_idx : int
			snake_idx = arrow_view.pick_snake(get_view_rel_pos(touch_e.position + c.position))
			if editor:
				if action == Action.ADD:
					if snake_idx < 0:
						# only add a snake if no snake was there
						var pos : Vector2i = Vector2i(get_view_rel_pos(touch_e.position + c.position)) / tile_size
						# point it towards the outside
						var towards : Side = arrow_view.get_side(pos)
						arrow_view.add_snake(pos, 1, towards)
					else:
						# select clicked snakes in add mode anyway
						arrow_view.select_snake(snake_idx)
				elif action == Action.SPLIT:
					if snake_idx >= 0:
						var pos : Vector2i = Vector2i(get_view_rel_pos(touch_e.position + c.position)) / tile_size
						arrow_view.split_selected_snake(pos)
				elif action == Action.JOIN:
					if snake_idx >= 0:
						arrow_view.join_selected_snake(snake_idx)
				elif action == Action.FLIES:
					if snake_idx < 0:
						var pos : Vector2i = Vector2i(get_view_rel_pos(touch_e.position + c.position)) / tile_size
						arrow_view.place_fly(pos)
				else:
					# Default action: select
					arrow_view.select_snake(snake_idx)
			else:
				if arrow_view.last_snake >= 0 and snake_idx == arrow_view.last_snake:
					arrow_view.activate_snake()
				else:
					arrow_view.select_snake(snake_idx)
	elif e is InputEventScreenDrag:
		var drag_e : InputEventScreenDrag = e as InputEventScreenDrag
		view_pos += drag_e.relative
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

func e_is_activate(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == false:
		return true
	return false

func menu_button_event(e : InputEvent, c : Control) -> void:
	get_viewport().set_input_as_handled()
	if e_is_activate(e):
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
	menu.update_size(last_size)

func make_menu(title : String, items : Array[MenuItemDesc]):
	# bit more involved because the menu is only loaded when needed
	shade.visible = true
	overlay.visible = false
	menu_display = true
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)
	update_menu(title, items)

func ingame_menu():
	make_menu("Game Menu", menu_ingame)

var menu_ingame : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_game, "Return to Game"),
	MenuSelectionDesc.new(return_to_menu, "Return to Menu")
]

func return_to_game():
	menu.destroy()
	menu_display = false
	overlay.visible = true
	shade.visible = false

func return_to_menu():
	menu.destroy()
	puzzle_finished.emit()

func puzzle_clear():
	if play_mode:
		endgame_menu()
	else:
		arrow_view.clear_offscreen_snake()
		editor = true

func endgame_menu():
	make_menu("Game Over", menu_endgame)

var menu_endgame : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_menu, "Return to Main Menu")
]

func editor_menu():
	make_menu("Editor Menu", menu_editor)

var menu_editor : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(file_menu, "File"),
	MenuSelectionDesc.new(resize_menu, "Resize"),
	MenuSelectionDesc.new(return_to_game, "Return to Editor"),
	MenuSelectionDesc.new(return_to_menu, "Return to Main Menu")
]

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
	MenuSelectionDesc.new(resize, "Resize"),
	MenuSelectionDesc.new(return_to_game, "Return to Editor")
]

func resize():
	var new_bounds : Rect2i = Rect2i(Vector2i(menu_resize[0].value, menu_resize[1].value),
									 Vector2i(menu_resize[2].value, menu_resize[3].value))
	arrow_view.resize_puzzle(new_bounds)
	update_map_size()
	return_to_game()

func file_menu():
	menu_file[0].text = file_name
	update_menu("File", menu_file)

var menu_file : Array[MenuItemDesc] = [
	MenuTextEntryDesc.new(file_name, set_file_name, "Name"),
	MenuSelectionDesc.new(select_file, "Browse"),
	MenuSelectionDesc.new(save_file, "Save"),
	MenuSelectionDesc.new(load_file, "Load"),
	MenuSelectionDesc.new(return_to_game, "Cancel"),
]

func set_file_name(fn : String):
	fn = fix_file_name(fn)
	file_name = fn

func save_file():
	var puzzledata : PuzzleData = arrow_view.get_data()
	var file : FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_buffer(puzzledata.serialize())
	file.close()
	puzzledata.free()
	return_to_game()

func load_file():
	arrow_view.select_snake(-1)
	var puzzledata : PuzzleData = PuzzleData.deserialize(FileAccess.get_file_as_bytes(file_name))
	arrow_view.set_data(puzzledata)
	update_map_size()
	return_to_game()

func select_file():
	menu_select = []
	for item in menu_select_template:
		menu_select.append(item)

	var puzzledata : PuzzleData
	var image : Image
	var desc : MenuImageSelectionDesc

	var dir : DirAccess = DirAccess.open("user://")
	dir.list_dir_begin()
	var fn : String = dir.get_next()
	while fn != "":
		if fn.get_extension() == FILE_EXTENSION:
			puzzledata = PuzzleData.deserialize(FileAccess.get_file_as_bytes("user://%s" % fn))
			image = puzzledata.get_preview()
			desc = MenuImageSelectionDesc.new(image, "user://%s" % fn, select_file_item, fn)
			menu_select.push_front(desc)
		fn = dir.get_next()
	select_return_func = file_menu
	update_menu("Browse", menu_select)
	menu.scrollable = true

var menu_select_template : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(select_return, "Cancel")
]

func free_menu_select():
	for item in menu_select:
		if item not in menu_select_template:
			item.free()
	menu_select = []

func select_return():
	free_menu_select()
	menu.scrollable = false
	select_return_func.call()

func select_file_item(key : String):
	file_name = key
	select_return()
