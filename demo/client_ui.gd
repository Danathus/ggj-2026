extends Control

@export var audio_stream: AudioStreamPlayer2D
@export var player_select_audio_clip: AudioStream

@onready var client: Node = $Client

@onready var room: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/RoomSecret
@onready var mesh: CheckBox = $HBoxContainer/VBoxContainer/HBoxContainer2/Connect/Mesh

@onready var logRoot: TextEdit = $HBoxContainer/VBoxContainer/TextEdit

@onready var playerName: LineEdit = $HBoxContainer/VBoxContainer/HBoxContainer2/YourNameHBox/YourName

@onready var playersList = $HBoxContainer/PlayersList

@onready var game: Node = $RockPaperScissorsGame

@onready var startButton = $HBoxContainer/VBoxContainer/HBoxContainer2/HBoxContainer

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

var isConnectedToLobby = false;

@onready var playerColor: ColorRect = $HBoxContainer/VBoxContainer/HBoxContainer2/YourNameHBox/YourColor


# set a string to true to output logs for it (debugging aid to make it easier to silence)
# we can hard-code for now which we want to show
var logsEnabled = {
	"Signaling": true,
	"Multiplayer": false,
	"Game": true,
	"Menu": true,
	"Help": true
}


func _log(type, msg: String) -> void:
	if logsEnabled.get(type, false):
		msg = "[%s] %s" % [type, msg]
		print(msg)
		logRoot.text += str(msg) + "\n"


func startCutscene(leftColor, rightColor) -> void:
	# lazily instantiate
	if cutsceneInstance != null and is_instance_valid(cutsceneInstance):
		cutsceneInstance.queue_free()
		cutsceneInstance = null

	cutsceneInstance = cutscenePrefab.instantiate()
	# add to scene tree
	cutsceneRoot.add_child(cutsceneInstance)
	# hack to put into good position to view
	cutsceneInstance.position.y = 650
	# assign the colors
	cutsceneInstance.set_player_colors(leftColor, rightColor)
	# and here...we...go!
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
	# only actually send if we are connected to someone
	#if multiplayer.get_peers().size() > 0:
	if isConnectedToLobby:
		netRecvInfo.rpc(key, value)

func netBroadcastAllMyInfo() -> void:
	var me = client.rtc_mp.get_unique_id()
	var playerData = game_data.get(me, {})

	# send everything
	for key in playerData:
		netBroadcastInfo(key, playerData[key])


#func netSendInfo(senderId, receiverId, key, value):
#	netRecvInfo.rpc(key, value)
#	# todo
#	return

var game_data = {}

@rpc("any_peer", "call_local")
func netRecvInfo(key, value) -> void:
	var senderID = multiplayer.get_remote_sender_id()

	_log("Multiplayer", "Net Recv Info from peer %d: key: %s value: %s" % [senderID, key, value])
	var playerData = game_data.get(senderID, null)

	if playerData == null:
		playerData = {
		"wins": 0
		}
	game_data[senderID] = playerData

	playerData[key] = value
	match key:
		"name":
			playersList.update(game_data)
		"color":
			playersList.update(game_data)
		"play":
			match value:
				"rock":
					game.UseRock(senderID)
				"paper":
					game.UsePaper(senderID)
				"scissors":
					game.UseScissor(senderID)
		"target":
			if value == -1:
				return
			var attackerName = playerData.get("name", "null")
			var defenderData = game_data.get(value, {})
			var defenderName = defenderData.get("name", "null")
			var logString = "%s wants to fight %s" % [attackerName, defenderName]
			if attackerName == defenderName:
				logString += " (silly %s!)" % [attackerName]
			_log("Game", logString)
			# if there's a match made, engage the game
			if senderID != value and game_data.get(value, {}).get("target", -1) == senderID:
				_log("Game", "Fight begins: %s vs %s!" % [attackerName, defenderName])
				var attackerColor = playerData.get("color", Color.WHITE)
				var defenderColor = defenderData.get("color", Color.WHITE)
				startCutscene(attackerColor, defenderColor)

				# try to resolve the round
				var winnerID = game.resolve_round(senderID, value)
				
				if winnerID == -1:
					_log("Game", "Something went wrong! Inconclusive!")
					return
				if winnerID == 0:
					_log("Game", "%s ties with %s! Stalemate!" % [attackerName, defenderName])
					return

				# there is a winner and a loser -- report the result
				var winnerData = game_data.get(winnerID, {})
				var winnerName = winnerData.get("name", "undefined")
				var loserID = value if senderID == winnerID else senderID
				var loserData = game_data.get(loserID, {})
				var loserName = loserData.get("name", "undefined")
				
				winnerData["wins"] = winnerData.get("wins", 0) + 1
				#if winnerData["wins"] == null:
					#winnerData["wins"] = 1
				#else:
					#winnerData["wins"] = winnerData["wins"] + 1
				#_log("Game", "Current winner: peer %d (name %s)" % [winnerID, winnerName])
				_log("Game", "%s beats %s!" % [winnerName, loserName])
				_log("Game", "Winner, %s now has now won %d time(s)" % [winnerName, winnerData["wins"]])
				_log("Game", "Loser, %s has only won %d time(s)" % [loserName, loserData["wins"]])


