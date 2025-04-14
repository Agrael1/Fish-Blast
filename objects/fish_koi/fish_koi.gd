extends Node2D

func _physics_process(delta: float) -> void:
	# cvar declared in debug_console.gd
	global_position.x -= GsomConsole.get_cvar("fish_speed") * delta
