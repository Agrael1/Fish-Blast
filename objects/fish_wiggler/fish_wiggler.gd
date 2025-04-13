extends Node2D

@onready var pivot: Node2D = $Pivot

var _spawn_time: float
var _speed_multiplier: float = 0

func _ready() -> void:
	_spawn_time = Time.get_ticks_msec()
	_speed_multiplier = randf_range(0.5, 1.5)

func _physics_process(delta: float) -> void:
	global_position.x -= GsomConsole.get_cvar("fish_speed") * delta

	var fish_wiggle: float = GsomConsole.get_cvar("fish_wiggle")
	var fish_wiggle_magnitude: float = GsomConsole.get_cvar("fish_wiggle_magnitude")
	pivot.position.y = sin((Time.get_ticks_msec() - _spawn_time) * fish_wiggle  * _speed_multiplier) * fish_wiggle_magnitude

