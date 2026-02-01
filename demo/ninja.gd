extends Node

@export var anim_left_player_path: NodePath = NodePath()
@export var anim_right_player_path: NodePath = NodePath()

@export var anim_left_player_fall_path: NodePath = NodePath()
@export var anim_right_player_fall_path: NodePath = NodePath()

@export var sprite_left_player_path: NodePath = NodePath()
@export var sprite_right_player_path: NodePath = NodePath()

@export var background_path: NodePath = NodePath("Background")

@onready var anim_left_player := get_node(anim_left_player_path) as AnimationPlayer
@onready var anim_right_player := get_node(anim_right_player_path) as AnimationPlayer

@onready var anim_left_player_fall := get_node(anim_left_player_fall_path) as AnimationPlayer
@onready var anim_right_player_fall := get_node(anim_right_player_fall_path) as AnimationPlayer

@onready var sprite_left_player := get_node(sprite_left_player_path) as CanvasItem
@onready var sprite_right_player := get_node(sprite_right_player_path) as CanvasItem

@onready var background_sprite := get_node(background_path) as CanvasItem

var winning_side = "tie" # will be overridden

var _pulse_elapsed := -1.0
var _pulse_duration := 1.0

var show_hand_drawn_sprites = true # default setting can be overridden by UI

var left_player_choice = "rock"
var right_player_choice = "rock"

@onready var left_ninja_mask: Sprite2D = $"Left Player/Sprite2D/NinjaMask"
@onready var right_ninja_mask: Sprite2D = $"Right Player/Sprite2D/NinjaMask2"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# delete this "set" after this is properly hooked up
	#set_player_colors(Color.RED, Color.BLUE)

	await play()

	# make loser fall
	match winning_side:
		"left":
			anim_right_player_fall.play_animation()
		"right":
			anim_left_player_fall.play_animation()

	# all done
	print("anim complete")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _pulse_elapsed < 0.0:
		return

	var material := _get_background_material()
	if material == null:
		_pulse_elapsed = -1.0
		return

	_pulse_elapsed += delta
	material.set_shader_parameter("pulse_time", _pulse_elapsed)

	if _pulse_elapsed >= _pulse_duration:
		material.set_shader_parameter("pulse_time", -1.0)
		_pulse_elapsed = -1.0


func play() -> void:
	_applySpriteSettings()

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


const rock_texture : Texture2D = preload("res://demo/rock_cat_10th.png")
const paper_texture : Texture2D = preload("res://demo/paper_ninja_10th.png")
const scissors_texture : Texture2D = preload("res://demo/elephant_10th.png")

const solid_color_square_texture: Texture2D = preload("res://materials/white.png")


func _choice_to_texture(choice: String) -> Texture2D:
	match choice:
		"rock":
			return rock_texture
		"paper":
			return paper_texture
		"scissors":
			return scissors_texture
		_:
			return paper_texture

func set_player_choices(in_left_player_choice: String, in_right_player_choice: String) -> void:
	left_player_choice = in_left_player_choice
	right_player_choice = in_right_player_choice


# either "left" or "right" or "tie" -- set before play()
func set_winner(winner_description) -> void:
	winning_side = winner_description


func trigger_pulse(duration: float = -1.0) -> void:
	var material := _get_background_material()
	if material == null:
		push_error("ninja.trigger_pulse(): missing background material.")
		return

	if duration > 0.0:
		_pulse_duration = duration
		material.set_shader_parameter("pulse_duration", _pulse_duration)
	else:
		var current_duration = material.get_shader_parameter("pulse_duration")
		_pulse_duration = current_duration if current_duration != null else _pulse_duration

	_pulse_elapsed = 0.0
	material.set_shader_parameter("pulse_time", _pulse_elapsed)


func _get_background_material() -> ShaderMaterial:
	if not background_sprite:
		return null
	return background_sprite.material as ShaderMaterial


# in practice most likely set once before animation starts
# but, if we can support live swapping, that's ideal
func toggleShowHandDrawn(use_hand_drawn) -> void:
	show_hand_drawn_sprites = use_hand_drawn
	# apply (live potentially)
	_applySpriteSettings()


func _applySpriteSettings() -> void:
	var desired_scale = [1, 1]
	if show_hand_drawn_sprites:
		sprite_left_player.texture = _choice_to_texture(left_player_choice)
		sprite_right_player.texture = _choice_to_texture(right_player_choice)
		desired_scale = [0.02, 0.02]
		left_ninja_mask.visible = false
		right_ninja_mask.visible = false
	else:
		sprite_left_player.texture = solid_color_square_texture
		sprite_right_player.texture = solid_color_square_texture
		desired_scale = [1, 1]
		left_ninja_mask.visible = true
		right_ninja_mask.visible = true
	sprite_left_player.scale.x = desired_scale[0]
	sprite_left_player.scale.y = desired_scale[1]
	sprite_right_player.scale.x = desired_scale[0]
	sprite_right_player.scale.y = desired_scale[1]
