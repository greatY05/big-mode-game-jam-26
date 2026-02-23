extends RigidBody2D


@onready var screen_break_position : Vector2
@onready var target: Node2D
@onready var homing_speed = 300
@onready var should_home = false
@onready var friendlyfire = false  #only hit enemies if hte bullet was bounced back by the player
var hit_wall = false #can only hit the wall once
var delete_timer = 0.0 # timer for deletion after staying put for a while


func _ready() -> void:
	get_node("/root/scene/Camera").shake.connect(jump) #bind signal camera shake to the bullet jumping

func _physics_process(delta: float) -> void:
	#condition and start of popup windows - 
	if global_position.x > Global.screen_size.x or global_position.x < 0 or global_position.y > Global.screen_size.y or global_position.y < 0:
		#print("out! ", global_position)
		screen_break_position = global_position #save position of exiting screen
		Global.score += 20 #should add a global fucntion to handle scroing instead of adding it like that 
		Windows.create_window(screen_break_position, linear_velocity) #continue logic of popup window in the windows script
		#add some sort of visual indictaor? #nah
		queue_free()
	#if friendlyfire: #once hit by player
		##if should_home and target: #shouldhome - defunct for now (was intended to make bullets hitting enemies easier)
			#var direction = (target.global_position - global_position).normalized()
			#linear_velocity = direction * homing_speed
	if linear_velocity.length() < 15 and !freeze:
		delete_timer-= delta # start counting down to deletion if idle
		if delete_timer <= 0:
			fade_out() #delete bullet once still (or close to 0)
	else:
		delete_timer = 1.5 #reset timer if movement renews

##DEFUNCT homing stuff that got scrapped, reimplement is possible if you want bullets to go to enemies instead of bounce around 
#func set_homing(new_target: Node2D, speed: int) -> void:
	#target = new_target
	#homing_speed = speed
#
#func _on_bullet_homing_range_area_entered(area: Area2D) -> void:
	#if area.is_in_group("enemy") and friendlyfire:
		#set_homing(area.get_parent(), 200)


func destroy(): #expendable for animations or other logic like spawning new stuff out of death
	queue_free()

func fade_out(): #pre death logic of fading out
	var tween := create_tween()
	tween.tween_property($texture, "modulate:a", 0, 1)
	await tween.finished
	destroy()

func jump(): #make balls jump in place if they stand still to give impact to ground slam
	if abs(linear_velocity.y) < 50 and !freeze:
		linear_velocity.y -= randf_range(100, 500)
