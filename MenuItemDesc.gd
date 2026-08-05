@abstract
class_name MenuItemDesc
extends Object

var label : String

func _init(...args):
	# this sucks and there has to be a better way
	var i : int = 0

	for prop in get_property_list():
		if prop['usage'] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(prop['name'], args[i])
			i += 1

@abstract func setup(container : Container,
					 menu : Menu) -> MenuItem
