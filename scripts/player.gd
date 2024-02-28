extends CharacterBody3D

signal point(value: int)

@export_subgroup("Properties")
@export var movement_speed := 6
@export var jump_strength := 9

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0
var container_offset = Vector3(0.6, -1, -0.7)
var tween: Tween

var mouse_sensitivity = 700
var movement_velocity: Vector3
var rotation_target: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var previously_floored := false

var health_value := 200
var paused := false

@onready var body: MeshInstance3D = $Body
@onready var collision_shape: CollisionShape3D = $Collider
@onready var head: Node3D = $Head

@onready var camera = $Head/Camera
@onready var container: Node3D = $Head/Camera/Container
@onready var muzzle: AnimatedSprite3D = $Head/Camera/Muzzle
@onready var ray_cast: RayCast3D = $Head/Camera/RayCast

@onready var crosshair: TextureRect = $HUD/Crosshair
@onready var health: Label = $HUD/Health
@onready var ammo: Label = $HUD/Ammo

@onready var pause_menu: Control = $PauseMenu
@onready var loadout: PanelContainer = $PauseMenu/MarginContainer/Loadout
@onready var options: VBoxContainer = $PauseMenu/MarginContainer/Options

@onready var loading_screen: PanelContainer = $LoadingScreen

@onready var sound_footsteps: AudioStreamPlayer = $SoundFootsteps
@onready var cooldown: Timer = $Cooldown

@onready var wall_sprite = preload("res://objects/powerups/wall/wallsprite.tscn")


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

	health.text = str(health_value)

	get_tree().create_timer(1).timeout.connect(func() -> void:
		_on_item_list_item_selected(weapon_index)
		ammo.text = str(weapon.clip_size)
		)

	point.connect(get_parent().get_parent()._on_point)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion and not paused:
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

	if Input.is_action_just_pressed("menu"):
		if not paused:
			_pause(true)
		elif paused:
			_pause(false)


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

	if Input.is_action_pressed("primary_attack"):
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


func _on_loading(state: bool) -> void:
	if state == true:
		loading_screen.show()
	elif state == false:
		loading_screen.hide()


func _on_resume_pressed() -> void:
	_pause(false)


func _on_loadout_pressed() -> void:
	options.hide()
	loadout.show()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_item_list_item_selected(index: int) -> void:
	weapon = weapons[index]
	initiate_change_weapon.rpc(index)

	Audio.play("sounds/weapon_change.ogg")


func _on_back_pressed() -> void:
	loadout.hide()
	options.show()


@rpc("any_peer")
func recieve_damage(amount: int) -> void:
	health_value -= amount
	health.text = str(health_value)

	if health_value <= 0:
		health_value = 200
		health.text = str(health_value)
		position = Vector3(0.0, 20.0, 0.0)
		point.emit(str(name))


@rpc("call_local")
func render_impact() -> void:
	var impact = preload("res://objects/impact.tscn")
	var impact_instance = impact.instantiate()

	impact_instance.play("shot")

	get_tree().root.add_child(impact_instance)

	impact_instance.position = ray_cast.get_collision_point() + (ray_cast.get_collision_normal() / 10)


@rpc("call_local")
func muzzle_animation(weapon_muzzle: Vector3) -> void:
	muzzle.play("default")

	muzzle.rotation_degrees.z = randf_range(-45, 45)
	muzzle.scale = Vector3.ONE * randf_range(0.20, 0.40)
	muzzle.position = container.position - weapon_muzzle


@rpc("call_local")
func initiate_change_weapon(index) -> void:
	weapon_index = index

	tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
	tween.tween_callback(change_weapon) # Changes the model


func change_weapon() -> void:
	if not is_multiplayer_authority(): return

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
	ray_cast.target_position = Vector3(0, 0, -1) * weapon.max_distance
	crosshair.texture = weapon.crosshair
	ammo.text = str(weapon.clip_size)


func add_ammo() -> void:
	if not is_multiplayer_authority(): return

	weapon.clip_size = weapon.max_clip_size
	ammo.text = str(weapon.clip_size)


func activate_wall() -> void:
	if not is_multiplayer_authority(): return
	
	var ws = wall_sprite.instantiate()
	add_child(ws)


func increase_jump() -> void:
	if not is_multiplayer_authority(): return
	
	jump_strength = 13


func decrease_size() -> void:
	if not is_multiplayer_authority(): return
	
	var new_mesh := CapsuleMesh.new()
	new_mesh.height = 1.0
	new_mesh.radius = 0.25
	body.mesh = new_mesh

	var new_collider := CapsuleShape3D.new()
	new_collider.height = 1.0
	new_collider.radius = 0.25
	collision_shape.shape = new_collider

	head.position = Vector3(0, 1.5, 0)


func _pause(status: bool) -> void:
	if not is_multiplayer_authority(): return
	
	if status:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		crosshair.hide()
		pause_menu.show()
		paused = true
	else:
		pause_menu.hide()
		crosshair.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		paused = false


func _action_shoot() -> void:
	if not is_multiplayer_authority(): return

	if !cooldown.is_stopped(): return # Cooldown for shooting
	if paused: return
	if weapon.clip_size == 0: return

	Audio.play(weapon.sound_shoot)

	# Set muzzle flash position, play animation
	muzzle_animation.rpc(weapon.muzzle_position)

	cooldown.start(weapon.cooldown)

	# Shoot the weapon, amount based on shot count
	for n in weapon.shot_count:
		weapon.clip_size -= 1
		ammo.text = str(weapon.clip_size)
		if weapon.clip_size == 0: return

		ray_cast.target_position.x = randf_range(-weapon.spread, weapon.spread)
		ray_cast.target_position.y = randf_range(-weapon.spread, weapon.spread)

		ray_cast.force_raycast_update()

		if !ray_cast.is_colliding(): continue # Don't create impact when raycast didn't hit

		var collider = ray_cast.get_collider()

		# Damage
		if collider.has_method("recieve_damage"):
			collider.recieve_damage.rpc_id(collider.get_multiplayer_authority(), weapon.damage)

		# Creating an impact animation
		render_impact.rpc()

	container.position.z += float(weapon.knockback) / 100.0 # Knockback of weapon visual
	camera.rotation.x += float(weapon.knockback) / 1000.0 # Knockback of camera
