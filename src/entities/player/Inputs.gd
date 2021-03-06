extends Node

export(Array, String) var just_pressed_inputs

var inputs = {
	dirv = Vector2.ZERO,
	roll = false,
	roll_jp = false,
	charge = false,
	charge_released = false
}

var disabled = false

var p: Player


func _ready():
	for just_pressed_input in just_pressed_inputs:
		inputs[just_pressed_input] = false


func init(_entity):
	self.p = _entity


func get_inputs():
	# Reset inputs
	for i in inputs.keys():
		if inputs[i] is bool:
			inputs[i] = false
	
	if disabled:
		inputs.dirv = Vector2.ZERO
		return
	
	if p.has_dir_control:
		inputs.dirv.x = Input.get_axis("move_left", "move_right")
		inputs.dirv.y = Input.get_axis("move_up", "move_down")
		
		inputs.dirv = inputs.dirv.normalized()
	
	if inputs.dirv != Vector2.ZERO:
		p.ori = inputs.dirv

	for just_pressed_input in just_pressed_inputs:
		if Input.is_action_just_pressed(just_pressed_input):
			inputs[just_pressed_input] = true
	
	if Input.is_action_just_released("charge"):
		inputs.charge_released = true
