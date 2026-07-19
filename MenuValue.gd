class_name MenuValue
extends MenuItem

var value : int = 0:
	set(new_value):
		value = new_value
		$"Value Container/Margins/Text".text = str(value)

@onready var clickable_dec : Control = $"Dec Container"
@onready var clickable_inc : Control = $"Inc Container"
