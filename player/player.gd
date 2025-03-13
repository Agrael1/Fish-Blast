class_name Player
extends RigidBody2D

@onready var hitbox_area: Area2D = $HitboxArea
@onready var input: PlayerInput = $PlayerInput

func _ready() -> void:	
	hitbox_area.area_entered.connect(func(_unused) -> void:
		CameraControl.shake(4, 0.1)
		)

func _process(_delta: float) -> void:
	if input.is_action_just_pressed(PlayerInput.GameButton.HOOK):
		print("hook")

func _physics_process(_delta: float) -> void:
	self.linear_velocity = input.get_movement_vector() * GsomConsole.get_cvar("movespeed")
