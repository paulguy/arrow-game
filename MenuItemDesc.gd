@abstract
class_name MenuItemDesc
extends Object

var label : String

func _init(...args):
	# this sucks and there has to be a better way
	# arguments are in reverse groups starting from the most
	# specific class up to this class.  I dunno if this is going
	# to be stable behavior between godot releases...
	var i : int = 0

	for prop in get_property_list():
		if prop['usage'] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(prop['name'], args[i])
			i += 1

@abstract func setup(container : Container,
					 menu : Menu) -> MenuItem
