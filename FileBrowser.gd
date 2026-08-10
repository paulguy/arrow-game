class_name FileBrowser
extends Node

enum FileOperation {
	NONE = 0,
	SAVE,
	LOAD
}

var menu : Menu
var file_item : FileItem
var return_func : Callable
var save_func : Callable
var load_func : Callable

var menu_select : Array[MenuItemDesc]
var show_load : bool = false
var show_save : bool = false
var editing : bool = false

func replace_placeholder_selection(label : String,
								   activate_func : Callable):
	for i in len(menu_file):
		var item : MenuItemDesc = menu_file[i]
		if item is MenuPlaceholderDesc and \
		   item.label == label:
			menu_file[i] = MenuSelectionDesc.new(activate_func, label)
			break

func replace_selection_placeholder(label : String):
	for i in len(menu_file):
		var item : MenuItemDesc = menu_file[i]
		if item is MenuSelectionDesc and \
		   item.label == label:
			menu_file[i] = MenuPlaceholderDesc.new(label)
			break

func _init(menu : Menu,
		   file_name : String,
		   return_func,
		   save_func,
		   load_func):
	self.menu = menu
	file_item = FileItem.make_from_path(file_name)
	self.return_func = return_func
	if save_func != null:
		self.save_func = save_func
		show_save = true
	if load_func != null:
		self.load_func = load_func
		show_load = true

func update_menu(title : String,
				 items : Array[MenuItemDesc]):
	menu.set_heading(title)
	menu.set_items(items)
	menu.update_size()

func display_menu():
	menu_file[0].text = file_item.get_display_string()

	if show_save:
		replace_placeholder_selection("Save", save_file)
	else:
		replace_selection_placeholder("Save")
	if show_load:
		replace_placeholder_selection("Load", load_file)
	else:
		replace_selection_placeholder("Load")

	update_menu("File", menu_file)

var menu_file : Array[MenuItemDesc] = [
	MenuTextEntryDesc.new("", set_editing, null, submit_name, "Name"),
	MenuPlaceholderDesc.new("Save"),
	MenuPlaceholderDesc.new("Load"),
	MenuSelectionDesc.new(select_file, "Browse"),
	MenuSelectionDesc.new(do_return, "Cancel"),
]

func do_return():
	menu.scrollable = false
	return_func.call()

func submit_name(fn : String):
	file_item.free()
	file_item = FileItem.make_from_path(fn)
	return file_item.get_display_string()

func save_file():
	if editing:
		submit_name(menu.menu_items[0].line_edit.text)
	save_func.call(file_item.get_path())
	do_return()

func load_file():
	if editing:
		submit_name(menu.menu_items[0].line_edit.text)
	load_func.call(file_item.get_path())
	do_return()

func set_editing(toggled_on : bool):
	if toggled_on:
		menu.menu_items[0].line_edit.text = file_item.get_edit_string()
	editing = toggled_on

func add_files_dir(dir_name : String):
	DirAccess.make_dir_recursive_absolute(dir_name)
	var dir : DirAccess = DirAccess.open(dir_name)
	dir.list_dir_begin()
	var fn : String = dir.get_next()
	while fn != "":
		if FileItem.match_name(fn):
			var item : FileItem = FileItem.make_from_path("%s%s" % [dir_name, fn])
			var puzzledata : PuzzleData = PuzzleData.deserialize(FileAccess.get_file_as_bytes(item.get_path()))
			var image : Image = puzzledata.get_preview()
			var desc : MenuImageSelectionDesc = MenuImageSelectionDesc.new(image, item, select_file_item, item.get_display_string())
			menu_select.append(desc)
		fn = dir.get_next()

func select_file():
	menu_select = []
	for sourcedir in FileItem.FILE_SOURCE_PATH:
		add_files_dir(sourcedir)

	for item in menu_select_template:
		menu_select.append(item)

	update_menu("Browse", menu_select)
	menu.scrollable = true

var menu_select_template : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(do_return, "Cancel")
]

func free_menu_select():
	for item in menu_select:
		if item not in menu_select_template:
			item.key.free()
			item.free()
	menu_select = []

func select_file_item(key : FileItem):
	file_item.free()
	file_item = key
	display_menu()
