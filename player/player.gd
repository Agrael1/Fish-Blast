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
	var hitbox: Hitbox
	var hit: Hitbox.Hit

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

@export_subgroup("Bobber Stats")
@export var _bobber_length: float = 80
@export var _bobber_time: float = 1
@export var bobber_knockback: float = 1000

@export_subgroup("Hook Stats")
@export var _hook_length: float = 80
@export var _hook_time: float = 0.2

@export_subgroup("Movement")
## Movespeeds in units per second
@export var _movespeed: float = 350.0

@export_subgroup("Node Refs")
@export var _hook_charge_bar: ProgressBar
@export var _bobber_charge_bar: ProgressBar
@export var _bobber_hook_bar_visibility_parent: CanvasItem
@export var _hitbox_area: Area2D
@export var _input: PlayerInput
@export var _buffered_input: PlayerBufferedInput
@export var _hook: Area2D
@export var _bobber: Area2D

var _line_out := LineOut.NONE
var _line_timer: float = 0
var _line_target_point: Vector2
var _hook_charge_time: float = 0
var _bobber_charge_time: float = 0

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
	_hook.monitoring = false
	_bobber.visible = false
	_bobber.monitoring = false
	
	# dont show charge bars by default
	_bobber_hook_bar_visibility_parent.visible = false
	
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
	ability_bobber_hit_ex.connect(func(_data: AbilityFishingLineHitData) -> void:
		ability_bobber_hit.emit())
	ability_hook_hit_ex.connect(func(_data: AbilityFishingLineHitData) -> void:
		ability_hook_hit.emit())
	
	_bobber.area_entered.connect(_bobber_area_entered)

func _bobber_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if not hitbox:
		return
	var data := Hitbox.Hit.new()
	data.source = self
	data.damage = 0
	data.knockback = self.global_position.direction_to(_bobber.global_position) * bobber_knockback
	
	# pull towards the player if hit while reeling in
	var completion: float = _line_timer / GsomConsole.get_cvar("player_bobber_time")
	if completion > 0.5:
		data.knockback *= -1
	
	var ability_hit_data := AbilityFishingLineHitData.new()
	ability_hit_data.charged = false
	ability_hit_data.hitbox = hitbox
	ability_hit_data.hit = data
	ability_bobber_hit_ex.emit(ability_hit_data)
	TimeControl.force_hitstop(0.016)
	CameraControl.shake(2, 0.1)
	
	hitbox.hit(data)

func _process(delta: float) -> void:
	const GA = PlayerInput.GameAction
	var is_charging_hook := false
	var is_charging_bobber := false
	
	const BufferedInputResponse = PlayerBufferedInput.BufferedInputResponse
	var hook_input: BufferedInputResponse = _buffered_input.get_hook_just_pressed_input()
	var bobber_input: BufferedInputResponse = _buffered_input.get_bobber_just_pressed_input()
	
	if _input.is_action_pressed(GA.CHARGE):
		# use hook with buffer if we already had some charge
		if hook_input.is_just_pressed and _line_out == LineOut.NONE and _hook_charge_time > 0:
			_use_hook()
			# mark it so it is no longer just pressed, it has been used to activate a hook
			hook_input.is_just_pressed_and_consume()
		elif _input.is_action_pressed(GA.HOOK) and _line_out != LineOut.HOOK:
			# charge whenever your not already hooking
			_hook_charge_time += delta
			is_charging_hook = true
		elif _input.is_action_just_released(GA.HOOK):
			if _line_out == LineOut.NONE:
				_use_hook()
		
		if _input.is_action_pressed(GA.BOBBER):
			_bobber_charge_time += delta
			is_charging_bobber = true
		elif _input.is_action_just_released(GA.BOBBER):
			if _line_out == LineOut.NONE:
				_use_bobber()
	else:
		# not charging
		pass
	
	if not is_charging_hook:
		_hook_charge_time -= delta

func _physics_process(delta: float) -> void:
	linear_velocity = _input.get_movement_vector() * GsomConsole.get_cvar("player_movespeed")
	
	if _line_out != LineOut.NONE:
		var time_total := _get_ability_time()
		var completion := _line_timer / time_total
		var lerp_weight := completion * 2.0
		if completion > 0.5:
			lerp_weight = 2.0 - lerp_weight
		
		var final_position := _line_target_point.lerp(global_position, 1.0 - lerp_weight)
		
		# TODO: put some nice bouncy curve equation instead of this linear interp
		if _line_out == LineOut.BOBBER:
			_bobber.global_position = final_position
		else:
			assert(_line_out == LineOut.HOOK)
			_hook.global_position = final_position

func _get_ability_time() -> float:
	assert(_line_out != LineOut.NONE)
	return GsomConsole.get_cvar("player_bobber_time" if _line_out == LineOut.BOBBER else "player_hook_time")

func _update_line_out_state_and_charge(delta: float) -> void:
	var is_charge_modal_key_pressed: bool = _input.is_action_pressed(PlayerInput.GameAction.CHARGE)
	
	if is_charge_modal_key_pressed:
		_bobber_hook_bar_visibility_parent.visible = true
		
		if _input.is_action_pressed(PlayerInput.GameAction.HOOK) and _line_out != LineOut.HOOK:
			_hook_charge_time += delta
		elif _input.is_action_just_released(PlayerInput.GameAction.HOOK) and _line_out != LineOut.HOOK:
			pass
		
		if _input.is_action_pressed(PlayerInput.GameAction.BOBBER):
			_bobber_charge_time += delta
		
	else:
		if _hook_charge_time <= 0 and _bobber_charge_time <= 0:
			_bobber_hook_bar_visibility_parent.visible = false
		
			if _line_out == LineOut.NONE:
				_change_line_out_state_on_press()
	
	_line_timer += delta
	_remove_line_after_time_up()

## If the timer for the current line ability (hook or bobber) is up, revert back
## to having nothing cast out and hide the hook/bobber
func _remove_line_after_time_up() -> void:
	if _line_timer > _get_ability_time():
		_line_out = LineOut.NONE
		_line_timer = 0
		_bobber.visible = false
		_hook.visible = false
		_bobber.monitoring = false
		_hook.monitoring = false
		if _line_out == LineOut.BOBBER:
			ability_bobber_completed.emit()
		else:
			ability_hook_completed.emit()

func _use_hook() -> void:
	assert(_line_out == LineOut.NONE)
	var c_hook_length: float = GsomConsole.get_cvar("player_hook_length")
	_line_out = LineOut.HOOK
	_hook.visible = true
	_hook.monitoring = true
	_line_target_point = global_position + global_position.direction_to(get_global_mouse_position()) * c_hook_length
	ability_hook_used.emit()
	_hook_charge_time = 0

func _use_bobber() -> void:
	assert(_line_out == LineOut.NONE)
	var c_bobber_length: float = GsomConsole.get_cvar("player_bobber_length")
	_line_out = LineOut.BOBBER
	_bobber.visible = true
	_bobber.monitoring = true
	ability_bobber_used.emit()
	_line_target_point = global_position + global_position.direction_to(get_global_mouse_position()) * c_bobber_length
	_bobber_charge_time = 0
