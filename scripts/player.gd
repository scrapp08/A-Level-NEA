extends CharacterBody3D

signal health_changed(health_value)

@export_group("Properties")
@export var movement_speed := 6
@export var jump_strength := 9

@export_group("Weapons")
@export var weapons: Array[Weapon] = []


var weapon: Weapon
var weapon_index: int
var container_offset := Vector3(1.2, -1.1, -2.75)
var tween: Tween

var mouse_sensitivity := 700
var movement_velocity: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var paused := false

var health := 200

@onready var world = get_parent()
@onready var camera := $Head/Camera
@onready var raycast := $Head/Camera/RayCast
@onready var muzzle := $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container := $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var crosshair: TextureRect = world.get_node("CanvasLayer/HUD/Crosshair")


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

	world.pause_status.connect(_on_pause_status)
	paused = false

	world.weapon_select.connect(_on_weapon_select)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion and not paused:
		rotation.y -= event.relative.x / mouse_sensitivity
		camera.rotation.x -= event.relative.y / mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	movement_velocity = transform.basis * Vector3(input.x, 0, input.y).normalized() * movement_speed

	if Input.is_action_just_pressed("move_up") and is_on_floor():
		gravity = -jump_strength

	gravity += 20 * delta

	if gravity > 0 and is_on_floor():
		gravity = 0

	velocity = velocity.lerp(movement_velocity, delta * 10)
	velocity.y = -gravity
	move_and_slide()


func _on_pause_status(value: bool) -> void:
	paused = value

	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	elif not paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_weapon_select(index: int) -> void:
	weapon = weapons[index]
	_initiate_change_weapon(index)


@rpc("any_peer")
func recieve_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		health = 200
		position = Vector3.ZERO
	health_changed.emit(health)


func _initiate_change_weapon(index) -> void:
	weapon_index = index

	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(_change_weapon) # Change model


func _change_weapon() -> void:
	weapon = weapons[weapon_index]

	# Remove previous weapon model(s) from container
	for n in container.get_children():
		container.remove_child(n)

	# Place new weapon model in container
	var weapon_model = weapon.model.instantiate()
	container.add_child(weapon_model)

	weapon_model.position = weapon.position
	weapon_model.rotation_degrees = weapon.rotation

	# Set model to only render on layer 2 (the weapon camera)
	for child in weapon_model.find_children("*", "MeshInstance3D"):
		child.layers = 2

	# Set weapon data
	raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
