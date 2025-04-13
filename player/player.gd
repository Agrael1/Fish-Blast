class_name Player
extends RigidBody2D

enum LineOut {
	NONE,
	HOOK,
	BOBBER,
}

class AbilityFishingLineHitData extends RefCounted:
	var charged_for_seconds: float
	var charged: bool
	var hit: Node2D

signal ability_bobber_used()
signal ability_bobber_used_ex(charged: bool, charged_for_seconds: float)
signal ability_hook_used()
signal ability_hook_used_ex(charged: bool, charged_for_seconds: float)
## Bobber reeled back in, another ability can now be used
signal ability_bobber_completed()
signal ability_bobber_completed_ex(hits: Array[AbilityFishingLineHitData])
## Hook reeled back in, another ability can now be used
signal ability_hook_completed()
signal ability_hook_completed_ex(hits: Array[AbilityFishingLineHitData])
## Shift pressed
signal ability_charge_modifier_engaged()
## Shift released
signal ability_charge_modifier_released()
## Pressed hook mouse button while shift was pressed
signal ability_hook_charge_engaged()
## Pressed bobber mouse button while shift was pressed
signal ability_bobber_charge_engaged()
## Fires on the frame that the bobber comes into contact with an object it can hit
signal ability_bobber_hit()
signal ability_bobber_hit_ex(data: AbilityFishingLineHitData)
## Fires on the frame that the hook comes into contact with an object it can hit
signal ability_hook_hit()
signal ability_hook_hit_ex(data: AbilityFishingLineHitData)

@export_category("Bobber Stats")
@export var _bobber_length: float = 80
@export var _bobber_time: float = 1

@export_category("Hook Stats")
@export var _hook_length: float = 80
@export var _hook_time: float = 0.2

@export_category("Player Movement")
@export var _movespeed: float = 350.0

@onready var _hitbox_area: Area2D = $HitboxArea
@onready var _input: PlayerInput = $PlayerInput
@onready var _buffered_input: PlayerBufferedInput = $PlayerInput/PlayerBufferedInput
@onready var _hook: Area2D = $Hook
@onready var _bobber: Area2D = $Bobber

var _line_out := LineOut.NONE
var _line_timer: float = 0
var _line_target_point: Vector2

func _ready() -> void:
	# there's only one player, so its okay for it to register cvars
	GsomConsole.register_cvar("player_movespeed", _movespeed,
		"Positive floating point number for the maximum speed reachable by the player with WASD")
	GsomConsole.register_cvar("player_hook_length", _hook_length,
		"Positive floating point number for the maximum distance that a " +
		"hook can travel before returning to the player.")
	GsomConsole.register_cvar("player_bobber_length", _bobber_length,
		"Positive floating point number for the maximum distance that a " +
		"bobber can travel before returning to the player.")
	GsomConsole.register_cvar("player_hook_time", _hook_time,
		"Positive floating point number for the base (uncharged) time in " +
		"seconds it takes for a hook to release from the player and return.")
	GsomConsole.register_cvar("player_bobber_time", _bobber_time,
		"Positive floating point number for the base (uncharged) time in " +
		"seconds it takes for a bobber to release from the player and return.")
	
	_hook.visible = false
	_bobber.visible = false
	_hitbox_area.area_entered.connect(func(_unused) -> void:
		CameraControl.shake(4, 0.1))
	
	# connect *_ex signals so that you only have to fire the *_ex signal and the simpler one
	# will also fire. these are glue that just ignore all function arguments
	ability_bobber_used_ex.connect(func(_charged: bool, _charged_for_seconds: float) -> void:
		ability_bobber_used.emit())
	ability_hook_used_ex.connect(func(_charged: bool, _charged_for_seconds: float) -> void:
		ability_hook_used.emit())
	ability_bobber_completed_ex.connect(func(_hits: Array[AbilityFishingLineHitData]) -> void:
		ability_bobber_completed.emit())
	ability_hook_completed_ex.connect(func(_hits: Array[AbilityFishingLineHitData]) -> void:
		ability_hook_completed.emit())
	# still glue mostly but also throw some hitstop in there
	ability_bobber_hit_ex.connect(func(_data: AbilityFishingLineHitData) -> void:
		TimeControl.queue_hitstop(0.16)
		ability_bobber_hit.emit())
	ability_hook_hit_ex.connect(func(_data: AbilityFishingLineHitData) -> void:
		TimeControl.queue_hitstop(0.16)
		ability_hook_hit.emit())

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
	return GsomConsole.get_cvar("player_bobber_time" if _line_out == LineOut.BOBBER else "player_hook_time")

func _update_line_out_state(delta: float) -> void:
	if _line_out == LineOut.NONE:
		if _buffered_input.get_hook_just_pressed_input().is_just_pressed_and_consume():
			var c_hook_length: float = GsomConsole.get_cvar("player_hook_length")
			_line_out = LineOut.HOOK
			_hook.visible = true
			_line_target_point = global_position + global_position.direction_to(get_global_mouse_position()) * c_hook_length
			ability_hook_used.emit()
		elif _buffered_input.get_bobber_just_pressed_input().is_just_pressed_and_consume():
			var c_bobber_length: float = GsomConsole.get_cvar("player_bobber_length")
			_line_out = LineOut.BOBBER
			_bobber.visible = true
			ability_bobber_used.emit()
			_line_target_point = global_position + global_position.direction_to(get_global_mouse_position()) * c_bobber_length
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
	self.linear_velocity = _input.get_movement_vector() * GsomConsole.get_cvar("player_movespeed")
