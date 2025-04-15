extends ProgressBar

func _process(delta: float) -> void:
	# shake when at full
	if value >= max_value:
		position.x = randf_range(-1, 1)
		position.y = randf_range(-1, 1)
