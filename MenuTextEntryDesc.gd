class_name MenuTextEntryDesc
extends MenuItemDesc

var text : String
var changed_func : Callable
var submit_func : Callable

func setup(container : Container,
		   menu : Menu) -> MenuItem:
	var item : MenuTextEntry = load("res://MenuTextEntry.tscn").instantiate()
	container.add_child(item)
	item.get_node("Value Container/Margins/Text").queue_free()
	var line_edit : LineEdit = LineEdit.new()
	item.get_node("Value Container/Margins").add_child(line_edit)
	line_edit.connect(&"text_changed",
					  item.text_changed)
	line_edit.connect(&"text_submitted",
					  item.text_submitted)
	line_edit.size_flags_horizontal |= Control.SIZE_EXPAND_FILL
	line_edit.expand_to_text_length = true
	line_edit.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	line_edit.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	line_edit.add_theme_color_override(&"font_color", Menu.header_label_settings.font_color)
	line_edit.add_theme_color_override(&"font_outline_color", Menu.header_label_settings.outline_color)
	line_edit.add_theme_constant_override(&"outline_size", Menu.header_label_settings.outline_size)
	line_edit.caret_blink = true
	if text != null:
		line_edit.text = text
	item.line_edit = line_edit
	item.menu = menu
	item.label_c.connect(&"gui_input",
						 item.menu_select)
	menu.connect(&"font_size_changed",
				 item.font_size_changed)
	return item
