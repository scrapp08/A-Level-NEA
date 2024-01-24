extends Node

signal address(address: String)

const PLAYER := preload("res://objects/player.tscn")
const DEFAULT_SERVER_IP := "127.0.0.1" # IPv4 localhost
const PORT := 9999

@export var debug_local_multiplayer: bool

var enet_peer = ENetMultiplayerPeer.new()

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/VBoxContainer/AddressEntry


func _on_host_pressed():
	main_menu.hide()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)

	_add_player(multiplayer.get_unique_id())

	if not debug_local_multiplayer:
		_upnp_setup()
	else:
		address.emit("IP: " + DEFAULT_SERVER_IP)
		print("Set address")


func _on_join_pressed():
	main_menu.hide()

	if address_entry.get_text() != "":
		enet_peer.create_client(address_entry.text, PORT)
		multiplayer.multiplayer_peer = enet_peer
	else:
		enet_peer.create_client(DEFAULT_SERVER_IP, PORT)
		multiplayer.multiplayer_peer = enet_peer
		address.emit("IP: " + DEFAULT_SERVER_IP)
		print("Set address")


func _add_player(peer_id) -> void:
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)


func _remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


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

	address.emit("IP: " + str(upnp.query_external_address()))
