class_name Menu
extends Control

const MAX_SEPARATION : int = 20
const MIN_SEPARATION : int = 2

const CHANGE_PERIODS : Array[float] = [
	0.2, 0.08, 0.03
]

@onready var container : VBoxContainer = $"Container"
@onready var filler : Control = $"Container/Heading Filler"

var header_label_settings : LabelSettings = load("res://DefaultLabel.tres")
var default_label_size : int = 0
var title_control : Label

var menu_descs : Dictionary[MenuItem, MenuItemDesc] = {}
var menu_items : Dictionary[Control, MenuItem] = {}
var last_change : MenuValue = null
var last_change_time : float = 0.0
var last_value_change_time : float = 0.0
var change_mult : int = 0

var size_changed : bool = false
var size_seek : int = 0

func _ready():
	default_label_size = header_label_settings.font_size
	title_control = Label.new()
	title_control.label_settings = header_label_settings
	title_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta : float):
	# ugly hacks to make the menu try to fit the screen
	var rect : Vector2 = container.get_rect().size
	var screen_rect : Vector2 = get_viewport_rect().size
	var header : Control = container.get_child(0)
	rect.y -= header.get_rect().size.y
	if header is Label:
		# total items (descs + title) over space taken by everything but the title
		var proportion : float = float(len(menu_descs)) / float(len(menu_descs) + 1)
		screen_rect.y *= proportion
	else:
		screen_rect.y /= 2.0

	if size_changed:
		if rect.x > screen_rect.x or rect.y > screen_rect.y:
			# if any axis is larger, try to shrink
			size_seek = -1
		elif rect.x < screen_rect.x and rect.y < screen_rect.y:
			# if both axes are smaller, try to grow
			size_seek = 1
		size_changed = false

	var separation : int
	if size_seek < 0:
		if rect.x > screen_rect.x or rect.y > screen_rect.y:
			# if any axis is larger, try to shrink
			separation = container.get_theme_constant(&'separation')
			if separation > MIN_SEPARATION:
				separation -= 1
				container.add_theme_constant_override(&'separation', separation)
			else:
				header_label_settings.font_size -= 1
		else:
			size_seek = 0
	elif size_seek > 0:
		if rect.x < screen_rect.x and rect.y < screen_rect.y:
			# if both axes are smaller, try to grow
			separation = container.get_theme_constant(&'separation')
			if separation < MAX_SEPARATION:
				separation += 1
				container.add_theme_constant_override(&'separation', separation)
			else:
				header_label_settings.font_size += 1
		else:
			size_seek = 0

	if last_change != null:
		last_change_time += delta

		var period : float = CHANGE_PERIODS[min(len(CHANGE_PERIODS) - 1, int(last_change_time))]
		if last_change_time - last_value_change_time >= period:
			last_value_change_time = last_change_time
			last_change.change_value(change_mult)

func clear_last_press():
		last_change = null

func _input(e : InputEvent):
	if e is InputEventScreenTouch and \
	   e.pressed == false:
		clear_last_press()

func update_heading_scale():
	# set some reasonable proportion for the heading
	var header = container.get_child(0)
	if header is Label:
		header.size_flags_stretch_ratio = 1.0
	else:
		header.size_flags_stretch_ratio = len(menu_descs)

func clear_size():
	size_changed = true

func set_heading(c):
	if c is String:
		title_control.text = c
		c = title_control
	var orig_c : Control = container.get_child(0)
	container.remove_child(orig_c)
	container.add_child(c)
	container.move_child(c, 0)
	c.size_flags_vertical |= orig_c.size_flags_vertical
	if orig_c == filler:
		orig_c.queue_free()
		filler = null
	update_heading_scale()
	clear_size()

func set_items(items : Array[MenuItemDesc]):
	# clear any existing items
	for item in menu_descs.keys():
		container.remove_child(item)
		item.queue_free()
	menu_items = {}
	menu_descs = {}

	for item in items:
		var menu_item : MenuItem = item.setup(container, self)
		container.move_child(menu_item, -2)
		menu_item.desc = item
		menu_item.label = item.label
		menu_descs[menu_item] = item

	update_heading_scale()
	clear_size()

static func e_is_activate(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == false:
		return true
	return false

static func e_is_pressed(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == true:
		return true
	return false

func set_last_change(c : Control, mult : int):
	last_change_time = 0.0
	last_value_change_time = 0.0
	last_change = c
	change_mult = mult
	last_change.change_value(change_mult)

func update_size(new_size : Vector2i):
	size = new_size
	clear_size()

func destroy():
	header_label_settings.font_size = default_label_size
	queue_free()
