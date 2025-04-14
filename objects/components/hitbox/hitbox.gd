class_name Hitbox
extends Area2D

class HitData extends RefCounted:
	var damage: float
	## Relative to this HitBox
	var knockback: Vector2
	var source: Node

# this signal is called was_hit to avoid name conflicts with the hit() method.
# normally i would choose the past tense word for the signal, but "hitted" is
# not a word in this stupid language
signal was_hit()
signal was_hit_ex(data: HitData)

func _ready() -> void:
	assert(collision_mask == 0, "Found that some bits were set in collision mask. " +
		"Unset the mask, a hitbox should collide with nothing, other things will " +
		"collide with it.")

## When hitting something, just call its hit method and allow the object to
## subscribe to signals and handle the hit itself
func hit(data: HitData) -> void:
	was_hit_ex.emit(data)
	was_hit.emit()
