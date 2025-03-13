extends Node2D

func _physics_process(delta: float) -> void:
	global_position.x -= GsomConsole.get_cvar("fish_speed") * delta
