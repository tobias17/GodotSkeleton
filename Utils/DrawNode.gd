extends Node2D

func _draw():
	for request in Globals.draw_requests:
		request.draw_on_obj(self)

func _process(delta):
	update()
