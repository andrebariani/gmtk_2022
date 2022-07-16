extends State

var look_vector

var starting_load = 0

func begin():
	if !e.enablers.charge:
		end("Idle")
		return
	
	look_vector = (e.get_global_mouse_position() - e.global_position).normalized()
	e.current_speed = e.charge_speed
	e.has_dir_control = false
	e.hitbox.monitoring = true
	starting_load = e.load_amount


func run(delta):
	e.apply_velocity(look_vector * delta)
	
	e.current_speed = lerp(e.charge_speed, e.walk_speed, 
		1 - e.load_amount/starting_load)
	e.load_amount -= delta*2
	if e.load_amount <= 0:
		if e.get_input('dirv') == Vector2.ZERO:
			end("Idle")
		else:
			end("Move")


func before_end(_next_state: String):
	e.current_speed = e.walk_speed
	e.has_dir_control = true
	e.hitbox.monitoring = false
	e.take_knockback(look_vector * 1500)


func _on_Hitbox_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(e.current_enemy_type)
	
	if area.has_method("take_knockback"):
		area.take_knockback(look_vector * e.current_speed)