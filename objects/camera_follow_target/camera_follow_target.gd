class_name CameraFollowTarget
extends Node2D

# intended to be constant, CameraControl reads this and only accepts
# request_follow if priority is higher or equal to current. can do some funny
# hacks with this
@export var priority: int = 0

func _enter_tree() -> void:
	CameraControl.request_follow(self)
