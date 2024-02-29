extends Node3D

@onready var raycast: RayCast3D = get_parent().get_node("Head/Camera/RayCast")
@onready var wall := preload("res://objects/powerups/wall/wall.tscn")


func _ready() -> void:
	set_as_top_level(true)
	global_transform.origin = raycast.get_collision_point()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("secondary_attack"):
		create_wall.rpc()


func _process(delta: float) -> void:
	global_transform.origin = raycast.get_collision_point()
	rotation = get_parent().rotation


@rpc("any_peer", "call_local")
func create_wall() -> void:
	var w = wall.instantiate()
	w.global_transform = global_transform
	get_parent().get_parent().add_child(w)
	queue_free()
