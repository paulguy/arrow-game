extends Control

const MAX_SEPARATION : int = 20
const MIN_SEPARATION : int = 2

@onready var container : VBoxContainer = $"Container"
@onready var filler : Control = $"Container/Heading Filler"

var header_label_settings : LabelSettings = load("res://DefaultLabel.tres")
var default_label_size : int = 0
var title_control : Label

var menu_descs : Dictionary[MenuItem, MenuItemDesc] = {}
var menu_items : Dictionary[Control, MenuItem] = {}
var last_change : MenuValue = null
var last_change_time : float = 0.0
var change_mult : int = 0

var size_changed : bool = false
var size_seek : int = 0

func _ready():
	default_label_size = header_label_settings.font_size
	title_control = Label.new()
	title_control.label_settings = header_label_settings
	title_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(_delta : float):
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
		if size_seek == 0:
			if rect.x > screen_rect.x or rect.y > screen_rect.y:
				# if any axis is larger, try to shrink
				size_seek = -1
			elif rect.x < screen_rect.x and rect.y < screen_rect.y:
				# if both axes are smaller, try to grow
				size_seek = 1
		size_changed = false

	var separation : int
	if size_seek < 0:
		prints(rect, screen_rect)
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
		var desc : MenuValueDesc = menu_descs[last_change as MenuItem]
		var hold_time : float = (Time.get_ticks_usec() / 1000000.0) - last_change_time + 1.0
		last_change.value = max(last_change.value + int(hold_time) * change_mult, desc.min_value)
		if desc.change_func.is_valid():
			last_change.value = desc.change_func.call(last_change.value)
		desc.value = last_change.value

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
		var menu_item : MenuItem
		if item is MenuSelectionDesc:
			var menu_selection : MenuSelection = load("res://MenuSelection.tscn").instantiate()
			container.add_child(menu_selection)
			menu_selection.clickable.connect(&"gui_input",
											 menu_select,
											 ConnectFlags.CONNECT_APPEND_SOURCE_OBJECT)
			menu_items[menu_selection.clickable] = menu_selection
			menu_item = menu_selection
		elif item is MenuValueDesc:
			var menu_value : MenuValue = load("res://MenuValue.tscn").instantiate()
			container.add_child(menu_value)
			menu_value.value = item.value
			menu_value.clickable_dec.connect(&"gui_input",
											 menu_dec,
											 ConnectFlags.CONNECT_APPEND_SOURCE_OBJECT)
			menu_value.clickable_inc.connect(&"gui_input",
											 menu_inc,
											 ConnectFlags.CONNECT_APPEND_SOURCE_OBJECT)
			menu_items[menu_value.clickable_dec] = menu_value
			menu_items[menu_value.clickable_inc] = menu_value
			menu_item = menu_value
		container.move_child(menu_item, -2)
		menu_item.label = item.label
		menu_descs[menu_item] = item

	update_heading_scale()
	clear_size()

func e_is_activate(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == false:
		return true
	return false

func e_is_pressed(e : InputEvent) -> bool:
	if e is InputEventScreenTouch and \
	   e.pressed == true:
		return true
	return false

func menu_select(e : InputEvent, c : Control):
	if e_is_activate(e):
		clear_last_press()
		var item : MenuSelection = menu_items[c]
		var desc : MenuSelectionDesc = menu_descs[item as MenuItem]
		desc.activate_func.call()

func menu_change(c : Control):
	var item : MenuValue = menu_items[c]
	last_change_time = Time.get_ticks_usec() / 1000000.0
	last_change = menu_items[c]

# TODO: allow holding with inertia
func menu_dec(e : InputEvent, c : Control):
	if e_is_pressed(e):
		change_mult = -1
		menu_change(c)

func menu_inc(e : InputEvent, c : Control):
	if e_is_pressed(e):
		change_mult = 1
		menu_change(c)

func update_size(new_size : Vector2i):
	size = new_size
	clear_size()

func destroy():
	header_label_settings.font_size = default_label_size
	queue_free()
