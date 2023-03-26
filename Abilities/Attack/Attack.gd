extends Node2D

export(String, "swing", "strike") var TYPE = "swing"
export var LENGTH         : int = 250
export var HALF_ANGLE_DEG : int = 40
export var HALF_WIDTH     : int = 30
export var ANGLE_START_DEG: int = 40
export var ANGLE_END_DEG  : int = -40
export var PITCH_START_DEG: int = 10
export var PITCH_END_DEG  : int = -10

onready var HALF_ANGLE  = deg2rad(HALF_ANGLE_DEG)
onready var ANGLE_START = deg2rad(ANGLE_START_DEG)
onready var ANGLE_END   = deg2rad(ANGLE_END_DEG)
onready var PITCH_START = deg2rad(PITCH_START_DEG)
onready var PITCH_END   = deg2rad(PITCH_END_DEG)

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
	self.attack_vector = attack_vector
	self.attack_angle  = attack_vector.angle()
	self.damage        = info["damage"]
	self.coll_layer    = casting_obj.COLLISION_LAYER
	self.char_offset   = casting_obj.attack_offset.position
	self.ab_container  = casting_obj.attached_abilities
	
	# add ourselves to necessary lists and containers
	casting_obj.ysort.add_child(self)
	self.ab_container.push_back(self)
	Globals.draw_requests.push_back(self)
	
	# set that we have run setup
	self.has_run_setup = true

func collided():
	pass

func delete():
	Globals.draw_requests.erase(self)
	self.ab_container.erase(self)
	queue_free()



####################
#   Attack Funcs   #
####################

func draw_on_obj(obj):
	var is_winding = tracker.wind_perc_rem() > 0
	var color = Globals.get_outline_color(is_winding, tracker.wind_perc_rem() if is_winding else tracker.cast_perc_rem())
	
	# reroute vars to shorter names
	var lw  = Globals.attack_outline_width
	var aa  = self.attack_angle
	var pos = self.global_transform.origin
	
	# call draw funcs on DrawNode
	if self.TYPE == "swing":
		obj.draw_line(pos, pos + Vector2(LENGTH, 0).rotated(aa - HALF_ANGLE), color, lw)
		obj.draw_line(pos, pos + Vector2(LENGTH, 0).rotated(aa + HALF_ANGLE), color, lw)
		obj.draw_arc(pos, LENGTH, aa - HALF_ANGLE, aa + HALF_ANGLE, Globals.ARC_COUNT, color, lw)
	if self.TYPE == "strike":
		obj.draw_line(pos + Vector2(0,  HALF_WIDTH).rotated(aa), pos + Vector2(LENGTH,  HALF_WIDTH).rotated(aa), color, lw, true)
		obj.draw_line(pos + Vector2(0, -HALF_WIDTH).rotated(aa), pos + Vector2(LENGTH, -HALF_WIDTH).rotated(aa), color, lw, true)
		obj.draw_arc(pos + Vector2(LENGTH + lw/2, 0).rotated(aa), HALF_WIDTH, aa+deg2rad(-90), aa+deg2rad(90), Globals.ARC_COUNT, color, lw, true)

onready var AbilityBox: PackedScene = load("res://Utils/AbilityBox/AbilityBox.tscn")
func create_collision():
	var area_node = AbilityBox.instance()
	area_node.collision_layer = self.coll_layer
	area_node.collision_mask  = 0
	
	self.add_child(area_node)
	var col_node = CollisionShape2D.new()
	area_node.add_child(col_node)
	
	var shape = null
	if self.TYPE == "swing":
		shape = ConvexPolygonShape2D.new()
		var points = PoolVector2Array()
		points.push_back(Vector2.ZERO)
		var start_vector = (self.attack_vector.normalized() * LENGTH).rotated(-HALF_ANGLE)
		for i in range(Globals.ARC_COUNT+1):
			points.push_back(start_vector.rotated((float(i) / Globals.ARC_COUNT) * 2 * HALF_ANGLE))
		shape.set_point_cloud(points)
	elif self.TYPE == "strike":
		shape = CapsuleShape2D.new()
		shape.set_height(LENGTH - HALF_WIDTH)
		shape.set_radius(HALF_WIDTH)
		
		col_node.position = (attack_vector.normalized() * (LENGTH/2 + HALF_WIDTH/2))
		col_node.rotation = attack_angle + deg2rad(90)
	
	col_node.shape = shape

onready var attack = self
onready var center = $Center
onready var anchor = $Center/Anchor
onready var offset = $Center/Anchor/Offset
onready var scalar = $Center/Anchor/Offset/Scalar

var dist_scale = 20
var vertical_mult = 3
func pitch_shrink(angle):
	return 1 - (tan(angle) * cos(angle))
func move_attack(weapon_angle, weapon_pitch):
	self.attack.position = (Vector2(1,0).rotated(weapon_angle) * 0.01)
	self.center.position = self.char_offset
	
	self.anchor.rotation = weapon_angle - (sin(weapon_pitch) * cos(weapon_angle))
	self.anchor.position = Vector2(1,0).rotated(weapon_angle) * self.dist_scale
	
	self.offset.position.x = self.dist_scale * (1 - cos(weapon_pitch)) * cos(weapon_angle)
	self.offset.position.y = -(self.vertical_mult * self.dist_scale * sin(weapon_pitch) * cos(weapon_angle))
	
	var weapon_angle_shrink = Globals.PITCH_ANGLE - (weapon_pitch * sin(weapon_angle))
	self.scalar.scale.x = 1.0 - abs(pitch_shrink(weapon_angle_shrink)*sin(weapon_angle))
	self.scalar.scale.y = 1.0 - abs(pitch_shrink(Globals.PITCH_ANGLE)*cos(weapon_angle))

var casted = false
func _process(delta):
	if not self.has_run_setup:        return
	if self.tracker.cast_perc_rem() <= 0:  self.delete()
	
	self.visible = self.tracker.wind_perc_rem() <= 0
	if self.visible and not self.casted:
		self.create_collision()
		self.casted = true
	var perc_rem = self.tracker.cast_perc_rem()
	var weapon_angle = perc_rem*self.ANGLE_START + (1-perc_rem)*self.ANGLE_END + self.attack_angle
	var weapon_pitch = perc_rem*self.PITCH_START + (1-perc_rem)*self.PITCH_END
	move_attack(weapon_angle, weapon_pitch)
