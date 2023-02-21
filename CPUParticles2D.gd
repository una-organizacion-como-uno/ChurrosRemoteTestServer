extends CPUParticles2D


export(int, 1,30) var param_particle_amount = 8
export var param_particle_speed = 10

func _init():
	ParamsServer.register_properties(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var new_amount = ParamsServer.data.global.get("param_particle_amount", param_particle_amount)
	if amount != new_amount:
		amount = new_amount
	var new_velocity = ParamsServer.data.global.get("param_particle_speed", param_particle_speed)
	if initial_velocity != new_velocity:
		initial_velocity = new_velocity
