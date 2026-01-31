extends Node

@export var anim_left_player_path: NodePath = NodePath()
@export var anim_right_player_path: NodePath = NodePath()

@onready var anim_left_player := get_node(anim_left_player_path) as AnimationPlayer
@onready var anim_right_player := get_node(anim_right_player_path) as AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await play()
	print("anim complete")

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass


func play() -> void:
	if not anim_left_player or not anim_right_player:
		push_error("ninja.play(): missing left/right AnimationPlayer reference.")
		return

	var remaining := [2]
	var on_finished := func(_anim_name: StringName) -> void:
		remaining[0] -= 1

	anim_left_player.animation_finished.connect(on_finished, CONNECT_ONE_SHOT)
	anim_right_player.animation_finished.connect(on_finished, CONNECT_ONE_SHOT)

	anim_left_player.play_animation()
	anim_right_player.play_animation()

	while remaining[0] > 0:
		await get_tree().process_frame
