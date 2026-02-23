extends Node

var BREAK_WINDOW = preload(("res://break_window.tscn"))
const BREAK_OUT = preload("uid://b36ug6htbwa44")



var max_windows = 24 #max size before staring to delete windows
var window_list = [] #array to keep track of all popup windows
var window_velocity : Vector2 #no built in velocty on window
var active_window = null #current window we operate on
var gravity = 1500 
var original_window_pos 

var window_pos: Vector2: 
	set(value):
		DisplayServer.window_set_position(value) #setter - when window repositioned - refetch the position for new break position calculations

func _ready() -> void:
	original_window_pos = DisplayServer.window_get_position() #get position of main game window


func create_window(break_position: Vector2, velocity: Vector2): 
	play_break_out_sound()
	
	var break_window = BREAK_WINDOW.instantiate()
	get_tree().root.add_child(break_window) #since this script is global we add the instantiated popup window to the root (or node that keeps track of popups
	
	var viewport_size = get_viewport().get_visible_rect().size #size of main window
	var window_pos = DisplayServer.window_get_position() #position of main window
	
	#clamp the given break position within the current monitors borders (means if main window in the middle of two screens popups will only come out of 1size)
	var local_pos = break_position
	local_pos.x = clamp(local_pos.x, 0, viewport_size.x)
	local_pos.y = clamp(local_pos.y, 0, viewport_size.y)
	
	#print("Window pos: ", window_pos)
	
	break_window.setup(local_pos + Vector2(window_pos), velocity) #set up values and transforms
	window_list.append(break_window) #add to array to keep access to all windows
	check_if_full() #if max number of windows reached - remove oldest popup
	shake_window(break_position)

##DEFUNCT - OLD physics process, now runs individually on each window for multiprocessing instead of only being to handle 1 i nthis global script
#func _physics_process(delta: float) -> void:
	#if active_window:
		##active_window.position.y += gravity * delta #apply gravity
		##active_window.position += Vector2i(window_velocity * delta)  #moved to break_window processing
		#
		#
		#var screen0_size = DisplayServer.screen_get_usable_rect(0).size.x
		#var screen1_offset = Vector2(screen0_size, 0)
		#var screen_rect = DisplayServer.screen_get_usable_rect(1)
		#var window_size = Vector2(active_window.size)
		#
		## Clamp to screen 1 bounds
		#var local_pos = active_window.position - Vector2i(screen1_offset)
		#local_pos = local_pos.clamp(Vector2.ZERO, Vector2(screen_rect.size) - window_size)
		#active_window.position = local_pos + Vector2i(screen1_offset)
		#
		## Bounce logic
		#if active_window.position.y <= screen1_offset.y:
			#window_velocity.y *= -0.8
		#if active_window.position.y + window_size.y >= screen_rect.size.y + screen1_offset.y:
			#window_velocity.y *= -0.8
		#
		#if active_window.position.x <= screen1_offset.x:
			#window_velocity.x *= -0.8
		#if active_window.position.x + window_size.x >= screen_rect.size.x + screen1_offset.x:
			#window_velocity.x *= -0.8


func shake_window(break_position): #shake the window when a ball is going out
	var window_size = get_window().size
	var screen_center = Vector2(window_size.x / 2.0, window_size.y / 2.0)  #get center of the window to anchor shake there and reposition at end of shake
	var direction = (screen_center - break_position).normalized() #direction of shake pushing away from the break position
	
	var original_pos = DisplayServer.window_get_position() #original position
	var shake_strength = 30.0
	var shake_count = 0
	
	while shake_count < 4:  #set shakes by changing the number
		#position of the next shake interation normalized by the screen height for impact
		var shake_pos = Vector2(original_pos) + direction * shake_strength * (1 - (break_position.y /  get_viewport().get_visible_rect().size.y) )
		DisplayServer.window_set_position(Vector2i(shake_pos)) 
		await get_tree().create_timer(0.015).timeout #intervals of shakes 
		
		DisplayServer.window_set_position(Vector2i(original_pos)) #reposition
		await get_tree().create_timer(0.015).timeout #intervals of shakes
		
		shake_strength *= 0.7  #reduce strength each shake
		shake_count += 1

func check_if_full():
	if window_list.size() > max_windows:
		free_window() #frees the oldest window in the array

func free_window():
	#print("freeing window")
	window_list[0].kill() # break_window function
	window_list.remove_at(0) #removes from array

func play_break_out_sound(): #since thsi is a global script we cant reference noides therefore a function to play audio
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = BREAK_OUT
	add_child(audio_player)
	audio_player.play()
	await audio_player.finished
	audio_player.queue_free()
