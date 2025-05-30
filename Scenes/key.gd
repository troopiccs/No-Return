extends Area2D


func _on_body_entered(body: Node2D):
	if "Player" in body.name:
		body.has_key = true
		$pickup.play()
		await $pickup.finished
		queue_free()
