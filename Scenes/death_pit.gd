extends Area2D

@onready var start_spawn = $start_spawn

func _on_body_entered(body: Node2D):
	if "Player" in body.name:
		body.queue_free()
		$Sprite2D.visible = true
		$AnimationPlayer.play("falling")
		await $AnimationPlayer.animation_finished
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		get_tree().reload_current_scene()
