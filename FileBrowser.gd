class_name FileBrowser
extends Object

const RAW_PROT : String = "arrows:"
const ZSTD_PROT : String = "arrowszstd:"

var menu : Menu
var file_item : FileItem
var return_func : Callable
var name_func : Callable
var save_func : Callable
var load_func : Callable
var puzzledata : PuzzleData

var menu_select : Array[MenuItemDesc]
var show_load : bool = false
var show_save : bool = false
var editing : bool = false
var done : bool = false

func replace_placeholder_selection(left_label : String,
								   left_func : Callable,
								   right_label : String,
								   right_func : Callable):
	for i in len(menu_file):
		var item : MenuItemDesc = menu_file[i]
		if item is MenuPlaceholderDesc and \
		   item.label == left_label:
			menu_file[i].free()
			menu_file[i] = MenuDoubleSelectionDesc.new(left_func, right_func, left_label, right_label)
			break

func replace_selection_placeholder(left_label : String):
	for i in len(menu_file):
		var item : MenuItemDesc = menu_file[i]
		if item is MenuSelectionDesc and \
		   item.label == left_label:
			menu_file[i].free()
			menu_file[i] = MenuPlaceholderDesc.new(left_label)
			break

func _init(menu : Menu,
		   file_name : String,
		   return_func,
		   name_func,
		   save_func,
		   load_func,
		   puzzledata : PuzzleData = null):
	self.menu = menu
	file_item = FileItem.make_from_path(file_name)
	self.return_func = return_func

	if name_func != null:
		self.name_func = name_func

	if save_func != null:
		self.save_func = save_func

	if puzzledata != null:
		self.puzzledata = puzzledata
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
		replace_placeholder_selection("Save", save_file, "Copy", export_file)
	else:
		replace_selection_placeholder("Save")
	if show_load:
		replace_placeholder_selection("Load", load_file, "Paste", import_file)
	else:
		replace_selection_placeholder("Load")

	update_menu("File", menu_file)

var menu_file : Array[MenuItemDesc] = [
	# TODO: Import/Export clipboard
	MenuTextEntryDesc.new("", set_editing, null, submit_name, "Name"),
	MenuPlaceholderDesc.new("Save"),
	MenuPlaceholderDesc.new("Load"),
	MenuSelectionDesc.new(select_file, "Browse"),
	MenuSelectionDesc.new(do_return, "Cancel"),
]

func do_return():
	file_item.free()
	done = true
	return_func.call()

func submit_name(fn : String):
	file_item.free()
	file_item = FileItem.make_from_path(fn)
	name_func.call(file_item.get_path())
	return file_item.get_display_string()

func save_file():
	if editing:
		submit_name(menu.menu_items[0].line_edit.text)

	var file_name : String = file_item.get_path()
	var file : FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
	if file == null:
		ErrorScreen.show(menu, "File %s couldn't be saved: %s" % [file_name, error_string(FileAccess.get_open_error())], display_menu)
	else:
		if not file.store_buffer(puzzledata.serialize()):
			ErrorScreen.show(menu, "Couldn't write file %s." % file_name, display_menu)
		else:
			# succeeded, about to return to original menu so put
			# it back to what it was
			if save_func != null:
				save_func.call()
			else:
				return_func.call()
		file.close()

func load_data(data : PackedByteArray, source : String):
	puzzledata = PuzzleData.deserialize(data)
	if puzzledata == null:
		ErrorScreen.show(menu, "%s is invalid or corrupt." % source, display_menu)
	else:
		if puzzledata.check_data():
			# succeeded, about to return to original menu so put
			# it back to what it was
			load_func.call(puzzledata)
		else:
			ErrorScreen.show(menu, "%s is invalid or corrupt." % source, display_menu)
			# discarding, free snake memory
			puzzledata.free_snakes()
			puzzledata.free()
			puzzledata = null

func load_file():
	if editing:
		submit_name(menu.menu_items[0].line_edit.text)

	var file_name : String = file_item.get_path()
	var data : PackedByteArray = FileAccess.get_file_as_bytes(file_name)
	if len(data) == 0:
		var error : Error = FileAccess.get_open_error()
		if error == Error.OK:
			ErrorScreen.show(menu, "File %s is empty." % file_name, display_menu)
		else:
			ErrorScreen.show(menu, "File %s couldn't be opened: %s" % [file_name, error_string(error)], display_menu)
	else:
		load_data(data, "file %s" % file_name)

func import_file():
	if not DisplayServer.clipboard_has():
		ErrorScreen.show(menu, "Clipboard is empty.", display_menu)

	var text : String = DisplayServer.clipboard_get().strip_edges()
	if text.begins_with(RAW_PROT):
		var data : PackedByteArray = Marshalls.base64_to_raw(text.substr(len(RAW_PROT)))
		load_data(data, "Clipboard data")
	elif text.begins_with(ZSTD_PROT):
		var data : PackedByteArray = Marshalls.base64_to_raw(text.substr(len(RAW_PROT))) \
										.decompress(len(text) - len(RAW_PROT),
													FileAccess.COMPRESSION_ZSTD)
		load_data(data, "Clipboard data")

func export_file():
	var data : PackedByteArray = puzzledata.serialize()
	var uncompressed : String = Marshalls.raw_to_base64(data)
	var compressed : String = Marshalls.raw_to_base64(data.compress(FileAccess.COMPRESSION_ZSTD))

	if len(compressed) + len(ZSTD_PROT) > len(uncompressed) + len(RAW_PROT):
		DisplayServer.clipboard_set(RAW_PROT + uncompressed)
	else:
		DisplayServer.clipboard_set(ZSTD_PROT + compressed)

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
			puzzledata.free_snakes()
			puzzledata.free()
			var desc : MenuImageSelectionDesc = MenuImageSelectionDesc.new(image, item, select_file_item, item.get_display_string())
			menu_select.append(desc)
		fn = dir.get_next()
	dir.list_dir_end()

func select_file():
	menu_select = []
	for sourcedir in FileItem.FILE_SOURCE_PATH:
		add_files_dir(sourcedir)

	for item in menu_select_template:
		menu_select.append(item)

	menu.scrollable = true
	update_menu("Browse", menu_select)

var menu_select_template : Array[MenuItemDesc] = [
	MenuSelectionDesc.new(return_to_menu, "Cancel")
]

func free_menu_select():
	for item in menu_select:
		if item not in menu_select_template:
			item.key.free()
			item.free()
	menu_select = []

func return_to_menu():
	menu.scrollable = false
	# clean up before returning
	free_menu_select()
	display_menu()

func select_file_item(key : FileItem):
	file_item.free()
	# copy the soon to be freed object
	file_item = FileItem.new(key.file_name, key.file_source)
	return_to_menu()
