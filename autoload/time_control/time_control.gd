extends Node

# called whenever a pause happens. if pause_class is &"hitstop", hitstop happened.
# if pause_class is &"menu", then the pause menu pause happened.
# NOTE: this includes if another pause mode happens on top. for example, if you
# start hitstop, then paused_for_class(&"hitstop") will fire. but then if you
# open the menu, unpaused_for_class(&"hitstop") will fire, followed by
# paused_for_class(&"menu"). When closing the menu, the opposite signals will
# happen, causing a second paused_for_class(&"hitstop") even though
# queue_hitstop may only have been called once.
signal paused_for_class(pause_class: StringName)
signal unpaused_for_class(pause_class: StringName)

@onready var hitstop_timer: Timer = $HitstopTimer
var _hitstop_queue: PackedFloat32Array

# Keep a stack of all possible states of pausing, returning to the one before whenever the top is
# unpaused. For example, if you are anchor dashing, this might just be [ "anchor_dashing" ].
# but then hitstop might happen, in which case you have [ "anchor_dashing", "hitstop" ]. when the
# hitstop is done, it is popped off the stack. Then, if you pressed the pause button while
# anchor dashing, it would be [ "anchor_dashing", "menu" ]
# when pausing with a given string NAME, all nodes in group "NAME_paused" are set to pause, whereas
# all nodes in group "NAME_unpaused" are set to continue processing
var _paused_stack: Array[StringName]

func _ready() -> void:
	hitstop_timer.paused = true # pause until hitstop happens
	hitstop_timer.timeout.connect(_update_hitstop)

	# make hitstop timer only run when hitstop pause is active
	paused_for_class.connect(func(pause_class: StringName) -> void:
		if pause_class == &"hitstop":
			hitstop_timer.paused = false
		)
	unpaused_for_class.connect(func(pause_class: StringName) -> void:
		if pause_class == &"hitstop":
			hitstop_timer.paused = true
		)

# check whether we are currently paused and the reason is hitstop
func _is_hitstop_paused() -> bool:
	if _paused_stack.is_empty():
		return false
	return _paused_stack[_paused_stack.size() - 1] == &"hitstop"

# If there's a hitstop, execute it. Otherwise, unpause the game
func _update_hitstop() -> void:
	assert(_is_hitstop_paused(), "timer ran out while no pause class or another pause class was active")
	# check if we have more hitstops to do, in which case stay hitstop paused and restart timer
	if not _hitstop_queue.is_empty():
		var seconds := _hitstop_queue[0]
		_hitstop_queue.remove_at(0)
		hitstop_timer.start(seconds)
	else:
		# no more hitstops, relieve control back to the previous pause mode
		unpause_game(&"hitstop")

# Pause the game for some amount of time, in seconds. If multiple people request hitstop all on
# the same frame, their hitstops will add up, each being executed one after the other
func queue_hitstop(seconds: float) -> void:
	_hitstop_queue.append(seconds)
	var hitstop_in_stack := _paused_stack.find(&"hitstop") != -1
	if not hitstop_in_stack:
		assert(hitstop_timer.paused)
		pause_game(&"hitstop")
		assert(not hitstop_timer.paused)
		_update_hitstop()

## Pause the game for some amount of time in seconds. Only one of these requests can be made per
## frame, and it overrides any requests that have been made via queue_hitstop.
## TODO: maybe some namespaced hitstop thing where it only accepts one hitstop per namespace per frame?
func force_hitstop(seconds: float) -> void:
	_hitstop_queue.clear()
	queue_hitstop(seconds)

func slow_time(time_scale: float, duration: float, callback: Callable = func(): pass) -> void:
	Engine.time_scale = maxf(time_scale, pow(2, -24))
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	callback.call()

# Pause the game with a given pause type.
# Never use "hitstop" as pause type- always use queue_hitstop instead.
func pause_game(pause_class: StringName = &"menu") -> void:
	if _paused_stack.find(pause_class) != -1:
		push_warning("attempt to pause with class \"", pause_class ,"\", but that class is already paused")
		return

	# unpause the previous pause class, if there was one
	if not _paused_stack.is_empty():
		var old_pause_class := _paused_stack[_paused_stack.size() - 1]
		_unpause_internal(old_pause_class)
		unpaused_for_class.emit(old_pause_class)

	# pause the nodes related to this pause class
	_pause_internal(pause_class)

	get_tree().paused = true
	_paused_stack.append(pause_class)
	paused_for_class.emit(pause_class)

func unpause_game(pause_class: StringName = &"menu") -> void:
	if _paused_stack.is_empty():
		push_warning("attempt to unpause game when it is not paused")
		return
	var old_pause_class := _paused_stack[_paused_stack.size() - 1]
	if pause_class != old_pause_class:
		push_warning("attempt to unpause for a class which was not the last class to pause. Pause class ", old_pause_class, " has precedence right now.")
		return

	# unpause nodes in special groups
	_unpause_internal(pause_class)

	# remove ourselves from the pause stack
	_paused_stack.remove_at(_paused_stack.size() - 1)
	unpaused_for_class.emit(pause_class)

	# if there is another pause under us, pause it
	if not _paused_stack.is_empty():
		var new_top_pause_class := _paused_stack[_paused_stack.size() - 1]
		_pause_internal(new_top_pause_class)
		paused_for_class.emit(new_top_pause_class)
	else:
		# otherwise, we are now unpaused
		get_tree().paused = false

# revert all nodes for a certain pause class to their usual process mode (should always be "inherit")
func _unpause_internal(pause_class: StringName) -> void:
	var paused := get_tree().get_nodes_in_group(str(pause_class, "_paused"))
	var unpaused := get_tree().get_nodes_in_group(str(pause_class, "_unpaused"))
	for node: Node in paused:
		assert(node.process_mode == Node.PROCESS_MODE_DISABLED)
		node.process_mode = Node.PROCESS_MODE_INHERIT
	for node: Node in unpaused:
		assert(node.process_mode == Node.PROCESS_MODE_ALWAYS)
		node.process_mode = Node.PROCESS_MODE_INHERIT

# This applies special NAME_paused and NAME_unpaused group effects
func _pause_internal(pause_class: StringName) -> void:
	var set_paused := get_tree().get_nodes_in_group(str(pause_class, "_paused"))
	var set_unpaused := get_tree().get_nodes_in_group(str(pause_class, "_unpaused"))
	for node: Node in set_paused:
		if node.process_mode != Node.PROCESS_MODE_INHERIT:
			push_warning("Node in pause class ", pause_class, " does not use PROCESS_MODE_INHERIT. ignoring whatever its set to")
		node.process_mode = Node.PROCESS_MODE_DISABLED
	for node: Node in set_unpaused:
		if node.process_mode != Node.PROCESS_MODE_INHERIT:
			push_warning("Node in pause class ", pause_class, " does not use PROCESS_MODE_INHERIT. ignoring whatever its set to")
		node.process_mode = Node.PROCESS_MODE_ALWAYS
