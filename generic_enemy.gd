extends Area2D
#preloads
@onready var BULLET = preload("res://bullet.tscn")
const ENEMY = preload("uid://em3qcldpa4kl")
const ENEMY_HURT = preload("uid://ya2x0j7pl864")

@onready var bullet_spawn: Marker2D = $bullet_spawn
@onready var shooting_timer: Timer = $shooting_timer
@onready var check_border_right: RayCast2D = $check_border_right
@onready var check_border_left: RayCast2D = $check_border_left
@onready var enemy_hit: AudioStreamPlayer = $sounds/EnemyHit
@onready var enemy_shoot: AudioStreamPlayer = $sounds/EnemyShoot

signal death


#logic logic
var intro_finished = false
var spawner #keep where you were spawned at
var player : CharacterBody2D 

#movement logic
var direction = 1.0
var wiggle_time = 0.0
var velocity : Vector2 = Vector2.ZERO #notice theres no velocity sicne enemy is area2d, its just a value that is added into position
var shooting_slowdown = 1.0
var wiggle_strength = 1.5
#ball holding logic
var bullet_speed  = 5
var ball_follow_enemy = false
var hold_ball_for_following
var bullet_shoot_strength = 200

func _ready() -> void:
	if get_node("../../hero_char"):
		#print("found player")
		player = get_node("../../hero_char") #get player node on initialization
	#print("enemy ready")
	#shoot_bullet(BULLET)


func intro():
	var tween : Tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 400, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC) #fly down from spawn offscreen
	intro_finished = true


func _physics_process(delta: float) -> void:
	if ball_follow_enemy and hold_ball_for_following and !is_queued_for_deletion():
		hold_ball_for_following.global_position = global_position #easiest way to stick ball to enemy without messing with rigidbody physics 
	
	if intro_finished and player and !is_queued_for_deletion():
		wiggle_time += delta #wiggle time calculates y position to make nemy move in wavelike forms (sine wave)
		
		velocity.x = 4 * direction * shooting_slowdown
		velocity.y = sin(wiggle_time * 8.0) * wiggle_strength #sine wave * arbitrary speed number 
		position += velocity
		
		#change directions if ray intersects with wall
		if check_border_left.is_colliding():
			var tween : Tween = create_tween()
			tween.tween_property(self, "direction", 1, 0.6)
			#direction = 1
		elif check_border_right.is_colliding():
			var tween : Tween = create_tween()
			tween.tween_property(self, "direction", -1, 0.6)
			#direction = -1



func shoot_bullet(given_bullet):
	if !player and !is_queued_for_deletion():
		return #stop from shooting bullets 
	
	#print("shooting bullet!")
	var bullet = given_bullet.instantiate()
	get_tree().root.get_node("scene").get_node("balls").add_child(bullet) #set the bullet as child of node holding all bullets in main scene for easier control
	
	hold_ball_for_following = bullet
	ball_follow_enemy = true
	
	var tween : Tween = create_tween()
	tween.tween_property(self, "shooting_slowdown", 0, 1) #slow down before shooting for clarity of player
	
	
	bullet.freeze = true #stop bullet from despawning and/or falling off the enemy before being shot
	await get_tree().create_timer(1).timeout #wait a second before shooting the bullet
	tween.kill() #prevent tween bugs happening after awaits 1
	if !bullet: #prevent weird bugs happening due to bullet deletion during hte await 2
		return
	
	bullet.freeze = false #unfreeze physics before shooting
	ball_follow_enemy = false #stop carrying the bullet
	
	enemy_shoot.play() #shooting sound
	
	var direction = (player.global_position - global_position).normalized() #direction to the playerrr
	bullet.linear_velocity = direction * bullet_speed * bullet_shoot_strength #"shoot" the bullet at the enemy - set strength of velocity with direction 
	
	ball_follow_enemy = false #stop carrying the bullet
	shooting_slowdown = 1 #reset enemy slowdown for next shoot 

 

##DEFUNCT -  can reimplement if you want enemy to shoot  a different bullet type ,currently guided by simple count (every 3rd shot rn)
#var special_bullet_count = 0
func _on_shooting_timer_timeout() -> void:
	#special_bullet_count += 1
	#if special_bullet_count == 3:
		#shoot_bullet(BULLET)
		#special_bullet_count = 0
	#else:
	shoot_bullet(BULLET)


func _on_body_entered(body: Node2D) -> void: #area detection of bullet hitting enemy
	if body.is_in_group("hittable") and body.friendlyfire == true:
		hurt()
		body.destroy() #kill the bullet hitting the enemy after hit


@onready var hp = 2
var force_kill = true #if true skips hp system, left on for simplicity in the game jam

func hurt():
	#print("ow, im dying!")
	hp -= 1
	$Sprite2D.texture = ENEMY_HURT
	enemy_hit.play() #sound
	await  get_tree().create_timer(0.3).timeout #wait a second as a cooldown for death logic 
	Global.score += 10 #should add a global fucntion to handle scroing instead of adding it like that 
	
	if hp <= 0 or force_kill: #death
		shooting_timer.stop() #stop recursive timer that shoots bullets
		Global.score += 5 #should add a global fucntion to handle scroing instead of adding it like that 
		ball_follow_enemy = false #stop carrying the bullet if one still happens to follow the enemy upon death 
		#print("goodbye cruel world")
		emit_signal("death")
		$sounds/EnemyDisappear.play() #sound
		await get_tree().create_timer(0.5).timeout #wait before disappearing for visual clarity
		queue_free() #DIE!!
	else:
		$Sprite2D.texture = ENEMY #reset texture to not hurt version
