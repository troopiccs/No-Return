extends Node2D


func _ready() -> void:
	$key/AnimatedSprite2D.play("idle")
	$ambience.play()
	$music.play()
