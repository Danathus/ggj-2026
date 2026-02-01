extends VBoxContainer


@onready var playersList: VBoxContainer = $ScrollContainer/PlayersList


# cheat and retain game_data whenever passed in
var game_data = {} # default to empty but this will be overridden

# preload the custom row scene
const PLAYER_ROW = preload("res://demo/player_row.tscn")


# signal up when we select a player (so parent can handle e.g. send network messages)
signal player_selected(peer_id: int)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update(in_game_data) -> void:
	game_data = in_game_data

	# get list of players
	# and build a map of name to player data
	var names = []
	var nameToPlayerData = {}
	for playerData in game_data.values():
		var name = playerData.get("name", null)
		if name:
			names.append(name)
			nameToPlayerData[name] = playerData

	# alphabetize list
	names.sort()

	# update the UI control with list of players

	# clear existing children
	for child in playersList.get_children():
		child.queue_free()

	# rebuild list
	for name in names:
		var row = PLAYER_ROW.instantiate()
		playersList.add_child(row)
		row.selected.connect(_on_player_selected)

		var p_info = nameToPlayerData[name]

		# Now you can access normal nodes!
		row.set_text(name)
		row.set_color(p_info.get("color", Color.WHITE))

		##
		# todo: make yourself bold
		#if peer_id == my_peer_id:
		#	#row.get_node("NameLabel").add_theme_font_override("font", load("res://BoldFont.ttf"))
		#	# Or just change the text color
		#	row.get_node("NameLabel").modulate = Color.YELLOW
		##


func get_item_text(index) -> String:
	return playersList.get_child(index).get_text()


func _on_player_selected(name: String) -> void:
	# what's the network ID for this name?
	var network_id = find_player_network_id_from_name(name)
	player_selected.emit(network_id)


func find_player_network_id_from_name(name) -> int:
	# just do a linear search for now
	for player_id in game_data:
		var playerData = game_data[player_id]
		if playerData.get("name", "") == name:
			return player_id

	# indicate failure
	return -1
