extends Node

const DEFAULT_SERVER_IP := "127.0.0.1" # IPv4 localhost
const PORT := 9999
const PLAYER := preload("res://objects/player.tscn")

var peer = null
var players
@export var score := {}

@onready var multiplayerPeer = ENetMultiplayerPeer.new()

@onready var name_edit: LineEdit = $UI/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var host_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Host
@onready var connect_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
@onready var disconnect_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
@onready var hostname: LineEdit = $UI/MarginContainer/VBoxContainer/HBoxContainer2/Hostname
@onready var player_list: ItemList = $UI/MarginContainer/VBoxContainer/Lobby/VBoxContainer/PlayerList
@onready var begin: Button = $UI/MarginContainer/VBoxContainer/Lobby/VBoxContainer/Begin

@onready var scoreboard: Control = $Scoreboard
@onready var blue_score: Label = $Scoreboard/Score/BlueScore/Label
@onready var red_score: Label = $Scoreboard/Score/RedScore/Label

@onready var lobby: Control = $UI/MarginContainer/VBoxContainer/Lobby
@onready var level = $"."


func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)


func start_game():
	host_button.disabled = true
	name_edit.editable = false
	hostname.editable = false
	connect_button.hide()
	disconnect_button.show()
	begin.disabled = false


func stop_game():
	host_button.disabled = false
	name_edit.editable = true
	hostname.editable = true
	disconnect_button.hide()
	connect_button.show()
	lobby.stop()


func _close_network():
	if multiplayer.server_disconnected.is_connected(_close_network):
		multiplayer.server_disconnected.disconnect(_close_network)
	if multiplayer.connection_failed.is_connected(_close_network):
		multiplayer.connection_failed.disconnect(_close_network)
	if multiplayer.connected_to_server.is_connected(_connected):
		multiplayer.connected_to_server.disconnect(_connected)

	multiplayerPeer.close()
	multiplayerPeer = ENetMultiplayerPeer.new()

	stop_game()
	$UI/AcceptDialog.show()
	$UI/AcceptDialog.get_ok_button().grab_focus()


func _connected():
	lobby.rpc("set_player_name", name_edit.text)


func _peer_connected(id):
	lobby.on_peer_add(id)


func _peer_disconnected(id):
	lobby.on_peer_del(id)
	if id==1:
		_close_network()


func _on_host_pressed():
	multiplayerPeer.create_server(PORT)

	multiplayer.server_disconnected.connect(_close_network)
	multiplayer.set_multiplayer_peer(multiplayerPeer)

	lobby.add_player(1, name_edit.text)

	start_game()


func _on_disconnect_pressed():
	_close_network()


func _on_connect_pressed():
	multiplayerPeer.create_client(DEFAULT_SERVER_IP, PORT)
	multiplayer.connection_failed.connect(_close_network)
	multiplayer.connected_to_server.connect(_connected)

	multiplayer.set_multiplayer_peer(multiplayerPeer)
	start_game()
	begin.disabled = true


func _on_begin_pressed() -> void:
	var scene = load("res://scenes/testworld.tscn")
	_remove_ui.rpc()

	level.add_child(scene.instantiate())

	var world = level.get_node("TestWorld")

	for p in lobby._players:
		_add_player(world, p)
		score[p] = 0
	players = lobby.get_players()
	print(score)


func _on_point(player: int) -> void:
	score[player] += 1
	if player == 1:
		red_score.text = str(1)
	else:
		blue_score.text = str(1)
	print(score)


func _add_player(world, position) -> void:
	var player = PLAYER.instantiate()
	player.name = str(position)
	world.add_child(player)
	player.point.connect(_on_point)


@rpc("call_local")
func _remove_ui() -> void:
	var ui = level.get_node("UI")
	level.remove_child(ui)
	ui.queue_free()
	scoreboard.show()