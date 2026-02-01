extends MarginContainer

@onready var nameLabel: Label = $HBoxContainer/NameLabel
@onready var playerColor: ColorRect = $HBoxContainer/PlayerColor

var index = 0 # communicated from level above

signal selected(text: String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_index(i: int) -> void:
	index = i

func set_text(text: String) -> void:
	nameLabel.text = text

func get_text() -> String:
	return nameLabel.text

func set_color(color) -> void:
	playerColor.color = color


func _on_button_pressed() -> void:
	selected.emit(nameLabel.text)
