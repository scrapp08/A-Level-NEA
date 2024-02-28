extends Node3D

var random_position: Vector3

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var water_collision: CollisionShape3D = $Water/StaticBody3D/CollisionShape3D

#Target should be between, -100->100, ~, -100->100
func spawn_features() -> void:
	water_collision.disabled = false

	for i in range(0, 15):
		random_position = Vector3(randi_range(-100, 100), -100, randi_range(-100, 100))
		ray_cast_3d.target_position = random_position
		print("Target set to: " + str(ray_cast_3d.target_position))

		ray_cast_3d.force_raycast_update()
		var collider = ray_cast_3d.get_collider()

		if collider and collider.is_in_group("land"):
			print("Spawning feature at: " + str(random_position))

	water_collision.disabled = true
