extends CharacterBody3D

signal health_updated(health_value)

@export_subgroup("Properties")
@export var movement_speed := 6
@export var jump_strength := 9

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0
var container_offset = Vector3(1.2, -1.1, -2.75)
var tween:Tween

var mouse_sensitivity = 700
var movement_velocity: Vector3
var rotation_target: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var previously_floored := false

var health := 200
var paused := false

@onready var world = get_parent()
@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@onready var muzzle = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var sound_footsteps = $SoundFootsteps
@onready var blaster_cooldown = $Cooldown
@onready var crosshair: TextureRect = world.get_node("CanvasLayer/HUD/Crosshair")


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	print(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

	world.pause_status.connect(_on_pause_status)
	paused = false

	world.weapon_select.connect(_on_weapon_select)

	_on_weapon_select(weapon_index)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion:
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement_velocity = Vector3(input.x, 0, input.y).normalized() * movement_speed

	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))

	if Input.is_action_just_pressed("move_up") and is_on_floor():
		gravity = -jump_strength

	gravity += 20 * delta

	if gravity > 0 and is_on_floor():
		gravity = 0

	if Input.is_action_pressed("shoot"):
		_action_shoot()

	# Movement
	movement_velocity = transform.basis * movement_velocity # Move forward
	velocity = velocity.lerp(movement_velocity, delta * 10)
	velocity.y = -gravity
	move_and_slide()

	# Rotation
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
	container.position = lerp(container.position, container_offset - (basis.inverse() * velocity / 30), delta * 10)

	# Movement sound
	sound_footsteps.stream_paused = true

	if is_on_floor():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			sound_footsteps.stream_paused = false

	# Landing after jump or falling
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)

	if is_on_floor() and gravity > 1 and !previously_floored: # Landed
		Audio.play("sounds/land.ogg")
		camera.position.y = -0.1

	previously_floored = is_on_floor()


func _on_pause_status(value: bool) -> void:
	paused = value

	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	elif not paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_weapon_select(index: int) -> void:
	weapon = weapons[index]
	_initiate_change_weapon(index)

	Audio.play("sounds/weapon_change.ogg")


@rpc("any_peer")
func recieve_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		health = 200
		position = Vector3.ZERO
	health_updated.emit(health)


func _action_shoot() -> void:
	if !blaster_cooldown.is_stopped(): return # Cooldown for shooting
	if paused: return

	Audio.play(weapon.sound_shoot)

	# Set muzzle flash position, play animation
	muzzle.play("default")

	muzzle.rotation_degrees.z = randf_range(-45, 45)
	muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
	muzzle.position = container.position - weapon.muzzle_position

	blaster_cooldown.start(weapon.cooldown)

	# Shoot the weapon, amount based on shot count
	for n in weapon.shot_count:
		raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
		raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)

		raycast.force_raycast_update()

		if !raycast.is_colliding(): continue # Don't create impact when raycast didn't hit

		var collider = raycast.get_collider()

		# Hitting an enemy
		if collider.has_method("damage"):
			collider.damage(weapon.damage)

		# Creating an impact animation
		var impact = preload("res://objects/impact.tscn")
		var impact_instance = impact.instantiate()

		impact_instance.play("shot")

		get_tree().root.add_child(impact_instance)

		impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
		impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)

	container.position.z += float(weapon.knockback) / 100.0 # Knockback of weapon visual
	camera.rotation.x += float(weapon.knockback) / 1000.0 # Knockback of camera


func _initiate_change_weapon(index) -> void:
	weapon_index = index

	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(_change_weapon) # Changes the model


func _change_weapon() -> void:
	weapon = weapons[weapon_index]

	# Step 1. Remove previous weapon model(s) from container
	for n in container.get_children():
		container.remove_child(n)

	# Step 2. Place new weapon model in container
	var weapon_model = weapon.model.instantiate()
	container.add_child(weapon_model)

	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation

	# Step 3. Set model to only render on layer 2 (the weapon camera)
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2

	# Set weapon data

	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
