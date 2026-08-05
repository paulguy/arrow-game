class_name MenuSelectionDesc
extends MenuItemDesc

var activate_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var menu_selection : MenuSelection = load("res://MenuSelection.tscn").instantiate()
	container.add_child(menu_selection)
	menu_selection.menu = menu
	menu_selection.clickable.connect(&"gui_input",
									 menu_selection.menu_select)
	menu.menu_items[menu_selection.clickable] = menu_selection
	return menu_selection
