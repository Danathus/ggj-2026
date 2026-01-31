extends AudioStreamPlayer2D

@export var landingClips: Array[AudioStream] = []
@export var runningClips: Array[AudioStream] = []
@export var jumpingClips: Array[AudioStream] = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func play_random_landing_clip() -> void:
	_play_random(landingClips, "landingClips")

func play_random_running_clip() -> void:
	_play_random(runningClips, "runningClips")

func play_random_jumping_clip() -> void:
	_play_random(jumpingClips, "jumpingClips")

func _play_random(clips: Array[AudioStream], label: String) -> void:
	if clips.is_empty():
		push_warning("audio_stream_player_2d.play_random(): no %s assigned." % label)
		return

	var index := _rng.randi_range(0, clips.size() - 1)
	stream = clips[index]
	play()
