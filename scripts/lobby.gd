extends Control

@export var _players := []

@onready var player_list = $VBoxContainer/PlayerList
@onready var begin_button = $VBoxContainer/Begin


@rpc("any_peer", "call_local")
func set_player_name(_name):
	var sender = multiplayer.get_remote_sender_id()
	rpc("update_player_name", sender, _name)


@rpc("any_peer", "call_local")
func update_player_name(player, _name):
	var pos = _players.find(player)
	if pos != -1:
		player_list.set_item_text(pos, _name)


@rpc("any_peer", "call_local")
func del_player(id):
	var pos = _players.find(id)
	if pos == -1:
		return
	_players.remove_at(pos)
	player_list.remove_item(pos)


@rpc("any_peer", "call_local")
func add_player(id, _name=""):
	_players.append(id)
	if _name == "":
		player_list.add_item("... connecting ...", null, false)
	else:
		player_list.add_item(_name, null, false)


func get_player_name(pos):
	if pos < player_list.get_item_count():
		return player_list.get_item_text(pos)
	else:
		return "Error!"


func stop():
	_players.clear()
	player_list.clear()
	begin_button.disabled = true


func on_peer_add(id):
	if not multiplayer.is_server():
		return
	for i in range(0, _players.size()):
		rpc_id(id, "add_player", _players[i], get_player_name(i))
	rpc("add_player", id)


func on_peer_del(id):
	if not multiplayer.is_server():
		return
	rpc("del_player", id)


func get_players():
	return _players
