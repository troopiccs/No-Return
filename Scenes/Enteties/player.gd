extends CharacterBody2D

@onready var attack_area = $attack_area/CollisionShape2D
@onready var ability_area = $ability_area/CollisionShape2D

# Player state variables
var is_in_cutscene = false
var is_ability = false
var is_invisible = false
var is_dashing = false
var is_attacking = false
var has_key = false
var combo_step = 0
var combo_timer = null
var combo_window = 0.4  # seconds to press attack again
var combo_ready = false

# Movement and combat variables
var health = 100
var current_attack_damage = 0
var dash_velocity = Vector2.ZERO
var dash_multiplyer = 3
var run_multiplyer = 2
var base_speed = 35
var speed = 35
var direction = Vector2.ZERO
var last_direction = "up"
var knockback_velocity := Vector2.ZERO


func take_damage(amount: int):
	health -= amount

func _ready() -> void:
	$ability_timer.connect("timeout", Callable(self, "_on_ability_timer_timeout"))
	$playersprite.connect("animation_finished", Callable(self, "_on_playersprite_animation_finished"))
	$combo_window_timer.connect("timeout", Callable(self, "_on_combo_window_timeout"))
	# Disable attack hitboxes initially
	attack_area.disabled = true
	ability_area.disabled = true
func get_facing_direction(dir: Vector2) -> String:
	if dir.x > 0:
		return "right"
	elif dir.x < 0:
		return "left"
	elif dir.y > 0:
		return "down"
	elif dir.y < 0:
		return "up"
	return last_direction
	
func use_ability_one():
	current_attack_damage = 40
	is_ability = true
	$playersprite.play("ability1_" + last_direction)

	await get_tree().create_timer(0.8).timeout  # Wind-up delay
	ability_area.disabled = false              # Enable hitbox

	await get_tree().create_timer(0.2).timeout  # Duration of hitbox
	ability_area.disabled = true              # Disable again

	$ability_timer.start()
	flash_color(Color(4, 4, 4))
func use_ability_two():
	current_attack_damage = 40
	is_ability = true
	$playersprite.play("ability2_" + last_direction)

	await get_tree().create_timer(0.6).timeout  # Wind-up delay
	ability_area.disabled = false              # Enable hitbox

	await get_tree().create_timer(0.2).timeout  # Duration of hitbox
	ability_area.disabled = true              # Disable again

	$ability_timer.start()
	flash_color(Color(4, 4, 4))
func _physics_process(delta: float) -> void:
	
	velocity = Vector2.ZERO
	
	# Disable attack areas each frame by default
	attack_area.disabled = true


	# Handle knockback movement and damping
	if knockback_velocity.length() > 5:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200 * delta)
		move_and_slide()
		return

	# Stop all movement during cutscene
	if is_in_cutscene:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# Handle player attacking logic
	player_attack()
	# Get movement input direction
	direction = Vector2.ZERO
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1

	# If dashing, just move with current velocity
	if is_dashing:
		velocity = dash_velocity
		move_and_slide()
		return

	dash_velocity = direction.normalized() * speed * dash_multiplyer

	# Start dash if input detected and timers allow
	if Input.is_action_just_pressed("dash") and $dashtimer.is_stopped() and $dashcooldown.is_stopped():
		if direction != Vector2.ZERO:
			velocity = direction.normalized() * speed * dash_multiplyer
		else:
			# Dash in the last facing direction if no input is given
			match last_direction:
				"up": velocity = Vector2.UP * speed * dash_multiplyer
				"down": velocity = Vector2.DOWN * speed * dash_multiplyer
				"left": velocity = Vector2.LEFT * speed * dash_multiplyer
				"right": velocity = Vector2.RIGHT * speed * dash_multiplyer
		$playersprite.play("dash")
		$dashtimer.start()
		$dashcooldown.start()
		is_dashing = true
		is_invisible = true
		is_attacking = false
		is_ability = false
		move_and_slide()
		return

	# Stop movement if using ability or attacking
	if is_ability or is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Adjust speed and animation based on run input
	var animation_name = "walk_"
	if Input.is_action_pressed("run"):
		speed = base_speed * run_multiplyer
		animation_name = "run_"
	else:
		speed = base_speed

	# Play movement animations based on input direction
	if direction != Vector2.ZERO:
		var facing = get_facing_direction(direction)
		$playersprite.play(animation_name + facing)
		last_direction = facing
	else:
		$playersprite.play("idle_" + last_direction)

	# Calculate final velocity including knockback
	velocity = direction.normalized() * speed
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 100 * delta)
	move_and_slide()
