extends Node

enum choice {rock, paper, scissors}

var players_dict = {
	
}

var beats = {
	choice.rock: choice.scissors,
	choice.paper: choice.rock,
	choice.scissors: choice.paper
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _UseRock(player_id: int) -> void:
	players_dict[player_id] = choice.rock

func _UseScissor(player_id: int) -> void:
	players_dict[player_id] = choice.scissors

func _UsePaper(player_id: int) -> void:
	players_dict[player_id] = choice.paper

func resolve_round() -> int:
	# this function will return
	# -1 = not everyone has chosen
	# 0 = tie
	# player_id = the player that has won
	
	if players_dict.size() != 2:
		return -1  # not ready or invalid state

	var ids := players_dict.keys()
	var p1_id: int = ids[0]
	var p2_id: int = ids[1]

	var c1: choice = players_dict[p1_id]
	var c2: choice = players_dict[p2_id]

	if c1 == c2:
		return  0 # tie
		
	return p1_id if beats[c1] == c2 else p2_id
