class_name MenuDoubleSelectionDesc
extends MenuItemDesc

var activate1_func : Callable
var activate0_func : Callable
# reverse these so they're in the same order as the label arguments
var label1 : String

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var item : MenuDoubleSelection = load("res://MenuDoubleSelection.tscn").instantiate()
	container.add_child(item)
	item.label1 = label1
	item.clickable0.connect(&"gui_input",
						   item.menu_select0)
	item.clickable1.connect(&"gui_input",
						   item.menu_select1)
	return item
