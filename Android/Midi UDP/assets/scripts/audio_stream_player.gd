extends AudioStreamPlayer
@export var delete : bool = false
var base_pitch : float = 0
func _process(delta: float) -> void:
	if delete:
		queue_free()
func _on_finished() -> void:
	queue_free()
