extends RigidBody2D

@export var _hitbox_brain: HitboxBrain

@onready var _starting_y := global_position.y

var _spawn_time: float
var _speed_multiplier: float = 0
var _wiggling: bool = true

func _ready() -> void:
	_spawn_time = Time.get_ticks_msec()
	_speed_multiplier = randf_range(0.5, 1.5)
	
	# cvar declared in debug_console.gd
	linear_velocity = Vector2(-GsomConsole.get_cvar("fish_speed"), 0)
	
	_hitbox_brain.was_hit_ex.connect(func(hit_data: Hitbox.Hit) -> void:
		if hit_data.knockback.length_squared() == 0:
			return
		linear_velocity = hit_data.knockback
		_wiggling = false
		)

func _physics_process(delta: float) -> void:
	if _wiggling:
		var fish_wiggle: float = GsomConsole.get_cvar("fish_wiggle")
		var fish_wiggle_magnitude: float = GsomConsole.get_cvar("fish_wiggle_magnitude")
		var y_offset := sin((Time.get_ticks_msec() - _spawn_time) * fish_wiggle  * _speed_multiplier) * fish_wiggle_magnitude
		global_position.y = _starting_y + y_offset
