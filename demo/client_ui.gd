extends Control

@onready var client: Node = $Client

@onready var room: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/RoomSecret
@onready var mesh: CheckBox = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/Mesh

@onready var logRoot: TextEdit = $HBoxContainer/VBoxContainer/TextEdit

@onready var playerName: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/YourNameHBox/YourName

@onready var playersList: ItemList = $HBoxContainer/VBoxContainer2/PlayersList

@onready var game: Node = $RockPaperScissorsGame

# prepare the ninja animation
const cutscenePrefab = preload("res://demo/ninja.tscn")
#@onready var cutsceneRoot = logRoot
@onready var cutsceneRoot = $HBoxContainer/VBoxContainer
var cutsceneInstance

# hard-coded set of possible letters to draw from for random initial name
var characters = 'abcdefghijklmnopqrstuvwxyz'

# buttons
@onready var btnRock = $HBoxContainer/VBoxContainer/HBoxContainer2/GameCtrl/Rock
@onready var btnPaper = $HBoxContainer/VBoxContainer/HBoxContainer2/GameCtrl/Paper
@onready var btnScissors = $HBoxContainer/VBoxContainer/HBoxContainer2/GameCtrl/Scissors


func startCutscene() -> void:
	# lazily instantiate
	if cutsceneInstance == null:
		cutsceneInstance = cutscenePrefab.instantiate()
		# add to scene tree
		cutsceneRoot.add_child(cutsceneInstance)
		# hack to put into good position to view
		cutsceneInstance.position.y = 650
		cutsceneInstance.play()


func _get_server_url() -> String:
	# we're not doing this anymore!
	# return host.text

	# intentionally hard-coding for now
	return "wss://godot-web-multiplayer.onrender.com"


func generate_word(chars, length) -> String:
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word


func netBroadcastInfo(key, value) -> void:
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
		"play":
			match value:
				"rock":
					game.UseRock(senderID)
					startCutscene()
				"paper":
					game.UsePaper(senderID)
				"scissors":
					game.UseScissor(senderID)
			# try to resolve the round
			var winnerID = game.resolve_round()
			var winnerData = game_data.get(winnerID, {})
			var winnerName = winnerData.get("name", "undefined")
			_log("[Game] Current winner: peer %d (name %s)" % [winnerID, winnerName])
		"target":
			var attackerName = playerData.get("name", "null")
			var defenderData = game_data.get(value, {})
			var defenderName = defenderData.get("name", "null")
			_log("[Game] %s wants to fight %s" % [attackerName, defenderName])


func updatePlayersList() -> void:
	# get list of players
	var names = []
	for playerData in game_data.values():
		var name = playerData.get("name", null)
		if name:
			names.append(name)

	# alphabetize list
	names.sort()

	# update the UI control with list of players
	playersList.clear()
	for name in names:
		playersList.add_item(name)


func find_player_network_id_from_name(name) -> int:
	# just do a linear search for now
	for player_id in game_data:
		var playerData = game_data[player_id]
		if playerData.get("name", "") == name:
			return player_id

	# indicate failure
	return -1


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

	# default to a random selection between rock, paper, and scissors
	var choices = [btnRock, btnPaper, btnScissors]
	var selection = choices.pick_random()
	selection.emit_signal("pressed")


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
	# put this in the room text field automatically
	room.text = lobby
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
	# print a note about how you may have to wait a moment
	_log("Waking server if needed (please wait)...")


func _on_stop_pressed() -> void:
	client.stop()


# gameplay buttons

func _on_rock_pressed() -> void:
	netBroadcastInfo("play", "rock")
	btnRock.disabled = true
	btnPaper.disabled = false
	btnScissors.disabled = false

func _on_paper_pressed() -> void:
	netBroadcastInfo("play", "paper")
	btnRock.disabled = false
	btnPaper.disabled = true
	btnScissors.disabled = false

func _on_scissors_pressed() -> void:
	netBroadcastInfo("play", "scissors")
	btnRock.disabled = false
	btnPaper.disabled = false
	btnScissors.disabled = true

func jsCopyHack(text_to_copy: String):
	var js_code = """
	// 1. Create a temporary text element
	var textArea = document.createElement("textarea");
	textArea.value = '%s';

	// 2. Make it invisible but part of the page
	textArea.style.position = "fixed";
	textArea.style.left = "-9999px";
	textArea.style.top = "0";
	document.body.appendChild(textArea);

	// 3. Select the text
	textArea.focus();
	textArea.select();

	// 4. The Magic: Execute the "old" copy command
	try {
		var successful = document.execCommand('copy');
		var msg = successful ? 'successful' : 'unsuccessful';
		console.log('Fallback copy command was ' + msg);
	} catch (err) {
		console.error('Fallback: Oops, unable to copy', err);
	}

	// 5. Clean up
	document.body.removeChild(textArea);
	""" % text_to_copy

	JavaScriptBridge.eval(js_code)


func copy_to_clipboard(text_to_copy: String):
	# 1. Try the standard Godot way (works on Desktop/Mobile)
	DisplayServer.clipboard_set(text_to_copy)
	
	# 2. If we are on the Web, try a JavaScript fallback
	if OS.get_name() == "Web":
		# Below is not working on itch.io
		## This executes raw JS in the browser
		## We use the 'navigator.clipboard' API directly
		#var js_code = "navigator.clipboard.writeText('%s').then(function() { console.log('Copy Success'); }, function(err) { console.error('Copy Failed', err); });" % text_to_copy
		#JavaScriptBridge.eval(js_code)
		
		# second method (also doesn't work)
		#jsCopyHack(text_to_copy)
		
		# third method (not pretty but it works)
		force_copy_prompt(text_to_copy)

	_log("Copied text %s" % [text_to_copy])

##
func force_copy_prompt(text_to_copy: String):
	if OS.get_name() == "Web":
		# Opens a browser prompt: "Copy this key: [ text_to_copy ]"
		# This cannot trigger a "Clipboard API" error because it doesn't use the clipboard API!
		var js_code = "prompt('Press Ctrl+C to copy your key:', '%s');" % text_to_copy
		JavaScriptBridge.eval(js_code)

func _on_copy_button_pressed() -> void:
	copy_to_clipboard(room.text)


func _on_paste_button_pressed() -> void:
	var output = ""
	if OS.get_name() == "Web":
		# 1. Ask the user to paste into a native prompt
		var js_code = "prompt('Please paste (Ctrl+V) your Room Key here:');"
		var result = JavaScriptBridge.eval(js_code)
		
		# 2. 'result' will be null if they hit Cancel, or the string if they hit OK
		if result:
			output = result
	else:
		# Desktop fallback
		output = DisplayServer.clipboard_get()
	room.text = output
	
	# try auto-joining room?
	#_on_join_room_logic(result) # Optional: Auto-join immediately


func _on_players_list_item_selected(index: int) -> void:
	# what's the name at this index?
	var name = playersList.get_item_text(index)
	
	# what's the network ID for this name?
	var network_id = find_player_network_id_from_name(name)

	# indicate that you want to fight this guy
	# if a match is made, you'll fight
	netBroadcastInfo("target", network_id)
