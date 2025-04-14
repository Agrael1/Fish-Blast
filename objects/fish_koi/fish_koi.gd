extends RigidBody2D

@export var _hitbox_brain: HitboxBrain

func _ready() -> void:
	self.linear_velocity = Vector2(-GsomConsole.get_cvar("fish_speed"), 0)
	
	_hitbox_brain.was_hit_ex.connect(func(data: Hitbox.Hit) -> void:
		self.linear_velocity = data.knockback)
