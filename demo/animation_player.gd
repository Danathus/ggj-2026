@tool
extends AnimationPlayer

@export var play_on_ready: bool = true
@export var run_animation: bool = false
@export var animation: String = ""

func _validate_property(property: Dictionary) -> void:
	if property.get("name") == &"animation":
		var names := get_animation_list()
		if names.is_empty():
			names = ["<none>"]
		property["type"] = TYPE_STRING
		property["hint"] = PROPERTY_HINT_ENUM
		property["hint_string"] = ",".join(names)
		property["usage"] |= PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE

func _ready() -> void:
	if Engine.is_editor_hint():
		# Force the Inspector to refresh the enum list.
		notify_property_list_changed()
		return

	if play_on_ready and animation != "" and animation != "<none>":
		if has_animation(animation):
			play(animation)
		else:
			push_warning("Autoplay animation not found: %s" % animation)
		
func _process(delta: float) -> void:
	if (run_animation):
		if animation != "" and animation != "<none>" and has_animation(animation):
			play(animation)
