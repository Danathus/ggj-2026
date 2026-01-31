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
	#run_tests()
	pass


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
	
	
func run_tests():
	print("=== TEST 1: Rock vs Scissors ===")
	players_dict.clear()
	players_dict[1] = choice.rock
	players_dict[2] = choice.scissors
	print("Winner:", resolve_round())  # expect 1
	
	print("=== TEST 1: Paper vs Scissors ===")
	players_dict.clear()
	players_dict[1] = choice.paper
	players_dict[2] = choice.scissors
	print("Winner:", resolve_round())  # expect 2

	print("=== TEST 2: Tie ===")
	players_dict.clear()
	players_dict[3] = choice.paper
	players_dict[4] = choice.paper
	print("Winner:", resolve_round())  # expect 0

	print("=== TEST 3: Waiting ===")
	players_dict.clear()
	players_dict[5] = choice.rock
	print("Winner:", resolve_round())  # expect -1
