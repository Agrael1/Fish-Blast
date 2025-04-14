## Contains an array of hitboxes. Whenever any one of them is hit, this will
## propagate the signal.
class_name HitboxBrain
extends Node

signal became_invulnerable()
signal became_vulnerable()
signal was_hit()
signal was_hit_ex(hit: Hitbox.Hit)
signal was_hit_source(hit: Hitbox.Hit, source: Hitbox)

@export_category("I-frames")
@export var invuln_time_seconds: float = 0
@export_category("Hitboxes To Join")
## Hitboxes listed here will cause this node to emit was_hit() when they emit
## was_hit()
@export var hitboxes: Array[Hitbox]
## Whether Hitbox nodes childed to this node should be added to the array
@export var add_child_hitboxes: bool = true

var _invuln_timer: float = 0:
	set(value):
		var is_invulnerable := _invuln_timer < 0
		var will_be_invulnerable := value > 0
		if not is_invulnerable and will_be_invulnerable:
			became_invulnerable.emit()
		elif is_invulnerable and not will_be_invulnerable:
			became_vulnerable.emit()
		_invuln_timer = value
	get:
		return _invuln_timer

func make_invulnerable_for_seconds(seconds: float) -> void:
	_invuln_timer = invuln_time_seconds

func _ready() -> void:
	was_hit_source.connect(func(hit: Hitbox.Hit, _source: Hitbox) -> void:
		was_hit.emit()
		was_hit_ex.emit(hit))
	
	if add_child_hitboxes:
		hitboxes.append_array(get_children().filter(func(child: Node) -> bool: return child is Hitbox))
	
	for hitbox: Hitbox in hitboxes:
		hitbox.was_hit_ex.connect(func(hit: Hitbox.Hit) -> void:
			was_hit_source.emit(hit, hitbox))

func _hitbox_was_hit(hit: Hitbox.Hit) -> void:
	if _invuln_timer < invuln_time_seconds:
		was_hit_ex.emit(hit)
		make_invulnerable_for_seconds(invuln_time_seconds)

func _process(delta: float) -> void:
	if _invuln_timer > 0:
		_invuln_timer -= delta
