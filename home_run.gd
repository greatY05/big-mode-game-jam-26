extends Area2D

var hit_count_requirement = 3
var hit_count = 0
var home_run_timer_time = 0 #10
var chain_hit_timer = 2
@onready var home_run_timer: Timer = $home_run_timer
@onready var wall_collision: CollisionPolygon2D = $"../border_wall/CollisionPolygon2D"

@export var ripple_rect : ColorRect
@onready var ripple_shader: ColorRect = $"../Camera/ripple_shader"
@onready var home_run_label: RichTextLabel = $"../home_run_label"
@onready var progress_bar: ProgressBar = $"../home_run_label/progress_homerun"
@onready var scene: Node2D = $".."

var default_color #default shader color

func _ready() -> void:
	get_parent().round_over.connect(_on_home_run_timer_timeout.bind()) #when game ends emit home run over



func _physics_process(delta: float) -> void:
	#if home_run_timer_time > 10:
		#home_run_timer_time - delta #idk why this is here its probably to remove
	if home_run_active:
		#print(home_run_timer.time_left)
		progress_bar.value = home_run_timer.time_left



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("hittable") and !body.hit_wall and !home_run_active:
		$"../sounds/Bounce".play()
		body.linear_velocity.x *= -0.8
		if body.hit_wall:
			return
		#if !abs(body.linear_velocity.y) > 5:
			#body.linear_velocity.x *= -5.8
		body.hit_wall = true
		hit_count += 1
		check_home_run_progress()
		
		#animation with raising pitch
		
		#var new_material = ripple_material.duplicate()
		var new_ripple_shader = ripple_shader.duplicate()
		add_child(new_ripple_shader)
		new_ripple_shader.show()
		new_ripple_shader.material = new_ripple_shader.get_material().duplicate()
		var ripple_material = new_ripple_shader.material
		
		var shader_pos = body.global_position / Vector2(get_window().size)
		ripple_material.set_shader_parameter("circle_center", shader_pos)
		#ripple_material.set_shader_parameter("color", Color.WHITE)

		var tween : Tween = create_tween()
		tween.tween_property(ripple_material, "shader_parameter/time", 1.0, 0.4).set_ease(Tween.EASE_IN)
		await tween.finished
		new_ripple_shader.queue_free()
		#print("ball hit the wall at ", body.global_position, " shader is at ", shader_pos)
		
var home_run_active = false
func check_home_run_progress():
	if hit_count == hit_count_requirement:
		homerun_logic(true)
		home_run_active = true
	elif hit_count < hit_count_requirement:
		print("left to hit ", hit_count_requirement - hit_count)

var loop_tween : Tween

func homerun_logic(active_state : bool):
	if active_state:
		print("homerun!!!")
		get_parent().disable_wall(true)
		var tween: Tween = create_tween()
		tween.tween_property(home_run_label, "position:y", 309, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		$"../sounds/HomeRun".play()
		home_run_timer.start()
		home_run_timer_time = 10
		
		await tween.finished
		loop_tween = create_tween().set_loops()
		loop_tween.tween_property(home_run_label, "scale",Vector2.ONE * 1.2, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		loop_tween.tween_property(home_run_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		
	else: #if home run over
		var tween: Tween = create_tween()
		tween.tween_property(home_run_label, "position:y", -218.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		get_parent().disable_wall(false)
		

func _on_home_run_timer_timeout() -> void:
	if loop_tween:
		loop_tween.kill()
	hit_count = 0
	home_run_active = false
	homerun_logic(false)
	#border_wall_collision.disabled = false
	print("home run over")
