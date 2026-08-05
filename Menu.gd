class_name Menu
extends Control

signal font_size_changed(amount : int)

const MIN_FONT_SIZE : int = 8

const CHANGE_PERIODS : Array[float] = [
	0.2, 0.08, 0.03
]

@onready var container : VBoxContainer = $"Container"
@onready var filler : Control = $"Container/Heading Filler"

static var header_label_settings : LabelSettings = load("res://DefaultLabel.tres")
var default_label_size : int = header_label_settings.font_size
var title_control : Label

var menu_descs : Dictionary[MenuItem, MenuItemDesc] = {}
var last_change : MenuValue = null
var last_change_time : float = 0.0
var last_value_change_time : float = 0.0
var change_mult : int = 0

var last_sizes : Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var last_screen_size : Vector2i = Vector2i.ZERO
var last_font_sizes : Array[int] = [0, header_label_settings.font_size]
var size_seek : int = 0

func _ready():
	title_control = Label.new()
	title_control.label_settings = header_label_settings
	title_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func change_font_size(amount : int):
	if header_label_settings.font_size + amount == last_font_sizes[0]:
		size_seek = 0
	else:
		header_label_settings.font_size += amount
		font_size_changed.emit(header_label_settings.font_size)
		last_font_sizes[0] = last_font_sizes[1]
		last_font_sizes[1] = header_label_settings.font_size

func clear_last_font_size():
	last_font_sizes[0] = 0

func _process(delta : float):
	# ugly hacks to make the menu try to fit the screen
	var rect : Vector2 = container.get_rect().size
	var screen_rect : Vector2i = size
	var header : Control = container.get_child(0)
	rect.y -= header.get_rect().size.y
	if header is Label:
		# total items (descs + title) over space taken by everything but the title
		var proportion : float = float(len(menu_descs)) / float(len(menu_descs) + 1)
		screen_rect.y *= proportion
	else:
		screen_rect.y /= 2.0

	if screen_rect != last_screen_size or \
	   rect != last_sizes[0]:
		if rect.x > screen_rect.x or rect.y > screen_rect.y:
			# if any axis is larger, try to shrink
			size_seek = -1
			clear_last_font_size()
		elif rect.x < screen_rect.x and rect.y < screen_rect.y:
			# if both axes are smaller, try to grow
			size_seek = 1
			clear_last_font_size()
		last_screen_size = screen_rect
		last_sizes[0] = last_sizes[1]
		last_sizes[1] = rect

	if size_seek < 0:
		if rect.x > screen_rect.x or rect.y > screen_rect.y:
			# if any axis is larger, try to shrink
			change_font_size(-1)
		else:
			size_seek = 0
	elif size_seek > 0:
		if rect.x < screen_rect.x and rect.y < screen_rect.y:
			# if both axes are smaller, try to grow
			change_font_size(1)
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
	clear_last_font_size()
	update_heading_scale()

func set_items(items : Array[MenuItemDesc]):
	# clear any existing items
	for item in menu_descs.keys():
		container.remove_child(item)
		item.queue_free()
	menu_descs = {}

	for item in items:
		var menu_item : MenuItem = item.setup(container, self)
		container.move_child(menu_item, -2)
		menu_item.desc = item
		menu_item.label = item.label
		menu_descs[menu_item] = item

	# don't change font size, just signal
	change_font_size(0)
	clear_last_font_size()
	update_heading_scale()

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

func destroy():
	header_label_settings.font_size = default_label_size
	queue_free()
