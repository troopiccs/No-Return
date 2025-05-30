extends StaticBody2D

@onready var Camera: Camera2D = get_tree().get_first_node_in_group("Camera")

var health := 3  

func _ready():
	$AnimatedSprite2D.play("shine")

func _on_hitbox_area_entered(area: Area2D):
	if area.name == "attack_area":
		health -= 1
		$AnimatedSprite2D.play("Hit1")
		$hit.play()
		Camera.trigger_shake()
		if health <= 0:
			break_box()

func break_box():
	$AnimatedSprite2D.play("Break")
	await $AnimatedSprite2D.animation_finished
	queue_free()
