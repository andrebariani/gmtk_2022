extends ColorRect

signal game_over_finished

func game_over(score, player_screen_position):
	print_debug(player_screen_position)
	material.set_shader_param("center", player_screen_position)
	$AnimationPlayer.play("GameOver")
	$Label/Score.text = "Score: " + str(score)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "GameOver":
		emit_signal("game_over_finished")
