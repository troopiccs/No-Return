extends Area2D


@onready var stair_return_spawn = $stair_return_spawn

func _on_body_entered(body: Node2D):
	if "Player" in body.name:
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		body.global_position = stair_return_spawn.global_position
