extends RigidBody2D

const MAX_ANGLE_OFFSET : float = 0.95
const ACCEL : float = 5.0
const TIMEOUT : float = 5.0
const ANIM_FRAMES : int = 2
const FRAME_TIME : float = 0.1

var path : Array[Vector2i]
var region : Rect2
var cell_size : Vector2i
var time : float = 0.0
var anim_time : float = 0.0
var anim : int = 0

@onready var sprite : Sprite2D = $Sprite

func _physics_process(delta : float):
	var view : Rect2 = get_viewport_rect()
	var screenpos : Vector2 = get_screen_transform().origin
	if screenpos.x < view.position.x or screenpos.x > view.end.x or \
	   screenpos.y < view.position.y or screenpos.y > view.end.y:
		queue_free()
		return

	rotation = 0.0
	var towards : float

	if time > TIMEOUT:
		collision_mask = 0

	if time > TIMEOUT or \
	   position.x < region.position.x + cell_size.x or position.x > region.end.x - cell_size.x or \
	   position.y < region.position.y + cell_size.x or position.y > region.end.y - cell_size.x:
		towards = region.get_center().angle_to_point(position)
	else:
		var nearest_pos : Vector2i = path[0]
		var nearest_i : int = 0
		var posi : Vector2i = Vector2i(position) / cell_size

		for i in len(path):
			var pos : Vector2i = path[i]
			# find the nearest position but avoid backtracking
			if pos != posi and \
			   posi.distance_to(pos) < posi.distance_to(nearest_pos) and \
			   i > nearest_i:
				nearest_pos = pos
				nearest_i = i

		towards = Vector2(posi).angle_to_point(nearest_pos)

	towards += randf_range(-PI, PI) * MAX_ANGLE_OFFSET
	apply_central_force(Vector2.from_angle(towards) * ACCEL)

	time += delta

func _process(delta : float):
	anim_time = fmod(anim_time + delta, FRAME_TIME * ANIM_FRAMES)
	sprite.frame_coords.x = floor(anim_time / FRAME_TIME)
