class_name MenuDoubleSelection
extends MenuItem

@onready var clickable0 : Control = $"Label Container"
@onready var clickable1 : Control = $"Label2 Container"

var label1 : String = "Label":
	set(new_label):
		label1 = new_label
		$"Label2 Container/Margins/Text".text = label1

func menu_select0(e : InputEvent):
	if Menu.e_is_activate(e):
		desc.activate0_func.call()

func menu_select1(e : InputEvent):
	if Menu.e_is_activate(e):
		desc.activate1_func.call()
