class_name MenuValue
extends MenuItem

@onready var clickable_dec : Control = $"Dec Container"
@onready var clickable_inc : Control = $"Inc Container"

var value : int = 0:
	set(new_value):
		value = new_value
		$"Value Container/Margins/Text".text = str(value)

func _ready():
	$"Dec Container/Margins/Text".text = "-"
	$"Inc Container/Margins/Text".text = "+"

func change_value(amount : int):
	value = min(max(value + amount, desc.min_value), desc.max_value)
	if desc.change_func.is_valid():
		value = desc.change_func.call(value)
	desc.value = value

func menu_change(mult : int):
	menu.set_last_change(self, mult)

func menu_dec(e : InputEvent):
	if Menu.e_is_pressed(e):
		menu_change(-1)

func menu_inc(e : InputEvent):
	if Menu.e_is_pressed(e):
		menu_change(1)
