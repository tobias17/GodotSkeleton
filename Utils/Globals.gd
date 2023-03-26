extends Node

###################
#    Constants    #
###################

var PLAYER_ATTACK_COLLISION_LAYER = 1 << (12 - 1)
var ENEMY_ATTACK_COLLISION_LAYER  = 1 << ( 9 - 1)

var PITCH_ANGLE:  float = deg2rad(45)
var DESPAWN_DIST: int   = 10000
var ARC_COUNT:    int   = 64



###################
#   Global Vars   #
###################

var node_container = null # needs to be set by the current world in _ready(), tells non-attached objects where to add themselves
var ui_container   = null # needs to be set by the current world in _ready(), tells nodes where to put ui elements
var player_obj     = null # needs to be set by the player in _ready(), is used by enemy AI to know where the player is
var draw_requests  = []   # accessed by the DrawNode, is added to by objects that want to draw under other sprites



###################
#   Debug Tools   #
###################

var DEBUG_ENABLED = true

var show_fps = true # TODO: implement
var show_cursor_lines = true

var manager = load("res://Utils/DebugManager.tscn")



###################
#  Utility Funcs  #
###################

func reset():
	node_container = null
	player_obj     = null
	draw_requests  = []

var attack_outline_width = 3
var attack_outline_max_alpha = 1.0
var attack_outline_min_alpha = 0.5
var wind_color = Color(1, 1, 1, 1)
var cast_color = Color(1, 0, 0, 1)
func get_outline_color(is_winding, perc_rem):
	var color = wind_color if is_winding else cast_color
	color.a   = attack_outline_min_alpha + (attack_outline_max_alpha - attack_outline_min_alpha) * perc_rem
	return color
