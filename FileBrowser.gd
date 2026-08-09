class_name FileBrowser
extends Node

var menu : Menu
var file_name : String
var extension : String
var return_func : Callable
var save_func : Callable
var load_func : Callable

var menu_select : Array[MenuItemDesc]

static func fix_file_name(fn : String, ext : String) -> String:
	if not (fn.begins_with("user://") or \
			fn.begins_with("res://")):
		fn = "user://%s" % fn

	if not fn.ends_with(".%s" % ext):
		fn = "%s.%s" % [fn, ext]

	return fn

func _init(menu : Menu,
		   file_name : String,
		   extension : String,
		   return_func,
		   save_func,
		   load_func):
	self.menu = menu
	self.file_name = fix_file_name(file_name, extension)
	self.extension = extension
	self.return_func = return_func
	if save_func != null:
		self.save_func = save_func
	if load_func != null:
		self.load_func = load_func

func remove_selection_if_null(out_func, in_func : Callable):
	if not out_func is Callable or \
	   not out_func.is_valid():
		for item in menu_file:
			if item is MenuSelectionDesc and \
			   item.activate_func == in_func:
				menu_file.erase(item)
				break

func update_menu(title : String,
				 items : Array[MenuItemDesc]):
	menu.set_heading(title)
	menu.set_items(items)
	menu.update_size()

func display_menu():
	remove_selection_if_null(save_func, save_file)
	remove_selection_if_null(load_func, load_file)
	menu_file[0].text = file_name
	update_menu("File", menu_file)

var menu_file : Array[MenuItemDesc] = [
	MenuTextEntryDesc.new(file_name, set_file_name, set_file_name, "Name"),
	MenuSelectionDesc.new(select_file, "Browse"),
	MenuSelectionDesc.new(save_file, "Save"),
	MenuSelectionDesc.new(load_file, "Load"),
	MenuSelectionDesc.new(do_return, "Cancel"),
]

func do_return():
	menu.scrollable = false
	return_func.call()

func save_file():
	save_func.call(file_name)
	do_return()

func load_file():
	load_func.call(file_name)
	do_return()

func set_file_name(fn : String) -> String:
	fn = fix_file_name(fn, extension)
	file_name = fn
	return file_name

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
		if fn.get_extension() == extension:
			puzzledata = PuzzleData.deserialize(FileAccess.get_file_as_bytes("user://%s" % fn))
			image = puzzledata.get_preview()
			desc = MenuImageSelectionDesc.new(image, "user://%s" % fn, select_file_item, fn)
			menu_select.push_front(desc)
		fn = dir.get_next()
	update_menu("Browse", menu_select)
	menu.scrollable = true

var menu_select_template : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(do_return, "Cancel")
]

func free_menu_select():
	for item in menu_select:
		if item not in menu_select_template:
			item.free()
	menu_select = []

func select_file_item(key : String):
	file_name = key
	display_menu()