func _play_combo_animation() -> void:
	match combo_step:
		1:
			$playersprite.play("attack1_" + last_direction)
			$combo_window_timer.start(0.3)  # tune per animation
		2:
			$playersprite.play("attack2_" + last_direction)
			$combo_window_timer.start(0.3)
		3:
			$playersprite.play("attack3_" + last_direction)
			$combo_window_timer.start(0.3)
		_:
			_reset_combo()

	match last_direction:
		"up": $attack_area.position = Vector2(0, -16)
		"down": $attack_area.position = Vector2(0, 16)
		"left": $attack_area.position = Vector2(-16, 0)
		"right": $attack_area.position = Vector2(16, 0)

	attack_area.disabled = false
func flash_color(color: Color, duration: float = 0.1) -> void:
	$playersprite.modulate = color
	await get_tree().create_timer(duration).timeout
	$playersprite.modulate = Color(1, 1, 1)  # Reset to normal (white)
func player_attack() -> void:
	if Input.is_action_just_pressed("attack1"):
		if combo_step == 0 or combo_ready:
			combo_step += 1
			combo_ready = false
			is_attacking = true
			_play_combo_animation()
			attack_area.disabled = false
			
			match combo_step:
				1:
					current_attack_damage = 10
				2:
					current_attack_damage = 10
				3:
					current_attack_damage = 20
			
			match combo_step:
				1:
					$playersprite.play("attack1_" + last_direction)
				2:
					$playersprite.play("attack2_" + last_direction)
				3:
					$playersprite.play("attack3_" + last_direction)
				_:
					combo_step = 0

			match last_direction:
				"up":
					$attack_area.position = Vector2(0, -10)
				"down":
					$attack_area.position = Vector2(0, 14)
				"left":
					$attack_area.position = Vector2(-12, 0)
				"right":
					$attack_area.position = Vector2(12, 0)

	if Input.is_action_just_pressed("ability1") and $ability_timer.is_stopped():
		use_ability_one()

	if Input.is_action_just_pressed("ability2") and $ability_timer.is_stopped():
		use_ability_two()
func _on_dashtimer_timeout() -> void:
	is_dashing = false
	is_invisible = false
func _on_dashcooldown_timeout() -> void:
	is_dashing = false
	is_invisible = false
func _on_area_2d_body_entered(body: Node2D) -> void: #KEY
	if body == self:
		is_in_cutscene = true
		has_key = true
		
		$playersprite.stop()
		$playersprite.play("key_collected", true)
		
		$keysprite.visible = true
		$keysprite.play("key_flip")

		await $playersprite.animation_finished

		$keysprite.queue_free()
		is_in_cutscene = false
func apply_player_knockback(force: Vector2) -> void:
	knockback_velocity = force * 0.5
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		var direction = (body.global_position - global_position).normalized()
		body.take_damage(current_attack_damage, direction)
		apply_player_knockback(-direction * 40)
func _on_ability_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		var direction = (body.global_position - global_position).normalized()
		body.take_damage(current_attack_damage, direction)
func _on_playersprite_animation_finished():
	if is_attacking:
		is_attacking = false
		combo_ready = true

		# Start combo window timer
		if combo_timer:
			combo_timer.queue_free()
		combo_timer = Timer.new()
		combo_timer.wait_time = combo_window
		combo_timer.one_shot = true
		combo_timer.connect("timeout", Callable(self, "_reset_combo"))
		add_child(combo_timer)
		combo_timer.start()

	if is_ability:
		is_ability = false
func _reset_combo():
	combo_step = 0
	combo_ready = false
	is_attacking = false
	if combo_timer:
		combo_timer.queue_free()
		combo_timer = null
func _on_combo_window_timer_timeout():
	combo_ready = true
func _on_ability_timer_timeout():
	is_ability = false
