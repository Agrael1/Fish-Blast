class_name PauseMenu
extends Control

@export var animation_player: AnimationPlayer

func _ready() -> void:
	animation_player.play(&"RESET")
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"esc"):
		if get_tree().paused:
			_resume()
		else:
			_pause()

func _resume() -> void:
	get_tree().paused = false
	animation_player.play_backwards(&"blur")
	visible = false

func _pause() -> void:
	visible = true
	get_tree().paused = true
	animation_player.play(&"blur")

func _on_resume_button_pressed() -> void:
	_resume()

func _on_quit_button_pressed() -> void:
	_resume()
	get_tree().change_scene_to_file("res://proto/menu.tscn")

func _on_restart_button_pressed() -> void:
	_resume()
	get_tree().reload_current_scene()
