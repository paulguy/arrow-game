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
