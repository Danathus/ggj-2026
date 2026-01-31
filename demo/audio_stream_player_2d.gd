extends AudioStreamPlayer2D

@export var landingClips: Array[AudioStream] = []
@export var runningClips: Array[AudioStream] = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func play_random_landing_clip() -> void:
	if landingClips.is_empty():
		push_warning("audio_stream_player_2d.play_random_landing_clip(): no landingClips assigned.")
		return

	var index := _rng.randi_range(0, landingClips.size() - 1)
	stream = landingClips[index]
	play()

func play_random_running_clip() -> void:
	if runningClips.is_empty():
		push_warning("audio_stream_player_2d.play_random_running_clip(): no runningClips assigned.")
		return

	var index := _rng.randi_range(0, runningClips.size() - 1)
	stream = runningClips[index]
	play()
