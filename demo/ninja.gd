extends Node

@export var anim_left_player_path: NodePath = NodePath()
@export var anim_right_player_path: NodePath = NodePath()

@export var sprite_left_player_path: NodePath = NodePath()
@export var sprite_right_player_path: NodePath = NodePath()

@onready var anim_left_player := get_node(anim_left_player_path) as AnimationPlayer
@onready var anim_right_player := get_node(anim_right_player_path) as AnimationPlayer

@onready var sprite_left_player := get_node(sprite_left_player_path) as CanvasItem
@onready var sprite_right_player := get_node(sprite_right_player_path) as CanvasItem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# delete this "set" after this is properly hooked up
	#set_player_colors(Color.RED, Color.BLUE)

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


func reset_players() -> void:
	anim_left_player.stop();
	anim_right_player.stop();


# sets the color of the sprites of each player
func set_player_colors(left_player_color: Color, right_player_color: Color) -> void:
	if not sprite_left_player or not sprite_right_player:
		push_error("ninja.set_player_colors(): missing left/right sprite reference.")
		return

	sprite_left_player.modulate = left_player_color
	sprite_right_player.modulate = right_player_color
