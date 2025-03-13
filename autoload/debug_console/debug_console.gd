class_name AutoloadConsole
extends Node

@onready var console: Control = $Console

func _ready() -> void:
	# HACK: the console has to do with mouse mode and it always instantiates at the
	# beginning of the game, so the initial mouse state is set here. this is a global thing
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	GsomConsole.toggled.connect(func(new_is_visible: bool) -> void:
		console.visible = new_is_visible
		if new_is_visible:
			TimeControl.pause_game()
		else:
			TimeControl.unpause_game()
		# switch to captured mode if we close the terminal
		if not new_is_visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)

	GsomConsole.register_cvar("movespeed", 350.0, "Floating point scalar value for the maximum speed reachable with WASD")
	GsomConsole.register_cvar("fish_speed", 100.0)
	GsomConsole.register_cvar("fish_wiggle", 0.005)
	GsomConsole.register_cvar("fish_wiggle_magnitude", 50.0)

func _process(_delta: float) -> void:
	# use global input singleton to prevent any swallowing of inputs to debug console
	if Input.is_action_just_pressed(&"debug_console"):
		GsomConsole.toggle()
