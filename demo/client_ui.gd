extends Control

@onready var client: Node = $Client
#@onready var host: LineEdit = $VBoxContainer/Connect/Host
#@onready var room: LineEdit = $VBoxContainer/Connect/RoomSecret

@onready var room: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/RoomSecret
@onready var mesh: CheckBox = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/Mesh

@onready var logRoot: TextEdit = $HBoxContainer/VBoxContainer/TextEdit

@onready var playerName: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/YourNameHBox/YourName

@onready var playersList: ItemList = $HBoxContainer/VBoxContainer2/PlayersList

# hard-coded set of possible letters to draw from for random initial name
var characters = 'abcdefghijklmnopqrstuvwxyz'


func _get_server_url() -> String:
	# we're not doing this anymore!
	# return host.text

	# intentionally hard-coding for now
	return "wss://godot-web-multiplayer.onrender.com"


func generate_word(chars, length):
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word


func netBroadcastInfo(key, value):
	netRecvInfo.rpc(key, value)


#func netSendInfo(senderId, receiverId, key, value):
#	netRecvInfo.rpc(key, value)
#	# todo
#	return

var game_data = {}

@rpc("any_peer", "call_local")
func netRecvInfo(key, value) -> void:
	var senderID = multiplayer.get_remote_sender_id()

	_log("[Multiplayer] Net Recv Info from peer %d: key: %s value: %s" % [senderID, key, value])
	var playerData = game_data.get(senderID, {})
	game_data[senderID] = playerData
	playerData[key] = value
	match key:
		"name":
			updatePlayersList()

func updatePlayersList() -> void:
	_log("trying to updatePlayersList()")
	# todo: update player name list
	playersList.clear()
	for playerData in game_data.values():
		playersList.add_item(playerData["name"])


func _ready() -> void:
	client.lobby_joined.connect(_lobby_joined)
	client.lobby_sealed.connect(_lobby_sealed)
	client.connected.connect(_connected)
	client.disconnected.connect(_disconnected)

	multiplayer.connected_to_server.connect(_mp_server_connected)
	multiplayer.connection_failed.connect(_mp_server_disconnect)
	multiplayer.server_disconnected.connect(_mp_server_disconnect)
	multiplayer.peer_connected.connect(_mp_peer_connected)
	multiplayer.peer_disconnected.connect(_mp_peer_disconnected)
	
	# randomly fill in a player name
	playerName.text = generate_word(characters, 6)


@rpc("any_peer", "call_local")
func ping(argument: float) -> void:
	_log("[Multiplayer] Ping from peer %d: arg: %f" % [multiplayer.get_remote_sender_id(), argument])


func _mp_server_connected() -> void:
	_log("[Multiplayer] Server connected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_server_disconnect() -> void:
	_log("[Multiplayer] Server disconnected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_peer_connected(id: int) -> void:
	_log("[Multiplayer] Peer %d connected" % id)
	# send the new peer my info
	# todo: send to just them, for now, broadcast
	#netSendInfo(client.rtc_mp.get_unique_id(), id, "name", playerName.text)
	netBroadcastInfo("name", playerName.text)


func _mp_peer_disconnected(id: int) -> void:
	_log("[Multiplayer] Peer %d disconnected" % id)


func _connected(id: int, use_mesh: bool) -> void:
	_log("[Signaling] Server connected with ID: %d. Mesh: %s" % [id, use_mesh])


func _disconnected() -> void:
	_log("[Signaling] Server disconnected: %d - %s" % [client.code, client.reason])


func _lobby_joined(lobby: String) -> void:
	_log("[Signaling] Joined lobby %s" % lobby)
	##
	# send my name
	##


func _lobby_sealed() -> void:
	_log("[Signaling] Lobby has been sealed")


func _log(msg: String) -> void:
	print(msg)
	#$VBoxContainer/TextEdit.text += str(msg) + "\n"
	logRoot.text += str(msg) + "\n"


func _on_peers_pressed() -> void:
	_log(str(multiplayer.get_peers()))


func _on_ping_pressed() -> void:
	ping.rpc(randf())


func _on_seal_pressed() -> void:
	client.seal_lobby()


func _on_start_pressed() -> void:
	var url = _get_server_url()
	client.start(url, room.text, mesh.button_pressed)


func _on_stop_pressed() -> void:
	client.stop()
