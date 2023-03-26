extends "res://Enemies/AI/RootAI.gd"

var MOVE_SPEED  = 300
var ATTACK_DIST = 250
var BACKUP_MULT = -0.25

export var Attack: PackedScene = null

var AbilityTracker = load("res://Utils/AbilityTracker.gd")
var tracker = AbilityTracker.new(2.0, 0.2, 0.4)

func _physics_process(delta):
	if not self.is_alive:           return
	if Globals.player_obj == null:  return
	
	tracker.tick(delta)
	var velocity = Vector2.ZERO
	if tracker.can_move():
		var player_delta: Vector2 = Globals.player_obj.position - self.position
		if tracker.can_cast():
			if player_delta.length() < ATTACK_DIST:
				var inst = Attack.instance()
				inst.cast(self, tracker, player_delta, { "damage": 10 })
				tracker.cast()
			else:
				velocity = player_delta.normalized() * MOVE_SPEED
		else:
			velocity = player_delta.normalized() * (MOVE_SPEED * BACKUP_MULT)
		
		move_and_slide(velocity)
