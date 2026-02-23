extends CharacterBody2D


@onready var jump_force : Vector2
@onready var move_speed_max = 450
@onready var can_jump = false
@onready var is_on_wall = false
@onready var is_dashing = false
@onready var wall_jump_cooldown = 0.0
@onready var on_wall_time = 0.0

@onready var jump_height = -700

@onready var ground_ray: RayCast2D = $ground_ray
@onready var right_wall_ray: RayCast2D = $right_wall_ray
@onready var left_wall_ray: RayCast2D = $left_wall_ray

@onready var direction : int = 1
@onready var last_direction : int = 0
@onready var wall_push_boost = 0.0

@onready var gravity = 1500
@onready var fall_gravity = 1500 * 1.5 
@onready var post_dash_count = 0.0

@onready var after_dash_cooldown = 0.0
@onready var dash_jump = false #removes vertical movement barrier of dash if dash-jumping
@onready var is_slamming = false
@onready var slam_dash_window = 0.0

@onready var texture: AnimatedSprite2D = $texture
@onready var force_walk = false

@onready var hit_sound: AudioStreamPlayer = $sounds/hit


func _ready() -> void:
	jump_force = Vector2(0, jump_height)

func var_gravity(velocity: Vector2): #gravity operator return higher gravity if  falling down
	if abs(velocity.x) < 0:
		return gravity
	else: return fall_gravity

func _physics_process(delta: float) -> void:
	set_state() #state checks for rays
	
	if !is_on_floor():
		velocity.y += var_gravity(velocity) * delta #gravity
	
	if force_walk: #intro mvoement
		direction = 1
		velocity.x = direction * move_speed_max
		move_and_slide()
		return
	last_direction = direction #buffer for last direction
	wall_jump_cooldown -= delta #counts how long youve been on the wall
	wall_push_boost -= delta #not working - should help you boost after turning around
	slam_dash_window -= delta
	after_dash_cooldown -= delta
	
	var input_direction = Input.get_axis("ui_left", "ui_right") #get axis
	var wall_ray = left_wall_ray if input_direction < 0 else right_wall_ray #handles which wall ray to use
	
	
	#entire movement handling
	if input_direction != 0 and wall_jump_cooldown <= 0 and !is_dashing: #if not standing still and not dashing
		if wall_ray.is_colliding() and input_direction != 0: #standing next to a wall and not moving?
			on_wall_time += delta #count up time on the wall for sliding
		else:
			on_wall_time = 0 #reset one wall time
		
		if wall_ray.is_colliding() and velocity.y < 0: #wall slide up
			#print("upslide")
			velocity.y += -abs(velocity.x)  #should convert the horizontal velocity into vertical one to slide up wall?
			velocity.x = 0 #reset horizontal
		
		elif wall_ray.is_colliding() and velocity.y > 0: #wall slide down
			velocity.x = 0 #reset horizontal
			velocity.y = clamp( 0 + on_wall_time * 500, 0, 700) # as time on wall continues slide down faster
		
		else: #sideways movement
			direction = input_direction #direction = current axis movement
			velocity.x = direction * move_speed_max #simple movement - direction times max speed
			#velocity.x = clamp(velocity.x, -move_speed_max, move_speed_max)   ##depreceated overly complicated
	else:
		if is_dashing:
			velocity.x = lerp(velocity.x, 0.0, 0.10) # decelerate slower after dash
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.15)  # Decelerate when no input
	
	
	if Input.is_action_just_pressed("jump"):
		if can_jump: 
			if is_dashing:
				dash_jump = true
				after_dash_cooldown = 0
				velocity.y = clamp(-abs(velocity.x), 0, -1200)
				#velocity.y = jump_force.y *1.1#jump applying
				#print("post-dash jump")
			elif (slam_dash_window / 3) > 0 :
				velocity.y = jump_force.y * 1.8 #jump applying
			else:
				velocity.y = jump_force.y #jump applying
		if is_on_wall and can_jump and !is_on_floor(): #for wall jump - check also that isnt on ground
			velocity += Vector2(-direction * 900, -120) #jump away from wall - get rid of magic numbers
			wall_jump_cooldown = 0.15 # set time before regaining movement after wall jump
			on_wall_time = 0 #reset time onb wall
	
	if Input.is_action_just_released("jump") and velocity.y < 0: #jump shorter if released the key
		velocity.y = jump_force.y / 4
	
	if Input.is_action_just_pressed("slam") and Input.is_action_pressed("ui_down") and !is_on_floor(): #ground slam ability
		is_slamming = true
		
	
	if Input.is_action_just_pressed("dash"):
		if after_dash_cooldown > 0:
			return
		
		is_dashing = true
		after_dash_cooldown = 0.5
		if slam_dash_window > 0:
			velocity.x += direction * move_speed_max * 5 #set dash speed times the regular speed
		else:
			velocity.x += direction * move_speed_max * 3 #set dash speed times the regular speed
		post_dash_count = 3.0
	
	
	
	
	if is_slamming:
		velocity.y = -jump_force.y * 2.5 #downward momentum
		velocity.x /= 10 #stop sideways movement while slamming
	
	if is_dashing: #while still dashing
		if !dash_jump:
			velocity.y = 0 #stop vertical movement while dashing while not dash-jumping
		if abs(velocity.x) < move_speed_max: #once back to normal speed
			is_dashing = false #regain control
	
	if is_on_wall  and !can_jump: #regain jump after landing on wall
		can_jump = true
	
	if !can_jump and velocity.y > 50: #downward force when falling
		if dash_jump: #reset dash jump after finishing it to immidately relock vertical movement
			dash_jump = false
		velocity.y += 2500 * delta
	
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("hit"):
		hit()
		

