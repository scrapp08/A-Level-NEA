extends Node3D

var random_position: Vector3

var tree := preload("res://objects/scenery/tree.tscn")
var bush := preload("res://objects/scenery/bush.tscn")
var rock := preload("res://objects/scenery/rock.tscn")

var ammo_item := preload("res://objects/powerups/ammo_item.tscn")
var wall_item := preload("res://objects/powerups/wall/wall_item.tscn")
var jump_item := preload("res://objects/powerups/jump_item.tscn")
var size_item := preload("res://objects/powerups/size_item.tscn")

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var water_collision: CollisionShape3D = $Water/StaticBody3D/CollisionShape3D

#Target should be between, -100->100, ~, -100->100
func spawn_features() -> void:
	water_collision.disabled = false

	for i in range(0, 10):
		random_position = Vector3(randi_range(-100, 100), -100, randi_range(-100, 100))
		ray_cast_3d.target_position = random_position

		ray_cast_3d.force_raycast_update()
		var collider = ray_cast_3d.get_collider()

		if collider and collider.is_in_group("land"):
			print("Spawning feature at: " + str(ray_cast_3d.get_collision_point()))
			var feature := randi_range(1,3)
			if feature == 1:
				var tree_object = tree.instantiate()
				tree_object.position = ray_cast_3d.get_collision_point()
				add_child(tree_object)
				
			elif feature == 2:
				var bush_object = bush.instantiate()
				bush_object.position = ray_cast_3d.get_collision_point()
				add_child(bush_object)
				
			elif feature == 3:
				var rock_object = rock.instantiate()
				rock_object.position = ray_cast_3d.get_collision_point()
				add_child(rock_object)
			

	water_collision.disabled = true
