class_name Player
extends RigidBody2D

enum LineOut {
	NONE,
	HOOK,
	BOBBER,
}

signal ability_bobber_used()
signal ability_hook_used()
signal ability_bobber_completed()
signal ability_hook_completed()

@export_category("Bobber Stats")
@export var bobber_length: float = 1
@export var bobber_time: float = 1

@export_category("Hook Stats")
@export var hook_length: float = 1
@export var hook_time: float = 0.2

@onready var _hitbox_area: Area2D = $HitboxArea
@onready var _input: PlayerInput = $PlayerInput
@onready var _hook: Area2D = $Hook
@onready var _bobber: Area2D = $Bobber

var _line_out := LineOut.NONE
var _line_timer: float = 0
var _line_target_point: Vector2

func _ready() -> void:
	_hook.visible = false
	_bobber.visible = false
	_hitbox_area.area_entered.connect(func(_unused) -> void:
		CameraControl.shake(4, 0.1)
		)

func _process(delta: float) -> void:
	_update_line_out_state(delta)
	if _line_out != LineOut.NONE:
		var time_total := _get_ability_time()
		var completion := _line_timer / time_total
		var lerp_weight := completion * 2.0
		if completion > 0.5:
			lerp_weight = 2.0 - lerp_weight
		
		# TODO: put some nice bouncy curve equation instead of this linear interp
		if _line_out == LineOut.BOBBER:
			_bobber.global_position = _line_target_point.lerp(global_position, 1.0 - lerp_weight)
		else:
			assert(_line_out == LineOut.HOOK)
			_hook.global_position = _line_target_point.lerp(global_position, 1.0 - lerp_weight)

func _get_ability_time() -> float:
	assert(_line_out != LineOut.NONE)
	return bobber_time if _line_out == LineOut.BOBBER else hook_time

func _update_line_out_state(delta: float) -> void:
	if _line_out == LineOut.NONE:
		if _input.is_action_just_pressed(PlayerInput.GameButton.HOOK):
			_line_out = LineOut.HOOK
			_hook.visible = true
			_line_target_point = get_global_mouse_position()
			ability_hook_used.emit()
		elif _input.is_action_just_pressed(PlayerInput.GameButton.BOBBER):
			_line_out = LineOut.BOBBER
			_bobber.visible = true
			ability_bobber_used.emit()
			_line_target_point = get_global_mouse_position()
		return
	
	_line_timer += delta
	
	if _line_timer > _get_ability_time():
		_line_out = LineOut.NONE
		_line_timer = 0
		_bobber.visible = false
		_hook.visible = false
		if _line_out == LineOut.BOBBER:
			ability_bobber_completed.emit()
		else:
			ability_hook_completed.emit()

func _physics_process(_delta: float) -> void:
	self.linear_velocity = _input.get_movement_vector() * GsomConsole.get_cvar("movespeed")
