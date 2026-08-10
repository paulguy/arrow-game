class_name ErrorScreen
extends Object

static func show(menu : Menu,
				 message : String,
				 return_func : Callable):
	var menu_error : Array[MenuItemDesc] = [
		MenuSelectionDesc.new(return_func, "OK")
	]
	menu.set_heading(message)
	menu.set_items(menu_error)
	menu.update_size()
