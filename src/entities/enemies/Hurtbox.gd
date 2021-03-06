extends Area2D

onready var enemy = get_parent()


func take_damage(player_color):
	if player_color == enemy.color_number and (enemy.protector or enemy.protections == 0):
		enemy.die()
		return true
	return false

func take_knockback(knockback_vector):
	enemy.take_knockback(knockback_vector)
