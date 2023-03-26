extends Node2D

var is_ready = false
var sprite_data = null

func _ready():
	self.is_ready = true
	if self.sprite_data != null:
		set_sprite_data(self.sprite_data)

onready var sprite: Sprite = $Sprite
func set_scope(is_in_scope):
	if is_in_scope:  self.sprite.modulate.a = 1.0
	else:            self.sprite.modulate.a = 0.5

func set_sprite_data(data):
	if not self.is_ready:
		self.sprite_data = data
		return
	
	self.sprite.texture = data["texture"]
	if "scale" in data:
		self.sprite.scale.x = data["scale"]
		self.sprite.scale.y = data["scale"]
	if "offset" in data:
		self.sprite.position = data["offset"]
	if "rotation" in data:
		self.sprite.rotation = deg2rad(data["rotation"])
	if "hframes" in data:
		self.sprite.hframes = data["hframes"]

onready var label = $Label
func set_text(text):
	self.label.text = text

func delete():
	self.queue_free()
