class_name SpawnTableEntry
extends Resource

enum FindSceneSizeMethod {
	USE_FIRST_RECTANGLE_AREA_2D,
	MANUAL_ENTRY,
}

# NOTE: this will probably need to be expanded a lot, ideally there'd be an
# editor plugin (or external editor tool) where we could sort of draw shapes
# for the spawned items and drag them around like musical notes in a DAW,
# particularly with an easy way to do all of these operations:
# "i want to JUST this item in the spawn pattern" and
# "i want to move this item and all the items after it should move, too" and
# "i want to scale/stretch this portion, so the items spawn at longer time
# intervals"
# maybe godot animation track is a good substitute for this?
@export var scene: PackedScene
@export var spawn_interval_min_seconds: float = 0.1
@export var spawn_interval_max_seconds: float = 1

# TODO: something like this, probably
#enum SpawnSpreadPattern {
#    EVEN_DISTRIBUTION,
#    CLUMPED,
#}

@export_category("Spawn Variation")
@export var amount_to_spawn_at_once_min: int = 1
@export var amount_to_spawn_at_once_max: int = 1

@export_category("Scene Size")
@export var find_scene_size_method := FindSceneSizeMethod.USE_FIRST_RECTANGLE_AREA_2D
@export_category("Scene Size - Manual Entry")
@export var dimensions: Vector2
@export var offset := Vector2.ZERO

func _ready() -> void:
	assert(scene)
	assert(spawn_interval_min_seconds <= spawn_interval_max_seconds)

func generate_random_number_to_spawn() -> int:
	return randi_range(amount_to_spawn_at_once_min, amount_to_spawn_at_once_max)

func generate_random_spawn_interval_seconds() -> float:
	return randf_range(spawn_interval_min_seconds, spawn_interval_max_seconds)

func get_dimensions(spawned: Node) -> Vector2:
	if find_scene_size_method == FindSceneSizeMethod.MANUAL_ENTRY:
		return dimensions
	else:
		assert(find_scene_size_method == FindSceneSizeMethod.USE_FIRST_RECTANGLE_AREA_2D)
		assert(spawned.scene_file_path == scene.resource_path,
		"attempt to get_dimensions with a node which does not appear to be the"
		+ " spawned scene for that SpawnTableEntry")
		var output: Dictionary = {}
		_search_for_first_rectangle_area2d(spawned, output)
		var shape: CollisionShape2D = output[&"found_shape"]

		return (shape.shape as RectangleShape2D).size

func get_offset(spawned: Node) -> Vector2:
	if find_scene_size_method == FindSceneSizeMethod.MANUAL_ENTRY:
		return offset
	else:
		assert(find_scene_size_method == FindSceneSizeMethod.USE_FIRST_RECTANGLE_AREA_2D)
		assert(spawned.scene_file_path == scene.resource_path,
		"attempt to get_dimensions with a node which does not appear to be "
		+ "the spawned scene for that SpawnTableEntry")
		var output: Dictionary = {}
		_search_for_first_rectangle_area2d(spawned, output)
		var shape: CollisionShape2D = output[&"found_shape"]
		return shape.position

func _search_for_first_rectangle_area2d(root: Node, context: Dictionary) -> void:
	_recursive_node_dfs(root, func(node: Node) -> bool:
		if node is Area2D and node.get_child_count() == 1:
			var collision_shape = node.get_child(0) as CollisionShape2D
			if collision_shape != null and collision_shape.shape is RectangleShape2D:
				context[&"found_shape"] = collision_shape
				return true
		return false
		)

	assert(context.has(&"found_shape"), "attempt to use "
	+ "FindSceneSizeMethod.USE_FIRST_RECTANGLE_AREA_2D but the given scene "
	+ "does not contain an Area2D with a single RectangleShape2D "
	+ "CollisionShape2D child.")

# callback should take one node to process  and return boolean, true if found and recursion should stop
func _recursive_node_dfs(root: Node, callback: Callable) -> bool:
	for node in root.get_children():
		if callback.call(node) or _recursive_node_dfs(node, callback):
			return true # stop execution
	# no children were found that said to stop execution
	return false
