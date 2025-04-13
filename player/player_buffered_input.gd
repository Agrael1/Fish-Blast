class_name PlayerBufferedInput
extends Node

@export var player_input: PlayerInput

@export_category("Action Buffer Lengths")
@export var hook_buffer_seconds: float = 0.2
@export var bobber_buffer_seconds: float = 0.2

@onready var _time_since_hook_pressed: float = hook_buffer_seconds + 1
@onready var _time_since_bobber_pressed: float = bobber_buffer_seconds + 1

class BufferedInputResponse extends RefCounted:
	var is_just_pressed: bool
	var _consume_func: Callable
	func is_just_pressed_and_consume() -> bool:
		if is_just_pressed:
			_consume_func.call()
			return true
		return false

func get_hook_just_pressed_input() -> BufferedInputResponse:
	var out := BufferedInputResponse.new()
	out.is_just_pressed = _time_since_hook_pressed < hook_buffer_seconds
	out._consume_func = _consume_hook_input
	return out

func get_bobber_just_pressed_input() -> BufferedInputResponse:
	var out := BufferedInputResponse.new()
	out.is_just_pressed = _time_since_bobber_pressed < bobber_buffer_seconds
	out._consume_func = _consume_bobber_input
	return out

func _consume_hook_input() -> void:
	_time_since_hook_pressed = hook_buffer_seconds + 1

func _consume_bobber_input() -> void:
	_time_since_bobber_pressed = bobber_buffer_seconds + 1

func _ready() -> void:
	# NOTE: not connecting signals in code here just to automate this process,
	# if all inputs are buffered then you have to remember to reconnect all the
	# signals if you delete the node
	player_input.action_pressed_event_in_game.connect(_on_action_pressed_in_game)

func _process(delta: float) -> void:
	if _time_since_hook_pressed <= hook_buffer_seconds:
		_time_since_hook_pressed += delta
	if _time_since_bobber_pressed <= bobber_buffer_seconds:
		_time_since_bobber_pressed += delta

func _on_action_pressed_in_game(action: PlayerInput.GameAction) -> void:
	match action:
		PlayerInput.GameAction.HOOK:
			_time_since_hook_pressed = 0
		PlayerInput.GameAction.BOBBER:
			_time_since_bobber_pressed = 0