var label_text : String
var previous_label_text = ""
func set_state():
	
	var input_direction = Input.get_axis("ui_left", "ui_right")
	var wall_ray = left_wall_ray if input_direction < 0 else right_wall_ray
	#big state tree to manage animations and is expandable but should just be turned into a state machine
	if texture.animation != "hit" :
		if is_on_wall and !force_walk:
			texture.play("wall_slide")
			label_text = "wall sliding"
		elif is_dashing and !force_walk:
			texture.play("dash")
			label_text = "dash"
			#shader_dash()
		elif is_slamming and !force_walk:
			texture.play("slam")
			label_text = "slamming"
		elif dash_jump and !force_walk: 
			texture.play("dash_jump")
			label_text = "dash-jumping"
		elif !can_jump and velocity.y > 0:
			texture.play("jump_fall")
			label_text = "falling / in air"
		elif !can_jump and velocity.y < 0:
			texture.play("jump")
			label_text = "jump"
		elif is_on_floor() and abs(velocity.x) >= 50 or force_walk:
			texture.play("run")
			label_text = "walking"
		elif is_on_floor():
			texture.play("idle")
			label_text = "standing"
	#$"../Label state".text = label_text
	
	if texture.animation != "hit":
		if direction > 0:
			texture.flip_h = false
		elif direction < 0:
			texture.flip_h = true
	#if last_direction != direction:
		#texture.flip_h = !texture.flip_h
	
	
	if label_text != previous_label_text:
		print("different ", label_text,  " ", previous_label_text)
		if label_text != "":
			var sound = $sounds.get_node_or_null(label_text)
			print("Sound node found: ", sound)  # Add this
			if sound:
				sound.play()
		previous_label_text = label_text
	
	if ground_ray.is_colliding() or is_on_wall:
		can_jump = true
		if is_slamming and !is_on_wall or is_on_floor() and is_on_wall and is_slamming:
			$sounds/slam.play()
			$"../Camera".apply_shake()
			after_dash_cooldown = 0
			is_slamming = false
			slam_dash_window = 1
	else:
		can_jump = false
	
	if right_wall_ray.is_colliding() or left_wall_ray.is_colliding():
		if is_on_floor():
			on_wall_time = 0 #reset time onb wall
		is_on_wall = true
	else:
		is_on_wall = false


@onready var hit_coll_med: CollisionPolygon2D = $bat_anchor/hit_area/hit_coll_med
@onready var hit_coll_weak: CollisionPolygon2D = $bat_anchor/hit_area/hit_coll_weak
@onready var hit_coll_strong: CollisionPolygon2D = $bat_anchor/hit_area/hit_coll_strong
@onready var hit_phase_timer: Timer = $hit_phase_timer

@onready var hit_inbetweens = 0.5

func hit():
	#hit_coll_strong.disabled = true
	#await get_tree().create_timer(hit_inbetweens).timeout
	#hit_coll_strong.disabled = false
	#hit_coll_med.disabled = true
	#await get_tree().create_timer(hit_inbetweens).timeout
	#hit_coll_med.disabled = false

	hit_coll_weak.disabled = true
	await get_tree().create_timer(hit_inbetweens).timeout
	hit_coll_weak.disabled = false

@onready var hit_strength_scale = 500

func _on_hit_area_body_entered(body: Node2D) -> void: #hitting logic
	if body.is_in_group("hittable"):
		if !body.friendlyfire:
			if !ground_ray.is_colliding():
				Global.score += 10 #double score if not on ground/in air or wall
			else:
				Global.score += 5 #add score
		
		body.friendlyfire = true
		var direction = (body.global_position - global_position).normalized() #reverse direction of entering area
		var force = 2 * hit_strength_scale 
		var should_home = false #DEFUNCT as of now
		
		
		#semi functioning half scrapped system to alter stregth of hit based on accuracy, doesnt do much right now but expendable
		if hit_coll_strong.disabled == false:
			force = 3.5 * hit_strength_scale
			#print("mid hit")
			should_home = true
			
		elif hit_coll_med.disabled == false:
			force = 7 * hit_strength_scale
			#print("strong hit")
			
			#should_home = true
		else:
			pass #print("weak hit") 
		
		
		body.linear_velocity = direction * force
		
		if should_home:
			body.should_home = true #activates homing in the bullets process - defunct
		
		manage_animation("hit")

#mostly just for hit animation to override any animation there can be
func manage_animation(animation):
	if animation == "hit":
		$sounds/hit.play()
		var last_texture_anim = texture.animation
		texture.play("hit")
		await get_tree().create_timer(0.16).timeout
		if last_texture_anim == "hit":
			texture.play("idle")
		else: 
			texture.play(last_texture_anim)
