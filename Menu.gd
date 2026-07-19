extends Control

signal menu_clicked(String)

@onready var container : Container = $"Menu Container"

var menu_descs : Dictionary[MenuItem, MenuItemDesc] = {}
var menu_items : Dictionary[Control, MenuItem] = {}

func set_heading(c : Control):
	var orig_c : Control = container.get_child(0)
	container.remove_child(orig_c)
	container.add_child(c)
	container.move_child(c, 0)
	c.size_flags_vertical |= orig_c.size_flags_vertical
	orig_c.queue_free()

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
			menu_value.value = item.init_value
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

	# set some reasonable proportion for the heading
	container.get_child(0).size_flags_stretch_ratio = len(items)

func e_is_activate(e : InputEvent) -> bool:
	if e is InputEventMouseButton and e.pressed == false:
		return true
	return false

func menu_select(e : InputEvent, c : Control):
	if e_is_activate(e):
		var item : MenuSelection = menu_items[c]
		var desc : MenuSelectionDesc = menu_descs[item as MenuItem]
		desc.activate_func.call()

func menu_dec(e : InputEvent, c : Control):
	if e_is_activate(e):
		var item : MenuValue = menu_items[c]
		var desc : MenuValueDesc = menu_descs[item as MenuItem]
		item.value = max(item.value - 1, desc.min_value)
		desc.change_func.call(item.value)

func menu_inc(e : InputEvent, c : Control):
	if e_is_activate(e):
		var item : MenuValue = menu_items[c]
		var desc : MenuValueDesc = menu_descs[item as MenuItem]
		item.value = min(item.value + 1, desc.max_value)
		desc.change_func.call(item.value)

func update_size(new_size : Vector2i):
	size = new_size
