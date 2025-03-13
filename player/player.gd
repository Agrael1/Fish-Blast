class_name Player
extends RigidBody2D

@onready var hitbox_area: Area2D = $HitboxArea
@onready var input: PlayerInput = $PlayerInput

const MOVE_FORCE: float = 1000
const MOVE_MAX_SPEED: float = 500

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if input.is_action_just_pressed(PlayerInput.GameButton.HOOK):
		print("hook")

func _physics_process(delta: float) -> void:
	var speed := self.linear_velocity.length()
	var wishdir := input.get_movement_vector()

	if wishdir.length_squared() == 0:

		# TODO: make not framerate dependent
		self.linear_velocity = self.linear_velocity.lerp(Vector2.ZERO, 0.5)

		return

	# if adding speed would go over max speed, add less (or maybe none)
	# other sources can still make us go over max though
	var new_speed := speed + (MOVE_FORCE * delta)
	var new_velocity := wishdir * (new_speed) # instant turning, no speed loss

	if new_speed <= MOVE_MAX_SPEED:
		self.linear_velocity = new_velocity
	elif speed <= MOVE_MAX_SPEED:
		self.linear_velocity = wishdir * MOVE_MAX_SPEED
