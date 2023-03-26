extends Node2D

onready var ysort = $YSort
onready var ui_container = $UiContainer

func _ready():
	Globals.node_container = self.ysort
	Globals.ui_container   = self.ui_container
