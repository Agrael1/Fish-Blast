extends Node

@export var spawn_area: CollisionShape2D
@export var spawn_table: Array[SpawnTableEntry]

var _shape: RectangleShape2D
var _spawn_offset := Vector2.ZERO

var _spawn_times: PackedFloat64Array

func _ready() -> void:
	assert(spawn_area.shape is RectangleShape2D, "area for random spawner must be rectangle");
	_shape = spawn_area.shape
	_spawn_offset = spawn_area.position
	_spawn_times.resize(spawn_table.size())
	for idx in spawn_table.size():
		_spawn_times[idx] = spawn_table[idx].generate_random_spawn_interval_seconds()

func spawn(scene: PackedScene, amount: int) -> void:
	for idx in amount:
		var spawned = scene.instantiate()
		spawned.global_position = spawn_area.global_position + Vector2(0, randf_range(-_shape.size.y, _shape.size.y))
		add_child(spawned, true)

func _process(delta: float) -> void:
	for idx in _spawn_times.size():
		_spawn_times[idx] -= delta

		if _spawn_times[idx] <= 0:
			spawn(spawn_table[idx].scene, spawn_table[idx].generate_random_number_to_spawn())
			_spawn_times[idx] = spawn_table[idx].generate_random_spawn_interval_seconds()
