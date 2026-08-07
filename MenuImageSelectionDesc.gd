class_name MenuImageSelectionDesc
extends MenuItemDesc

var image : Image
var key : Variant
var activate_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var item : MenuImageSelection = load("res://MenuImageSelection.tscn").instantiate()
	# HACK: normally this is set by the menu system but it needs
	# to be available in the ready function
	item.desc = self
	container.add_child(item)
	item.clickable.connect(&"gui_input",
						   item.menu_select)
	return item
