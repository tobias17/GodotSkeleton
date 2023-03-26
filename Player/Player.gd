extends KinematicBody2D

###############
#  Abilities  #
###############
func load_scene(name):
	return load("res://Abilities/" + name + "/" + name + ".gd")

var AbilityTracker = load("res://Utils/AbilityTracker.gd")
onready var abilities = {
	"crossbow": {
		"tracker": AbilityTracker.new(0.5, 0.1, 0.1),
		"scene":   load("res://Abilities/Projectile/Crossbow/Crossbow.tscn"),
		"damage":  10,
		"sprite": {
			"texture": preload("res://Abilities/Projectile/Crossbow/arrow2.png"),
			"scale":   0.2,
		},
	},
	"sword_swing": {
		"tracker": AbilityTracker.new(1.8, 0.25, 0.1),
		"scene":   load("res://Abilities/Attack/SwordSwing/SwordSwing.tscn"),
		"damage":  20,
		"sprite": {
			"texture":  preload("res://Abilities/Attack/SwordSwing/Sword.png"),
			"scale":    0.2,
			"rotation": 90,
		},
	},
	"fireball": {
		"tracker": AbilityTracker.new(3.0, 0.4, 0.2, 0.1),
		"scene":   load("res://Abilities/Conjuration/Fireball/Fireball.tscn"),
		"damage":  30,
		"sprite": {
			"texture": preload("res://Abilities/Conjuration/Fireball/fireball2.png"),
			"scale":   1.4,
			"hframes": 3,
		},
	},
}

# key=input, value=type
var starting_abilities = {
	"q": { "ability": "crossbow",    "display": Vector2(1920/2-150, 1080-150) },
	"w": { "ability": "sword_swing", "display": Vector2(1920/2,     1080-150) },
	"e": { "ability": "fireball",    "display": Vector2(1920/2+150, 1080-150) },
}

var ab_sl = 1.0
func bind_ability(input_name, attack_type):
	var tr = self.abilities[attack_type]["tracker"]
	return AbilityTracker.new(tr.max_down_time, tr.max_cast_time*ab_sl, tr.max_wind_time*ab_sl, tr.max_stop_time*ab_sl, input_name, attack_type)
onready var ability_trackers = []
func setup_abilities():
	for key in self.starting_abilities:
		self.ability_trackers.append(bind_ability(key, self.starting_abilities[key]["ability"]))

var cd_displays = null
onready var CdDisplay = load("res://Utils/CdDisplay/CdDisplay.tscn")
func create_cd_displays():
	self.cd_displays = {}
	for key in self.starting_abilities:
		var disp = CdDisplay.instance()
		var attack_type: String = self.starting_abilities[key]["ability"]
		disp.set_sprite_data(self.abilities[attack_type]["sprite"])
		Globals.ui_container.add_child(disp)
		disp.position = self.starting_abilities[key]["display"]
		self.cd_displays[key] = disp



###############
#   Movement  #
###############
var MOVE_SPEED = 350
var STOP_MOVE_THRESH = 5
var move_target = null
var velocity: Vector2 = Vector2.ZERO

func stop_moving():
	self.curr_state = States.NONE
	self.move_target = null
	self.velocity = Vector2.ZERO

func start_moving(target: Vector2):
	self.curr_state = States.MOVING
	self.move_target = target

func move_tick():
	var move_vec = self.move_target - self.position
	if move_vec.length() <= self.STOP_MOVE_THRESH:  stop_moving()
	else:  self.velocity = move_vec.normalized() * self.MOVE_SPEED



################
#  Main Funcs  #
################
func _ready():
	Globals.player_obj = self
	Globals.draw_requests.push_back(self)
	setup_abilities()

func draw_on_obj(obj):
	if Globals.show_cursor_lines:
		var ao = self.attack_offset.position
		obj.draw_line(self.global_transform.origin,      get_global_mouse_position(), Color(0, 1, 0), Globals.attack_outline_width)
		obj.draw_line(self.global_transform.origin + ao, get_global_mouse_position(), Color(0, 0, 1), Globals.attack_outline_width)

enum States {
	NONE,
	MOVING,
	ABILITY,
}
var curr_state = States.NONE

var COLLISION_LAYER = Globals.PLAYER_ATTACK_COLLISION_LAYER
onready var attack_offset = $AttackOffset
onready var ysort = $YSort
var curr_ability = null
var is_alive = true
var attached_abilities = []

func _physics_process(delta):
	if not is_alive:  return
	
	for tracker in ability_trackers:
		tracker.tick(delta)
	
	if Globals.ui_container != null:
		if self.cd_displays == null:  self.create_cd_displays()
		for tracker in self.ability_trackers:
			if tracker.input_name in self.cd_displays:
				var disp = self.cd_displays[tracker.input_name]
				
				if tracker.down_time <= 0:
					disp.set_text("")
					disp.set_scope(true)
				else:
					disp.set_text(str(int(tracker.down_time + 1)))
					disp.set_scope(false)
	
	if curr_state == States.ABILITY:
		if curr_ability.can_move():
			if move_target == null:  curr_state = States.NONE
			else:                    curr_state = States.MOVING
	else:
		for tracker in ability_trackers:
			if tracker.can_cast() and Input.is_action_just_pressed(tracker.input_name):
				self.curr_ability = tracker
				tracker.cast()
				
				var instance = abilities[tracker.attack_type]["scene"].instance()
				instance.cast(self, tracker, get_local_mouse_position(), abilities[tracker.attack_type])
				
				stop_moving()
				self.curr_state = States.ABILITY
				break
	
	if Input.is_action_just_pressed("stop"):
		move_target = null
		if curr_state == States.MOVING:   stop_moving() 
	elif Input.is_action_pressed("move"):
		move_target = get_global_mouse_position()
		if curr_state != States.ABILITY:  curr_state = States.MOVING
	
	if curr_state == States.MOVING:
		move_tick()
	
	move_and_slide(self.velocity)
	#queue_redraw()



###############
#    Hooks    #
###############
onready var health_manager = $Health
func _on_CharacterBox_area_entered(area):
	var parent = area.get_parent()
	health_manager.curr_health -= parent.damage
	parent.collided()
