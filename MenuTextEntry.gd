class_name MenuTextEntry
extends MenuItem

@onready var label_c : Control = $"Label Container"

var line_edit : LineEdit

func menu_select(e : InputEvent):
	if Menu.e_is_activate(e):
		if line_edit.has_focus():
			text_submitted(line_edit.text)
			line_edit.release_focus()
		else:
			line_edit.grab_focus()

func text_submitted(new_text : String):
	desc.submit_func.call(new_text)

func font_size_changed(val : int):
	line_edit.add_theme_font_size_override(&"font_size", val)