func generate_random_hsv_color() -> Color:
	# Hue (0.0 to 1.0), Saturation (0.0 to 1.0), Value/Brightness (0.0 to 1.0)
	# Using randf() for hue, and a specific range for a vibrant color
	return Color.from_hsv(randf(), 1.0, 1.0)



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

	playersList.player_selected.connect(_on_player_selected)

	# randomly fill in a player name
	playerName.text = generate_word(characters, 6)

	# randomly assign a color too
	playerColor.color = generate_random_hsv_color()

	# default to a random selection between rock, paper, and scissors
	var choices = [btnRock, btnPaper, btnScissors]
	var selection = choices.pick_random()
	selection.emit_signal("pressed")

	# print help text
	_log("Help", "Welcome to the game, %s!" % [playerName.text])
	_log("Help", "You can click Start to create a new game room.")
	_log("Help", "Or, you can paste in a secret room key and click Start to join an existing game room.")


@rpc("any_peer", "call_local")
func ping(argument: float) -> void:
	_log("Multiplayer", "Ping from peer %d: arg: %f" % [multiplayer.get_remote_sender_id(), argument])


func _mp_server_connected() -> void:
	_log("Multiplayer", "Server connected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_server_disconnect() -> void:
	_log("Multiplayer", "Server disconnected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_peer_connected(id: int) -> void:
	_log("Multiplayer", "Peer %d connected" % id)

	# send the new peer my info
	# todo: send to just them -- but for now, broadcast to all
	#netSendInfo(client.rtc_mp.get_unique_id(), id, "name", playerName.text)
	netBroadcastAllMyInfo()


func _mp_peer_disconnected(id: int) -> void:
	_log("Multiplayer", "Peer %d disconnected" % id)


func _connected(id: int, use_mesh: bool) -> void:
	_log("Signaling", "Server connected with ID: %d. Mesh: %s" % [id, use_mesh])


func _disconnected() -> void:
	_log("Signaling", "Server disconnected: %d - %s" % [client.code, client.reason])


func _lobby_joined(lobby: String) -> void:
	isConnectedToLobby = true
	startButton.hide()
	_log("Signaling", "Joined lobby %s" % lobby)
	# put this in the room text field automatically
	room.text = lobby
	# give some more tips
	_log("Help", "You can choose between Rock, Paper, Scissors with the buttons on the top right")
	_log("Help", "Feel free to change your mind whenever you like.")
	_log("Help", "When you're ready, click on a player you want to fight.")
	_log("Help", "When a match is made, it's going down!")

	# at this point we should commit our fields to the network
	netBroadcastInfo("name", playerName.text)
	netBroadcastInfo("color", playerColor.color)
	var play = "rock"
	if btnPaper.disabled:
		play = "paper"
	if btnScissors.disabled:
		play = "scissors"
	netBroadcastInfo("play", play)


func _lobby_sealed() -> void:
	_log("Signaling", "Lobby has been sealed")


func _on_peers_pressed() -> void:
	pass
	#_log(str(multiplayer.get_peers()))


func _on_ping_pressed() -> void:
	ping.rpc(randf())


func _on_seal_pressed() -> void:
	client.seal_lobby()


func _on_start_pressed() -> void:
	var url = _get_server_url()
	client.start(url, room.text, mesh.button_pressed)
	# print a note about how you may have to wait a moment
	_log("Help", "Waking server if needed (please wait)...")


func _on_stop_pressed() -> void:
	client.stop()


# gameplay buttons

func _on_rock_pressed() -> void:
	btnRock.disabled = true
	btnPaper.disabled = false
	btnScissors.disabled = false
	netBroadcastInfo("play", "rock")

func _on_paper_pressed() -> void:
	btnRock.disabled = false
	btnPaper.disabled = true
	btnScissors.disabled = false
	netBroadcastInfo("play", "paper")

func _on_scissors_pressed() -> void:
	btnRock.disabled = false
	btnPaper.disabled = false
	btnScissors.disabled = true
	netBroadcastInfo("play", "scissors")

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

	_log("Menu", "Copied text %s" % [text_to_copy])


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
	
	_log("Menu", "Pasted text %s" % [output])
	room.text = output

	# try auto-joining room?
	#_on_join_room_logic(result) # Optional: Auto-join immediately


func _on_player_selected(network_id: int) -> void:
	audio_stream.stream = player_select_audio_clip
	audio_stream.play()
	# indicate that you want to fight this guy
	# if a match is made, you'll fight
	netBroadcastInfo("target", network_id)
