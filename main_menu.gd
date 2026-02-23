extends Control


@onready var banner_title: Sprite2D = $BannerTitle
@onready var banner_guy: Sprite2D = $BannerGuy
@onready var blackout: ColorRect = $blackout

func _ready() -> void:
	breath(banner_title, 15)
	breath(banner_guy, -5)
	

func breath(node, offset): #function to make nodes float up and down gently "float"
	var node_pos = node.position
	var tween = create_tween().set_loops()
	tween.tween_property(node, "position:y", node_pos.y + offset, 3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position:y", node_pos.y - offset, 3).set_trans(Tween.TRANS_SINE)

func _on_play_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(blackout, "color:a", 1, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scene.tscn")


func _on_exit_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(blackout, "color:a", 1, 0.15)
	await tween.finished
	get_tree().quit()
