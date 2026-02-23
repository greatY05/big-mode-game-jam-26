extends Node2D

var spawner_array = {}
const ENEMY = preload("res://enemy.tscn")

@onready var label_score: Label = $"label score"
@onready var player: CharacterBody2D = $hero_char
@onready var balls: Node2D = $balls

var goals = [100, 250, 500, 750, 1000, 10000] #proto "levels", each iteration of the game just increments in these array for higher challenge
var times = [20, 35, 45, 60, 90, 180]
var current_goal 
var allowed_to_continue = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED # start main game paused until resumed - for the tutorial that reanbles once pressed
	#very stupid and not efficient way to do so, it was last minute solution and the game is not complicated enough to warrant anything more complex
	if process_mode !=  Node.PROCESS_MODE_DISABLED:
		intro(Global.level) #start new level once unpaused
	
	Global.score_added.connect(score_ui) #connect score signal
	
	for i in $enemy_spawners.get_children(): #fetch and save enemy spawners with indicator wehtere theyre full or not
		if i is Marker2D:
			spawner_array[i.name] = {"object": i, "free": true} 
			#print(i.name)

#start of round/game logic
func intro(level):
	#fade in
	$blackout.color.a = 1
	$blackout.show()
	var tween = create_tween()
	tween.tween_property($blackout, "color:a", 0, 0.3)
	$sounds/StartRound.play()
	$score_screen.hide() #if here after score screen hide it
	
	player.position = $start_position.position #set palyer position to start hte"cutscene"
	disable_wall(true)
	
	tween = create_tween()
	player.force_walk = true #removes controls from palyer for intro movement
	tween.tween_property(player, "position:x", player.position.x + 500, 1.5)
	await tween.finished
	player.force_walk = false
	
	$Timer.start(1) #start enemy spawnings
	$countdown_timer.start(times[Global.level]) #start the timer with the corresponding level time
	disable_wall(false)
	
	current_goal = goals[level] #set goal to corresponding level clear requirement
	$"label score/required_score".text = "REQUIRED - " + str(current_goal)
	

#outro logic
func outro():
	#kill all popup windows
	for window in get_tree().root.get_children(): #windows are not categorized under root oops
		if window.name.contains("break_window") or window is Window: 
			window.kill()
	 
	$Timer.stop() #stop new enemy creation while in outro
	for i in $enemies.get_children(): #kill all existing enemies
		i.force_kill = true
		i.hurt()
	#moved killing balls to the end to account for edge cases and less awkward disappearence mid outro
	
	#set collisions for player moving out of the screen
	player.set_collision_mask_value(8, false) 
	disable_wall(true)
	
	player.force_walk = true #continue process of making character walk forward off screen in the player script
	var tween = create_tween()
	tween.tween_property($blackout, "color:a", 1, 1)
	
	await tween.finished
	
	disable_wall(false)
	player.set_collision_mask_value(8, true) 
	
	tween.kill()
	
	tween = create_tween()
	tween.tween_property($blackout, "color:a", 0, 1) #fade out black
	$score_screen.show()
	
	await tween.finished
	$blackout.hide()
	
	#set button to continue/retry based on success of clearning the required goal
	$"score_screen/label score".text = "SCORE - " + str(Global.score)
	if Global.score >= current_goal:
		allowed_to_continue = true
		$"score_screen/label score/status".text = "SUCCESS!"
	else:
		allowed_to_continue = false
		$"score_screen/label score/status".text = "FAILED"
	
	
	#kill all balls  - moved to end to account for bullets created last second
	for i in balls.get_children():
		i.queue_free()


func _physics_process(delta: float) -> void:
	$label_time.text = "TIME LEFT-"+ str(int($countdown_timer.time_left)) #set timer label time


func _on_spawner_timer_timeout() -> void:
	var cur_spawner = "spawner"+ str(randi_range(1, 5)) #choose random spawner for enemies
	var spawner_data = spawner_array[cur_spawner]
	
	if spawner_data["free"]: #if spawner is free (also causes slower enemy spawns when more enemies present by having more options blocked)
		var new_enemy = ENEMY.instantiate()
		$enemies.add_child(new_enemy) #add enemy under enemy group to keep organized
		new_enemy.spawner = cur_spawner
		
		new_enemy.death.connect(free_spawner.bindv([cur_spawner])) #bind to know when spawner goes free
		
		new_enemy.position = spawner_data["object"].position
		spawner_data["free"] = false #set spawner as busy
		new_enemy.intro() 


func free_spawner(spawner):
	spawner_array[spawner]["free"] = true


var color_combo = 0.2
func score_ui(score): #score ui handler
	label_score.text = "SCORE: " + str(score)
	#make label "punch out" when score added for pazaz then shirnk down to origianl size
	label_score.scale = Vector2(1.4, 1.4) 
	label_score.add_theme_color_override("font_color", Color(1,1-color_combo,1-color_combo))
	#slow delay 
	await get_tree().create_timer(0.03).timeout
	label_score.scale = Vector2(1.2, 1.2)
	await get_tree().create_timer(0.1).timeout
	#fade color tint out
	label_score.add_theme_color_override("font_color", Color.WHITE)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label_score, "scale", Vector2(1,1), 0.15) #fade size to orignal

func disable_wall(state):
	if state: # true
		#work around to disabling since for some reason disable on collisionpolygon doesnt work
		$border_wall.set_collision_layer_value(8, true) 
		$border_wall.set_collision_layer_value(1, false) 
		$border_wall.set_collision_mask_value(8, true) 
		$border_wall.set_collision_mask_value(1, false) 
	else: # false
		#reanable
		$border_wall.set_collision_layer_value(8, false) 
		$border_wall.set_collision_layer_value(1, true) 
		$border_wall.set_collision_mask_value(8, false) 
		$border_wall.set_collision_mask_value(1, true) 
	#$border_wall/CollisionPolygon2D.call_deferred("disabled", state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):  
		if $pause_screen.visible:
			pausing(false)
		else:
			pausing(true)

func _on_continue_button_up() -> void:
	pausing(false)

func _on_main_menu_button_up() -> void:
	pausing(false)
	#print("unpause")
	var tween = create_tween()
	tween.tween_property($blackout, "color:a", 1, 0.15)
	await tween.finished
	get_tree().change_scene_to_file("res://main_menu.tscn") 
	#print("by bye")

func pausing(state): #changing processing mode function
	if state:
		$pause_screen.show()
		$pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		$pause_screen.hide()
		$pause_screen.process_mode = Node.PROCESS_MODE_INHERIT
		process_mode = Node.PROCESS_MODE_INHERIT

signal round_over

func _on_countdown_timer_timeout() -> void:
	$sounds/Whistle.play()
	round_over.emit()
	$ball_wall.homerun_logic(false)
	outro()

func _on_play_button_up() -> void:
	#print("play pressed")
	if Global.score >= current_goal:
		$score_screen/play.text = "CONTINUE"
		Global.level += 1 
	else:
		$score_screen/play.text = "RETRY"
	$score_screen.hide()
	intro(Global.level)
	Global.score = 0
	

func _on_exit_button_up() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
	#print("exit clicked")
	

func _on_hide_tutor_button_up() -> void:
	if !pause_tutorial:
		process_mode = Node.PROCESS_MODE_INHERIT
	$moveset_tutorial.hide()
	intro(Global.level)

var pause_tutorial = false
func _on_show_tutorail_button_up() -> void:
	pause_tutorial = true
	$moveset_tutorial.show()
