extends Window

var window_velocity: Vector2 #save diy velocity since window class doesnt have built in
var gravity = 1000 #gravity scale

func _ready() -> void:
	get_node("/root/scene/Camera").shake.connect(window_jump) #bind for ground slam impact logic

func setup(break_position: Vector2, velocity: Vector2) -> void: #setup - set values and transforms for the new window
	position = break_position + Vector2(0, -25)
	window_velocity = velocity
	#size = Vector2(200, 200)
	visible = true

func _physics_process(delta: float) -> void:
	if window_velocity.length() < 0.1:
		window_velocity = Vector2.ZERO #stop position calculation if  velocity is low to save processing power
		return
	
	window_velocity.y += gravity * delta #gravity
	window_velocity *= 0.98 #"friction" / slowing down naturally
	position += Vector2i(window_velocity * delta) #windwo calss position is in int (since coordinates) - casting velocity to vec2i and multiplying by delta
	
	#screen indexing - godot is a bit wonky with counting monitors
	var screen_idx = DisplayServer.window_get_current_screen() #get the index of the current screen
	var screen_rect = DisplayServer.screen_get_usable_rect(screen_idx) #get teh size of the monitor (not window)
	var screen_pos = Vector2(screen_rect.position) #position of the window in the monitor
	var screen_size = Vector2(screen_rect.size) #size of window
	
	# creating virtual boundaries for popup windows to bounce around in - clamping windows inside
	if position.x < screen_pos.x: #left side of monitor
		position.x = screen_pos.x
		window_velocity.x *= -0.8 #reverse velocity as to "bounce"
	elif position.x + size.x > screen_pos.x + screen_size.x: #right side of monitor - check popup window right side by its position + its size 
		position.x = screen_pos.x + screen_size.x - size.x 
		window_velocity.x *= -0.8 #reverse velocity as to "bounce"
	
	if position.y < screen_pos.y: #top border
		position.y = screen_pos.y
		window_velocity.y *= -0.8 #reverse velocity as to "bounce"
	elif position.y + size.y > screen_pos.y + screen_size.y: # bottom border - popup window position + its size  to get bottom border
		position.y = screen_pos.y + screen_size.y - size.y
		window_velocity.y *= -0.8 #reverse velocity as to "bounce"


func kill():
	#print("goodbye! im window!")
	var tween := create_tween()
	tween.tween_property($Camera2D/texture, "modulate:a", 0, 1) # fade out
	await tween.finished
	queue_free()

func window_jump(): #make windwo "jump" as impact from ground slam/jump signal
	if window_velocity.y < 50:
		window_velocity.y -= randf_range(100, 500)
