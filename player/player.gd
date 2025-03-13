class_name Player
extends RigidBody2D

@onready var hitbox_area: Area2D = $HitboxArea
@onready var input: PlayerInput = $PlayerInput

func _ready() -> void:
	GsomConsole.register_cvar("cl_movespeed", 350.0, "Floating point scalar value for the maximum speed reachable with WASD")

func _process(_delta: float) -> void:
	if input.is_action_just_pressed(PlayerInput.GameButton.HOOK):
		print("hook")

func _physics_process(_delta: float) -> void:
	self.linear_velocity = input.get_movement_vector() * GsomConsole.get_cvar("cl_movespeed")
