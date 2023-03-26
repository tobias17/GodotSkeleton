extends Node2D

onready var healthbar = $Healthbar

export  var max_health  = 100
onready var curr_health = max_health setget set_health

signal no_health

func set_max_health(max_health):
	self.max_health = max_health
	reset_health()

func reset_health():
	set_health(max_health)

func set_health(value):
	curr_health = min(max_health, max(0, value))
	healthbar.scale.x = (float(curr_health) / float(max_health))
	if curr_health <= 0:
		self.visible = false
		emit_signal("no_health")
