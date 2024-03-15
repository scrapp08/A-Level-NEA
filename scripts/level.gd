extends Node

const DEFAULT_SERVER_IP := "127.0.0.1" # IPv4 localhost
const PORT := 9999
const PLAYER := preload("res://objects/player.tscn")

@export var debug_local_multiplayer := true

var peer = null
var score := {}

@onready var multiplayerPeer = ENetMultiplayerPeer.new()

@onready var name_edit: LineEdit = $UI/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var host_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Host
@onready var connect_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
@onready var disconnect_button: Button = $UI/MarginContainer/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
@onready var hostname: LineEdit = $UI/MarginContainer/VBoxContainer/HBoxContainer2/Hostname
@onready var player_list: ItemList = $UI/MarginContainer/VBoxContainer/Lobby/VBoxContainer/PlayerList
@onready var begin: Button = $UI/MarginContainer/VBoxContainer/Lobby/VBoxContainer/Begin

@onready var scoreboard: Control = $Scoreboard
@onready var blue_label: Label = $Scoreboard/Score/BlueScore/Label
@onready var red_label: Label = $Scoreboard/Score/RedScore/Label

@onready var win_screen: PanelContainer = $WinScreen
@onready var winner_text: Label = $WinScreen/WinnerText

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
	hostname.text = "DEFAULT_SERVER_IP"


func _on_disconnect_pressed():
	_close_network()
	hostname.text = ""


func _on_connect_pressed():
	multiplayerPeer.create_client(DEFAULT_SERVER_IP, PORT)
	multiplayer.connection_failed.connect(_close_network)
	multiplayer.connected_to_server.connect(_connected)

	multiplayer.set_multiplayer_peer(multiplayerPeer)
	start_game()
	begin.disabled = true


func _on_begin_pressed() -> void:
	var scene = preload("res://scenes/world.tscn")
	_remove_ui.rpc()

	level.add_child(scene.instantiate())

	var map = level.get_node("World/Map")
	print("spawning features")
	map.spawn_features()

	var world = level.get_node("World")

	for p in lobby._players:
		_add_player(world, p)


func _on_point(player: String) -> void:
	score[player] += 1
	if player == "1":
		var red_score = score[player]
		update_score.rpc(red_score, 1)
	else:
		var blue_score = score[player]
		update_score.rpc(blue_score, 2)


func _add_player(world, position) -> void:
	var player = PLAYER.instantiate()
	player.name = str(position)
	player.position = Vector3(0.0, 20.0, 0.0)
	world.add_child(player)
	initialise_score.rpc(position)


@rpc("call_local")
func initialise_score(position) -> void:
	score[str(position)] = 0


@rpc("call_local")
func _remove_ui() -> void:
	var ui = level.get_node("UI")
	level.remove_child(ui)
	ui.queue_free()
	scoreboard.show()


@rpc("call_local", "any_peer")
func update_score(score_value, player) -> void:
	if player == 1:
		red_label.text = str(score_value)
		if red_label.text == "4":
			winner_text.text = "Red wins!"
			win_screen.show()
	else:
		blue_label.text = str(score_value)
		if blue_label.text == "4":
			winner_text.text = "Blue wins!"
			win_screen.show()
