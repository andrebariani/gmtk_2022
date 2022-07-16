extends KinematicBody2D

var speed = 500
var velocity = Vector2.ZERO
var attributes


func _process(delta):
	if move_and_collide(velocity * speed * delta):
		queue_free()
	

func initialize_bullet(initial_pos, direction):
	self.global_position = initial_pos
	self.velocity = direction.normalized()


func _on_Life_timer_timeout():
	queue_free()

func _on_Hitbox_area_entered(_area):
	queue_free()
