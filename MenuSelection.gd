class_name MenuSelection
extends MenuItem

@onready var clickable : Control = $"Label Container"

func menu_select(e : InputEvent):
	if Menu.e_is_activate(e):
		desc.activate_func.call()
