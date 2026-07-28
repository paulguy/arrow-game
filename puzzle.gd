extends Node2D

signal puzzle_finished

const DRAG_DELAY_MS : float = 200
const VIEW_OFF_RATIO : float = 0.8
const ZOOM_OCTAVE_DIV : float = 12.0
const ZOOM_MIN : float = 1.0/8.0

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

@onready var border : TileMapLayer = $"Border"
@onready var field_bg : Polygon2D = $"Border/Field Background"
@onready var blur_viewport : Polygon2D = $"Arrow Viewport Blur"
@onready var arrow_viewport : Polygon2D = $"Arrow Viewport View"
@onready var flies_viewport : Polygon2D = $"Flies Viewport View"
@onready var back_button : Control = $"Left Menu/Back"
@onready var shade : Polygon2D = $"Shade"

var arrow_view : ArrowView = null
var tile_size : Vector2i
var map_size : Vector2i
var view_pos : Vector2 = Vector2.ZERO
var view_zoom : float = 0.0
var last_drag : int = 0
var last_size : Vector2i
var menu_display : bool = false
var menu : Control = null
var play_mode : bool = true
var editor : bool = false:
	set(mode):
		if mode:
			if not editor:
				$"Left Menu/Add".visible = true
				$"Left Menu/Delete".visible = true
				editor = true
		else:
			if editor:
				$"Left Menu/Add".visible = false
				$"Left Menu/Delete".visible = false
				editor = false

func _ready():
	arrow_view = load("res://ArrowView.tscn").instantiate()
	add_child(arrow_view)
	move_child(arrow_view, border.get_index() + 1)

	$"Left Menu/Back/Margins/Text".text = "Menu"
	if not play_mode:
		$"Left Menu/Back/Margins/Mode".text = "Mode"
		$"Left Menu/Back/Margins/Mode".visible = true
		$"Left Menu/Back/Margins/Add".text = "Add"
		$"Left Menu/Back/Margins/Delete".text = "Delete"
	else:
		arrow_view.connect(&"puzzle_finished", endgame_menu)

	var viewport_texture : ViewportTexture = arrow_view.get_viewport_texture()
	blur_viewport.texture = viewport_texture
	arrow_viewport.texture = viewport_texture
	flies_viewport.texture = arrow_view.get_flies_viewport_texture()

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

	if view_zoom == 0.0:
		# set zoom value to a sensible level to fit the puzzle on screen
		var map_px_diff : Vector2i = last_size - (map_size * tile_size)
		view_zoom = Vector2(last_size)[map_px_diff.min_axis_index()] / Vector2(map_size * tile_size)[map_px_diff.min_axis_index()] * VIEW_OFF_RATIO
		view_pos = (Vector2(last_size) - (map_size * tile_size * view_zoom)) / 2

	if menu != null:
		menu.size = view_size
		menu.update_size(view_size)

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

func set_puzzle_size(size : Vector2i):
	arrow_view.make_map(size)
	map_size = arrow_view.get_map_size()
	tile_size = arrow_view.tile_size
	update_border(size)

func generate_random(gen_params : RandGenParams):
	arrow_view.generate_random(gen_params)

func _input(e : InputEvent):
	if menu_display:
		return

	var zoom_rel : float = 0.0
	var zoom_pos : Vector2

	if e is InputEventScreenTouch:
		var touch_e : InputEventScreenTouch = e as InputEventScreenTouch
		if touch_e.pressed:
			arrow_view.click_snake(get_view_rel_pos(touch_e.position))
	elif e is InputEventScreenDrag:
		var drag_e : InputEventScreenDrag = e as InputEventScreenDrag
		view_pos += drag_e.relative
		last_drag = Time.get_ticks_msec()
		update_view_positions()
	elif e is InputEventMouseButton:
		var mouse_e : InputEventMouseButton = e as InputEventMouseButton
		zoom_pos = mouse_e.position
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
		zoom_pos = gesture_e.position
		zoom_rel = gesture_e.factor

	if zoom_rel != 0.0:
		update_zoom(zoom_rel, zoom_pos)
		update_view_positions()

func e_is_activate(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == false:
		return true
	return false

func menu_button_event(e: InputEvent) -> void:
	if e_is_activate(e):
		ingame_menu()

func make_menu(title : String, items : Array[MenuItemDesc]):
	# bit more involved because the menu is only loaded when needed
	shade.visible = true
	back_button.visible = false
	menu_display = true
	menu = load("res://Menu.tscn").instantiate()
	add_child(menu)
	menu.size = last_size
	menu.update_size(last_size)
	menu.set_heading(title)
	menu.set_items(items)
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)

func ingame_menu():
	make_menu("Game Menu", menu_ingame)

var menu_ingame : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_game, "Return to Game"),
	MenuSelectionDesc.new(return_to_menu, "Return to Main Menu")
]

func return_to_game():
	menu.destroy()
	menu_display = false
	back_button.visible = true
	shade.visible = false

func return_to_menu():
	menu.destroy()
	puzzle_finished.emit()

func endgame_menu():
	make_menu("Game Over", menu_endgame)

var menu_endgame : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_menu, "Return to Main Menu")
]
