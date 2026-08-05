class_name MenuValueDesc
extends MenuItemDesc

var value : int
var min_value : int
var max_value : int
var change_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var item : MenuValue = load("res://MenuValue.tscn").instantiate()
	container.add_child(item)
	item.menu = menu
	item.value = value
	item.clickable_dec.connect(&"gui_input",
							   item.menu_dec)
	item.clickable_inc.connect(&"gui_input",
							   item.menu_inc)
	return item
