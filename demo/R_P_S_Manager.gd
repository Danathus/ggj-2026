extends Node

enum choice {rock, paper, scissors, invalid}

var players_dict = {}

# beats[a] == b means "a beats b"
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


func UseRock(player_id: int) -> void:
	players_dict[player_id] = choice.rock

func UseScissor(player_id: int) -> void:
	players_dict[player_id] = choice.scissors

func UsePaper(player_id: int) -> void:
	players_dict[player_id] = choice.paper

func resolve_round(p1_id: int, p2_id: int) -> int:
	# this function will return
	# -1 = not everyone has chosen
	# 0 = tie
	# player_id = the player that has won

	## try to find the players in the dictionary
	var c1 = players_dict.get(p1_id, choice.invalid)
	var c2 = players_dict.get(p2_id, choice.invalid)

	if c1 == choice.invalid or c2 == choice.invalid:
		return -1

	if c1 == c2:
		# tie
		return 0

	return p1_id if beats[c1] == c2 else p2_id


func run_tests():
	print("=== TEST 1: Rock vs Scissors ===")
	players_dict.clear()
	players_dict[1] = choice.rock
	players_dict[2] = choice.scissors
	print("Winner:", resolve_round(1, 2))  # expect 1
	
	print("=== TEST 1: Paper vs Scissors ===")
	players_dict.clear()
	players_dict[1] = choice.paper
	players_dict[2] = choice.scissors
	print("Winner:", resolve_round(1, 2))  # expect 2

	print("=== TEST 2: Tie ===")
	players_dict.clear()
	players_dict[3] = choice.paper
	players_dict[4] = choice.paper
	print("Winner:", resolve_round(3, 4))  # expect 0

	print("=== TEST 3: Waiting ===")
	players_dict.clear()
	players_dict[5] = choice.rock
	print("Winner:", resolve_round(1, 2))  # expect -1
