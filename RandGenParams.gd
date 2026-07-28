class_name RandGenParams
extends Object

# snake length
var min_length : int = 3
var max_length : int = 10
# initial chance for a snake to start generating at some space
var base_chance_num : int = 1
var base_chance_den : int = 100
var base_chance : float = 0.0
# multiplier to increase chance to generate by each iteration
var chance_mult_num : int = 11
var chance_mult_den : int = 10
var chance_mult : float = 0.0
# base preference for an arrow to go forward
var forward_pref_num : int = 4
var forward_pref_den : int = 1
var forward_pref : float = 0.0
# preference for an arrow to follow along other arrows
var along_snake_pref_num : int = 8
var along_snake_pref_den : int = 1
var along_snake_pref : float = 0.0
# bias based on what quadrant an arrow is in to try to get them towards center
var quadrant_pref_num : int = 10
var quadrant_pref_den : int = 1
var quadrant_pref : float = 0.0
# likelihood to follow along the edges
var along_edge_pref_num : int = 1
var along_edge_pref_den : int = 10
var along_edge_pref : float = 0.0

func update_floats():
	base_chance = float(base_chance_num) / float(base_chance_den)
	chance_mult = float(chance_mult_num) / float(chance_mult_den)
	forward_pref = float(forward_pref_num) / float(forward_pref_den)
	along_snake_pref = float(along_snake_pref_num) / float(along_snake_pref_den)
	quadrant_pref = float(quadrant_pref_num) / float(quadrant_pref_den)
	along_edge_pref = float(along_edge_pref_num) / float(along_edge_pref_den)
