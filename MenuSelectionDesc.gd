class_name MenuSelectionDesc
extends MenuItemDesc

var activate_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var item : MenuSelection = load("res://MenuSelection.tscn").instantiate()
	container.add_child(item)
	item.menu = menu
	item.clickable.connect(&"gui_input",
						   item.menu_select)
	return item
