class_name PlayerBufferedInput
extends Node

@export var player_input: PlayerInput

@export_category("Action Buffer Lengths")
@export var hook_buffer_seconds: float = 0.2
@export var bobber_buffer_seconds: float = 0.2

@onready var _time_since_hook_pressed: float = hook_buffer_seconds + 1
@onready var _time_since_bobber_pressed: float = bobber_buffer_seconds + 1
@onready var _time_since_hook_released: float = hook_buffer_seconds + 1
@onready var _time_since_bobber_released: float = bobber_buffer_seconds + 1

## Note that a buffered input response can be both pressed and released at the
## same time. This may happen if the player spams the button faster than the
## buffer window.
class BufferedInputResponse extends RefCounted:
	var is_just_pressed: bool
	var is_just_released: bool
	var _consume_pressed_func: Callable
	var _consume_released_func: Callable
	func is_just_pressed_and_consume() -> bool:
		if is_just_pressed:
			_consume_pressed_func.call()
			return true
		return false
	func is_just_released_and_consume() -> bool:
		if is_just_released:
			_consume_released_func.call()
			return true
		return false

func get_hook_input() -> BufferedInputResponse:
	var out := BufferedInputResponse.new()
	out.is_just_pressed = _time_since_hook_pressed < hook_buffer_seconds
	out.is_just_released = _time_since_hook_released < hook_buffer_seconds
	out._consume_pressed_func = _consume_hook_pressed_input
	out._consume_released_func = _consume_hook_released_input
	return out

func get_bobber_input() -> BufferedInputResponse:
	var out := BufferedInputResponse.new()
	out.is_just_pressed = _time_since_bobber_pressed < bobber_buffer_seconds
	out.is_just_released = _time_since_bobber_released < bobber_buffer_seconds
	out._consume_pressed_func = _consume_bobber_pressed_input
	out._consume_released_func = _consume_bobber_released_input
	return out

func _consume_hook_pressed_input() -> void:
	_time_since_hook_pressed = hook_buffer_seconds + 1

func _consume_bobber_pressed_input() -> void:
	_time_since_bobber_pressed = bobber_buffer_seconds + 1

func _consume_hook_released_input() -> void:
	_time_since_hook_released = hook_buffer_seconds + 1

func _consume_bobber_released_input() -> void:
	_time_since_bobber_released = bobber_buffer_seconds + 1

func _ready() -> void:
	# NOTE: not connecting signals in code here just to automate this process,
	# if all inputs are buffered then you have to remember to reconnect all the
	# signals if you delete the node
	player_input.action_pressed_event_in_game.connect(_on_action_pressed_in_game)
	player_input.action_released_event_in_game.connect(_on_action_released_in_game)

func _process(delta: float) -> void:
	if _time_since_hook_pressed <= hook_buffer_seconds:
		_time_since_hook_pressed += delta
	if _time_since_bobber_pressed <= bobber_buffer_seconds:
		_time_since_bobber_pressed += delta
	if _time_since_hook_released <= hook_buffer_seconds:
		_time_since_hook_released += delta
	if _time_since_bobber_released <= bobber_buffer_seconds:
		_time_since_bobber_released += delta

func _on_action_pressed_in_game(action: PlayerInput.GameAction) -> void:
	match action:
		PlayerInput.GameAction.HOOK:
			_time_since_hook_pressed = 0
		PlayerInput.GameAction.BOBBER:
			_time_since_bobber_pressed = 0

func _on_action_released_in_game(action: PlayerInput.GameAction) -> void:
	match action:
		PlayerInput.GameAction.HOOK:
			_time_since_hook_released = 0
		PlayerInput.GameAction.BOBBER:
			_time_since_bobber_released = 0
