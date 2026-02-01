@tool
extends AnimationPlayer

var animation: String = ""
@export var particle_system_path: NodePath = NodePath()

@onready var particle_system := get_node_or_null(particle_system_path)

func _get_property_list() -> Array[Dictionary]:
	var names := get_animation_list()
	return [
		{
			"name": "animation",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(names),
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE
		}
	]

func _get(property: StringName) -> Variant:
	if property == &"animation":
		return animation
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == &"animation":
		animation = String(value)
		return true
	return false

func _ready() -> void:
	if Engine.is_editor_hint():
		# Force the Inspector to refresh the enum list.
		notify_property_list_changed()
		return

	particle_system = get_node_or_null(particle_system_path)

func play_animation() -> void:
	if animation != "":
		if has_animation(animation):
			play(animation)
		else:
			push_warning("Animation not found: %s" % animation)

func set_particles_enabled(enabled: bool) -> void:
	if not particle_system:
		push_warning("Particle system not set.")
		return

	if particle_system.has_method("set_emitting"):
		particle_system.set("emitting", enabled)
	else:
		push_warning("Particle system does not support 'emitting': %s" % particle_system.name)
