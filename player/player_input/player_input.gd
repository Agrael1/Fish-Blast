class_name PlayerInput
extends Node

enum ButtonState {
	UNPRESSED,
	JUST_PRESSED,
	PRESSED,
	JUST_RELEASED,
}

enum GameAction { # as opposed to actions for navigating menus
	UP,
	DOWN,
	LEFT,
	RIGHT,
	HOOK,
	BOBBER,
	CHARGE,
	# must be last
	MAX_BUTTON,
}

## The action's name in the project's input map settings
const CORRESPONDING_STRINGS: PackedStringArray = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"ability_hook",
	"ability_bobber",
	"ability_modifier_charge",
];

# retained-mode / signal-handling interface
signal mouse_moved_in_game(movement: Vector2)
signal action_pressed_event_in_game(action: GameAction)
signal action_released_event_in_game(action: GameAction)

var _button_states : PackedByteArray = []
var _button_states_physics : PackedByteArray = []

func is_action_just_pressed(action: GameAction) -> bool:
	var array := _button_states_physics if Engine.is_in_physics_frame() else _button_states
	return array[action] == ButtonState.JUST_PRESSED

func is_action_pressed(action: GameAction) -> bool:
	var array := _button_states_physics if Engine.is_in_physics_frame() else _button_states
	var state := array[action]
	return state == ButtonState.PRESSED or state == ButtonState.JUST_PRESSED

func is_action_just_released(action: GameAction) -> bool:
	var array := _button_states_physics if Engine.is_in_physics_frame() else _button_states
	return array[action] == ButtonState.JUST_RELEASED

func get_movement_vector() -> Vector2:
	var out := Vector2.ZERO
	out += ((1 if is_action_pressed(GameAction.RIGHT) else 0) - (1 if is_action_pressed(GameAction.LEFT) else 0)) * Vector2(1, 0)
	out += ((1 if is_action_pressed(GameAction.DOWN) else 0) - (1 if is_action_pressed(GameAction.UP) else 0)) * Vector2(0, 1)
	# protect from normalizing zero vector
	if out.length_squared() == 0.0:
		return out
	return out.normalized()

func _ready() -> void:
	_button_states.resize(GameAction.MAX_BUTTON)
	_button_states.fill(ButtonState.UNPRESSED)
	_button_states_physics.resize(GameAction.MAX_BUTTON)
	_button_states_physics.fill(ButtonState.UNPRESSED)
	assert(CORRESPONDING_STRINGS.size() == _button_states.size(), "New game button improperly added to GameButton enum and CORRESPONDING_STRINGS array.")

func _process(_delta: float) -> void:
	if get_tree().paused:
		# if player presses buttons during pause, they just kind of stay
		# buffered until unpause, and then the frame after that they are
		# marked as held. that way on unpause people can check "just_pressed"
		# and its like the player pressed it the frame of the unpause
		return
	_remove_just_pressed_or_released.call_deferred(_button_states)

func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return
	_remove_just_pressed_or_released.call_deferred(_button_states_physics)

func _remove_just_pressed_or_released(button_state_array: PackedByteArray) -> void:
	for idx in GameAction.MAX_BUTTON:
		var state := button_state_array[idx]
		if state == ButtonState.JUST_PRESSED:
			button_state_array[idx] = ButtonState.PRESSED
		elif state == ButtonState.JUST_RELEASED:
			button_state_array[idx] = ButtonState.UNPRESSED

func _unhandled_input(event: InputEvent):
	# filter out mouse motion events ourselves. there is _unhandled_key_input but
	# it seems to filter out mouse buttons as well, which prevents rebinding keys
	# to mouse buttons :/
	if event is InputEventMouseMotion:
		mouse_moved_in_game.emit((event as InputEventMouseMotion).get_relative())
		get_viewport().set_input_as_handled()
		return
	
	var handled := false
	for idx in CORRESPONDING_STRINGS.size():
		var string := CORRESPONDING_STRINGS[idx]
		if event.is_action_pressed(string):
			_button_states[idx] = ButtonState.JUST_PRESSED
			_button_states_physics[idx] = ButtonState.JUST_PRESSED
			handled = true
			action_pressed_event_in_game.emit(idx) # int to enum cast here
		elif event.is_action_released(string):
			_button_states[idx] = ButtonState.JUST_RELEASED
			_button_states_physics[idx] = ButtonState.JUST_RELEASED
			handled = true
			action_released_event_in_game.emit(idx) # int to enum cast here
	if handled:
		get_viewport().set_input_as_handled()
