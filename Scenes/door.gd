extends Area2D

var playerHasKey = false
var playerBody


func _input(event: InputEvent):
	pass

func _on_body_entered(body: Node2D):
	if "Player" in body.name:
		
		playerBody = body
		if body.has_key:
			playerHasKey = true
			body.has_key = false
			TransitionScreen.transition()
			await TransitionScreen.on_transition_finished
			get_tree().change_scene_to_file("res://Scenes/Level2.tscn")
		else: $Label.visible = true
func _on_body_exited(body: Node2D):
	$Label.visible = false
