extends Node2D

export var SPEED:      int = 500
export var LENGTH:     int = 50
export var HALF_WIDTH: int = 10

var tracker       = null
var attack_vector = null
var attack_angle  = null
var damage        = 0
var coll_layer    = null 
var char_offset   = null
var ab_container  = null

var has_run_setup = false



####################
#  Required Funcs  #
####################

func cast(casting_obj, tracker, attack_vector, info):
	# store local varibales
	self.tracker       = tracker
	self.char_offset   = casting_obj.attack_offset.position
	self.attack_vector = (attack_vector - self.char_offset).normalized() * SPEED
	self.attack_angle  = self.attack_vector.angle()
	self.damage        = info["damage"]
	self.coll_layer    = casting_obj.COLLISION_LAYER
	self.ab_container  = casting_obj.attached_abilities
	self.visible       = false
	
	# add ourselves to necessary lists and containers
	Globals.node_container.add_child(self)
	Globals.draw_requests.push_back(self)
	self.ab_container.push_back(self)
	self.position = casting_obj.position
	
	# set that we have run setup
	self.has_run_setup = true

func collided():
	self.damage = 0
	self.delete()

func delete():
	Globals.draw_requests.erase(self)
	self.ab_container.erase(self)
	queue_free()



####################
# Projectile Funcs #
####################

func draw_on_obj(obj):
	if not self.casted:  return
	
	# reroute vars to shorter names
	var color = Globals.get_outline_color(false, 0.0)
	var lw    = Globals.attack_outline_width
	var aa    = self.attack_angle
	var pos   = self.global_transform.origin
	
	obj.draw_line(pos + Vector2(0,  HALF_WIDTH).rotated(aa), pos + Vector2(LENGTH,  HALF_WIDTH).rotated(aa), color, lw, true)
	obj.draw_line(pos + Vector2(0, -HALF_WIDTH).rotated(aa), pos + Vector2(LENGTH, -HALF_WIDTH).rotated(aa), color, lw, true)
	obj.draw_arc(pos + Vector2(LENGTH + lw/2, 0).rotated(aa), HALF_WIDTH, aa+deg2rad(-90), aa+deg2rad(90), Globals.ARC_COUNT, color, lw, true)
	obj.draw_arc(pos + Vector2(-lw/2, 0).rotated(aa), HALF_WIDTH, aa+deg2rad(90), aa+deg2rad(270), Globals.ARC_COUNT, color, lw, true)

onready var attack = self
onready var center = $Center
onready var anchor = $Center/Anchor
onready var scalar = $Center/Anchor/Scalar
onready var AbilityBox: PackedScene = load("res://Utils/AbilityBox/AbilityBox.tscn")
func init_projectile():
	# setup positions and angles
	self.attack.position += (Vector2(1,0).rotated(self.attack_angle) * 0.01)
	self.center.position = self.char_offset
	self.anchor.rotation = self.attack_angle
	
	# create collision
	var area_node = AbilityBox.instance()
	area_node.collision_layer = self.coll_layer
	area_node.collision_mask  = 0
	
	self.add_child(area_node)
	var col_node = CollisionShape2D.new()
	area_node.add_child(col_node)
	
	var shape = CapsuleShape2D.new()
	shape.set_height(LENGTH)
	shape.set_radius(HALF_WIDTH)
	
	col_node.position = (attack_vector.normalized() * (LENGTH/2))
	col_node.rotation = attack_angle + deg2rad(90)
	col_node.shape = shape
	
	# set variables
	self.visible = true
	self.casted  = true

var casted = false
func _physics_process(delta):
	if not self.has_run_setup: return
	if not self.casted:
		if self.tracker.wind_perc_rem() <= 0:  self.init_projectile()
		else:                                  return
	
	self.position += self.attack_vector * delta
	if (self.position - Globals.player_obj.position).length() > Globals.DESPAWN_DIST:
		self.delete()
