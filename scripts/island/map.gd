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


func spawn_features() -> void:
	water_collision.disabled = false

	# Spawn natural features
	for i in range(0, 20):
		# Locate position to spawn features
		random_position = Vector3(randi_range(-100, 100), -100, randi_range(-100, 100))
		ray_cast_3d.target_position = random_position
		
		# Update raycast to match new position, and get collider
		ray_cast_3d.force_raycast_update()
		var collider = ray_cast_3d.get_collider()
		
		# Check if spawn position is valid
		if collider and collider.is_in_group("land") and not collider.is_in_group("water"):
			# Spawn feature if valid and increase loop index
			print("Spawning feature at: " + str(ray_cast_3d.get_collision_point()))
			var feature := randi_range(1,3)
			place_features.rpc(feature, ray_cast_3d.get_collision_point())
			i += 1
		
		# Repeat loop if position is not valid
		else:
			i = i
			
	# Spawn powerups
	for i in range(0, 10):
		# Locate position to spawn powerups
		random_position = Vector3(randi_range(-100, 100), -100, randi_range(-100, 100))
		ray_cast_3d.target_position = random_position

		# Update raycast to match new position, and get collider
		ray_cast_3d.force_raycast_update()
		var collider = ray_cast_3d.get_collider()

		# Check if spawn position is valid
		if collider and collider.is_in_group("land") and not collider.is_in_group("water"):
			# Spawn feature if valid and increase loop index
			print("Spawning feature at: " + str(ray_cast_3d.get_collision_point()))
			var feature := randi_range(4,7)
			place_features.rpc(feature, ray_cast_3d.get_collision_point())
			i += 1
		
		# Repeat loop if position is not valid
		else:
			i = i

	water_collision.disabled = true


@rpc("call_local")
func place_features(feature: int, spawn_position: Vector3) -> void:
	# Place random feature or powerup in determined position
	if feature == 1:
		var tree_object = tree.instantiate()
		tree_object.position = spawn_position
		add_child(tree_object, true)
				
	elif feature == 2:
		var bush_object = bush.instantiate()
		bush_object.position = spawn_position
		add_child(bush_object, true)
				
	elif feature == 3:
		var rock_object = rock.instantiate()
		rock_object.position = spawn_position
		add_child(rock_object, true)
		
	elif feature == 4:
		var ammo_object = ammo_item.instantiate()
		ammo_object.position = spawn_position + Vector3(0, 1, 0)
		add_child(ammo_object, true)
				
	elif feature == 5:
		var wall_object = wall_item.instantiate()
		wall_object.position = spawn_position + Vector3(0, 1, 0)
		add_child(wall_object, true)
				
	elif feature == 6:
		var jump_object = jump_item.instantiate()
		jump_object.position = spawn_position + Vector3(0, 1, 0)
		add_child(jump_object, true)
			
	elif feature == 7:
		var size_object = size_item.instantiate()
		size_object.position = spawn_position + Vector3(0, 1, 0)
		add_child(size_object, true)
