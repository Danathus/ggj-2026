extends VBoxContainer

@onready var playersList: ItemList = $PlayersList

# signal up when we select a player (so parent can handle e.g. send network messages)
signal player_selected(peer_id: int)


# cheat and retain game_data whenever passed in
var game_data = {} # default to empty but this will be overridden


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update(in_game_data) -> void:
	game_data = in_game_data

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

func get_item_text(index) -> String:
	return playersList.get_item_text(index)

func _on_players_list_item_selected(index: int) -> void:
	# what's the name at this index?
	#var name = playersList.get_item_text(index)
	var name = playersList.get_item_text(index)

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
