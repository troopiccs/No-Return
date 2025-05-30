extends Node2D

@export var enemy_scene: PackedScene
@onready var spawn_points = $SpawnPoints.get_children()
var velocity = Vector2.ZERO
var has_spawned = false


func _ready() -> void:
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("idle")
	for point in spawn_points:
		print("Spawn marker: ", point.name, " Global Pos: ", point.global_position)



func _process(delta):
	print("Spawner position: ", global_position)


func _on_press_body_exited(body: Node2D):
	$AnimatedSprite2D.play("idle")

func _on_press_body_entered(body: Node2D):
	if body.is_in_group("Player") and not has_spawned:
		has_spawned = true
		spawn_enemies(6)
		$AnimatedSprite2D.play("press")
		$button.play()
		
		
func spawn_enemies(amount: int) -> void:
	var used_indices := []
	for i in range(amount):
		var available = []
		for j in range(spawn_points.size()):
			if j not in used_indices:
				available.append(j)

		if available.is_empty():
			break

		var index = available[randi() % available.size()]
		used_indices.append(index)

		var spawn_marker: Marker2D = spawn_points[index]
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_marker.global_position
		get_tree().current_scene.add_child(enemy)
