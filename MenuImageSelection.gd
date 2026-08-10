class_name MenuImageSelection
extends MenuItem

@onready var clickable : Control = self

var texrect : TextureRect = TextureRect.new()

var image : Image:
	set(img):
		texrect.texture = ImageTexture.create_from_image(img)

func _ready():
	$"Image Container/Margins/Text".queue_free()
	$"Image Container/Margins".add_child(texrect)
	texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texrect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	image = desc.image

func menu_select(e : InputEvent):
	if Menu.e_is_activate(e):
		desc.activate_func.call(desc.key)
