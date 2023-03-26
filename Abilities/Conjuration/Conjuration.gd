extends Node2D

export var MAX_DIST: int = 500
export var RADIUS:   int = 40

var tracker       = null
var attack_vector = null
var damage        = 0
var coll_layer    = null 
var char_offset   = null
var ab_container  = null

var has_run_setup = false

onready var sprite = $Center/Sprite



####################
#  Required Funcs  #
####################

func cast(casting_obj, tracker, attack_vector, info):
	# store local varibales
	self.tracker       = tracker
	self.char_offset   = casting_obj.attack_offset.position
	self.attack_vector = attack_vector - self.char_offset
	if self.attack_vector.length() > self.MAX_DIST:
		self.attack_vector = self.attack_vector.normalized() * self.MAX_DIST
	self.damage        = info["damage"]
	self.coll_layer    = casting_obj.COLLISION_LAYER
	self.ab_container  = casting_obj.attached_abilities
	self.visible       = false
	
	# add ourselves to necessary lists and containers
	Globals.node_container.add_child(self)
	Globals.draw_requests.push_back(self)
	self.ab_container.push_back(self)
	self.position = casting_obj.position + self.attack_vector
	
	# set that we have run setup
	self.has_run_setup = true

func collided():
	pass

func delete():
	Globals.draw_requests.erase(self)
	self.ab_container.erase(self)
	queue_free()



####################
# Projectile Funcs #
####################

func draw_on_obj(obj):
	var is_winding = tracker.wind_perc_rem() > 0
	var color = Globals.get_outline_color(is_winding, tracker.wind_perc_rem() if is_winding else tracker.cast_perc_rem())
	obj.draw_arc(self.global_transform.origin, RADIUS, 0, 2*PI, Globals.ARC_COUNT*2, color, Globals.attack_outline_width)

onready var attack = self
onready var center = $Center
onready var AbilityBox: PackedScene = load("res://Utils/AbilityBox/AbilityBox.tscn")
func init_conjuration():
	# setup positions and angles
	self.center.position = self.char_offset
	
	# create collision
	var area_node = AbilityBox.instance()
	area_node.collision_layer = self.coll_layer
	area_node.collision_mask  = 0
	
	self.add_child(area_node)
	var col_node = CollisionShape2D.new()
	area_node.add_child(col_node)
	
	var shape = CircleShape2D.new()
	shape.set_radius(RADIUS)
	
	col_node.position = Vector2.ZERO
	col_node.shape = shape
	
	# set variables
	self.visible = true
	self.casted  = true

var casted = false
func _physics_process(delta):
	if not self.has_run_setup: return
	if not self.casted:
		if self.tracker.wind_perc_rem() <= 0:  self.init_conjuration()
		else:                                  return
	
	var perc_rem = self.tracker.cast_perc_rem()
	print(perc_rem)
	if perc_rem <= 0:
		print("deleting")
		self.delete()
	else:
		var frame_count = max(self.sprite.hframes, self.sprite.vframes)
		self.sprite.frame = max(0, min(frame_count, (1 - perc_rem) * frame_count))
