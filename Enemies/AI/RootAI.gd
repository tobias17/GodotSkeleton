extends KinematicBody2D

var COLLISION_LAYER = Globals.ENEMY_ATTACK_COLLISION_LAYER
var attached_abilities = []
onready var attack_offset = $AttackOffset
onready var ysort = $YSort
var is_alive = true

#############
#    Hit    #
#############
onready var health_manger = $Health
onready var hit_player = $HitPlayer
func _on_CharacterBox_area_entered(area):
	hit_player.queue("hit")
	
	var parent = area.get_parent()
	health_manger.curr_health -= parent.damage
	parent.collided()

#############
#   Death   #
#############
onready var death_player = $DeathPlayer
onready var char_box_col = $CharacterBox/Collision
onready var world_col    = $Collision
func _on_Health_no_health():
	char_box_col.disabled = true
	world_col.disabled    = true
	self.death()

func death():
	while len(self.attached_abilities) > 0:  self.attached_abilities[0].delete()
	self.is_alive = false
	self.death_player.queue("death")

func _on_DeathPlayer_animation_finished(anim_name):
	if anim_name == "death":  self.delete()
	else:                     print("WARNING: got unexpected animation finished with name: " + str(anim_name))

func delete():
	queue_free()
