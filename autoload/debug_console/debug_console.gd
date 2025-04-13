class_name AutoloadConsole
extends Node

@onready var console: Control = $Console

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	GsomConsole.toggled.connect(func(new_is_visible: bool) -> void:
		console.visible = new_is_visible
		if new_is_visible:
			TimeControl.pause_game()
		else:
			TimeControl.unpause_game()
		)

	
	GsomConsole.register_cvar("fish_speed", 100.0)
	GsomConsole.register_cvar("fish_wiggle", 0.005)
	GsomConsole.register_cvar("fish_wiggle_magnitude", 50.0)

func _process(_delta: float) -> void:
	# use global input singleton to prevent any swallowing of inputs to debug console
	if Input.is_action_just_pressed(&"debug_console"):
		GsomConsole.toggle()
