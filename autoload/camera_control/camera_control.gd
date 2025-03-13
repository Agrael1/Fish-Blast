extends Node

# @onready var _actual_camera: Camera2D = $Pivot/ScreenshakeOffset/ActualCamera
@onready var _pivot: Node2D = $Pivot
@onready var _screenshake_offset: Node2D = $Pivot/ScreenshakeOffset

var _follow_target: CameraFollowTarget = null
var _follow_lerp_speed: float = 0.2

var _screenshakes: Array[Dictionary] = []

const SCREENSHAKE_RECOVERY_LERP_SPEED = 0.1
const MAX_PERFRAME_SHAKE_DISTANCE = Vector2(0.5, 0.5)
const MAX_TOTAL_SHAKE_DISTANCE = Vector2(10, 10)

func shake(max_magnitude: float, duration_seconds: float, axes: Vector2 = Vector2(1, 1)) -> void:
	_screenshakes.append({
		max_magnitude = max_magnitude,
		duration = duration_seconds,
		axes = axes,
	})

func request_follow(new_target: CameraFollowTarget) -> void:
	if is_instance_valid(_follow_target) and _follow_target.priority <= new_target.priority:
		_follow_target = new_target

func _process(delta: float) -> void:
	# follow. affects _pivot's position by lerping
	if is_instance_valid(_follow_target):
		_pivot.global_rotation = _follow_target.global_rotation
		# TODO: make this not deltatime dependant
		_pivot.global_position = _pivot.global_position.lerp(_follow_target.global_position, _follow_lerp_speed)

	# add to the position of _screenshake_offset based on current shakes
	_process_screenshakes(delta)
	# clamp maximum offset that can be caused by screenshake
	_screenshake_offset.position = _screenshake_offset.position.clamp(-MAX_TOTAL_SHAKE_DISTANCE, MAX_TOTAL_SHAKE_DISTANCE)
	# lerp back to zero screenshake / stable screen
	# TODO: make this not deltatime dependant
	_screenshake_offset.position = _screenshake_offset.position.lerp(Vector2.ZERO, SCREENSHAKE_RECOVERY_LERP_SPEED)

## Modifies _screenshake_offset's position based on shakes currently active
func _process_screenshakes(delta: float) -> void:
	var move_delta := Vector2(0, 0)
	for current_shake in _screenshakes:
		var mag : float = current_shake[&"max_magnitude"]
		var axes : Vector2 = current_shake[&"axes"]
		var random = Vector2(
			randf_range(-mag, mag),
			randf_range(-mag, mag),
		)
		move_delta += random * axes
		current_shake[&"duration"] -= delta

	move_delta.clamp(-MAX_PERFRAME_SHAKE_DISTANCE, MAX_PERFRAME_SHAKE_DISTANCE)

	_screenshake_offset.position = move_delta
	_screenshakes = _screenshakes.filter(func(item: Dictionary) -> bool: return item[&"duration"] > 0)
