class_name MenuValueDesc
extends MenuItemDesc

var value : int
var min_value : int
var max_value : int
var change_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var menu_value : MenuValue = load("res://MenuValue.tscn").instantiate()
	container.add_child(menu_value)
	menu_value.menu = menu
	menu_value.value = value
	menu_value.clickable_dec.connect(&"gui_input",
									 menu_value.menu_dec)
	menu_value.clickable_inc.connect(&"gui_input",
									 menu_value.menu_inc)
	menu.menu_items[menu_value.clickable_dec] = menu_value
	menu.menu_items[menu_value.clickable_inc] = menu_value
	return menu_value
