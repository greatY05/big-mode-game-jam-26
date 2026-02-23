extends Node

signal score_added(score)

var screen_size : Vector2 = Vector2(960, 736)
var entire_screen_size : Vector2 #the monitor size of hte current monitor
var level = 0

var score : float = 0.0:
	set(new_score): #setter for adding score for signaling
		emit_signal("score_added", new_score)
		score = new_score

func _ready() -> void:
	entire_screen_size = get_screen_size()
	screen_size = get_window_size()
	#print(DisplayServer.get_window_at_screen_position(Vector2.ZERO))


func get_screen_size() -> Vector2:
	return DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen()).size

func get_window_size():
	return get_viewport().get_visible_rect().size
