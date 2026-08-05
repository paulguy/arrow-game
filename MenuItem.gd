@abstract
class_name MenuItem
extends HBoxContainer

var desc : MenuItemDesc
var menu : Menu

var label : String = "Label":
	set(new_label):
		label = new_label
		$"Label Container/Margins/Text".text = label
