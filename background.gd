extends Polygon2D

const OVERLAY_X_LOCATION : float = 0.6

@onready var overlay : Polygon2D = $Overlay

func _ready():
	var p : PackedVector2Array = uv
	p[2].y = texture.get_height()
	p[3].y = texture.get_height()
	uv = p
	var texsize : Vector2i = overlay.texture.get_size()
	p = overlay.uv
	p[1].x = texsize.x
	p[2] = Vector2(texsize)
	p[3].y = texsize.y
	overlay.uv = p

func update_size(new_size : Vector2i):
	var view_size : Vector2 = Vector2(new_size)
	var overlay_x : float = view_size.x * OVERLAY_X_LOCATION
	var overlay_scale : float = view_size.y / texture.get_height()
	var overlay_width : float = overlay.texture.get_width() * overlay_scale
	var p : PackedVector2Array = overlay.polygon
	p[0].x = overlay_x - (overlay_width / 2.0)
	p[0].y = view_size.y - (overlay.texture.get_height() * overlay_scale)
	p[1].x = p[0].x + overlay_width
	p[1].y = p[0].y
	p[2].x = p[1].x
	p[2].y = view_size.y
	p[3].x = p[0].x
	p[3].y = view_size.y
	overlay.polygon = p
	p = polygon
	p[1].x = view_size.x
	p[2] = view_size
	p[3].y = view_size.y
	polygon = p
	p = uv
	if view_size.x < view_size.y:
		view_size.x *= view_size.x / view_size.y
	p[1].x = view_size.x
	p[2].x = view_size.x
	uv = p
