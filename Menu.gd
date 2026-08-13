class_name Menu
extends ScrollContainer

signal font_size_changed(amount : int)

const MIN_FONT_SIZE : int = 8

const CHANGE_PERIODS : Array[float] = [
	0.2, 0.08, 0.03
]

@onready var container : VBoxContainer = $"Container"
@onready var filler : Control = $"Container/Heading Filler"

var last_size : Vector2i = Vector2i.ZERO

static var header_label_settings : LabelSettings = load("res://DefaultLabel.tres")
var default_label_size : int = header_label_settings.font_size
var title_control : Label

var font_size : float = float(header_label_settings.font_size)
var last_rects : Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var last_font_change : float = 0.0

var menu_descs : Dictionary[MenuItem, MenuItemDesc] = {}
var menu_items : Array[MenuItem] = []
var last_change : MenuValue = null
var last_change_time : float = 0.0
var last_value_change_time : float = 0.0
var change_mult : int = 0
var scrollable : bool

func _ready():
	title_control = Label.new()
	title_control.label_settings = header_label_settings
	title_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func change_font_size(amount : float):
	last_font_change = amount
	font_size *= pow(1.2, amount)
	font_size = max(font_size, MIN_FONT_SIZE)
	header_label_settings.font_size = int(font_size)
	font_size_changed.emit(header_label_settings.font_size)

func _process(delta : float):
	if Vector2i(size) != last_size:
		size = last_size

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

	# font size can be adjusted but whether it fits or not won't
	# be known until the next frame is processed.  Due to the way
	# fonts can be at different sizes, there's also no continuous
	# function to determine font size and menu rect size.  Worse,
	# a new font atlas and glyphs must be rendered at each size
	# change, ruining performance at large scales.
	# screen size and rect size can change at any moment, even
	# without changing the menu items.

	# this sucks and it's been redone several times and it's
	# probably still broken in some edge case

	if rect != last_rects[0]:
		last_rects[0] = last_rects[1]
		last_rects[1] = rect

		if scrollable:
			if rect.x > screen_rect.x:
				# rect too big, shrink
				var diff : float = rect.x - screen_rect.x
				if last_font_change > 0.0:
					# grew past, undo last change
					change_font_size(-last_font_change)
					last_font_change = 0.0
				else:
					change_font_size(-diff / screen_rect.x)
			elif rect.x < screen_rect.x:
				# rect too small, grow
				var diff : float = screen_rect.x - rect.x
				change_font_size(diff / screen_rect.x)
		else:
			if rect.x > screen_rect.x or rect.y > screen_rect.y:
				# rect too big, shrink
				var largest : int = (rect - Vector2(screen_rect)).max_axis_index()
				var diff : float = rect[largest] - screen_rect[largest]
				if last_font_change > 0.0:
					# grew past, undo last change
					change_font_size(-last_font_change)
					last_font_change = 0.0
				else:
					change_font_size(-diff / screen_rect[largest])
			elif rect.x < screen_rect.x and rect.y < screen_rect.y:
				# rect too small, grow
				var largest : int = (Vector2(screen_rect) - rect).max_axis_index()
				var diff : float = screen_rect[largest] - rect[largest]
				change_font_size(diff / screen_rect[largest])

	if last_change != null:
		last_change_time += delta

		var period : float = CHANGE_PERIODS[min(len(CHANGE_PERIODS) - 1, int(last_change_time))]
		if last_change_time - last_value_change_time >= period:
			last_value_change_time = last_change_time
			last_change.change_value(change_mult)

func clear_last_press():
	last_change = null

func _gui_input(e : InputEvent):
	if e_is_release(e):
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
	elif c is TextureRect:
		var title_logo : TextureRect = c as TextureRect
		title_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var orig_c : Control = container.get_child(0)
	container.remove_child(orig_c)
	container.add_child(c)
	container.move_child(c, 0)
	c.size_flags_vertical |= orig_c.size_flags_vertical
	if orig_c == filler:
		orig_c.queue_free()
		filler = null
	update_heading_scale()

func clear_items():
	for item in menu_items:
		if item != null:
			#container.remove_child(item)
			item.queue_free()

func set_items(items : Array[MenuItemDesc]):
	# clear any existing items
	clear_items()
	menu_descs = {}
	menu_items = []

	for item in items:
		var menu_item : MenuItem = item.setup(container, self)
		if menu_item != null:
			container.move_child(menu_item, -2)
			menu_item.desc = item
			menu_item.label = item.label
			menu_descs[menu_item] = item
			menu_items.append(menu_item)
		else:
			menu_items.append(null)

	# don't change font size, just signal
	change_font_size(0)
	update_heading_scale()

static func e_is_release(e : InputEvent) -> bool:
	if (e is InputEventScreenTouch or \
		(e is InputEventMouseButton and \
		 e.button_index == MOUSE_BUTTON_LEFT)) and \
	   e.pressed == false:
		return true
	return false

static func e_is_pressed(e : InputEvent) -> bool:
	if (e is InputEventScreenTouch or \
		(e is InputEventMouseButton and \
		 e.button_index == MOUSE_BUTTON_LEFT)) and \
	   e.pressed == true:
		return true
	return false

static func e_is_activate(e : InputEvent) -> bool:
	return e_is_release(e)

static func e_is_dragging(e : InputEvent) -> bool:
	if e is InputEventScreenDrag or \
	   (e is InputEventMouseMotion and \
		e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return true
	return false

func set_last_change(c : Control, mult : int):
	last_change_time = 0.0
	last_value_change_time = 0.0
	last_change = c
	change_mult = mult
	last_change.change_value(change_mult)

func update_size(new_size : Vector2i = Vector2i.ZERO):
	if new_size != Vector2i.ZERO:
		last_size = new_size
	var heading : Control = container.get_child(0)
	if heading is TextureRect:
		var title_logo : TextureRect = heading as TextureRect
		var texsize : Vector2i = title_logo.texture.get_size()
		var texaspect : float = texsize.x / texsize.y
		var headeraspect : float = last_size.x / (last_size.y / 2.0)
		if texaspect > headeraspect:
			title_logo.custom_minimum_size = Vector2(last_size.x, -1.0)
			title_logo.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		else:
			title_logo.custom_minimum_size = Vector2(-1.0, last_size.y / 2.0)
			title_logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

func destroy():
	header_label_settings.font_size = default_label_size
	title_control.queue_free()
	clear_items()
	queue_free()
