extends CharacterBody3D

@export_group("Properties")
@export var movement_speed := 6
@export var jump_strength := 9

@export_group("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0
var container_offset = Vector3(1.2, -1.1, -2.75)
var tween:Tween

var mouse_sensitivity := 700
var movement_velocity: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera := $Head/Camera
@onready var ray_cast := $Head/Camera/Aim
@onready var reach := $Head/Camera/Reach
@onready var muzzle := $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container := $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container

@export var crosshair: TextureRect


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / mouse_sensitivity
		camera.rotation.x -= event.relative.y / mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _process(delta: float) -> void:
	if reach.is_colliding():
		if reach.get_collider().get_name() == "pass":
			pass

