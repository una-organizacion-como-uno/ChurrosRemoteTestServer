extends AnimationPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(float, 0.1, 10) var param_size = 1.0
export(float, 0.1, 5) var param_speed = 0.5

func _init():
	ParamsServer.register_properties(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$"../Sprite".scale = ParamsServer.data.global.get("param_size", param_size) * Vector2.ONE
	playback_speed = ParamsServer.data.global.get("param_speed", param_speed)
