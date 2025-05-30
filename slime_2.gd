extends CharacterBody2D

@onready var Camera: Camera2D = get_tree().get_first_node_in_group("Camera")
var knockback_velocity := Vector2.ZERO
var health = 40
var speed = 20

var is_dead = false
var player = null
var attack_range = 16
var can_attack = true

# Patrol variables
var is_patrolling = true
var patrol_origin = Vector2.ZERO
var patrol_target = Vector2.ZERO
var patrol_radius = 64
var wait_time = 1.0
var patrol_waiting = false


func _ready():
	$PatrolWaitTimer.connect("timeout", Callable(self, "_on_patrol_wait_timer_timeout"))
	$AnimatedSprite2D.play("idle")
	patrol_origin = global_position
	choose_new_patrol_target()
	patrol_origin += Vector2(randf_range(-10, 10), randf_range(-10, 10))


func choose_new_patrol_target():
	var angle = randf() * TAU
	var distance = randf_range(16, patrol_radius)
	patrol_target = patrol_origin + Vector2.RIGHT.rotated(angle) * distance



func attack_player():
	can_attack = false
	$AnimatedSprite2D.play("attack")

	if player and player.has_method("take_damage"):
		player.take_damage(10)  # Replace with your desired value

	await get_tree().create_timer(1.0).timeout  # 1 second cooldown
	can_attack = true


func _physics_process(delta: float) -> void:
	# Skip if dead
	if is_dead:
		return

	var direction = Vector2.ZERO

# Knockback override
# Apply knockback to velocity before move
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300 * delta)


# Chasing player
	elif player and is_instance_valid(player):
		var to_player = player.global_position - global_position
		var distance = to_player.length()

		if distance > attack_range:
			direction += to_player.normalized()
			$AnimatedSprite2D.play("walk")
		else:
			$AnimatedSprite2D.play("attack")
			if can_attack:
				attack_player()
		is_patrolling = false

# Patrolling
	elif is_patrolling and not patrol_waiting:
		var to_target = patrol_target - global_position
		if to_target.length() > 4:
			direction += to_target.normalized()
			$AnimatedSprite2D.play("walk")
		else:
			$AnimatedSprite2D.play("idle")
			patrol_waiting = true
			$PatrolWaitTimer.start(wait_time)

# Apply velocity
	velocity = direction.normalized() * speed
	move_and_slide()
	
	# Stuck Detection
	if is_patrolling and not patrol_waiting and velocity.length() > 0:
		if get_last_slide_collision() != null:
			choose_new_patrol_target()



	# Apply knockback movement with damping
	position += knockback_velocity * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300 * delta)
	
func flash_color(color: Color, duration: float = 0.1) -> void:
	$AnimatedSprite2D.modulate = color
	await get_tree().create_timer(duration).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)  # Reset to normal (white)


func play_hit_smoke(from_direction: Vector2):
	var smoke = preload("res://Scenes/Enteties/hit_smoke.tscn").instantiate()
	get_tree().current_scene.add_child(smoke)

	var offset = from_direction * 16
	smoke.global_position = global_position + offset

	# Rotate the smoke in the direction of the knockback
	smoke.rotation = from_direction.angle()

	var particles = smoke.get_node("GPUParticles2D")
	particles.restart()

			
func take_damage(amount: int, from_direction: Vector2):
	health -= amount
	print(health)
	play_hit_smoke(from_direction)

	$hit.play()
	Camera.trigger_shake()

	knockback_velocity = from_direction * 20
	flash_color(Color(4, 4, 4))

	if health <= 0 and not is_dead:
		is_dead = true
		player = null
		is_patrolling = false
		$Area2D/CollisionShape2D.disabled = true
		$AnimatedSprite2D.play("death")
		await $AnimatedSprite2D.animation_finished
		queue_free()


func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		is_patrolling = false
		$detectshock.visible = true
		$detectshock.play("exclamation")
		await $detectshock.animation_finished
		$detectshock.visible = false

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		is_patrolling = true
		$detectshock.visible = false
		choose_new_patrol_target()


func _on_patrol_wait_timer_timeout():
	choose_new_patrol_target()
	patrol_waiting = false
