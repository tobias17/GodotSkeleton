var max_down_time: float
var max_cast_time: float
var max_wind_time: float
var max_stop_time: float
var down_time = 0.0
var cast_time = 0.0
var wind_time = 0.0
var stop_time = 0.0

var input_name: String
var attack_type: String

# down_time: the amount of time between button and the next time you are allowed to cast the ability
# cast_time: the length of the ability itself, eg. with a fireball how long does the fireball exist for
# wind_time: delay before the ability is cast, eg. with a fireball how long between button press and fireball existing
# stop_time: how long is the player blocked from moving, if none is provided defaults to wind_time + cast_time

func _init(down_time, cast_time, wind_time, stop_time=null, input_name="", attack_type=""):
	self.max_down_time = down_time
	self.max_cast_time = cast_time
	self.max_wind_time = wind_time
	self.max_stop_time = stop_time if stop_time != null else wind_time + cast_time
	
	self.input_name = input_name
	self.attack_type = attack_type

func cast():
	self.down_time = self.max_down_time
	self.cast_time = self.max_cast_time
	self.wind_time = self.max_wind_time
	self.stop_time = self.max_stop_time

func tick(delta):
	if (self.down_time > 0): self.down_time -= delta
	if (self.stop_time > 0): self.stop_time -= delta
	if (self.wind_time > 0):
		self.wind_time -= delta
		if self.wind_time < 0: self.cast_time += self.wind_time
	if (self.cast_time > 0 and self.wind_time <= 0): self.cast_time -= delta

func can_move():      return self.stop_time <= 0
func can_cast():      return self.down_time <= 0
func wind_perc_rem(): return self.wind_time / self.max_wind_time
func cast_perc_rem(): return self.cast_time / self.max_cast_time



