extends Node

signal pause_status(value: bool)
signal weapon_select(value: int)

const PLAYER := preload("res://objects/player.tscn")
const PORT := 9999

@export var debug_local_multiplayer: bool

var paused: bool

var _enet_peer = ENetMultiplayerPeer.new()

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/VBoxContainer/AddressEntry

@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var loadout: PanelContainer = $CanvasLayer/PauseMenu/MarginContainer/Loadout
@onready var options: VBoxContainer = $CanvasLayer/PauseMenu/MarginContainer/Options
@onready var item_list: ItemList = $CanvasLayer/PauseMenu/MarginContainer/Loadout/MarginContainer/VBoxContainer/ItemList
@onready var back: Button = $CanvasLayer/PauseMenu/MarginContainer/Loadout/MarginContainer/VBoxContainer/Back

@onready var hud: Control = $CanvasLayer/HUD
@onready var crosshair: TextureRect = $CanvasLayer/HUD/Crosshair
@onready var health_bar: Label = $CanvasLayer/HUD/Health
@onready var ip: Label = $CanvasLayer/HUD/IP


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("menu") and not paused:
		pause(true)

	elif Input.is_action_just_pressed("menu") and paused:
		pause(false)


func _on_host_pressed() -> void:
	main_menu.hide()
	hud.show()
	_enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = _enet_peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player(multiplayer.get_unique_id())

	if not debug_local_multiplayer:
		_upnp_setup()
	else:
		ip.text = "IP: localhost"
		ip.show()


func _on_join_pressed() -> void:
	main_menu.hide()
	hud.show()
	_enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = _enet_peer


func _add_player(peer_id) -> void:
	var player := PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)

	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health)


func _remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))

	if player:
		player.queue_free()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health)


func _on_resume_pressed() -> void:
	pause(false)


func _on_loadout_pressed() -> void:
	options.hide()
	loadout.show()


func _on_item_list_item_selected(index: int) -> void:
	weapon_select.emit(index)


func _on_back_pressed() -> void:
	loadout.hide()
	options.show()


func _on_quit_pressed() -> void:
	get_tree().quit()


func pause(status: bool) -> void:
	if status:
		crosshair.hide()
		pause_menu.show()
		paused = true
		pause_status.emit(true)

	else:
		pause_menu.hide()
		crosshair.show()
		paused = false
		pause_status.emit(false)


func update_health(health_value) -> void:
	health_bar.text = health_value


func _upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()

	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)

	print("Success! Join Address: %s" % upnp.query_external_address())
	ip.text = "IP: %s" % upnp.query_external_address()
