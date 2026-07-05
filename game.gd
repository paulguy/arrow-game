extends Node2D

const DEFAULT_SIZE : Vector2i = Vector2i(120, 120)
const DRAG_DELAY_MS : float = 200
const VIEW_OFF_RATIO : float = 0.2

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

@onready var arrow_view : Node2D = $"ArrowView"
@onready var border : TileMapLayer = $"Border"
@onready var field_bg : Polygon2D = $"Border/Field Background"

var tile_size : Vector2
var map_size : Vector2i
var view_pos : Vector2i = Vector2i.ZERO
var last_drag : int = 0

func update_border_pos():
	border.position = (get_viewport_rect().size - (Vector2(map_size + Vector2i(2, 2)) * tile_size)) / 2.0 + Vector2(view_pos)

func setup_map(size : Vector2i):
	#arrow_view.set_view(border.position)
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
		Vector2(size.x, 0) * tile_size,
		Vector2(size) * tile_size,
		Vector2(0, size.y) * tile_size
	])
	arrow_view.make_map(size)
	map_size = arrow_view.arrow_map.size
	update_border_pos()

func _ready():
	tile_size = Vector2(border.tile_set.tile_size)
	var viewport_texture : ViewportTexture = arrow_view.get_viewport_texture()
	$"Arrow Viewport Blur".texture = viewport_texture
	$"Arrow Viewport View".texture = viewport_texture
	$"Flies Viewport View".texture = arrow_view.get_flies_viewport_texture()
	setup_map(DEFAULT_SIZE)

func _input(e : InputEvent):
	if Time.get_ticks_msec() - last_drag > DRAG_DELAY_MS and e is InputEventMouseButton:
		var mouse_e : InputEventMouseButton = e as InputEventMouseButton
		if not mouse_e.pressed and mouse_e.button_index == MOUSE_BUTTON_LEFT:
			arrow_view.click_snake(get_global_mouse_position() - border.position - tile_size)
	elif e is InputEventScreenDrag:
		var drag_e : InputEventScreenDrag = e as InputEventScreenDrag
		view_pos += Vector2i(drag_e.relative)
		var view_size : Vector2i = get_viewport_rect().size
		var overhangs : Vector2i = ((map_size * Vector2i(tile_size)) - view_size) / 2
		view_pos.x = min((map_size.x * tile_size.x) - overhangs.x - (view_size.x * VIEW_OFF_RATIO), view_pos.x)
		view_pos.x = max(-(map_size.x * tile_size.x) + overhangs.x + (view_size.x * VIEW_OFF_RATIO), view_pos.x)
		view_pos.y = min((map_size.y * tile_size.y) - overhangs.y - (view_size.y * VIEW_OFF_RATIO), view_pos.y)
		view_pos.y = max(-(map_size.y * tile_size.y) + overhangs.y + (view_size.y * VIEW_OFF_RATIO), view_pos.y)
		update_border_pos()
		arrow_view.set_view(view_pos)
		last_drag = Time.get_ticks_msec()
